package Test::AnyStor::ClusterFailure;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';
use Test::Most;
use Data::Dumper;
use List::Util qw/shuffle/;

use Test::AnyStor::Util;
use Test::AnyStor::Base;
use Test::AnyStor::Base;
use Test::AnyStor::Manager;
use Test::AnyStor::Account;
use Test::AnyStor::ClusterVolume;
use Test::AnyStor::ClusterInfra;
use Test::AnyStor::Dashboard;
use Test::AnyStor::Filing;
use Test::AnyStor::Network;
use Test::AnyStor::Share;

extends 'Test::AnyStor::Base';

use base 'Exporter';

our @EXPORT = qw/
    ping_check_list
    /;

has 'no_logout' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

## internal function
## 인자로 받은 모든 노드의 상태를 체크한다. 한놈이라도 비정상시 에러 리턴
## 타임아웃 발생시 에러 리턴한다.
## 인자 :
##      %vm_info : VM 설정
##      %args    : 인자값들
##      $node    : 관리 IP
##      $type    : 장애 유형 (service/power/storage)
##      $mode    : 상태 (up/down)
##      $flag    : skip test if all node ctdb status is ok (null / no_check)

sub full_status_check
{
    my $self = shift;

    my ($vm_info, $args, $node) = (shift, shift, shift);
    my ($comp,    $mode, $flag) = (shift, shift, shift);

    # 1. Check Event
    # 2. Node Status
    # 3. Cluster Status

    for my $n (keys(%{$vm_info->{vm_nodes}}))
    {
        next if ($comp eq 'power' && $mode eq 'down' && $n eq $node);

        $self->info_diag(sprintf("ctdb on(%s)\n", $n));

        call_system("ssh $n ctdb ip");
        call_system("ssh $n ctdb status");

        $self->info_diag(sprintf("starting merge test(%s)\n", $n));

        goto ERROR_CHK if (stat_chk($n));
    }

    # CTDB Restore Checking
    my $node_cnt = keys(%{$vm_info->{vm_nodes}});
    my $ctdb_check_cmd
        = 'ctdb status | grep OK | wc -l | xargs echo  | grep ' . $node_cnt;
    my $ctdb_status = 0;

    # check for service/management network allinone mode
    if ($mode eq 'up' && !defined($flag))
    {
        p_w_printf("CTDB Status Recovery Checking (%s)\n", $args->{wait});

        for (my $cnt = 0; $cnt < $args->{wait}; $cnt++)
        {
            if (call_system("ssh $node \"$ctdb_check_cmd\"") == 0)
            {
                $ctdb_status = 1;
                last;
            }
            else
            {
                $ctdb_status = 0;
                p_w_printf("CTDB Status abnormal waiting ...(%s/%s)\n",
                    $cnt, $args->{wait});
            }

            sleep 1;
        }

        if ($ctdb_status != 1)
        {
            p_e_printf("Failed to CTDB Status\n");

            call_system("ssh $node ctdb ip");
            call_system("ssh $node ctdb status");

            goto ERROR_CHK;
        }

        p_e_printf("CTDB Status Successful\n");
    }

    my $res = $self->service_io_check($args);

    for my $n (keys(%{$vm_info->{vm_nodes}}))
    {
        next if ($comp eq 'power' && $mode eq 'down' && $n eq $node);

        $self->info_diag(sprintf("ctdb on(%s)\n", $n));

        call_system("ssh $n ctdb ip");
        call_system("ssh $n ctdb status");
    }

    goto ERROR_CHK if ($res != 0);

    return 0;

ERROR_CHK:
    $self->err_diag(
        sprintf('[%s] not ok: full_status check failed', get_time()));
    return -1;
}

