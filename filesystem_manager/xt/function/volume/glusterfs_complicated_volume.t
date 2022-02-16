#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'GlusterFS complicated volume creation test';

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
        "/usr/girasole/lib");
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

subtest "GlusterFS complicated volume creation test" => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $node_cnt  = scalar(@{$t->nodes});
    my @created   = ();
    my @need_vols = ();

    if ($node_cnt >= 2)
    {
        # A, B 노드 볼륨 생성 * 2, dist, rep2, 1g, tcp
        for my $i (0 .. 1)
        {
            push(@need_vols,
                {
                    volpolicy  => 'Distributed',
                    capacity   => '1.0G',
                    replica    => 2,
                    node_count => 2,
                    start_node => 0,
                }
            );
        }

        # C, D 노드에 볼륨 생성 * 2, stripe, rep1, 2g, tcp
        for my $i (0 .. 1)
        {
            push(@need_vols,
                {
                    volpolicy  => 'Striped',
                    capacity   => '2.0G',
                    replica    => 1,
                    node_count => 2,
                    start_node => 0,
                }
            );
        }
    }

    if ($node_cnt >= 3)
    {
        # A, B, C 노드에 볼륨 생성 * 2, networkraid, code1, 2g, tcp
        for my $i (0 .. 1)
        {
            push(@need_vols,
                {
                    volpolicy  => 'Disperse',
                    capacity   => '2.0G',
                    code_count => 1,
                    node_count => 3,
                    start_node => 0,
                }
            );
        }
    }

    if ($node_cnt >= 4)
    {
        # A, B, C, D 노드에 볼륨 생성 * 3, networkraid, code1, 3g, tcp
        for my $i (0 .. 2)
        {
            push(@need_vols,
                {
                    volpolicy  => 'Disperse',
                    capacity   => '3.0G',
                    code_count => 1,
                    node_count => 4,
                    start_node => 0,
                }
            );
        }

        # C, D  노드에 볼륨 생성 * 2, dist, rep1, 2g, tcp
        for my $i (0 .. 1)
        {
            push(@need_vols,
                {
                    volpolicy  => 'Distributed',
                    capacity   => '2.0G',
                    replica    => 1,
                    node_count => 2,
                    start_node => 2,
                }
            );
        }

        # A, B, C, D 노드에 볼륨 생성 * 2, dist, rep2, 2g, tcp
        for my $i (0 .. 1)
        {
            push(@need_vols,
                {
                    volpolicy  => 'Distributed',
                    capacity   => '2.0G',
                    replica    => 2,
                    node_count => 4,
                    start_node => 0,
                }
            );
        }

        # A, B, C, D 노드에 볼륨 생성 * 2, stripe, rep2, 2g, tcp
        for my $i (0 .. 1)
        {
            push(@need_vols,
                {
                    volpolicy  => 'Striped',
                    capacity   => '2.0G',
                    replica    => 2,
                    node_count => 4,
                    start_node => 0,
                }
            );
        }
    }

    for my $need (@need_vols)
    {
        my $res = $t->volume_create(%{$need});

        if ($res)
        {
            $need->{volname} = $res;

            push(@created, $need);

            # wait to create gluster vol & files on all nodes
            sleep 1;

            $t->verify_volstatus(volname => $res, exists => 1);

            $t->file_write(
                volname => $res,
                path    => "/export/$res",
                file    => 'test.file'
            );
        }
    }

    diag("Created Volume info: ${\Dumper(\@created)}");

    foreach my $vol (@created)
    {
        diag("to delete volume info: ${\Dumper($vol)}");

        $t->verify_volstatus(volname => $vol->{volname}, exists => 1);

        my $res = $t->volume_delete(volname => $vol->{volname});

        is($res, 0, 'cluster volume delete');

        # wait to delete gluster vol & files on all nodes
        sleep 1;

        $t->verify_volstatus(volname => $vol->{volname}, exists => 0);
    }
};

done_testing();
