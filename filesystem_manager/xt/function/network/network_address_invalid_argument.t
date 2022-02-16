#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Network Address API가 변경한 내용이 시스템에 적용되는지 확인하는 테스트";

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

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

if (!defined($GMS_TEST_ADDR) || !defined($GMS_TEST_IFACE))
{
    ok(0, 'argument missing');
    return 1;
}

my $invalid_addr = '192.236.-34.1';
my $invalid_netmask = '255.123.0.2';

subtest "initialize test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'off'
    );
};

subtest 'Address API: invalid input test when address creating' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $return = $t->network_address_create(
        devname      => $GMS_TEST_IFACE,
        ipaddr       => $invalid_addr,
        netmask      => '255.255.255.0',
        active       => 'off',
        return_false => 1
    );

    ok($return == 1,
        "check if invalid 'IPaddr'($invalid_addr) input is denied");

    if ($return =~ /^\w+\d+$/)
    {
        $t->network_address_delete(addrname => $return);
    }

    $return = $t->network_address_create(
        devname      => $GMS_TEST_IFACE,
        ipaddr       => '100.0.0.1',
        netmask      => $invalid_netmask,
        active       => 'off',
        return_false => 1
    );

    ok($return == 1,
        "check if invalid 'Netmask'($invalid_netmask) input is denied");

    if ($return =~ /^\w+\d+$/)
    {
        $t->network_address_delete(addrname => $return);
    }
};

subtest 'Address API: invalid input test when address updating' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $target_addr = $t->network_address_create(
        devname => $GMS_TEST_IFACE,
        ipaddr  => '100.0.0.1',
        netmask => '255.255.255.0',
        active  => 'off',
    );

    my $return = $t->network_address_update(
        addrname     => $target_addr,
        ipaddr       => $invalid_addr,
        netmask      => '255.255.255.0',
        return_false => 1
    );

    ok($return == 1,
        "check if invalid 'IPaddr'($invalid_addr) input is denied");

    $return = $t->network_address_update(
        addrname     => $target_addr,
        ipaddr       => '100.0.0.1',
        netmask      => $invalid_netmask,
        return_false => 1
    );

    ok($return == 1,
        "check if invalid 'Netmask'($invalid_netmask) input is denied");

    $t->network_address_delete(addrname => $target_addr);
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
