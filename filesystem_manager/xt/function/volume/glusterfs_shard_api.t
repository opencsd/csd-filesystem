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
use Test::Most;
use Test::AnyStor::Base;
use Test::AnyStor::Account;
use Test::AnyStor::Network;
use Test::AnyStor::ClusterVolume;
use Test::AnyStor::Share;
use Test::AnyStor::Filing;
use Test::AnyStor::Time;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $T = Test::AnyStor::ClusterVolume->new(
            addr      => $GMS_TEST_ADDR,
            no_logout => 1);

my $NODE_CNT = scalar(@{$T->nodes});

if ($NODE_CNT <= 3)
{
    diag("node cnt is not enough to test shard, skip...\n");
    done_testing();
    exit 0;
}

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my $verbose = 0;

my $shard_block_size = '512M';
my $test_vol = undef;


my $filing = Test::AnyStor::Filing->new(
    addr        => $GMS_TEST_ADDR,
    not_umount  => 1,   # un-mount passively
    no_complete => 1,   # not call done_testing() due to $T
);

ok(1, '[SHARD] Preparing for shard volume test');

subtest 'create test account' => sub
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    $t->user_create(prefix => 'snap_test_user');
};

subtest 'create test zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    $t->cluster_network_zone_create(
        zonename    => 'test_zone',
        description => 'Network zone allow global access for testing',
        type        => 'netmask',
        zoneip      => '0.0.0.0',
        zonemask    => '0.0.0.0',
    );
};

subtest 'create test volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);
    my $node_cnt = scalar(@{$t->nodes});

    if ($node_cnt % 2)
    {
        $test_vol = $t->volume_create(
            volpolicy  => 'Distributed',
            capacity   => '20.0G',
            replica    => 2,
            node_count => $node_cnt,
            start_node => 0,
            pool_name  => 'vg_cluster',
            chaining   => 'true'
        );
    }
    else
    {
        $test_vol = $t->volume_create(
            volpolicy  => 'Distributed',
            capacity   => '20.0G',
            replica    => 2,
            node_count => $node_cnt,
            start_node => 0,
            pool_name  => 'vg_cluster',
        );

        my $res = $t->attach_arbiter(
            volume_name      => $test_vol,
            shard            => 'true',
            shard_block_size => $shard_block_size 
        );

        is( $res, 'true', 'Arbiter attach with shard');

        if (!defined $test_vol or $test_vol eq '')
        {
            fail('create test volume');
        }
        else
        {
            ok(1, 'create test volume');
        }
    }
};

subtest 'create share instances' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR, no_logout => 1);
    my $node_cnt = scalar(@{$t->nodes});

    $t->cluster_share_create(
        sharename => $test_vol,
        volume    => $test_vol,
        path      => $test_vol,
    );

    my $share_list = $t->cluster_share_list();

    my $find_flag = 0;

    for my $share (@$share_list)
    {
        if ($test_vol eq $share->{ShareName})
        {
            ok(1, 'share create check');
            $find_flag = 1;
            last;
        }
    }

    if (!$find_flag)
    {
        fail('share create check');
        next;
    }

    $t->cluster_share_update(
        sharename  => $test_vol,
        volume     => $test_vol,
        path       => $test_vol,
        CIFS_onoff => 'on',
        NFS_onoff  => 'on'
    );

    my $cifs_list = $t->cluster_share_cifs_list();

    $find_flag = 0;

    foreach my $each_cifs (@$cifs_list)
    {
        if ($each_cifs->{ShareName} eq $test_vol)
        {
            ok(1, 'cifs activate check');
            $find_flag = 1;
            last;
        };
    }

    if (!$find_flag)
    {
        fail('cifs activate check');
        next;
    }

    $t->cluster_share_cifs_setconf(active => 'on');

    #/cluster/share/cifs/update
    $t->cluster_share_cifs_update(
        sharename   => $test_vol,
        active      => 'on',
        share_right => 'read/write',
        access_zone => 'test_zone',
        zone_right  => 'allow',
        access_user => 'snap_test_user-1',
        user_right  => 'read/write',
    );

    my $nfs_list = $t->cluster_share_nfs_list();

    $find_flag = 0;

    foreach my $each_nfs (@$nfs_list)
    {
        if ($each_nfs->{ShareName} eq $test_vol)
        {
            ok(1, 'nfs activate check');
            $find_flag = 1;
            last;
        };
    }

    if (!$find_flag)
    {
        fail('nfs activate check');
        next;
    }

    $t->cluster_share_nfs_setconf(active => 'on');

    $t->cluster_share_nfs_update(
        sharename   => $test_vol,
        active      => 'on',
        access_zone => 'test_zone',
        zone_right  => 'read/write'
    );
};

