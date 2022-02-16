package GMS::Controller::FileSystem;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Cluster::Etcd;
use GMS::FileSystem::FSCtl;

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
    default => sub { GMS::FileSystem::FSCtl->new(); },
);

has 'etcd' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { GMS::Cluster::Etcd->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub format
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->format(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub mount
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->mount(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub unmount
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->unmount(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub unmountable
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->unmountable(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub extend
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->extend(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub report_quota
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->report_quota(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub set_quota
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->set_quota(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub update_quota
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->update_quota(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub unset_quota
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->unset_quota(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

# reload to mount info
around [qw/mount unmount/] => sub
{
    my $orig = shift;
    my $self = shift;

    my $rv = $self->$orig(@_);

    my %mounts;

    foreach my $entry (@{$self->ctl->mounter->table})
    {
        if ($entry->{vfstype} =~ m/^(xfs|ext4|fuse\.glusterfs|cvfs)/)
        {
            $mounts{$entry->{file}} = $entry;
        }
    }

    if (
        $self->etcd->set_key(
            key    => "/${\$self->hostname()}/Mount",
            value  => \%mounts,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error("Failed to set /${\$self->hostname()}/Mount");
    }

    return $rv;
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::FileSystem - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

