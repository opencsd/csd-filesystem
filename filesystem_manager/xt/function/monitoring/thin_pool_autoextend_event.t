#!/usr/bin/perl -I /usr/gms/t/lib

use strict;
use warnings;
use utf8;

our $AUTHORITY        = 'hclee';
our $VERSION          = '1.00';
our $TEST_DESCRIPTOIN = 'thin pool auto extending event test';

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname(rel2abs(__FILE__));
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/perl5/lib/perl5",
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib",
        "/usr/gsm/lib");

}

use Env;

use Test::Most;
use Test::AnyStor::Base;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined $GMS_TEST_ADDR)
{
    fail('Argument is missing');
    return 0;
}

subtest 'dmeventd event test' => sub
{
    my $ip = [split(/:/, $GMS_TEST_ADDR)]->[0];

    my $diskname = '/dev/sdd';
    my $vgname   = 'vg_test';
    my $poolname = 'test_pool';
    my $lvname   = 'test_lv';

    my $threshold = get_lvm_conf($ip, "thin_pool_autoextend_threshold");
    my $percent   = get_lvm_conf($ip, "thin_pool_autoextend_percent");

    ok(1, "thin_pool_autoextend_threshold = $threshold");
    ok(1, "thin_pool_autoextend_percent = $percent");

    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR);

    my @prepare = (
        {
            msg      => "check disk exists or not",
            cmd      => "ls $diskname | wc -l",
            expected => "1",
        },
        {
            msg      => "destroy meta data section in disk",
            cmd      => "sgdisk -z $diskname &> /dev/null; echo \$?",
            expected => "0",
        },
        {
            msg => "make partition (2G)",
            cmd => "parted -a optimal $diskname mklabel gpt "
                . "unit MiB mkpart primary 0% 2048 &> /dev/null; echo \$?",
            expected => "0",
        },
        {
            msg      => "pvcreate $diskname" . "1",
            cmd      => "pvcreate $diskname" . "1 > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg => "vgcrate $vgname",
            cmd => "vgcreate $vgname $diskname"
                . "1 > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg => "lvcreate $vgname/$poolname 1G",
            cmd => "lvcreate --size 1G --type thin-pool "
                . "-n $poolname $vgname > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg => "lvcreate $vgname/$lvname 3G",
            cmd => "lvcreate -V 3G  --thinpool $vgname/$poolname "
                . " -n $lvname $vgname > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg => "mkfs.xfs -f /dev/$vgname/$lvname",
            cmd =>
                "mkfs.xfs -f /dev/$vgname/$lvname > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg      => "mkdir -p /mnt/$lvname",
            cmd      => "mkdir -p /mnt/$lvname > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg => "mount /dev/$vgname/$lvname /mnt/$lvname",
            cmd => "mount /dev/$vgname/$lvname "
                . "/mnt/$lvname > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg      => "check mount or not /mnt/$lvname",
            cmd      => "mount | grep  /mnt/$lvname | wc -l",
            expected => "1",
        },
    );

    for my $test (@prepare)
    {
        my ($got, undef) = $t->ssh_cmd(
            addr => $ip,
            cmd  => $test->{cmd},
        );

        is($got, $test->{expected}, $test->{msg});
    }

    my @event_test = (
        {
            msg => "dd to /mnt/$lvname/test.file.1 850MB",
            cmd => "dd if=/dev/zero of=/mnt/$lvname/test.file.1 "
                . "bs=1M count=850 > /dev/null  2>&1; echo \$?",
            expected => "0",
        },
        {
            msg => "dd to /mnt/$lvname/test.file.2 450MB",
            cmd => "dd if=/dev/zero of=/mnt/$lvname/test.file.2 "
                . "bs=1M count=450 > /dev/null  2>&1; echo \$?",
            expected => "0",
        },
    );

    my ($from, $to) = ($t->get_ts_from_server(), undef);

    for my $test (@event_test)
    {
        sleep 5;

        my ($got, undef) = $t->ssh_cmd(
            addr => $ip,
            cmd  => $test->{cmd},
        );

        is($got, $test->{expected}, $test->{msg});
    }

    sleep 60;

    $to = $t->get_ts_from_server();

    my $event_code = 'THIN_POOL_LV_EXTEND';

    $t->check_api_code_in_recent_events(
        category  => 'DEFAULT',
        prefix    => $event_code,
        from      => $from,
        to        => $to,
        level     => 'INFO',
        msg       => "$vgname/$poolname autoextending success.",
        skip_fail => 'false',
    );

    $t->check_api_code_in_recent_events(
        category  => 'DEFAULT',
        prefix    => $event_code,
        from      => $from,
        to        => $to,
        level     => 'ERROR',
        msg       => "$vgname/$poolname autoextending fail.",
        skip_fail => 'false',
    );

    my @cleanup = (
        {
            msg      => "umount /mnt/$lvname",
            cmd      => "umount /mnt/$lvname > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg => "lvremove -f $vgname/$poolname",
            cmd => "lvremove -f $vgname/$poolname > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg      => "vgremove -f $vgname",
            cmd      => "vgremove -f $vgname > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg => "pvremove -f $diskname",
            cmd => "pvremove -f $diskname" . "1 > /dev/null 2>&1; echo \$?",
            expected => "0",
        },
        {
            msg      => "destroy meta data section in disk",
            cmd      => "sgdisk -z $diskname &> /dev/null; echo \$?",
            expected => "0",
        },

    );

    for my $test (@cleanup)
    {
        my ($got, undef) = $t->ssh_cmd(
            addr => $ip,
            cmd  => $test->{cmd},
        );

        is($got, $test->{expected}, $test->{msg});
    }
};

done_testing();

sub get_lvm_conf_with_prefix
{
    my $ip     = shift;
    my $prefix = shift;

    my @cmd = ("cat", "/etc/lvm/lvm.conf", "|", "egrep", "'^\\s$prefix'",);

    my ($output, undef) = Test::AnyStor::Base::ssh_cmd(
        addr => $ip,
        cmd  => "@cmd",
    );

    return if (!defined $output);

    my @res = ();
    for my $line (split(/\n/, $output))
    {
        next if ($line eq "");

        my @tmp = split(/\s*=\s*/, $line);
        if (@tmp == 2)
        {
            push @res,
                {
                key => trim($tmp[0]),
                val => trim($tmp[1]),
                };
        }
    }

    return \@res;
}

sub get_lvm_conf
{
    my $ip  = shift;
    my $key = shift;

    my $res = get_lvm_conf_with_prefix($ip, $key);

    if (!defined $res || @{$res} == 0)
    {
        return;
    }

    return $res->[0]{val};
}

sub trim
{
    my $s = shift;
    $s =~ s/^\s+|\s+$|\n//g;
    return $s;
}
