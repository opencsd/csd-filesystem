package Test::AnyStor::Network;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Dumper;
use Test::Most;
use JSON qw/decode_json/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'event_check' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub network_host_info
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->request(
        uri      => '/network/host/info',
        expected => $expected,
    );

    return $res->{entity}->[0];
}

sub network_host_update
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->request(
        uri    => '/network/host/update',
        params => {
            Hostname => $args{hostname}
        },
        expected => $expected,
    );

    return $self->t->success;
}

sub network_device_list
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->call_rest_api(
        uri      => '/network/device/list',
        expected => $expected,
    );

    return $res->{entity};
}

sub network_device_info
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->call_rest_api(
        uri      => '/network/device/info',
        params   => {Device => $args{devname}},
        expected => $expected,
    );

    return $res->{entity}->[0];
}

sub network_device_update
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %base_args = (devname => $args{devname});

    my %payload = (
        MTU       => $args{mtu},
        Active    => $args{active},
        IPasign   => $args{ipasign},
        VLAN_Tags => $args{vlan_tags}
    );

    my $res = $self->request(
        uri      => '/network/device/update',
        params   => \%payload,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_DEV_UPDATE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_DEV_UPDATE_OK' event check"
        );
    }

    return $self->t->success;
}

sub network_bonding_list
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %ext_args = (expected => $expected);

    my $res = $self->request(
        uri      => '/network/bonding/list',
        expected => $expected,
    );

    return $res->{entity};
}

sub network_bonding_info
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %base_args = (devname => $args{bondname});

    my %ext_args = (expected => $expected);

    my $res = $self->call_rest_api(
        uri      => '/network/bonding/info',
        params   => {Device => $args{bondname}},
        expected => $expected,
    );

    return $res->{entity}->[0];
}

sub network_bonding_create
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %payload = (
        PrimarySlave => $args{primary},
        Slave        => $args{slave},
        Mode         => $args{mode},
        MTU          => $args{mtu},
        Active       => $args{active}
    );

    my $res = $self->call_rest_api(
        uri      => '/network/bonding/create',
        params   => \%payload,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_BOND_CREATE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_BOND_CREATE_OK' event check"
        );
    }

    if ($self->t->success)
    {
        return $res->{entity}->[0]->{created} // 1;
    }

    return 0;
}

sub network_bonding_update
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %entity = (
        PrimarySlave => $args{primary},
        Slave        => $args{slave},
        Mode         => $args{mode},
        MTU          => $args{mtu},
        Active       => $args{active}
    );

    my $res = $self->request(
        uri      => '/network/bonding/update',
        params   => \%entity,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_BOND_UPDATE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_BOND_UPDATE_OK' event check"
        );
    }

    return $self->t->success;
}

sub network_bonding_delete
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %base_args = (devname => $args{bondname});

    my $res = $self->request(
        uri      => '/network/bonding/delete',
        params   => {Device => $args{bondname}},
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_BOND_DELETE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_BOND_DELETE_OK' event check"
        );
    }

    return $self->t->success;
}

sub network_address_list
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->request(
        uri      => '/network/address/list',
        expected => $expected,
    );

    return $res->{entity};
}

sub network_address_create
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %payload = (
        IPaddr  => $args{ipaddr},
        Netmask => $args{netmask},
        Gateway => $args{gateway},
        Active  => $args{active}
    );

    my $res = $self->request(
        uri      => '/network/address/create',
        params   => \%payload,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_ADDR_CREATE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_ADDR_CREATE_OK' event check"
        );
    }

    if ($self->t->success)
    {
        return $res->{entity}->[0]->{created} // 1;
    }

    return 0;
}

sub network_address_update
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %payload = (
        IPaddr  => $args{ipaddr},
        Netmask => $args{netmask},
        Gateway => $args{gateway},
        Active  => $args{active}
    );

    my $res = $self->request(
        uri      => '/network/address/update',
        params   => \%payload,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_ADDR_UPDATE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_ADDR_UPDATE_OK' event check"
        );
    }

    return $self->t->success;
}

sub network_address_delete
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->request(
        uri      => '/network/address/delete',
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_ADDR_DELETE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_ADDR_DELETE_OK' event check"
        );
    }

    return $self->t->success;
}

sub cluster_network_dns_info
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->request(
        uri      => '/cluster/network/dns/info',
        expected => $expected,
    );

    return $res->{entity}->[0];
}

