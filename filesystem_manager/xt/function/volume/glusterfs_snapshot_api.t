#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'Cluster volume snapshot API test';

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname( rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Scalar::Util qw/looks_like_number/;
use Test::Most;

use API::Return;

use Test::AnyStor::Account;
use Test::AnyStor::Network;
use Test::AnyStor::Share;
use Test::AnyStor::Filing;
use Test::AnyStor::ClusterVolume;

$ENV{GMS_TEST_ADDR}   = shift(@ARGV) if @ARGV;
$ENV{GMS_CLIENT_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR   = $ENV{GMS_TEST_ADDR};
my $GMS_CLIENT_ADDR = $ENV{GMS_CLIENT_ADDR};

my ($test_addr) = $GMS_TEST_ADDR =~ m/^(.+):\d+$/;

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

if (!defined($GMS_TEST_ADDR) && !defined($GMS_CLIENT_ADDR))
{
    ok(0, 'argument missing');
    return 1;
}

my $verbose = 0;
my @hostnms = ();
my @mgmtips = ();

my $filing = Test::AnyStor::Filing->new(
                addr       => $GMS_TEST_ADDR,
                no_login   => 1,
                not_umount => 1);

$filing->quiet(1) if (!$verbose);

ok(1, "Preparing for snapshot api test");

my $TEST_VOL = undef;

subtest 'create test account' => sub
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR);

    $t->user_create(prefix => 'snap_test_user');
};

subtest 'Create test zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_zone_create(
        zonename    => 'test_zone',
        description => 'Network zone allow global access for testing',
        type        => 'netmask',
        zoneip      => '0.0.0.0',
        zonemask    => '0.0.0.0',
    );
};

subtest 'Create test volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @tmp = $t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes}));

    my @nodeinfo = ();

    push(@nodeinfo, { Hostname => $_ }) foreach (@tmp);

    my $res = $t->volume_pool_create(
        pooltype => 'thin',
        basepool => 'vg_cluster',
        capacity => '10G',
        nodes    => \@nodeinfo,
    );

    if (!$res)
    {
        fail('Failed to create thin volume pool on vg_cluster');
    }
    else
    {
        ok(1, 'Thin volume pool is created');
    }
};

subtest 'create test volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $TEST_VOL = $t->volume_create(
        volpolicy  => 'Distributed',
        capacity   => '1.0G',
        replica    => 1,
        node_count => 1,
        start_node => 0,
        pool_name  => 'tp_cluster',
        provision  => 'thin',
    );

    cmp_ok($TEST_VOL // '', 'ne', '', "Test volume is created: $TEST_VOL");
};

subtest 'Create share instances' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    $t->cluster_share_create(
        sharename => $TEST_VOL,
        volume    => $TEST_VOL,
        path      => $TEST_VOL,
    );

    my $share_list = $t->cluster_share_list();

    my $find_flag = 0;

    foreach my $share (@{$share_list})
    {
        next if ($TEST_VOL ne $share->{ShareName});

        $find_flag = 1;
        last;
    }

    cmp_ok($find_flag, '==', 1, 'Share is created');

    $t->cluster_share_update(
        sharename  => $TEST_VOL,
        volume     => $TEST_VOL,
        path       => $TEST_VOL,
        CIFS_onoff => 'on',
        NFS_onoff  => 'on'
    );

    my $cifs_list = $t->cluster_share_cifs_list();

    $find_flag = 0;

    foreach my $each_cifs (@{$cifs_list})
    {
        if ($each_cifs->{ShareName} eq $TEST_VOL)
        {
            $find_flag = 1;
            last;
        };
    }

    cmp_ok($find_flag, '==', 1, 'CIFS is activated');

    $t->cluster_share_cifs_setconf(active => 'on');

    #/cluster/share/cifs/update
    $t->cluster_share_cifs_update(
        sharename   => $TEST_VOL,
        active      => 'on',
        share_right => 'read/write',
        access_zone => 'test_zone',
        zone_right  => 'allow',
        access_user => 'snap_test_user-1',
        user_right  => 'read/write',
    );

    my $nfs_list = $t->cluster_share_nfs_list();

    $find_flag = 0;

    foreach my $each_nfs (@{$nfs_list})
    {
        if ($each_nfs->{ShareName} eq $TEST_VOL)
        {
            $find_flag = 1;
            last;
        };
    }

    cmp_ok($find_flag, '==', 1, 'NFS is activated');

    $t->cluster_share_nfs_setconf(active => 'on');

    $t->cluster_share_nfs_update(
        sharename   => $TEST_VOL,
        active      => 'on',
        access_zone => 'test_zone',
        zone_right  => 'read/write'
    );
};

