#!/usr/bin/perl -I /usr/gms/t/lib/

use strict;
use warnings;
use utf8;

our $AUTHORITY   = 'cpan:gluesys';
our $DESCRIPTOIN = <<'ENDL';
기본적인 Network API의 동작을 확인하는 테스트이며,
모든 Network API를 한번씩 호출하여 정상적으로 동작하는지 검사함
ENDL

use Env;
use Test::Most;
use Test::AnyStor::Network;
use Test::AnyStor::ClusterAddress;

$ENV{GMS_TEST_ADDR}  = shift(@ARGV) if @ARGV;
$ENV{GMS_TEST_IFACE} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR  = $ENV{GMS_TEST_ADDR};
my $GMS_TEST_IFACE = $ENV{GMS_TEST_IFACE};

my $verbose          = 0;
my $application_wait = 3;

my $TEST_IP_POOL_START = '100.0.0.1';
my $TEST_IP_POOL_END   = '100.0.0.10';

my @TEST_IP_POOL;
my $POOL_SIZE;

if (!defined($GMS_TEST_ADDR) || !defined($GMS_TEST_IFACE))
{
    ok(0, 'argument missing');
    return 1;
}

sub addr_to_dec
{
    my $addr = shift;

    my $decimal_addr = 0;
    my @addr_split   = split /\./, $addr;

    for (my $class = 0; $class < 4; $class++)
    {
        $decimal_addr += ($addr_split[3 - $class] << (8 * $class));
    }

    return $decimal_addr;
}

sub dec_to_addr
{
    my $decimal_addr = shift;

    my @addr_split = (
        ($decimal_addr & 255 * 256 * 256 * 256) >> 24,
        ($decimal_addr & 255 * 256 * 256) >> 16,
        ($decimal_addr & 255 * 256) >> 8,
        ($decimal_addr & 255) >> 0
    );

    return join('.', @addr_split);
}

subtest 'make_test_ip_pool' => sub
{
    my $dec_pool_start = addr_to_dec($TEST_IP_POOL_START);
    my $dec_pool_end   = addr_to_dec($TEST_IP_POOL_END);

    for (
        my $dec_addr = $dec_pool_start;
        $dec_addr <= $dec_pool_end;
        $dec_addr++
        )
    {
        my $test_addr = dec_to_addr($dec_addr);
        push(@TEST_IP_POOL, $test_addr);
    }

    $POOL_SIZE = scalar(@TEST_IP_POOL);

    ok(
        1,
        "Test ip pool has been created (size: $POOL_SIZE, range: $TEST_IP_POOL_START ~ $TEST_IP_POOL_END)"
    );
};

subtest "initialize test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'off'
    );
};

subtest 'device_api' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $vlan_number = 100;

    $t->network_device_update(
        devname   => $GMS_TEST_IFACE,
        mtu       => 2000,
        active    => 'on',
        vlan_tags => [$vlan_number]
    );

    sleep $application_wait;

    my $device_info = $t->network_device_info(devname => $GMS_TEST_IFACE);

    is($device_info->{MTU},    2000, "Verify updated MTU");
    is($device_info->{Active}, 'on', "Verify updated Active");

    my $check_vlan_tag = 1;

    $check_vlan_tag &&= (ref($device_info->{VlanTags} eq 'ARRAY')
            && scalar(@{$device_info->{VlanTags}}) != 0);

    my $device_list = $t->network_device_list();

    $check_vlan_tag
        &&= (grep { $_->{DevName} eq "$GMS_TEST_IFACE.$vlan_number" }
            @$device_list);

    ok($check_vlan_tag, "Verify updated VLAN Tag");

    $t->network_device_update(
        devname   => $GMS_TEST_IFACE,
        mtu       => 1500,
        active    => 'off',
        vlan_tags => []
    );

    sleep $application_wait;

    $device_info = $t->network_device_info(devname => $GMS_TEST_IFACE);

    is($device_info->{MTU},    1500,  "Verify reset MTU");
    is($device_info->{Active}, 'off', "Verify reset Active");

    $check_vlan_tag = 1;
    $check_vlan_tag &&= (ref($device_info->{VlanTags}) eq 'ARRAY'
            && scalar(@{$device_info->{VlanTags}}) == 0);

    $device_list = $t->network_device_list();
    $check_vlan_tag
        &&= (!grep { $_->{DevName} eq "$GMS_TEST_IFACE.$vlan_number" }
            @$device_list);

    ok($check_vlan_tag, "Verify reset VLAN Tag");
};

