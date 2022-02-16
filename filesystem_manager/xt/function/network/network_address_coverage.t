#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Address Network API가 ethernet과 bond를 모두 관리할 수 있는지 검사함";

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Network;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_TEST_IFACE} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $GMS_TEST_IFACE = $ENV{GMS_TEST_IFACE};

my $verbose = 0;
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
    my @addr_split = split(/\./, $addr);

    for (my $class = 0; $class < 4; $class++)
    {
        $decimal_addr += ($addr_split[3-$class] << (8 * $class));
    }

    return $decimal_addr;
}

sub dec_to_addr
{
    my $decimal_addr = shift;

    my @addr_split = (
        ($decimal_addr & 255*256*256*256) >> 24,
        ($decimal_addr & 255*256*256) >> 16,
        ($decimal_addr & 255*256) >> 8,
        ($decimal_addr & 255) >> 0
    );

    return join('.', @addr_split);
}

subtest 'make_test_ip_pool' => sub
{
    my $dec_pool_start = addr_to_dec($TEST_IP_POOL_START);
    my $dec_pool_end   = addr_to_dec($TEST_IP_POOL_END);

    for (my $dec_addr = $dec_pool_start
        ; $dec_addr <= $dec_pool_end
        ; $dec_addr++)
    {
        push(@TEST_IP_POOL, dec_to_addr($dec_addr));
    }

    $POOL_SIZE = scalar(@TEST_IP_POOL);

    ok(1, "Test ip pool has been created (size: $POOL_SIZE, range: $TEST_IP_POOL_START ~ $TEST_IP_POOL_END)");
};

my $vlan_number = 100;

subtest "initialize test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname   => $GMS_TEST_IFACE,
        mtu       => 1500,
        active    => 'off',
        vlan_tags => [ $vlan_number ]
    );
};

subtest 'Address API: ethernet cover test' => sub
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
        };
    }

    ok($find_flag, 'address create check');

    $t->network_address_delete(addrname => $test_addr);
};

subtest 'Address API: VLAN tagged ethernet cover test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $eth_vlan_tagged = "$GMS_TEST_IFACE.$vlan_number";
    my $created_addr    = $TEST_IP_POOL[rand($POOL_SIZE)];

    $t->network_address_create(
        devname => $eth_vlan_tagged,
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
            && $each_addr->{Iface} eq $eth_vlan_tagged)
        {
            $find_flag = 1;
            $test_addr = $each_addr->{AddrName};
            last;
        };
    }

    ok($find_flag, 'address create check');

    $t->network_address_delete(addrname => $test_addr);
};

my $test_bond;

subtest 'initialize test bond' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $test_bond = $t->network_bonding_create(
        slave  => [ $GMS_TEST_IFACE ],
        mode   => 0,
        mtu    => 1500,
        active => 'off'
    );
};

subtest 'Address API: bond cover test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    my $created_addr = $TEST_IP_POOL[rand($POOL_SIZE)];

    $t->network_address_create(
        devname => $test_bond,
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
            && $each_addr->{Iface} eq $test_bond)
        {
            $find_flag = 1;
            $test_addr = $each_addr->{AddrName};
            last;
        };
    }

    ok($find_flag, 'address create check');

    $t->network_address_delete(addrname => $test_addr);
};

subtest 'reset test bond' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_bonding_delete(bondname => $test_bond);
};

subtest "reset test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname   => $GMS_TEST_IFACE,
        mtu       => 1500,
        active    => 'off',
        vlan_tags => []
    );
};

done_testing();
