#!/usr/bin/env perl

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

our $GMSROOT;

BEGIN
{
    use Cwd qw/abs_path/;

    ($GMSROOT = abs_path($0)) =~ s/\/xt\/[^\/]*$//;

    unshift(@INC,
        "$GMSROOT/xt/lib",
        "$GMSROOT/libgms",
        "$GMSROOT/lib",
        '/usr/girasole/lib');
}

use Data::Dumper;
use Env;
use JSON qw/from_json/;
use Test::AnyStor::Account;
use Test::AnyStor::Auth;
use Test::AnyStor::Base;
use Test::AnyStor::ClusterFailure;
use Test::AnyStor::ClusterInfra;
use Test::AnyStor::ClusterPower;
use Test::AnyStor::ClusterVolume;
use Test::AnyStor::Dashboard;
use Test::AnyStor::Event;
use Test::AnyStor::Filing;
use Test::AnyStor::Manager;
use Test::AnyStor::Network;
use Test::AnyStor::Share;
use Test::AnyStor::Stage;
use Test::AnyStor::Status;
use Test::AnyStor::Util;
use Test::Most;

# UTF encoding trick for Data::Dumper
no warnings 'redefine';
*Data::Dumper::qquote   = sub { qq["${\(shift)}"] };
$Data::Dumper::Useperl  = 1;
$Data::Dumper::Sortkeys = 1;
use warnings 'redefine';

#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------
select((select(STDERR), $| = 1)[0]);
select((select(STDOUT), $| = 1)[0]);

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
p_printf("[%s] ******* Starting Merge-test for %s *******\n\n",
    get_time(), $ENV{GMS_TEST_ADDR});

die_on_fail();

set_failure_handler(
    sub
    {
        my $builder = shift;

        paint_err();
        BAIL_OUT("merge_test.t is bailed out");
        paint_reset();

        done_testing();
    }
);

#---------------------------------------------------------------------------
#   Cluster Infra test
#---------------------------------------------------------------------------
p_printf("[%s] Test for Cluster-Infrastructure will be performed...\n\n",
    get_time());

subtest 'Cluster-Infra' => sub
{
    my $t = Test::AnyStor::ClusterInfra->new(addr => $ENV{GMS_TEST_ADDR});

    $t->check_cluster_fine();

    # Dashboard
    $t->dashboard_scan("skip_volume_usage");

    my $debug_info = $t->get_debug();

    ok($debug_info->{Event} == 0, 'Debugging mode has disabled for "Event"');

    $t->set_debug(scope => 'Event', value => 'enable');

    $debug_info = $t->get_debug();

    ok($debug_info->{Event} == 1, 'Debuging mode has enabled for "Event"');

    return;
};

#---------------------------------------------------------------------------
#   Cluster status validation
#---------------------------------------------------------------------------
#p_printf("[%s] Test for cluster status will be performed...\n\n", get_time());
#
#subtest 'Cluster status' => sub
#{
#    sleep(60);
#
#    my $t = Test::AnyStor::Status->new(addr => $ENV{GMS_TEST_ADDR});
#
#    my $status = $t->get_all_status();
#
#    cmp_ok(ref($status), 'eq', 'HASH', 'status isa HASH');
#
#    diag("Cluster statuses: ${\explain($status)}");
#
#    ok(exists($status->{cluster}), 'status->cluster exists');
#    ok(exists($status->{cluster}->{status}),
#        'status->cluster->status exists');
#
#    cmp_ok(uc($status->{cluster}->{status}),
#        'eq', 'OK', 'Cluster status is "OK"');
#};

#---------------------------------------------------------------------------
#   Node status validation
#---------------------------------------------------------------------------
#p_printf("[%s] Test for node status will be performed...\n\n", get_time());
#
#subtest 'node status' => sub
#{
#    my $t = Test::AnyStor::Status->new(addr => $ENV{GMS_TEST_ADDR});
#
#    my $node_cnt  = scalar(@{$t->nodes});
#    my @hostnames = $t->gethostnm(start_node => 0, cnt => $node_cnt);
#
#    my $status = $t->get_nodes_status();
#
#    diag("Node statuses: ${\explain($status)}");
#
#    cmp_ok(ref($status), 'eq', 'HASH', 'status isa HASH');
#
#    foreach my $node (keys(%{$status}))
#    {
#        if (!grep { $_ eq $node } @hostnames)
#        {
#            fail("Invalid hostname in Status DB : $node");
#        }
#
#        cmp_ok(uc($status->{$node}->{status}),
#            'eq', 'OK', "$node status is \"OK\"");
#    }
#};

