#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY        = 'hclee';
our $VERSION          = '1.00';
our $TEST_DESCRIPTOIN = 'abnormal volume delete test';

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

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

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $T        = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
my $NODE_CNT = $T->nodes ? scalar(@{$T->nodes}) : 0;

my $MASTER_IP = (split(/:/, $GMS_TEST_ADDR))[0];
my $FLAG_PATH = '/tmp/reenterable_create_test';

my @HOST_NMS = $T->gethostnm(start_node => 0, cnt => $NODE_CNT);
my @STG_IPS  = $T->hostnm2stgip(hostnms => \@HOST_NMS);
my @MGMT_IPS = $T->hostnm2mgmtip(hostnms => \@HOST_NMS);

my $VOL_NAME = 'recreate_test';

# reenterable test
subtest 'set flag to fail the /cluster/volume/create api' => sub
{
    my ($out, $err)
        = $T->ssh_cmd(addr => $MASTER_IP, cmd  => "touch $FLAG_PATH");

    if (!cmp_ok($err, 'eq', ''))
    {
        fail("Failed to create the flag file: $FLAG_PATH: $err");
        return;
    }

    ok("Flag file is created: $FLAG_PATH");
};

subtest 'request to create a volume' => sub
{
    my $vol_info = {
        volname    => $VOL_NAME,
        volpolicy  => 'Distributed',
        capacity   => '4.0G',
        replica    => 1,
        node_count => $NODE_CNT,
        start_node => 0,
    };

    my $retval = $T->volume_create(
        %{$vol_info},
        expected => {
            dryrun => 'false',
            return => 'false',
        }
    );

    cmp_ok($retval // '', 'eq', ''
            , "Failed to create the volume: $VOL_NAME");
};

subtest 'Check a volume exists or not' => sub
{
    my $vol_list = $T->volume_list();

    if (!isa_ok($vol_list, 'ARRAY'))
    {
        fail('Failed to get volume list');
        return;
    }

    diag(explain($vol_list));

    my $volume = (grep { $_->{Volume_Name} eq $VOL_NAME } @{$vol_list})[0];

    cmp_ok($volume, '!=', undef, "Volume $VOL_NAME does exist");

    diag(explain($volume));

    is($volume->{Oper_Stage}
        , 'CREATE_FAIL'
        , 'Operation Stage eq "CREATE_FAIL"');
};

subtest 'Clear the flag file' => sub
{
    my ($out, $err)
        = $T->ssh_cmd(addr => $MASTER_IP, cmd  => "rm -r $FLAG_PATH");

    if (!cmp_ok($err, 'eq', ''))
    {
        fail("Failed to remove the flag file: $FLAG_PATH: $err");
        return;
    }

    ok("Flag file is removed: $FLAG_PATH");
};

subtest 'Cleanup volume, if exists' => sub
{
    my $retval = $T->volume_delete(volname => $VOL_NAME);

    cmp_ok($retval, '==', 0, "Volume is deleted: $VOL_NAME");
};
