#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Network route API가 변경한 route 내용이 시스템에 적용되는지 확인하는 테스트";

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

my $TEST_IP_POOL_START = '100.0.0.1';
my $TEST_IP_POOL_END   = '100.0.0.10';

my @TEST_IP_POOL;
my $POOL_SIZE;

my $SCRIPT_DIR = '/etc/sysconfig/network-scripts';

my $disable = 1;

if ($disable)
{
    ok(1, 'route_aplication_test is skipped');
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

subtest "initialize test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'on'
    );
};

my $created_dest = $TEST_IP_POOL[rand($POOL_SIZE)];

subtest 'Network route API: created route application test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_route_create(
        devname     => $GMS_TEST_IFACE,
        netmask     => '255.255.255.0',
        destination => $created_dest
    );

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/route-$GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            my $value;

            last if ($find_flag == 2);

            if ($line =~ /ADDRESS/)
            {
                $value = $line;
                $value =~ s/ADDRESS\d+=//;

                if ($value eq $created_dest)
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

                if ($value eq '255.255.255.0')
                {
                    $find_flag++;
                }
                elsif ($find_flag > 0)
                {
                    $find_flag = 0;
                }
            }
        }

        ok($find_flag, "created service pool permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "route"`;
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            (my $dest_net_id, my $gateway, my $netmask
                , undef, undef, undef, undef
                , my $iface)
                    = split(/[ ]+/, $line);

            (my $created_dest_net_id = $created_dest) =~ s/.\d+$/.0/g;

            if ($dest_net_id eq $created_dest_net_id 
                && $gateway eq '*'
                && $netmask eq '255.255.255.0'
                && $iface eq $GMS_TEST_IFACE)
            {
                $find_flag++;
                last;
            }
        }

        ok($find_flag, "created service pool run-time apply check");
    };
};

my $updated_dest;

subtest 'Network route API: updated route application test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    do
    {
        $updated_dest = $TEST_IP_POOL[rand($POOL_SIZE)];
    } while($POOL_SIZE != 1 && $created_dest eq $updated_dest);

    $t->cluster_network_route_update(
        old_devname     => $GMS_TEST_IFACE,
        old_netmask     => '255.255.255.0',
        old_destination => $created_dest,
        new_devname     => $GMS_TEST_IFACE,
        new_netmask     => '255.255.255.0',
        new_destination => $updated_dest
    );

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/route-$GMS_TEST_IFACE"`;
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            my $value;

            last if ($find_flag == 2);

            if ($line =~ /ADDRESS/)
            {
                $value = $line;
                $value =~ s/ADDRESS\d+=//;

                if ($value eq $updated_dest)
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

                if ($value eq '255.255.255.0')
                {
                    $find_flag++;
                }
                elsif ($find_flag > 0)
                {
                    $find_flag = 0;
                }
            }
        }

        ok( $find_flag, "updated service pool permanent apply check" );
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "route"`;
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            (my $dest_net_id, my $gateway, my $netmask
                , undef, undef, undef, undef
                , my $iface)
                    = split(/[ ]+/, $line);

            (my $updated_dest_net_id = $updated_dest) =~ s/.\d+$/.0/g;

            if ($dest_net_id eq $updated_dest_net_id
                && $gateway eq '*'
                && $netmask eq '255.255.255.0'
                && $iface eq $GMS_TEST_IFACE)
            {
                $find_flag++;
                last;
            }
        }

        ok($find_flag, "updated service pool run-time apply check");
    };
};

subtest 'Network route API: deleted route application test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_route_delete(
        devname     => $GMS_TEST_IFACE,
        netmask     => '255.255.255.0',
        destination => $updated_dest
    );

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ls -l $SCRIPT_DIR"`;
        my @lines = split(/\n/, $diagnosis);

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
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            (my $dest_net_id, my $gateway, my $netmask
                , undef, undef, undef, undef
                , my $iface)
                    = split(/[ ]+/, $line);

            (my $updated_dest_net_id = $updated_dest) =~ s/.\d+$/.0/g;

            if ($dest_net_id eq $updated_dest_net_id 
                && $gateway eq '*'
                && $netmask eq '255.255.255.0'
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

    $t->network_device_update(
        devname => $GMS_TEST_IFACE,
        mtu     => 1500,
        active  => 'off'
    );
};

done_testing();