subtest 'setup mount for client' => sub
{
    $filing->make_directory(dir => "/mnt/$test_vol");

    my %args = (
        type   => 'nfs',
        device => "$test_addr:/$test_vol",
        point  => "/mnt/$test_vol",
    );

    cmp_ok($filing->is_mountable(%args), '==', 1
        , "$test_addr:/$test_vol is mountable");

    cmp_ok($filing->mount(%args), '==', 0
        , "$test_addr:/$test_vol is mounted");
};

subtest '[SHARD1] sharded option check' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);
    my $node_cnt = scalar(@{$t->nodes});

    my ($res_on, undef)
        = $t->ssh_cmd(
            addr => $test_addr,
            cmd  => "gluster volume get $test_vol features.shard");

    my ($onoff) = $res_on =~ /features\.shard\s+([^\s]+)/g;

    cmp_ok($onoff, 'eq', 'on', "features.shard option is on");

    my ($res_blk, undef)
        = $t->ssh_cmd(
            addr => $test_addr,
            cmd  => "gluster volume get $test_vol features.shard-block-size");

    my ($blksize) = $res_blk =~ /features\.shard-block-size\s+([^\s]+)/x;

    cmp_ok($blksize, 'eq', '512MB', 'features.shard-block-size is 512MB');
};

subtest '[SHARD1] sharded file check' => sub
{
    my $node_cnt = scalar(@{$filing->nodes});

    $filing->io(
        point    => "/mnt/$test_vol",
        tool     => 'dd',
        dd_bs    => '512M',
        dd_count => '10',
    );

    my $file_exist = 0;

    foreach my $node (@{$filing->nodes})
    {
        my (@res, undef)
            = $filing->ssh_cmd(
                addr => $node->{Mgmt_IP}->{ip},
                cmd  => "ls -sh /volume/$test_vol".'_0/.shard/');

        print "============== $node->{Mgmt_IP}->{ip} ==============\n";
        print @res;
        print "\n";

        my $file_cnt = scalar(@res) - 1;

        $file_exist++ if (0 <= $file_cnt);
    }

    cmp_ok($file_exist, '==', $node_cnt, "File is split up into $node_cnt chunks");
};

subtest 'cleanup mount' => sub
{
    $filing->umount();
    $filing->rm(dir => "/mnt/$test_vol");
};

subtest 'cleanup test share instances' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    $t->cluster_share_cifs_setconf(active => 'off');
    $t->cluster_share_nfs_setconf(active => 'off');

    $t->cluster_share_update(
        sharename  => $test_vol,
        volume     => $test_vol,
        path       => $test_vol,
        CIFS_onoff => 'off',
        NFS_onoff  => 'off'
    );

    $t->cluster_share_delete(sharename => $test_vol);
};

subtest 'cleanup test volumes'  => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);
    my $node_cnt = scalar(@{$t->nodes});

    # delete volume
    is($t->volume_delete(volname => $test_vol), 0, 'cluster volume delete');

    # verify the volume is deleted
    $t->verify_volstatus(volname => $test_vol, exists => 0);
};

subtest 'cleanup test zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    $t->cluster_network_zone_delete(zonename => 'test_zone');
};

subtest 'cleanup test account' => sub
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    $t->user_delete(names => 'snap_test_user-1');
};

undef $filing;

done_testing();
