#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'Basic test for GlusterFS arbiter';

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
use Test::AnyStor::Share;
use Test::AnyStor::ClusterVolume;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $MASTER_IP = (split(/:/, $GMS_TEST_ADDR))[0];

subtest '[ARBITER_0] Preparing arbiter test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(
        addr      => $GMS_TEST_ADDR,
        no_logout => 1
    );

    my $node_cnt = scalar(@{$t->nodes});

    if ($node_cnt == 3)
    {
        my @created   = ();
        my @need_vols = ();

        my $tmp = {
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 2,
            node_count => 2,
            start_node => 0,
            volname    => 'arbt_shard_2node_expand',
            verify     => 1,
        };

        push(@need_vols, $tmp);

        for my $i (0 .. $#need_vols)
        {
            my $res = $t->volume_create(%{$need_vols[$i]});

            sleep 1;

            if ($res)
            {
                $need_vols[$i]->{volname} = $res;

                push(@created, $need_vols[$i]);

                $t->verify_volstatus(volname => $res, exists => 1);
            }

        }
    }
    elsif ($node_cnt == 4)
    {
        my @created   = ();
        my @need_vols = ();

        my @tmp = (
            {   volpolicy    => 'Distributed',
                capacity   => '1.0G',
                replica    => 2,
                node_count => 2,
                start_node => 0,
                volname    => 'arbt_norm_activate',
                verify     => 1,
            },
            {   volpolicy    => 'Distributed',
                capacity   => '1.0G',
                replica    => 2,
                node_count => 2,
                start_node => 0,
                volname    => 'arbt_chain_activate',
                chaining   => 'true',
                verify     => 1,
            }
        );

        push(@need_vols, @tmp);

        for my $i ( 0 .. $#need_vols )
        {
            my $res = $t->volume_create(%{$need_vols[$i]});

            sleep 1;

            if ($res)
            {
                $need_vols[$i]->{volname} = $res;

                push(@created, $need_vols[$i]);

                $t->verify_volstatus(volname => $res, exists => 1);
            }
        }
    }
    else
    {
        print 'Pass this case';
    }
};

subtest '[ARBITER_1] Arbiter attach test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(
        addr      => $GMS_TEST_ADDR,
        no_logout => 1
    );

    my $node_cnt = scalar(@{$t->nodes});

    if ($node_cnt == 3)
    {
        subtest '[ARBITER_1_0] Arbiter attach with 2 node sharded replica' => sub
        {
            my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);

            my $res = $t->attach_arbiter(
                volume_name      => 'arbt_shard_2node_expand',
                shard            => 'true',
                shard_block_size => '512M'
            );

            is($res, 'true', 'Arbiter attach with normal replica');

            my $verify = $t->verify_arbiter(
                chaining    => 'Not_Chained',
                master_ip   => $MASTER_IP,
                volume_name => 'arbt_shard_2node_expand',
            );

            is($verify, 0, 'The count of Arbiter is verified');
        };
    }
    elsif ($node_cnt == 4)
    {
        subtest '[ARBITER_1_0] Arbiter attach with 4 node  normal replica' => sub
        {
            my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);

            my $res = $t->attach_arbiter(
                volume_name      => 'arbt_norm_activate',
                shard            => 'true',
                shard_block_size => '512M'
            );

            is($res, 'true', 'Arbiter attach with normal replica');

            my $verify = $t->verify_arbiter(
                chaining    => 'Not_Chained',
                master_ip   => $MASTER_IP,
                volume_name => 'arbt_norm_activate',
            );

            is($verify, 0, 'The count of Arbiter is verified');
        };

        subtest '[ARBITER_1_0] Arbiter attach with chaind replica' => sub
        {
            my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);

            my $res = $t->attach_arbiter(
                volume_name      => 'arbt_chain_activate',
                shard            => 'true',
                shard_block_size => '512M'
            );

            is($res, 'true', 'Arbiter attach with normal replica');

            my $verify = $t->verify_arbiter(
                chaining    => 'Optimal',
                master_ip   => $MASTER_IP,
                volume_name => 'arbt_chain_activate',
            );

            is($verify, 0, 'The count of Arbiter is verified');
        };
    }
    else
    {
        print 'Pass this case';
    }
};

subtest '[ARBITER_2] Expanding volume with arbiter' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);
    my $node_cnt = scalar(@{$t->nodes});

    if ($node_cnt == 4)
    {
        # Getting the information to expanding node list
        my $addcnt     = $node_cnt-2;
        my $start_node = 2;

        my @hostnm_list = $t->gethostnm(
            start_node => $start_node,
            cnt        => $addcnt,
        );

        my @stgip_list = $t->hostnm2stgip(
            hostnms => \@hostnm_list
        );

        my $res = $t->volume_expand(
            volname   => 'arbt_shard_2node_expand',
            add_count => $addcnt,
            node_list => \@stgip_list
        );

        is($res, 0, 'Expanding volume with arbiter');

        my $verify = $t->verify_arbiter(
            chaining    => 'Not_Chained',
            master_ip   => $MASTER_IP,
            volume_name => 'arbt_shard_2node_expand',
        );

        is($verify, 0, 'The count of Arbiter is verified');
    }
    else
    {
        print 'Pass this case';
    }
};

subtest '[ARBITER_3] Cleaning arbiter test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt = scalar(@{$t->nodes});

    if ($node_cnt == 4)
    {
        my @vol_name = (
            'arbt_shard_2node_expand',
            'arbt_norm_activate',
            'arbt_chain_activate'
        );

        cmp_ok($t->volume_delete(volname => $_), '==', "Volume is deleted: $_")
            foreach (@vol_name);
    }
    else
    {
        print 'Pass this case';
    }
};

done_testing();
