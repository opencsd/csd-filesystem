package Test::AnyStor::Schedule;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::Most;
use Mojo::UserAgent;
use JSON qw/decode_json/;

extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
#===  CLASS METHOD  ==========================================================
#        CLASS: Schedule
#       METHOD: sched_create
#        BRIEF: 스케줄링 정보 생성
#=============================================================================
sub sched_create
{
    my $self = shift;
    my %args = @_;

    my %base_args = (Sched_Type => 'snapshot_take', %args);
    my %ext_args  = ();
    my %entity    = ();

    $self->call_rest_api('cluster/schedule/snapshot/create',
        \%base_args, \%entity, \%ext_args);

    my $res = $self->t;

    my $api_success = $res->success;

    my $api_json   = $res->tx->res->json;
    my $api_return = $api_json->{success};
    my $api_stage  = $api_json->{stage_info}{stage};

    my $api_httpcode = $res->tx->res->{code};

    if (!$api_success || $api_httpcode ne '200')
    {
        $api_return = 0;
    }

    $self->check_api_code_in_recent_events(
        category => 'SCHEDULE',
        prefix   => 'CLST_SCHED_CREATE_',
        from     => $api_json->{prof}->{from},
        to       => $api_json->{prof}->{to},
        status   => $api_return,
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    if ($api_stage ne 'running')
    {
        diag(explain($api_json));
        return '';
    }

    return $api_json->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Schedule
#       METHOD: sched_list
#        BRIEF: 스케줄링 정보 리스트 반환
#=============================================================================
sub sched_list
{
    my $self = shift;
    my %args = @_;

    my %base_args = (Sched_Type => 'snapshot_take', %args);
    my %ext_args  = ();
    my %entity    = ();

    my $res = $self->call_rest_api('cluster/schedule/snapshot/list',
        \%base_args, \%entity, \%ext_args);

    goto ERROR
        if (!$res->{success} || $res->{stage_info}{stage} ne 'running');

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Schedule
#       METHOD: sched_change
#        BRIEF: 스케줄링 정보 변경
#=============================================================================
sub sched_change
{
    my $self = shift;
    my %args = @_;

    my %base_args = (Sched_Type => 'snapshot_take', %args);
    my %ext_args  = ();
    my %entity    = ();

    $self->call_rest_api('cluster/schedule/snapshot/change',
        \%base_args, \%entity, \%ext_args);

    my $res         = $self->t;
    my $api_success = $res->success;

    my $api_json   = $res->tx->res->json;
    my $api_return = $api_json->{success};
    my $api_stage  = $api_json->{stage_info}{stage};

    my $api_httpcode = $res->tx->res->{code};

    if (!$api_success || $api_httpcode ne '200')
    {
        $api_return = 0;
    }

    $self->check_api_code_in_recent_events(
        category => 'SCHEDULE',
        prefix   => 'CLST_SCHED_CHANGE_',
        from     => $api_json->{prof}->{from},
        to       => $api_json->{prof}->{to},
        status   => $api_return,
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    diag(explain($api_json)) if ($api_stage ne 'running');

    if (!$api_return || $api_stage ne 'running')
    {
        return -1;
    }

    return 0;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Schedule
#       METHOD: sched_delete
#        BRIEF: 스케줄링 정보 변경
#=============================================================================
sub sched_delete
{
    my $self = shift;
    my %args = @_;

    my %base_args = (Sched_Type => 'snapshot_take', %args);
    my %ext_args  = ();
    my %entity    = ();

    $self->call_rest_api('cluster/schedule/snapshot/delete',
        \%base_args, \%entity, \%ext_args);

    my $res         = $self->t;
    my $api_success = $res->success;

    my $api_json   = $res->tx->res->json;
    my $api_return = $api_json->{success};
    my $api_stage  = $api_json->{stage_info}{stage};

    my $api_httpcode = $res->tx->res->{code};

    if (!$api_success || $api_httpcode ne '200')
    {
        $api_return = 0;
    }

    $self->check_api_code_in_recent_events(
        category => 'SCHEDULE',
        prefix   => 'CLST_SCHED_DELETE_',
        from     => $api_json->{prof}->{from},
        to       => $api_json->{prof}->{to},
        status   => $api_return,
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    diag(explain($api_json)) if ($api_stage ne 'running');

    if (!$api_return || $api_stage ne 'running')
    {
        return -1;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
