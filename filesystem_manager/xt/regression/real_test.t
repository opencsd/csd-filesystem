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

use Env;
use Getopt::Long;
use JSON qw/decode_json/;
use List::Util qw/shuffle/;

use Test::AnyStor::Base;

my $GMS_ROOT = '/usr/gms';

my @nodes     = ();
my $boot_wait = 300;

exit main();

sub main
{
    GetOptions('h' => \&help, 'nodes=s' => \@nodes);

    @nodes = split(/\s*,\s*/, join(',', @nodes));

    help() if (!scalar(@nodes));

    my $master_node = $nodes[0];

    p_printf("[%s]Real Cluster test : Check ping\n", get_time(time()));

    my @booted      = ();
    my @notbooted   = ();
    my $boot_up_cnt = 0;

    # 노드가 살아 있는지 확인한다.
    while ($boot_wait--)
    {
        sleep(1);

        p_printf("[%s] %d nodes boot up, timeout (%d)\n",
            get_time(time), $boot_up_cnt, $boot_wait);

        for my $node (@notbooted)
        {
            if (isboot_use_ping($node))
            {
                next if (grep { $node eq $_; } @booted);

                $boot_up_cnt++;

                push(@booted, $node);

                if ($boot_up_cnt >= scalar(@nodes))
                {
                    goto ALLBOOT;
                }
            }
        }
    }

    # 일부 노드라도 ping이 성공하지 않은 경우
    if ($boot_up_cnt < scalar(@nodes))
    {
        warn sprintf(
            "@notbooted %s not boot up (%s)\n\n",
            @notbooted == 1 ? "is" : "are",
            get_time(time())
        );

        warn sprintf("Real Node test failed (%s) \n\n", get_time(time()));

        return -1;
    }

ALLBOOT:

    # 모든 노드 ping alive check 성공, check cluster fine

    my $cnt = $boot_wait * 3;

    while ($cnt--)
    {
        p_printf("[%s] %d nodes boot up, timeout (%d)\n",
            get_time(time), $boot_up_cnt, $cnt);

        sleep(1);

        if (isclstfine($booted[0]))
        {
            p_printf("cluster status is fine (%s)\n", get_time(time()));

            my $status = 0;

            for my $node (@booted)
            {
                $status++ if (stat_chk($node));
            }

            if (!$status)
            {
                warn sprintf("[%s] Real Node test is succeed\n",
                    get_time(time()));
                last;
            }
            else
            {
                warn sprintf("[%s] Real Node test is failed\n",
                    get_time(time()));
                my $destpath = '/real-node/';
                nodes_archive($destpath, \@booted);
                return -1;
            }
        }
    }

    # Cluster Fine not detected
    if ($cnt < 1)
    {
        warn sprintf("[%s] cluster status is not fine\n\n", get_time(time()));

        my $status = 0;

        for my $node (@booted)
        {
            $status++ if (stat_chk($node));
        }

        if (!$status)
        {
            warn
                sprintf("[%s] Real Node test is succeed\n", get_time(time()));
            last;
        }
        else
        {
            warn sprintf("[%s] Real Node test is failed\n", get_time(time()));
            my $destpath = '/real-node/';
            nodes_archive($destpath, \@booted);
            return -1;
        }
    }

    return 0;
}

sub help
{
    warn "help\n";
    exit -1;
}
