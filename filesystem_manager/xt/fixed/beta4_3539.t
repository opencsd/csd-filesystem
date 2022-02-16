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
printf("Preparing Merge-test for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};


# 1. 분배 볼륨 생성
printf("\nTest for cluster volume management will be performed...\n\n");

my @volumes;

subtest 'Create volumes used to test' => sub {
    my $t   = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});
    my $vol = $t->volume_create_distribute();

    push(@volumes, $vol);
};

subtest 'Validate default options for cluster volume' => sub {
    my $t = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});

    my $default_options = {
        'network.ping-timeoiut'            => 1,
        'diagnostics.brick-sys-log-level'  => 'WARNING',
        'diagnostics.client-sys-log-level' => 'WARNING',
        'cluster.min-free-disk'            => 5
    };
    
    foreach my $vol (@volumes){
        my $_options = $t->volume_get_config(volname => $vol);
        foreach my $default_key (keys %{$default_options}){
            if(!defined($_options->{$default_key}) or
                $_options->{$default_key} eq $default_options->{$default_key}){
                fail("Could not find default options for cluster volume");
                return -1;
            }
        }
    }
};

subtest 'Delete volumes used to test' => sub {
    my $t = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});

    foreach my $vol (@volumes){
        $t->volume_delete(volname => $vol);
    }
};

done_testing();
