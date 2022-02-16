#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY = 'bakeun';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'Check functionality of dummy API';

use strict;
use warnings;
use utf8;

BEGIN {

#    my $ROOTDIR = dirname( rel2abs(__FILE__) );
#    $ROOTDIR =~ s/gms\/.+$/gms/;
    #
#    unshift( @INC,
#        "$ROOTDIR/perl5/lib/perl5", "$ROOTDIR/lib",
#        "$ROOTDIR/libgms",          "$ROOTDIR/t/lib",
#        "/usr/gsm/lib" );
}

use Env;
use Data::Dumper;
use Test::Mojo;
use Test::Most;
use Test::AnyStor::Base;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if ( !defined $GMS_TEST_ADDR ) {
    fail('Argument is missing');
    return 0;
}

ok(1, "Test for #6096 redmine issue");
ok(1, "Ref. http://redmine.gluesys.com/redmine/issues/6096");

subtest "Dummy API test" => sub {
    my $t = Test::AnyStor::Base->new();

    my $res = $t->call_rest_api ("dummy", {}, {}, {});
};

subtest "Cluster Dummy API test" => sub {
    my $t = Test::AnyStor::Base->new();

    my $res = $t->call_rest_api ("cluster/dummy", {}, {}, {});
};

done_testing();