subtest 'bonding_api' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $test_bond = $t->network_bonding_create(
        slave  => [$GMS_TEST_IFACE],
        mode   => 0,
        mtu    => 1500,
        active => 'on'
    );

    sleep $application_wait;

    my $bond_list = $t->network_bonding_list();

    my $find_flag = 0;

    foreach my $each_bond (@{$bond_list})
    {
        if ($each_bond->{DevName} eq $test_bond)
        {
            $find_flag = 1;
            last;
        }
    }

    ok($find_flag, 'bonding create check');

    $t->network_bonding_update(
        bondname => $test_bond,
        primary  => $GMS_TEST_IFACE,
        slave    => [$GMS_TEST_IFACE],
        mode     => 1,
        mtu      => 2000,
        active   => 'off'
    );

    sleep $application_wait;

    my $bond_info = $t->network_bonding_info(bondname => $test_bond);

    is($bond_info->{PrimarySlave},
        $GMS_TEST_IFACE, "Verify updated PimarySlave");
    is($bond_info->{Mode},   1,     "Verify updated Mode");
    is($bond_info->{MTU},    2000,  "Verify updated MTU");
    is($bond_info->{Active}, 'off', "Verify updated Active");

    $t->network_bonding_delete(bondname => $test_bond);

    sleep $application_wait;

    $bond_list = $t->network_bonding_list();

    $find_flag = 0;

    foreach my $each_bond (@{$bond_list})
    {
        if ($each_bond->{DevName} eq $test_bond)
        {
            $find_flag = 1;
            last;
        }
    }

    ok(!$find_flag, 'bonding delete check');
};

subtest 'address_api' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $created_addr = $TEST_IP_POOL[rand($POOL_SIZE)];

    $t->network_address_create(
        devname => $GMS_TEST_IFACE,
        ipaddr  => $created_addr,
        netmask => '255.255.255.0',
        active  => 'on'
    );

    sleep $application_wait;

    my $addr_list = $t->network_address_list();

    my $test_addr;
    my $find_flag = 0;

    foreach my $each_addr (@{$addr_list})
    {
        if ($each_addr->{IPaddr} eq $created_addr
            && $each_addr->{Netmask} eq '255.255.255.0'
            && $each_addr->{Iface} eq $GMS_TEST_IFACE)
        {
            $find_flag = 1;
            $test_addr = $each_addr->{AddrName};
            last;
        }
    }

    ok($find_flag, 'address create check');

    my $updated_addr;

    do
    {
        $updated_addr = $TEST_IP_POOL[rand($POOL_SIZE)];
    } while ($POOL_SIZE != 1 && $created_addr eq $updated_addr);

    $t->network_address_update(
        addrname => $test_addr,
        ipaddr   => $updated_addr,
        netmask  => '255.255.252.0',
        gateway  => $TEST_IP_POOL[0],
        active   => 'on'
    );

    sleep $application_wait;

    $t->network_address_delete(addrname => $test_addr);

    sleep $application_wait;

    $addr_list = $t->network_address_list();

    $find_flag = 0;

    foreach my $each_addr (@{$addr_list})
    {
        if ($each_addr->{IPaddr} eq $updated_addr
            && $each_addr->{Netmask} eq '255.255.252.0'
            && $each_addr->{Iface} eq $GMS_TEST_IFACE
            && $each_addr->{Gateway} eq $TEST_IP_POOL[0])
        {
            $find_flag = 1;
            last;
        }
    }

    ok(!$find_flag, 'address delete check');
};

subtest 'service_address_pool_api' => sub
{
    my $t = Test::AnyStor::ClusterAddress->new(addr => $GMS_TEST_ADDR);

    my $ip_pool_max_idx = $POOL_SIZE - 1;

    $t->cluster_svc_addr_create(
        interface => $GMS_TEST_IFACE,
        start     => $TEST_IP_POOL[0],
        end       => $TEST_IP_POOL[$ip_pool_max_idx / 2],
        netmask   => '255.255.255.0'
    );

    my $svc_pool_list = $t->cluster_svc_addr_list();

    my $find_flag = 0;

    foreach my $each_svc_pool (@{$svc_pool_list})
    {
        if ($each_svc_pool->{interface} eq $GMS_TEST_IFACE
            && $each_svc_pool->{start} eq $TEST_IP_POOL[0]
            && $each_svc_pool->{end} eq $TEST_IP_POOL[$ip_pool_max_idx / 2]
            && $each_svc_pool->{netmask} eq '255.255.255.0')
        {
            $find_flag = 1;
            last;
        }
    }

    ok($find_flag, 'service address pool create check');

    $t->cluster_svc_addr_update(
        old_interface => $GMS_TEST_IFACE,
        old_start     => $TEST_IP_POOL[0],
        old_end       => $TEST_IP_POOL[$ip_pool_max_idx / 2],
        old_netmask   => '255.255.255.0',
        new_interface => $GMS_TEST_IFACE,
        new_start     => $TEST_IP_POOL[0],
        new_end       => $TEST_IP_POOL[$ip_pool_max_idx],
        new_netmask   => '255.255.252.0'
    );

    $svc_pool_list = $t->cluster_svc_addr_list();

    $find_flag = 0;

    foreach my $each_svc_pool (@{$svc_pool_list})
    {
        if ($each_svc_pool->{interface} eq $GMS_TEST_IFACE
            && $each_svc_pool->{start} eq $TEST_IP_POOL[0]
            && $each_svc_pool->{end} eq $TEST_IP_POOL[$ip_pool_max_idx]
            && $each_svc_pool->{netmask} eq '255.255.252.0')
        {
            $find_flag = 1;
            last;
        }
    }

    ok($find_flag, 'service address pool update check');

    $t->cluster_svc_addr_delete(
        interface => $GMS_TEST_IFACE,
        start     => $TEST_IP_POOL[0],
        end       => $TEST_IP_POOL[$ip_pool_max_idx],
        netmask   => '255.255.252.0'
    );

    $svc_pool_list = $t->cluster_svc_addr_list();

    $find_flag = 0;

    foreach my $each_svc_pool (@{$svc_pool_list})
    {
        if ($each_svc_pool->{interface} eq $GMS_TEST_IFACE
            && $each_svc_pool->{start} eq $TEST_IP_POOL[0]
            && $each_svc_pool->{end} eq $TEST_IP_POOL[$ip_pool_max_idx]
            && $each_svc_pool->{netmask} eq '255.255.252.0')
        {
            $find_flag = 1;
            last;
        }
    }

    ok(!$find_flag, 'service address pool delete check');
};

