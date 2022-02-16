#!/usr/bin/perl

our $AUTHORITY = 'cpan:alghost';
our $VERSION   = '1.00';

use strict;
use warnings;
use utf8;

our $GMSROOT;
our $GSMROOT;

use Env;
use Test::Most;
use Data::Dumper;

use Test::AnyStor::Dashboard;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if ( !defined $GMS_TEST_ADDR ) {
    fail('Argument is missing');
    return 0;
}

subtest 'Events and Tasks' => sub
{
    my $t = Test::AnyStor::Dashboard->new(addr => $ENV{GMS_TEST_ADDR});
    $t->event_list();
    $t->task_list();
    $t->task_count();
    return;
};

done_testing();
