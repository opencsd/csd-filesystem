#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'cpan:gluesys';
our $DESCRIPTOIN = "Share API로 CIFS 접근 권한 설정이 잘 되는지 확인하는 테스트";

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
my $TEST_DIR = '/mnt/cifs_access_test';
my $VOLUME = 'test_volume';
my $VOLUME_MOUNT = '/export/test_volume';
my $verbose = 1;

(my $test_addr = $GMS_TEST_ADDR) =~ s/:\d+$//;

my %answer_sheet = (
    'zone_right' => {
        'allow' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 1
        },
        'disallow' => {
            'mountable' => 0,
            'readable' => 0,
            'writable' => 0
        },
        'deny' => {
            'mountable' => 0,
            'readable' => 0,
            'writable' => 0
        }
    },
    'user_right' => {
        'allow' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 1
        },
        'disallow' => {
            'mountable' => 0,
            'readable' => 0,
            'writable' => 0
        },
        'read/write' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 1
        },
        'readonly' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 0
        },
        'deny' => {
            'mountable' => 0,
            'readable' => 0,
            'writable' => 0
        }
    },
    'group_right' => {
        'allow' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 1
        },
        'disallow' => {
            'mountable' => 0,
            'readable' => 0,
            'writable' => 0
        },
        'read/write' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 1
        },
        'readonly' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 0
        },
        'deny' => {
            'mountable' => 0,
            'readable' => 0,
            'writable' => 0
        }
    },
    'share_right' => {
        'read/write' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 1
        },
        'readonly' => {
            'mountable' => 1,
            'readable' => 1,
            'writable' => 0
        }
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
        quiet  => $verbose ? 0 : 1,
        remote => $test_addr
    );

    $t->write_file(point => $VOLUME_MOUNT);

    $t->remote($GMS_CLIENT_ADDR);
    $t->make_directory(dir => $TEST_DIR);
};

subtest 'create_cifs_share_instance' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    # /cluster/share/create
    $t->cluster_share_create(
        sharename  => 'test_share',
        volume     => $VOLUME,
        path       => $VOLUME_MOUNT,
        CIFS_onoff => 'on'
    );

    # /cluster/share/nfs/setconf
    $t->cluster_share_cifs_setconf(active => 'on');
};

subtest 'cifs_share_active_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $file_t = Test::AnyStor::Filing->new(
        addr     => $GMS_TEST_ADDR,
        no_login => 1,
        quiet    => $verbose ? 0 : 1,
        remote   => $GMS_CLIENT_ADDR,
    );

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
        guest_allow  => 'off',
        hidden_share => 'off',
        audit_on     => 'off'
    );

    sleep $CIFS_UPDATE_WAIT;

    $t->cluster_share_update(
        sharename  => 'test_share',
        CIFS_onoff => 'off'
    );

    my $mntable = $file_t->is_mountable(
        type    => 'cifs',
        options => [
            "user=\'test_user-1\'",
            "password=\'gluesys!!\'",
            "rw",
            "sec=ntlmssp"
        ],
        device  => "//$test_addr/test_share",
        point   => $TEST_DIR,
        skip_smb_restart => 1,
    );

    ok(!$mntable, 'check if cifs share access is denied when cifs share_active off');

    $t->cluster_share_update(
        sharename  => 'test_share',
        CIFS_onoff => 'on'
    );

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
        guest_allow  => 'off',
        hidden_share => 'off',
        audit_on     => 'off'
    );

    sleep $CIFS_UPDATE_WAIT;

    $mntable = $file_t->is_mountable(
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

    ok($mntable, 'check if cifs share access is allow when cifs share_active on');
};

subtest 'cifs_daemon_active_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $file_t = Test::AnyStor::Filing->new(
        addr     => $GMS_TEST_ADDR,
        no_login => 1,
        quiet    => $verbose ? 0 : 1,
        remote   => $GMS_CLIENT_ADDR,
    );

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
        guest_allow  => 'off',
        hidden_share => 'off',
        audit_on     => 'off'
    );

    sleep $CIFS_UPDATE_WAIT;

    $t->cluster_share_cifs_setconf(active => 'off');

    my $mntable = $file_t->is_mountable(
        type    => 'cifs',
        options => [
            "user=\'test_user-1\'",
            "password=\'gluesys!!\'",
            "rw",
            "sec=ntlmssp"
        ],
        device => "//$test_addr/test_share",
        point  => $TEST_DIR,
        skip_smb_restart => 1,
    );

    ok(!$mntable, 'check if cifs share access is denied when cifs daemon off');

    $t->cluster_share_cifs_setconf(active => 'on');

    $mntable = $file_t->is_mountable(
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

    ok($mntable, 'check if cifs share access is allow when cifs daemon on');
};

