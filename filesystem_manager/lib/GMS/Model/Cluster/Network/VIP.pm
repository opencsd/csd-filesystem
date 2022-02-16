package GMS::Model::Cluster::Network::VIP;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Network::Type qw(prefix_to_netmask);
use Net::IP qw(ip_bintoip ip_inttobin $IP_NO_OVERLAP);
use Sys::Hostname::FQDN qw(short);

use constant {
    CIDR      => 'GMS::Network::Type::CIDR',
    CIDRRange => 'GMS::Network::Type::CIDRRange',
};

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/Cluster/Network/VIP'; };
etcd_keygen sub { name => shift; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'hosts' => (
    is       => 'ro',
    isa      => 'HashRef',
    init_arg => undef,
    default  => sub { {}; },
);

has 'ipaddrs' => (
    is       => 'ro',
    isa      => "ArrayRef[${\CIDR}|${\CIDRRange}]",
    init_arg => undef,
    default  => sub { []; },
);

# prerequisite for GMS::CTDB::Configurable
has 'internal_path' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/home/__internal',
);

# prerequisite for GMS::CTDB::Configurable
has 'private_path' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/home/__internal',
);

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::File::JSON', 'GMS::CTDB::Configurable';

upgrade_attrs(
    key      => 'name',
    excludes => [
        'internal_path',
        'private_path',
        'files',
        'timeout',
        'ctdb_nodes',
        'ctdb_addrs',
        'ctdb_routes',
    ],
);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'to_hash' => sub
{
    my $self = shift;

    my @hosts   = ();
    my @ipaddrs = ();

    foreach my $ipaddr ($self->all_ipaddrs())
    {
        my ($first, $last, $netmask) = split(/(?:-|\/)/, $ipaddr);

        push(
            @ipaddrs,
            {
                Name    => $self->name,
                First   => $first,
                Last    => defined($netmask) ? $last : $first,
                Netmask => defined($netmask)
                ? prefix_to_netmask($netmask)
                : prefix_to_netmask($last),
            }
        );
    }

    foreach my $host ($self->all_hosts())
    {
        push(
            @hosts,
            map {
                my $device = $_;

                {
                    Name   => $self->name,
                    Host   => $host,
                    Device => $device,
                };
            } @{$self->hosts->{$host}->{devices}}
        );
    }

    return {
        Name    => $self->name,
        Hosts   => \@hosts,
        IPAddrs => \@ipaddrs,
    };
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub all_hosts
{
    my $self = shift;

    return keys(%{$self->hosts});
}

sub host_exists
{
    my $self = shift;
    my $host = shift;

    return exists($self->hosts->{$host});
}

sub get_host
{
    my $self = shift;
    my $host = shift;

    return $self->host_exists($host) ? $self->hosts->{$host} : undef;
}

sub get_host_devices
{
    my $self = shift;
    my $host = shift;

    if (!$self->host_exists($host)
        || ref($self->hosts->{$host}->{devices}) ne 'ARRAY')
    {
        return wantarray ? () : undef;
    }

    return wantarray
        ? @{$self->hosts->{$host}->{devices}}
        : $self->hosts->{$host}->{devices};
}

sub add_host
{
    my $self = shift;
    my %args = @_;

    state $rule = {
        host => {
            isa => 'NotEmptyStr',
        },
        device => {
            isa => 'NotEmptyStr',
        },
        host_ip => {
            isa      => 'GMS::Network::Type::IP',
            optional => 1,
        },
        length => {
            isa      => 'NotEmptyStr',
            optional => 1,
        },
    };

    my $args = $self->validate($rule, \%args);

    my $host_ip = $args->{host_ip} // _get_storage_ip($args->{host});

    if (!defined($host_ip))
    {
        $self->throw_error(message =>
                "Could not add VIP host for unknown node: $args->{host}");
    }

    if (!$self->host_exists($args->{host}))
    {
        $self->hosts->{$args->{host}} = {};
    }

    my $host = $self->get_host($args->{host});

    if (!grep { $args->{device} eq $_; }
        $self->get_host_devices($args->{host}))
    {
        push(@{$host->{devices}}, $args->{device});
    }

    return $self->add_ctdb_node(ipaddr => $host_ip);
}

sub remove_host
{
    my $self = shift;
    my %args = @_;

    state $rule = {
        host => {
            isa => 'NotEmptyStr',
        },
        device => {
            isa => 'NotEmptyStr',
        },
        length => {
            isa      => 'NotEmptyStr',
            optional => 1,
        },
    };

    my $args = $self->validate($rule, \%args);

    # Not exists
    if (!$self->host_exists($args->{host}))
    {
        warn "[WARN] Host not found: $args->{host}";
        return;
    }

    for (my $i = 0; $i < $args->{length}; $i++)
    {
        my $devices = $self->hosts->{$args->{host}}->{devices};

        if ($devices->[0] eq $args->{device})
        {
            delete($devices->[$i]);
        }
    }

    return $self->remove_ctdb_node(ipaddr => _get_storage_ip($args->{host}));
}

sub all_ipaddrs
{
    my $self = shift;

    return @{$self->ipaddrs};
}

sub count_ipaddrs
{
    my $self = shift;

    return scalar(@{$self->ipaddrs});
}

sub add_ipaddr
{
    my $self = shift;

    my $constraint
        = $self->meta->find_attribute_by_name('ipaddrs')->type_constraint;

    $constraint->assert_valid($constraint->coerce(\@_))
        if (defined($constraint));

    push(@{$self->ipaddrs}, @_);

    $self->_arrange_ipaddrs();

    return $self->count_ipaddrs;
}

sub remove_ipaddr
{
    my $self = shift;
    my $addr = shift;

    my @new_ips;
    my @deleted;

    my ($ip1, $prefix1) = split(/\//, $addr);

    $ip1 = Net::IP->new($ip1);

    foreach ($self->all_ipaddrs())
    {
        my ($ip2, $prefix2) = split(/\//, $_);

        $ip2 = Net::IP->new($ip2);

        my ($start, $end);

        do
        {
            if (!defined($start))
            {
                $start = $ip2->ip;
            }

            # if target IP(or IP range) is not overlapped with configured
            # IP(or IP range), assign the end of new range.
            if (Net::IP->new($ip2->ip)->overlaps($ip1) == $IP_NO_OVERLAP)
            {
                $end = $ip2->ip;

                # if current iteration is the end of the range, assign new
                # range
                if ($ip2->last_ip eq $end)
                {
                    push(@new_ips, "$start-$end/$prefix2");
                }
            }

            # assign new range if current iteration is overlapped
            else
            {
                push(@deleted, "${\$ip2->ip}/$prefix2");

                $start = $end = undef;
            }
        } while (++$ip2);
    }

    @{$self->ipaddrs} = @new_ips;

    $self->_arrange_ipaddrs();

    return wantarray ? @deleted : \@deleted;
}

sub reload
{
    my $self = shift;
    my %args = @_;

    # update CTDB nodes file
    foreach my $host ($self->all_hosts())
    {
        my $strg_ip = _get_storage_ip($host);

        if (!defined($strg_ip))
        {
            $self->throw_error(
                message => "Could not find storage IP address: $host");
        }

        $self->add_ctdb_node(ipaddr => $strg_ip);
    }

    # update CTDB public addresses file
    my $host = short();

    if (!$self->host_exists($host))
    {
        warn sprintf(
            '[DEBUG] This host is not a member of this VIP group: %s: %s',
            $self->name, $host);

        return;
    }

    my @devices = $self->get_host_devices($host);

    if (scalar(@devices) == 0)
    {
        $self->throw_error(message => "Could not find any devices: $host");
    }

    my %cidrs = map { $_ => 0; } $self->all_ipaddrs();

    foreach my $dev (@devices)
    {
        # 1. CTDB에 있음, DB에 없음 => 제거
        foreach my $cidr (@{$self->ctdb_addrs->{$dev}})
        {
            my ($ip1, $prefix1) = split(/\//, $cidr);

            $ip1 = Net::IP->new($ip1);

            do
            {
                my $overlaps_cnt = 0;

                foreach (keys(%cidrs))
                {
                    my ($ip2, $prefix2) = split(/\//, $_);

                    if ($ip1->overlaps(Net::IP->new($ip2)))
                    {
                        $overlaps_cnt++;
                        $cidrs{$_}++;
                    }
                }

                if (!$overlaps_cnt)
                {
                    $self->remove_ctdb_addr(
                        interface => $dev,
                        ipaddr    => "${\$ip1->ip}/$prefix1",
                    );
                }
            } while (++$ip1);
        }

        # 2. DB에 있음, CTDB에 없음 => 추가
        foreach my $cidr (keys(%cidrs))
        {
            if ($cidrs{$cidr} == 0)
            {
                my ($ip, $prefix) = split(/\//, $cidr);

                $ip = Net::IP->new($ip);

                do
                {
                    $self->add_ctdb_addr(
                        interface => $dev,
                        ipaddr    => "${\$ip->ip}/$prefix",
                    );
                } while (++$ip);
            }
        }
    }

    return;
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _get_storage_ip
{
    my @ips = GMS::Cluster::Etcd->new()->get_storage_ip(host => shift);

    return wantarray ? @ips : shift(@ips);
}

sub _arrange_ipaddrs
{
    my $self = shift;

    for (my $i = 0; $i < $self->count_ipaddrs; $i++)
    {
        for (my $j = $i + 1; $j < $self->count_ipaddrs; $j++)
        {
            my $cidr1 = $self->ipaddrs->[$i];

            # x.x.x.x-y.y.y.y/zz
            next if ($cidr1 !~ m/^(?<ip>[^\/]+)\/(?<prefix>\d?\d)$/);

            my $ip1     = Net::IP->new($+{ip});
            my $prefix1 = $+{prefix};

            my $range = Net::IP->new(
                sprintf(
                    '%s-%s',
                    ip_bintoip(
                        ip_inttobin($ip1->intip - 1, $ip1->version),
                        $ip1->version
                    ),
                    ip_bintoip(
                        ip_inttobin($ip1->last_int + 1, $ip1->version),
                        $ip1->version
                    )
                )
            );

            next
                if (
                $self->ipaddrs->[$j] !~ m/^(?<ip>[^\/]+)\/(?<prefix>\d?\d)/);

            my $ip2     = Net::IP->new($+{ip});
            my $prefix2 = $+{prefix};

            next
                if ($prefix1 != $prefix2
                || $ip1->version != $ip2->version
                || $ip2->overlaps($range) == $IP_NO_OVERLAP);

            my $new_first
                = $range->intip < $ip2->intip
                ? $ip1->ip
                : $ip2->ip;

            my $new_last
                = $range->last_int > $ip2->last_int
                ? $ip1->last_ip
                : $ip2->last_ip;

            splice(@{$self->ipaddrs}, $i, 1, "$new_first-$new_last/$prefix1");
            splice(@{$self->ipaddrs}, $j ? $j-- : $j, 1);
        }
    }
}

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'update' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if (exists($args{ipaddrs}))
    {
        if (ref($args{ipaddrs}) ne 'ARRAY')
        {
            $self->throw_exception(
                'InvalidParameter',
                param => 'ipaddrs',
                value => $args{ipaddrs}
            );
        }

        foreach my $cidr ($self->all_ipaddrs())
        {
            # :TODO 05/30/2019 06:39:46 PM: by P.G.
            # overlap checking
            next if (grep { $_ eq $cidr; } @{$args{ipaddrs}});

            $self->remove_ipaddr($cidr);
        }

        foreach my $cidr (@{$args{ipaddrs}})
        {
            $self->add_ipaddr($cidr);
        }
    }

    if (exists($args{hosts}))
    {
        if (ref($args{hosts}) ne 'HASH')
        {
            $self->throw_exception(
                'InvalidParameter',
                param => 'hosts',
                value => $args{hosts},
            );
        }

        # :TODO 09/24/2019 06:50:33 PM: by P.G.
        # hosts parameter handling
    }

    return $self->$orig(%args);
};

around 'delete' => sub
{
    my $orig = shift;
    my $self = shift;

    if ($self->name eq 'default')
    {
        $self->throw_exception('NotSupported',
            feature => '"default" VIP group cannot be deleted',);
    }

    foreach my $addr ($self->all_ipaddrs())
    {
        $self->remove_ipaddr($addr);
    }

    foreach my $host ($self->all_hosts())
    {
        foreach my $device (@{$self->hosts->{$host}->{devices}})
        {
            $self->remove_host(
                host   => $host,
                device => $device,
            );
        }
    }

    $self->$orig($self->name);
};

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Model::Cluster::Network::VIP - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

