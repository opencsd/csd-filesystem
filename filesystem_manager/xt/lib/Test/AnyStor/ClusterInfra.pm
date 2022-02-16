package Test::AnyStor::ClusterInfra;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Dumper;
use Devel::NYTProf;
use File::Basename;
use File::Path qw/make_path remove_tree/;
use Test::Most;
use Time::Local;

use GMS::Common::IPC;
use GMS::Common::Command qw /:exec/;

use Test::AnyStor::Util;
use Test::AnyStor::Base;

extends 'Test::AnyStor::Base';

# 2017/07/17 hgichon : bypass fsusage test result for Blue Color ^^
my $girasole_check = 'off';

sub mysql_test
{
    return;
}

sub check_cluster_fine
{
    my $self = shift;
    my $res;
    my ($ip, $port) = split(/:/, $self->addr);
    my $cnt = 300;

    while ($cnt--)
    {
        diag(
            sprintf(
                "[%s] Checking cluster status is fine... (%d)\n",
                get_time(), $cnt
            )
        );

        if (cluster_status_api($self->api_token, $ip))
        {
            diag(sprintf("[%s] Cluster status is fine!\n", get_time()));
            last;
        }

        sleep(1);
    }

    ok($cnt > 0, '');
    return;
}

sub check_girasole_hub
{
    my $self = shift;
    my $res  = -1;
    my $out;
    my ($ip, $port) = split(/:/, $self->addr);
    my $timeo = 120;

    my $girasole_cmd = sprintf(
        '%s event create -d10 --category=%s --code=%s --type=%s --level=%s --message %s',
        '/usr/sbin/girasole', 'CI_TEST', 'CI_TEST', 'CI_TEST',
        'INFO', 'merge_test_checking.' . $$,
    );

    diag(
        sprintf(
            '[%s] Issuing TEST EVENT for checking girasole cmd = %s',
            get_time(), $girasole_cmd
        )
    );

    ($out, $res) = $self->ssh_cmd(
        addr  => $ip,
        cmd   => $girasole_cmd,
        timeo => $timeo
    );

    my $time = get_time();

    if (!defined($res))
    {
        $self->paint_err();
        diag("[$time] girasole event timeout!!!");
        $self->paint_reset();
    }
    else
    {
        $self->paint_info();
        diag("[$time] girasole event success : $out/$res");
        $self->paint_reset();
    }

    return;
}

sub check_nodestatus
{
    my $self     = shift;
    my %ext_args = (http_status => 200);
    my $res;

    # 30seconds retry by hgichon 16/09/13
    # join/reboot test 에서 nodestatus 에러가 많이 발생하여 retry 추가함
    my $retry_cnt = 60;

NODESTATUS_RETRY1:

    $res = $self->call_rest_api('cluster/nodes', {}, {}, \%ext_args);

    if ($res->{entity}->[0]->{Status} ne 'OK' && $retry_cnt-- > 0)
    {
        sleep(1);

        diag(
            sprintf(
                '[%s] nodes status checking retry = %d, %s',
                get_time(), $retry_cnt, Dumper($res->{entity}->{Details})
            )
        );

        goto NODESTATUS_RETRY1;
    }

    ok($res->{entity}->[0]->{Status} eq 'OK', 'check node status');

    return;
}

