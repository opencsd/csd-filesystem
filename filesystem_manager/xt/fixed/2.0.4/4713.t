#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'alghost';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN = "4713: wrong order of names in clients api";

use strict;
use warnings;
use utf8;

our $GMSROOT;
our $GSMROOT;

BEGIN
{
    use Cwd qw/abs_path/;

    ($GMSROOT = abs_path($0)) =~ s/\/t\/[^\/]*$//;
    ($GSMROOT = $GMSROOT) =~ s/\/[^\/]*$/\/gsm/;

    unshift(@INC
        , "$GMSROOT/perl5/lib/perl5"
        , "$GMSROOT/t/lib"
        , "$GMSROOT/libgms"
        , "$GMSROOT/lib"
        , "$GSMROOT/lib");
}

use Env;
use Test::Most;

use Test::AnyStor::Dashboard;

#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing TEST CODE for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};

subtest 'Check order of X axis in clientgraph api ' => sub {
    my $t = Test::AnyStor::Dashboard->new(addr => $ENV{GMS_TEST_ADDR});
    my @result = $t->clientgraph();

    my $node_cnt = 1;
    foreach my $_e (@result){
        ok(defined($_e->{key}), 'Check there is X axis');
        ok($_e->{key} =~ /-$node_cnt/, 'Check order of X axis');
        $node_cnt++;
    }
};

done_testing();
