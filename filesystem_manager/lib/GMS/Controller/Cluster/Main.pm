package GMS::Controller::Cluster::Main;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return;
use GMS::Cluster::HTTP;
use GMS::Cluster::Stage;
use POSIX qw(setlocale);

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Main';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
sub manager
{
    my $self = shift;

    my ($token, $jwt) = $self->authenticate();

    if (!$token)
    {
        $self->redirect_to('/');
        return;
    }

    my $stage = $self->stager->get_stage(scope => 'cluster');

    if (uc($stage->{stage}) eq 'INSTALLED')
    {
        $self->redirect_to('/config');
    }
    elsif (uc($stage->{stage}) eq 'CONFIGURED')
    {
        $self->redirect_to('/init');
    }

    $self->render(
        template => 'main/manager',
        lang     => $self->inspect_lang(),
    );
}

sub config
{
    my $self = shift;

    my $stage = $self->stager->get_stage(scope => 'cluster');

    if (uc($stage->{stage}) eq 'CONFIGURED')
    {
        $self->redirect_to('/init');
    }
    elsif (uc($stage->{stage}) eq 'RUNNING'
        || uc($stage->{stage}) eq 'UNINITIALIZED')
    {
        $self->redirect_to('/manager');
    }

    $self->render(
        template => 'main/config',
        lang     => $self->inspect_lang(),
    );
}

sub init
{
    my $self = shift;

    my $stage = $self->stager->get_stage(scope => 'cluster');

    if (uc($stage->{stage}) eq 'INSTALLED')
    {
        $self->redirect_to('/config');
    }
    elsif (uc($stage->{stage}) eq 'RUNNING'
        || uc($stage->{stage}) eq 'UNINITIALIZED')
    {
        $self->redirect_to('/manager');
    }

    $self->render(
        template => 'main/init',
        lang     => $self->inspect_lang(),
    );
}

sub dummy
{
    my $self = shift;

    my $http = GMS::Cluster::HTTP->new();

    my @resps = $http->request(uri => '/api/dummy');

    my @failed = grep { !$_->success; } @resps;

    if (@failed)
    {
        return $self->throw_exception(
            'UnknownException',
            message => sprintf('dummy API has failed: %s',
                join(', ', map { $_->host; } @failed),
            )
        );
    }

    api_status(
        category => 'DUMMY',
        level    => 'INFO',
        code     => CLUSTER_DUMMY_TEST,
        quiet    => 1
    );

    $self->app->gms_new_event(locale => $self->inspect_lang());

    $self->render(status => 200, json => {});
}

sub tree
{
    my $self   = shift;
    my $params = $self->req->json;

    api_status(
        level => 'INFO',
        code  => GMS_OK,
    );

    setlocale(POSIX::LC_ALL,
        $self->inspect_lang() =~ m/^ko/ ? 'ko_KR' : 'en_US');

    $self->render(json => $self->get_menu_tree());
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Main - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

