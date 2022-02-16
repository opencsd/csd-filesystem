#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'cpan:gluesys';
our $DESCRIPTOIN = 'GMS Block API test';

use strict;
use warnings;
use utf8;

BEGIN {
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Test::Most;
use Data::Dumper;
use Test::AnyStor::Block;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $verbose = 1;

ok(1, 'Preparing for block API test');

subtest 'Block API' => sub
{
    my $block_test = Test::AnyStor::Block->new(addr => $GMS_TEST_ADDR);

    my $block_device_list = $block_test->block_device_list(scope => 'ALL');

    diag(explain($block_device_list)) if ($verbose);

    ok(defined($block_device_list->[0]), 'There is block_device_list');

    my $block_device_info = $block_test->block_device_info(devname => '/dev/sda');

    diag(explain($block_device_info)) if ($verbose);
};

done_testing();
