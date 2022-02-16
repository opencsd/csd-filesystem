#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY        = 'Hyochan Lee';
our $VERSION          = '1.00';
our $TEST_DESCRIPTOIN = 'GlusterFS volume reenterable extend test';

use strict;
use warnings;
use utf8;

BEGIN {
    use File::Basename          qw/dirname/;
    use File::Spec;
    use File::Spec::Functions   qw/rel2abs/;

    my $ROOTDIR = dirname(rel2abs(__FILE__));
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib",
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

my $FLAG_PATH = '/tmp/reenterable_extend_test';

my $T         = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
my $MASTER_IP = (split(/:/, $GMS_TEST_ADDR))[0];
my $NODE_CNT  = $T->nodes ? scalar(@{$T->nodes}) : 0;
my @HOST_NMS  = $T->gethostnm(start_node => 0, cnt => $NODE_CNT);
my @STG_IPS   = $T->hostnm2stgip(hostnms => \@HOST_NMS);
my @MGMT_IPS  = $T->hostnm2mgmtip(hostnms => \@HOST_NMS);

my $VOL_NAME  = undef;

sub extend_test
{
    for (my $i=0; $i<2; $i++)
    {
        if ($i)
        {
            diag('Volume extending failure & extending test');
        }
        else
        {
            diag('Volume extending failure & delete test');
        }

        subtest 'Request to create the volume' => sub
        {
            my $vol_info = {
                volpolicy  => 'Distributed',
                capacity   => '2.0G',
                replica    => 1,
                node_count => $NODE_CNT,
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

        subtest 'Create failure-flag file for /cluster/volume/extend API' => sub
        {
            my ($out, $err)
                = $T->ssh_cmd(addr => $MASTER_IP, cmd => "touch $FLAG_PATH");

            if ($err ne '')
            {
                fail("Failed to create the flag file: $FLAG_PATH: $err");
                return;
            }

            ok("Flag file is created: $FLAG_PATH");
        };

        subtest 'Try to extend the volume' => sub
        {
            my $retval = $T->volume_extend(
                            volname    => $VOL_NAME,
                            extendsize => '4.0G',
                            expected   => {
                                dryrun => 'true',
                                return => 'false',
                            });

            cmp_ok($retval, '==', 0, "Failed to extend the volume: $VOL_NAME");
        };

        subtest 'Check volume exists or not' => sub
        {
            my $vol_list = $T->volume_list(volname => $VOL_NAME);

            if (!isa_ok($vol_list, 'ARRAY'))
            {
                fail("Failed to get volume list: ${\Dumper($vol_list)}");
                return;
            }

            cmp_ok($vol_list->[0]{Volume_Name}, 'eq', $VOL_NAME
                    , 'Volume does exist');

            cmp_ok($vol_list->[0]{Oper_Stage}, 'eq', 'EXTEND_FAIL'
                    , 'oper stage eq "EXTEND_FAIL"');
        };

        subtest 'Clear the flag file' => sub
        {
            my ($out, $err)
                = $T->ssh_cmd(addr => $MASTER_IP, cmd => "rm -f $FLAG_PATH");

            if ($err ne '')
            {
                fail("Failed to remove the flag file: $FLAG_PATH: $err");
                return;
            }

            ok("Flag file is removed: $FLAG_PATH");
        };

        # volume extending fail & extending test
        if ($i)
        {
            subtest 'Try to extend failed volume' => sub
            {
                my $retval = $T->volume_extend(
                                volname    => $VOL_NAME,
                                extendsize => '4.0G');

                cmp_ok($retval, '==', 0, "Volume $VOL_NAME is extented");
            };
        }

        subtest 'Cleanup test volume, if exists' => sub
        {
            my $vol_list = $T->volume_list();

            return if (!isa_ok($vol_list, 'ARRAY'));

            my $volume = (grep { $_->{Volume_Name} eq $VOL_NAME; } @{$vol_list})[0];

            return if (!ok($volume, "Could not find volume: $VOL_NAME"));

            cmp_ok($T->volume_delete(volname => $VOL_NAME)
                , '=='
                , 0
                , "Volume $volume->{Volume_Name} is deleted");
        };
    }
}

extend_test();

done_testing();
