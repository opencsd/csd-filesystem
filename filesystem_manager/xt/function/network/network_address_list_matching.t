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

sub get_device_names
{
    my $dev_info_from_ifconfig = `ssh $test_addr "ifconfig -a"`;

    my @line_with_dev_name = grep {
        $_ =~ /^[\w\d]+ /;
    } (split(/\n/, $dev_info_from_ifconfig));

    return map { (my $dev_name) = split(/ /, $_); } @line_with_dev_name;
}

sub get_device_info_from_ifconfig
{
    my $target_device = shift;

    return {} if ($target_device !~ /[a-zA-Z0-9\.]+/);

    my $dev_info_from_ifconfig = `ssh $test_addr "ifconfig $target_device"`;

    my $base_device_info = { devname => $target_device };

    my @dev_info = grep {
        $_ =~ /inet addr:|Mask:/;
    } (split(/\s\s+/, $dev_info_from_ifconfig));

    foreach my $each_info (@dev_info)
    {
        my ($key, $data) = ('', $each_info);

        if ($data =~ /inet addr:/)
        {
            $key  = 'ipaddr';
            $data =~ s/inet addr://;
        }
        elsif ($data =~ /Mask:/)
        {
            $key  = 'netmask';
            $data =~ s/Mask://;
        }
        else
        {
            next;
        }

        $base_device_info->{$key} = $data;
    }

    return $base_device_info;
}

sub compare_address_info
{
    my $list_from_api = shift;
    my $info_from_ifconfig = shift;

    if (ref($list_from_api) ne 'ARRAY' && ref($info_from_ifconfig) ne 'HASH')
    {
        ok(0, "compare_device_info: invalid device_info");
        return 0;
    }

    (my $target_ipaddr) = grep {
        $_->{IPaddr} eq $info_from_ifconfig->{ipaddr}
        && $_->{Netmask} eq $info_from_ifconfig->{netmask}
        && $_->{DevName} eq $info_from_ifconfig->{devname}
    } @{$list_from_api};

    return defined($target_ipaddr);
}

subtest 'Address API: Address list matching test with ifconfig' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    my $address_list_from_api = $t->network_address_list;

    foreach my $each_device_name (get_device_names())
    {
        my $device_info_from_ifconfig
            = get_device_info_from_ifconfig($each_device_name);

        next if (!defined($device_info_from_ifconfig->{ipaddr})
                || $each_device_name eq 'lo');

        ok(
            compare_address_info($address_list_from_api, $device_info_from_ifconfig),
            "Check if represent ip($device_info_from_ifconfig->{ipaddr}) "
            . "of $each_device_name info in db and one in ifconfig is same"
        );
    }
};

done_testing();
