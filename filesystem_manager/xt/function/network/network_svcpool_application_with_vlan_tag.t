#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY   = 'cpan:gluesys';
our $DESCRIPTOIN = "Cluster Service pool API가 변경한 내용이 시스템에 적용되는지 확인하는 테스트(with vtag)";

use strict;
use warnings;
use utf8;

use Env;
use Test::Most;
use Test::AnyStor::Network;
use Test::AnyStor::ClusterAddress;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_TEST_IFACE} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $GMS_TEST_IFACE = $ENV{GMS_TEST_IFACE};
my $vlan_number = 100;

my $verbose = 0;

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my $TEST_IP_POOL_START = '100.0.0.1';
my $TEST_IP_POOL_END   = '100.0.0.10';

my @TEST_IP_POOL;
my $POOL_SIZE;

my $SCRIPT_FILE = '/mnt/private/CTDB/public_addresses';

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

sub get_maskbit
{
    my $str_netmask = shift;
    my $dex_netmask = addr_to_dec($str_netmask);

    my $maskbit = 32;

    while ($maskbit > 0)
    {
        if ($dex_netmask % 2)
        {
            last;
        }
        else
        {
            $dex_netmask =  $dex_netmask / 2;
            $maskbit--;
        }
    }

    return $maskbit;
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

subtest "initialize test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'on'
    );
};

subtest 'Cluster Serivce Address API: created service pool application test' => sub
{
    my $t = Test::AnyStor::ClusterAddress->new(addr => $GMS_TEST_ADDR);

    my $ip_pool_max_idx = $POOL_SIZE - 1;

    $t->cluster_svc_addr_create(
        interface => "$GMS_TEST_IFACE.$vlan_number",
        start     => $TEST_IP_POOL[0],
        end       => $TEST_IP_POOL[$ip_pool_max_idx/2],
        netmask   => '255.255.255.0',
    );

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_FILE"`;
        my @lines = split(/\n/, $diagnosis);

        my %svc_addr_pool;

        foreach my $line (@lines)
        {
            (my $tmp, my $svc_interface) = split(/[ ]+/, $line);
            (my $svc_addr, my $svc_mask) = split(/\//, $tmp);

            $svc_addr_pool{$svc_addr} = 1;
        }

        my $check_flag = 1;

        for (my $idx = 0; $idx <= $ip_pool_max_idx/2; $idx++)
        {
            my $check_addr = $TEST_IP_POOL[$idx];

            if (!defined($svc_addr_pool{$check_addr}))
            {
                $check_flag = 0;
                last;
            }
        }

        ok($check_flag, "created service pool permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ctdb ip"`;
        my @lines = split(/\n/, $diagnosis);

        my %svc_addr_pool;

        foreach my $line (@lines)
        {
            (my $svc_addr, undef) = split(/[ ]+/, $line);
            $svc_addr_pool{$svc_addr} = 1;
        }

        my $check_flag = 1;

        for (my $idx = 0; $idx <= $ip_pool_max_idx/2; $idx++)
        {
            my $check_addr = $TEST_IP_POOL[$idx];

            if (!defined($svc_addr_pool{$check_addr}))
            {
                $check_flag = 0;
                last;
            }
        }

        ok($check_flag, "created service pool run-time apply check");
    };
};

subtest 'Cluster Serivce Address API: expanded service pool application test' => sub
{
    my $t = Test::AnyStor::ClusterAddress->new(addr => $GMS_TEST_ADDR);

    my $ip_pool_max_idx = $POOL_SIZE - 1;

    $t->cluster_svc_addr_update(
        old_interface => "$GMS_TEST_IFACE.$vlan_number",
        old_start     => $TEST_IP_POOL[0],
        old_end       => $TEST_IP_POOL[$ip_pool_max_idx/2],
        old_netmask   => '255.255.255.0',
        new_interface => "$GMS_TEST_IFACE.$vlan_number",
        new_start     => $TEST_IP_POOL[0],
        new_end       => $TEST_IP_POOL[$ip_pool_max_idx],
        new_netmask   => '255.255.255.0'
    );

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_FILE"`;
        my @lines = split(/\n/, $diagnosis);

        my %svc_addr_pool;

        foreach my $line (@lines)
        {
            (my $tmp, my $svc_interface) = split(/[ ]+/, $line);
            (my $svc_addr, my $svc_mask) = split(/\//, $tmp);

            $svc_addr_pool{$svc_addr} = 1;
        }

        my $check_flag = 1;

        for (my $idx = 0; $idx <= $ip_pool_max_idx; $idx++)
        {
            my $check_addr = $TEST_IP_POOL[$idx];

            if (!defined($svc_addr_pool{$check_addr}))
            {
                $check_flag = 0;
                last;
            }
        }

        ok($check_flag, "expanded service pool permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ctdb ip"`;
        my @lines = split(/\n/, $diagnosis);

        my %svc_addr_pool;

        foreach my $line (@lines)
        {
            (my $svc_addr, undef) = split(/[ ]+/, $line);
            $svc_addr_pool{$svc_addr} = 1;
        }

        my $check_flag = 1;

        for (my $idx = 0; $idx <= $ip_pool_max_idx; $idx++)
        {
            my $check_addr = $TEST_IP_POOL[$idx];

            if (!defined($svc_addr_pool{$check_addr}))
            {
                $check_flag = 0;
                last;
            }
        }

        ok($check_flag, "expanded service pool run-time apply check");
    };
};

subtest 'Cluster Serivce Address API: deleted service pool application test' => sub
{
    my $t = Test::AnyStor::ClusterAddress->new(addr => $GMS_TEST_ADDR);

    my $ip_pool_max_idx = $POOL_SIZE - 1;

    $t->cluster_svc_addr_delete(
        interface => "$GMS_TEST_IFACE.$vlan_number",
        start     => $TEST_IP_POOL[0],
        end       => $TEST_IP_POOL[$ip_pool_max_idx],
        netmask   => '255.255.255.0'
    );

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_FILE"`;
        my @lines = split(/\n/, $diagnosis);

        my %svc_addr_pool;

        foreach my $line (@lines)
        {
            (my $tmp, my $svc_interface) = split(/[ ]+/, $line);
            (my $svc_addr, my $svc_mask) = split(/\//, $tmp);

            $svc_addr_pool{$svc_addr} = 1;
        }

        my $find_flag = 0;

        for (my $idx = 0; $idx <= $ip_pool_max_idx; $idx++)
        {
            my $check_addr = $TEST_IP_POOL[$idx];

            if (defined($svc_addr_pool{$check_addr}))
            {
                $find_flag = 1;
                last;
            }
        }

        ok(!$find_flag, "deleted service pool permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ctdb ip"`;
        my @lines = split(/\n/, $diagnosis);

        my %svc_addr_pool;

        foreach my $line (@lines)
        {
            (my $svc_addr, undef) = split(/[ ]+/, $line);
            $svc_addr_pool{$svc_addr} = 1;
        }

        my $find_flag = 0;

        for (my $idx = 0; $idx <= $ip_pool_max_idx; $idx++)
        {
            my $check_addr = $TEST_IP_POOL[$idx];

            if (defined($svc_addr_pool{$check_addr}))
            {
                $find_flag = 1;
                last;
            }
        }

        ok(!$find_flag, "deleted service pool run-time apply check");
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
