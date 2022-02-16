#!/usr/bin/perl

use v5.14;

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/\/[^\/]+$//;

    unshift(@INC,
        (map { "$ROOTDIR/$_"; } qw/libgms lib/),
        '/usr/girasole/lib');
}

use Getopt::Long;
use Time::HiRes qw/time usleep/;
use Data::Dumper;

use constant {
    SUC               => 'Success',
    FAIL_PROC_STAT    => 'Process status is abnormal',
    FAIL_MERGE_TEST   => 'Merge test failed',
    FAIL_GLSTVOL_STAT => 'Cluster volume(glusterFS) status is abnormal',
};

my $gmsroot = '/usr/gms';
my $logfh   = undef;
my $logfile = undef;

my @ps_chk_list = (
    '/usr/gms/script/gms',
    '/usr/sbin/girasole-hub',
    '/usr/sbin/girasole-notifier',
    '/usr/sbin/girasole-publisher',
    '/usr/sbin/ctdbd',
    '/usr/sbin/glusterd',
    '/usr/sbin/glusterfsd',
    '/usr/sbin/glusterfs',
    '/usr/bin/mysqld_safe',
    '/usr/sbin/mysqld',
    '/sbin/rsyslogd',
    '/usr/gms/script/noti_supervisord.py',
    '/usr/gms/misc/mntgluster/bg-mntgluster',
    '/usr/sbin/lighttpd',
    '/usr/bin/php-cgi',
);

exit main();

sub main
{
    GetOptions(
        'h'         => \&help,
        'logfile=s' => \$logfile
    );

    help() if (!$logfile);

    open($logfh, '>', $logfile)
        || die "Failed to open : $logfile: $!";

    my $ret    = SUC;
    my $btime  = boottime();
    my $host   = hostname();
    my $mgmtip = mgmtip();

    print $logfh "gmsroot $gmsroot\n";
    print $logfh "[Node Informations]\n";
    print $logfh "managment IP: $mgmtip\n";
    print $logfh "hostname: $host\n";
    print $logfh sprintf("current time: %s\n", gettime(time()));
    print $logfh "boot time: $btime\n";
    print $logfh "\n[Process Informations]\n";

    for my $pcmd (@ps_chk_list)
    {
        my ($pcnt, $etime) = procstat($pcmd);

        print $logfh sprintf('%-45s',              $pcmd);
        print $logfh sprintf('%-15s',              "count: " . $pcnt);
        print $logfh sprintf("running time: %s\n", $etime ? $etime : "None");
    }

    print $logfh "\n";

    if (glstvolstat())
    {
        $ret = FAIL_GLSTVOL_STAT;
        goto RET;
    }

#    if (merge_test())
#    {
#        $ret = FAIL_MERGE_TEST;
#        goto RET;
#    }

RET:
    close($logfh) if ($logfh);

    warn "$ret\n";

    return -1 if ($ret ne SUC);

    return 0;
}

sub hostname
{
    my $host = undef;
    $host = `hostname`;
    chomp($host);
    return $host;
}

sub mgmtip
{
    my $ip = undef;
    $ip
        = `ifconfig eth0 | grep -w 'inet addr' | awk -F':' '{print \$2}' | awk '{print \$1}'`;
    chomp($ip);
    return $ip;
}

sub boottime
{
    my $uptime = `cat /proc/uptime | awk \'{print \$1}\'`;
    my $btime  = time() - int $uptime;
    $btime = gettime($btime);
    return $btime;
}

sub gettime
{
    my $time = shift;
    my ($S, $M, $H, $d, $m, $Y) = localtime($time);

    $m += 1;
    $Y += 1900;

    return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $Y, $m, $d, $H, $M, $S);
}

sub procstat
{
    my $proc = shift;
    my $plist_cmd
        = sprintf('ps -eo etime,pid,cmd | grep -w %s | grep -v grep | sort',
        $proc);
    my $pcnt_cmd = sprintf('%s | wc -l', $plist_cmd);
    my $petime_cmd
        = sprintf("%s | awk \'{print \$1}\' | head -1", $plist_cmd);

    my $ps_cnt = `$pcnt_cmd`;
    my $etime  = `$petime_cmd`;

    chomp($ps_cnt);
    chomp($etime);

    return $ps_cnt, $etime;
}

sub merge_test
{
    my $merge_t
        = sprintf(
        "perl %s $gmsroot/t/merge_test.t 127.0.0.1:80 >> $logfile 2>&1",
        map { "-I$_"; } @INC);

    my $testlog = `$merge_t`;

    if ($? == -1)
    {
        print $logfh "Failed to execute: 'merge_test.t'\n\n";
        return 1;
    }
    elsif ($? >> 8)
    {
        print $logfh
            sprintf("Test 'merge_test.t' failed with status '%d'\n\n",
            $? >> 8);
        return -1;
    }

    print $logfh "$testlog\n";
    print $logfh "Test 'merge_test.t' is succeed\n\n";

    return 0;
}

sub glstvolstat
{
    # TODO: self all gluster volume check
    return 0;
}

sub help
{
    warn "help\n";
    exit 1;
}

