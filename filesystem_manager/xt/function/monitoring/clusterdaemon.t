#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY   = 'cpan:gluesys';
our $DESCRIPTOIN = 'Girasole ClusterDaemon 모니터링 테스트 코드';

use strict;
use warnings;
use utf8;

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
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Base;
use Test::AnyStor::Share;
use Test::AnyStor::ClusterVolume;
use Test::AnyStor::Network;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $SSH_RETRY = 300;

subtest "CTDB recover test" => sub
{
    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt         = scalar(@{$t->nodes});
    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);
    my @node_list_stgip  = $t->hostnm2stgip(hostnms => \@node_list_hostnm);

    my $ctdbs = undef;

    for my $i (0 .. $#node_list_mgmtip)
    {
        $ctdbs = get_pids_from_ps(
            ip     => $node_list_mgmtip[$i],
            greps  => [ "/usr/sbin/ctdbd" ],
            grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
        );

        if (!defined($ctdbs) || scalar(@{$ctdbs}) < 1)
        {
            fail("Cannot found ctdbd process to kill");
            next;
        }

        ok(1, "current ctdbds($node_list_mgmtip[$i], @{$ctdbs})");

        my $err = $t->ssh(
            addr => $node_list_mgmtip[$i],
            cmd  => 'killall ctdbd'
        );

        if ($err == -1)
        {
            fail("killall ctdbd");
            next;
        }

        ok(1, "killall ctdbd");

        for my $retry (0 .. $SSH_RETRY)
        {
            sleep 1;

            $ctdbs = get_pids_from_ps(
                ip     => $node_list_mgmtip[$i],
                greps  => [ "/usr/sbin/ctdbd" ],
                grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
            );

            if (!defined($ctdbs) || scalar(@{$ctdbs}) == 0)
            {
                if ($retry == $SSH_RETRY)
                {
                    fail("ctdbd recover waiting ... ($retry/$SSH_RETRY)");
                    last;
                }

                ok(1, "ctdbd recover waiting ... ($retry/$SSH_RETRY)");
                next;
            }

            ok(1, "ctdbd recover success($node_list_mgmtip[$i], @{$ctdbs})");
            last;
        }
    }
};

subtest "glusterd recover test" => sub
{
    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt         = scalar(@{$t->nodes});
    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);
    my @node_list_stgip  = $t->hostnm2stgip(hostnms => \@node_list_hostnm);

    my $glstd = undef;

    for my $i (0 .. $#node_list_mgmtip)
    {
        $glstd = get_pids_from_ps(
            ip     => $node_list_mgmtip[$i],
            greps  => ["/usr/sbin/glusterd"],
            grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
        );

        if (!defined($glstd) || scalar(@{$glstd}) < 1)
        {
            fail("Cannot found glusterd process to kill");
            next;
        }

        ok(1, "current gms($node_list_mgmtip[$i], @{$glstd})");

        my $err = $t->ssh(
            addr => $node_list_mgmtip[$i],
            cmd  => "kill -9 @{$glstd}"
        );

        if ($err == -1)
        {
            fail("kill -9 @{$glstd}");
            next;
        }

        ok(1, "kill -9 @{$glstd}");

        for my $retry (0 .. $SSH_RETRY)
        {
            sleep 1;

            $glstd = get_pids_from_ps(
                ip     => $node_list_mgmtip[$i],
                greps  => ["/usr/sbin/glusterd"],
                grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
            );

            if (!defined($glstd) || scalar(@{$glstd}) == 0)
            {
                if ($retry == $SSH_RETRY)
                {
                    fail("glusterd recover waiting ... ($retry/$SSH_RETRY)");
                    last;
                }

                ok(1, "glusterd recover waiting ... ($retry/$SSH_RETRY)");
                next;
            }

            ok(1, "glusterd recover success($node_list_mgmtip[$i], @{$glstd})");
            last;
        }
    }
};

