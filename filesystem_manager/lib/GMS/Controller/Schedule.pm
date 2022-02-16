package GMS::Controller::Schedule;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Schedule::ScheduleCtl;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'ctl' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Schedule::ScheduleCtl->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub snap_sched_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->list(
        Sched_Type => 'snapshot_take',
        %{$params->{argument}},
        %{$params->{entity}}
    );

    $self->render(json => $result);
}

sub snap_sched_create
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->create(
        Sched_Type => 'snapshot_take',
        %{$params->{argument}},
        %{$params->{entity}}
    );

    $self->app->gms_new_event(locale => $self->req->json->{lang});

    $self->render(json => $result);
}

sub snap_sched_change
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->change(
        Sched_Type => 'snapshot_take',
        %{$params->{argument}},
        %{$params->{entity}}
    );

    $self->app->gms_new_event(locale => $self->req->json->{lang});

    $self->render(json => $result);
}

sub snap_sched_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->delete(
        Sched_Type => 'snapshot_take',
        %{$params->{argument}},
        %{$params->{entity}}
    );

    $self->app->gms_new_event(locale => $self->req->json->{lang});

    $self->render(json => $result);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Schedule - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

