#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY = 'alghost';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'Check apis for dealing with debug mode';

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

ok(1, "Test debug api");
subtest "check enable debug mode" => sub {
    my $t = Test::AnyStor::Base->new();
    my $debug_info = $t->get_debug();
    
    ok ($debug_info->{Cluster} == 0, 'Debug was disabled for Cluster');
    $t->set_debug(
        scope => 'Cluster',
        value => 'enable'
    );
    $debug_info = $t->get_debug();
    ok ($debug_info->{Cluster} == 1, 'Debug become enabled for Cluster');
};

subtest "check disable debug mode" => sub {
    my $t = Test::AnyStor::Base->new();
    my $debug_info = $t->get_debug();
    
    ok ($debug_info->{Cluster} == 1, 'Debug was enabled for Cluster');
    $t->set_debug(
        scope => 'Cluster',
        value => 'disable'
    );
    $debug_info = $t->get_debug();
    ok ($debug_info->{Cluster} == 0, 'Debug become disabled for Cluster');
};
done_testing();
