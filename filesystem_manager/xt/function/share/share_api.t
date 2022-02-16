#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = <<ENDL;
기본적인 Share API의 동작을 확인하는 테스트.
모든 Share API를 한번씩 호출하여 정상적으로 동작하는지 검사함
ENDL

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

my $CIFS_UPDATE_WAIT = 1;
my $NFS_UPDATE_WAIT = 8;
my $TEST_DIR = '/mnt/share_api_test';
my $VOLUME = 'test_volume';
my $VOLUME_MOUNT = '/export/test_volume';
my $verbose = 1;

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my $nfs_method = 'ganesha';

diag("\tnfs_method: $nfs_method\n") if ($verbose);

my %answer_sheet = (
    'cifs_api' => {
        'mountable' => 1,
        'readable'  => 1,
        'writable'  => 1
    },
    'nfs_api' => {
        'mountable' => 1,
        'readable'  => 1,
        'writable'  => 1
    }
);

if (!defined($GMS_TEST_ADDR) && !defined($GMS_CLIENT_ADDR))
{
    ok(0, 'argument missing');
    return 1;
}

subtest 'create_test_account' => sub 
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR);

    $t->user_create(prefix => 'test_user');
    $t->user_create(prefix => 'group_user');
    $t->group_create(prefix => 'test_group');

    $t->join(group => 'test_group-1', members => ['group_user-1']);
};

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
    my $t = Test::AnyStor::Filing->new(
        addr   => $GMS_TEST_ADDR,
        remote => $test_addr,
        quiet  => $verbose ? 0 : 1,
    );

    $t->write_file(point => $VOLUME_MOUNT);

    $t->remote($GMS_CLIENT_ADDR);
    $t->make_directory(dir => $TEST_DIR);
};

subtest 'share_instance_api' => sub 
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    # /cluster/share/create
    $t->cluster_share_create(
        sharename => 'test_share',
        volume    => $VOLUME,
        path      => $VOLUME_MOUNT
    );

    # /cluster/share/list
    my $share_list = $t->cluster_share_list();

    my $find_flag = 0;

    foreach my $each_share (@{$share_list})
    {
        if ($each_share->{ShareName} eq 'test_share')
        {
            ok(1, 'share create check');
            $find_flag = 1;
            last;
        };
    }

    if (!$find_flag)
    {
        ok(0, 'share create check');
    }

    # /cluster/share/update
    $t->cluster_share_update(
        sharename  => 'test_share',
        volume     => $VOLUME,
        path       => $VOLUME_MOUNT,
        CIFS_onoff => 'on',
        NFS_onoff  => 'on' 
    );

    my $cifs_list = $t->cluster_share_cifs_list();

    $find_flag = 0;

    foreach my $each_cifs (@{$cifs_list})
    {
        if ($each_cifs->{ShareName} eq 'test_share')
        {
            ok(1, 'cifs activate check');
            $find_flag = 1;
            last;
        };
    }

    if (!$find_flag)
    {
        ok(0, 'cifs activate check');
    }

    my $nfs_list = $t->cluster_share_nfs_list();

    $find_flag = 0;

    foreach my $each_nfs (@{$nfs_list})
    {
        if ($each_nfs->{ShareName} eq 'test_share')
        {
            ok(1, 'nfs activate check');
            $find_flag = 1;
            last;
        };
    }

    if (!$find_flag)
    {
        ok(0, 'nfs activate check');
    }
};

