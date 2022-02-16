package Test::AnyStor::Stage;

use v5.14;

use Mouse;
use namespace::clean -except => 'meta';
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Data::Dumper;

use Test::Most;
use Mojo::UserAgent;
use JSON;
use Try::Tiny;
use POSIX qw/:sys_wait_h/;
use IO::Handle;
use IO::Pipe;

use Test::AnyStor::Measure;
use Test::AnyStor::Util;

extends 'Test::AnyStor::Base';

our @EXPORT = qw/rest_check/;

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub cluster_stage_set
{
    my $self = shift;
    my %args = @_;

    return $self->request(
        uri    => 'cluster/stage/set',
        params => {
            Stage => $args{stage},
            Scope => $args{scope},
            Data  => $args{data} // '',
        },
    );
}

sub cluster_stage_get
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => 'cluster/stage/get',
        params => {Scope => $args{scope}},
    );

    my $entity = $res->{entity};

    ok(defined($entity->{stage}),
        'Cluster Stage: ' . ($entity->{stage} // 'undef'));

    return $res;
}

sub cluster_stage_list
{
    my $self = shift;
    my %args = @_;

    return $self->call_rest_api(
        uri    => 'cluster/stage/list',
        params => {Scope => $args{scope}},
    );
}

sub cluster_stage_info
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => 'cluster/stage/info');

    my $entity = $res->{entity};

    ok(defined($entity->{Name}),  'entity->Name is defined');
    ok(defined($entity->{Stage}), 'entity->Stage is defined');
    ok(
        defined($entity->{Total_Capacity}),
        'entity->Total_Capacity is defined'
    );
    ok(
        defined($entity->{Usage_Capacity}),
        'entity->Usage_Capacity is defined'
    );

    cmp_ok(ref($entity->{Management}),
        'eq', 'ARRAY', 'entity->Management isa ARRAY');

    my $stage_info = $res->{stage_info};

    ok(defined($stage_info->{stage}), 'stage_info->stage is defined');
    ok(defined($stage_info->{data}),  'stage_info->data is defined');

    return $res;
}

#-------------------------------------------------------------------------------
# Parallel API tester for stage test
#-------------------------------------------------------------------------------
sub cluster_stage_test
{
    my $self      = shift;
    my $expected  = shift;
    my $try_max   = shift // 300;
    my $test_type = shift // 'AFTER-INIT';
    my $interval  = shift // 5;
    my $t_started = get_time();

    # Check sequence for stage
    my @expected = ();

    given (uc($expected))
    {
        when ('CONFIG')
        {
            @expected = ('installed', 'configured');
        }
        when ('INIT')
        {
            @expected = ('configured', 'initializing', 'running');
        }
        when ('EXPAND')
        {
            @expected = ('running', 'expanding', 'running');
        }
        when ('SUPPORT')
        {
            @expected = ('support');
        }
        when ('RUNNING')
        {
            @expected = ('running');
        }
        default
        {
            warn "[ERR] Test stage is not defined: $expected";
            return 1;
        }
    }

    # Prepare Asyncjob
    my $job;

    if (uc($test_type) eq 'AFTER-INIT')
    {
        $job = Asyncjob->new(
            obj     => $self,
            func    => \&after_init_stage_t,
            timeout => 5,
        );
    }
    else
    {
        $job = Asyncjob->new(
            obj     => $self,
            func    => \&before_init_stage_t,
            timeout => 5,
        );
    }

    my $ctl        = Asyncctl->new(trigger_term => 2);
    my $prev_stage = 'start';
    my @changes    = ();

    my $try      = 0;
    my $tmp_res  = 1;
    my $test_res = 1;
    my $date;

    my $fatal_cnt     = 0;
    my $max_fatal_cnt = 20;

    while (1)
    {
        # Job add
        $ctl->add($job);

        # Running jobs
        my $run_res = $ctl->run();

        if ($run_res)
        {
            warn '[ERR] Failed to run API';
            return -1;
        }

        # Wait APIs res
        while (!$ctl->done())
        {
            sleep 1;
        }

        # Return value
        my $stage = $job->retval;

        if (defined($stage))
        {
            # XXX: 임시 코드
            # 클러스터 초기화 시 잠깐 fatal 상태가 되는 경우가 있음
            # fatal일 때 1분 동안 재시도하여 running 상태로 변경되는지 확인
            if (lc($expected) eq 'init'
                && $prev_stage eq 'initializing'
                && $stage eq 'fatal'
                && $fatal_cnt < $max_fatal_cnt)
            {
                $fatal_cnt++;
                goto RETRY;
            }

            if ($stage ne $prev_stage)
            {
                $prev_stage = $stage;

                push(@changes, $stage);
            }
        }

        # Check to failure
        my $chg_idx = $#changes;

        if (@changes > 0
            && $changes[$chg_idx] ne $expected[$chg_idx])
        {
            $test_res = 1;
            $ctl->clear;
            last;
        }

        # Check to finish
        if ($#expected == $#changes)
        {
            # Job clear
            $test_res = 0;
            $ctl->clear;
            last;
        }

        if ($try > $try_max)
        {
            warn "[ERR] Reached to the maximum retry ($try)";

            $test_res = 1;
            $ctl->clear;
            last;
        }

        $date = get_time();

    RETRY:
        diag(
            sprintf(
                '[%s] Check Stage retry(%s) : Current[%s], Variation[%s]',
                $date, $try, $stage, join(', ', @changes)
            )
        );

        # Job clear
        $ctl->clear;

        sleep($interval);
        $try++;
    }

    # judge
    my $t_finished = get_time();

    diag("Stage test result");
    diag("- Expected : @expected");
    diag("- Changes  : @changes");
    diag("- Started  : $t_started");
    diag("- Finished : $t_finished");

    return $test_res;
}

#-------------------------------------------------------------------------------
# Test API
#-------------------------------------------------------------------------------
# This test routine only return a Stage value
# because of independant status check
#-------------------------------------------------------------------------------
sub before_init_stage_t
{
    my $self = shift;
    my %args = @_;

    $self->login() if (!defined($self->api_token));

    my $res = $self->request(
        uri         => 'cluster/volume/list',
        http_status => undef,
    );

    return ($res->{success}, $res->{stage_info}{stage});
}

sub after_init_stage_t
{
    my $self = shift;
    my %args = @_;

    $self->login() if (!defined($self->api_token));

    my $res = $self->cluster_stage_get(scope => 'cluster');
    my $ret = $res->{success};

    my $stage = $res->{stage_info}{stage};

    my %base_args = ();
    my %ext_args;

    foreach my $node (@{$self->nodes})
    {
        $ext_args{target} = "$node->{Mgmt_IP}->{ip}:80";

        $res = $self->request(
            uri         => 'cluster/volume/list',
            http_status => undef,
        );

        if (ref($res) eq 'HASH'
            && ref($res->{stage_info}) eq 'HASH'
            && defined($res->{stage_info}->{stage})
            && $res->{stage_info}->{stage} ne $stage)
        {
            $stage = $res->{stage_info}{stage};
            last;
        }
    }

    return ($ret, $stage);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Stage - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item B<Item 1>

=item B<Item 2>

=item B<Item 3>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
