#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'Cluster volume pool API test';

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
use Test::AnyStor::ClusterBlock;
use Test::AnyStor::ClusterVolume;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $pool_name       = 'vg_test_pool';
my $thin_pool_name  = 'tp_test_pool';
my $new_thick_vpool = 'vg_test_tier';
my $new_thin_vpool  = 'tp_test_tier';
my $blkdevs         = undef;
my $SKIP            = 0;

subtest 'Volume pool API basic' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @nodeinfo = ();

    foreach ($t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes})))
    {
        push(@nodeinfo,
            {
                Hostname => $_,
                PVs      => [ { Name =>'/dev/sdb' } ]
            }
        );
    }

    if (@nodeinfo > 2)
    {
        diag('VPool API test can only performed 2 nodes at a time');
        $SKIP=1;
        return;
    }

    my $res = $t->volume_pool_create(
        pool_name => $pool_name,
        provision => 'thick',
        pooltype  => 'Gluster',
        nodes     => \@nodeinfo,
        purpose   => 'for_data',
    );

    ok(defined($res), 'Thick volume pool is created successfully');

    ok(defined($t->volume_pool_list(pool_name => $pool_name))
        , "$pool_name does exist");

    $res = $t->volume_pool_create(
        provision => 'thin',
        pooltype  => 'Gluster',
        basepool  => $pool_name,
        capacity  => '10G',
        nodes     => \@nodeinfo,
    );

    ok(defined($res), 'Thin volume pool is created successfully');

    ok(defined($t->volume_pool_list(pool_name => $thin_pool_name))
        , "$thin_pool_name does exist");

    ok(defined($t->volume_pool_remove(pool_name => $thin_pool_name))
        , 'Thin volume pool is removed successfully');
};

goto TESTEND if ($SKIP);

subtest 'Get all of block device info' => sub
{
    my $t = Test::AnyStor::ClusterBlock->new(addr => $GMS_TEST_ADDR);

    $blkdevs = $t->list_block_device(scope => 'NO_INUSE');

    if (!isa_ok($blkdevs, 'ARRAY'
            , 'All block devices info for each nodes has retrived'))
    {
        return;
    }

    diag(explain($blkdevs));
};

subtest 'New thick volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @nodeinfo = ();

    foreach my $node (@{$blkdevs})
    {
        if (ref($node->{Devices}) eq 'ARRAY'
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

    diag(explain(\@nodeinfo));

    if (!cmp_ok(scalar(@nodeinfo), '>', 0
                , '"/dev/sdc" does exist for each nodes'))
    {
        return;
    }

    my $res = $t->volume_pool_create(
        provision => 'thick',
        pooltype  => 'Gluster',
        pool_name => $new_thick_vpool,
        nodes     => \@nodeinfo,
        purpose   => 'for_tiering',
    );

    if (!ok(defined($res), "Volume pool is created: $new_thick_vpool"))
    {
        return;
    }

    diag(explain($t->volume_pool_list()));
};

subtest 'New thin volume pool on thick volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @nodeinfo = ();

    push(@nodeinfo, { Hostname => $_ })
        foreach ($t->gethostnm(start_node => 0, cnt => scalar(@{$t->{nodes}})));

    my $res = $t->volume_pool_create(
        provision => 'thin',
        pooltype  => 'Gluster',
        basepool  => $new_thick_vpool,
        capacity  => '5G',
        nodes     => \@nodeinfo,
    );

    if (!ok(defined($res)
            , sprintf('Thin volume pool is created: %s(base:%s)'
                    , $new_thin_vpool, $new_thick_vpool)))
    {
        return;
    }

    diag(explain($t->volume_pool_list()));
};

subtest 'Remove thin volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    ok(defined($t->volume_pool_remove(pool_name => $new_thin_vpool))
        , "Thin volume pool is removed successfully: $new_thin_vpool");

    my $list = $t->volume_pool_list();

    diag(explain($list));
};

