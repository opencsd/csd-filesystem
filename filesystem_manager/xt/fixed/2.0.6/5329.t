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

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if ( !defined $GMS_TEST_ADDR ) {
    fail('Argument is missing');
    return 0;
}

my $config = '';
my $t = Test::Mojo->new();
ok(1, "Test for netdata starts");
subtest "Access url for getting configuration related to netdata" => sub {
    my $url = $GMS_TEST_ADDR;
    $url =~ s/3000/19999/g;
    $t->get_ok("http://$url/netdata.conf")
    ->status_is(200);
    $config = $t->tx->res->content->asset->{content};
};

subtest "Validate configuration for plugins" => sub {
    ok(index($config, 'tc = no') != -1, 'Validation plugin: tc = no');
    ok(index($config, 'diskspace = yes') != -1, 'Validation plugin: diskspace = yes');
    ok(index($config, 'idlejitter = no') != -1, 'Validation plugin: idlejitter = no');
    ok(index($config, 'cgroups = no') != -1, 'Validation plugin: cgroups = no');
    ok(index($config, 'checks = no') != -1, 'Validation plugin: checks = no');
    ok(index($config, 'enable running new plugins = no') != -1, 'Validation plugin: enable running new plugins = no');
    ok(index($config, 'apps = no') != -1, 'Validation plugin: apps = no');
    ok(index($config, 'fping = no') != -1, 'Validation plugin: fping = no');
    ok(index($config, 'node.d = no') != -1, 'Validation plugin: node.d= no');
    ok(index($config, 'python.d = no') != -1, 'Validation plugin: python.d= no');
    ok(index($config, 'charts.d = no') != -1, 'Validation plugin: charts.d= no');
    ok(index($config, 'proc = yes') != -1, 'Validation plugin: proc = yes');
};

subtest "Validate configuration for backend" => sub {
    my $backend = '\[backend\][ \n\t]+enabled = yes[ \n\t]+type = json[ \n\t]+destination = 127.0.0.1:5170[ \n\t]+update every = 5';
    ok(index($config, /$backend/) != -1, 'Validation backend');
};

done_testing();
