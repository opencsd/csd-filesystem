#!/usr/bin/perl -I/usr/gms/t/lib

BEGIN {
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname( rel2abs(__FILE__) );
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift( @INC,
        "$ROOTDIR/perl5/lib/perl5", "$ROOTDIR/lib",
        "$ROOTDIR/libgms",          "$ROOTDIR/t/lib",
        "/usr/girasole/lib" );
}

use Env;
use Test::Most;

use Test::AnyStor::Base;
use Test::AnyStor::Account;
use Test::AnyStor::Network;
use Test::AnyStor::Share;
use Test::AnyStor::ClusterVolume;
use Test::AnyStor::Network;
use Test::AnyStor::Filing;
use Test::AnyStor::Time;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my $verbose = 0;
my @hostnms = ();
my @mgmtips = ();

my $filing = Test::AnyStor::Filing->new(
    addr       => $GMS_TEST_ADDR,
    no_login   => 1,
    not_umount => 1
    quiet      => $verbose ? 0 : 1,
);

ok(1, "[TRIM_0] Preparing for thin volume trimming test");

my $test_vol = undef;

subtest 'create test account' => sub 
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR);

    $t->user_create(prefix => 'trim_test_user');
};

subtest 'create test zone' => sub
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

subtest 'create test volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @tmp = $t->gethostnm(start_node => 0, cnt => scalar @{$t->nodes});

    my @nodeinfo = ();
    push(@nodeinfo, { Hostname => $_ }) for (@tmp);

    my $res = $t->volume_pool_create(
        pooltype => 'thin',
        basepool => 'vg_cluster',
        capacity => '30G',
        nodeinfo => \@nodeinfo,
    );

    if (!$res)
    {
        fail('Fail to create thin volume pool on vg_cluster');
    }
    else
    {
        ok(1, 'thin volume pool create');
    }
};

subtest 'create test volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $node_cnt = scalar(@{$t->nodes});

    $test_vol = $t->volume_create(
        volpolicy  => 'Distributed',
        capacity   => '20.0G',
        replica    => 1,
        node_count => $node_cnt,
        start_node => 0,
        pool_name  => 'tp_cluster',
    );

    if (!defined $test_vol or $test_vol eq '')
    {
        fail('create test volume');
    }
    else 
    {
        ok(1, 'create test volume');
    }
};

subtest "create share instances" => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    $t->cluster_share_create(
        sharename => $test_vol,
        volume    => $test_vol,
        path      => $test_vol,
    );

    my $share_list = $t->cluster_share_list();

    my $find_flag = 0;

    for my $share (@{$share_list})
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

    foreach my $each_cifs (@{$cifs_list})
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

    # /cluster/share/cifs/update
    $t->cluster_share_cifs_update(
        sharename   => $test_vol,
        active      => 'on',
        share_right => 'read/write',
        access_zone => 'test_zone',
        zone_right  => 'allow',
        access_user => 'trim_test_user-1',
        user_right  => 'read/write',
    );

    my $nfs_list = $t->cluster_share_nfs_list();

    $find_flag = 0;

    foreach my $each_nfs (@{$nfs_list})
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

subtest "setup mount for client" => sub
{
    ok(1, 'dummy');

    $filing->make_directory(dir => "/mnt/$test_vol");

    my %args = (
        type   => 'nfs',
        device => "$test_addr:/$test_vol",
        point  => "/mnt/$test_vol",
    );

    if ($filing->is_mountable(%args))
    {
        $filing->mount(%args);
    }
};

subtest '[TRIM_1] Trim test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(
        addr      => $GMS_TEST_ADDR,
        no_logout => 1
    );

    # Regex exp
    my $re .='.*?';
    $re .='[+-]?\\d*\\.\\d+(?![-+0-9\\.])';
    $re .='.*?';
    $re .='([+-]?\\d*\\.\\d+)(?![-+0-9\\.])';

    # 1. file write on volume
    $filing->io(
        point    => "/mnt/$test_vol",
        tool     => 'dd',
        dd_bs    => '512M',
        dd_count => 4
    );

    # 3. check lv data 
    my $node_cnt       = scalar(@{$t->nodes});
    my @hostnms        = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @stgips         = $t->hostnm2stgip(hostnms => \@hostnms);
    my @mgmtips        = $t->hostnm2mgmtip(hostnms => \@hostnms);
    my @sorted_mgmtips = sort(@mgmtips);

    my $cnt = 0;
    my @bef_lvs = ();

    foreach my $node_ip (@sorted_mgmtips)
    {
        my ($bef_res, undef) = $t->ssh_cmd(
            addr => $node_ip,
            cmd  => "lvs |grep $test_vol"
        );

        if ($bef_res =~ m/$re/is)
        {
            $bef_lvs[$cnt]= $1;
            diag("Bef lv size [$cnt][$node_ip]: $bef_lvs[$cnt]");
            $cnt++;
        }
    }

    # 4. file delete
    $filing->rm(target => "/mnt/$test_vol/dummy.txt");

    my ($time, undef) = $t->ssh_cmd(addr => $test_addr, cmd => "date +%s");

    # 5. clock trans
    subtest "[TRIM_1_0]datetime config" => sub
    {
        my $t = Test::AnyStor::Time->new(addr => "$test_addr:80", no_logout => 1);

        # TODO test date setting after time
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
            = localtime($time+604800);

        $year += 1900;
        $mon += 1;

        my $test_date = sprintf("%.4d-%.2d-%.2d %.2d:%.2d:%.2d", $year, $mon, $mday, $hour, $min, $sec);

        my $ret = $t->time_config(DateTime => $test_date, NTP_Enabled => 'false');
    };

    # trimming plugin check the lvs per five minutes
    sleep 300;

    # 6. check usage
    my @aft_lvs = ();
    $cnt = 0;

    foreach my $node_ip (@sorted_mgmtips)
    {
        my ($aft_res, undef) = $t->ssh_cmd(
            addr => $node_ip,
            cmd  => "lvs |grep $test_vol"
        );

        if ($aft_res =~ m/$re/is)
        {
            $aft_lvs[$cnt]= $1;
            diag("Aft lv size [$cnt][$node_ip]: $aft_lvs[$cnt]");
            $cnt++;
        }
    }

    my $jdg = 0;

    for ($cnt=0; $cnt<=$#sorted_mgmtips; $cnt++)
    {
        if (defined($bef_lvs[$cnt]) && defined($aft_lvs[$cnt]))
        {
            diag("Compare: [Bef]:$bef_lvs[$cnt] > [Aft]$aft_lvs[$cnt]");

            if ($bef_lvs[$cnt] > $aft_lvs[$cnt])
            {
                $jdg = 1;
            }
        }
    }

    # 7. judgement of trim test
    ok ($jdg, "success to trimming of thin lv");


};

subtest "cleanup mount" => sub 
{
    ok(1, 'dummy');

    $filing->umount();
};

subtest 'cleanup test share instances' => sub 
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

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
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    # delete volume
    my $res = $t->volume_delete(volname => $test_vol);

    is($res, 0, 'cluster volume delete');

    # verify the volume is deleted
    $t->verify_volstatus(volname => $test_vol, exists => 0);
};

subtest 'cleanup test volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $t->volume_pool_remove(poolname => 'tp_cluster');
};


subtest 'cleanup test zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_zone_delete(zonename => 'test_zone');
};

subtest 'cleanup test account' => sub
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR);

    $t->user_delete(names => 'trim_test_user-1');
};

done_testing();
