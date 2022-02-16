#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY = 'Hyochan Lee';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'GlusterFS volume API 기본 테스트';

use strict;
use warnings;
use utf8;

BEGIN {
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname( rel2abs(__FILE__) );
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift( @INC,
        "$ROOTDIR/perl5/lib/perl5", "$ROOTDIR/lib",
        "$ROOTDIR/libgms",          "$ROOTDIR/t/lib",
        "/usr/gsm/lib" );
}

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::ClusterVolume;
use Volume::LVM::LV;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if ( !defined $GMS_TEST_ADDR ) {
    fail('Argument is missing');
    return 0;
}

subtest "create a cluster volume with reserved word \"volume\"" => sub {
    ok(1, "subtest started");

    my @vol_names =  (qw/volume snapshot/);

    my $t = Test::AnyStor::ClusterVolume->new( addr => $GMS_TEST_ADDR );

    my $node_cnt  = scalar @{ $t->nodes };

    for my $name (@vol_names)
    {
        my %vol_opt = ( 
            volname    => $name,
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => $node_cnt,
            start_node => 0,
            pool_name  => 'vg_cluster',
        );

        my $res = $t->volume_create(%vol_opt, verify => 0);
        if (!defined $res) 
        {
            ok (1, "\"$name\" volume is not created")
        }
        else
        {
            fail("\"$name\" volume is created");
        }

        $t->verify_volstatus(volname => $name, exists => 0);
    }
};

subtest "create a cluster volume with others reserved words" => sub {
    ok(1, "subtest started");

    my @vol_names = (qw/VOLUME vol v tier tiering snaps/,
                     qw/replicate replicated distribute distributed/,
                     qw/disperse stripe transport gluster/);

    my $t = Test::AnyStor::ClusterVolume->new( addr => $GMS_TEST_ADDR );

    my $node_cnt  = scalar @{ $t->nodes };

    for my $name (@vol_names)
    {
        my %vol_opt = ( 
            volname    => $name,
            volpolicy  => 'Distributed',
            capacity   => '1.0G',
            replica    => 1,
            node_count => $node_cnt,
            start_node => 0,
            pool_name  => 'vg_cluster',
        );

        my $res = $t->volume_create(%vol_opt);

        if (!defined $res) 
        {
            fail("\"$name\" volume is not created");
        }
        else
        {
            ok (1, "\"$name\" volume is created")
        }

        $t->verify_volstatus(volname => $name, exists => 1);
    }
};

subtest "cleanup cluster volume, if exists" => sub {
    ok(1, "subtest started");

    my $t = Test::AnyStor::ClusterVolume->new( addr => $GMS_TEST_ADDR );

    my $list = $t->volume_list();

    for my $vol (@$list)
    {
        my $name = $vol->{Volume_Name}; 
        $t->volume_delete(volname => $name);
        $t->verify_volstatus(volname => $name, exists => 0);
    }
};

done_testing();
