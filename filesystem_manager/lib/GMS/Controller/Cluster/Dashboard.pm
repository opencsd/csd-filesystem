package GMS::Controller::Cluster::Dashboard;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Try::Tiny;

use GMS::API::Return qw/:CLUSTER api_status/;
use GMS::Common::Units;
use GMS::Cluster::DashboardCtl;

use Girasole::Constants qw/:LEVEL/;
use Girasole::Analyzer::Stats;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has ctl => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::DashboardCtl->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub cluster_status
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(openapi => $self->ctl->__cluster_status(%{$params}));
}

sub node_status
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(openapi => $self->ctl->__node_status(%{$params}));
}

sub fsusage
{
    my $self = shift;

    $self->render(openapi => $self->ctl->__fsusage());
}

sub clientgraph
{
    my $self = shift;

    $self->render(openapi => $self->ctl->__clientgraph());
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Dashboard - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