#---------------------------------------------------------------------------
#   Components status validation
#---------------------------------------------------------------------------
p_printf("[%s] Test for components status will be performed...\n\n",
    get_time());

subtest 'components status' => sub
{
    my $t = Test::AnyStor::Status->new(addr => $ENV{GMS_TEST_ADDR});

    for my $node (@{$t->{nodes}})
    {
        my $check = $t->check_components_status($node->{Mgmt_Hostname},
            $node->{Mgmt_IP}->{ip});

        ok($check == 0,
            $node->{Mgmt_Hostname} . ' components status is "OK"');
    }
};

#---------------------------------------------------------------------------
#   Manager test
#---------------------------------------------------------------------------
p_printf("[%s] Test for manager will be performed...\n\n", get_time());

subtest 'Manager' => sub
{
    my $t = Test::AnyStor::Manager->new(addr => $ENV{GMS_TEST_ADDR});

    my $info = $t->info(ID => 'admin');

    $t->update(ID => 'admin');
};

#---------------------------------------------------------------------------
#   Event/Task test
#---------------------------------------------------------------------------
p_printf("[%s] Test for event/task will be performed...\n\n", get_time());

subtest 'EventAndTask' => sub
{
    my $t = Test::AnyStor::Dashboard->new(addr => $ENV{GMS_TEST_ADDR});

    my @events = ();

    @events = $t->event_list();

    diag(sprintf("Events(ALL): %d", scalar @events));

    @events = $t->event_list(type => 'MONITOR');

    diag(sprintf("Events(category => 'MONITOR'): %d", scalar @events));

    @events = $t->event_list(level => 'WARNING');

    diag(sprintf("Events(level => 'WARN'): %d", scalar @events));

    @events = $t->event_list(level => 'ERROR');

    diag(sprintf("Events(level => 'ERROR'): %d", scalar @events));

    my @tasks = ();

    @tasks = $t->task_list();

    diag(sprintf("Tasks(ALL): %d", scalar @tasks));

    @tasks = $t->task_list(type => 'MONITOR');

    diag(sprintf("Tasks(category => 'MONITOR'): %d", scalar @tasks));

    @tasks = $t->task_list(level => 'WARNING');

    diag(sprintf("Tasks(level => 'WARN'): %d", scalar @tasks));

    @tasks = $t->task_list(level => 'ERROR');

    diag(sprintf("Tasks(level => 'ERROR'): %d", scalar @tasks));

    return 0;
};

#---------------------------------------------------------------------------
#   User/Group test
#---------------------------------------------------------------------------
p_printf("[%s] Test for account management will be performed...\n\n",
    get_time());

my @users;
my @groups;

subtest 'Account' => sub
{
    my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});

    # 그룹 추가
    @groups = $t->group_create(prefix => 'testgroup', number => 3);

    # 사용자 추가
    @users = $t->user_create(prefix => 'testuser', number => 9);

    # 사용자 그룹 참여
    for (
        my $i = 0, my $cut = int(scalar(@users) / scalar(@groups));
        $i < @groups;
        $i++
        )
    {
        $t->join(
            group   => $groups[$i],
            members => [
                grep { defined($_); }
                    @users[$i * $cut .. (($i + 1) * $cut) - 1]
            ],
        );
    }

    return 0;
};

#---------------------------------------------------------------------------
#   Authentication test
#---------------------------------------------------------------------------
#p_printf("[%s] Test for authentication will be performed...\n\n", get_time());
#
#subtest 'Auth' => sub
#{
#    my $t = Test::AnyStor::Auth->new(addr => $ENV{GMS_TEST_ADDR});
#
#    for (my $i=0; $i<10; $i++)
#    {
#        system("ping -c 1 $i &>/dev/null");
#
#        if ($? == -1)
#        {
#            paint_err();
#            fail("Failed to execute: ping: $!");
#            paint_reset();
#            goto RETURN;
#        }
#        elsif ($? >> 8)
#        {
#            if ($i == 9)
#            {
#                paint_err();
#                fail("This test will be skipped because Domain Controller is not working");
#                paint_reset();
#                goto RETURN;
#            }
#
#            next;
#        }
#
#        diag("Domain Controller is working normally");
#        last;
#    }
#
#    # ADS 참여
#    if ($t->ads_enable(
#            realm => 'anycloud2.gluesys.com',
#            dcs   => ['dc-2012r2.anycloud2.gluesys.com'],
#            admin => 'administrator',
#            pwd   => 'P@ssw0rd1',
#            dns   => '192.168.3.70'))
#    {
#        return -1;
#    }
#
#    # ADS 참여 해제
#    if ($t->ads_disable(
#            admin => 'administrator',
#            pwd   => 'P@ssw0rd1'))
#    {
#        return -1;
#    }
#
#RETURN:
#    return 0;
#};

