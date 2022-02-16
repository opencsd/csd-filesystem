#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY        = 'Hyochan Lee';
our $VERSION          = '1.00';
our $TEST_DESCRIPTOIN = 'GlusterFS volume reenterable expand test';

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename          qw/dirname/;
    use File::Spec;
    use File::Spec::Functions   qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Net::OpenSSH;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::ClusterVolume;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $FLAG_PATH = '/tmp/reenterable_expand_test';

my $T         = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
my $MASTER_IP = (split(/:/, $GMS_TEST_ADDR))[0];
my $NODE_CNT  = scalar(@{$T->nodes}) // 0;

if ($NODE_CNT < 2)
{
    diag('The number of nodes is not enough to test reenterable volume expand, skip...');
    exit 0;
}

my @HOST_NMS         = $T->gethostnm(start_node => 0, cnt => $NODE_CNT);
my @STG_IPS          = $T->hostnm2stgip(hostnms => \@HOST_NMS);
my @MGMT_IPS         = $T->hostnm2mgmtip(hostnms => \@HOST_NMS);
my $BRICK_CNT        = int($NODE_CNT / 2) ? int($NODE_CNT / 2) : 1;
my @EXPAND_NODE_LIST = @STG_IPS[$BRICK_CNT .. ($BRICK_CNT * 2 - 1)];

my $VOL_NAME = undef;

for (my $i=0; $i<2; $i++)
{
    if ($i)
    {
        diag('volume expanding fail & expanding test');
    }
    else
    {
        diag('volume expanding fail & delete test');
    }

    subtest 'Request to create the volume' => sub
    {
        my $vol_info = {
            volpolicy  => 'Distributed',
            capacity   => '2.0G',
            replica    => 1,
            node_count => $BRICK_CNT,
            start_node => 0,
        };

        my $res = $T->volume_create(%{$vol_info});

        if (!defined($res) || $res eq '')
        {
            fail('Failed to create the volume');
            return;
        }

        $VOL_NAME = $res;

        ok("Volume $VOL_NAME is created");
    };

    subtest 'Create failure-flag file for /cluster/volume/expand API' => sub
    {
        my ($out, $err)
            = $T->ssh_cmd(addr => $MASTER_IP, cmd  => "touch $FLAG_PATH");

        if ($err ne '')
        {
            fail("Failed to create the flag file: $FLAG_PATH: $err");
            return;
        }

        ok("Flag file is created: $FLAG_PATH");
    };

    subtest 'Try to expand the volume' => sub
    {
        my $retval = $T->volume_expand(
                        volname   => $VOL_NAME,
                        add_count => $BRICK_CNT,
                        node_list => \@EXPAND_NODE_LIST,
                        expected  => {
                            dryrun => 'true',
                            return => 'false'
                        });

        cmp_ok($retval, '==', 0, "Failed to expand the volume: $VOL_NAME");
    };

    subtest 'Check volume exists or not' => sub
    {
        my $vol_list = $T->volume_list(volname => $VOL_NAME);

        if (!defined($vol_list))
        {
            fail("Failed to get volume list: ${\Dumper($vol_list)}");
            return;
        }

        cmp_ok($vol_list->[0]{Volume_Name}, 'eq', $VOL_NAME
                , 'Volume does exist');

        cmp_ok($vol_list->[0]{Oper_Stage}, 'eq', 'EXPAND_FAIL'
                , 'oper stage eq "EXPAND_FAIL"');
    };

    subtest 'Clear the flag file' => sub
    {
        my ($out, $err)
            = $T->ssh_cmd(addr => $MASTER_IP, cmd  => "rm -f $FLAG_PATH");

        if ($err ne '')
        {
            fail("Failed to remove the flag file: $FLAG_PATH");
            return;
        }

        ok("Flag file is removed: $FLAG_PATH");
    };

    # volume expanding failed & expanding test
    if ($i)
    {
        subtest 'Try to expand the failed volume' => sub
        {
            my $retval = $T->volume_expand(
                            volname   => $VOL_NAME,
                            add_count => $BRICK_CNT,
                            node_list => \@EXPAND_NODE_LIST);

            cmp_ok($retval, '==', 0, "Volume $VOL_NAME is expanded");
        };
    }
}