sub service_io_check
{
    my $self = shift;
    my ($args) = @_;

    # 4. CTDB ping Check
    goto ERROR_SVC_IO if (ping_check_list($args->{svc_list}, $args->{wait}));

    my $cmd;

    # 5. DF
    for my $sip (@{$args->{svc_list}})
    {
        $cmd = "df /mnt/cifs/$sip | grep $sip";

        goto ERROR_SVC_IO if (retry_cmd($cmd, $args->{fail_wait}));

        $cmd = "df /mnt/nfs/$sip | grep $sip";

        goto ERROR_SVC_IO if (retry_cmd($cmd, $args->{fail_wait}));
    }

    # 6. Service IO
    #
    for my $sip (@{$args->{svc_list}})
    {

        $cmd = "dd if=/dev/zero of=/mnt/cifs/$sip/cifs_dd.1M bs=1M count=1";
        goto ERROR_SVC_IO if retry_cmd($cmd, $args->{fail_wait});

        $cmd = "dd if=/dev/zero of=/mnt/nfs/$sip/nfs_dd.1M bs=1M count=1";
        goto ERROR_SVC_IO if retry_cmd($cmd, $args->{fail_wait});
    }

    return 0;

ERROR_SVC_IO:
    $self->err_diag(
        sprintf("[%s]not ok :service io check failed", get_time()));
    return -1;
}

## internal function
## 인자로 받은 명령어를 반복 수행한다.
sub ping_check_list
{
    my ($nodes, $wait, $mode) = @_;

    my $cnt         = $wait;
    my $boot_up_cnt = 0;

    my %notbooted;

    $mode = 'up' if (!defined($mode));

    for my $sip (@{$nodes})
    {
        $notbooted{$sip} = '';
    }

    while (1)
    {
        diag(
            sprintf(
                "[%s] %d ip %s, retry (%d/%d)\n",
                get_time(), $boot_up_cnt, $mode, $wait - $cnt--, $wait
            )
        );

        for my $node (keys(%notbooted))
        {
            my $ret = isboot_use_ping($node);

            if (($ret && $mode eq 'up')
                || (!$ret && $mode eq 'down'))
            {
                $boot_up_cnt++;
                delete($notbooted{$node});
            }
        }

        last if (scalar(keys(%notbooted)) < 1);

        return 1 if ($cnt < 1);
    }

    return 0;
}

## internal function
## 인자로 받은 명령어를 반복 수행한다.

sub retry_cmd
{
    my ($cmd, $wait) = @_;

    for (my $i = 0; $i < $wait; $i++)
    {
        diag(sprintf('[%d][%s] %s', $i + 1, get_time(), $cmd));

        return 0 if (!call_system($cmd));
        sleep 1;
    }

    return 1;
}

## internal function
## 인자로 받은 모든 노드의 상태를 체크한다. 한놈이라도 비정상시 에러 리턴
## 타임아웃 발생시 에러 리턴한다.
## 인자 :
##      @nodes : 노드 IP 리스트
##      %args  : 인자값들
sub node_status_check
{
    my $self = shift;
    my ($nodes, $args) = @_;

    my @booted      = ();
    my %notbooted   = ();
    my $boot_up_cnt = 0;

    my $cnt = $args->{wait};

    for my $n (@{$nodes})
    {
        $notbooted{$n} = '';
    }

    while ($cnt--)
    {
        $self->info_diag(
            sprintf(
                "[%s] Nodes status checking, retry (%d/%d)\n",
                get_time(), $args->{wait} - $cnt,
                $args->{wait}
            )
        );

        for my $node (keys(%notbooted))
        {
            if (cluster_status_api($node))
            {
                $self->info_diag(
                    sprintf(
                        "[%s] %s node status online\n", get_time(), $node
                    )
                );

                $boot_up_cnt++;

                delete($notbooted{$node});

                # alghost: 모든 노드가 부팅 완료된 경우 pass
                return 0 if ($boot_up_cnt == scalar(@{$nodes}));

                # 임시로 mds 2개 이상이 부팅 완료면 pass 하기로 함
                #if ( $boot_up_cnt + 1 >= scalar @{$nodes} )
#                if (! defined $args->{full_status_check} and scalar @{$nodes} > 2)
#                {
#                    return 0 if($boot_up_cnt + 1 >= scalar @{$nodes});
#                }
#                else{
#                    return 0 if($boot_up_cnt == scalar @{$nodes});
#                }
            }
            else
            {
                $self->warn_diag("[$node] status is abnormal");
            }
        }

        sleep(1);
    }

    return -1;
}