#---------------------------------------------------------------------------
#   Cluster volume test
#---------------------------------------------------------------------------
p_printf("[%s] Test for cluster volume management will be performed...\n\n",
    get_time());

my @volumes;

subtest 'Volume-Pool' => sub
{
    local @ARGV = $ENV{GMS_BUILD_CONFIG};
    local $/    = undef;

    my $lines     = <>;
    my $config_db = from_json($lines, {utf8 => 1});

    my @vpool_pvs;

    foreach my $pv (@{$config_db->{pvs}})
    {
        $pv =~ s/^[\/dev]*\/{0,1}//;

        push(@vpool_pvs, {Name => "/dev/$pv"});
    }

    my $t = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});

    my @nodes;

    foreach my $node (@{$t->nodes})
    {
        push(
            @nodes,
            {
                Hostname => $node->{Mgmt_Hostname},
                PVs      => \@vpool_pvs
            }
        );
    }

    my $res = $t->volume_pool_create(
        pool_name => 'vg_cluster',
        provision => 'thick',
        pooltype  => 'Gluster',
        nodes     => \@nodes,
        purpose   => 'for_data',
    );

    diag(explain($res));

    ok(defined($res), 'Volume pool is created successfully: vg_cluster');
};

subtest 'Volume' => sub
{
    my $t   = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});
    my $vol = 'vol_test_dist';
    my $node_cnt = scalar(@{$t->nodes});
    my $replica  = 1;
    my $res      = undef;

    # 2배수 노드일 경우 복제수 2
    $replica = 2 if (!($node_cnt % 2));

    # 3배수 노드일 경우, 체인 모드 볼륨 테스트
    if (!($node_cnt % 3))
    {
        p_printf("Chaining volume: nodes=$node_cnt, replica=2\n");

        $res = $t->volume_create_distribute(
            pool_name  => 'vg_cluster',
            volname    => $vol,
            capacity   => '10G',
            node_count => $node_cnt,
            replica    => 2,
            chaining   => 'true'
        );
    }

    # 일반 볼륨 테스트
    else
    {
        p_printf("Distributed volume: nodes=$node_cnt, replica=$replica\n");

        $res = $t->volume_create_distribute(
            pool_name  => 'vg_cluster',
            volname    => $vol,
            capacity   => '10G',
            node_count => $node_cnt,
            replica    => $replica,
        );
    }

    if (!cmp_ok(
        $res, 'eq', $vol,
        sprintf('Cluster volume is created: %s', $res // 'undef')
    ))
    {
        fail('Test bailed out due to cluster volume creation failure');
        exit 255;
    }

    push(@volumes, $vol);
};

#---------------------------------------------------------------------------
#   Zone test
#---------------------------------------------------------------------------
p_printf("[%s] Test for Zone management will be performed...\n\n",
    get_time());

my @zones;

subtest 'Zone' => sub
{
    my $t    = Test::AnyStor::Network->new(addr => $ENV{GMS_TEST_ADDR});
    my $zone = 'TEST_GLOBAL';

    $t->cluster_network_zone_create(
        zonename    => $zone,
        description => 'Network zone allow global access for testing',
        type        => 'netmask',
        zoneip      => '0.0.0.0',
        zonemask    => '0.0.0.0',
    );

    push(@zones, $zone);
};

#---------------------------------------------------------------------------
#   Share test
#---------------------------------------------------------------------------
p_printf("[%s] Test for share management will be performed...\n\n",
    get_time());

my @shares;

subtest 'Preparing for Share' => sub
{
    my $t = Test::AnyStor::Filing->new(addr => $ENV{GMS_TEST_ADDR});

    (my $mgmtip = $ENV{GMS_TEST_ADDR}) =~ s/:\d+//;

    my $share = {
        name   => 'test_share',
        volume => $volumes[0],
        path   => '/test_share',
        ftp    => 0,
        nfs    => 1,
        smb    => 1,
        afp    => 0,
    };

    $t->remote($mgmtip);
    $t->make_directory(
        dir     => sprintf('/export/%s/%s', $volumes[0], $share->{path}),
        options => ['-p', '-m 777']
    );

    push(@shares, $share);
};

my $testuser = $users[int(rand(scalar(@users)))];

