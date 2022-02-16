#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Share API로 NFS 접근 권한 설정이 잘 되는지 확인하는 테스트";

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
my $NFS_UPDATE_WAIT = 3;
my $TEST_DIR = '/mnt/nfs_access_test';
my $VOLUME = 'test_volume';
my $VOLUME_MOUNT = '/export/test_volume';
my $verbose = 1;

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my $nfs_method = 'ganesha';

diag("\tnfs_method: $nfs_method\n") if ($verbose);

my $MOUNT_TARGET = ($nfs_method eq 'gluster') ? "$test_addr:/$VOLUME"
                 : ($nfs_method eq 'ganesha') ? "$test_addr:/$VOLUME"
                 : ($nfs_method eq 'kernel')  ? "$test_addr:$VOLUME_MOUNT"
                 : undef;

if (!defined($MOUNT_TARGET))
{
    ok(0, 'nfs_method is invalid: '.$nfs_method);
    done_testing();
    exit 1;
}


my %answer_sheet = (
    'zone_right' => {
        'read/write' => {
            'mountable' => 1,
            'readable'  => 1,
            'writable'  => 1
        },
        'readonly' => {
            'mountable' => 1,
            'readable'  => 1,
            'writable'  => 0
        },
        'disallow' => {
            'mountable' => 0,
            'readable'  => 0,
            'writable'  => 0
        }
    }
);

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

    # /cluster/share/create
    $t->cluster_share_create(
        sharename => 'test_share',
        volume    => $VOLUME,
        path      => $VOLUME_MOUNT,
        NFS_onoff => 'on'
    );

    # /cluster/share/nfs/setconf
    $t->cluster_share_nfs_setconf(active => 'on');
};

subtest 'nfs_share_active_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $file_t = Test::AnyStor::Filing->new(addr => $GMS_TEST_ADDR, no_login => 1);

    if (!$verbose)
    {
        $file_t->quiet(1);
    }

    $file_t->remote($GMS_CLIENT_ADDR);

    $t->cluster_share_nfs_update(
        sharename         => 'test_share',
        active            => 'on',
        access_zone       => 'test_zone',
        zone_right        => 'read/write',
        insecure          => 'off',
        no_root_squashing => 'off'
    );

    sleep $NFS_UPDATE_WAIT;

    $t->cluster_share_update(
        sharename => 'test_share',
        NFS_onoff => 'off'
    );

    my $mntable = $file_t->is_mountable(
        type    => 'nfs',
        options => ['rw', "timeo=$NFS_UPDATE_WAIT" ],
        device  => $MOUNT_TARGET,
        point   => $TEST_DIR,
        timeo   => $NFS_UPDATE_WAIT
    );

    ok(!$mntable, 'check if nfs share access is denied when nfs share_active off');

    $t->cluster_share_update(sharename => 'test_share', NFS_onoff => 'on');

    $t->cluster_share_nfs_update(
        sharename         => 'test_share',
        active            => 'on',
        access_zone       => 'test_zone',
        zone_right        => 'read/write',
        insecure          => 'off',
        no_root_squashing => 'off'
    );

    sleep $NFS_UPDATE_WAIT;

    $mntable = $file_t->is_mountable(
        type    => 'nfs',
        options => ['rw', "timeo=$NFS_UPDATE_WAIT"],
        device  => $MOUNT_TARGET,
        point   => $TEST_DIR,
        timeo   => $NFS_UPDATE_WAIT
    );

    ok($mntable, 'check if nfs share access is allow when nfs share_active on');
};

