#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "임의로 설정한 bond option이 Network  API로 인해 사라지는 경우가 있는지 확인하는 테스트";

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

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my $verbose = 0;

my $TEST_IP_POOL_START = '100.0.0.1';
my $TEST_IP_POOL_END   = '100.0.0.10';

my @TEST_IP_POOL;
my $POOL_SIZE;

my $SCRIPT_DIR = '/etc/sysconfig/network-scripts';

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
        active  => 'off'
    );
};

my $test_bond;

subtest 'initialize test bond' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $test_bond = $t->network_bonding_create(
        slave  => [ $GMS_TEST_IFACE ],
        mode   => 1,
        mtu    => 1500,
        active => 'on'
    );
};

subtest 'modify BONDING_OPTS' => sub
{
    my $bond_cfg = `ssh $test_addr \"cat $SCRIPT_DIR/ifcfg-$test_bond\"`;
    my @lines = split(/\n/, $bond_cfg);

    foreach my $line (@lines)
    {
        if ($line =~ /BONDING_OPTS/)
        {
            $line =~ s/\'$//;
            $line .= " test_option=yes'";
        }
    }

    $bond_cfg = join("\n", @lines);

    if (open(my $fh, '>', "/tmp/ifcfg-$test_bond"))
    {
        print $fh $bond_cfg;
        close $fh;

        ok(1, "add test_option to $test_bond");

        system("scp /tmp/ifcfg-$test_bond $test_addr:$SCRIPT_DIR > /dev/null");
        system("rm -f /tmp/ifcfg-$test_bond");
    }
    else
    {
        ok(0, "Failed to add test_option to test_bond");
    }
};

subtest 'Bonding API: option maintenance test after primary slave update' => sub
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

    subtest 'check test_option maintenance' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

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
                    if ($opt eq 'test_option=yes')
                    {
                        $find_flag++;
                        last;
                    }
                }

                last;
            }
        }

        ok( $find_flag, "check maintenance of test_option" );
    };
};

subtest 'Device API: option maintenance test after bond become down' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->network_device_update(
        devname => $test_bond,
        active  => 'off'
    );

    subtest 'check test_option maintenance' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            next if ($line !~ /BONDING_OPTS/);

            my $bond_opts = $line;

            $bond_opts =~ s/BONDING_OPTS=//;
            $bond_opts =~ s/^'|'$//g;

            my @array_bond_opts = split(/[ ]+/, $bond_opts);

            foreach my $opt (@array_bond_opts)
            {
                if ($opt eq 'test_option=yes')
                {
                    $find_flag++;
                    last;
                }
            }

            last;
        }

        ok($find_flag, "check maintenance of test_option");
    };
};

subtest 'Address API: option maintenance test after a address is assigned to the bond' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    my $created_addr = $TEST_IP_POOL[rand($POOL_SIZE)];

    $t->network_address_create(
        devname => $test_bond,
        ipaddr  => $created_addr,
        netmask => '255.255.255.0',
        active  => 'on'
    );

    subtest 'check test_option maintenance' => sub
    {
        my $diagnosis = `ssh $test_addr "cat $SCRIPT_DIR/ifcfg-$test_bond"`;
        my @lines = split(/\n/, $diagnosis);

        my $find_flag = 0;

        foreach my $line (@lines)
        {
            next if ($line !~ /BONDING_OPTS/);

            my $bond_opts = $line;

            $bond_opts =~ s/BONDING_OPTS=//;
            $bond_opts =~ s/^'|'$//g;

            my @array_bond_opts = split(/[ ]+/, $bond_opts);

            foreach my $opt (@array_bond_opts)
            {
                if ($opt eq 'test_option=yes')
                {
                    $find_flag++;
                    last;
                }
            }

            last;
        }

        ok($find_flag, "check maintenance of test_option");
    };
};

subtest 'reset test bond' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    my $addr_list = $t->network_address_list();

    my $test_addr;

    foreach my $each_addr (@{$addr_list})
    {
        if ($each_addr->{Iface} eq $test_bond)
        {
            $test_addr = $each_addr->{AddrName};
        };
    }

    $t->network_address_delete(addrname => $test_addr);
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
