package GMS::Controller::Cluster::Gluster;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Try::Tiny;
use Sys::Hostname::FQDN qw/short/;

### GMS 패키지
use GMS::API::Return;
use GMS::Cluster::Gluster;
use GMS::Common::Units;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'handler' => (
    is       => 'ro',
    isa      => 'GMS::Cluster::Gluster',
    init_arg => undef,
    default  => sub { GMS::Cluster::Gluster->new(); },
    lazy     => 1,
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub probe
{
    my $self   = shift;
    my $params = $self->req->json;

    my $probed = $self->handler->probe(ip => $params->{IP});

    if (!defined($probed))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GLUSTER_PROBE_FAILURE,
            msgargs => [node => short()],
        );

        goto RETURN;
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GLUSTER_PROBE_OK,
        msgargs => [node => short()],
    );

RETURN:
    $self->render(openapi => $probed);
}

sub detach
{
    my $self   = shift;
    my $params = $self->req->json;

    my $detached = $self->handler->detach(ip => $params->{IP});

    if (!defined($detached))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GLUSTER_DETACH_FAILURE,
            msgargs => [node => short()],
        );

        goto RETURN;
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GLUSTER_DETACH_OK,
        msgargs => [node => short()],
    );

RETURN:
    $self->render(openapi => $detached);
}

sub start
{
    my $self   = shift;
    my $params = $self->req->json;

    my $pid = $self->handler->start(%{$params});

    if (!defined($pid))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GLUSTER_START_FAILURE,
            msgargs => [node => short()],
        );

        goto RETURN;
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GLUSTER_START_OK,
        msgargs => [node => short()],
    );

RETURN:
    $self->render(openapi => $pid);
}

sub stop
{
    my $self   = shift;
    my $params = $self->req->json;

    my $success = 0;

    if ($self->handler->stop(%{$params}))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GLUSTER_STOP_FAILURE,
            msgargs => [node => short()],
        );

        goto RETURN;
    }

    $success = 1;

    api_status(
        level   => 'INFO',
        code    => CLST_GLUSTER_STOP_OK,
        msgargs => [node => short()],
    );

    $self->render(openapi => $success);
}

sub restart
{
    my $self   = shift;
    my $params = $self->req->json;

    my $pid = $self->handler->restart(%{$params});

    if (!defined($pid))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GLUSTER_RESTART_FAILURE,
            msgargs => [node => short()],
        );

        goto RETURN;
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GLUSTER_RESTART_OK,
        msgargs => [node => short()],
    );

RETURN:
    $self->render(openapi => $pid);
}

sub clear
{
    my $self   = shift;
    my $params = $self->req->json;

    my $volume = $self->handler->clear(%{$params});

    if (!defined($volume))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GLUSTER_CLEAR_FAILURE,
            msgargs => [node => short()],
        );

        goto RETURN;
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GLUSTER_CLEAR_OK,
        msgargs => [node => short()],
    );

RETURN:
    $self->render(openapi => $volume);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Gluster - 

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