sub cluster_network_dns_update
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my @payload = ();

    foreach my $dns (@{$args{dns}})
    {
        push(@payload, $dns);
    }

    my $res = $self->call_rest_api(
        uri      => '/cluster/network/dns/update',
        params   => \@payload,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_matched_exist_in_recent_events(
                code  => 'NETWORK_DNS_UPDATE_OK',
                from  => $res->{prof}->{from},
                scope => $self->hostname()
            ),
            "'NETWORK_DNS_UPDATE_OK' event check"
        );
    }

    return $res->{entity}->[0];
}

sub cluster_network_route_list
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->call_rest_api(
        uri      => '/cluster/network/route/list',
        expected => $expected,
    );

    return $res->{entity};
}

sub cluster_network_route_create
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %payload = (
        DevName     => $args{devname},
        Netmask     => $args{netmask},
        Destination => $args{destination},
        Gateway     => $args{gateway},
    );

    my %ext_args = (expected => $expected);

    my $res = $self->call_rest_api(
        uri      => '/cluster/network/route/create',
        params   => \%payload,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_ROUTE_CREATE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_ROUTE_CREATE_OK' event check"
        );
    }

    return $self->t->success;
}

sub cluster_network_route_update
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %base_args = (
        DevName     => $args{old_devname},
        Netmask     => $args{old_netmask},
        Destination => $args{old_destination},
        Gateway     => $args{old_gateway}
    );

    my %payload = (
        DevName     => $args{new_devname},
        Netmask     => $args{new_netmask},
        Destination => $args{new_destination},
        Gateway     => $args{new_gateway}
    );

    my $res = $self->call_rest_api(
        uri      => '/cluster/network/route/update',
        params   => \%payload,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_ROUTE_UPDATE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_ROUTE_UPDATE_OK' event check"
        );
    }

    return $self->t->success;
}

sub cluster_network_route_delete
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %payload = (
        DevName     => $args{devname},
        Netmask     => $args{netmask},
        Destination => $args{destination},
        Gateway     => $args{gateway}
    );

    my $res = $self->request(
        uri      => '/cluster/network/route/delete',
        params   => \%payload,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_ROUTE_DELETE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_ROUTE_DELETE_OK' event check"
        );
    }

    return $self->t->success;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Network
#       METHOD: cluster_network_zone_list
#        BRIEF: 네트워크 영역 목록 조회
#=============================================================================
sub cluster_network_zone_list
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my $res = $self->call_rest_api(
        uri      => '/cluster/network/zone/list',
        expected => $expected,
    );

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Network
#       METHOD: cluster_network_zone_create
#        BRIEF: 네트워크 영역 생성
#=============================================================================
sub cluster_network_zone_create
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %params = (Name => $args{zonename});

    if (defined($args{description}))
    {
        $params{Desc} = $args{description};
    }

    if (defined($args{zoneip}))
    {
        $params{Addrs}
            = ref($args{zoneip}) eq 'ARRAY' ? $args{zoneip} : [$args{zoneip}];
    }

    if (defined($args{zoneipfrom}) || defined($args{zoneipto}))
    {
        $params{Range} = sprintf('%s-%s', $args{zoneipfrom}, $args{zoneipto});
    }

    if (defined($args{domain}))
    {
        $params{Domain} = $args{domain};
    }

    my $res = $self->request(
        uri      => '/cluster/network/zone/create',
        params   => \%params,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_ZONE_CREATE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_ZONE_CREATE_OK' event check"
        );
    }

    return $self->t->success;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Network
#       METHOD: cluster_network_zone_delete
#        BRIEF: 네트워크 영역 삭제
#=============================================================================
sub cluster_network_zone_delete
{
    my $self = shift;
    my %args = @_;

    my $expected = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $expected = 0;
    }

    my %params = (Name => $args{zonename});

    my %ext_args = (expected => $expected);

    my $res = $self->request(
        uri      => '/cluster/network/zone/delete',
        params   => \%params,
        expected => $expected,
    );

    if ($self->event_check && $expected)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'NETWORK_ZONE_DELETE_OK', $res->{prof}->{from}
            ),
            "'NETWORK_ZONE_DELETE_OK' event check"
        );
    }

    return $self->t->success;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Network - 

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