subtest "Smbd recover test" => sub
{
    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt         = scalar(@{$t->nodes});
    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);
    my @node_list_stgip  = $t->hostnm2stgip(hostnms => \@node_list_hostnm);

    my $smbd = undef;

    for my $i (0 .. $#node_list_mgmtip)
    {
        # prepare for test
        my $vol = create_testvolume(where => $i);

        next if (!$vol);

        create_testshare(vol => $vol, share => $vol);

        # get smbd pids
        $smbd = get_pids_from_ps(
            ip     => $node_list_mgmtip[$i],
            greps  => ["smbd"],
            grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
        );

        if (!defined($smbd) || scalar(@{$smbd}) < 1)
        {
            fail("Cannot found smbd process to kill");
            goto CLEANUP;
        }

        ok(1, "current smbd($node_list_mgmtip[$i], @{$smbd})");

        # try to kill pids
        my $err = $t->ssh(
            addr => $node_list_mgmtip[$i],
            cmd  => "kill -9 @{$smbd}"
        );

        if ($err == -1)
        {
            fail("kill -9 @{$smbd}");
            goto CLEANUP;
        }

        ok(1, "kill -9 @{$smbd}");

        # wait smbd recover
        for my $retry (0 .. $SSH_RETRY)
        {
            sleep 1;

            $smbd = get_pids_from_ps(
                ip     => $node_list_mgmtip[$i],
                greps  => ["smbd"],
                grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
            );

            if (!defined($smbd) || scalar(@{$smbd}) == 0)
            {
                if ($retry == $SSH_RETRY)
                {
                    fail ("smbd recover waiting ... ($retry/$SSH_RETRY)");
                    last;
                }

                ok(1, "smbd recover waiting ... ($retry/$SSH_RETRY)");
                next;
            }

            ok(1, "smbd recover success($node_list_mgmtip[$i], @{$smbd})");
            last;
        }

    CLEANUP:
        sleep 20;

        # remove all test instanace
        clnup_allshare();
        clnup_allvolume();
    }
};

subtest "glusterfsd process recover test" => sub
{
    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt         = scalar(@{$t->nodes});
    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);
    my @node_list_stgip  = $t->hostnm2stgip(hostnms => \@node_list_hostnm);

    for my $i (0 .. $#node_list_mgmtip)
    {
        # prepare for test
        my $vol = create_testvolume(where => $i);

        next if (!$vol);

        my $fsd_pid_file = "/var/run/gluster/vols/$vol/$node_list_stgip[$i]-volume-$vol\_0.pid";
        my $glstfsd_file = get_pid_from_file(
            ip   => $node_list_mgmtip[$i],
            file => $fsd_pid_file
        );

        if (!defined($glstfsd_file) || $glstfsd_file eq '')
        {
            fail("Cannot kill glusterfsd, glusterfsd.pid file may be empty or not exists");
            goto CLEANUP;
        }

        ok(1, "current glusterfsd($node_list_mgmtip[$i], $glstfsd_file)");

        my $err = $t->ssh(
            addr => $node_list_mgmtip[$i],
            cmd  => "kill -9 $glstfsd_file"
        );

        if ($err == -1)
        {
            fail("kill -9 $glstfsd_file");
            goto CLEANUP;
        }

        ok(1, "kill -9 $glstfsd_file");

        for my $retry (0 .. $SSH_RETRY)
        {
            sleep 1;

            $glstfsd_file = get_pid_from_file(
                ip   => $node_list_mgmtip[$i],
                file => $fsd_pid_file
            );

            my $glstfsd = get_pids_from_ps(
                ip     => $node_list_mgmtip[$i],
                greps  => [ "/usr/sbin/glusterfsd", $fsd_pid_file ],
                grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ] 
            );

            # wait glusterfsd.pid file's pid exists in real process ids
            if (!defined($glstfsd_file) || $glstfsd_file eq ''
                || !defined($glstfsd) || scalar(@{$glstfsd}) == 0)
            {
                if ($retry == $SSH_RETRY)
                {
                    fail("glusterfsd recover waiting ... ($retry/$SSH_RETRY)");
                    last;
                }

                ok(1, "glusterfsd recover waiting ... ($retry/$SSH_RETRY)");
                next;
            }

            if ($glstfsd_file ~~ $glstfsd)
            {
                ok(1, "glusterfsd recover success ($node_list_mgmtip[$i], $glstfsd_file)");
                last;
            }
            else
            {
                if ($retry == $SSH_RETRY)
                {
                    fail("glusterfsd recover waiting ... ($retry/$SSH_RETRY)");
                    last;
                }

                ok(1, "glusterfsd recover waiting ... ($retry/$SSH_RETRY)");
                next;
            }
        }

    CLEANUP:
        sleep 20;
        # remove all test instanace
        clnup_allvolume();
    }
};

