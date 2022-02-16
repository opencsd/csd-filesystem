#!/usr/bin/perl -I /usr/gms/t/lib

use strict;
use warnings;
use utf8;

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'Cluster volume snapshot scheduling API test';

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Net::OpenSSH;
use DateTime;
use DateTime::TimeZone;

use Data::Dumper;

use Test::Most;
use Test::AnyStor::Schedule;
use Test::AnyStor::ClusterVolume;
use Test::AnyStor::Time;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $TEST_VOL = undef;

subtest 'Create test volume pool' => sub
{
    my $t   = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    my @tmp = $t->gethostnm(start_node => 0, cnt => scalar(@{$t->nodes}));

    my @nodeinfo = ();

    push(@nodeinfo, {Hostname => $_}) foreach (@tmp);

    $t->volume_pool_list(pool_name => 'vg_cluster');

    my $res = $t->volume_pool_create(
        pooltype => 'thin',
        basepool => 'vg_cluster',
        capacity => '10G',
        nodes    => \@nodeinfo,
    );

    if (!$res)
    {
        fail('Failed to create thin volume pool on vg_cluster');
    }
    else
    {
        ok(1, 'thin volume pool create');
    }
};

subtest 'Create cluster volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    $TEST_VOL = $t->volume_create(
        volpolicy  => 'Distributed',
        capacity   => '1.0G',
        replica    => 1,
        node_count => 1,
        start_node => 0,
        pool_name  => 'tp_cluster',
        provision  => 'thin',
    );

    if (!$TEST_VOL || $TEST_VOL eq '')
    {
        fail('create test volume');
    }
    else
    {
        ok(1, 'create test volume');
    }
};

subtest 'snapshot scheduling api test' => sub
{
    my $t  = Test::AnyStor::Schedule->new(addr => $GMS_TEST_ADDR);
    my $tz = DateTime::TimeZone->new(name => 'local')->name();
    my $dt = DateTime->now(time_zone => $tz);

    my %comm_args = (
        FS_Type           => 'glusterfs',
        Volume_Name       => $TEST_VOL,
        Sched_Times       => '01,02,03,22',
        Start_Date        => $dt->ymd('/'),
        End_Date          => '',
        Sched_Enabled     => 'true',
        Snapshot_Activate => 'false',
        Snapshot_Limit    => '1',
    );

    my %hourly_args = (
        Period_Unit => 'H',
        Sched_Name  => 'Hourly_Scheduling'
    );

    my %daily_args = (
        Period_Unit => 'D',
        Period      => '10',
        Sched_Name  => '10_Days_Scheduling'
    );

    my %weekly_args = (
        Period_Unit     => 'W',
        Period          => '10',
        Sched_Week_Days => 'SUN',
        Sched_Name      => 'Every_Sunday_Per_10_Weeks_Scheduling'
    );

    my %monthly_args = (
        Period_Unit     => 'M',
        Period          => '10',
        Sched_Week_Days => 'SUN',
        Sched_Weeks     => '1',
        Sched_Name      => 'Sunday_In_1st_Week_Per_10_Months_Scheduling'
    );

    my @args_list
        = (\%hourly_args, \%daily_args, \%weekly_args, \%monthly_args);

    for (my $i = 0; $i < @args_list; $i++)
    {
        my %curr_args = (%comm_args, %{$args_list[$i]});

        # scheduling create
        my $id = $t->sched_create(%curr_args);

        diag(explain($id));

        if (!$id || $id eq '')
        {
            fail('snapshot schedule create');
        }
        else
        {
            ok(1, 'snapshot schedule create');
        }

        sleep 5;

        # check scheduler create or not
        my $sched_list = $t->sched_list(FS_Type => 'glusterfs');

        if (ref($sched_list) ne 'ARRAY')
        {
            fail('snapshot schedule list');
        }
        else
        {
            ok(1, 'snapshot schedule list');
        }

        my $found = 0;

        for my $info (@{$sched_list})
        {
            if ($info->{Sched_ID} eq $id)
            {
                ok(1, 'snapshot schedule info founded');
                $found = 1;
                last;
            }
        }

        fail('snapshot schedule info founded') if (!$found);

        # scheduling config change
        my @verify_keys = ();

        my %change_args = %curr_args;

        delete($change_args{Volume_Name})
            if (exists($change_args{Volume_Name}));

        push(@verify_keys,
            qw/End_Date Sched_Enabled Snapshot_Activate Snapshot_Limit/);

        $change_args{End_Date}          = $dt->ymd('/');
        $change_args{Sched_Enabled}     = 'true';
        $change_args{Snapshot_Activate} = 'true';
        $change_args{Snapshot_Limit}    = '10';

        if (exists($change_args{Period}) && defined($change_args{Period}))
        {
            push(@verify_keys, qw/Period/);
            $change_args{Period} = 1;
        }

        if (exists($change_args{Sched_Times}))
        {
            push(@verify_keys, qw/Sched_Times/);
            $change_args{Sched_Times}
                = '00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23';
        }

        if (exists($change_args{Sched_Week_Days}))
        {
            push(@verify_keys, qw/Sched_Week_Days/);
            $change_args{Sched_Week_Days} = 'SUN,MON,TUE,WED,THU,FRI,SAT';
        }

        if (exists($change_args{Sched_Weeks}))
        {
            push(@verify_keys, qw/Sched_Weeks/);
            $change_args{Sched_Weeks} = '1,2,3,4,5,6';
        }

        $t->sched_change(Sched_ID => $id, %change_args);

        #check sched config change or not
        $sched_list = $t->sched_list(FS_Type => 'glusterfs');

        if (ref($sched_list) ne 'ARRAY')
        {
            fail('snapshot schedule list');
        }
        else
        {
            ok(1, 'snapshot schedule list');
        }

        my $sched = undef;

        for my $info (@{$sched_list})
        {
            if ($info->{Sched_ID} eq $id)
            {
                ok(1, 'snapshot schedule info founded');

                # verification of sched conf change
                foreach my $key (@verify_keys)
                {
                    if (defined($info->{$key})
                        && $info->{$key} eq $change_args{$key})
                    {
                        ok(
                            1,
                            "verify the changing of scheduling configuration($key)"
                        );
                    }
                    else
                    {
                        fail(
                            "verify the changing of scheduling configuration($key)"
                        );
                    }
                }

                $sched = $info;
                last;
            }
        }

        fail('snapshot schedule info founded') if (!$sched);
    }
};

