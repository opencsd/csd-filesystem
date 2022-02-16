#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'alghost';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN = "#4535: improve locking";

use strict;
use warnings;
use utf8;

our $GMSROOT;
our $GSMROOT;

BEGIN
{
    unshift(@INC
        , "/usr/gms/perl5/lib/perl5"
        , "/usr/gms/t/lib"
        , "/usr/gms/libgms"
        , "/usr/gms/lib"
        , "/usr/gsm/lib");
}

use Env;
use Test::Most;

use Test::AnyStor::Measure;
use Test::AnyStor::ClusterVolume;
use Cluster::ClusterGlobal;
use Cluster::MDSAdapter;

#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing TEST CODE for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};

# Create a cluster volume in background
# Start to create a cluster volume while creating
# Check creating a cluster volume after prevvolume is created

subtest 'Basic test for locking improved' => sub {

    my $vol_test = Test::AnyStor::ClusterVolume->new(
        addr => $ENV{GMS_TEST_ADDR}
    );

    my $prev_create = Asyncjob->new(
        obj     => $vol_test,
        func    => \&Test::AnyStor::ClusterVolume::volume_create_distribute,
        args    => ['volname', 'prevvolume'],
        timeout => 120
    );
    my $next_create = Asyncjob->new(
        obj     => $vol_test,
        func    => \&Test::AnyStor::ClusterVolume::volume_create_distribute,
        args    => ['volname', 'nextvolume'],
        timeout => 120 
    );

    my $ctl    = Asyncctl->new(trigger_term => 2);
    $ctl->add($prev_create);
    $ctl->add($next_create);
    
    my $res = $ctl->run();
    if ($res)
    {
        fail('Failed to create a Asyncjob');
    }

    while (!$ctl->done()){
        print "Asyncctl is not done yet; ret:$_\n";
        sleep 1;
    }
    
    if($prev_create->error){
        fail('Failed to create prev volume');
    }

    if($next_create->error){
        fail('Failed to create next volume');
    }
};

subtest 'Cleaning' => sub {

    my $vol_test = Test::AnyStor::ClusterVolume->new(
        addr => $ENV{GMS_TEST_ADDR}
    );
        
    $vol_test->volume_delete(volname => 'prevvolume');
    $vol_test->volume_delete(volname => 'nextvolume');
};

done_testing();