subtest "glusterfs process recover test" => sub
{
    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt         = scalar(@{$t->nodes});
    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);
    my @node_list_stgip  = $t->hostnm2stgip(hostnms => \@node_list_hostnm);

    my $nfs_pid = '/var/run/gluster/nfs/nfs.pid';
    my $shd_pid = '/var/run/gluster/glustershd/run/glustershd.pid';

    for my $i (0 .. $#node_list_mgmtip)
    {
        # prepare for test
        my $vol = create_testvolume(where => $i);

        next if (!$vol);

        my $glstfs = get_pids_from_ps(
            ip     => $node_list_mgmtip[$i],
            greps  => [ "/usr/sbin/glusterfs", "/export/$vol" ],
            grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch', $nfs_pid, $shd_pid ]
        );

        if (!defined($glstfs) || scalar(@{$glstfs}) < 1)
        {
            fail("Cannot found glusterfs process to kill");
            goto CLEANUP;
        }

        ok(1, "current gms($node_list_mgmtip[$i], @{$glstfs})");

        my $err = $t->ssh(
            addr => $node_list_mgmtip[$i],
            cmd  => "kill -9 @{$glstfs}"
        );

        if ($err == -1)
        {
            fail("kill -9 @{$glstfs}");
            goto CLEANUP;
        }

        ok(1, "kill -9 @{$glstfs}");

        for my $retry (0 .. $SSH_RETRY)
        {
            sleep 1;

            $glstfs = get_pids_from_ps(
                ip     => $node_list_mgmtip[$i],
                greps  => [ "/usr/sbin/glusterfs", "/export/$vol" ],
                grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch', $nfs_pid, $shd_pid ]
            );

            if (!defined($glstfs) || scalar(@{$glstfs}) == 0)
            {
                if ($retry == $SSH_RETRY)
                {
                    fail("glusterfs recover waiting ... ($retry/$SSH_RETRY)");
                    last;
                }

                ok(1, "glusterfs recover waiting ... ($retry/$SSH_RETRY)");
                next;
            }

            ok(1, "glusterfs recover success($node_list_mgmtip[$i], @{$glstfs})");
            last;

        }

    CLEANUP:
        sleep 20;

        # remove all test instanace
        clnup_allvolume();
    }
};

subtest "glusterfs/nfs process recover test" => sub {

    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt  = scalar @{ $t->nodes };
    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);
    my @node_list_stgip = $t->hostnm2stgip(hostnms => \@node_list_hostnm);

    my $nfs_pid      = '/var/run/gluster/nfs/nfs.pid';

    for my $i (0 .. $#node_list_mgmtip)
    {
        # prepare for test
        my $vol = create_testvolume(where => $i);

        next if (!$vol);

        create_test_zone();
        create_testshare(vol => $vol, share => $vol, nfs_update => 1);

        my $glstfs_nfs = get_pids_from_ps(
            ip     => $node_list_mgmtip[$i],
            greps  => [ "/usr/sbin/glusterfs", $nfs_pid ],
            grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
        );

        if (!defined($glstfs_nfs) || scalar(@{$glstfs_nfs}) < 1)
        {
            fail("Cannot found glusterfs/nfs process to kill");
            goto CLEANUP;
        }

        ok(1, "current gms($node_list_mgmtip[$i], @{$glstfs_nfs})");

        my $err = $t->ssh(
            addr => $node_list_mgmtip[$i],
            cmd  => "kill -9 @{$glstfs_nfs}"
        );

        if ($err == -1)
        {
            fail("kill -9 @{$glstfs_nfs}");
            goto CLEANUP;
        }

        ok(1, "kill -9 @{$glstfs_nfs}");

        for my $retry (0 .. $SSH_RETRY)
        {
            sleep 1;

            $glstfs_nfs = get_pids_from_ps(
                ip     => $node_list_mgmtip[$i],
                greps  => [ "/usr/sbin/glusterfs", $nfs_pid ],
                grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
            );

            if (!defined($glstfs_nfs) || scalar(@{$glstfs_nfs}) == 0)
            {
                if ($retry == $SSH_RETRY)
                {
                    fail("glusterfs/nfs recover waiting ... ($retry/$SSH_RETRY)");
                    last;
                }

                ok(1, "glusterfs/nfs recover waiting ... ($retry/$SSH_RETRY)");
                next;
            }

            ok(1, "glusterfs/nfs recover success($node_list_mgmtip[$i], @{$glstfs_nfs})");
            last;

        }

    CLEANUP:
        sleep 20;

        # remove all test instanace
        clnup_allshare();
        clnup_allvolume();
        delete_test_zone();
    }
};