subtest 'cleanup all snapshot scheduling' => sub
{
    my $t = Test::AnyStor::Schedule->new(addr => $GMS_TEST_ADDR);

    my $sched_list = $t->sched_list(FS_Type => 'glusterfs');

    if (ref($sched_list) ne 'ARRAY')
    {
        fail('snapshot schedule list');
    }
    else
    {
        ok(1, 'snapshot schedule list');
    }

    foreach my $info (@{$sched_list})
    {
        $t->sched_delete(
            FS_Type  => 'glusterfs',
            Sched_ID => $info->{Sched_ID}
        );
    }
};

subtest 'cleanup all snapshot' => sub
{
    my $t         = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    my $snap_info = $t->volume_snapshot_list(volname => $TEST_VOL);

    foreach my $info (@{$snap_info})
    {
        $t->volume_snapshot_delete(
            volname  => $TEST_VOL,
            snapname => $info->{Snapshot_Name}
        );
    }
};

my $curr_sched_list = [];

subtest 'prepare snapshot scheduling test' => sub
{
    my $t  = Test::AnyStor::Schedule->new(addr => $GMS_TEST_ADDR);
    my $tz = DateTime::TimeZone->new(name => 'local')->name();
    my $dt = DateTime->now(time_zone => $tz);

    my %common_args = (
        FS_Type     => 'glusterfs',
        Volume_Name => $TEST_VOL,
        Start_Date  => $dt->ymd('/'),
        Sched_Times =>
            '00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23',
        End_Date          => '',
        Sched_Enabled     => 'true',
        Snapshot_Activate => 'true',

        #Snapshot_Limit    => '1',
        Period_Unit => 'H',
    );

    my $req_args = [
        {
            Snapshot_Limit => 3,
            Sched_Name     => 'Hourly_Scheduling_1',
        },
        {
            Snapshot_Limit => 1,
            Sched_Name     => 'Hourly_Scheduling_2',
        }
    ];

    foreach my $req (@{$req_args})
    {
        map { $req->{$_} = $common_args{$_}; } keys(%common_args);

        my $id = $t->sched_create(%{$req});

        if (!defined($id) || $id eq '')
        {
            fail('snapshot schedule create');
        }
        else
        {
            ok(1, 'snapshot schedule create');
        }

        my $sched_list = $t->sched_list(FS_Type => 'glusterfs');

        if (ref($sched_list) ne 'ARRAY')
        {
            fail('snapshot schedule list');
            last;
        }

        diag(explain($sched_list));

        my $hit = 0;

        foreach my $sched_info (@{$sched_list})
        {
            if ($sched_info->{Sched_ID} eq $id
                && $sched_info->{Sched_Name} eq $req->{Sched_Name})
            {
                push(@{$curr_sched_list}, $sched_info);
                $hit = 1;
            }
        }

        if (!$hit)
        {
            fail("cannot found snapshot schedule: ${\Dumper($req)}");
        }
    }
};

my $timestamp = $curr_sched_list->[0]{Next_Sched};

subtest 'time config for snapshot scheduling - 1' => sub
{
    time_config_to_1hour_after();
};

subtest 'checking snapshot creation - 1' => sub
{
    snapshot_checking(
        [
            {sched_info => $curr_sched_list->[0], expected => 1},
            {sched_info => $curr_sched_list->[1], expected => 1},
        ]
    );
};

subtest 'time config for snapshot scheduling - 2' => sub
{
    time_config_to_1hour_after();
};

