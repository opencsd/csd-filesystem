#!/usr/bin/perl

our $AUTHORITY = 'cpan:gluesys';

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
use Test::AnyStor::Filing;
use Test::AnyStor::Base;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_CLIENT_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Function-test for %s...\n\n", $ENV{GMS_TEST_ADDR});

our ($tgt, undef) = split(':', $ENV{GMS_TEST_ADDR});
our ($src, undef) = split(':', $ENV{GMS_CLIENT_ADDR});
our $VOLUME_MOUNT = '/export/test_volume';
our $GMS_CLIENT_ADDR = $ENV{GMS_CLIENT_ADDR};
our $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
our $res;

use constant {
    TEST_CNT        => 3,
    TEST_VOL        => 'test_volume',
};

set_failure_handler(
    sub {
        my $builder = shift;
        paint_err();
        BAIL_OUT("01-sharectl.t is bailed out");
        paint_reset();
        done_testing();
    }
);


printf("\nTest for sharectl will be performed...\n\n");

# 0. 환경 구성

subtest 'create_test_users' => sub 
{
    $res = call_system("ssh $tgt /usr/gms/bin/accountctl user ".
        "add -u test_user -p test_user");
    ok($res == 0, "user created");
};

subtest 'create_test_zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $res = $t->cluster_network_zone_create(
        zonename => 'test_zone',
        type     => 'ip',
        zoneip   => $src
    );

    ok ($res == 1, "zone created");
};

subtest 'create_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $res = $t->volume_pool_create();
    ok (defined ($res), "volume pool created");

    $res = $t->volume_create_distribute(volname => TEST_VOL);
    ok (defined ($res), "volume created");

    my $volume_info = $t->volume_list(volname => TEST_VOL);
    $VOLUME_MOUNT = $volume_info->[0]->{Volume_Mount};
};

# 1. 기본 검사

subtest 'sharect_cifs_create' => sub 
{
    #1. create write mode share
    $res = call_system("ssh $tgt /usr/gms/bin/sharectl cifs create ".
                            "-m root:root:777  -w ".
                            "-S share_write -P $VOLUME_MOUNT/share_write");
    ok($res == 0, "share_write created");

    #1.1 share list check
    $res = call_system("ssh $tgt /usr/gms/bin/sharectl cifs list ".
                            "| grep share_write");
    ok($res == 0, "share_write listed");

    #1.2 share mount check

    #1.3 share write file check

    #1.4 share delete

    $res = call_system("ssh $tgt /usr/gms/bin/sharectl cifs remove ".
                            "-d -S share_write");

    ok($res == 0, "share_write removed");

    #2. create read mode share
    $res = call_system("ssh $tgt /usr/gms/bin/sharectl cifs create ".
                            "-m root:root:777  -r ".
                            "-S share_read -P $VOLUME_MOUNT/share_read");
    ok($res == 0, "share_read created");

    #2.1 share list check
    $res = call_system("ssh $tgt /usr/gms/bin/sharectl cifs list ".
                            "| grep share_read");
    ok($res == 0, "share_read listed");

    #2.2 share mount check

    #2.3 share write file failed check

    #2.4 share delete

    $res = call_system("ssh $tgt /usr/gms/bin/sharectl cifs remove ".
                            "-S share_read");
    ok($res == 0, "share_read removed");

    return 0;
};

subtest 'clean test_users' => sub
{
    $res = call_system( "ssh $tgt /usr/gms/bin/accountctl user ".
        "del -u test_user");
    ok($res == 0, "test_user deleted");
};

subtest 'delete_test_zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $res = $t->cluster_network_zone_delete( zonename => 'test_zone' );

    ok ($res == 1, "zone deleted");
};

subtest 'delete_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $res = $t->volume_delete(volname => TEST_VOL);
    ok (defined ($res), "volume deleted");

    $res = $t->volume_pool_remove();
    ok (defined ($res), "volume pool deleted");
};

done_testing();
