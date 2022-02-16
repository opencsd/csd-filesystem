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
use Test::AnyStor::Volume;
use Test::AnyStor::Filesystem;

use Data::Dumper;


#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Fixed-test(#3698,#3697) for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};


# 1. LV 생성
printf("\nTest for #3698,#3697 will be performed...\n\n");

my @volumes;

subtest 'Create a LV used to test' => sub {
    my $t = Test::AnyStor::Volume->new(addr => $ENV{GMS_TEST_ADDR});
    my $vol = $t->lvcreate();

    push(@volumes, $vol);
};

subtest 'Format the LV used to test' => sub {
    my $t = Test::AnyStor::Filesystem->new(addr => $ENV{GMS_TEST_ADDR});

    foreach my $_vol (@volumes){
        $t->format( lvname => $_vol );
    }
};

subtest 'Mount the LV used to test' => sub {
    my $t = Test::AnyStor::Filesystem->new(addr => $ENV{GMS_TEST_ADDR});

    foreach my $_vol (@volumes){
        $t->mount( lvname => $_vol );
    }
};

subtest 'Unmount the LV used to test' => sub {
    my $t = Test::AnyStor::Filesystem->new(addr => $ENV{GMS_TEST_ADDR});

    foreach my $_vol (@volumes){
        $t->unmount( path => "/dev/vg_cluster/$_vol" );
    }
};

subtest 'Remove the LV used to test' => sub {
    my $t = Test::AnyStor::Volume->new(addr => $ENV{GMS_TEST_ADDR});
    
    foreach my $_vol (@volumes){
        $t->lvdelete();
    }
};

done_testing();
