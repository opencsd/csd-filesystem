#!/usr/bin/perl

our $AUTHORITY = 'cpan:potatogim';

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Base;
use Test::AnyStor::Auth;
use Test::AnyStor::ClusterVolume;
use Test::AnyStor::Network;
use Test::AnyStor::Share;
use Test::AnyStor::Filing;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

$ENV{LDAP_SERVER} = '192.168.3.114' if (!defined($ENV{LDAP_SERVER}));
$ENV{LDAP_USER}   = 'potatogim'     if (!defined($ENV{LDAP_USER}));
$ENV{LDAP_PASS}   = 'potatogim'     if (!defined($ENV{LDAP_PASS}));

my $MGMT_IP = (split(/:/, $ENV{GMS_TEST_ADDR}))[0];
my $VPOOL   = 'vg_cluster';
my $VOLUME  = 'ldap_vol';
my $SECZONE = 'DEFAULT';
my $SHARE   = {
    name   => 'ldap_share',
    volume => $VOLUME,
    path   => "/export/$VOLUME/ldap_share",
    ftp    => 1,
    nfs    => 1,
    cifs   => 1,
    afp    => 1,
};

# 검사 준비
printf("Preparing Function-test for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub
{
    ok(1, 'Ready');
};

# 1. 기본 검사
printf("\nTest for LDAP auth management will be performed...\n\n");

subtest 'LDAP Enabling' => sub
{
    my $t = Test::AnyStor::Auth->new(addr => $ENV{GMS_TEST_ADDR});

    my $res = $t->call_rest_api(
        'cluster/network/dns/update'
        , undef, [$ENV{LDAP_SERVER}], undef
    );

    if (!$t->success)
    {
        paint_err();
        fail('Failed to update DNS settings');
        paint_reset();
        goto RETURN;
    }

    for (my $i=0; $i<10; $i++)
    {
        system("ping -c $i $ENV{LDAP_SERVER} &>/dev/null");

        if ($? == -1)
        {
            paint_err();
            fail("Failed to execute: ping: $!");
            paint_reset();
            goto RETURN;
        }
        elsif ($? >> 8)
        {
            if ($i == 9)
            {
                paint_err();
                fail("This test will be skipped because LDAP server is not working");
                paint_reset();
                goto RETURN;
            }

            next;
        }

        diag("LDAP server is working normally");
        last;
    }

    my %entity = (
        URI        => "ldap://$ENV{LDAP_SERVER}",
        BaseDN     => 'dc=gmac,dc=gluesys,dc=com',
        BindDN     => 'uid=diradmin,cn=users,dc=gmac,dc=gluesys,dc=com',
        BindPw     => 'gluesys!!',
        RootBindDN => 'uid=diradmin,cn=users,dc=gmac,dc=gluesys,dc=com',
        RootBindPw => 'gluesys!!',
        PasswdDN   => 'cn=users,dc=gmac,dc=gluesys,dc=com',
        ShadowDN   => 'cn=users,dc=gmac,dc=gluesys,dc=com',
        GroupDN    => 'cn=groups,dc=gmac,dc=gluesys,dc=com'
    );

    # LDAP 인증 활성화
    is($t->ldap_enable(entity => \%entity), 0);

    $t->ssh_cmd(addr => $MGMT_IP, cmd => 'cat /etc/nslcd.conf');

RETURN:
    return;
};

subtest 'Volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});

    my @node_info = ();

    foreach ($t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes})))
    {
        push(@node_info,
            {
                Hostname => $_,
                PVs      => [ { Name =>'/dev/sdb' } ]
            }
        );
    }

    if (!$t->volume_pool_list(pool_name => $VPOOL, ignore_return => 1))
    {
        my $res = $t->volume_pool_create(
            pool_name => $VPOOL,
            provision => 'thick',
            pooltype  => 'Gluster',
            nodes     => \@node_info,
            purpose   => 'for_data',
        );

        ok(defined($res), 'Thick volume pool is created successfully');

        ok(defined($t->volume_pool_list(pool_name => $VPOOL))
            , "$VPOOL does exist");
    }

    my $node_cnt = scalar(@{$t->nodes});

    my $retval = $t->volume_create_distribute(
        pool_name  => $VPOOL,
        volname    => 'ldap_vol',
        capacity   => '10G',
        node_count => scalar(@{$t->nodes}),
        replica    => 1,
    );

    ok(defined($retval) && $retval eq $VOLUME, "Volume is created: $retval");
};

subtest 'Zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $ENV{GMS_TEST_ADDR});

    cmp_ok($t->cluster_network_zone_create(
        zonename    => $SECZONE,
        description => 'Zone allow global access for testing',
        type        => 'netmask',
        zoneip      => '0.0.0.0',
        zonemask    => '0.0.0.0',
    ), '==', 1, 'Zone "DEFAULT" is created');

    return;
};

subtest 'Share' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $ENV{GMS_TEST_ADDR});

#    $t->cluster_share_ftp_setconf(active => 'on');
    $t->cluster_share_nfs_setconf(active => 'on');
    $t->cluster_share_cifs_setconf(active => 'on');