subtest 'share_cifs_api' => sub 
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    # /cluster/share/cifs/setconf
    $t->cluster_share_cifs_setconf(active => 'on');

    # /cluster/share/cifs/getconf
    my $cifs_conf_info = $t->cluster_share_cifs_getconf();

    ok($cifs_conf_info->{Active} eq 'on', 'cifs set config check');

    # /cluster/share/cifs/update
    $t->cluster_share_cifs_update(
        sharename    => 'test_share',
        active       => 'on',
        share_right  => 'read/write',
        access_zone  => 'test_zone',
        zone_right   => 'allow',
        access_user  => 'test_user-1',
        user_right   => 'read/write',
        access_group => 'test_group-1',
        group_right  => 'read/write',
    );

    my $cifs_info = $t->cluster_share_cifs_info(sharename => 'test_share');

    if ($cifs_info->{Active} eq 'on')
    {
        my $find_flag = 0;

        foreach my $each_cifs_zone (@{$cifs_info->{AccessZone}})
        {
            if ($each_cifs_zone->{ZoneName} eq 'test_zone'
                && $each_cifs_zone->{Access} eq 'allow')
            {
                $find_flag++;
                last;
            };
        }

        foreach my $each_cifs_user (@{$cifs_info->{AccessUser}})
        {
            if ($each_cifs_user->{UserID} eq 'test_user-1'
                && $each_cifs_user->{AccessRight} eq 'read/write')
            {
                $find_flag++;
                last;
            };
        }

        foreach my $each_cifs_group (@{$cifs_info->{AccessGroup}})
        {
            if ($each_cifs_group->{GroupID} eq 'test_group-1'
                && $each_cifs_group->{AccessRight} eq 'read/write')
            {
                $find_flag++;
                last;
            };
        }

        if ($find_flag == 3)
        {
            ok(1, 'cifs update check');
        }
        else
        {
            ok(0, 'cifs update check');
        }
    }
    else
    {
        ok(0, 'cifs update check');
    }

    sleep $CIFS_UPDATE_WAIT;

    subtest 'I/O test' => sub
    {
        my %answer = (
            mountable => 0,
            readable  => 0,
            writable  => 0
        );

        my $t = Test::AnyStor::Filing->new(
            addr     => $GMS_TEST_ADDR,
            no_login => 1,
            remote   => $GMS_CLIENT_ADDR,
            quiet    => $verbose ? 0 : 1,
        );

        my $mntable = $t->is_mountable(
            type    => 'cifs',
            options => [
                "user=\'test_user-1\'",
                "password=\'gluesys!!\'",
                "rw",
                "sec=ntlmssp",
            ],
            device  => "//$test_addr/test_share",
            point   => $TEST_DIR
        );

        if ($mntable)
        {
            $answer{mountable} = $mntable;

            my $result = $t->mount(
                type    => 'cifs',
                options => [
                    "user=\'test_user-1\'",
                    "password=\'gluesys!!\'",
                    "rw",
                    "sec=ntlmssp"
                ],
                device  => "//$test_addr/test_share",
                point   => $TEST_DIR
            );

            if (!$result)
            {
                $answer{readable} = $t->is_readable(point => $TEST_DIR);
                $answer{writable} = $t->is_writable(point => $TEST_DIR);
            }
            else
            {
                ok(0, "[WARN] Failed to CIFS mount: //$test_dir/test_share: $TEST_DIR");
            }
        }

        my $correct = 1;

        foreach my $key (keys(%answer))
        {
            my $answer = $answer{$key};
            my $correct_answer = $answer_sheet{cifs_api}{$key};

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

        ok($correct, "CIFS Share I/O check");
    };

    # cifs_off
    $t->cluster_share_cifs_setconf(active => 'off');


    $t->cluster_share_update(
        sharename  => 'test_share',
        volume     => $VOLUME,
        path       => $VOLUME_MOUNT,
        CIFS_onoff => 'off',
        NFS_onoff  => 'on' 
    );
};

