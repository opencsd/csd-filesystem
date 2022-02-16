#!/usr/bin/perl

our $AUTHORITY = 'bakeun';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN = 'Check whether #6684 issue fixed';

use strict;
use warnings;
use utf8;


BEGIN {
    use File::Basename          qw/dirname/;
    use File::Spec::Functions   qw/rel2abs/;

    my $ROOTDIR = dirname( rel2abs(__FILE__) );
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift( @INC,
        "$ROOTDIR/perl5/lib/perl5", "$ROOTDIR/lib",
        "$ROOTDIR/libgms",          "$ROOTDIR/t/lib",
        "/usr/girasole/lib" );
}

use Common::Useful;
use Share::CIFS::sambaConf;

use Env;
use Data::Dumper;
use Test::Mojo;
use Test::Most;
use Test::AnyStor::Share;
use Test::AnyStor::ClusterVolume;


$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $VOLUME = 'test_volume';

if ( !defined $GMS_TEST_ADDR ) {
    fail('Argument is missing');
    return 0;
}

ok(1, "Test for #6684 redmine issue");
ok(1, "Ref. http://redmine.gluesys.com/redmine/issues/6684");

subtest 'create_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    $t->volume_create_distribute(volname => $VOLUME);
    my $volume_info = $t->volume_list(volname => $VOLUME);
};

subtest 'create_share_instance_one' => sub 
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    #/cluster/share/create
    $t->cluster_share_create(
        sharename => 'test_share1', volume => $VOLUME, path => '/'
    );

    #/cluster/share/list
    my $share_list = $t->cluster_share_list();

    my $find_flag = 0;
    foreach my $each_share (@$share_list)
    {
        if( $each_share->{ShareName} eq 'test_share1' )
        {
            ok(1,'share create check');
            $find_flag = 1; 
            last;
        };
    }
    if( !$find_flag )
    {
        ok(0,'share create check');
    }

    #/cluster/share/update
    $t->cluster_share_update( 
        sharename => 'test_share1', volume => $VOLUME, path => '/',
        CIFS_onoff => 'on', NFS_onoff => 'off' 
    );

    my $cifs_list = $t->cluster_share_cifs_list();

    $find_flag = 0;
    foreach my $each_cifs (@$cifs_list)
    {
        if( $each_cifs->{ShareName} eq 'test_share1' )
        {
            ok(1,'cifs activate check');
            $find_flag = 1; 
            last;
        };
    }
    if( !$find_flag )
    {
        ok(0,'cifs activate check');
    }
};

subtest 'create_share_instance_two' => sub 
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    #/cluster/share/create
    $t->cluster_share_create(
        sharename => 'test_share2', volume => $VOLUME, path => '/'
    );

    #/cluster/share/list
    my $share_list = $t->cluster_share_list();

    my $find_flag = 0;
    foreach my $each_share (@$share_list)
    {
        if( $each_share->{ShareName} eq 'test_share2' )
        {
            ok(1,'share create check');
            $find_flag = 1; 
            last;
        };
    }
    if( !$find_flag )
    {
        ok(0,'share create check');
    }

    #/cluster/share/update
    $t->cluster_share_update( 
        sharename => 'test_share2', volume => $VOLUME, path => '/',
        CIFS_onoff => 'on', NFS_onoff => 'off' 
    );

    my $cifs_list = $t->cluster_share_cifs_list();

    $find_flag = 0;
    foreach my $each_cifs (@$cifs_list)
    {
        if( $each_cifs->{ShareName} eq 'test_share2' )
        {
            ok(1,'cifs activate check');
            $find_flag = 1; 
            last;
        };
    }
    if( !$find_flag )
    {
        ok(0,'cifs activate check');
    }
};

subtest 'check_wether_all_shares_is_exist_in_meta_sharefile' => sub 
{
    my $samba_conf = new Share::CIFS::sambaConf;
    my $meta_share_file = $samba_conf->{Config}{shares_file};
    diag(qq|target to check: $meta_share_file|);

    my @meta_cont = get_array_contents_from($meta_share_file);

    ok(
        ((grep {$_ =~ /\[test_share[1|2]\]/} @meta_cont) == 2),
        q|meta_share_file check|
    );

    diag(qq|meta_share_file contents\n|.join(qq|\n|, @meta_cont));
};

subtest 'delete_test_shares' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    #/cluster/share/delete
    $t->cluster_share_delete( sharename => 'test_share1' );
    $t->cluster_share_delete( sharename => 'test_share2' );
};

subtest 'delete_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    $t->volume_delete(volname => $VOLUME);
};

done_testing();

