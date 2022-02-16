#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY = 'alghost';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'Check whether DNS delete bug is fixed';

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Mojo;
use Test::Most;
use Test::AnyStor::Base;
use Test::AnyStor::Network;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if ( !defined $GMS_TEST_ADDR ) {
    fail('Argument is missing');
    return 0;
}

my $test_dns = '8.8.8.8';

ok(1, "Test DNS delete bug");
subtest "check dns update" => sub {
    my $t = Test::AnyStor::Network->new();
    $t->cluster_network_dns_update(dns => [$test_dns,'']);
    my $dns_info = $t->cluster_network_dns_info();
    ok (
      grep("$_ eq $test_dns", @{$dns_info->{nameserver}}),
      "Check whether test dns($test_dns) is exist"
    );
};

subtest "check dns delete" => sub {
    my $t = Test::AnyStor::Network->new();
    $t->cluster_network_dns_update(dns => ['','']);
    my $dns_info = $t->cluster_network_dns_info();
    ok (
      ! grep("$_ eq $test_dns", @{$dns_info->{nameserver}}),
      "Check whether test dns($test_dns was deleted"
    );
};

done_testing();
