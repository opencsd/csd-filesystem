#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'polishedwh';
our $DESCRIPTION = '외부 볼륨 풀 API 테스트';

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname( rel2abs(__FILE__) )) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Net::OpenSSH;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Share;
use Test::AnyStor::ClusterVolume;
use Volume::LVM::LV;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my @jenkins_master_ip = map { chomp($_); $_; } split(/\s+/, `hostname -I`);

if (!@jenkins_master_ip)
{
    fail('Failed to get ips in this master');
    exit 1;
}

my $NFS_ADDR = $jenkins_master_ip[0];
my $NFS_DIR = '/nfs/data';

subtest 'Prepare nfs server' => sub
{
    # 1. Make directory for shared
    my $out = `mkdir -p $NFS_DIR 2>&1`;

    is($?>>8, 0, 'Failed to create test directory for NFS share');

    # 2. Setting the access control options
    open(my $fh, '>', '/etc/exports');

    print $fh "$NFS_DIR * (rw,sync)\n";

    close($fh);

    # Restarting the nfs-server
    $out = `systemctl restart nfs-server.service 2>&1`;

    is($?>>8, 0, 'Create test directory for NFS share');
};

subtest 'External vpool create' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @host_list = map {
        {
            Hostname => $_
        }
    } $t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes}));

    # required
    #   - nfs service ip
    #   - nfs shared path
    my $res = $t->volume_pool_create(
        pooltype     => 'External',
        pool_name    => 'ext_pool',
        purpose      => 'externaltest',
        ip           => $NFS_ADDR,
        externaltype => 'nfs',
        nodes        => \@host_list,
    );
};

subtest 'External volume create' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my @host_list = map {
        {
            Hostname => $_
        }
    } $t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes}));

    my $res = $t->volume_create_external(
        volname         => 'external_vol',
        pool_name       => 'ext_pool',
        externaltarget  => '/nfs/data',
        externaloptions => 'nfs',
        nodes           => \@host_list,
    );
};

subtest 'External vpool node reduce' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    my $node_cnt = scalar(@{$t->nodes});
    my @hostnms  = $t->gethostnm(start_node => 0, cnt => $node_cnt);

    shift(@hostnms);
    pop(@hostnms);

    my @with_dev = ();
    push (@with_dev, 
        {
            Hostname => $_,
            dev => ['/dev/sdd'] # dummy form
        }
    ) for @hostnms;

    if ($node_cnt >= 4)
    {
        my $res = $t->volume_pool_reconfig_external(
            pool_name => 'ext_pool',
            nodes     => \@with_dev,
        );
    }
    else
    {
        diag("pass");
    }
    
};

subtest 'External vpool node expand ' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    my $node_cnt = scalar(@{$t->nodes});
    my @hostnms  = $t->gethostnm(start_node => 0, cnt => $node_cnt);

    my @with_dev = ();
    push (@with_dev, 
        {
            Hostname => $_,
            dev => ['/dev/sdd'] # dummy form
        }
    ) for @hostnms;

    if ($node_cnt >= 4)
    {
        my $res = $t->volume_pool_reconfig_external(
            pool_name => 'ext_pool',
            nodes     => \@with_dev,
        );
    }
    else
    {
        diag("pass");
    }
    
};

# nfs share test
subtest 'External volume delete' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $res = $t->volume_delete_external(
        volname   => 'external_vol',
        pool_name => 'ext_pool',
    );
};

subtest 'External vpool remove' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    my $res = $t->volume_pool_remove(
        pooltype  => 'External',
        pool_name => 'ext_pool',
    );
};

subtest 'Clear NFS server' => sub
{
    # Clear access control options
    my $out = `perl -pi -e 's/data.*?\n//mg' '/etc/exports' 2>&1`;

    if (!is($?>>8, 0, '/etc/exports is cleaned'))
    {
        fail("Failed to clean /etc/exports: $out");
        return;
    }

    # Restart the nfs-server
    $out = `systemctl restart nfs-server 2>&1`;

    if (!is($?>>8, 0, 'nfs-server has restarted'))
    {
        fail("Failed to restart nfs-server: $out");
        return;
    }

    # Remove directory to share
    $out = `rm -rf $NFS_DIR 2>&1`;

    if (!is($?>>8, 0, 'the directory for NFS sharing is deleted'))
    {
        fail("Failed to delete NFS shared directory: $NFS_DIR: $out");
        return;
    }
};

done_testing();
