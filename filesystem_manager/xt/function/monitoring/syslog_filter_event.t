#!/usr/bin/perl -I /usr/gms/t/lib

use strict;
use warnings;
use utf8;

our $AUTHORITY        = 'hclee';
our $VERSION          = '1.00';
our $TEST_DESCRIPTOIN = 'syslog filter event test';

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname(rel2abs(__FILE__));
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/perl5/lib/perl5",
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib",
        "/usr/gsm/lib");

}

use Env;

use Test::Most;
use Test::AnyStor::Base;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined $GMS_TEST_ADDR)
{
    fail('Argument is missing');
    return 0;
}

subtest 'syslog filter event test' => sub
{
    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR);

    my $ip = [split(/:/, $GMS_TEST_ADDR)]->[0];

    my @ctdb_event = (
        {
            name => "check event with ctdbd recovery lock fail message.",
            cmd => "logger -t ctdbd -i \"failed read from recovery_lock_fd\"",
            expected     => 0,
            expected_msg => "ctdbd: failed read from recovery_lock_fd",
        },
    );

    my @etcd_event = (
        {
            name => "check event with etcd prev leader failure message.",
            cmd  =>
                "logger -t etcd -i \"request timed out, possibly due to previous leader failure\"",
            expected     => 0,
            expected_msg =>
                "etcd: request timed out, possibly due to previous leader failure",
        },
    );

    my @all_test = (@ctdb_event, @etcd_event);

    for my $test (@all_test)
    {
        my ($from, $to) = ($t->get_ts_from_server(), undef);

        my ($got, undef) = $t->ssh(
            addr => $ip,
            cmd  => $test->{cmd},
        );

        is($got, $test->{expected}, $test->{name});

        sleep 10;
        $to = $t->get_ts_from_server();

        $t->check_api_code_in_recent_events(
            category  => 'MONITOR',
            prefix    => "LOG_FROM_COMPONENT",
            from      => $from,
            to        => $to,
            level     => 'WARNING',
            msg       => $test->{expected_msg},
            skip_fail => 'false',
        );
    }
};

done_testing();