#    $t->cluster_share_afp_setconf(active => 'on');

    # 공유 생성
    $t->cluster_share_create(
        sharename   => $SHARE->{name},
        volume      => $SHARE->{volume},
        path        => $SHARE->{path},
        description => 'Share to test LDAP',
        CIFS_onoff  => 'on',
        NFS_onoff   => 'on',
        FTP_onoff   => 'on',
        AFP_onoff   => 'on',
    );

    # 공유 활성화
    $t->cluster_share_nfs_update(
        sharename   => $SHARE->{name},
        active      => 'on',
        access_zone => 'DEFAULT',
        zone_right  => 'read/write',
    );

    $t->cluster_share_cifs_update(
        sharename    => $SHARE->{name},
        active       => 'on',
        share_right  => 'read/write',
        access_zone  => 'DEFAULT',
        zone_right   => 'allow',
        guest_allow  => 'off',
        access_user  => $ENV{LDAP_USER},
        user_right   => 'allow',
        hidden_share => 'off',
    );

    sleep 10; #wait for share daemon reloading

RETURN:
    return;
};

subtest 'Filing' => sub
{
    my $t = Test::AnyStor::Filing->new(addr => $ENV{GMS_TEST_ADDR});

    my $target;
    my $service_ip;

    foreach my $node (@{$t->nodes})
    {
        if ($node->{Mgmt_IP}->{ip} eq $MGMT_IP)
        {
            $target = $node;
        }

        if (ref($node->{Service_IP}) eq 'ARRAY'
            && defined($node->{Service_IP}[0])
            && !defined($service_ip))
        {
            $service_ip = $node->{Service_IP}[0];
        }
    }

    if (!defined($target))
    {
        paint_err();
        fail('Could not find the matched node for this testing!');
        paint_reset();
        goto RETURN;
    }

    if (!(defined($service_ip)))
    {
        paint_err();
        fail("Target doesn't have any service IP!");
        paint_reset();
        goto RETURN;
    }

    foreach my $type (qw/nfs cifs/)
    {
        my $addr = $service_ip;

        my $device;
        my $point = "/mnt/$type/$SHARE->{name}";
        my @options;

        if ($type eq 'nfs')
        {
            # 서비스_IP:/볼륨_이름
            $device = sprintf('%s:/%s/%s', $addr, $VOLUME, $SHARE->{name});
            # refered #4491
            @options = ('nolock,vers=3');
        }
        elsif ($type eq 'cifs')
        {
            # //서비스_IP/공유_이름
            $device  = sprintf('//%s/%s', $addr, $SHARE->{name});
            @options = (
                "username=$ENV{LDAP_USER}",
                "password=$ENV{LDAP_PASS}",
            );

            my $smb_config = <<ENDL;
ENDL

            system('modprobe cifs');
            system('echo "0x30" > /proc/fs/cifs/SecurityFlags');

            map {
                system("sed -i '/\[homes\]/i$_' /etc/samba/smb.conf");
            } (
                'client NTLMv2 auth = no',
                'client lanman auth = yes',
                'client plaintext auth = yes',
                'encrypt passwords = no',
            );
        }

        if (! -d $point)
        {
            $t->make_directory(dir => $point, options => ['-p']);
        }

        $t->show_mount(
            type    => $type,
            ip      => $addr,
            share   => $SHARE->{name},
            user    => $ENV{LDAP_USER},
            pass    => $ENV{LDAP_PASS},
        );

        if ($t->mount(
            type    => $type,
            device  => $device,
            point   => $point,
            options => \@options))
        {
            fail("Failed to mount ${\uc($type)} with LDAP auth");
            last;
        }
    }

    # 입출력
#    $t->io(
#        # 메모리 크기의 2배로 설정하도록...
#        memtotal => '1G',
#        rand_num => 1,
#        rand_max => 2048,
#        rand_min => 1024,
#        uid      => 0,
#        gid      => 0,
#        count    => 1,
#    );

RETURN:
    return;
};

subtest 'Clean-up : Share' => sub
{
    my $t = Test::AnyStor::Share->new(addr => $ENV{GMS_TEST_ADDR});

    $t->cluster_share_delete(sharename => $SHARE->{name});

    return;
};

subtest 'Clean-up : Zone' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $ENV{GMS_TEST_ADDR});

    $t->cluster_network_zone_delete(zonename => $SECZONE);

    return;
};

subtest 'Clean-up : Volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $ENV{GMS_TEST_ADDR});

    $t->volume_delete(pool_name => $VPOOL, volname => $VOLUME);

    if ($t->volume_pool_list(pool_name => $VPOOL, ignore_return => 1))
    {
        diag(explain($t->volume_pool_list()));

        ok(defined($t->volume_pool_remove(pool_name => $VPOOL))
            , "Thin volume pool is removed successfully: $VPOOL");

        diag(explain($t->volume_pool_list()));
    }
};

subtest 'LDAP disabling' => sub
{
    my $t = Test::AnyStor::Auth->new(addr => $ENV{GMS_TEST_ADDR});

    # LDAP 인증 비활성화
    is($t->ldap_disable(), 0);

    $t->ssh_cmd(addr => $MGMT_IP, cmd => 'cat /etc/nslcd.conf');

RETURN:
    return;
};

done_testing();
