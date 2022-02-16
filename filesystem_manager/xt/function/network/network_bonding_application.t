#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Network Bonding API가 변경한 내용이 시스템에 적용되는지 확인하는 테스트";

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

my $test_bond;

subtest 'initialize test bond' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $test_bond = $t->network_bonding_create(
        slave  => [ $GMS_TEST_IFACE ],
        mode   => 0,
        mtu    => 1500,
        active => 'on'
    );
};

subtest 'Bonding API: created bonding application test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /BONDING_OPTS/)
            {
                $applied_value = 'BONDING';
                last;
            }
        }

        is($applied_value, 'BONDING'
            , "created bonding permanent apply check(master)");

        $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        @lines = split(/\n/, $diagnosis);

        $applied_value = '';

        foreach my $line (@lines)
        {
            if ($line =~ /SLAVE/)
            {
                $applied_value = $line.' &'.$applied_value;
            }

            if( $line =~ /MASTER/)
            {
                $applied_value = $applied_value.'& '.$line;
            }
        }

        is($applied_value, "SLAVE=yes && MASTER=$test_bond"
            , "created bonding permanent apply check(slave)");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /MASTER/)
            {
                if ($line =~ /UP/)
                {
                    $applied_value = 'UP &';
                }

                $applied_value = $applied_value.'& MASTER';
                last;
            }
        }

        is($applied_value, 'UP && MASTER'
            , "created bonding run-time apply check(master)");

        $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        @lines = split(/\n/, $diagnosis);

        foreach my $line (@lines)
        {
            if ($line =~ /SLAVE/)
            {
                if ($line =~ /UP/)
                {
                    $applied_value = 'UP &';
                }

                $applied_value = $applied_value.'& SLAVE';
                last;
            }
        }

        is($applied_value, 'UP && SLAVE'
            , "created bonding run-time apply check(slave)");
    };
};

subtest 'Bonding API: bonding mode application test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_bonding_update(
        bondname => $test_bond,
        slave    => [ $GMS_TEST_IFACE ],
        mode     => 1,
        mtu      => 1500,
        active   => 'on'
    );

    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /BONDING_OPTS/)
            {
                my $bond_opts = $line;

                $bond_opts =~ s/BONDING_OPTS=//;
                $bond_opts =~ s/^'|'$//g;

                my @array_bond_opts = split(/[ ]+/, $bond_opts);

                foreach my $opt (@array_bond_opts)
                {
                    if ($opt =~ /mode/)
                    {
                        $applied_value = $opt;
                        last;
                    }
                }

                last;
            }
        }

        is($applied_value, 'mode=1', "bonding mode permanent apply check(master)");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat /sys/class/net/$test_bond/bonding/mode"`;
        chomp($diagnosis);

        my @columns = split(/ /, $diagnosis);

        my $applied_value = $columns[1];

        is($applied_value, 1, "bonding mode run-time apply check(master)");
    };
};

subtest 'Bonding API: primary slave application test (Bond)' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_bonding_update(
        bondname => $test_bond,
        primary  => $GMS_TEST_IFACE,
        slave    => [ $GMS_TEST_IFACE ],
        mode     => 1,
        mtu      => 1500,
        active   => 'on'
    );

    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $applied_value;

        foreach my $line (@lines)
        {
            if ($line =~ /BONDING_OPTS/)
            {
                my $bond_opts = $line;

                $bond_opts =~ s/BONDING_OPTS=//;
                $bond_opts =~ s/^'|'$//g;

                my @array_bond_opts = split(/[ ]+/, $bond_opts);

                foreach my $opt (@array_bond_opts)
                {
                    if ($opt =~ /primary/)
                    {
                        $applied_value = $opt;
                        last;
                    }
                }

                last;
            }
        }

        is($applied_value, "primary=$GMS_TEST_IFACE"
            , "bonding primary permanent apply check(master)");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat /sys/class/net/$test_bond/bonding/primary"`;
        chomp($diagnosis);

        my $applied_value = $diagnosis;

        is($applied_value, $GMS_TEST_IFACE
            , "bonding primary run-time apply check(master)");
    };
};

subtest 'reset test bond' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    $t->network_bonding_delete(bondname => $test_bond);
    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        ok(! -e "$SCRIPT_DIR/ifcfg-$test_bond"
            , "deleted bonding permanent apply check(master)");

        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $check_flag = 0;

        foreach my $line (@lines)
        {
            if ($line =~ /SLAVE/)
            {
                $check_flag++;
            }
            elsif ($line =~ /MASTER/)
            {
                $check_flag++;
            }
            elsif ($line =~ /ONBOOT/)
            {
                $check_flag++ if ($line ne 'ONBOOT=no');
            }
        }

        ok(!$check_flag, "deleted bonding permanent apply check(slave)");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $is_running = 0;

        foreach my $line (@lines)
        {
            if ($line =~ /RUNNING/)
            {
                $is_running++;
                last;
            }
        }

        ok(!$is_running, "deleted bonding run-time apply check(master)");

        $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        @lines = split(/\n/, $diagnosis);

        my $is_slave = 0;

        foreach my $line (@lines)
        {
            if ($line =~ /SLAVE/)
            {
                $is_slave++;
                last;
            }
        }

        ok(!$is_slave, "deleted bonding run-time apply check(slave)");
    };
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
