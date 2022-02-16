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
use Test::AnyStor::ClusterVolume;

use Data::Dumper;


#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Fixed-test(#3596) for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};


# 1. 분배 볼륨 생성
printf("\nTest for cluster volume management will be performed...\n\n");

my @volumes;

subtest 'Create first volume used to test' => sub {
    my $t   = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});
    my $vol = $t->volume_create_distribute(
        volname => 'alghost-test-1'
    );

    push(@volumes, $vol);
};

subtest 'Create second volume used to test' => sub {
    my $t   = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});
    my $vol = $t->volume_create_distribute(
        volname => 'alghost---1'
    );

    push(@volumes, $vol);
};

subtest 'Delete volumes used to test' => sub {
    my $t = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});

    foreach my $vol (@volumes){
        $t->volume_delete(volname => $vol);
    }
};

done_testing();
