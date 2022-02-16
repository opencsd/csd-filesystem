package GMS::Controller::Login;

use v5.14;

use strict;
use warnings;
use utf8;

use Mouse;
use namespace::clean -except => 'meta';
use Mojo::Util qw/b64_decode/;

use Crypt::OpenSSL::RSA;

use GMS::Account::Local;
use GMS::API::Return;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'account' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { GMS::Account::Local->new(); },
);

#---------------------------------------------------------------------------
#   Public Methods
#---------------------------------------------------------------------------
sub sign_in
{
    my $self   = shift;
    my $params = $self->req->json;

    my $signing_key = $self->get_signing_privkey();

    #warn "[DEBUG] signing_privkey: ${\$signing_key}";

    my $rsa = Crypt::OpenSSL::RSA->new_private_key($signing_key);

    $rsa->use_pkcs1_padding();

    my $encrypted = b64_decode($params->{Password});

    #warn "[DEBUG] encrypted: ${\length($encrypted)}";

    my $decrypted = $rsa->decrypt($encrypted);

    #warn "[DEBUG] decrypted: $decrypted";

    # validate the existence of an user
    my $user = $self->account->find_user(name => $params->{ID});

    if (!defined($user))
    {
        $self->throw_error("User not found: $params->{ID}");
    }

    my $managers = $self->etcd->get_key(key => '/Manager', format => 'json');

    if (!defined($managers->{$params->{ID}}))
    {
        $self->throw_error(
            level   => 'ERROR',
            code    => MANAGER_NOT_DELEGATED,
            msgargs => [user => $params->{ID}],
        );
    }

    # validate the matching of a password
    if (!$self->_is_valid_password(
        cipher => $user->{sp_pwd},
        plain  => $decrypted,
    ))
    {
        $self->throw_error("Incorrect password: $params->{ID}");
    }

    # generate a token
    my $token = $self->generate_token(id => $params->{ID});

    if (!defined($token))
    {
        $self->throw_error("Failed to generate a token: $params->{ID}");
    }

    $self->res->headers->authorization("Bearer $token");
    $self->cookie(gms_token => $token);

    api_status(
        level   => 'INFO',
        code    => SIGNED_IN,
        msgargs => [id => $params->{ID}],
    );

    $self->gms_new_event();

    return $self->render(
        openapi => {
            token      => $token,
            public_key => $self->get_pubkey(token => $token),
        }
    );
}

sub sign_out
{
    my $self   = shift;
    my $params = $self->req->json;

    my $token  = $self->get_token();
    my $claims = $self->decode_jwt(token => $token);

    if ($token ne $self->get_trusted_token())
    {
        $self->destroy_token(token => $token);
    }

    api_status(
        level   => 'INFO',
        code    => SIGNED_OUT,
        msgargs => [id => $claims->{id}],
    );

    $self->gms_new_event();

    $self->render(openapi => $claims);
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _is_valid_password
{
    my $self = shift;
    my %args = @_;

    my $cipher = $args{cipher};
    my $plain  = $args{plain};

    chomp($plain);

    return (crypt($plain, $cipher) eq $cipher);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Login - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

