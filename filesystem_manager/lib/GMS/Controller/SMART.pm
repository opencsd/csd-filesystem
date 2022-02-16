package GMS::Controller::SMART;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

#use GMS::API::Return;
use GMS::SMART::SMARTCtl;

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
    default => sub { GMS::SMART::SMARTCtl->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub devices
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->devices(
        %{$params->{argument}},
        %{$params->{entity}}

    );

    #$self->app->gms_new_event(locale => $self->req->json->{lang});

    $self->render(json => $result);
}

sub attributes
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->attributes(%{$params->{argument}},
        %{$params->{entity}});

    #$self->app->gms_new_event(locale => $self->req->json->{lang});

    $self->render(json => $result);
}

sub test_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->test_list(%{$params->{argument}}, %{$params->{entity}});

    #$self->app->gms_new_event(locale => $self->req->json->{lang});

    $self->render(json => $result);
}

sub test_trigger
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->test_trigger(%{$params->{argument}},
        %{$params->{entity}});

    $self->app->gms_new_event(locale => $self->req->json->{lang});

    $self->render(json => $result);
}

sub reload
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->reload(%{$params->{argument}}, %{$params->{entity}});

    $self->app->gms_new_event(locale => $self->req->json->{lang});

    $self->render(json => $result);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::SMART - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