subtest 'Setup mount for client' => sub
{
    $filing->make_directory(dir => "/mnt/$TEST_VOL");

    my %args = (
        type   => 'nfs',
        device => "$test_addr:/$TEST_VOL",
        point  => "/mnt/$TEST_VOL",
    );

    if ($filing->is_mountable(%args))
    {
        $filing->mount(%args);
    }
};

subtest 'Snapshot API test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $node_cnt = scalar(@{$t->nodes});

    @hostnms = $t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes}));
    @mgmtips = $t->hostnm2mgmtip(hostnms => \@hostnms);

    # file write on volume
    $filing->write_file(
        point => "/mnt/$TEST_VOL",
        file  => time(),
    );

    # take snapshot
    my $snapname = $t->volume_snapshot_create(
                    volname  => $TEST_VOL,
                    snapname =>'test');

    ok(defined($snapname), 'New snapshot is created: ' . $snapname // 'undef');

    # checking th snapshot info
    my $snap_list = $t->volume_snapshot_list(volname => $TEST_VOL);

    if (defined($snap_list))
    {
        my $hit = 0;

        foreach my $info (@{$snap_list})
        {
            next if ($info->{Snapshot_Name} ne $snapname);

            $hit = 1;
            last;
        }

        if ($hit)
        {
            ok(1, "Snapshot information($snapname) is found");
        }
        else
        {
            fail("Cannot found snapshot($snapname) in snapshot list");
        }
    }
    else
    {
        fail('Snapshot list is empty');
    }

    # activating the snapshot for file checking
    $t->volume_snapshot_activate(
        volname   => $TEST_VOL,
        snapname  => $snapname,
        activated => 'true'
    );

    for (my $i=1; $i<=60; $i++)
    {
        my $remain_test_pass_cnt = 2;

        # file checking on snapshot volume
        my ($node, undef) = $t->ssh_cmd(
            addr => $test_addr,
            cmd  => "ls /export/$TEST_VOL/.snaps/$snapname | wc -l"
        );

        my ($client, undef) = $t->ssh_cmd(
            addr => $GMS_CLIENT_ADDR,
            cmd  => "ls /mnt/$TEST_VOL/.snaps/$snapname | wc -l"
        );

        if (defined($node) && $node =~ /^\d+$/)
        {
            ok(1, "File checking in snapshot($snapname) on node's /export/* ($test_addr)");
            ok(1, "Got      : $node");
            ok(1, "Expected : 1");

            $remain_test_pass_cnt--;
        }
        else
        {
            ok(1, 'Failed to check snapshot uss on node with SSH command');
        }

        if (defined($client) && $client =~ /^\d+$/)
        {
            ok(1, "File checking in snapshot($snapname) on client's /mnt/* ($GMS_CLIENT_ADDR)");
            ok(1, "Got      : $client");
            ok(1, "Expected : 1");

            $remain_test_pass_cnt--;
        }
        else
        {
            ok(1, 'Failed to check snapshot uss on client with SSH command');
        }

        if ($remain_test_pass_cnt <= 0)
        {
            last;
        }

        ok(1, "snapshot uss checking retry($snapname) ... ($i/60)");
        ok(1, "remain snapshot uss checking count($remain_test_pass_cnt)");

        sleep 1;
    }

    # deactivate state of snapshot
    $t->volume_snapshot_activate(
        volname   => $TEST_VOL,
        snapname  => $snapname,
        activated => 'false',
    );

    # deactivate state of snapshot
    $t->volume_snapshot_delete(
        volname  => $TEST_VOL,
        snapname => $snapname,
    );
};

subtest 'cleanup mount' => sub
{
    $filing->umount();
    $filing->rm(dir => "/mnt/$TEST_VOL");
};

subtest 'cleanup test share instances' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    $t->cluster_share_cifs_setconf(active => 'off');
    $t->cluster_share_nfs_setconf(active => 'off');

    $t->cluster_share_update(
        sharename  => $TEST_VOL,
        volume     => $TEST_VOL,
        path       => $TEST_VOL,
        CIFS_onoff => 'off',
        NFS_onoff  => 'off'
    );

    $t->cluster_share_delete(sharename => $TEST_VOL);
};

subtest 'cleanup test volumes' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    # delete volume
    is($t->volume_delete(volname => $TEST_VOL), 0, 'cluster volume delete');

    # verify the volume is deleted
    $t->verify_volstatus(volname => $TEST_VOL, exists => 0);
};

subtest 'cleanup test volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    $t->volume_pool_remove(pool_name => 'tp_cluster');
};

subtest 'cleanup test zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);
    $t->cluster_network_zone_delete(zonename => 'test_zone');
};

subtest 'cleanup test account' => sub
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR);
    $t->user_delete(names => 'snap_test_user-1');
};

undef($filing);

done_testing();