## internal function
## 인자로 받은 모든 노드를 리부팅하고, 모든 노드가 ping 이 될때까지 기다린다.
## 타임아웃 발생시 에러 리턴한다.
## 인자 :
##      @nodes : 노드 IP 리스트
##      %args  : 인자값들
sub reboot_all
{
    my $self = shift;
    my ($nodes, $args, $vm_info) = @_;
    my @booted      = ();
    my %notbooted   = ();
    my $boot_up_cnt = 0;

    my @s_nodes        = shuffle(@{$nodes});
    my $max_rand_sleep = 0;

    $self->info_diag(sprintf("Reboot Ordering ...@s_nodes\n"));

    for my $node (@s_nodes)
    {
        my $rand_sleep
            = int($args->{count} % 2) == 1
            ? int(rand($args->{delay}))
            : 0;

        $max_rand_sleep = $rand_sleep if ($rand_sleep > $max_rand_sleep);

        if (($args->{total} / 3) > $args->{count})
        {
            shutdown_node_ssh($node, '', $rand_sleep);

            $self->info_diag(
                sprintf(
                    "[%s] %s node shutdown, normally sleep(%d)\n",
                    get_time(), $node, $rand_sleep
                )
            );
        }
        else
        {
            shutdown_node_ssh($node, 'force', $rand_sleep);

            $self->warn_diag(
                sprintf(
                    "[%s] %s node shutdown, force , sleep(%d)\n",
                    get_time(), $node, $rand_sleep
                )
            );
        }

        $notbooted{$node} = '';
    }

    return -1 if (ping_check_list(\@s_nodes, $args->{wait}, 'down'));

    $self->info_diag(
        "all nodes goes down, check rebooting... (timeout: $args->{wait})\n");

    sleep 10;

    for my $node (@s_nodes)
    {
        vm_ctl($node, $vm_info, 'stop',  'hard');
        vm_ctl($node, $vm_info, 'start', 'soft');
    }

    return ping_check_list(\@s_nodes, $args->{wait}, 'up') ? -1 : 0;
}

##
## external func
##
sub reboot_basic_test
{
    my $self = shift;
    my ($nodes, $args, $vm_info) = @_;

    $self->info_diag(
        sprintf(
            "[%d th] All Node Reboot test is started (%s)\n",
            $args->{count}, get_time()
        )
    );

    goto ERROR_RET
        if ($self->reboot_all($nodes, $args, $vm_info)
        || $self->node_status_check($nodes, $args));

    my $cnt = $args->{wait} * 3;

    while ($cnt--)
    {
        $self->warn_diag(
            sprintf(
                "[%s] Wait Cluster Fine ... retry (%d/%d)\n",
                get_time(), $args->{wait} * 3 - $cnt,
                $args->{wait}
            )
        );

        sleep(1);

        if (cluster_status_api(@{$nodes}[0]))
        {
            my $status = 0;

            ok('Cluster fine detected!');

            my $res = $self->service_io_check($args);

            goto ERROR_RET if ($res != 0);

            for my $node (@{$nodes})
            {
                goto ERROR_RET if (stat_chk($node));

                $self->info_diag(
                    sprintf(
                        "[%s] Wait for 30 secs to recover gluster daemons\n",
                        get_time())
                );

                sleep(30);
            }

            last;
        }
    }

    goto ERROR_RET if ($cnt < 1);

    ok("[$args->{count} TH] Bootup Test Success!!!");

    return 0;

ERROR_RET:
    $self->err_diag(
        sprintf(
            "[%s TH][%s]not ok :AC2 GMS reboot test is failed)\n",
            $args->{count}, get_time()
        )
    );

    return -1;
}

sub power_test
{
    my $self = shift;
    my ($vm_info, $args) = @_;

    my $error_cnt    = 0;
    my $node_cnt     = 0;
    my @manage_nodes = ();

    for my $node (keys(%{$vm_info->{vm_nodes}}))
    {
        push @manage_nodes, $node;
    }

    $args->{full_status_check} = 1;

    $self->info_diag(
        sprintf("\n[%s][Single mode] Power Fail TEST\n", get_time()));

    for my $node (keys(%{$vm_info->{vm_nodes}}))
    {
        $node_cnt++;

        $self->warn_diag(
            sprintf(
                "[%s][%s][%s th] Power down...",
                get_time(),
                $node,
                $node_cnt
            )
        );

        $error_cnt++
            if (vm_ctl($node, $vm_info, 'stop', 'hard')
            || $self->full_status_check($vm_info, $args, $node, 'power',
                'down'));

        $self->warn_diag(
            sprintf(
                '[%s][%s][%s th] Power up...',
                get_time(),
                $node,
                $node_cnt
            )
        );

        $error_cnt++
            if (vm_ctl($node, $vm_info, 'start')
            || ping_check_list(\@manage_nodes, $args->{wait})
            || $self->node_status_check(\@manage_nodes, $args)
            || $self->full_status_check($vm_info, $args, $node, 'power', 'up')
            );

        sleep(60);
    }

    goto ERROR_PWR if ($error_cnt > 0);

    return 0;

ERROR_PWR:
    $self->err_diag(sprintf('[%s] not ok: Power test is failed', get_time()));
    return -1;
}

