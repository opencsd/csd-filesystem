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
use Test::Most;
use IO::File;

use Data::Dumper;

use Test::AnyStor::Util;
use Test::AnyStor::Initialize;

use Cluster::Initializer::Join;

$ENV{GMS_TEST_ADDR}        = shift(@ARGV) if @ARGV;
$ENV{GMS_JOIN_MASTER_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_JOIN_TGT_ADDR}    = shift(@ARGV) if @ARGV;

if (!defined($ENV{GMS_BUILD_CONFIG}) || !defined($ENV{GMS_TEST_ADDR}))
{
    warn '[ERR] Arguments missing';
    return 1;
}

# get master node ipaddr
my $MASTER = $ENV{GMS_JOIN_MASTER_ADDR};

# get cluster info for cluster initializing
my $INIT_ARGS = {Cluster_IP => $MASTER,};

if (!defined($INIT_ARGS->{Cluster_IP}))
{
    warn '[ERR] Cluster initializing args is empty';
    return 1;
}

my @TESTS = ();

# init rollback fault injection steps

my $creation_steps = Cluster::Initializer::Join->new->get_steps_detail;

foreach my $each_step (@{$creation_steps})
{
    if (defined($each_step->{backward_operation})
        && $each_step->{backward_operation} ne 'NO_OPERATION')
    {
        if (defined($each_step->{forward_operation}))
        {
            push(@TESTS, $each_step->{forward_operation});
        }
    }
}

if (scalar(@TESTS) == 0)
{
    warn 'There are no item to test';
    return 0;
}

print "fault injection points is like bellow\n" . join(', ', @TESTS) . "\n";

subtest 'Cluster initializing rollback test' => sub
{
    my $t = Test::AnyStor::Initialize->new(
        addr      => "$ENV{GMS_JOIN_TGT_ADDR}:80",
        no_logout => 1
    );

    # Test start
    for my $fault (@TESTS)
    {
        warn "Fault injection step: $fault";

        my $err = $t->ssh(
            addr => $ENV{GMS_JOIN_TGT_ADDR},
            cmd  => "echo $fault > /var/lib/gms/jipper_fault_injection",
        );

        if ($err)
        {
            fail('Failed to trigger cluster initializing rollback');
            return;
        }

        $t->init_join($INIT_ARGS);

        $err = $t->ssh(
            addr => $ENV{GMS_JOIN_TGT_ADDR},
            cmd  => 'rm -f /var/lib/gms/jipper_fault_injection',
        );

        fail(
            'Failed to delete /var/lib/gms/jipper_fault_injection for next test'
        ) if ($err);
    }

TESTEND:
};

done_testing();