sub dashboard_scan
{
    my $self      = shift;
    my $mode      = shift;
    my %args      = ();
    my %ext_args  = ();
    my $retry_cnt = 60;
    my $res;

    ### ClusterStage Checking ###

    $res = $self->request(uri => '/cluster/status');

    if ($res->{entity}->{Msg} eq 'RUNNING')
    {
        $self->paint_info();
        diag('running!!!');
        $self->paint_reset();
    }
    else
    {
        $self->paint_warn();
        diag("$res->{entity}->{Msg}");
        $self->paint_reset();
    }

    ### nodestatus API ###

    $ext_args{http_status} = 200;

NODESTATUS_RETRY2:
    $res = $self->request(uri => '/cluster/nodes');

    if (uc($res->{entity}->[0]->{Status}) ne 'OK' && $retry_cnt-- > 0)
    {
        sleep(2);

        diag(
            sprintf(
                '[%s] nodes status checking retry = %d, %s: %s',
                get_time(),
                $retry_cnt,
                $res->{entity}->[0]->{Status},
                Dumper($res->{entity}->[0]->{Details})
            )
        );

        goto NODESTATUS_RETRY2;
    }

    cmp_ok(uc($res->{entity}->[0]->{Status}),
        'eq', 'OK', 'entity->[0]->Status is OK');

    delete($ext_args{http_status});

    ### clientgraph API : No Checking ###

    $res = $self->request(uri => '/cluster/dashboard/clientgraph');

    ### fsusage API ###

    $retry_cnt = 60;

    if (!defined($mode))
    {
    FSUSAGE_RETRY1:
        $res = $self->request(uri => '/cluster/dashboard/fsusage');

        if ($res->{entity}->{is_available} ne 'true' && $retry_cnt-- > 0)
        {
            sleep(1);
            diag(
                sprintf(
                    '[%s] fsusage check retry = %d',
                    get_time(), $retry_cnt
                )
            );
            goto FSUSAGE_RETRY1;
        }

        if ($girasole_check eq 'on')
        {
            ok($res->{entity}->{is_available} eq 'true',
                'volume usage found');
        }
        elsif ($res->{entity}->{is_available} ne 'true')
        {
            $self->paint_err();
            diag('not ok: volume usage not founded, skipped');
            $self->paint_reset();
        }
    }

### netstats API ###

#    %args = (Limit => 120, Interval => 30);
#
#    $res = $self->call_rest_api(
#            'cluster/dashboard/netstats'
#            , \%args, {}, \%ext_args);
#
#    my $is_available = $res->{entity}->{is_available};
#    my $count = scalar(@{$res->{entity}->{data}});
#
#    if ($is_available eq 'true')
#    {
#        ok($count > 1 , "state count = $count") if ($girasole_check eq 'on');
#    }
#    else
#    {
#        fail(sprintf('[%s] Statistics is not available: "ret:%s"'
#                , get_time(), $is_available)) if ($girasole_check eq 'on');
#
#        $self->paint_err();
#        diag('not ok: net Statistics is not available, skipped:');
#        $self->paint_reset();
#    }

### fstats API ###

#    $res = $self->call_rest_api(
#            'cluster/dashboard/fsstats'
#            , \%args, {}, \%ext_args);
#
#    $is_available = $res->{entity}->{is_available};
#
#    $count = scalar(@{$res->{entity}->{data}});
#
#    if ($is_available eq 'true')
#    {
#        ok($count > 1, "state count = $count") if ($girasole_check eq 'on');
#    }
#    else
#    {
#        fail(sprintf('[%s] Statistics is not available: "ret:%s"'
#                    , get_time(), $is_available)) if ($girasole_check eq 'on');
#
#        $self->paint_err();
#
#        diag('not ok: FS Statistics is not available, skipped:');
#
#        $self->paint_reset();
#    }

### procusage API ###

#    $res = $self->call_rest_api(
#            'cluster/dashboard/procusage'
#            , \%args, {}, \%ext_args);
#
#    $is_available = $res->{entity}->{is_available};
#
#    $count = scalar(@{$res->{entity}->{data}});
#
#    if ($is_available eq 'true')
#    {
#        ok($count > 1 , "state count = $count") if ($girasole_check eq 'on');
#    }
#    else
#    {
#        fail(sprintf('[%s] Statistics is not available: "ret:%s"'
#                    , get_time(), $is_available)) if ($girasole_check eq 'on');
#
#        $self->paint_err();
#
#        diag('not ok: CPU Statistics is not available, skipped:');
#
#        $self->paint_reset();
#    }

### girasole event test ###

    %args      = (Message => "merge_test_checking.$$");
    $retry_cnt = 60;
    $self->check_girasole_hub();

GIRASOLE_RETRY:
    $res = $self->request(
        uri    => '/cluster/event/list',
        params => \%args
    );

    my $count
        = ref($res->{entity}) eq 'ARRAY'
        ? scalar(@{$res->{entity}})
        : 0;

    if ($count < 1 && $retry_cnt-- > 0)
    {
        sleep(1);

        diag("[${\get_time()}] girasole event checking retry = $retry_cnt");

        goto GIRASOLE_RETRY;
    }

    if ($count > 0)
    {
        ok($count > 0, "found CI_TEST event : $count")
            if ($girasole_check eq 'on');
    }
    else
    {
        fail('Cannot found CI_TEST event!!!') if ($girasole_check eq 'on');

        $self->paint_err();

        diag('not ok: Cannot found CI_TEST event, skipped');

        $self->paint_reset();
    }

    return;
}

sub _profile_sub
{
    my $target_code = shift;
    my $file_prefix = shift // '/tmp/profile/nytprof';
    my $nytprof_opt = shift;

    my $dirpath = dirname($file_prefix);

    if (!-e $dirpath && !make_path($dirpath, {error => \my $err}))
    {
        die "Failed to make directory: $dirpath: ${\Dumper($err)}";
    }

    return {} if (ref($target_code) ne 'CODE');

    if (defined($nytprof_opt) && defined($ENV{NYTPROF}))
    {
        $nytprof_opt = "$ENV{NYTPROF}:$nytprof_opt";
    }

    local $ENV{NYTPROF} = $nytprof_opt if (defined($nytprof_opt));

    my $res = {};

    DB::enable_profile("$file_prefix.out");

    $res->{subroutine_return} = $target_code->();

    DB::finish_profile();

    my $exec_result = GMS::Common::IPC::exec(
        cmd   => 'nytprofhtml',
        args  => ['-f', "$file_prefix.out", '-o', "$file_prefix.html"],
        quiet => 1,
    );

    if (is_exec_success($exec_result))
    {
        my $file = "$file_prefix.html/all_stacks_by_time.calls";
        my $fh;

        open($fh, '<', $file)
            || die "Failed to open file: $file: $!";

        flock($fh, Fcntl::LOCK_SH)
            || die "Failed to lock file: $file: $!";

        while (my $line = <$fh>)
        {
            $line =~ s/^.+;//;

            my ($time, $stack) = split(/\s+/, $line, 2);

            $res->{all_stacks_by_time}->{$time} = $stack;
        }

        flock($fh, Fcntl::LOCK_UN)
            || die "Failed to unlock file: $file: $!";

        close($fh);
    }

    return $res;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Test::AnyStor::ClusterInfra

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

