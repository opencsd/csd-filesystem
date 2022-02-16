#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Network route API가 변경한 default gateway 내용이 시스템에 적용되는지 확인하는 테스트";

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

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my $TEST_IP_POOL_START = '55.0.0.1';
my $TEST_IP_POOL_END   = '55.0.0.10';

my @TEST_IP_POOL;
my $POOL_SIZE;

my $SCRIPT_DIR = '/etc/sysconfig/network-scripts';

my $disable = 1;

if ($disable)
{
    ok(1, 'default_gateway_aplication_test is skipped');
    done_testing();
    exit 0;
}

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

my $created_addr;

subtest "initialize test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'on'
    );

    $created_addr = $TEST_IP_POOL[rand($POOL_SIZE)];

    $t->network_address_create(
        devname => $GMS_TEST_IFACE,
        ipaddr  => $created_addr,
        netmask => '255.255.255.0',
        active  => 'on'
    );
};

my $test_gateway = $TEST_IP_POOL[0];

subtest 'Network route API: default gateway application test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $test_gateway = $TEST_IP_POOL[0];

    $t->cluster_network_route_create(
        devname     => $GMS_TEST_IFACE,
        netmask     => '255.255.255.0',
        destination => $GMS_TEST_IFACE,
        gateway     => $test_gateway
    );

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/route-$GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            my $value;

            last if ($find_flag == 3);

            if ($line =~ /ADDRESS/)
            {
                $value = $line;
                $value =~ s/ADDRESS\d+=//;

                if ($value eq '0.0.0.0')
                {
                    $find_flag++;
                }
                elsif ($find_flag > 0)
                {
                    $find_flag = 0;
                }
            }

            if ($line =~ /NETMASK/)
            {
                $value = $line;
                $value =~ s/NETMASK\d+=//;

                if ($value eq '0.0.0.0')
                {
                    $find_flag++;
                }
                elsif ($find_flag > 0)
                {
                    $find_flag = 0;
                }
            }

            if ($line =~ /GATEWAY/)
            {
                $value = $line;
                $value =~ s/GATEWAY\d+=//;

                if ($value eq $test_gateway)
                {
                    $find_flag++;
                }
                elsif ($find_flag > 0)
                {
                    $find_flag = 0;
                }
            }
        }

        ok($find_flag, "default gateway permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "route"`;
        my @lines     = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            (my $dest_net_id, my $gateway, my $netmask
                , undef, undef, undef, undef, my $iface)
                    = split(/[ ]+/, $line);

            if ($dest_net_id eq 'default'
                && $gateway eq $test_gateway
                && $netmask eq '0.0.0.0'
                && $iface eq $GMS_TEST_IFACE)
            {
                $find_flag++;
                last;
            }
        }

        ok($find_flag, "default gateway run-time apply check");
    };
};

subtest 'Network route API: reset default gateway' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_route_delete(
        devname     => $GMS_TEST_IFACE,
        netmask     => '255.255.255.0',
        destination => $GMS_TEST_IFACE,
        gateway     => $test_gateway
    );

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ls -l $SCRIPT_DIR"`;
        my @lines     = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            if ($line =~ /route-$GMS_TEST_IFACE/)
            {
                $find_flag++;
                last;
            }
        }

        ok(!$find_flag , "deleted service pool permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "route"`;
        my @lines     = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            (my $dest_net_id, my $gateway, my $netmask
                , undef, undef, undef, undef
                , my $iface)
                    = split(/[ ]+/, $line);

            if ($dest_net_id eq 'default'
                && $gateway eq $test_gateway
                && $netmask eq '0.0.0.0'
                && $iface eq $GMS_TEST_IFACE)
            {
                $find_flag++;
                last;
            }
        }

        ok(!$find_flag, "deleted service pool run-time apply check");
    };
};

subtest "reset test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $addr_list = $t->network_address_list();

    my $target_addr;

    foreach my $each_addr (@{$addr_list})
    {
        if ($each_addr->{IPaddr} eq $created_addr
            && $each_addr->{Netmask} eq '255.255.255.0'
            && $each_addr->{Iface} eq $GMS_TEST_IFACE)
        {
            $target_addr = $each_addr->{AddrName};
            last;
        };
    }

    $t->network_address_delete(addrname => $target_addr);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'off'
    );
};

done_testing();
