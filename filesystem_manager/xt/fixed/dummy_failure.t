#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'Geunyeong Bak';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN = "dummy failure test code";

use strict;
use warnings;
use utf8;

our $GMSROOT;
our $GSMROOT;

use Env;
use Test::Most;

#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Dummy TEST CODE for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};


subtest 'Doing Dummy CODE' => sub {
    ok(0, 'oops dummy failed');
};

done_testing();