subtest 'Share' => sub
{
    my $t     = Test::AnyStor::Share->new(addr => $ENV{GMS_TEST_ADDR});
    my $share = $shares[0];

    # 공유 생성
    $t->cluster_share_create(
        sharename   => $share->{name},
        volume      => $share->{volume},
        path        => $share->{path},
        description => 'Test share',
    );

    # 공유 활성화
    if ($share->{nfs})
    {
        $t->cluster_share_nfs_set_config(active => 'on',);

        $t->cluster_share_nfs_enable(sharename => $share->{name},);

        $t->cluster_share_nfs_update(
            sharename => $share->{name},
            active    => 'yes',
        );

        $t->cluster_share_nfs_set_network_access(
            sharename => $share->{name},
            zone      => 'TEST_GLOBAL',
            right     => 'read/write',
        );
    }

    if ($share->{smb})
    {
        $t->cluster_share_smb_set_config(active => 'on',);

        $t->cluster_share_smb_enable(sharename => $share->{name},);

        $t->cluster_share_smb_set_user_access(
            sharename => $share->{name},
            user      => $testuser,
            right     => 'read/write',
        );

        $t->cluster_share_smb_set_network_access(
            sharename => $share->{name},
            zone      => 'TEST_GLOBAL',
            right     => 'allow',
        );
    }

    sleep 10;    # wait for filing service reloading
};

#---------------------------------------------------------------------------
#   Filing test
#---------------------------------------------------------------------------
p_printf("[%s] Filing protocol access test will be performed...\n\n",
    get_time());

my @points = ();

subtest 'Filing' => sub
{
    my $t = Test::AnyStor::Filing->new(addr => $ENV{GMS_TEST_ADDR});

    # 마운트
    #   - NFS
    #   - SMB

    my $target;
    my $service_ip;

    (my $mgmtip = $ENV{GMS_TEST_ADDR}) =~ s/:\d+//;

    foreach my $node (@{$t->nodes})
    {
        if ($node->{Mgmt_IP}->{ip} eq $mgmtip)
        {
            $target = $node;
        }

        if (ref($node->{Service_IP}) eq 'ARRAY'
            && defined($node->{Service_IP}->[0])
            && !defined($service_ip))
        {
            $service_ip = $node->{Service_IP}->[0];
        }
    }

    if (!defined($target))
    {
        paint_err();
        fail('Could not find the matched node for this testing!');
        paint_reset();
        return -1;
    }

    if (!defined($service_ip))
    {
        paint_err();
        fail("Target does not have any service IP!");
        paint_reset();
        return -1;
    }

    foreach my $type (qw/nfs cifs/)
    {
        my $addr = $service_ip;

        foreach my $share (@shares)
        {
            my $device;
            my $point = "/mnt/$type/$share->{name}";
            my @options;

            if (-d $point)
            {
                system("umount $point");

                my $out = `rm -rf $point`;

                if ($? == -1)
                {
                    fail("Failed to execute: rm -rf $point: $!");
                }
                elsif ($? >> 8)
                {
                    fail("Failed to delete: $point: $out");
                }
            }

            if ($type eq 'nfs')
            {
                # <SVC_IP>:<EXPORT_PATH or TAG>
                $device = sprintf('%s:/%s', $addr, $share->{name});

                # refered #4491
                @options = ('nolock,vers=3');
            }
            elsif ($type eq 'cifs')
            {
                # //<SVC_IP>/<SHARE_NAME>
                $device  = sprintf('//%s/%s', $addr, $share->{name});
                @options = ("username=$testuser", 'password=gluesys!!');

#               @options = ("guest");
            }

            if (!-d $point)
            {
                system("mkdir -p $point")
                    && fail("Failed to make directory: $point: $!");

                push(@points, $point);
            }

            $t->show_mount(
                type  => $type,
                ip    => $addr,
                share => $share->{name},
                user  => $testuser,
                pass  => 'gluesys!!'
            );

            $t->mount(
                type    => $type,
                device  => $device,
                point   => $point,
                options => \@options,
            ) && die "Failed to mount $type: $device => $point";

            # 입출력 by hgichon
            $t->io_bonnie(
                points   => [$point],
                rand_num => 1,
                rand_max => 2048,
                rand_min => 1024,
                dir_num  => 100,
            ) && die "Failed to IO";
        }
    }

    # 입출력
#    $t->io(
#        # 메모리 크기의 2배로 설정하도록...
#        memtotal => '1G',
#        rand_num => 1,
#        rand_max => 2048,
#        rand_min => 1024,
#        uid      => 0,
#        gid      => 0,
#        count    => 1,
#    );
};