=pod

subtest 'cluster_route_api' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $from = $t->get_ts_from_server() if( $event_check );

    my $created_dest = $TEST_IP_POOL[rand($POOL_SIZE)];
    $t->cluster_network_route_create(
        devname => $GMS_TEST_IFACE,
        netmask => '255.255.255.0',
        destination => $created_dest
    );

    my $route_list = $t->cluster_network_route_list();

    my $find_flag = 0;
    foreach my $each_route (@$route_list)
    {
        if( $each_route->{DevName} eq $GMS_TEST_IFACE 
            && $each_route->{Netmask} eq '255.255.255.0'
            && $each_route->{Destination} eq $created_dest )
        {
            $find_flag = 1; 
            last;
        };
    }
    ok($find_flag, 'cluster route create check');

    my $updated_dest;
    do
    {
        $updated_dest = $TEST_IP_POOL[rand($POOL_SIZE)];
    }
    while( $POOL_SIZE != 1 && $created_dest eq $updated_dest );

    $t->cluster_network_route_update(
        old_devname => $GMS_TEST_IFACE,
        old_netmask => '255.255.255.0',
        old_destination => $created_dest,
        new_devname => $GMS_TEST_IFACE,
        new_netmask => '255.255.252.0',
        new_destination => $updated_dest
    );

    $route_list = $t->cluster_network_route_list();

    $find_flag = 0;
    foreach my $each_route (@$route_list)
    {
        if( $each_route->{DevName} eq $GMS_TEST_IFACE 
            && $each_route->{Netmask} eq '255.255.252.0'
            && $each_route->{Destination} eq $updated_dest )
        {
            $find_flag = 1; 
            last;
        };
    }
    ok($find_flag, 'cluster route update check');

    $t->cluster_network_route_delete( 
        devname => $GMS_TEST_IFACE,
        netmask => '255.255.252.0',
        destination => $updated_dest,
    );

    $route_list = $t->cluster_network_route_list();

    $find_flag = 0;
    foreach my $each_route (@$route_list)
    {
        if( $each_route->{DevName} eq $GMS_TEST_IFACE 
            && $each_route->{Netmask} eq '255.255.252.0'
            && $each_route->{Destination} eq $updated_dest )
        {
            $find_flag = 1; 
            last;
        };
    }
    ok(!$find_flag, 'cluster route delete check');

};

=cut

subtest 'cluster_dns_api' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $dns_info = $t->cluster_network_dns_info();

    my $old_dns = $dns_info->{nameserver};

    $t->cluster_network_dns_update(dns => ['8.8.8.8']);

    $dns_info = $t->cluster_network_dns_info();

    is($dns_info->{nameserver}->[0], '8.8.8.8', "Verify updated dns");

    if (defined($old_dns) && scalar(@{$old_dns}))
    {
        $t->cluster_network_dns_update(dns => [@{$old_dns}]);
    }

};

subtest 'cluster_zone_api' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $created_zoneip = $TEST_IP_POOL[rand($POOL_SIZE)];

    $t->cluster_network_zone_create(
        zonename    => 'network_function_test',
        description => 'for test',
        type        => 'ip',
        zoneip      => $created_zoneip
    );

    my $zone_list = $t->cluster_network_zone_list();

    my $find_flag = 0;

    foreach my $each_zone (@{$zone_list})
    {
        if ($each_zone->{ZoneName} eq 'network_function_test')
        {
            $find_flag = 1;
            last;
        }
    }

    ok($find_flag, 'zone create check');

    $t->cluster_network_zone_delete(zonename => 'network_function_test');

    $zone_list = $t->cluster_network_zone_list();

    $find_flag = 0;

    foreach my $each_zone (@{$zone_list})
    {
        if ($each_zone->{ZoneName} eq 'network_function_test')
        {
            $find_flag = 1;
            last;
        }
    }

    ok(!$find_flag, 'zone delete check');
};

done_testing();
