#!/usr/bin/perl -I /usr/gms/t/lib

use strict;
use warnings;
use utf8;

our $AUTHORITY        = 'Hyochan Lee';
our $VERSION          = '1.00';
our $TEST_DESCRIPTOIN = '클러스터 시간 설정 테스트 코드';

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname(rel2abs(__FILE__));
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Data::Dumper;

use Test::Most;
use Test::AnyStor::ClusterCTDB;
use Test::AnyStor::Time;
use Test::AnyStor::Base;
use Test::AnyStor::ClusterPower;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

subtest 'datetime config test' => sub
{
    my $t = Test::AnyStor::Time->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt = scalar(@{$t->nodes});

    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
        = localtime(time + 1200);

    $year += 1900;
    $mon  += 1;

    my $test_date = sprintf(
        '%.4d-%.2d-%.2d %.2d:%.2d:%.2d',
        $year,
        $mon,
        $mday,
        $hour,
        $min,
        $sec
    );
    my $cmp_date = sprintf('%.4d-%.2d-%.2d %.2d:', $year, $mon, $mday, $hour);

    my $ret = $t->time_config(DateTime => $test_date, NTP_Enabled => 'false');

    sleep 10;

    my $to   = $t->get_ts_from_server();
    my $from = ($to - 60) < 0 ? 0 : $to - 60;

    # is event up
    $t->_wait_event();
    $t->check_api_code_in_recent_events(
        category => 'SYSTEM',
        prefix   => 'TIME_CONFIG_',
        from     => $from,
        to       => $to,
        status   => $ret,
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    sleep 1;

    my $res = $t->time_info();

    if (!$res || !exists($res->{DateTime}) || !defined($res->{DateTime}))
    {
        fail('Getting current time info is failed');
        goto TESTEND;
    }

    my $config_date = $res->{DateTime};

    if (!(defined($config_date) || $config_date =~ /$cmp_date/))
    {
        fail('datetime config failed');

        print "datetime to config : $test_date\n";
        print Dumper $res;

        goto TESTEND;
    }

    for my $node (@node_list_mgmtip)
    {
        ($res, undef) = $t->ssh_cmd(
            addr => $node,
            cmd  => 'date +"%Y-%m-%d %H:%M:%S"'
        );

        if (!$res)
        {
            fail("Getting datetime on $node is failed");
            goto TESTEND;
        }

        if (!(defined($res) || $res =~ /$cmp_date/))
        {
            fail("Verify the datetime on $node");
            print Dumper $res;
            goto TESTEND;
        }

        ok(1, "Verify the datetime on $node");
    }

    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
        = localtime(time());

    $year += 1900;
    $mon  += 1;

    my $curr_date = sprintf(
        '%.4d-%.2d-%.2d %.2d:%.2d:%.2d',
        $year,
        $mon,
        $mday,
        $hour,
        $min,
        $sec
    );

    $t->time_config(DateTime => $curr_date, NTP_Enabled => 'false');

    sleep 10;

    subtest 'Restore time' => sub
    {
        my $st = Test::AnyStor::Time->new(
            addr      => $GMS_TEST_ADDR,
            no_logout => 1
        );

        $to   = $t->get_ts_from_server();
        $from = ($to - 60) < 0 ? 0 : $to - 60;

        # is event up
        $t->_wait_event();
        $t->check_api_code_in_recent_events(
            category => 'SYSTEM',
            prefix   => 'TIME_CONFIG_',
            from     => $from,
            to       => $to,
            status   => $ret,
            ok       => ['OK'],
            failure  => ['FAILURE'],
        );
    };

    sleep 1;

TESTEND:
};

subtest 'timezone config test' => sub
{
    my $t = Test::AnyStor::Time->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt = scalar(@{$t->nodes});

    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);

    my $test_timezone = 'Asia/Pyongyang';

    my $ret = $t->time_config(TimeZone => $test_timezone);

    sleep 10;

    # is event up
    my $to   = $t->get_ts_from_server();
    my $from = ($to - 60) < 0 ? 0 : $to - 60;

    # is event up
    $t->_wait_event();
    $t->check_api_code_in_recent_events(
        category => 'SYSTEM',
        prefix   => 'TIME_CONFIG_',
        from     => $from,
        to       => $to,
        status   => $ret,
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    sleep 1;

    my $res = $t->time_info();

    if (!$res || !exists($res->{TimeZone}) || !defined($res->{TimeZone}))
    {
        fail('Getting current time info is failed');
        goto TESTEND;
    }

    is($res->{TimeZone}, $test_timezone, 'Time zone config done');

    if ($res->{TimeZone} ne $test_timezone)
    {
        fail("timezone config failed");
        print Dumper $res;
        goto TESTEND;
    }

    my $test_timezone_md5
        = `md5sum /usr/share/zoneinfo/$test_timezone | awk \'{print \$1}\'`;

    chomp($test_timezone_md5);

    print Dumper $test_timezone_md5;

    if (!$test_timezone_md5)
    {
        fail(
            "Getting md5hash of /usr/share/zoneinfo/$test_timezone to verify is failed"
        );
        goto TESTEND;
    }

    for my $node (@node_list_mgmtip)
    {
        ($res, undef) = $t->ssh_cmd(
            addr => $node,
            cmd  => "md5sum /etc/localtime | awk '{print \$1}'"
        );

        print Dumper $res;

        if (!$res)
        {
            fail(
                "Getting md5hash of /etc/localtime to verify on $node is failed"
            );
            goto TESTEND;
        }

        cmp_ok($res, '==', $test_timezone_md5,
            "verify the /etc/localtime is changed $test_timezone, $node");
    }

    $ret = $t->time_config(TimeZone => 'Asia/Seoul');

    sleep 10;

    subtest 'Restore timezone' => sub
    {
        my $st = Test::AnyStor::Time->new(
            addr      => $GMS_TEST_ADDR,
            no_logout => 1
        );

        $to   = $st->get_ts_from_server();
        $from = ($to - 60) < 0 ? 0 : $to - 60;

        # is event up
        $st->_wait_event();

        $st->check_api_code_in_recent_events(
            category => 'SYSTEM',
            prefix   => 'TIME_CONFIG_',
            from     => $from,
            to       => $to,
            status   => $ret,
            ok       => ['OK'],
            failure  => ['FAILURE'],
        );
    };

    sleep 1;
TESTEND:
};

subtest 'ntp server config test' => sub
{
    my $t = Test::AnyStor::Time->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    my $node_cnt         = scalar(@{$t->nodes});
    my @node_list_hostnm = $t->gethostnm(start_node => 0, cnt => $node_cnt);
    my @node_list_mgmtip = $t->hostnm2mgmtip(hostnms => \@node_list_hostnm);

    my $res = $t->time_info();

    if (!$res
        || !exists($res->{NTP_Servers})
        || !defined($res->{NTP_Servers}))
    {
        fail('Getting current time info is failed');
        goto TESTEND;
    }

    my $test_ntpsvrs = ['0.test.ntp.svr', '1.test.ntp.svr'];
    my @prev_ntpsvrs = split(',', $res->{NTP_Servers});

    print "Trying to config ntp servers @$test_ntpsvrs\n";

    my $ret = $t->time_config(
        NTP_Servers => $test_ntpsvrs,
        NTP_Enabled => 'true'
    );

    my $to   = $t->get_ts_from_server();
    my $from = ($to - 60) < 0 ? 0 : $to - 60;

    # is event up
    $t->_wait_event();
    $t->check_api_code_in_recent_events(
        category => 'SYSTEM',
        prefix   => 'TIME_CONFIG_',
        from     => $from,
        to       => $to,
        status   => $ret,
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    sleep 1;

    $res = $t->time_info();

    if (!$res
        || !exists($res->{NTP_Servers})
        || !defined($res->{NTP_Servers}))
    {
        fail('Getting current time info is failed');
        goto TESTEND;
    }

    my @tmp = split(',', $res->{NTP_Servers});

    if (@tmp != @$test_ntpsvrs)
    {
        fail('verify the set ntp servers');
        print Dumper($res);
        goto TESTEND;
    }
    else
    {
        ok(1, 'verify the set ntp servers');
    }

    my $ntp_master        = $res->{NTP_Master};
    my $ntp_master_ip     = '';
    my $ntp_master_stg_ip = '';

    for my $node (@{$t->nodes})
    {
        if ($node->{Mgmt_Hostname} eq $ntp_master)
        {
            $ntp_master_ip     = $node->{Mgmt_IP}->{ip};
            $ntp_master_stg_ip = $node->{Storage_IP};
            last;
        }
    }

    if ($ntp_master_ip eq '')
    {
        fail('get ntp master mgmt IP');
        goto TESTEND;
    }

    my ($conf, undef) = $t->ssh_cmd(
        addr => $ntp_master_ip,
        cmd  => "cat /etc/ntp.conf"
    );

    if (!$conf)
    {
        fail("read ntp.conf is failed (ntp master)");
        goto TESTEND;
    }

    @tmp = split("\n", $conf);

    my $hit = 0;

    for my $line (@tmp)
    {
        if ($line =~ /^server (?<server>.+) iburst/)
        {
            for my $svr (@$test_ntpsvrs)
            {
                $hit++ if ($svr eq $+{server});
            }
        }
    }

    if ($hit != @$test_ntpsvrs)
    {
        fail('verify the set ntp servers with ntp.conf(ntp master)');
        goto TESTEND;
    }

    ok(1, 'verify the set ntp servers with ntp.conf(ntp master)');

    $ret = $t->time_config(
        NTP_Servers => \@prev_ntpsvrs,
        NTP_Enabled => 'true'
    );

    $to   = $t->get_ts_from_server();
    $from = ($to - 60) < 0 ? 0 : $to - 60;

    # is event up
    $t->_wait_event();

    $t->check_api_code_in_recent_events(
        category => 'SYSTEM',
        prefix   => 'TIME_CONFIG_',
        from     => $from,
        to       => $to,
        status   => $ret,
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    sleep 1;
TESTEND:
};

subtest 'NTP master fail-over test' => sub
{
    my $t = Test::AnyStor::Time->new(addr => $GMS_TEST_ADDR, no_logout => 1);

    if (@{$t->nodes} == 1)
    {
        ok(1, 'node count is 1, nothing to do');
        return 0;
    }

    foreach my $node (@{$t->nodes})
    {
        # get ntp master's hostname
        my $ti     = $t->time_info();
        my $master = $ti->{NTP_Master} // '';

        print Dumper($ti);

        return -1
            if (!cmp_ok(
            $master, 'ne', '', "Current master NTP server: $master"));

        my @master_info
            = grep { $_->{Mgmt_Hostname} eq $master } @{$t->nodes};
        my $master_ip = $master_info[0]->{Mgmt_IP}->{ip};

        # To check the power status
        my $ts = Test::AnyStor::ClusterPower->new(addr => "$master_ip:80");
        my @mgmt_ip = $ts->mgmtip_list('ARR');

        my %uptime = $ts->get_uptime($master_ip);

        return -1
            if (!cmp_ok(
            scalar(keys(%uptime)),
            '>', 0, "get_uptime(): ${\Dumper(\%uptime)}"
            ));

        # reboot ntp master
        my $ssh_cmd
            = "ssh root\@$master_ip \"nohup sh -c 'sleep 5; reboot' &\"";

        system($ssh_cmd);

        if ($? == -1)
        {
            fail(sprintf('Failed to execute: %s', $ssh_cmd));
            return -1;
        }
        elsif ($? >> 8)
        {
            fail(
                sprintf(
                    "Command %s exited with the status '%d'",
                    $ssh_cmd, $? >> 8
                )
            );
            return -1;
        }

        ok(1, $ssh_cmd);

        # compare uptime
        cmp_ok($ts->cmp_uptime(300, $master_ip, %uptime),
            '==', 0, 'Reboot check');

        my $cnt = 500;
        my $try = {wait => $cnt};

        cmp_ok($ts->rest_check(\@mgmt_ip, $try),
            '==', 0, 'Reboot checking has succeeded');

        ok(is_sync(@mgmt_ip), 'Time sync verification');

        last
            if (verify_ntp_failover(
            prev_master => $master,
            nodelist    => $ts->nodes
            ));
    }

    return 0;
};

# resolve ctdb timezone problem?
subtest 'reload ctdb' => sub
{
    my $t = Test::AnyStor::ClusterCTDB->new(addr => $GMS_TEST_ADDR);

    $t->cluster_ctdb_control(command => 'reload');
};

#---------------------------------------------------------------------------------
# local func
#---------------------------------------------------------------------------------
sub verify_ntp_failover
{
    my %args        = @_;
    my $nodelist    = $args{nodelist};
    my $prev_master = $args{prev_master};

    paint_info();
    diag(
        sprintf(
            'NTP Fail-over verification: Prev-master is %s', $prev_master
        )
    );
    paint_reset();

    my $t  = Test::AnyStor::Time->new(addr => $GMS_TEST_ADDR, no_logout => 1);
    my $ti = $t->time_info();

    my $ntp_master = $ti->{NTP_Master} // '';

    paint_info();
    diag(
        sprintf("NTP Fail-over verification: Current master is %s",
            $ntp_master)
    );
    paint_reset();

    if ($ntp_master eq '')
    {
        fail('Failed to get current NTP master');
        last;
    }

    for my $node (@{$nodelist})
    {
        my $tmp = $t->time_info()->{NTP_Master};

        if (!$tmp)
        {
            fail('Failed to get current NTP master node');
            return -1;
        }

        $ntp_master = $tmp;

        print "Node       : $node->{Mgmt_Hostname}\n";
        print "NTP master : $ntp_master\n";

        my ($res, $err) = $t->ssh_cmd(
            addr => $node->{Mgmt_IP}->{ip},
            cmd  => 'ntpq -p'
        );

        if ($err || !$res || $res eq '')
        {
            fail('Failed to get NTP remote status');
            return -1;
        }

        print Dumper($res);

        my @ntp_remote = split(/\n+/, $res);

        if ($node->{Mgmt_Hostname} eq $ntp_master)
        {
            if (
                !cmp_ok(@ntp_remote, '>', 2,
                    'SSH command result contains more than three headers')
                && !cmp_ok(
                    scalar(grep { $_ =~ /LOCAL/ } @ntp_remote),
                    '==', 0,
                    'SSH command result does not contain local time server'
                )
                )
            {
                fail(
                    "ntpd of the NTP master is not working (master: $ntp_master)"
                );
                return -1;
            }

            ok(1, "NTP master($ntp_master) is ok");
        }
        else
        {
            my $hit = grep { $_ =~ /$ntp_master/ } @ntp_remote;

            if (!cmp_ok(
                $hit, '>', 0,
                "$node->{Mgmt_Hostname} is synced with NTP master"
            ))
            {
                return -1;
            }

            ok(1, "NTP slave($node->{Mgmt_Hostname}) is ok");
        }
    }

    ok(1, 'NTP Fail-over is verified');

    return 0;
}

sub is_sync
{
    my @mgmt_ip = @_;
    my $try     = 100;

    my $pre_clk = undef;
    my $cnt     = 0;

    print "Waiting the clock sync...\n";

    for (my $i = 0; $i <= $try; $i++)
    {
        print "Clock check ($i/$try)\n";

        foreach my $ip (@mgmt_ip)
        {
            my $nxt_clk = `ssh root\@$ip date +%k%M`;

            print "IP: $ip, Clock: $nxt_clk \n";

            if (!defined($pre_clk))
            {
                $pre_clk = $nxt_clk;

            }
            elsif ($pre_clk == $nxt_clk)
            {
                $cnt++;
            }
        }

        if ($cnt == $#mgmt_ip)
        {
            print "It's same\n";
            return 1;
        }

        $cnt     = 0;
        $pre_clk = undef;

        sleep 20;
    }

    print "It's not same\n";

    return 0;
}

done_testing();
