package GMS::Controller::Cluster::Share::NFS::Ganesha;

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
extends 'GMS::Controller::Share::NFS::Ganesha';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'build_models' => sub
{
    {
        Share   => 'GMS::Model::Cluster::Share',
        Zone    => 'GMS::Model::Cluster::Network::Zone',
        Core    => 'GMS::Model::Cluster::NFS::Ganesha::Core',
        Default => 'GMS::Model::Cluster::NFS::Ganesha::Default',
        MDCache => 'GMS::Model::Cluster::NFS::Ganesha::MDCache',
        Export  => 'GMS::Model::Cluster::NFS::Ganesha::Export',
    };
};

# :WARNING 09/01/2019 07:19:05 PM: by P.G.
#no strict 'refs';
#*GMS::Controller::Share::NFS::Ganesha::build_models = \&build_models;
#use strict 'refs';

foreach (qw/enable disable update set_network_access/)
{
    override $_ => sub
    {
        my $self = shift;

        super();

        my @resp = GMS::Cluster::HTTP->new->request(
            uri      => '/api/share/nfs/ganesha/reload',
            excludes => {
                self => 1,
            }
        );

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                "Failed to reload NFS-Ganesha settings on ${\$r->host}");
        }

        warn '[INFO] NFS-Ganesha settings has reloaded';

        @resp = GMS::Cluster::HTTP->new->request(
            uri  => '/api/share/nfs/ganesha/control',
            body => {Action => 'reload'},
        );

        foreach my $r (@resp)
        {
            next if (!defined($r) || $r->status == 200);

            $self->throw_error(
                "Failed to reload NFS-Ganesha service on ${\$r->host}");
        }

        warn '[INFO] NFS-Ganesha service has reloaded';

        map { delete($self->stash->{$_}) if (exists($self->stash->{$_})); }
            (qw/section share volume/);

        return $self->render();
    };
}

override 'set_config' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    super();

    my $action = $params->{Active} eq 'on' ? 'reload' : 'stop';

    my @resp = GMS::Cluster::HTTP->new->request(
        uri  => '/api/share/nfs/ganesha/control',
        body => {
            Active => $params->{Active},
            Action => $action
        },
        excludes => {
            self => 1,
        }
    );

    foreach my $r (@resp)
    {
        next if (!defined($r) || $r->status == 200);

        $self->throw_error(
            sprintf(
                'Failed to %s NFS-Ganesha service on %s',
                $action, $r->host
            )
        );
    }

    return;
};

override 'control' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    super();

    my @resp = GMS::Cluster::HTTP->new->request(
        uri      => '/api/share/nfs/ganesha/control',
        body     => $params,
        excludes => {
            self => 1,
        }
    );

    foreach my $r (@resp)
    {
        next if (!defined($r) || $r->status == 200);

        $self->throw_error(
            sprintf(
                'Failed to %s NFS-Ganesha on %s',
                $params->{Action}, $r->host
            )
        );
    }

    return;
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Share::NFS::Ganesha - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