subtest 'Re-config thick volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @hostnms = $t->gethostnm(start_node => 0, cnt => scalar(@{$t->{nodes}}));

    # reconfig(생성/삭제/축소/확장)를 테스트를 위한 볼륨 풀 셋업
    # node1 : 2 pv
    # node2 : 1 pv
    # node3 : 2 pv
    # node4 : 0 pv
    my @node_info = ();

    for (my $i=0; $i<scalar(@hostnms); $i++)
    {
        my $tmp = { Hostname => $hostnms[$i] };

        if ($i == 0)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdc' }, { Name => '/dev/sdd' } ];
        }
        elsif ($i == 1)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdc' } ];
        }
        elsif ($i == 2)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdc' }, { Name => '/dev/sdd'} ];
        }
        else
        {
            next;
        }

        push(@node_info, $tmp);
    }

    diag("Try to reconfig volume pool: $new_thick_vpool");
    diag(explain(\@node_info));

    my $res = $t->volume_pool_reconfig(
        pool_name => $new_thick_vpool,
        nodes     => \@node_info,
    );

    if (!ok(defined($res), "Volume pool is reconfigured: $new_thick_vpool"))
    {
        return;
    }

    # reconfig test
    # node1 : 2 pv -> 1 pv (shrink)
    # node2 : 1 pv -> 2 pv (extend)
    # node3 : 2 pv -> 0 pv (remove)
    # node4 : 0 pv -> 2 pv (create)

    # reconfig(생성/삭제/축소/확장)를 테스트
    @node_info = ();

    for (my $i=0; $i<scalar @hostnms; $i++)
    {
        my $tmp = { Hostname => $hostnms[$i] };

        if ($i == 0)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdc' } ];
        }
        elsif ($i == 1)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdd' }, { Name => '/dev/sdc' } ];
        }
        elsif ($i == 2)
        {
            next;
        }
        elsif ($i == 3)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdd' }, { Name => '/dev/sdc' } ];
        }
        else
        {
            next;
        }

        push(@node_info, $tmp);
    }

    diag("Try to reconfig $new_thick_vpool volume pool");
    diag(explain(\@node_info));

    $res = $t->volume_pool_reconfig(
        pool_name => $new_thick_vpool,
        nodes     => \@node_info,
    );

    if (!ok(defined($res), "Volume pool is reconfigured: $new_thick_vpool"))
    {
        return;
    }

    # reconfig test
    # node1 : 1 pv -> 1 pv (expand -> shirink)
    #                      (sdc + sdd) -> (sdd)

    # reconfig(생성/삭제/축소/확장)를 테스트
    @node_info = ();

    for (my $i=0; $i<scalar(@hostnms); $i++)
    {
        my $tmp = { Hostname => $hostnms[$i] };

        if ($i == 0)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdd' } ];
        }
        elsif ($i == 1)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdd' }, { Name => '/dev/sdc' } ];
        }
        elsif ($i == 2)
        {
            next;
        }
        elsif ($i == 3)
        {
            $tmp->{PVs} = [ { Name => '/dev/sdd' }, { Name => '/dev/sdc' } ];
        }
        else
        {
            next;
        }

        push(@node_info, $tmp);
    }

    diag("Try to reconfig $new_thick_vpool volume pool");
    diag(explain(\@node_info));

    $res = $t->volume_pool_reconfig(
        pool_name => $new_thick_vpool,
        nodes     => \@node_info,
    );

    if (!ok(defined($res), "Volume pool is reconfigured: $new_thick_vpool"))
    {
        return;
    }

    # rollback thick volume pool
    @node_info = ();

    for (my $i=0; $i<scalar(@hostnms); $i++)
    {
        my $tmp = { Hostname => $hostnms[$i] };

        $tmp->{PVs} = [ { Name => '/dev/sdc' } ];

        push(@node_info, $tmp);
    }

    diag("Try to reconfig volume pool: $new_thick_vpool");
    diag(explain(\@node_info));

    $res = $t->volume_pool_reconfig(
        pool_name => $new_thick_vpool,
        nodes     => \@node_info,
    );

    if (!ok(defined($res), "Volume pool is reconfigured: $new_thick_vpool"))
    {
        return;
    }

    my $list = $t->volume_pool_list();

    diag(explain($list));
};

subtest 'Re-config thin volume pool test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @hostnms = $t->gethostnm(start_node => 0, cnt => scalar(@{$t->{nodes}}));

    if (@hostnms == 1)
    {
        ok(1, 'skip thin volume pool reconfig test');
        return;
    }

    # thin volume pool setup
    # node1 : 5G
    # node2 : 0G
    # node3 : 5G
    my @nodeinfo = ();

    for (my $i=0; $i<scalar(@hostnms); $i++)
    {
        my $tmp = { Hostname => $hostnms[$i] };

        push(@nodeinfo, $tmp) if ($i == 0 || $i == 2);
    }

    diag("Try to create thin volume pool: $new_thick_vpool");
    diag(explain(\@nodeinfo));

    my $res = $t->volume_pool_create(
        provision => 'thin',
        pooltype  => 'Gluster',
        basepool  => $new_thick_vpool,
        capacity  => '5G',
        nodes     => \@nodeinfo,
    );

    if (!ok(defined($res)
            , sprintf('Thin volume pool is created: %s(base:%s)'
                    , $new_thin_vpool, $new_thick_vpool)))
    {
        return;
    }

    # reconfig test (thin volume pool shrinking is not available)
    # node1 : 5G -> 0G (remove)
    # node2 : 0G -> 7G (create)
    # node3 : 5G -> 7G (extend)

    @nodeinfo = ();

    for (my $i=0; $i<scalar(@hostnms); $i++)
    {
        my $tmp = { Hostname => $hostnms[$i] };

        next if ($i == 0);

        push(@nodeinfo, $tmp);
    }

    diag("Try to reconfig thin volume pool: $new_thick_vpool");
    diag(explain(\@nodeinfo));

    $res = $t->volume_pool_reconfig(
        pool_name => $new_thin_vpool,
        basepool  => $new_thick_vpool,
        capacity  => '7G',
        nodes     => \@nodeinfo,
    );

    if (!ok(defined($res)
            , sprintf('Thin volume pool is reconfigured: %s(base:%s)'
                , $new_thin_vpool, $new_thick_vpool)))
    {
        return;
    }

    my $list = $t->volume_pool_list();

    diag(explain($list));
};

subtest 'Clean-up volume pool test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    my @hostnms = $t->gethostnm(start_node => 0, cnt => scalar(@{$t->{nodes}}));

    my @targets;

    push(@targets, $pool_name);
    push(@targets, $new_thin_vpool) if (scalar(@{$t->nodes}) > 1);
    push(@targets, $new_thick_vpool);

    foreach my $vpool (@targets)
    {
        diag(explain($t->volume_pool_list()));

        ok(defined($t->volume_pool_remove(pool_name => $vpool))
            , "Thin volume pool is removed successfully: $vpool");

        diag(explain($t->volume_pool_list()));
    }
};

TESTEND:
done_testing();
