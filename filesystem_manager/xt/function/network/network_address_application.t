#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'Geunyeong Bak';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN = "
    Network Address API가 변경한 내용이 시스템에 적용되는지 확인하는 테스트
";

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Network;
use Test::AnyStor::ClusterAddress;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_TEST_IFACE} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $GMS_TEST_IFACE = $ENV{GMS_TEST_IFACE};

my $verbose = 0;
my $application_wait = 3;

my $test_addr = $GMS_TEST_ADDR;
$test_addr =~ s/:\d+$//;

my $TEST_IP_POOL_START = '100.0.0.1';
my $TEST_IP_POOL_END   = '100.0.0.10';

my @TEST_IP_POOL;
my $POOL_SIZE;

my $SCRIPT_DIR = '/etc/sysconfig/network-scripts';

if( !defined $GMS_TEST_ADDR || !defined $GMS_TEST_IFACE )
{
    ok(0, 'argument missing');
    return 1;
}

sub addr_to_dec
{
    my $addr = shift;

    my $decimal_addr = 0;
    my @addr_split = split /\./, $addr;
    for( my $class = 0;$class < 4; $class++ )
    {
        $decimal_addr += ( $addr_split[3-$class] << ( 8 * $class ) );
    }

    return $decimal_addr;
}

sub dec_to_addr
{
    my $decimal_addr = shift;

    my @addr_split = (
        ( $decimal_addr & 255*256*256*256 ) >> 24,
        ( $decimal_addr & 255*256*256 ) >> 16,
        ( $decimal_addr & 255*256 ) >> 8,
        ( $decimal_addr & 255 ) >> 0
    );
    my $addr = join '.', @addr_split;

    return $addr;
}

subtest 'make_test_ip_pool' => sub
{
    my $dec_pool_start = addr_to_dec( $TEST_IP_POOL_START );
    my $dec_pool_end = addr_to_dec( $TEST_IP_POOL_END );

    for( my $dec_addr = $dec_pool_start; $dec_addr <= $dec_pool_end; $dec_addr++ )
    {
        my $test_addr = dec_to_addr( $dec_addr );
        push @TEST_IP_POOL, $test_addr;
    }

    $POOL_SIZE = scalar(@TEST_IP_POOL);

    ok(1, "Test ip pool has been created (size: $POOL_SIZE, range: $TEST_IP_POOL_START ~ $TEST_IP_POOL_END)");
};

subtest "initialize test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    $t->network_device_update(
        devname => $GMS_TEST_IFACE, mtu => 1500, active => 'off'
    );
};

my $created_addr;
subtest 'Address API: created address application test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $created_addr = $TEST_IP_POOL[rand($POOL_SIZE)];
    $t->network_address_create(
        devname => $GMS_TEST_IFACE,
        ipaddr => $created_addr,
        netmask => '255.255.255.0',
        active => 'off'
    );
    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        my @lines = split /\n/, $diagnosis;

        my $applied_value = '';
        foreach my $line ( @lines )
        {
            if( $line =~ /IPADDR/ )
            {
                $applied_value = $line.' &'.$applied_value;
            }
            if( $line =~ /NETMASK/ )
            {
                $applied_value = $applied_value.'& '.$line;
            }
        }
        is( $applied_value, "IPADDR=$created_addr && NETMASK=255.255.255.0", "created address permanent apply check" );
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        my @lines = split /\n/, $diagnosis;

        my $applied_value = '';
        foreach my $line ( @lines )
        {
            if ($line =~ /inet (?<ipaddr>[\d|\.]+)\s+netmask (?<netmask>[\d|\.]+)/)
            {
                # NOTE: $each_info is like below
                # "inet $ipaddr  netmask $netmask  broadcast $broadcast"
                $applied_value = 'addr:'.$+{ipaddr}.' && Mask:'.$+{netmask};
                last;
            }
        }
        is( $applied_value, "addr:$created_addr && Mask:255.255.255.0", "created address run-time apply check" );
    };
};

my $target_addr;
subtest 'Address API: updated address application test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $addr_list = $t->network_address_list();

    foreach my $each_addr (@$addr_list)
    {
        if( $each_addr->{IPaddr} eq $created_addr 
            && $each_addr->{Netmask} eq '255.255.255.0' 
            && $each_addr->{Iface} eq $GMS_TEST_IFACE )
        {
            $target_addr = $each_addr->{ AddrName };
            last;
        };
    }

    my $updated_addr;
    do
    {
        $updated_addr = $TEST_IP_POOL[rand($POOL_SIZE)];
    }
    while( $POOL_SIZE != 1 && $created_addr eq $updated_addr );

    $t->network_address_update(
        addrname => $target_addr,
        ipaddr => $updated_addr,
        netmask => '255.255.255.0',
        active => 'off'
    );
    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        my @lines = split /\n/, $diagnosis;

        my $applied_value = '';
        foreach my $line ( @lines )
        {
            if( $line =~ /IPADDR/ )
            {
                $applied_value = $line.' &'.$applied_value;
            }
            if( $line =~ /NETMASK/ )
            {
                $applied_value = $applied_value.'& '.$line;
            }
        }
        is( $applied_value, "IPADDR=$updated_addr && NETMASK=255.255.255.0", "updated address permanent apply check" );
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        my @lines = split /\n/, $diagnosis;

        my $applied_value = '';
        foreach my $line ( @lines )
        {
            if ($line =~ /inet (?<ipaddr>[\d|\.]+)\s+netmask (?<netmask>[\d|\.]+)/)
            {
                # NOTE: $each_info is like below
                # "inet $ipaddr  netmask $netmask  broadcast $broadcast"
                $applied_value = 'addr:'.$+{ipaddr}.' && Mask:'.$+{netmask};
                last;
            }
        }
        is( $applied_value, "addr:$updated_addr && Mask:255.255.255.0", "updated address run-time apply check" );
    };
};

subtest 'reset test address' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    $t->network_address_delete( addrname => $target_addr );
    sleep $application_wait;

    subtest 'check permanent apply' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$GMS_TEST_IFACE"`;
        my @lines = split /\n/, $diagnosis;

        my $check_flag = 0;
        foreach my $line ( @lines )
        {
            if( $line =~ /IPADDR/ )
            {
                if( $line ne 'IPADDR=0.0.0.0' )
                {
                    $check_flag++;
                }
            }
            if( $line =~ /NETMASK/ )
            {
                $check_flag++;
            }
        }
        ok(!$check_flag, "deleted address permanent apply check");
    };

    subtest 'check run-time apply' => sub
    {
        my $diagnosis = `ssh $test_addr "ifconfig $GMS_TEST_IFACE"`;
        my @lines = split /\n/, $diagnosis;

        my $check_flag = 0;
        foreach my $line ( @lines )
        {
            if( $line =~ /inet / )
            {
                $check_flag++;
                last;
            }
        }
        ok(!$check_flag, "deleted address run-time apply check");
    };
};

subtest "reset test device($GMS_TEST_IFACE)" => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    $t->network_device_update(
        devname => $GMS_TEST_IFACE, mtu => 1500, active => 'off'
    );
};

done_testing();

exit 0;
