#!/usr/bin/perl

use v5.14;

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/\/[^\/]+$//;

    unshift(@INC,
        (map { "$ROOTDIR/$_"; } qw/libgms lib/),
        '/usr/girasole/lib');
}

use Data::Dumper;
use Env;
use File::Basename;
use Getopt::Long;
use Net::OpenSSH;
use Number::Bytes::Human qw/format_bytes/;
use Scalar::Util qw/looks_like_number/;
use Try::Tiny;

use Test::Most;
use Test::AnyStor::Base;
use Test::AnyStor::Util;
use Test::AnyStor::Measure;
use Test::AnyStor::Network;
use Test::AnyStor::Account;
use Test::AnyStor::Share;
use Test::AnyStor::Filing;
use Test::AnyStor::ClusterVolume;

select(STDERR);
$| = 1;
select(STDOUT);
$| = 1;

my $GMS_CLIENT_ADDR = $ENV{GMS_CLIENT_ADDR};

my $PROG = basename($0);

my %TEST_INFOS = (
    conf_file    => '',
    node_mgmtips => undef,
    test_mode    => 'BMT',
    share        => 'CIFS',
    io_tool      => 'bonnie++',
    io_count     => 1,
    io_memtotal  => undef,
    io_seq_max   => undef,
    io_seq_chunk => undef,
    io_rand_num  => undef,
    io_rand_max  => undef,
    io_rand_min  => undef,
    io_dir_num   => undef,
    timeout      => 0,
    node_cnt     => 0,
    tp_sz        => 0,
    mount_ipaddr => '',
    max_snap     => undef,
    stop_io_fail => 'false',
    io_test_fail => 0,
);

my @VOL_INFOS = (

    # distributed replica, 1 * 1
    {
        volpolicy  => 'Distributed',
        capacity   => 0,
        replica    => 1,
        node_count => 1,
        start_node => 0,
        volname    => 'dist1_rep1',
        pool_name  => 'tp_cluster',
    },

    # distibuted replica, 1 * 2
    {
        volpolicy  => 'Distributed',
        capacity   => '',
        replica    => 2,
        node_count => 2,
        start_node => 0,
        volname    => 'dist1_rep2',
        pool_name  => 'tp_cluster',
    },

    # disperse code 1,  2 + 1
    {
        volpolicy  => 'Disperse',
        capacity   => '',
        code_count => 1,
        node_count => 3,
        start_node => 0,
        volname    => 'netraid2_cd1',
        pool_name  => 'tp_cluster',
    },

    # distibuted replica, 2 * 2
    {
        volpolicy  => 'Distributed',
        capacity   => '',
        replica    => 2,
        node_count => 4,
        start_node => 0,
        volname    => 'dist2_rep2',
        pool_name  => 'tp_cluster',
    },

    # disperse code 1,  3 + 1
    {
        volpolicy  => 'Disperse',
        capacity   => '',
        code_count => 1,
        node_count => 4,
        start_node => 0,
        volname    => 'netraid3_cd1',
        pool_name  => 'tp_cluster',
    },
);

################################################
# main
################################################

my $t_filing = undef;

if (test_prepare())
{
    _err_exit("Test prepare failed");
}

if (thin_pool_create())
{
    _err_exit("Thin volume pool create failed");
}

