#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Device Network API가 ethernet과 bond를 모두 관리 할 수 있는지 검사함";

use strict;
use warnings;
use utf8;

use Env;
use Test::Most;
use Test::AnyStor::Network;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_TEST_IFACE} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $GMS_TEST_IFACE = $ENV{GMS_TEST_IFACE};

my $verbose = 0;
my $application_wait = 3;

if (!defined($GMS_TEST_ADDR) || !defined($GMS_TEST_IFACE))
{
    ok(0, 'argument missing');
    return 1;
}

subtest "initialize test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'off'
    );
};

subtest 'Device API: ethernet cover test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 2000,
        active  => 'on'
    );

    sleep $application_wait;

    my $device_info = $t->network_device_info(devname => $GMS_TEST_IFACE);

    is($device_info->{MTU}, 2000, "Verify updated MTU");
    is($device_info->{Active}, 'on', "Verify updated Active");
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

subtest 'Device API: bond cover test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $test_bond,
        mtu     => 2000,
        active  => 'on'
    );

    sleep $application_wait;

    my $device_info = $t->network_device_info(devname => $test_bond);

    is($device_info->{MTU}, 2000, "Verify updated MTU");
    is($device_info->{Active}, 'on', "Verify updated Active");
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
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'off'
    );
};

done_testing();