subtest 'cifs_zone_right_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $ZoneRightList = $t->cluster_share_cifs_getlist(
        partition => 'AccessZoneRight'
    );

    foreach my $zone_right (@{$ZoneRightList})
    {
        # /cluster/share/nfs/update
        $t->cluster_share_cifs_update(
            sharename    => 'test_share',
            active       => 'on',
            share_right  => 'read/write',
            access_zone  => 'test_zone',
            zone_right   => $zone_right,
            access_user  => 'test_user-1',
            user_right   => 'read/write',
            access_group => 'test_group-1',
            group_right  => 'read/write',
            guest_allow  => 'off',
            hidden_share => 'off',
            audit_on     => 'off'
        );

        sleep $CIFS_UPDATE_WAIT;

        subtest "zone_right($zone_right) test" => sub
        {
            my %answer = (
                mountable => 0,
                readable  => 0,
                writable  => 0
            );

            my $t = Test::AnyStor::Filing->new(
                addr     => $GMS_TEST_ADDR,
                no_login => 1
                quiet    => $verbose ? 0 : 1,
                remote   => $GMS_CLIENT_ADDR,
            );

            my $mntable = $t->is_mountable(
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
                    ok(0, "[WARN] Failed to CIFS mount: //$test_addr/test_share -> $TEST_DIR");
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
};

subtest 'cifs_user_right_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $UserRightList = $t->cluster_share_cifs_getlist(
        partition => 'AccessUserRight'
    );

    foreach my $user_right (@{$UserRightList})
    {
        next if ($user_right eq 'read/write');

        # /cluster/share/nfs/update
        $t->cluster_share_cifs_update(
            sharename    => 'test_share',
            active       => 'on',
            share_right  => 'read/write',
            access_zone  => 'test_zone',
            zone_right   => 'allow',
            access_user  => 'test_user-1',
            user_right   => $user_right,
            access_group => 'test_group-1',
            group_right  => 'read/write',
            guest_allow  => 'off',
            hidden_share => 'off',
            audit_on     => 'off'
        );

        sleep $CIFS_UPDATE_WAIT;

        subtest "user_right($user_right) test" => sub
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
                remote   => $GMS_CLIENT_ADDR,
            );

            my $mntable = $t->is_mountable(
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
                    ok(0, "[WARN] Failed to CIFS mount: //$test_addr/test_share -> $TEST_DIR");
                    next;
                }
            }

            my $correct = 1;

            foreach my $key (keys(%answer))
            {
                my $answer = $answer{$key};
                my $correct_answer = $answer_sheet{user_right}{$user_right}{$key};

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

            ok($correct, "user access check ($user_right)");
        };
    }
};

subtest 'cifs_group_right_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $GroupRightList = $t->cluster_share_cifs_getlist(
        partition => 'AccessGroupRight'
    );

    foreach my $group_right (@{$GroupRightList})
    {
        next if ($group_right eq 'read/write');

        # /cluster/share/nfs/update
        $t->cluster_share_cifs_update(
            sharename    => 'test_share',
            active       => 'on',
            share_right  => 'read/write',
            access_zone  => 'test_zone',
            zone_right   => 'allow',
            access_user  => 'test_user-1',
            user_right   => 'disallow',
            access_group => 'test_group-1',
            group_right  => $group_right,
            guest_allow  => 'off',
            hidden_share => 'off',
            audit_on     => 'off'
        );

        sleep $CIFS_UPDATE_WAIT;

        subtest "group_right($group_right) test" => sub
        {
            my %answer = (
                mountable => 0,
                readable  => 0,
                writable  => 0
            );

            my $t = Test::AnyStor::Filing->new(
                addr     => $GMS_TEST_ADDR,
                no_login => 1,
                verbose  => $verbose ? 0 : 1,
                remote   => $GMS_CLIENT_ADDR,
            );

            my $mntable = $t->is_mountable(
                type    => 'cifs',
                options => [
                    "user=\'group_user-1\'",
                    "password=\'gluesys!!\'",
                    "rw",
                    "sec=ntlmssp"
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
                        "user=\'group_user-1\'",
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
                    ok(0, "[WARN] Failed to CIFS mount: //$test_addr/test_share -> $TEST_DIR");
                    next;
                }
            }

            my $correct = 1;

            foreach my $key (keys(%answer))
            {
                my $answer = $answer{$key};
                my $correct_answer = $answer_sheet{group_right}{$group_right}{$key};

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

            ok($correct, "group access check ($group_right)");
        };
    }
};

subtest 'cifs_share_right_test' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    my $ShareRightList = $t->cluster_share_cifs_getlist(
        partition => 'ShareRight'
    );

    foreach my $share_right (@{$ShareRightList})
    {
        # /cluster/share/nfs/update
        $t->cluster_share_cifs_update(
            sharename    => 'test_share',
            active       => 'on',
            share_right  => $share_right,
            access_zone  => 'test_zone',
            zone_right   => 'allow',
            access_user  => 'test_user-1',
            user_right   => 'allow',
            access_group => 'test_group-1',
            group_right  => 'allow',
        );

        sleep $CIFS_UPDATE_WAIT;

        subtest "share_right($share_right) test" => sub
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
                remote   => $GMS_CLIENT_ADDR,
            );

            my $mntable = $t->is_mountable(
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
                    ok(0, "[WARN] Failed to CIFS mount: //$test_addr/test_share -> $TEST_DIR");
                    next;
                }
            }

            my $correct = 1;

            foreach my $key (keys(%answer))
            {
                my $answer = $answer{$key};
                my $correct_answer = $answer_sheet{share_right}{$share_right}{$key};

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

            ok($correct, "share access check ($share_right)");
        };
    }
};

subtest 'delete_cifs_share_instance' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $GMS_TEST_ADDR);

    # nfs_off
    $t->cluster_share_cifs_setconf(active => 'off');

    # /cluster/share/delete
    $t->cluster_share_delete(sharename => 'test_share');
};

subtest 'delete_test_paths' => sub
{
    my $t = Test::AnyStor::Filing->new(
        addr   => $GMS_TEST_ADDR,
        remote => $test_addr,
        quiet  => $verbose ? 0 : 1,
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