for my $i (0 .. $#VOL_INFOS)
{
    next if ($TEST_INFOS{node_cnt} < $VOL_INFOS[$i]->{node_count});

    my $volname = volume_create(%{$VOL_INFOS[$i]});

    if (!$volname)
    {
        print Dumper($VOL_INFOS[$i]);
        _err_exit('Volume create failed');
    }

    if (zone_create($volname))
    {
        _err_exit('Zone create failed');
    }

    if (user_create($volname))
    {
        _err_exit('User create failed');
    }

    if (share_create($volname))
    {
        _err_exit('Share create failed');
    }

    if (client_mount($volname))
    {
        _err_exit('Volume mount failed on client');
    }

    if (snapshot_create_test($volname))
    {
        _err_exit('Snapshot create test failed');
    }

    if (snapshot_delete_test($volname))
    {
        _err_exit('Snapshot delete test failed');
    }

    if (client_umount($volname))
    {
        _err_exit('Volume umount failed on client');
    }

    if (share_delete($volname))
    {
        _err_exit('Share delete failed');
    }

    if (user_delete($volname))
    {
        _err_exit('User delete failed');
    }

    if (zone_delete($volname))
    {
        _err_exit('Zone delete failed');
    }

    $VOL_INFOS[$i]->{volname} = $volname;

    if (volume_delete(volname => $volname))
    {
        print Dumper($VOL_INFOS[$i]);
        _err_exit('Volume delete failed');
    }
}

if (thin_pool_delete())
{
    _err_exit('Thin volume pool delete failed');
}

diag("INFO: I/O test fail count : $TEST_INFOS{io_test_fail}\n\n");

diag("INFO: Test is done");

_archive_all();

done_testing();

################################################
# functions
################################################
sub zone_create
{
    my $zone_name = shift;

    diag("INFO: Try to create zone");

    my $t = Test::AnyStor::Network->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    return !(
        $t->cluster_network_zone_create(
            zonename    => $zone_name,
            description => 'Network zone allow global access for testing',
            type        => 'netmask',
            zoneip      => '0.0.0.0',
            zonemask    => '0.0.0.0',
        )
    );
}

sub zone_delete
{
    my $zone_name = shift;

    diag("INFO: Try to delete zone");

    my $t = Test::AnyStor::Network->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    return !($t->cluster_network_zone_delete(zonename => $zone_name));
}

sub user_create
{
    my $user_name = shift;

    diag("INFO: Try to create user");

    my $t = Test::AnyStor::Account->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    return !($t->user_create(prefix => $user_name));
}

sub user_delete
{
    my $user_name = shift;

    diag("INFO: Try to delete user");

    my $t = Test::AnyStor::Account->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    return $t->user_delete(names => "$user_name-1");
}

sub share_create
{
    my $share_name = shift;

    diag("INFO: Try to create share");

    my $t = Test::AnyStor::Share->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    my $res = $t->cluster_share_create(
        sharename => $share_name,
        volume    => $share_name,
        path      => "/export/$share_name",
    );

    return $res if ($res);

    $res = $t->cluster_share_update(
        sharename  => $share_name,
        volume     => $share_name,
        path       => "/export/$share_name",
        CIFS_onoff => 'on',
        NFS_onoff  => 'on'
    );

    return $res if ($res);

    $res = $t->cluster_share_cifs_setconf(active => 'on');

    return $res if ($res);

    $res = $t->cluster_share_cifs_update(
        active      => 'on',
        sharename   => $share_name,
        share_right => 'read/write',
        access_zone => $share_name,
        zone_right  => 'allow',
        access_user => "$share_name-1",
        user_right  => 'allow',
    );

    return $res if ($res);

    $res = $t->cluster_share_nfs_setconf(active => 'on');

    return $res if ($res);

    $res = $t->cluster_share_nfs_update(
        sharename   => $share_name,
        active      => 'on',
        access_zone => $share_name,
        zone_right  => 'read/write',

    );

    return $res if ($res);

    return 0;
}

sub share_delete
{
    my $share_name = shift;

    diag("INFO: Try to delete share");

    my $t = Test::AnyStor::Share->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    my $res = $t->cluster_share_cifs_setconf(active => 'off');

    return $res if ($res);

    $res = $t->cluster_share_nfs_setconf(active => 'off');

    return $res if ($res);

    $res = $t->cluster_share_update(
        sharename  => $share_name,
        volume     => $share_name,
        path       => "/export/$share_name",
        CIFS_onoff => 'off',
        NFS_onoff  => 'off'
    );

    return $res if ($res);

    $res = $t->cluster_share_delete(sharename => $share_name);

    return $res;
}

sub client_mount
{
    my $mount_dir = shift;

    diag("INFO: Try to mount cluster volume");

    my $exists = $t_filing->exists(target => "/mnt/$mount_dir");

    if ($exists && $t_filing->make_directory(dir => "/mnt/$mount_dir"))
    {
        return -1;
    }

    my %args = (
        type    => ($TEST_INFOS{share} eq 'CIFS') ? 'cifs' : 'nfs',
        options => ($TEST_INFOS{share} eq 'CIFS')
        ? ["username=$mount_dir-1", "passwd=gluesys!!"]
        : ['vers=3'],
        device => ($TEST_INFOS{share} eq 'CIFS')
        ? "//$TEST_INFOS{mount_ipaddr}/$mount_dir"
        : "$TEST_INFOS{mount_ipaddr}:/$mount_dir",
        point => "/mnt/$mount_dir",
    );

    return -1 if (!$t_filing->is_mountable(%args));

    return $t_filing->mount(%args);
}

sub client_umount
{
    my $mount_dir = shift;

    diag("INFO: Try to umount cluster volume");

    my $res = $t_filing->umount();

    return $res if ($res);

    $t_filing->rm(dir => "/mnt/$mount_dir");

    return $res;
}

sub snapshot_create_test
{
    my $volname  = shift;
    my $max_snap = $TEST_INFOS{max_snap};

    diag("INFO: Snapshot create test");

    if (!$max_snap)
    {
        my %opts = (
            user                  => 'root',
            port                  => '22',
            master_stderr_discard => 1,
        );

        my $ssh = Net::OpenSSH->new($TEST_INFOS{node_mgmtips}->[0], %opts);

        if ($ssh->error)
        {
            fail(
                "$TEST_INFOS{node_mgmtips}->[0] SSH connect failed ($ssh->error)"
            );
            return -1;
        }

        my $cmd     = 'gluster snapshot config';
        my $configs = $ssh->capture2($cmd);

        if ($ssh->error)
        {
            fail("ERROR: SSH command failed($cmd)");
            return -1;
        }

        my $hit = 0;

        for my $line (split(/\n+/, $configs))
        {
            next if ($line eq '');

            $hit = 1 if ($line =~ /^Volume\s*:\s*$volname$/);

            next if (!$hit);

            if ($line =~ /^Effective snap-max-soft-limit\s*:\s*(?<val>\d+)/)
            {
                $max_snap = $+{val};
                last;
            }
        }
    }

    if (!$max_snap)
    {
        fail("ERROR: Fail to get max snapshot count");
        return -1;
    }

    $TEST_INFOS{max_snap} = $max_snap;

    my $t_vol = Test::AnyStor::ClusterVolume->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    for (my $i = 0; $i < $max_snap; $i++)
    {
        if ($TEST_INFOS{test_mode} eq 'BMT')
        {
            my $prefix
                = "$TEST_INFOS{share}_"
                . $volname
                . "_node$TEST_INFOS{node_cnt}_snapshot$i"
                . "_create_$TEST_INFOS{test_mode}";

            my %args = (
                tool      => $TEST_INFOS{io_tool},
                point     => "/mnt/$volname",
                save_path =>
                    "/tmp/$TEST_INFOS{io_tool}_$TEST_INFOS{test_mode}_test",
                save_prefix => $prefix,
                memtotal    => (defined $TEST_INFOS{io_memtotal})
                ? $TEST_INFOS{io_memtotal}
                : int($t_filing->memtotal / 1024),
                count => $TEST_INFOS{io_count},
            );

            for my $key (
                grep { /^io_(seq.+|rand.+|dir.+)$/ }
                keys(%TEST_INFOS)
                )
            {
                $key =~ s/io_//;
                $args{$key} = $TEST_INFOS{"io_$key"};
            }

            my $start = time();
            my $res   = $t_filing->io(%args);
            my $end   = time();

            diag(
                sprintf("I/O test elapsed time : %d (s)\n",
                    int($end - $start))
            );

            if ($res)
            {
                fail("I/O test return failed");
                $TEST_INFOS{io_test_fail}++;
                return -1 if ($TEST_INFOS{stop_io_fail} eq 'true');
            }

            $start = time();

            $res = $t_vol->volume_snapshot_create(
                volname  => $volname,
                snapname => $volname,
            );

            $end = time();

            diag(
                sprintf(
                    "Snapshot(%d) create elapsed time : %d (s)\n",
                    $i, int($end - $start)
                )
            );

            if (!$res)
            {
                fail("Snapshot create return failed");
                return -1;
            }
        }
        else
        {
            my $prefix
                = "$TEST_INFOS{share}_"
                . $volname
                . "_node$TEST_INFOS{node_cnt}_snapshot"
                . ($i + 1)
                . "_create_$TEST_INFOS{test_mode}";

            my %args = (
                tool      => $TEST_INFOS{io_tool},
                point     => "/mnt/$volname",
                save_path =>
                    "/tmp/$TEST_INFOS{io_tool}_$TEST_INFOS{test_mode}_test",
                save_prefix => $prefix,
                memtotal    => (defined $TEST_INFOS{io_memtotal})
                ? $TEST_INFOS{io_memtotal}
                : int($t_filing->memtotal / 1024),
                count => $TEST_INFOS{io_count},
            );

            for my $key (
                grep { /^io_(seq.+|rand.+|dir.+)$/ }
                keys(%TEST_INFOS)
                )
            {
                $key =~ s/io_//;
                $args{$key} = $TEST_INFOS{"io_$key"};
            }

            my @tmp       = %args;
            my $io_bonnie = Asyncjob->new(
                obj  => $t_filing,
                func => \&Test::AnyStor::Filing::io,
                args => \@tmp,
            );

            my $snapshot = Asyncjob->new(
                obj  => $t_vol,
                func =>
                    \&Test::AnyStor::ClusterVolume::volume_snapshot_create,
                args    => ['volname', $volname, 'snapname', $volname],
                timeout => $TEST_INFOS{timeout}
            );

            my $ctl = Asyncctl->new(trigger_term => 5);

            $ctl->add($io_bonnie);
            $ctl->add($snapshot);

            my $res = $ctl->run();

            if ($res)
            {
                fail("ERROR: Fail to run I/O test & snapshot create");
                return -1;
            }

            # wait async jobs
            while (1)
            {
                $res = $ctl->done();
                print "ctl->done(): $res\n";
                last if ($res);
                sleep 1;
            }

            # if async job fail
            if ($io_bonnie->error || $snapshot->error)
            {
                fail("ERROR: Fail to run I/O test & snapshot create");
                print Dumper($io_bonnie->error);
                print Dumper($snapshot->error);
                return -1;
            }

            if ($io_bonnie->retval)
            {
                fail("I/O test return failed");
                print Dumper($io_bonnie->result);
                $TEST_INFOS{io_test_fail}++;
                return -1 if ($TEST_INFOS{stop_io_fail} eq 'true');
            }

            if (!$snapshot->retval)
            {
                fail("snapshot create return failed");
                print Dumper($snapshot->result);
                return -1;
            }

            diag(
                sprintf("I/O test elapsed time: %d (s)\n",
                    int($io_bonnie->end - $io_bonnie->start))
            );
            diag(
                sprintf(
                    "Snapshot(%d) create elapsed time: %d (s)\n",
                    $i + 1, int($snapshot->end - $snapshot->start)
                )
            );

        }

        # if deactivated, set to activate
        my $snap_list = $t_vol->volume_snapshot_list(volname => $volname);

        for my $info (@{$snap_list})
        {
            if ($info->{Activated} eq 'false')
            {
                $t_vol->volume_snapshot_activate(
                    volname   => $volname,
                    snapname  => $info->{Snapshot_Name},
                    activated => 'true',
                );
            }
        }
    }

    return 0;
}

sub snapshot_delete_test
{
    my $volname = shift;

    diag('INFO: Snapshot delete test');

    my $t_vol = Test::AnyStor::ClusterVolume->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    my $snap_list = $t_vol->volume_snapshot_list(volname => $volname);

    for (my $i = scalar(@$snap_list); $i > 0; $i--)
    {
        if ($TEST_INFOS{test_mode} eq 'BMT')
        {
            my $prefix
                = "$TEST_INFOS{share}_"
                . $volname
                . "_node$TEST_INFOS{node_cnt}_snapshot$i"
                . "_delete_$TEST_INFOS{test_mode}";

            my %args = (
                tool      => $TEST_INFOS{io_tool},
                point     => "/mnt/$volname",
                save_path =>
                    "/tmp/$TEST_INFOS{io_tool}_$TEST_INFOS{test_mode}_test",
                save_prefix => $prefix,
                memtotal    => defined($TEST_INFOS{io_memtotal})
                ? $TEST_INFOS{io_memtotal}
                : int($t_filing->memtotal / 1024),
                count => $TEST_INFOS{io_count},
            );

            for my $key (
                grep { /^io_(seq.+|rand.+|dir.+)$/ }
                keys(%TEST_INFOS)
                )
            {
                $key =~ s/io_//;
                $args{$key} = $TEST_INFOS{"io_$key"};
            }

            my $start = time();
            my $res   = $t_filing->io(%args);

            if ($res)
            {
                fail("I/O test return failed");
                $TEST_INFOS{io_test_fail}++;
                return -1 if ($TEST_INFOS{stop_io_fail} eq 'true');
            }

            my $end = time();

            diag(
                sprintf(
                    "I/O test elapsed time: %d (s)\n", int($end - $start)
                )
            );

            $start = time();

            $res = $t_vol->volume_snapshot_delete(
                volname  => $volname,
                snapname => $snap_list->[$i - 1]->{Snapshot_Name}
            );

            $end = time();

            diag(
                sprintf(
                    "Snapshot(%d) delete elapsed time : %d (s)\n",
                    $i, int($end - $start)
                )
            );

            if ($res && $res == -1)
            {
                fail("Snapshot delete return failed");
                return -1;
            }
        }
        else
        {
            my $prefix
                = "$TEST_INFOS{share}_"
                . $volname
                . "_node$TEST_INFOS{node_cnt}_snapshot"
                . ($i - 1)
                . "_delete_$TEST_INFOS{test_mode}";

            my %args = (
                tool      => $TEST_INFOS{io_tool},
                point     => "/mnt/$volname",
                save_path =>
                    "/tmp/$TEST_INFOS{io_tool}_$TEST_INFOS{test_mode}_test",
                save_prefix => $prefix,
                memtotal    => defined($TEST_INFOS{io_memtotal})
                ? $TEST_INFOS{io_memtotal}
                : int($t_filing->memtotal / 1024),
                count => $TEST_INFOS{io_count},
            );

            for my $key (
                grep { /^io_(seq.+|rand.+|dir.+)$/ }
                keys(%TEST_INFOS)
                )
            {
                $key =~ s/io_//;
                $args{$key} = $TEST_INFOS{"io_$key"};
            }

            my @tmp = %args;

            my $io_bonnie = Asyncjob->new(
                obj  => $t_filing,
                func => \&Test::AnyStor::Filing::io,
                args => \@tmp,
            );

            my $snapshot = Asyncjob->new(
                obj  => $t_vol,
                func =>
                    \&Test::AnyStor::ClusterVolume::volume_snapshot_delete,
                args => [
                    'volname', $volname, 'snapname',
                    $snap_list->[$i - 1]->{Snapshot_Name}
                ],
                timeout => $TEST_INFOS{timeout}
            );

            my $ctl = Asyncctl->new(trigger_term => 5);

            $ctl->add($io_bonnie);
            $ctl->add($snapshot);

            my $res = $ctl->run();

            if ($res)
            {
                fail("ERROR: Fail to run I/O test & snapshot delete");
                return -1;
            }

            # wait async jobs
            while (1)
            {
                $res = $ctl->done();
                print "ctl->done(): $res\n";
                last if ($res);
                sleep 1;
            }

            # if async job fail
            if ($io_bonnie->error || $snapshot->error)
            {
                fail("ERROR: Fail to run I/O test & snapshot delete\n");
                print Dumper($io_bonnie->error);
                print Dumper($snapshot->error);
                return -1;
            }

            if ($io_bonnie->retval)
            {
                fail("I/O test return failed");
                print Dumper($io_bonnie->result);
                $TEST_INFOS{io_test_fail}++;
                return -1 if ($TEST_INFOS{stop_io_fail} eq 'true');
            }

            if ($snapshot->retval && $snapshot->retval == -1)
            {
                fail("snapshot delete return failed");
                print Dumper($snapshot->result);
                return -1;
            }

            diag(
                sprintf("I/O test elapsed time: %d (s)\n",
                    int($io_bonnie->end - $io_bonnie->start))
            );

            diag(
                sprintf(
                    "Snapshot(%d) delete elapsed time: %d (s)\n",
                    $i - 1, int($snapshot->end - $snapshot->start)
                )
            );
        }
    }

    return 0;
}

sub volume_create
{
    my %args = @_;

    diag('INFO: Try to create cluster volume');

    my $t = Test::AnyStor::ClusterVolume->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    return $t->volume_create(%args);
}

sub volume_delete
{
    my %args = @_;

    diag('INFO: Try to delete cluster volume');

    my $t = Test::AnyStor::ClusterVolume->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    return $t->volume_delete(%args);
}

sub thin_pool_create
{
    diag('INFO: Try to create thin volume pool');

    my $t = Test::AnyStor::ClusterVolume->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    my $tp_sz = format_bytes(
        $TEST_INFOS{tp_sz} / $TEST_INFOS{node_cnt},
        bs => 1024,
        si => 1
    );

    return $t->volume_pool_create(capacity => $tp_sz);
}

sub thin_pool_delete
{
    diag('INFO: Try to delete thin volume pool');

    my $t = Test::AnyStor::ClusterVolume->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    return $t->volume_pool_remove(poolname => 'tp_cluster');
}

sub test_prepare
{
    # get options from ARGV
    try
    {
        GetOptions(
            'h'              => \&help,
            'config=s'       => \$TEST_INFOS{conf_file},
            'test_mode=s'    => \$TEST_INFOS{test_mode},
            'io_tool=s'      => \$TEST_INFOS{io_tool},
            'io_memtotal=s'  => \$TEST_INFOS{io_memtotal},
            'io_seq_max=s'   => \$TEST_INFOS{io_seq_max},
            'io_seq_chunk=s' => \$TEST_INFOS{io_seq_chunk},
            'io_rand_num=s'  => \$TEST_INFOS{io_rand_num},
            'io_rand_max=s'  => \$TEST_INFOS{io_rand_max},
            'io_rand_min=s'  => \$TEST_INFOS{io_rand_min},
            'io_dir_num=i'   => \$TEST_INFOS{io_dir_num},
            'io_count=i'     => \$TEST_INFOS{io_count},
            'share=s'        => \$TEST_INFOS{share},
            'timeout=i'      => \$TEST_INFOS{timeout},
            'max_snap=i'     => \$TEST_INFOS{max_snap},
            'stop_io_fail=s' => \$TEST_INFOS{stop_io_fail},
        );
    }
    catch
    {
        fail("ERROR: Argument parsing failed");
        goto ERROR;
    };

    my @io_opts = ();

    push(@io_opts, qw/io_memtotal/) if ($TEST_INFOS{io_memtotal});
    push(@io_opts, qw/io_count/)    if ($TEST_INFOS{io_count});

    if ($TEST_INFOS{io_seq_max})
    {
        push(@io_opts, qw/io_seq_max/);
        push(@io_opts, qw/io_seq_chunk/) if ($TEST_INFOS{io_seq_chunk});
    }

    if ($TEST_INFOS{io_rand_num})
    {
        push(@io_opts, qw/io_rand_num/);
        push(@io_opts, qw/io_rand_max/) if ($TEST_INFOS{io_rand_max});
        push(@io_opts, qw/io_rand_min/) if ($TEST_INFOS{io_rand_min});
        push(@io_opts, qw/io_dir_num/)  if ($TEST_INFOS{io_dir_num});
    }

    my $human = Number::Bytes::Human->new(bs => 1024, si => 1);

    for my $opt (@io_opts)
    {
        if ($TEST_INFOS{$opt} =~ /^(?<val>\d+)\s*(B|Ki*B|Mi*B|Gi*B|Ti*B)\s*$/
            && int($+{val}) > 0)
        {
            $TEST_INFOS{$opt} = $human->parse($TEST_INFOS{$opt});
        }
        elsif (!looks_like_number($TEST_INFOS{$opt}) || $TEST_INFOS{$opt} < 1)
        {
            fail("ERROR: \"$opt\" parsing failed");
            help();
            goto ERROR;
        }

        $TEST_INFOS{$opt} = int($TEST_INFOS{$opt} / 1024 / 1024)
            if (grep { $opt eq $_; } (qw/io_memtotal io_seq_max/));
    }

    # check ARGV validation
    $TEST_INFOS{node_mgmtips}
        = _get_init_conf('test_nodes', $TEST_INFOS{conf_file});

    if (!$TEST_INFOS{node_mgmtips} || !@{$TEST_INFOS{node_mgmtips}})
    {
        fail("ERROR: Getting the mgmt IP of nodes is failed");
        help();
        goto ERROR;
    }

    my $tmp = _get_init_conf('create', $TEST_INFOS{conf_file});

    try
    {
        $TEST_INFOS{mount_ipaddr} = $tmp->{service}->{start};
    }
    catch
    {
        fail('ERROR: Getting the service IP of first node is failed');
        help();
        goto ERROR;
    };

    if (uc($TEST_INFOS{test_mode}) !~ /^\s*STRESS|BMT\s*$/)
    {
        fail('ERROR: Unknown test mode');
        help();
        goto ERROR;
    }

    if (uc($TEST_INFOS{share}) !~ /^\s*CIFS|NFS\s*$/)
    {
        fail('ERROR: Unknown sharing protocol');
        help();
        goto ERROR;
    }

    if (lc($TEST_INFOS{io_tool}) !~ /^\s*bonnie\+\+\s*$/)
    {
        fail('ERROR: Unknown I/O test tool');
        help();
        goto ERROR;
    }

    if (!looks_like_number($TEST_INFOS{timeout}) || $TEST_INFOS{timeout} < 0)
    {
        fail('ERROR: Invalid timeout option');
        help();
        goto ERROR;
    }

    # make directory for I/O test result file
    $t_filing = Test::AnyStor::Filing->new(
        addr       => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_login   => 1,
        not_umount => 1,
        remote     => $GMS_CLIENT_ADDR,
    );

    my $exists = $t_filing->exists(
        target => "/tmp/$TEST_INFOS{io_tool}_$TEST_INFOS{test_mode}_test");

    if (!$exists)
    {
        $t_filing->rm(
            dir => "/tmp/$TEST_INFOS{io_tool}_$TEST_INFOS{test_mode}_test");
    }

    $t_filing->make_directory(
        dir => "/tmp/$TEST_INFOS{io_tool}_$TEST_INFOS{test_mode}_test");

    # get vg info to create thin pool size
    my $vg_info = undef;
    my $t       = Test::AnyStor::ClusterVolume->new(
        addr      => "$TEST_INFOS{node_mgmtips}->[0]:80",
        no_logout => 1
    );

    my $vp_list = $t->volume_pool_list();

    for my $pool (@{$vp_list})
    {
        if ($pool->{Pool_Name} eq 'vg_cluster')
        {
            $vg_info = $pool;
            last;
        }
    }

    if (!$vg_info)
    {
        fail('ERROR: Cannot found vg_cluster information');
        return -1;
    }

    my $node_cnt = scalar(@{$t->nodes});

    $TEST_INFOS{tp_sz}
        = $vg_info->{Pool_Free_Size_Bytes} - (1024 * 1024 * 1024 * $node_cnt);
    $TEST_INFOS{node_cnt} = $node_cnt;

    my $lv_per_node = ($TEST_INFOS{tp_sz} / $node_cnt) - (1024 * 1024 * 1024);

    # set size to each volumes
    for my $i (0 .. $#VOL_INFOS)
    {
        my $vol_sz = 0;

        my $nodes
            = $VOL_INFOS[$i]->{node_count} - $VOL_INFOS[$i]->{start_node};

        if ($VOL_INFOS[$i]->{volpolicy} eq 'Disperse')
        {
            my $cd = $VOL_INFOS[$i]->{code_count};
            $vol_sz = $lv_per_node * ($nodes - $cd);
        }
        else
        {
            my $replica = $VOL_INFOS[$i]->{replica};
            $vol_sz = $lv_per_node * $nodes / $replica;
        }

        $VOL_INFOS[$i]->{capacity}
            = format_bytes($vol_sz, bs => 1024, si => 1);
    }

    return 0;

ERROR:
    return -1;
}

sub _archive_all
{
    my @nodes = @{$TEST_INFOS{node_mgmtips}}[0 .. $TEST_INFOS{node_cnt} - 1];

    nodes_archive('', \@nodes);

    $t_filing->io_archive(
        srcpath  => "/tmp/$TEST_INFOS{io_tool}_$TEST_INFOS{test_mode}_test",
        destip   => $ENV{ARCHIVE_IP},
        destpath => "$ENV{ARCHIVE_ROOT}/$ENV{JOB_NAME}/$ENV{BUILD_NUMBER}",
        tool     => "bonnie++",
        print    => 1,
    );

    printf(
        "Log: http://%s/jenkins_log/%s/%s\n\n",
        $ENV{ARCHIVE_IP},
        $ENV{JOB_NAME},
        $ENV{BUILD_NUMBER}
    );
}

sub _err_exit
{
    my $msg = shift;

    fail($msg);

    _archive_all();

    done_testing();

    diag("INFO: I/O test fail count: $TEST_INFOS{io_test_fail}");

    exit -1;
}

sub help
{
    warn "Usage: $PROG\n";
    warn "\t--config=[jenkins test-set config file path]\n";
    warn "\t--test_mode=[BMT|STRESS]\n";
    warn "\t--share=[CIFS|NFS]\n";
    warn "\t--io_tool=[bonnie++]\n";
    warn "\t--io_memtotal=[test client's ram size]\n";
    warn "\t--io_sea_max=[sequential I/O test file size]\n";
    warn "\t--io_seq_chunk=[sequential I/O test file chunk size]\n";
    warn "\t--io_rand_num=[dir per file count for small file I/O test]\n";
    warn
        "\t--io_rand_max=[maximum limit of randomize size for small file I/O test]\n";
    warn
        "\t--io_rand_min=[minimum limit of randomize size for small file I/O test]\n";
    warn "\t--io_dir_num=[number of dir for small file I/O test]\n";
    warn "\t--timeout=[API timeout check secs]\n";
    warn "\t--stop_io_fail=[when I/O failed, stop the test]\n\n";
}

1;
