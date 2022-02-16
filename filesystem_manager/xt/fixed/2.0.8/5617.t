#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY = 'bakeun';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'Check if CPU, Memory, Disk size exists or not in nodelist';

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

ok(1, "Test for #5617 redmine issue");
ok(1, "Ref. http://redmine.gluesys.com/redmine/issues/5617");

subtest "Get nodelist with CPU, Memory, Disk size" => sub {
    my $t = Test::AnyStor::Base->new();

    my $res = $self->call_rest_api ("cluster/general/nodelist", {}, {}, {});

    $t->t->json_has('/entity', 'has entity');
    ok(ref($res->{entity}) eq 'ARRAY', 'entity is ARRAY');

    my $node_list = $res->{entity};
    foreach my $each_node (@$node_list) {
        ok(defined($each_node->{Memory}),
          "Has Memory($each_node->{Storage_Hostname}): $each_node->{Memory}");
        ok(defined($each_node->{CPU}),
          "Has CPU($each_node->{Storage_Hostname}): $each_node->{CPU}");
        ok(defined($each_node->{Physical_Block_Size}),
          "Has Physical_Block_Size($each_node->{Storage_Hostname}): $each_node->{Physical_Block_Size}");
    }
};

done_testing();