sub test_preset
{
    my $self = shift;
    my ($vm_nodes, $vm_infos, $args) = @_;

    my $manager_ip = @$vm_nodes[0];
    my $manager    = "$manager_ip:80";
    my $error_cnt  = 0;

    my $res;

    $args->{result}{preset}{'1.start'} = get_time();

    # User Create
    my $t = Test::AnyStor::Account->new(addr => $manager, no_logout => 1);

    $res = $t->user_create(prefix => 'preset_user', number => 1);

    goto ERROR_PRE if (!defined($res));

    $args->{result}{preset}{user_create} = get_time();

    undef $t;

    # Volume Create
    $t = Test::AnyStor::ClusterVolume->new(addr => $manager, no_logout => 1);

    $res = $t->volume_pool_create();

    my $node_cnt = scalar(@{$t->nodes});
    my $replica  = 1;

    $replica = 2 if (!($node_cnt % 2));

    $res = $t->volume_create_distribute(
        cluster    => 'jnode',
        volname    => 'preset_vol',
        capacity   => '5G',
        node_count => $node_cnt,
        replica    => $replica,
    );

    goto ERROR_PRE if (!defined($res));

    if ($node_cnt > 3)
    {
        $res = $t->attach_arbiter(volume_name => 'preset_vol',);
        $t->info_diag("Arbiter attached\n");
    }

    $args->{result}{preset}{vol_create} = get_time();

    # Zone Create
    $t   = Test::AnyStor::Network->new(addr => $manager, no_logout => 1);
    $res = $t->cluster_network_zone_create(
        zonename    => 'preset_zone',
        description => 'Network zone allow global access for failure testing',
        type        => 'netmask',
        zoneip      => '0.0.0.0',
        zonemask    => '0.0.0.0',
    );

    goto ERROR_PRE if (!defined($res));

    $args->{result}{preset}{zone_create} = get_time();

    # Share Create
    $t = Test::AnyStor::Filing->new(addr => $manager, no_logout => 1);

    (my $mgmtip = $manager) =~ s/:\d+//;

    my $share = {
        name   => 'preset_share',
        volume => 'preset_vol',
        path   => '/export/preset_vol/preset_share',
        ftp    => 0,
        nfs    => 1,
        cifs   => 1,
        afp    => 0,
    };

    $args->{result}{preset}{share_property} = get_time();

    $t->remote($mgmtip);
    $res
        = $t->make_directory(dir => $share->{path}, options => ['-p -m 777']);

    goto ERROR_PRE if (!defined($res));

    # Share Setting
    $t = Test::AnyStor::Share->new(addr => $manager, no_logout => 1);

    if ($share->{nfs})
    {
        $res = $t->cluster_share_nfs_setconf(
            sharename => $share->{name},
            active    => 'on',
        );

        goto ERROR_PRE if (!defined($res));
    }

    $args->{result}{preset}{nfs_update} = get_time();

    if ($share->{cifs})
    {
        $res = $t->cluster_share_cifs_setconf(active => 'on');
        goto ERROR_PRE if (!defined($res));
    }

    $args->{result}{preset}{cifs_update} = get_time();

    # 공유 생성
    $res = $t->cluster_share_create(
        sharename   => $share->{name},
        volume      => $share->{volume},
        path        => $share->{path},
        description => 'Failure Test share',
        CIFS_onoff  => $share->{cifs} ? 'on' : 'off',
        NFS_onoff   => $share->{nfs}  ? 'on' : 'off',
        FTP_onoff   => $share->{ftp}  ? 'on' : 'off',
        AFP_onoff   => $share->{afp}  ? 'on' : 'off',
    );

    goto ERROR_PRE if (!defined($res));

    # 공유 활성화
    if ($share->{nfs})
    {
        $res = $t->cluster_share_nfs_update(
            sharename   => $share->{name},
            active      => 'on',
            access_zone => 'preset_zone',
            zone_right  => 'read/write',
        );

        goto ERROR_PRE if (!defined($res));
    }

    if ($share->{cifs})
    {
        $res = $t->cluster_share_cifs_update(
            sharename    => $share->{name},
            active       => 'on',
            share_right  => 'read/write',
            access_zone  => 'preset_zone',
            zone_right   => 'allow',
            guest_allow  => 'off',
            access_user  => 'preset_user-01',
            user_right   => 'allow',
            hidden_share => 'off',
        );

        goto ERROR_PRE if (!defined($res));
    }

    $args->{result}{preset}{share_create} = get_time();

    $t = Test::AnyStor::Filing->new(addr => $manager, no_logout => 1);

    map { goto ERROR_PRE if (call_system($_)); } (
        'umount -t cifs -a',
        'umount -t nfs -a',
        'rm -rf /mnt/cifs',
        'rm -rf /mnt/nfs'
    );

    $args->{result}{preset}{client_clear} = get_time();

    for my $sip (@{$args->{svc_list}})
    {
        goto ERROR_PRE if (call_system("mkdir -p /mnt/cifs/$sip"));
        goto ERROR_PRE if (call_system("mkdir -p /mnt/nfs/$sip"));
    }

    $args->{result}{preset}{client_mkdir} = get_time();

    for my $sip (@{$args->{svc_list}})
    {
        my $cmd_opt
            = "sec=ntlmssp,username=preset_user-01,password=gluesys!!";
        my $cmd
            = "mount -t cifs -o $cmd_opt //$sip/$share->{name} /mnt/cifs/$sip";

        diag(sprintf("[%s] CMD: [%s]", get_time(), $cmd));

        $error_cnt++ if (call_system($cmd));

        # refered #4491 by hgichon
        $cmd
            = "mount -t nfs -o nolock,vers=3 $sip:/$share->{volume}/$share->{name} /mnt/nfs/$sip";

        diag(sprintf("[%s] CMD: [%s]", get_time(), $cmd));

        $error_cnt++ if (call_system($cmd));
    }

    goto ERROR_PRE if ($error_cnt > 0);

    $args->{result}{preset}{client_mount} = get_time();

    for my $sip (@{$args->{svc_list}})
    {
        diag(
            sprintf('[%s] CMD: [%s]',
                get_time(), "touch /mnt/cifs/$sip/cifs_touch")
        );

        $error_cnt++ if (call_system("touch /mnt/cifs/$sip/cifs_touch"));

        diag(
            sprintf('[%s] CMD: [%s]',
                get_time(), "touch /mnt/nfs/$sip/nfs_touch")
        );

        $error_cnt++ if (call_system("touch /mnt/nfs/$sip/nfs_touch"));
    }

    goto ERROR_PRE if ($error_cnt > 0);

    $self->info_diag(
        sprintf("\n[%s] Preset_vol setting success\n", get_time()));

    $args->{result}{preset}{client_touch} = get_time();
    $args->{result}{preset}{'2.end'}      = get_time();
    $args->{result}{preset}{'3.result'}   = 'success';

    return 0;

ERROR_PRE:
    $self->err_diag(sprintf('[%s] not ok: preset failed', get_time()));

    $args->{result}{preset}{'2.end'}    = get_time();
    $args->{result}{preset}{'3.result'} = 'failed';

    return -1;
}

