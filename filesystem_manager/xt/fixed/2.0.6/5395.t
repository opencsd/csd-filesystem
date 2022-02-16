#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY = 'alghost';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'Check if netdata exists or not';

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

ok(1, "Test for netdata starts");
subtest "Get master" => sub {
    my $t = Test::AnyStor::Base->new();
    my $res = $t->get_master();

    ok(defined($res->{Hostname}), "Has hostname: $res->{Hostname}");
    ok(defined($res->{Mgmt_ip}), "Has hostname: $res->{Mgmt_ip}");
    ok(defined($res->{Storage_ip}), "Has hostname: $res->{Storage_ip}");
};

done_testing();
