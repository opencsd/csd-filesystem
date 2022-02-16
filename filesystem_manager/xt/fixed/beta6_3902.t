#!/usr/bin/perl

our $AUTHORITY = 'cpan:alghost';
our $VERSION   = '1.00';

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
use Test::AnyStor::ClusterInfra;

#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Fixed-test(#3596) for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};


# 1. 노드 상태를 조회하여 Status가 OK인지 확인
printf("\nTest for cluster volume management will be performed...\n\n");

subtest 'Check node status' => sub {
    my $t   = Test::AnyStor::ClusterInfra->new(addr => $ENV{GMS_TEST_ADDR});
    $t->check_nodestatus();
};

done_testing();
