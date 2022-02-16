#!/usr/bin/perl

use Env;
use Test::Most;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

my $IP = ($GMS_TEST_ADDR =~ m/^([^:]+)/)[0];

undef($t);
