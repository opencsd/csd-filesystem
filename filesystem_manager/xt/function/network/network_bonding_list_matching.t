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

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

if (!defined($GMS_TEST_ADDR) || !defined($GMS_TEST_IFACE))
{
    ok(0, 'argument missing');
    return 1;
}

sub get_device_info_from_ifconfig
{
    my $target_device = shift;

    if ($target_device !~ /[a-zA-Z0-9\.]+/)
    {
        return {};
    }

    my $dev_info_from_ifconfig = `ssh $test_addr "ifconfig $target_device"`;

    my $base_device_info = {};

    $base_device_info->{Active} = ($dev_info_from_ifconfig =~ /RUNNING/) ? 1 : 0;
    $base_device_info->{Slave}  = ($dev_info_from_ifconfig =~ /SLAVE/) ? 1 : 0;

    my @dev_info = grep(
        $_ =~ /flags|inet |txqueuelen/,
        split(/\n/, $dev_info_from_ifconfig)
    );

    foreach my $each_info (@dev_info)
    {
        if ($each_info =~ /\<[\w|,]+\>\s+mtu (?<mtu>\d+)/)
        {
            # NOTE: $each_info is like below
            # "$each_dev: flags=##<FLAG1,FLAG2,...>  mtu ###"
            $base_device_info->{MTU} = $+{mtu};
        }
        elsif ($each_info =~ /inet (?<ipaddr>[\d|\.]+)\s+netmask (?<netmask>[\d|\.]+)/)
        {
            # NOTE: $each_info is like below
            # "inet $ipaddr  netmask $netmask  broadcast $broadcast"
            $base_device_info->{ipaddr} = $+{ipaddr};
            $base_device_info->{netmask} = $+{netmask};
        }
        elsif ($each_info =~ /\w+ (?<hwaddr>[\d|\w|:]+)*\s*txqueuelen \d+\s+\(.+\)/)
        {
            # NOTE: $each_info is like below
            # "$type_short $hwaddr  txqueuelen ##  ($type_long)"
            $base_device_info->{HWaddr} = $+{hwaddr} if (defined($+{hwaddr}));
        }
    }

    return $base_device_info;
}

sub compare_device_info
{
    my $info_from_api = shift;
    my $info_from_ifconfig = shift;

    if (ref($info_from_api) ne 'HASH' && ref($info_from_ifconfig) ne 'HASH')
    {
        ok(0, "compare_device_info: invalid device_info");
        return 0;
    }

    my $standard = 1;

    map {
        $standard &&= ($info_from_api->{$_} eq $info_from_ifconfig->{$_});
    } (qw/HWaddr MTU/);

    map {
        $standard
            &&= (($info_from_api->{$_} eq 'off'
                    && $info_from_ifconfig->{$_} == 0)
                || ($info_from_api->{$_} eq 'on'
                    && $info_from_ifconfig->{$_} == 1));
    } (qw/Active/);

    if (defined($info_from_ifconfig->{ipaddr}))
    {
        (my $target_ipaddr) = grep {
            $_->{Ipaddr} eq $info_from_ifconfig->{ipaddr}
            && $_->{Netmask} eq $info_from_ifconfig->{netmask}
        } @{$info_from_api->{IPaddrInfo}};

        $standard &&= defined($target_ipaddr);
    }

    return $standard;
}

subtest 'Bonding API: Bonding list matching test with ifconfig' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    my $bonding_list_from_api = $t->network_bonding_list;

    foreach my $each_bonding_info (@$bonding_list_from_api)
    {
        my $each_bonding_name = $each_bonding_info->{DevName};

        if ($each_bonding_name !~ /[a-zA-Z0-9\.]+/)
        {
            ok(0,
                "There is invalid device name "
                ."in bonding_list_from_api($each_bonding_name)");

            last;
        }

        my $bonding_info_from_ifconfig
            = get_device_info_from_ifconfig($each_bonding_name);

        ok(compare_device_info($each_bonding_info, $bonding_info_from_ifconfig)
            , "Check if $each_bonding_name info in db and one in ifconfig is same");

        foreach my $each_slave (@{$each_bonding_info->{Slave}})
        {
            my $each_slave_info
                = get_device_info_from_ifconfig($each_slave->{Device});

            ok($each_slave_info->{Slave} == 1, "Check slave($each_slave->{Device})");
        }
    }
};

done_testing();
