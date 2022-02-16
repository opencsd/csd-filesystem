package GMS::Controller::Auth::ADS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Validate::IP qw/is_loopback_ip is_linklocal_ip/;
use Fcntl qw/:flock/;
use IO::Interface::Simple;
use List::MoreUtils qw/uniq/;
use Sys::Hostname::FQDN qw/short/;

use GMS::API::Return qw/:AUTH api_status/;
use GMS::Auth::ADS;
use GMS::Common::IPC;
use GMS::Network::Type;
use GMS::System::Service qw/enable_service disable_service service_status
    control_service/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'hosts_file' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/etc/hosts',
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $ads  = GMS::Auth::ADS->new();
    my $info = $ads->info();

    if (ref($info) ne 'HASH')
    {
        $self->throw_error('Failed to get ADS authentication info');
    }

    my %rv = (
        Enabled =>
            (defined($info->{security}) && $info->{security} =~ m/^(ADS)$/i)
        ? 1
        : 0,
        Realm  => $info->{realm},
        DC     => $info->{ldap_server_name} // [],
        NBName => $info->{nbname},
    );

    $self->stash(openapi => \%rv);

    return \%rv;
}

sub enable
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Realm => {
            isa => 'NotEmptyStr',
        },
        DC => {
            isa => 'NotEmptyStr',
        },
        NBName => {
            isa     => 'NotEmptyStr',
            default => short(),
        },
        Admin => {
            isa => 'NotEmptyStr',
        },
        Password => {
            isa => 'NotEmptyStr',
        },
    };

    my $args = $self->validate($rule, $params);

    $self->_validate_dc($args->{DC});
    $self->_validate_realm($args->{Realm});

    my $ads = GMS::Auth::ADS->new(
        realm    => $args->{Realm},
        dc       => $args->{DC},
        nbname   => $args->{NBName},
        admin    => $args->{Admin},
        password => $args->{Password},
    );

    if ($self->_add_fqdn_host(
        nbname => $args->{NBName},
        realm  => $args->{Realm}
    ))
    {
        $self->throw_error('Failed to add FQDN host for ADS authentication');
    }

    if ($ads->config_enable())
    {
        $self->throw_error('Failed to update ADS authentication config');
    }

    warn '[DEBUG] idmap cache will be cleaned';

    if ($ads->clear_idmap_cache())
    {
        warn '[WARN] Failed to flush idmap cache';
    }

    if ($ads->join() || $ads->testjoin())
    {
        $self->throw_error('Failed to join to ADS');
    }

    my @addrs = map { $_->address; } IO::Interface::Simple->interfaces;
    @addrs = grep { !is_loopback_ip($_) && !is_linklocal_ip($_); } @addrs;

    if ($ads->dns_register(
        hostname => sprintf('%s.%s', $args->{NBName}, $args->{Realm}),
        addrs    => \@addrs,
    ))
    {
        my $msg = sprintf(
            'Failed to register DNS record: %s/%s',
            $args->{hostname} // 'undef',
            CORE::join(', ', @{$args->{addrs}})
        );

        $self->throw_error($msg);
    }

    foreach my $svc (qw/smb winbind/)
    {
        enable_service(service => $svc);

        my $oper = service_status(service => $svc) ? 'start' : 'restart';

        if (control_service(service => $svc, action => $oper))
        {
            $self->throw_error("Failed to $oper $svc");
        }
    }

    return $self->stash(
        openapi => 'OK',
        status  => 204,
    );
}