sub service_network_test
{
    my $self = shift;
    my ($vm_info, $args) = @_;

    my $error_cnt = 0;
    my $node_cnt  = 0;
    my $tmp_cnt   = 0;

    $args->{svc_eth} =~ /eth(\d)/;

    my $net_dev = "Network adapter " . ($1 + 1);    # VMware config plus

    $self->info_diag(
        sprintf("\n[%s][Single mode] Service NIC Fail TEST\n", get_time()));

    for my $node (keys %{$vm_info->{vm_nodes}})
    {
        $node_cnt++;
        $tmp_cnt++;

        $self->warn_diag(
            sprintf(
                '[%s][%s][%s][%s th][Service NIC Fail][SingleMode] Service NIC detach',
                get_time(), $node, $args->{svc_eth}, $node_cnt
            )
        );

        $error_cnt++
            if (
            vm_ctl($node, $vm_info, 'disconnectdevice', $net_dev)
            || $self->full_status_check(
                $vm_info, $args, $node, 'service', 'down'
            )
            );

        $self->warn_diag(
            sprintf(
                '[%s][%s][%s][%s th][Service NIC Fail][SingleMode] Service NIC attach',
                get_time(), $node, $args->{svc_eth}, $node_cnt
            )
        );

        $error_cnt++
            if (vm_ctl($node, $vm_info, 'connectdevice', $net_dev)
            || $self->full_status_check($vm_info, $args, $node, 'service',
                'up'));
    }

    goto ERROR_SVC if ($error_cnt > 0);

    $self->info_diag(
        sprintf(
            "\n[%s][Cascade mode] Service NIC Fail TEST: Node Count(%s)",
            get_time(), $node_cnt
        )
    );

    for my $node (keys(%{$vm_info->{vm_nodes}}))
    {
        last if ($tmp_cnt-- == 1);

        $self->warn_diag(
            sprintf(
                '[%s][%s][%s][%s th][Service NIC Fail][CascadeMode] Service NIC detach',
                get_time(), $node, $args->{svc_eth}, $node_cnt - $tmp_cnt
            )
        );

        $error_cnt++
            if (
            vm_ctl($node, $vm_info, 'disconnectdevice', $net_dev)
            || $self->full_status_check(
                $vm_info, $args, $node, 'service', 'down'
            )
            );
    }

    goto ERROR_SVC if ($error_cnt > 0);

    for my $node (keys(%{$vm_info->{vm_nodes}}))
    {
        last if (++$tmp_cnt == $node_cnt);

        $self->warn_diag(
            sprintf(
                '[%s][%s][%s][%s th][Service NIC Fail][CascadeMode] Service NIC attach',
                get_time(), $node, $args->{svc_eth}, $tmp_cnt
            )
        );

        $error_cnt++ if (vm_ctl($node, $vm_info, 'connectdevice', $net_dev));

        # last attach in casecade mode
        if ($node_cnt - $tmp_cnt == 1)
        {
            $error_cnt++
                if ($self->full_status_check(
                $vm_info, $args, $node, 'service', 'up'
                ));
        }
        else
        {
            $error_cnt++
                if ($self->full_status_check(
                $vm_info, $args, $node, 'service', 'up', 'no_check'
                ));
        }
    }

    goto ERROR_SVC if ($error_cnt > 0);
    return 0;

ERROR_SVC:
    $self->err_diag(
        sprintf('[%s] not ok: Service NIC test is failed', get_time()));
    return -1;
}

