#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'GlusterFS volume 확장 테스트';

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

subtest 'GlusterFS volume expand, rebalance test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $node_cnt  = scalar(@{$t->nodes});
    my @need_vols = ();
    my @created   = ();
    my @sub_tests = ();

    if ($node_cnt == 1)
    {
        push(@sub_tests, 'Distributed, Replicated 1 expand test');
        push(@need_vols,
            {
                volpolicy  => 'Distributed',
                capacity   => '1.0G',
                replica    => 1,
                node_count => 1,
                start_node => 0,
            }
        );
    }
    elsif ($node_cnt == 2)
    {
        push(@sub_tests, 'Distributed, Replicated 2 expand test');
        push(@need_vols,
            {
                volpolicy  => 'Distributed',
                capacity   => '1.0G',
                replica    => 2,
                node_count => 2,
                start_node => 0,
            }
        );

        push(@sub_tests, 'Striped, Replicated 1 expand test');
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
    elsif ($node_cnt == 3)
    {
        push(@sub_tests, 'Disperse, Code 1 expand test');
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
    elsif ($node_cnt >= 4)
    {
        push(@sub_tests, 'Striped, Replicated 2 expand test');
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

    foreach my $need (@need_vols)
    {
        my $res = $t->volume_create(%{$need});

        next unless ($res);

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

    for my $i (0 .. $#need_vols)
    {
        expand_test(
            request  => $need_vols[$i],
            testname => $sub_tests[$i],
            handler  => $t
        );
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

sub expand_test
{
    my %args = @_;

    foreach my $key (qw/request testname handler/)
    {
        if (!defined($args{$key}))
        {
            fail("Argument($key}) is missing.");
            return;
        }
    }

    my $request  = $args{request};
    my $testname = $args{testname};
    my $handler  = $args{handler};

    my $node_cnt = scalar(@{$handler->nodes});
    my @hostnms  = $handler->gethostnm(start_node => 0, cnt => $node_cnt);
    my @stgips   = $handler->hostnm2stgip(hostnms => \@hostnms);
    my @mgmtips  = $handler->hostnm2mgmtip(hostnms => \@hostnms);

    subtest $testname => sub
    {
        my $totfiles = $node_cnt * 2;
        my $addcnt   = $request->{node_count};
        my $i        = $request->{start_node} + $request->{node_count} - 1;

        while (1)
        {
            if ($i+$addcnt > $node_cnt - 1)
            {
                ok(1, "node is not enough to expand the volume");
                last;
            }

            # clearing volume for reblance test
            $handler->file_remove(
                volname => $request->{volname},
                path    => "/export/$request->{volname}",
                file    => '*'
            );

            # all file write on first node
            my @first_node_hostnm = @hostnms[0..0];
            my $first_node_mgmtip = $mgmtips[0];

            $handler->file_write(
                volname   => $request->{volname},
                node_list => \@first_node_hostnm,
                path      => "/export/$request->{volname}",
                file      => 'test.file',
                tot       => $totfiles
            );

            # try to expand volume
            my @expand_list = @stgips[$i+1 .. $i+$addcnt];

            my $res = $handler->volume_expand(
                volname   => $request->{volname},
                add_count => $addcnt,
                node_list => \@expand_list
            );

            last if ($res);

            $res = $handler->verify_volstatus(
                volname => $request->{volname},
                exists  => 1
            );

            last if ($res);

            # get file count, before rebalance
            my ($file_cnt, undef) = $handler->ssh_cmd(
                addr => $first_node_mgmtip,
                cmd  => "ls /volume/$request->{volname} | wc -l"
            );

            if (!$file_cnt || $file_cnt == -1)
            {
                fail("Getting file count on "
                    . "$first_node_mgmtip:/volume/$request->{volname}");

                last;
            }

            # try to rebalance file in volume
            $res = $handler->volume_rebalance(volname => $request->{volname});

            last if ($res);

            # waiting to reloading vol files & moving data file in volume
            sleep 1;

            $res = $handler->verify_volrebalance(
                volname   => $request->{volname},
                node      => $first_node_mgmtip,
                totfiles  => $file_cnt
            );

            last if ($res);

            # clearing volume
            $handler->file_remove(
                volname => $request->{volname},
                path    => "/export/$request->{volname}",
                file    => '*'
            );

            # file i/o test each bricks
            $handler->file_write(
                volname => $request->{volname},
                path    => "/export/$request->{volname}",
                file    => 'test.file'
            );

            $i += $addcnt;
        }
    };
}

done_testing();