sub disable
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Realm => {
            isa => 'NotEmptyStr',
        },
        DC => {
            isa => 'NotEmptyStr',
        },
        NBName => {
            isa     => 'NotEmptyStr',
            default => short(),
        },
        Admin => {
            isa => 'NotEmptyStr',
        },
        Password => {
            isa => 'NotEmptyStr',
        },
    };

    my $args = $self->validate($rule, $params);

    my $ads = GMS::Auth::ADS->new(
        realm    => $args->{Realm},
        dc       => $args->{DC},
        nbname   => $args->{NBName},
        admin    => $args->{Admin},
        password => $args->{Password},
    );

    $self->_validate_realm($ads->realm);

    if ($ads->dns_unregister(
        hostname => sprintf('%s.%s', $args->{NBName}, $args->{Realm}),
    ))
    {
        $self->throw_error(
            sprintf('Failed to unregister DNS record: %s',
                $args->{hostname} // 'undef')
        );
    }

    if ($ads->leave())
    {
        $self->throw_error('Failed to leave from ADS');
    }

    if ($ads->config_disable())
    {
        $self->throw_error('Failed to disable ADS authentication');
    }

    if ($self->_del_fqdn_host(
        nbname => $ads->nbname,
        realm  => $ads->realm
    ))
    {
        $self->throw_error(
            'Failed to delete FQDN host for ADS authentication');
    }

    warn '[DEBUG] Kerberos ticket cache will be deleted...';

    my $result = GMS::Common::IPC::exec(
        cmd     => 'rm',
        args    => ['-f', '/tmp/krb5*'],
        timeout => 10
    );

    if (!defined($result) || $result->{status})
    {
        warn "[WARN] Failed to delete kerberos ticket cache: $result->{err}";
    }

    foreach my $svc (qw/smb winbind/)
    {
        enable_service(service => $svc);

        my $oper = service_status(service => $svc) ? 'start' : 'restart';

        if (control_service(service => $svc, action => $oper))
        {
            $self->throw_error("Failed to $oper $svc");
        }
    }

    return $self->stash(
        openapi => 'OK',
        status  => 204,
    );
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _validate_dc
{
    my $self = shift;
    my $dc   = shift;

    my $connected = 0;
    my $rv;

    for (my $i = 0; $i < 5; $i++)
    {
        $rv = GMS::Common::IPC::exec(
            cmd  => 'ping',
            args => ['-c', 1, $dc],
        );

        if (ref($rv) eq 'HASH' && $rv->{status} == 0)
        {
            $connected = 1;
            last;
        }
    }

    if (!$connected)
    {
        $self->throw_error(
            "Domain controller '$dc' not responding: $rv->{err}");
    }

    return;
}

sub _validate_realm
{
    my $self  = shift;
    my $realm = shift;

    my $rv = GMS::Common::IPC::exec(
        cmd  => 'nslookup',
        args => [$realm],
    );

    if (ref($rv) ne 'HASH' || $rv->{status})
    {
        $self->throw_error("Failed to DNS query for the realm '$realm'");
    }

    return;
}

sub _add_fqdn_host
{
    my $self = shift;
    my %args = @_;

    map {
        if (!(defined($args{$_}) && length($args{$_})))
        {
            warn "[ERR] Invalid parameter: $_";
            return -1;
        }
    } qw/nbname realm/;

    my $fqdn = sprintf('%s.%s', $args{nbname}, lc($args{realm}));

    my $fh;

    if (!open($fh, '+<', $self->hosts_file))
    {
        warn "[ERR] Failed to open: ${\$self->hosts_file}: $!";
        return -1;
    }

    if (!flock($fh, LOCK_EX))
    {
        warn "[ERR] Failed to lock: ${\$self->hosts_file}: $!";
        return -1;
    }

    my @lines;

    while (my $line = <$fh>)
    {
        chomp($line);

        $line =~ s/(^\s+|\s+$)//g;

        if (!length($line) || $line =~ m/^#/)
        {
            push(@lines, $line);
            next;
        }

        my $comment;

        if ($line =~ s/(?<comment>#.*$)//)
        {
            $comment = $+{comment};
        }

        my ($addr, @names) = split(/\s+/, $line);

        my $newline = sprintf('%s', $addr);

        if (grep { $_ =~ m/^$args{nbname}/i; } @names)
        {
            unshift(@names, $fqdn);
        }

        map { $newline = sprintf('%s %s', $newline, $_) } uniq(@names);

        $newline .= sprintf(' %s', $comment) if ($comment);

        push(@lines, $newline);
    }

    if (!seek($fh, 0, 0))
    {
        warn "[ERR] Failed to seek: ${\$self->hosts_file}: $!";
        return -1;
    }

    if (!truncate($fh, 0))
    {
        warn "[ERR] Failed to truncate: ${\$self->hosts_file}: $!";
        return -1;
    }

    map { warn "[DEBUG] /etc/hosts: $_: $lines[$_]\n"; } (0 .. $#lines);
    map { print $fh "$_\n"; } @lines;

    if (!flock($fh, LOCK_UN))
    {
        warn "[ERR] Failed to unlock: ${\$self->hosts_file}: $!";
    }

    close($fh);

    return 0;
}

sub _del_fqdn_host
{
    my $self = shift;
    my %args = @_;

    map {
        if (!(defined($args{$_}) && length($args{$_})))
        {
            warn "[ERR] Invalid parameter: $_";
            return -1;
        }
    } qw/nbname realm/;

    my $fqdn = sprintf('%s.%s', $args{nbname}, lc($args{realm}));

    my $fh;

    if (!open($fh, '+<', $self->hosts_file))
    {
        warn "[ERR] Failed to open file: ${\$self->hosts_file}: $!";
        return -1;
    }

    if (!flock($fh, LOCK_EX))
    {
        warn "[ERR] Failed to lock file: ${\$self->hosts_file}: $!";
        return -1;
    }

    my @lines;

    while (my $line = <$fh>)
    {
        chomp($line);

        $line =~ s/(^\s+|\s+$)//g;

        if (!length($line) || $line =~ m/^#/)
        {
            push(@lines, $line);
            next;
        }

        my $comment;

        if ($line =~ s/(?<comment>#.*$)//)
        {
            $comment = $+{comment};
        }

        my ($addr, @names) = split(/\s+/, $line);

        my $newline = sprintf('%s', $addr);

        my $num = 0;

        warn "[INFO] FQDN: $fqdn";

        map {
            warn "[INFO] HOSTNAME: $_";

            if (lc($_) ne lc($fqdn))
            {
                warn "[INFO] UNMATCHED: $_";
                $newline = sprintf('%s %s', $newline, $_);
                $num++;
            }
        } uniq(@names);

        next if (!$num);

        $newline = sprintf('%s %s', $newline, $comment) if ($comment);

        push(@lines, $newline);
    }

    if (!seek($fh, 0, 0))
    {
        warn "[ERR] Failed to seek: ${\$self->hosts_file}: $!";
        return -1;
    }

    if (!truncate($fh, 0))
    {
        warn "[ERR] Failed to truncate: ${\$self->hosts_file}: $!";
        return -1;
    }

    map { print $fh "$_\n"; } @lines;

    if (!flock($fh, LOCK_UN))
    {
        warn "[ERR] Failed to unlock file: ${\$self->hosts_file}: $!";
    }

    close($fh);

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Auth::ADS - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item B<Item 1>

=item B<Item 2>

=item B<Item 3>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

