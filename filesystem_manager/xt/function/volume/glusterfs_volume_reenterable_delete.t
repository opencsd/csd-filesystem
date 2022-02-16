#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY        = 'hclee';
our $VERSION          = '1.00';
our $TEST_DESCRIPTOIN = 'GlusterFS volume reenterable delete test';

use strict;
use warnings;
use utf8;

BEGIN {
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

my $FLAG_PATH = '/tmp/reenterable_delete_test';

my $T        = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
my $NODE_CNT = $T->nodes ? scalar(@{$T->nodes}) : 0;

my $MASTER_IP = (split(/:/, $GMS_TEST_ADDR))[0];
my @HOST_NMS  = $T->gethostnm(start_node => 0, cnt => $NODE_CNT);
my @STG_IPS   = $T->hostnm2stgip(hostnms => \@HOST_NMS);
my @MGMT_IPS  = $T->hostnm2mgmtip(hostnms => \@HOST_NMS);

my $VOL_NAME  = undef;

subtest 'request to create the volume' => sub
{
    ok('dummy');

    my $vol_info = {
        volpolicy  => 'Distributed',
        capacity   => '4.0G',
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

subtest 'set flag to fail the /cluster/volume/delete api' => sub
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

subtest 'try to delete the volume' => sub
{
    my $retval = $T->volume_delete(
                    volname  => $VOL_NAME,
                    expected => {
                        dryrun => 'true',
                        return => 'false',
                    });

    cmp_ok($retval, '==', 0, "Failed to delete the volume: $VOL_NAME");
};

subtest 'check volume exists or not' => sub
{
    my $vol_list = $T->volume_list(volname => $VOL_NAME);

    if (!defined($vol_list))
    {
        fail('Failed to get volume list');
        return;
    }

    my $volume = (grep { $_->{Volume_Name} eq $VOL_NAME; } @{$vol_list})[0];

    return if (!ok($volume, "Could not find volume: $VOL_NAME"));

    cmp_ok($volume->{Oper_Stage}
        , 'eq'
        , 'DELETE_FAIL'
        , 'Operation Stage is "DELETE_FAIL"');
};

subtest 'clear the flag file' => sub
{
    my ($out, $err)
        = $T->ssh_cmd(addr => $MASTER_IP, cmd  => "rm -f $FLAG_PATH");

    if ($err ne '')
    {
        fail("Failed to remove the flag file: $FLAG_PATH: $err");
        return;
    }

    ok("Flag file is removed: $FLAG_PATH");
};

subtest 'try to delete failed volume' => sub
{
    my $retval = $T->volume_delete(volname => $VOL_NAME);

    cmp_ok($retval, '==', 0, "Volume $VOL_NAME is deleted");
};
