#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY = 'alghost';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'Check if configurations for fluentd and influxdb are correct';

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

my $config;
my @nodes;
ok(1, "Test for fluentd and influxdb");
subtest "Get nodes list" => sub {
    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR);
    @nodes = @{$t->nodes};
};

subtest "Validate configuration for fluentd" => sub {
    my $node_count = scalar(@nodes);
    my $mds_count = $node_count > 3 ? 3 : $node_count;
    foreach my $node (@nodes)
    {
        $config = `ssh $node->{Mgmt_IP} "cat /etc/td-agent/td-agent.conf"`;
        my $store_count = () = $config =~ /<store>/g;

        ok($store_count == $mds_count, "Validation store($store_count/$mds_count)");
        ok(index($config, '{{hostname}}') == -1, 'Validation to replace variable: {{hostname}}');
        ok(index($config, '{{db_config}}') == -1, 'Validation to replace variable: {{db_config}}');
    }
};

done_testing();
