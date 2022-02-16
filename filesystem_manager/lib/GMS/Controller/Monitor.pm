package GMS::Controller::Monitor;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Monitor::MonitorCtl;

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
    default => sub { GMS::Monitor::MonitorCtl->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub system_summary
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(json => $self->ctl->system_summary());
}

sub process_status
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->process_status(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub ftp_status
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->ftp_status(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub nfs_status
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->nfs_status(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub smb_status
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->smb_status(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub afp_status
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->afp_status(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub cpu_stats
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->cpu_stats(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub cpu_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->cpu_info(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub mem_stats
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->mem_stats(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub mem_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->mem_info(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub fs_stats
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->fs_stats(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub fs_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->fs_info(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub net_stats
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->net_stats(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub net_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->net_info(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Monitor - 

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