subtest "GMS recover test" => sub
{
    my $t = Test::AnyStor::Base->new(
        addr      => $GMS_TEST_ADDR,
        no_logout => 1
    );

    my $node_cnt         = scalar(@{$t->nodes});
    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);
    my @node_list_stgip  = $t->hostnm2stgip(hostnms => \@node_list_hostnm);

    my $gms = undef;

    for my $i (0 .. $#node_list_mgmtip)
    {
        $gms = get_pids_from_ps(
            ip     => $node_list_mgmtip[$i],
            greps  => ["/usr/gms/script/gms"],
            grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
        );

        if (!defined($gms) || scalar(@{$gms}) < 1)
        {
            fail("Cannot found gms process to kill");
            next;
        }

        ok(1, "current gms($node_list_mgmtip[$i], @{$gms})");

        my $err = $t->ssh(
            addr => $node_list_mgmtip[$i],
            cmd  => "kill -9 @{$gms}"
        );

        if ($err == -1)
        {
            fail("kill -9 @{$gms}");
            next;
        }

        ok(1, "kill -9 @{$gms}");

        for my $retry (0 .. $SSH_RETRY)
        {
            sleep 1;

            $gms = undef;
            $gms = get_pids_from_ps(
                ip     => $node_list_mgmtip[$i],
                greps  => ["/usr/gms/script/gms"],
                grepvs => [ 'vim', 'tail', 'ps', 'grep', 'watch' ]
            );

            if (defined($gms) && scalar(@{$gms}) > 5)
            {
                ok(1, "gms recover success($node_list_mgmtip[$i], @{$gms})");
                last;
            }

            if ($retry == $SSH_RETRY)
            {
                fail("gms recover waiting ... ($retry/$SSH_RETRY)");
                last;
            }

            ok(1, "gms recover waiting ... ($retry/$SSH_RETRY)");
            next;
        }
    }
};

sub get_pids_from_ps
{
    my %args   = @_;
    my $ip     = $args{ip};
    my $greps  = $args{greps};
    my $grepvs = $args{grepvs};
    my $cmd    = "ps -eo pid,args";

    for my $grep (@{$greps}) { $cmd .= " | grep -w \"$grep\""; }
    for my $grep (@{$grepvs}) { $cmd .= " | grep -v \"$grep\""; }

    my ($out, $err) = Test::AnyStor::Base->ssh_cmd(
        undef,
        addr  => $ip,
        cmd   => $cmd,
        quiet => 1,
    );

    return [] if ($err);

    my @pids = ();

    if (defined($out))
    {
        my @lines = split(/\n/, $out);

        diag("grep process list : ${\Dumper(\@lines)}");

        for my $line (@lines)
        {
            $line =~ s/^\s*|\s*$//g;

            my $pid = undef;

            if ($line =~ /^(?<pid>\d+)\s+/)
            {
                $pid = $+{pid};
            }

            if (!defined($pid))
            {
                fail("Unexpected error");
                return [];
            }

            push(@pids, $pid);
        }
    }

    return \@pids;
}

sub get_pid_from_file
{
    my %args = @_;
    my $ip   = $args{ip};
    my $file = $args{file};

    my ($out, $err) = Test::AnyStor::Base->ssh_cmd(
        undef,
        addr => $ip,
        cmd  => "cat $file"
    );

    return $err ? undef : $out;
}

