package GMS::Plugin::AuthHelper;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Coro;
use Crypt::Digest::SHA512 qw/sha512_hex/;
use Crypt::OpenSSL::RSA;
use Mojo::JWT;
use Try::Tiny;

use GMS::Common::Logger;
use GMS::Cluster::Etcd;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'signing_privkey' => (
    is     => 'ro',
    isa    => 'Str',
    writer => 'set_signing_privkey',
);

has 'signing_pubkey' => (
    is     => 'ro',
    isa    => 'Str',
    writer => 'set_signing_pubkey',
);

has 'signing_refresh_interval' => (
    is      => 'ro',
    isa     => 'Int',
    default => 600,
);

has 'latest_refresh' => (
    is      => 'ro',
    isa     => 'Int',
    default => time,
    writer  => 'set_latest_refresh',
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub register
{
    my ($self, $app, $args) = @_;

    $app->helper(authenticate      => \&authenticate);
    $app->helper(generate_token    => \&generate_token);
    $app->helper(validate_token    => \&validate_token);
    $app->helper(destroy_token     => \&destroy_token);
    $app->helper(encode_jwt        => \&encode_jwt);
    $app->helper(decode_jwt        => \&decode_jwt);
    $app->helper(get_token         => \&get_token);
    $app->helper(get_trusted_token => \&get_trusted_token);
    $app->helper(get_pubkey        => \&get_pubkey);
    $app->helper(get_privkey       => \&get_privkey);

    $app->helper(
        get_signing_pubkey => sub
        {
            ($self->signing_pubkey, $self->latest_refresh);
        }
    );

    $app->helper(
        get_signing_privkey => sub
        {
            $self->signing_privkey;
        }
    );

    $self->regen_signing_key();

    Mojo::IOLoop->recurring(
        $self->signing_refresh_interval => sub
        {
            async
            {
                $Coro::current->{desc} = 'signing-key-refresher';

                catch_sig_warn(%{$app->log_settings});

                #Coro::on_enter
                #{
                #    warn "[DEBUG] on_enter: $Coro::current->{desc}";
                #};

                #Coro::on_leave
                #{
                #    warn "[DEBUG] on_leave: $Coro::current->{desc}";
                #};

                warn '[DEBUG] Regenerating signing key...';

                $self->regen_signing_key();
            };
        }
    );

    return;
}

sub regen_signing_key
{
    my $self = shift;

    my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);

    $rsa->use_pkcs1_padding();

    $self->set_signing_pubkey($rsa->get_public_key_x509_string);

    warn sprintf('[DEBUG] Signing private-key regenerated successfully: %s',
        $self->signing_privkey // 'undef');

    $self->set_signing_privkey($rsa->get_private_key_string);

    warn sprintf('[DEBUG] Signing public-key regenerated successfully: %s',
        $self->signing_pubkey // 'undef');

    $self->set_latest_refresh(time);

    return;
}

sub authenticate
{
    my $c    = shift;
    my %args = @_;

    my $token = $c->get_token();

    if (defined($token) && $token eq get_trusted_token())
    {
        return ($token, {});
    }

    if (!defined($token))
    {
        warn '[DEBUG] Token is empty';
        return;
    }

    my $jwt = $c->validate_token(token => $token);

    if (!defined($jwt))
    {
        warn sprintf(
            '[ERR] Token is invalid: %s: %s: %s',
            $c->req->request_id // 'undef',
            $token // 'undef',
            defined($jwt) ? $c->dumper($jwt) : 'undef'
        );

        return;
    }

    warn sprintf(
        '[DEBUG] Token is valid: %s: %s: %s',
        $c->req->request_id // 'undef',
        $token // 'undef',
        defined($jwt) ? $c->dumper($jwt) : 'undef'
    );

    return ($token, $jwt);
}

sub get_trusted_token
{
    my $fh;
    my $file = '/var/lib/gms/trusted.token';

    if (!open($fh, '<', $file))
    {
        warn "[ERR] Failed to open file: $file: $!";
        return;
    }

    chomp(my $token = <$fh>);

    close($fh);

    return $token;
}

sub generate_token
{
    my $c    = shift;
    my %args = @_;

    my $id = $args{id};

    my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);

    $rsa->use_pkcs1_padding();

    my %payload = (
        id         => $id,
        public_key => $rsa->get_public_key_x509_string,
    );

    my $token = $c->encode_jwt(
        payload   => \%payload,
        secret    => $rsa->get_private_key_string,
        algorithm => 'RS512',
    );

    # :TODO 12/01/2020 02:44:03 PM: by P.G.
    # store RSA key-pairs into etcd with authentication
    # ref: https://etcd.io/docs/v2/authentication/
    my $etcd = GMS::Cluster::Etcd->new();

    my $sessions = $etcd->get_key(
        key    => '/Sessions',
        format => 'json',
    );

    if (exists($sessions->{$c->tx->remote_address}))
    {
        return $sessions->{$c->tx->remote_address}->{token};
    }

    $sessions->{$c->tx->remote_address} = {
        token       => $token,
        public_key  => $rsa->get_public_key_x509_string(),
        private_key => $rsa->get_private_key_string(),
    };

    if (
        $etcd->set_key(
            key    => '/Sessions',
            value  => $sessions,
            format => 'json',
        ) <= 0
        )
    {
        warn '[ERR] Failed to set /Sessions';
        return;
    }

    return $token;
}

sub validate_token
{
    my $c    = shift;
    my %args = @_;

    my $jwt = try
    {
        return $c->decode_jwt(token => $args{token});
    }
    catch
    {
        warn "[ERR] Failed to decode token as JWT: @_";
        return;
    };

    return $jwt;
}

sub destroy_token
{
    my $c    = shift;
    my %args = @_;

    my $etcd = GMS::Cluster::Etcd->new();

    my $sessions = $etcd->get_key(
        key    => '/Sessions',
        format => 'json',
    );

    foreach my $s (values(%{$sessions}))
    {
        if ($s->{token} eq $args{token})
        {
            delete($sessions->{$args{token}});
            last;
        }
    }

    if (
        $etcd->set_key(
            key    => '/Sessions',
            value  => $sessions,
            format => 'json',
        ) <= 0
        )
    {
        warn '[ERR] Failed to set /Sessions';
        return -1;
    }

    return 0;
}

sub encode_jwt
{
    my $c    = shift;
    my %args = @_;

    if (exists($args{payload}))
    {
        $args{claims} = delete($args{payload});
    }

    #$args{expires} = exists($args{expires}) ? $args{expires} : 60;

    return Mojo::JWT->new(%args)->encode();
}

sub decode_jwt
{
    my $c    = shift;
    my %args = @_;

    my $pubkey = $c->get_pubkey(token => $args{token});

    if (!defined($pubkey))
    {
        warn sprintf('[ERR] Could not find RSA keypair for the token: %s',
            $args{token});

        return;
    }

    return Mojo::JWT->new(public => $pubkey)->decode($args{token} || '');
}

sub get_token
{
    my $c = shift;

    my $token;

    if ($c->req->headers->authorization
        && $c->req->headers->authorization =~ m/^Bearer\s+(?<token>.+)/)
    {
        warn '[DEBUG] Getting the token from Authorization header...';
        $token = $+{token};
    }
    elsif ($c->cookie('gms_token'))
    {
        warn '[DEBUG] Getting the token from cookie...';
        $token = $c->cookie('gms_token');
    }

    return $token;
}

sub get_pubkey
{
    my $c    = shift;
    my %args = @_;

    my $token = $args{token} // $c->get_token;

    if (!defined($token))
    {
        return;
    }

    my $etcd = GMS::Cluster::Etcd->new();

    my $sessions = $etcd->get_key(
        key    => '/Sessions',
        format => 'json',
    );

    warn "[DEBUG] Sessions: ${\$c->dumper($sessions)}";

    my $s = $sessions->{$c->tx->remote_address};

    if ($s->{token} ne $token)
    {
        warn "[ERR] Invalid token: ${\$c->tx->remote_address}: $token";
        return;
    }

    return $s->{public_key};
}

sub get_privkey
{
    my $c    = shift;
    my %args = @_;

    my $token = $args{token} // $c->get_token;

    my $etcd = GMS::Cluster::Etcd->new();

    my $sessions = $etcd->get_key(
        key    => '/Sessions',
        format => 'json',
    );

    my $s = $sessions->{$c->tx->remote_address};

    if ($s->{token} ne $token)
    {
        warn "[ERR] Invalid token: ${\$c->tx->remote_address}: $token";
        return;
    }

    return $s->{private_key};
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::AuthHelper - GMS authentication helper

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
