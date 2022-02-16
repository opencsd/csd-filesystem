#!/usr/bin/perl

use v5.14;

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Share;
use Test::AnyStor::Account;
use Test::AnyStor::Network;
use Test::AnyStor::ClusterVolume;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR  = $ENV{GMS_TEST_ADDR};
my $VOLUME         = 'test_volume';
my $VOLUME_MOUNT   = '/export/test_volume';
my $MAXIMUM_NUMBER = 255;

if (!defined($GMS_TEST_ADDR))
{
    ok(0, 'argument missing');
    return 1;
}

subtest 'create_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $t->volume_create_distribute(volname => $VOLUME);

    my $volume_info = $t->volume_list(volname => $VOLUME);

    $VOLUME_MOUNT = $volume_info->[0]->{Volume_Mount};
};

subtest 'maximum_share_create' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    for (my $i = 1; $i <= $MAXIMUM_NUMBER; $i++)
    {
        #/cluster/share/create
        $t->cluster_share_create(
            sharename => "test_share-$i",
            volume    => $VOLUME,
            path      => $VOLUME_MOUNT
        );
    }

    my $share_list = $t->cluster_share_list();
    my $count      = 0;

    foreach my $each_share (@{$share_list})
    {
        if ($each_share->{ShareName} =~ /^test_share-\d/)
        {
            $count++;
        }
    }

    if ($count == $MAXIMUM_NUMBER)
    {
        ok(1, 'maximum_share_create_check');
    }
    else
    {
        ok(0, 'maximum_share_create_check');
    }
};

subtest 'shares_delete' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    for (my $i = 1; $i <= $MAXIMUM_NUMBER; $i++)
    {
        #/cluster/share/delete
        $t->cluster_share_delete(sharename => "test_share-$i");
    }
};

subtest 'delete_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $t->volume_delete(volname => $VOLUME);
};

done_testing();

exit 0;
