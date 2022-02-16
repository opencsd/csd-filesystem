#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Network Bonding API가 필수 bonding의 수정/삭제를 방지 하는지 확인하는 테스트";

use strict;
use warnings;
use utf8;

use Env;
use Test::Most;
use Test::AnyStor::Network;

use Encode  qw/decode_utf8/;
use JSON    qw/decode_json/;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_TEST_IFACE} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $GMS_TEST_IFACE = $ENV{GMS_TEST_IFACE};

my $verbose = 0;

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

if (!defined($GMS_TEST_ADDR) || !defined($GMS_TEST_IFACE))
{
    ok(0, 'argument missing');
    return 1;
}

subtest 'get Cluster Info' => sub
{
    my $out = `ssh $test_addr "etcdctl get /ClusterInfo"`;

    $ci = decode_json(decode_utf8($out));

    ok(defined($ci), 'get /ClusterInfo from cluster database');
};

my $storage_iface;

subtest 'find storage interface' => sub
{
    $storage_iface = 'bond0';
    ok(defined($storage_iface), "get storage interface: $storage_iface");
};

subtest 'storage interface protect test' => sub
{
    subtest 'config update protect test' => sub
    {
        my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
        my $bond_info = $t->network_bonding_info(bondname => $storage_iface);

        my $primary = $bond_info->{PrimarySlave};

        if ($primary eq 'None')
        {
            undef $primary;
        }

        my @slave;

        foreach my $each_slave (@{$bond_info->{Slave}})
        {
            push(@slave, $each_slave->{Device});
        }

        my $mode   = $bond_info->{Mode};
        my $mtu    = $bond_info->{MTU};
        my $active = $bond_info->{Active};

        my $result = $t->network_bonding_update(
            bondname     => $storage_iface,
            primary      => $primary,
            slave        => @slave,
            mode         => $mode,
            mtu          => $mtu+1000,
            active       => $active,
            return_false => 1
        );

        ok($result, "storage interface protect test(config update)");
    };

    subtest 'address update protect test' => sub
    {
        my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

        my $addr_list = $t->network_address_list();

        my $storage_addr;

        foreach my $each_addr (@{$addr_list})
        {
            if ($each_addr->{Iface} eq $storage_iface)
            {
                $storage_addr = $each_addr->{AddrName};
                last;
            };
        }

        my $result = $t->network_address_update(
            addrname     => $storage_addr,
            ipaddr       => '55.0.0.5',
            netmask      => '255.255.255.0',
            active       => 'on',
            return_false => 1
        );

        ok($result, "storage interface protect test(address update)");
    };

    subtest 'delete protect test' => sub
    {
        my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

        my $result = $t->network_bonding_delete(
            bondname     => $storage_iface,
            return_false => 1
        );

        ok($result, "storage interface protect test(delete)");
    };

    ok(1, "storage interface protect test");
};

done_testing();
