#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'Cluster volume tiering API test';

use strict;
use warnings;
use utf8;

BEGIN {
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Scalar::Util qw/looks_like_number/;
use Test::Most;

use Test::AnyStor::ClusterVolume;
use Test::AnyStor::ClusterBlock;

$ENV{GMS_TEST_ADDR}   = shift(@ARGV) if (@ARGV);
$ENV{GMS_CLIENT_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR   = $ENV{GMS_TEST_ADDR};
my $GMS_CLIENT_ADDR = $ENV{GMS_CLIENT_ADDR};

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

if (!(defined($GMS_TEST_ADDR) || defined($GMS_CLIENT_ADDR)))
{
    ok(0, 'argument missing');
    return 1;
}

my $new_thick_vpool = 'vg_tier';
my $new_thin_vpool  = 'tp_tier';
my $blk_dev_info    = undef;

subtest 'create thin volume on vg_cluster' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @tmp = $t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes}));

    my @nodeinfo = ();

    push(@nodeinfo, { Hostname => $_ }) foreach (@tmp);

    $t->volume_pool_list(pool_name => 'vg_cluster');

    my $res = $t->volume_pool_create(
        pooltype => 'thin',
        basepool => 'vg_cluster',
        capacity => '10G',
        nodes    => \@nodeinfo,
    );

    if (!$res)
    {
        fail('Failed to create thin volume pool on vg_cluster)');
    }

    my $list = $t->volume_pool_list();

    diag(explain($list));
};

subtest 'Get all of block device info' => sub
{
    my $t = Test::AnyStor::ClusterBlock->new(addr => $GMS_TEST_ADDR);

    my $res = $t->list_block_device(scope => 'NO_INUSE');

    if (!$res)
    {
        fail("Failed to get the all node's information of block device");
        goto TESTEND;
    }

    $blk_dev_info = $res;

    ok(1, "getting the all node's information of block device");
};

subtest 'New thick volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @nodeinfo = ();

    foreach my $node (@{$blk_dev_info})
    {
        if (ref($node->{Devices}) eq 'ARRAY' && @{$node->{Devices}}
            && grep { $_->{Name} eq '/dev/sdc' } @{$node->{Devices}})
        {
            push(@nodeinfo,
                {
                    Hostname => $node->{Hostname},
                    PVs      => [ { Name =>'/dev/sdc' } ]
                }
            );
        }
    }

    if (!@nodeinfo)
    {
        fail("Cannot found /dev/sdc on any nodes");
        goto TESTEND;
    }

    my $res = $t->volume_pool_create(
        pooltype  => 'thick',
        pool_name => $new_thick_vpool,
        nodes     => \@nodeinfo,
        purpose   => 'for_tiering',
    );

    if (!$res)
    {
        fail("Failed to create volume pool($new_thick_vpool)");
        goto TESTEND;
    }

    my $list = $t->volume_pool_list();

    diag(explain($list));
};

subtest 'New thin volume pool on thick volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @nodeinfo = ();

    push(@nodeinfo, { Hostname => $_ })
        foreach ($t->gethostnm(start_node => 0, cnt => scalar(@{$t->{nodes}})));

    my $res = $t->volume_pool_create(
        pooltype => 'thin',
        basepool => $new_thick_vpool,
        capacity => '5G',
        nodes    => \@nodeinfo,
    );

    if (!$res)
    {
        fail("Failed to create volume pool($new_thin_vpool)");
        goto TESTEND;
    }

    my $list = $t->volume_pool_list();

    diag(explain($list));
};

subtest 'Tiering API test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $node_cnt = scalar(@{$t->nodes});
    my @nodes    = $t->gethostnm(start_node => 0, cnt => $node_cnt);

    my @created  = ();
    my %vol_info = (
        volpolicy  => 'Distributed',
        capacity   => '1.0G',
        replica    => 1,
        node_count => 1,
        start_node => 0,
        pool_name  => 'tp_cluster'
        provision  => 'thin'
    );

    my $volname = $t->volume_create(%vol_info);

    sleep 1;

    if (!$volname)
    {
        fail('Failed to create test volume');
        goto TESTEND;
    }

    sleep 1;

    $t->verify_volstatus(volname => $volname, exists => 1, thin => 1);

    my $ret = $t->volume_tier_attach(
        pool_name   => $new_thin_vpool,
        volname     => $volname,
        capacity    => '2.0G',
        replica_cnt => ($node_cnt % 2) ? 1 : 2,
        node_list   => \@nodes
    );

    diag(explain($ret));

    my $list = $t->volume_tier_list(volname => $volname);

    diag(explain($list));

    my $res = $t->volume_tier_opts(volname => $volname, action_type => 'get');

    diag(explain($res));

    #'Tier_Opts'   => {
    #   'Tier_Pause'     => 'on',
    #   'Tier_Mode'      => 'cache',
    #   'Tier_Max_MB'    => '4000', 
    #   'Tier_Max_Files' => '10000',
    #   'Watermark'      => { 'High' => '90', 'Low' => '75' },
    #   'IO_Threshold'   => { 'Read_Freq' => '0', 'Write_Freq' => '0' },
    #   'Migration_Freq' => { 'Promote' => '120', 'Demote' => '3600' },
    #};

    my $opts = $res->{Tier_Opts};

    $opts->{Tier_Mode}                = 'test';
    $opts->{Tier_Max_MB}              = 200;
    $opts->{Tier_Max_Files}           = 10000;
    $opts->{Watermark}{High}          = 50;
    $opts->{Watermark}{Low}           = 30;
    $opts->{IO_Threshold}{Read_Freq}  = 20;
    $opts->{IO_Threshold}{Write_Freq} = 20;
    $opts->{Migration_Freq}{Promote}  = 10;
    $opts->{Migration_Freq}{Demote}   = 60;

    $res = $t->volume_tier_opts(
        volname     => $volname,
        action_type => 'set',
        tier_opts   => $opts
    );

    diag(explain($res));

    $t->volume_tier_detach(volname => $volname);

    $list = $t->volume_tier_list(volname => $volname);

    diag(explain($list));

    $ret = $t->volume_delete(volname => $volname);

    is($ret, 0, 'cluster volume delete');

    sleep 1;

    $t->verify_volstatus(volname => $volname, exists => 0, thin => 1);
};

subtest 'Clean-up volume pool test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $t->volume_pool_remove(pool_name => 'tp_tier');
    $t->volume_pool_remove(pool_name => 'vg_tier');

    my $list = $t->volume_pool_list();

    diag(explain($list));
};

TESTEND:
done_testing();