subtest 'share_nfs_api' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    # /cluster/share/nfs/setconf
    $t->cluster_share_nfs_setconf(active => 'on');

    # /cluster/share/nfs/getconf
    my $nfs_conf_info = $t->cluster_share_nfs_getconf();

    ok($nfs_conf_info->{Active} eq 'on', 'nfs set config check');

    # /cluster/share/nfs/update
    $t->cluster_share_nfs_update(
        sharename   => 'test_share',
        active      => 'on',
        access_zone => 'test_zone',
        zone_right  => 'read/write'
    );

    my $nfs_info = $t->cluster_share_nfs_info(sharename => 'test_share');

    if ($nfs_info->{Active} eq 'on')
    {
        my $find_flag = 0;

        foreach my $each_nfs_zone (@{$nfs_info->{AccessZone}})
        {
            if ($each_nfs_zone->{ZoneName} eq 'test_zone'
                && $each_nfs_zone->{Access} eq 'read/write')
            {
                ok(1, 'nfs update check');
                $find_flag = 1;
                last;
            };
        }

        if (!$find_flag)
        {
            ok(0, 'nfs update check');
        }
    }
    else
    {
        ok(0, 'nfs update check');
    }

    my $nfs_ready = 0;

    for (my $chk_try = $NFS_UPDATE_WAIT; $chk_try > 0; $chk_try--)
    {
        sleep $NFS_UPDATE_WAIT;

        my $check_result = `ssh $test_addr "showmount -e | grep $VOLUME | wc -l"`;

        if ($check_result > 0 || $nfs_method eq 'ganesha')
        {
            $nfs_ready = 1;
            last;
        }
    }

    if ($nfs_ready == 0)
    {
        fail("nfs can't be ready during waiting time");
    }
    else
    {
        subtest 'I/O test' => sub
        {
            my %answer = (
                mountable => 0,
                readable  => 0,
                writable  => 0
            );

            my $t = Test::AnyStor::Filing->new(
                addr     => $GMS_TEST_ADDR,
                remote   => $GMS_CLIENT_ADDR,
                no_login => 1,
                quiet    => $verbose ? 0 : 1,
            );

            my $mntable = $t->is_mountable(
                type    => 'nfs',
                options => [ "rw" ],
                device  => "$test_addr:/test_volume",
                point   => $TEST_DIR
            );

            if ($mntable)
            {
                $answer{mountable} = $mntable;

                my $result = $t->mount(
                    type    => 'nfs',
                    options => [ "rw" ],
                    device  => "$test_addr:/test_volume",
                    point   => $TEST_DIR
                );

                if (!$result)
                {
                    $answer{readable} = $t->is_readable(point => $TEST_DIR);
                    $answer{writable} = $t->is_writable(point => $TEST_DIR);
                }
                else
                {
                    ok(0, "[WARN] Failed to NFS mount: $test_addr:/test_volume -> $TEST_DIR");
                }
            }

            my $correct = 1;

            foreach my $key (keys(%answer))
            {
                my $answer = $answer{$key};
                my $correct_answer = $answer_sheet{nfs_api}{$key};

                if ($verbose)
                {
                    diag("\t\tanswer($key): $answer\n");
                    diag("\t\tcorrect_answer($key): $correct_answer\n");
                }

                if ($answer != $correct_answer)
                {
                    $correct = 0;
                    last;
                }
            }

            ok($correct, "NFS Share I/O check");
        };
    }

    # nfs_off
    $t->cluster_share_nfs_setconf(active => 'off');

    $t->cluster_share_update(
        sharename  => 'test_share',
        volume     => $VOLUME,
        path       => $VOLUME_MOUNT,
        CIFS_onoff => 'off',
        NFS_onoff  => 'off' 
    );
};

subtest 'delete_test_share' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    # /cluster/share/delete
    $t->cluster_share_delete(sharename => 'test_share');
};

subtest 'delete_test_paths' => sub
{
    my $t = Test::AnyStor::Filing->new(
        addr   => $GMS_TEST_ADDR,
        quiet  => $verbose ? 0 : 1,
        remote => $test_addr,
    );

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

subtest 'delete_test_account' => sub
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR);

    $t->user_delete(names => 'test_user-1');
    $t->user_delete(names => 'group_user-1');
    $t->group_delete(names => 'test_group-1');
};

done_testing();