#---------------------------------------------------------------------------
#   Dashboard test
#---------------------------------------------------------------------------
p_printf("[%s] Test for Cluster Infrastructure performed...\n\n", get_time());

subtest 'Cluster-Infra' => sub
{
    my $t = Test::AnyStor::ClusterInfra->new(addr => $ENV{GMS_TEST_ADDR});

    # Dashboard
    $t->dashboard_scan();

    return;
};

#---------------------------------------------------------------------------
#   Cleaning test
#---------------------------------------------------------------------------
p_printf("[%s] Delete share used to test ...\n\n", get_time());

subtest 'Clean-up : Share' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $ENV{GMS_TEST_ADDR});

    foreach my $share (@shares)
    {
        $t->cluster_share_delete(sharename => $share->{name});
    }

    return;
};

subtest 'Clean-up : Directory' => sub
{
    my $t = Test::AnyStor::Filing->new(addr => $ENV{GMS_TEST_ADDR});

    (my $mgmtip = $ENV{GMS_TEST_ADDR}) =~ s/:\d+//;

    $t->remote(undef);
    $t->rm(dir => $_) foreach (@points);

    $t->remote($mgmtip);
    $t->rm(dir => $_->{path}) foreach (@shares);

    return;
};

subtest 'Clean-up : Zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $ENV{GMS_TEST_ADDR});

    foreach my $zone (@zones)
    {
        $t->cluster_network_zone_delete(zonename => $zone);
    }
};

subtest 'Clean-up : Volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});

    foreach my $vol (@volumes)
    {
        my $rv = $t->volume_delete(
            pool_name => 'vg_cluster',
            volname   => $vol,
        );

        ok($rv == 0, "Volume was deleted: vg_cluster/$vol");
    }

    my $rv = $t->volume_pool_remove(pool_name => 'vg_cluster');

    ok($rv, 'Volume pool was deleted: vg_cluster');
};

subtest 'Clean-up : Account' => sub
{
    my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});

    # 사용자 정리
    $t->user_delete(names => \@users);

    # 그룹 정리
    $t->group_delete(names => \@groups);
};

#---------------------------------------------------------------------------
#   Stage test
#---------------------------------------------------------------------------
p_printf("\n[%s] ******* Cluster Stage Test for Merge test *******\n\n",
    get_time(), $ENV{GMS_TEST_ADDR});

subtest 'Cluster Stage : Support' => sub
{
    # Set support
    my $t = Test::AnyStor::Stage->new(
        addr      => $ENV{GMS_TEST_ADDR},
        no_logout => 1
    );

    my $res;

    $t->cluster_stage_set(
        stage => 'support',
        scope => 'cluster',
        data  => ''
    );

    # Support check
    for (my $try = 0; $try < 300; $try++)
    {
        $res = $t->cluster_stage_test('Support', 300);
        last if (!$res);
    }

    # Result
    ok(!$res, 'Cluster Stage : Support succeed');

    # Restore
    $t->cluster_stage_set(
        stage => 'running',
        scope => 'cluster',
        data  => ''
    );

    # Running check
    for (my $try = 0; $try < 300; $try++)
    {
        $res = $t->cluster_stage_test('Running', 300);

        last if (!$res);
    }

    # Result
    ok(!$res, 'Cluster Stage : Running succeed');
};

#---------------------------------------------------------------------------
#   Event validation
#---------------------------------------------------------------------------
subtest 'Event Validation' => sub
{
    my $sleep_secs = 60;

    p_printf("[%s] Waiting to collect latest events for %ds...\n\n",
        get_time(), $sleep_secs);

    sleep($sleep_secs);

    my $t = Test::AnyStor::Event->new(addr => $ENV{GMS_TEST_ADDR});

    #ok($t->event_validate() == 0, 'Event Validation');

    my $debug_info = $t->get_debug();

    ok($debug_info->{Event} == 1, 'Debugging mode has enabled for "Event"');

    $t->set_debug(scope => 'Event', value => 'disable');

    $debug_info = $t->get_debug();

    ok($debug_info->{Event} == 0, 'Debuging mode has disabled for "Event"');

    return;
};

#---------------------------------------------------------------------------
#   Report
#---------------------------------------------------------------------------
#p_printf("\nGenerating test report for this test...\n\n");
#
#subtest 'Report Generating' => sub
#{
#    # 엑셀? HTML? 전자우편?
#    #   - 노드별 로그는 포함
#    my $srcip = $ENV{GMS_TEST_ADDR};
#
#    ok(1);
#};

# 검사 종료
done_testing();
