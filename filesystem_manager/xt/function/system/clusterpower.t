#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY        = 'Woonghee Han';
our $TEST_DESCRIPTOIN = 'Cluster Power Test for reboot';

use strict;
use warnings;
use utf8;

BEGIN {
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname(rel2abs(__FILE__));
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift( @INC,
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Test::Most;
use Test::AnyStor::ClusterPower;
use Test::AnyStor::Util;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

subtest 'Cluster reboot test' => sub
{
    my $test_addr = $ENV{GMS_TEST_ADDR};

    my $t = Test::AnyStor::ClusterPower->new(addr => $ENV{GMS_TEST_ADDR});

    my %bef = $t->get_uptime;

    if (!%bef)
    {
        diag('Do not receive the bef uptime');
        goto OUT;
    }

    my $res = $t->cluster_reboot();
    my $cmp = $t->cmp_uptime(300, undef, %bef);

OUT:
    cmp_ok($cmp, '==', 0, 'Reboot check');

    # check REST API response for next test steps
    my $cnt  = 500;
    my $args = { wait => $cnt };

    my @mgmt_ip = $t->mgmtip_list('ARR');

    cmp_ok($t->rest_check(\@mgmt_ip, $args), '==', 0,
            'Reboot checking has succeeded');

    sleep 10;
};

done_testing();