sub storage_network_test
{
    my $self = shift;
    my ($vm_info, $args) = @_;

    my $error_cnt = 0;
    my $node_cnt  = 0;

    $args->{stg_eth} =~ /eth(\d)/;

    my $net_dev = "Network adapter " . ($1 + 1);    # VMware config plus

    $self->info_diag(sprintf("\n[%s] Storage NIC Fail TEST\n", get_time()));

    for my $node (keys(%{$vm_info->{vm_nodes}}))
    {
        $node_cnt++;

        $self->warn_diag(
            sprintf(
                '[%s][%s][%s][%s th] Storage NIC detach',
                get_time(), $node, $args->{stg_eth}, $node_cnt
            )
        );

        $error_cnt++
            if (
            vm_ctl($node, $vm_info, 'disconnectdevice', $net_dev, $node_cnt));

        # limitaion: service ip failover takes max 3 secs
        $self->warn_diag(sprintf('[%s] Wait for 3 seconds', get_time()));

        sleep(3);

        $error_cnt++
            if ($self->full_status_check(
            $vm_info, $args, $node, 'storage', 'down'
            ));

        $self->warn_diag(
            sprintf(
                '[%s][%s][%s][%s th] Storage NIC attach',
                get_time(), $node, $args->{stg_eth}, $node_cnt
            )
        );

        $error_cnt++
            if (
            vm_ctl($node, $vm_info, 'connectdevice', $net_dev, $node_cnt));

        # wait for recovering
        $self->warn_diag(sprintf('[%s] Wait for 60 seconds', get_time()));

        sleep(60);

        $error_cnt++
            if (
            $self->full_status_check($vm_info, $args, $node, 'storage', 'up')
            );
    }

    goto ERROR_STG if ($error_cnt > 0);

    return 0;

ERROR_STG:
    $self->err_diag(
        sprintf('[%s] not ok: Storage NIC test is failed', get_time()));
    return -1;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Test::AnyStor::ClusterFailure

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