subtest 'nfs_daemon_active_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $file_t = Test::AnyStor::Filing->new(addr => $GMS_TEST_ADDR, no_login => 1);

    if (!$verbose)
    {
        $file_t->quiet(1);
    }

    $file_t->remote($GMS_CLIENT_ADDR);

    $t->cluster_share_nfs_update(
        sharename         => 'test_share',
        active            => 'on',
        access_zone       => 'test_zone',
        zone_right        => 'read/write',
        insecure          => 'off',
        no_root_squashing => 'off'
    );

    sleep $NFS_UPDATE_WAIT;

    $t->cluster_share_nfs_setconf(active => 'off');

    my $mntable = $file_t->is_mountable(
        type    => 'nfs',
        options => ['rw', "timeo=$NFS_UPDATE_WAIT" ],
        device  => $MOUNT_TARGET,
        point   => $TEST_DIR,
        timeo   => $NFS_UPDATE_WAIT
    );

    # if method gluater nfs, glusterd is not stoped
    if ($nfs_method eq 'gluster')
    {
        $mntable = !$mntable;
    }

    ok(!$mntable, 'check if nfs share access is allow when nfs daemon off'); 

    $t->cluster_share_nfs_setconf(active => 'on');

    $t->cluster_share_nfs_update(
        sharename         => 'test_share',
        active            => 'on',
        access_zone       => 'test_zone',
        zone_right        => 'read/write',
        insecure          => 'off',
        no_root_squashing => 'off'
    );

    sleep $NFS_UPDATE_WAIT;

    $mntable = $file_t->is_mountable(
        type    => 'nfs',
        options => ['rw', "timeo=$NFS_UPDATE_WAIT" ],
        device  => $MOUNT_TARGET,
        point   => $TEST_DIR,
        timeo   => $NFS_UPDATE_WAIT
    );

    ok($mntable, 'check if nfs share access is allow when nfs daemon on');
};

subtest 'nfs_zone_right_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $ZoneRightList = $t->cluster_share_nfs_getlist(
        partition => 'AccessZoneRight'
    );

    foreach my $zone_right (@{$ZoneRightList})
    {
        # /cluster/share/nfs/update
        $t->cluster_share_nfs_update(
            sharename         => 'test_share',
            active            => 'on',
            access_zone       => 'test_zone',
            zone_right        => $zone_right,
            insecure          => 'off',
            no_root_squashing => 'off'
        );

        my $nfs_ready = 0;

        for (my $chk_try = $NFS_UPDATE_WAIT; $chk_try > 0; $chk_try--)
        {
            sleep $NFS_UPDATE_WAIT;

            my $check_result = 0;

            if ($zone_right eq 'disallow' || $nfs_method eq 'ganesha')
            {
                $check_result = 1;
            }
            else
            {
                diag("cmd ==> showmount -e | grep $VOLUME | wc -l");
                $check_result = `ssh $test_addr "showmount -e | grep $VOLUME | wc -l"`; 
            }

            if ($check_result > 0)
            {
                $nfs_ready = 1;
                last;
            }
        }

        if ($nfs_ready == 0)
        {
            diag("showmount -e: ".`ssh $test_addr "showmount -e"`);
            fail("nfs can't be ready during waiting time($zone_right)");
        }
        else
        {
            subtest "zone_right($zone_right) test" => sub
            {
                my %answer = (
                    mountable => 0,
                    readable  => 0,
                    writable  => 0
                );

                my $t = Test::AnyStor::Filing->new(
                    addr     => $GMS_TEST_ADDR,
                    no_login => 1,
                    quiet    => $verbose ? 0 : 1,
                );

                $t->remote($GMS_CLIENT_ADDR);

                #mount
                my $mntable = $t->is_mountable(
                    type    => 'nfs',
                    options => ['rw', "timeo=$NFS_UPDATE_WAIT"],
                    device  => $MOUNT_TARGET,
                    point   => $TEST_DIR,
                    timeo   => $NFS_UPDATE_WAIT
                );

                if ($mntable)
                {
                    $answer{mountable} = $mntable;

                    my $result = $t->mount(
                        type    => 'nfs',
                        options => ['rw'],
                        device  => $MOUNT_TARGET,
                        point   => $TEST_DIR
                    );

                    if (!$result)
                    {
                        $answer{readable} = $t->is_readable(point => $TEST_DIR);
                        $answer{writable} = $t->is_writable(point => $TEST_DIR);
                    }
                    else
                    {
                        ok(0, "[WARN] Failed to NFS mount: $MOUNT_TARGET -> $TEST_DIR");
                        next;
                    }
                }

                my $correct = 1;

                foreach my $key (keys(%answer))
                {
                    my $answer = $answer{$key};
                    my $correct_answer = $answer_sheet{zone_right}{$zone_right}{$key};

                    if ($verbose)
                    {
                        diag("\t\tanswer($key): $answer\n");
                        diag("\t\tcorrect_answer($key): $correct_answer\n");
                    }

                    if ($answer != $correct_answer)
                    {
                        $correct = 0;
                        last;
                    };
                }

                ok($correct, "zone access check ($zone_right)");
            };
        }
    }
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
    my $t = Test::AnyStor::Filing->new(
        addr  => $GMS_TEST_ADDR,
        quiet => $verbose ? 0 : 1,
    );

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
