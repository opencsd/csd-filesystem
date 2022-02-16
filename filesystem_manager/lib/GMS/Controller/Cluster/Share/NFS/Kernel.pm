package GMS::Controller::Cluster::Share::NFS::Kernel;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Share::NFS::Kernel';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'build_models' => sub
{
    {
        Share     => 'GMS::Model::Cluster::Share',
        Zone      => 'GMS::Model::Cluster::Network::Zone',
        Sysconfig => 'GMS::Model::Cluster::NFS::Kernel::Sysconfig',
        Export    => 'GMS::Model::Cluster::NFS::Kernel::Export',
    };
};

# :WARNING 09/01/2019 07:19:05 PM: by P.G.
#no strict 'refs';
#*GMS::Controller::Share::NFS::Kernel::build_models = \&build_models;
#use strict 'refs';
#
foreach (qw/enable disable update set_network_access/)
{
    override $_ => sub
    {
        my $self = shift;

        super();

        my @resp = GMS::Cluster::HTTP->new->request(
            uri      => '/api/share/nfs/kernel/reload',
            excludes => {
                self => 1,
            }
        );

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                "Failed to reload Kernel NFS settings on ${\$r->host}");
        }

        warn '[INFO] Kernel NFS settings has reloaded';

        @resp = GMS::Cluster::HTTP->new->request(
            uri  => '/api/share/nfs/kernel/control',
            body => {Action => 'reload'},
        );

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                "Failed to reload Kernel NFS service on ${\$r->host}");
        }

        warn '[INFO] Kernel NFS service has reloaded';

        map { delete($self->stash->{$_}) if (exists($self->stash->{$_})); }
            (qw/section share volume/);

        return $self->render();
    };
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Share::NFS::Kernel - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
