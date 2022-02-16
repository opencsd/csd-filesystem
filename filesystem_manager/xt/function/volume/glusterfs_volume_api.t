#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'GlusterFS volume API 기본 테스트';

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname( rel2abs(__FILE__) )) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Net::OpenSSH;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Share;
use Test::AnyStor::ClusterVolume;
use Volume::LVM::LV;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

our $POOLNAME  = 'vg_vol_api_test';
our $TPOOLNAME = 'tp_vol_api_test';

subtest 'GlusterFS volume api basic test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @node_info = ();

    foreach ($t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes})))
    {
        push(@node_info,
            {
                Hostname => $_,
                PVs      => [ { Name =>'/dev/sdb' } ]
            }
        );
    }

    if (!$t->volume_pool_list(pool_name => $POOLNAME, ignore_return => 1))
    {
        my $res = $t->volume_pool_create(
            pool_name => $POOLNAME,
            provision => 'thick',
            pooltype  => 'Gluster',
            nodes     => \@node_info,
            purpose   => 'for_data',
        );

        ok(defined($res), 'Thick volume pool is created successfully');

        ok(defined($t->volume_pool_list(pool_name => $POOLNAME))
            , "$POOLNAME does exist");
    }
    else
    {
        my $res = $t->volume_pool_reconfig(
            pool_name => $POOLNAME,
            nodes     => \@node_info,
        );

        ok(defined($res), "Volume pool is reconfigured: $POOLNAME");
    }

    my @created   = ();
    my @need_vols = (
        {
            pool_name  => $POOLNAME,
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => 0,
        },
    );

    my @configs = (
        {
            option    => 'nfs.ports-insecure',
            parameter => 'off',
        },
        {
            option    => 'performance.io-thread-count',
            parameter => '32',
        },
    );

    foreach my $need (@need_vols)
    {
        my $res = $t->volume_create(%{$need});

        sleep 1;

        if ($res)
        {
            $need->{volname} = $res;
            push(@created, $need);

            $t->verify_volstatus(
                pool_name => $POOLNAME,
                volname   => $res,
                exists    => 1
            );

            sleep 1;
        }
    }

    foreach my $vol (@created)
    {
        foreach my $conf (@configs)
        {
            $t->volume_set_config(
                volname   => $vol->{volname},
                option    => $conf->{option},
                parameter => $conf->{parameter},
            );
        }

        sleep 1;
    }

    foreach my $vol (@created)
    {
        my $vol_opts = $t->volume_get_config(
            volname => $vol->{volname},
        );

        explain($vol_opts);

        foreach my $conf (@configs)
        {
            if (exists($vol_opts->{$conf->{option}})
                && defined($vol_opts->{$conf->{option}})
                && $vol_opts->{$conf->{option}} eq $conf->{parameter})
            {
                ok(1, "Gluster volume option is set(opt: $conf->{option}, param: $conf->{parameter})");
            }
            else
            {
                fail("Gluster volume option is not set(opt: $conf->{option}, param: $conf->{parameter})");
            }
        }

        sleep 1;
    }

    foreach my $vol (@created)
    {
        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $vol->{volname},
            exists    => 1
        );

        my $res = $t->volume_delete(
            pool_name => $POOLNAME,
            volname   => $vol->{volname}
        );

        is($res, 0, 'cluster volume delete');

        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $vol->{volname},
            exists    => 0
        );
    }
};

subtest "Create volumes with '-'" => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @created   = ();
    my @need_vols = (
        {
            pool_name  => $POOLNAME,
            volname    => 'test-1_0',
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => 0,
        },
        {
            pool_name  => $POOLNAME,
            volname    => 'test--1_0',
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => 0,
        },
        {
            pool_name  => $POOLNAME,
            volname    => 'test---1_0',
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => 0,
        },
        {
            pool_name  => $POOLNAME,
            volname    => 'test-1_0-',
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => 0,
        },
    );

    foreach my $i (0 .. $#need_vols)
    {
        my $res = $t->volume_create(%{$need_vols[$i]});

        sleep 1;

        if ($res)
        {
            $need_vols[$i]->{volname} = $res;

            push(@created, $need_vols[$i]);

            $t->verify_volstatus(
                pool_name => $POOLNAME,
                volname   => $res,
                exists    => 1
            );
        }
    }

    foreach my $vol (@created)
    {
        my $res = $t->volume_delete(
            pool_name => $POOLNAME,
            volname   => $vol->{volname}
        );

        is($res, 0, 'cluster volume delete');

        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $vol->{volname},
            exists    => 0
        );
    }
};

subtest 'Create duplicated cluster volume test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @created   = ();
    my @need_vols = (
        {
            pool_name  => $POOLNAME,
            volname    => 'duplicated_vol',
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => 0,
        },
        {
            pool_name  => $POOLNAME,
            volname    => 'duplicated_vol',
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => 0,
        },
    );

    foreach my $i (0 .. $#need_vols)
    {
        my $res = $t->volume_create(
            %{$need_vols[$i]},
            expected => { return => $i > 0 ? 'false' : 'true' }
        );

        sleep 1;

        if ($res)
        {
            $need_vols[$i]->{volname} = $res;

            push(@created, $need_vols[$i]);

            $t->verify_volstatus(
                pool_name => $POOLNAME,
                volname   => $res,
                exists    => 1
            );
        }

        if ($i < 1)
        {
            is($res, $need_vols[$i]->{volname}
                , "Create first cluster volume: $need_vols[$i]->{volname}");
        }
        else
        {
            is($res, undef, 'create duplicate cluster volume (should be denined)');
        }
    }

    foreach my $vol (@created)
    {
        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $vol->{volname},
            exists    => 1
        );

        my $res = $t->volume_delete(
            pool_name => $POOLNAME,
            volname   => $vol->{volname}
        );

        is($res, 0, 'cluster volume delete');

        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $vol->{volname},
            exists    => 0
        );
    }
};

