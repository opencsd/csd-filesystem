#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY   = 'cpan:gluesys';
our $DESCRIPTOIN = "Share API로 NFS 옵션 설정이 잘 되는지 확인하는 테스트";

use strict;
use warnings;
use utf8;

use Env;
use Test::Most;
use Test::AnyStor::Share;
use Test::AnyStor::Account;
use Test::AnyStor::Network;
use Test::AnyStor::ClusterVolume;
use Test::AnyStor::Filing;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_CLIENT_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $GMS_CLIENT_ADDR = $ENV{GMS_CLIENT_ADDR};
my $NFS_UPDATE_WAIT = 8;
my $TEST_DIR = '/mnt/nfs_option_test';
my $VOLUME = 'test_volume';
my $VOLUME_MOUNT = '/export/test_volume';
my $verbose = 1;

my $nfs_method = "ganesha";

diag("\tnfs_method: $nfs_method\n") if ($verbose);

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my %answer_sheet = ();

if (!defined($GMS_TEST_ADDR) && !defined($GMS_CLIENT_ADDR))
{
    ok(0, 'argument missing');
    return 1;
}

subtest 'create_test_zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_zone_create(
        zonename => 'test_zone',
        type     => 'ip',
        zoneip   => $GMS_CLIENT_ADDR
    );
};

subtest 'create_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $t->volume_pool_create();
    $t->volume_create_distribute(volname => $VOLUME);

    my $volume_info = $t->volume_list(volname => $VOLUME);

    $VOLUME_MOUNT = $volume_info->[0]->{Volume_Mount};
};

subtest 'create_test_paths' => sub
{
    my $t = Test::AnyStor::Filing->new(addr => $GMS_TEST_ADDR);

    if (!$verbose)
    {
        $t->quiet(1);
    }

    $t->remote($test_addr);
    $t->write_file(point => $VOLUME_MOUNT);

    $t->remote($GMS_CLIENT_ADDR);
    $t->make_directory(dir => $TEST_DIR);
};

subtest 'create_nfs_share_instance' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    #/cluster/share/create
    $t->cluster_share_create(
        sharename => 'test_share',
        volume    => $VOLUME,
        path      => $VOLUME_MOUNT,
        NFS_onoff => 'on'
    );

    #/cluster/share/nfs/setconf
    $t->cluster_share_nfs_setconf(active => 'on');
};

subtest 'nfs_NoRootSquashing_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    #/cluster/share/nfs/update
    $t->cluster_share_nfs_update(
        sharename         => 'test_share',
        active            => 'on',
        access_zone       => 'test_zone',
        zone_right        => 'read/write',
        insecure          => 'off',
        no_root_squashing => 'on'
    );

    #no_root_squshing_test
    my $chk_flag = 0;

    if ($nfs_method eq 'gluster')
    {
        my $get_config = `ssh $test_addr "gluster volume get test_volume server.root-squash"`;

        diag("\tget_config\n\"\n$get_config\"") if ($verbose);

        my @lines = split(/\n/, $get_config);
        my $main_line = $lines[@lines-1];

        diag("\tmain_line: $main_line\n") if ($verbose);

        (my $key, my $value) = split(/\s+/, $main_line);

        if ($value eq 'off')
        {
            $chk_flag = 1;
        }
    }
    elsif ($nfs_method eq 'ganesha')
    {
        my $nfs_info = $t->cluster_share_nfs_info(sharename => 'test_share');

        (my $zone_info) = grep {
            $_->{ZoneName} eq 'test_zone'
        } @{$nfs_info->{AccessZone}};

        if ($zone_info->{NoRootSquashing} eq 'on')
        {
            $chk_flag = 1;
        }
    }

    ok(0, 'Not suported nfs method');

    ok($chk_flag, 'no_root_squashing check');
};

subtest 'nfs_Insecure_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    # /cluster/share/nfs/update
    $t->cluster_share_nfs_update(
        sharename         => 'test_share',
        active            => 'on',
        access_zone       => 'test_zone',
        zone_right        => 'read/write',
        insecure          => 'on',
        no_root_squashing => 'off'
    );

    # insecure_test
    my $chk_flag = 0;

    if ($nfs_method eq 'gluster')
    {
        my $get_config = `ssh $test_addr "gluster volume get test_volume nfs.ports-insecure"`;

        diag("\tget_config\n\"\n$get_config\"") if ($verbose);

        my @lines = split(/\n/, $get_config);
        my $main_line = $lines[@lines-1];

        diag("\tmain_line: $main_line\n") if ($verbose);

        (my $key, my $value) = split(/\s+/, $main_line);

        if ($value eq 'on')
        {
            $chk_flag = 1;
        }
    }
    elsif ($nfs_method eq 'ganesha')
    {
        my $nfs_info = $t->cluster_share_nfs_info(sharename => 'test_share');

        (my $zone_info) = grep {
            $_->{ZoneName} eq 'test_zone'
        } @{$nfs_info->{AccessZone}};

        if ($zone_info->{Insecure} eq 'on')
        {
            $chk_flag = 1;
        }
    }

    ok(0, 'Not suported nfs method');

    ok($chk_flag, 'insecure check');
};

subtest 'delete_nfs_share_instance' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    # nfs_off
    $t->cluster_share_nfs_setconf(active => 'off');

    # /cluster/share/delete
    $t->cluster_share_delete(sharename => 'test_share');
};

subtest 'delete_test_paths' => sub
{
    my $t = Test::AnyStor::Filing->new(addr => $GMS_TEST_ADDR);

    if (!$verbose)
    {
        $t->quiet(1);
    }

    $t->remote($test_addr);
    $t->rm(point => $VOLUME_MOUNT);

    $t->remote($GMS_CLIENT_ADDR);
    $t->rm(dir => $TEST_DIR);
};

subtest 'delete_test_volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $t->volume_delete(volname => $VOLUME);
    $t->volume_pool_remove();
};

subtest 'delete_test_zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $GMS_TEST_ADDR);

    $t->cluster_network_zone_delete(zonename => 'test_zone');
};

done_testing();