sub create_testshare
{
    my %args = @_;
    my $vol = $args{vol};
    my $share = $args{share};
    my $nfs_update;

    if (defined($args{nfs_update}))
    {
        $nfs_update = $args{nfs_update};

        if ($nfs_update)
        {
            ok(1, 'create testshare for nfs');
        }
    }
    else
    {
        $nfs_update = 0;
    }

    subtest "create share" => sub
    {
        my $share_t = Test::AnyStor::Share->new( addr => $GMS_TEST_ADDR, no_logout => 1);

        $share_t->cluster_share_cifs_setconf(active => 'on');

        $share_t->cluster_share_nfs_setconf(active => 'on');

        $share_t->cluster_share_create(
            sharename  => $share,
            volume     => $vol,
            path       => "/export/__$vol",
            CIFS_onoff => 'on',
            NFS_onoff  => 'on'
        );

        if ($nfs_update)
        {
            my $nfs_conf_info = $share_t->cluster_share_nfs_getconf();

            ok($nfs_conf_info->{Active} eq 'on', 'nfs set config check');

            $share_t->cluster_share_nfs_update(
                sharename   => $share,
                active      => 'on',
                access_zone => 'test_zone',
                zone_right  => 'read/write'
            );

            my $nfs_info = $share_t->cluster_share_nfs_info(sharename => $share);

            if ($nfs_info->{Active} eq 'on')
            {
                my $nfs_find_flag = 0;

                foreach my $each_nfs_zone (@{$nfs_info->{AccessZone}})
                {
                    if ($each_nfs_zone->{ZoneName} eq 'test_zone'
                        && $each_nfs_zone->{Access} eq 'read/write')
                    {
                        ok(1, 'nfs update check');
                        $nfs_find_flag = 1;
                        last;
                    };
                }

                if (!$nfs_find_flag)
                {
                    ok(0, 'nfs update check');
                }
            }
            else
            {
                ok(0, 'nfs update check');
            }
        }

        my $share_list = $share_t->cluster_share_list();

        my $find_flag = 0;

        foreach my $each_share (@{$share_list})
        {
            if ($each_share->{ShareName} eq $share)
            {
                $find_flag = 1;
                last;
            }
        }

        ok($find_flag, 'share create check');
    };
}

sub create_test_zone
{
    subtest "create test zone" => sub
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
}

sub delete_test_zone
{
    subtest "delete test zone" => sub
    {
        my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR, no_logout => 1);

        $t->cluster_network_zone_delete(zonename => 'test_zone');
    }
}

sub clnup_allshare
{
    subtest "delete all share" => sub
    {
        my $share_t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR, no_logout => 1);

        my $share_list = $share_t->cluster_share_list();

        for my $share (@{$share_list})
        {
            $share_t->cluster_share_delete(sharename => $share->{ShareName});
        }

        $share_list = $share_t->cluster_share_list();

        is(0, @$share_list, 'all share delete check');

        $share_t->cluster_share_cifs_setconf(active => 'off');
        $share_t->cluster_share_nfs_setconf(active => 'off');

    };
}

sub create_testvolume
{
    my %args  = @_;
    my $where = $args{where};
    my $ret   = undef;

    subtest "create test volume" => sub
    {
        my $vol_t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);

        my %need_vol = (
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => $where,
        );

        $ret = $vol_t->volume_create(%need_vol);

        if ($ret)
        {
            ok(1, 'volume create');
        }
        else
        {
            fail('volume_create');
        }
    };

    return $ret;
}

sub clnup_allvolume
{
    subtest "delete all volume" => sub
    {
        my $vol_t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);
        my $vol_list = $vol_t->volume_list();

        for my $vol (@{$vol_list})
        {
            $vol_t->verify_volstatus(volname => $vol->{Volume_Name}, exists => 1);

            my $res = $vol_t->volume_delete(volname => $vol->{Volume_Name});

            is($res, 0, 'cluster volume delete');

            $vol_t->verify_volstatus(volname => $vol->{Volume_Name}, exists => 0);
        }
    };
}

done_testing();