my $sharename = 'test_share_' . time();
my %need_vol  = (
    pool_name  => $POOLNAME,
    volpolicy  => 'Distributed',
    capacity   => '1.0G',
    replica    => 1,
    node_count => 1,
    start_node => 0,
);

subtest 'Delete shared cluster volume test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $res = $t->volume_create(
        %need_vol,
        expected => { return => 'true' }
    );

    sleep 5;

    if ($res)
    {
        $need_vol{volname} = $res;
        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $res,
            exists    => 1
        );
    }
    else
    {
        fail('cluster volume create failed');
    }
};

subtest 'Share instance create' => sub
{
    my $share = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    $share->cluster_share_create(
        sharename  => $sharename,
        volume     => $need_vol{volname},
        path       => "/export/__$need_vol{volname}",
        CIFS_onoff => 'on',
        NFS_onoff  => 'on'
    );

    my $share_list = $share->cluster_share_list();

    my $find_flag = 0;

    foreach my $each_share (@$share_list)
    {
        next if ($each_share->{ShareName} ne $sharename);

        $find_flag = 1;
        last;
    }

    ok($find_flag, 'share create check');
};

subtest 'Try to delete shared volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $res = $t->volume_delete(
        pool_name => $POOLNAME,
        volname   => $need_vol{volname},
        expected  => {
            dryrun => 'false',
            return => 'false'
        }
    );

    is($res, -1, 'shared cluster volume cannot be deleted');

    sleep 1;
};

subtest 'Share instance delete' => sub
{
    my $share = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    $share->cluster_share_delete(sharename => $sharename);

    my $share_list = $share->cluster_share_list();

    my $find_flag = 0;

    foreach my $each_share (@{$share_list})
    {
        next if ($each_share->{ShareName} ne $sharename);

        $find_flag = 1;
        last;
    }

    ok(!$find_flag, 'share delete check');
};

subtest 'cleanup shared cluster volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    if (!ok(defined($t->verify_volstatus(
                    pool_name => $POOLNAME,
                    volname   => $need_vol{volname},
                    exists    => 1))
            , "Shared volume exists: $need_vol{volname}"))
    {
        return;
    }

    my $res = $t->volume_delete(
        pool_name => $POOLNAME,
        volname   => $need_vol{volname}
    );

    if (!is($res, 0, "Shared volume is deleted successfully: $need_vol{volname}"))
    {
        return;
    }

    $t->verify_volstatus(
        pool_name => $POOLNAME,
        volname   => $need_vol{volname},
        exists    => 0
    );
};

subtest 'GlusterFS thin volume create' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @tmp = $t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes}));

    my @nodeinfo = ();

    push(@nodeinfo, { Hostname => $_ }) foreach (@tmp);

    my $res = $t->volume_pool_create(
        provision => 'thin',
        basepool  => $POOLNAME,
        capacity  => '10G',
        nodes     => \@nodeinfo,
    );

    if (!$res)
    {
        fail("Failed to create thin volume pool on $POOLNAME");
    }
    else
    {
        ok(1, 'thin volume pool create');
    }

    my @created   = ();
    my @need_vols = (
        {
            pool_name  => $TPOOLNAME,
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => 1,
            start_node => 0,
            provision  => 'thin',
        },
    );

    my @configs = (
        {
            option    => 'nfs.ports-insecure',
            parameter => 'off',
        },
        {
            option    => 'performance.io-thread-count',
            parameter => '32',
        },
        {
            option    => 'features.uss',
            parameter => 'off',
        },
        {
            option    => 'snap-max-hard-limit',
            parameter => '200',
        },
    );

    foreach my $need (@need_vols)
    {
        my $res = $t->volume_create(%$need);

        sleep 1;

        next if (!$res);

        $need->{volname} = $res;

        push(@created, $need);

        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $res,
            exists    => 1,
            thin      => 1
        );

        sleep 1;
    }

    foreach my $vol (@created)
    {
        foreach my $conf (@configs)
        {
            $t->volume_set_config(
                volname   => $vol->{volname},
                option    => $conf->{option},
                parameter => $conf->{parameter},
            );
        }

        sleep 1;
    }

    foreach my $vol (@created)
    {
        my $vol_opts = $t->volume_get_config(
            volname => $vol->{volname},
        );

        explain($vol_opts);

        foreach my $conf (@configs)
        {
            if (exists($vol_opts->{$conf->{option}})
                && defined($vol_opts->{$conf->{option}})
                && $vol_opts->{$conf->{option}} eq $conf->{parameter})
            {
                ok(1, "Gluster volume option is set(opt: $conf->{option}, param: $conf->{parameter})");
            }
            else
            {
                fail("Gluster volume option is not set(opt: $conf->{option}, param: $conf->{parameter})");
            }
        }

        sleep 1;
    }

    foreach my $vol (@created)
    {
        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $vol->{volname},
            exists    => 1,
            thin      => 1
        );

        my $res = $t->volume_delete(
            pool_name => $TPOOLNAME,
            volname   => $vol->{volname}
        );

        is($res, 0, 'cluster volume delete');

        $t->verify_volstatus(
            pool_name => $POOLNAME,
            volname   => $vol->{volname},
            exists    => 0,
            thin      => 1
        );
    }

    $t->volume_pool_remove(pool_name => $TPOOLNAME);
};

done_testing();