subtest 'checking snapshot creation - 2' => sub
{
    snapshot_checking(
        [
            {sched_info => $curr_sched_list->[0], expected => 2},
            {sched_info => $curr_sched_list->[1], expected => 1},
        ]
    );
};

subtest 'time config for snapshot scheduling - 3' => sub
{
    time_config_to_1hour_after();
};

subtest 'checking snapshot creation - 3' => sub
{
    snapshot_checking(
        [
            {sched_info => $curr_sched_list->[0], expected => 3},
            {sched_info => $curr_sched_list->[1], expected => 1},
        ]
    );
};

subtest 'time config for snapshot scheduling - 4' => sub
{
    time_config_to_1hour_after();
};

subtest 'checking snapshot creation - 4' => sub
{
    snapshot_checking(
        [
            {sched_info => $curr_sched_list->[0], expected => 3},
            {sched_info => $curr_sched_list->[1], expected => 1},
        ]
    );
};

subtest 'cleanup all snapshot scheduling' => sub
{
    my $t = Test::AnyStor::Schedule->new(addr => $GMS_TEST_ADDR);

    my $sched_list = $t->sched_list(FS_Type => 'glusterfs');

    if (ref($sched_list) ne 'ARRAY')
    {
        fail('snapshot schedule list');
    }
    else
    {
        ok(1, 'snapshot schedule list');
    }

    foreach my $info (@{$sched_list})
    {
        $t->sched_delete(
            FS_Type  => 'glusterfs',
            Sched_ID => $info->{Sched_ID}
        );
    }
};

subtest 'cleanup all snapshot' => sub
{
    my $t         = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);
    my $snap_info = $t->volume_snapshot_list(volname => $TEST_VOL);

    foreach my $info (@{$snap_info})
    {
        $t->volume_snapshot_delete(
            volname  => $TEST_VOL,
            snapname => $info->{Snapshot_Name}
        );
    }
};

subtest 'cleanup cluster volume' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $res = $t->volume_delete(volname => $TEST_VOL);
    is($res, 0, 'cluster volume delete');
};

subtest 'cleanup thin volume pool' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $res = $t->volume_pool_remove(pool_name => 'tp_cluster');

    ok(defined($res), 'cluster thin volume pool is removed');
};

sub time_config_to_1hour_after
{
    my $t = Test::AnyStor::Time->new(addr => $GMS_TEST_ADDR);

    my $tz = DateTime::TimeZone->new(name => 'local')->name();
    my $next_sched
        = DateTime->from_epoch(epoch => $timestamp, time_zone => $tz);

    $t->time_config(
        DateTime =>
            sprintf('%s %s', $next_sched->ymd('-'), $next_sched->hms()),
        NTP_Enabled => 'false'
    );

    $next_sched->add(hours => 1);
    $next_sched->truncate(to => 'hour');

    $timestamp = $next_sched->epoch();
}

sub snapshot_checking
{
    my $check_list = shift;

    my $t  = Test::AnyStor::Schedule->new(addr => $GMS_TEST_ADDR);
    my $tz = DateTime::TimeZone->new(name => 'local')->name();

    for (my $i = 0; $i < 10; $i++)
    {
        my $verification = @{$check_list};

        # waiting for Girasole schedule plugin running
        sleep 60;

        my $sched_list = $t->sched_list(FS_Type => 'glusterfs');

        if (ref($sched_list) ne 'ARRAY')
        {
            fail('snapshot schedule list');
            last;
        }

        ok(1, 'snapshot schedule list');

        foreach my $check (@{$check_list})
        {
            my @found
                = grep { $_->{Sched_ID} eq $check->{sched_info}->{Sched_ID} }
                @{$sched_list};

            if (!@found)
            {
                fail(
                    "Cannot found snapshot schedule: $check->{sched_info}->{Sched_Name}"
                );
                return;
            }

            if ($found[0]->{Snapshot_Count} eq $check->{expected})
            {
                my $prev_sched_status = $found[0]->{Prev_Sched_Status};
                my $prev_sched_time   = $found[0]->{Prev_Sched};

                next if ($prev_sched_time eq '');

                my $now = DateTime->now(time_zone => $tz)->epoch;

                if (int($now - $prev_sched_time) < 60 * 60)
                {
                    $verification--;
                    ok(1, "Snapshot schedule is work: ${\Dumper($found[0])}");
                }

                my $to   = $t->get_ts_from_server();
                my $from = int($to - 5 * 60);

                $t->check_api_code_in_recent_events(
                    from   => $from,
                    to     => $to,
                    prefix => 'SNAPSHOT_SCHEDULE',
                    level  => ($prev_sched_status eq 'OK') ? 'INFO' : 'ERR',
                );
            }
        }

        if ($verification)
        {
            ok(
                1,
                sprintf("Waiting for snapshot scheduling ... (%s/10 mins)",
                    $i + 1)
            );
            next;
        }

        last;
    }
}

done_testing();

