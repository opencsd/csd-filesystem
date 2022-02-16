#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Network Device API가 변경한 내용이 시스템에 적용되는지 확인하는 테스트";

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

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my $SCRIPT_DIR = '/etc/sysconfig/network-scripts';

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

subtest 'Device API: MTU application test (Ethernet)' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 2000,
        active  => 'off'
    );

    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /MTU/)
            {
                $applied_value = $line;
                last;
            }
        }

        is($applied_value, 'MTU=2000', "MTU permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /\<[\w|,]+\>\s+mtu (?<mtu>\d+)/)
            {
                # NOTE: $each_info is like below
                # "$each_dev: flags=##<FLAG1,FLAG2,...>  mtu ###"
                $applied_value = 'MTU:'.$+{mtu};
                last;
            }
        }

        is($applied_value, 'MTU:2000', "MTU run-time apply check");
    };
};

subtest 'Device API: Active application test (Ethernet)' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'on'
    );

    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /ONBOOT/)
            {
                $applied_value = $line;
                last;
            }
        }

        is($applied_value, 'ONBOOT=yes', "Active permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /UP/)
            {
                $applied_value = 'UP';
                last;
            }
        }

        is($applied_value, 'UP', "Active run-time apply check");
    };
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

subtest 'Device API: MTU application test (Bond)' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $test_bond,
        mtu     => 2000,
        active  => 'off'
    );

    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /MTU/)
            {
                $applied_value = $line;
                last;
            }
        }

        is($applied_value, 'MTU=2000', "MTU permanent apply check(master)");

        $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        @lines = split(/\n/, $diagnosis);

        foreach my $line (@lines)
        {
            if ($line =~ /MASTER/)
            {
                $applied_value = $line;
                last;
            }
        }

        is($applied_value, "MASTER=$test_bond", "MTU permanent apply check(slave)");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /\<[\w|,]+\>\s+mtu (?<mtu>\d+)/)
            {
                # NOTE: $each_info is like below
                # "$each_dev: flags=##<FLAG1,FLAG2,...>  mtu ###"
                $applied_value = 'MTU:'.$+{mtu};
                last;
            }
        }

        is($applied_value, 'MTU:2000', "MTU run-time apply check(master)");

        $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        @lines = split(/\n/, $diagnosis);

        foreach my $line (@lines)
        {
            if ($line =~ /\<[\w|,]+\>\s+mtu (?<mtu>\d+)/)
            {
                # NOTE: $each_info is like below
                # "$each_dev: flags=##<FLAG1,FLAG2,...>  mtu ###"
                $applied_value = 'MTU:'.$+{mtu};
                last;
            }
        }

        is($applied_value, 'MTU:2000', "MTU run-time apply check(slave)");
    };
};

subtest 'Device API: Active application test (Bond)' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $test_bond,
        mtu     => 1500,
        active  => 'on'
    );

    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /ONBOOT/)
            {
                $applied_value = $line;
                last;
            }
        }

        is($applied_value, 'ONBOOT=yes', "Active permanent apply check(master)");

        $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        @lines = split(/\n/, $diagnosis);

        foreach my $line (@lines)
        {
            if ($line =~ /ONBOOT/)
            {
                $applied_value = $line;
                last;
            }
        }

        is($applied_value, 'ONBOOT=yes', "Active permanent apply check(slave)");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /UP/)
            {
                $applied_value = 'UP';
                last;
            }
        }

        is($applied_value, 'UP', "Active run-time apply check(master)");

        $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        @lines = split(/\n/, $diagnosis);

        foreach my $line (@lines)
        {
            if ($line =~ /UP/)
            {
                $applied_value = 'UP';
                last;
            }
        }

        is($applied_value, 'UP', "Active run-time apply check(slave)");
    };
};

subtest 'reset test bond' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_bonding_delete(bondname => $test_bond);

    sleep $application_wait;
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
