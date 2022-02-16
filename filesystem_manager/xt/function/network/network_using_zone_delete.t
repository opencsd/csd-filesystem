#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY   = 'cpan:gluesys';
our $DESCRIPTOIN = "Network Zone API가 사용 중인 Zone의 삭제를 방지하는지 확인하는 테스트";

use strict;
use warnings;
use utf8;

use Env;
use Test::Most;
use Test::AnyStor::Share;
use Test::AnyStor::Network;
use Test::AnyStor::ClusterVolume;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_TEST_IFACE} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $VOLUME = 'test_volume';
my $VOLUME_MOUNT = '/export/test_volume';
my $verbose = 0;

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

if (!defined($GMS_TEST_ADDR) || !defined($GMS_TEST_IFACE))
{
    ok(0, 'argument missing');
    return 1;
}

subtest 'create test zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_zone_create(
        zonename => 'test_zone',
        type     => 'ip',
        zoneip   => $test_addr
    );
};

subtest 'create test volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $t->volume_create_distribute(volname => $VOLUME);

    my $volume_info = $t->volume_list(volname => $VOLUME);

    $VOLUME_MOUNT = $volume_info->[0]->{Volume_Mount};
};

subtest 'create share using test_zone' => sub 
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    #/cluster/share/create
    $t->cluster_share_create(
        sharename  => 'test_share',
        volume     => $VOLUME,
        path       => $VOLUME_MOUNT,
        CIFS_onoff => 'on'
    );

    #/cluster/share/cifs/update
    $t->cluster_share_cifs_update(
        sharename   => 'test_share',
        active      => 'on',
        share_right => 'read/write',
        access_zone => 'test_zone',
        zone_right  => 'allow'
    );
};

subtest 'using zone delete test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    my $result = $t->cluster_network_zone_delete(
        zonename     => 'test_zone',
        return_false => 1
    );

    ok($result, 'using zone delete check');
};

subtest 'delete_test_share' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    #/cluster/share/delete
    $t->cluster_share_delete(sharename => 'test_share');
};

subtest 'delete_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $t->volume_delete(volname => $VOLUME);
};

subtest 'delete_test_zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_zone_delete(zonename => 'test_zone');
};

done_testing();
