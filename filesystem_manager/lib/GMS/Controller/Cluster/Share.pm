package GMS::Controller::Cluster::Share;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Cluster::HTTP;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Share';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'build_models' => sub
{
    my $self = shift;
    my %args = @_;

    my $retval = super();

    $retval->{Share}          = 'GMS::Model::Cluster::Share';
    $retval->{'NFS::Kernel'}  = 'GMS::Model::Cluster::NFS::Kernel::Export';
    $retval->{'NFS::Ganesha'} = 'GMS::Model::Cluster::NFS::Ganesha::Export';
    $retval->{SMB}            = 'GMS::Model::Cluster::SMB::Samba::Section';

    return $retval;
};

override 'delete' => sub
{
    my $self = shift;
    my %args = @_;

    super();

    my @resp;

    if ($self->stash('NFS::Kernel'))
    {
        @resp = GMS::Cluster::HTTP->new->request(
            uri => '/api/share/nfs/kernel/reload');

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                sprintf(
                    'Failed to reload Kernel NFS settings on %s: %s',
                    $r->host, $r->msg
                )
            );
        }

        warn sprintf('[DEBUG] Kernel NFS settings has reloaded: %s',
            $self->dumper(\@resp));

        @resp = GMS::Cluster::HTTP->new->request(
            uri  => '/api/share/nfs/kernel/control',
            body => {Action => 'reload'},
        );

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                sprintf(
                    'Failed to reload Kernel NFS service on %s: %s',
                    $r->host, $r->msg
                )
            );
        }

        warn sprintf('[DEBUG] Kernel NFS service has reloaded: %s',
            $self->dumper(\@resp));
    }

    if ($self->stash('NFS::Ganesha'))
    {
        @resp = GMS::Cluster::HTTP->new->request(
            uri => '/api/share/nfs/ganesha/reload');

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                sprintf(
                    'Failed to reload NFS-Ganesha settings on %s: %s',
                    $r->host, $r->msg
                )
            );
        }

        warn sprintf('[DEBUG] NFS-Ganesha settings has reloaded: %s',
            $self->dumper(\@resp));

        @resp = GMS::Cluster::HTTP->new->request(
            uri  => '/api/share/nfs/ganesha/control',
            body => {Action => 'reload'},
        );

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                sprintf(
                    'Failed to reload NFS-Ganesha service on %s: %s',
                    $r->host, $r->msg
                )
            );
        }

        warn sprintf('[DEBUG] NFS-Ganesha service has reloaded: %s',
            $self->dumper(\@resp));
    }

    if ($self->stash('SMB'))
    {
        @resp = GMS::Cluster::HTTP->new->request(
            uri => '/api/share/smb/reload');

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                sprintf(
                    'Failed to reload SMB settings on %s: %s',
                    $r->host, $r->msg
                )
            );
        }

        warn "[DEBUG] SMB settings has reloaded: ${\$self->dumper(\@resp)}";

        @resp = GMS::Cluster::HTTP->new->request(
            uri  => '/api/share/smb/control',
            body => {Action => 'reload'},
        );

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                sprintf(
                    'Failed to reload SMB service on %s: %s',
                    $r->host, $r->msg
                )
            );
        }

        warn "[DEBUG] SMB service has reloaded: ${\$self->dumper(\@resp)}";
    }
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Share - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
