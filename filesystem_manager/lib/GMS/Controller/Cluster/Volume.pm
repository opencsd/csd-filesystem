package GMS::Controller::Cluster::Volume;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Cluster::FSCtl;
use GMS::Model::Cluster::Share;

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
    default => sub { GMS::Cluster::FSCtl->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub brick_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__brick_list($params->{argument}, $params->{entity});

    $self->render(json => $result);
}

sub volume_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__volume_list($params->{argument}, $params->{entity});

    $self->render(json => $result);
}

sub volume_create
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__volume_create($params->{argument}, $params->{entity});

    $self->publish_event();
    $self->app->run_checkers();

    $self->render(json => $result);
}

sub volume_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    foreach my $name (GMS::Model::Cluster::Share->list())
    {
        my $model = GMS::Model::Cluster::Share->find($name);

        if ($model->pool eq $params->{argument}->{Pool}
            || $model->volume eq $params->{argument}->{Volume_Name})
        {
            die 'Shared volume cannot be deleted';
        }
    }

    my $result
        = $self->ctl->__volume_delete($params->{argument}, $params->{entity});

    if (!defined($params->{argument}->{Dry})
        || $params->{argument}->{Dry} ne 'true')
    {
        $self->publish_event();
        $self->app->run_checkers();
    }

    $self->render(json => $result);
}

sub volume_ctlopt
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__volume_ctlopt($params->{argument}, $params->{entity});

    $self->publish_event();
    $self->render(json => $result);
}

sub volume_reload
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__volume_reload($params->{argument}, $params->{entity});

    $self->render(json => $result);
}

sub volume_quota_enable
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_quota_enable($params->{argument},
        $params->{entity});

    $self->publish_event();
    $self->render(json => $result);
}

sub volume_quota_disable
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_quota_disable($params->{argument},
        $params->{entity});

    $self->publish_event();
    $self->render(json => $result);
}

sub volume_quota_setlimit
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_quota_setlimit($params->{argument},
        $params->{entity});

    $self->publish_event();
    $self->render(json => $result);
}

sub volume_quota_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_quota_list($params->{argument},
        $params->{entity});

    $self->render(json => $result);
}

sub volume_quota_rmlimit
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_quota_rmlimit($params->{argument},
        $params->{entity});

    $self->publish_event();
    $self->render(json => $result);
}

sub volume_quota_settime
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_quota_settime($params->{argument},
        $params->{entity});

    $self->publish_event();
    $self->render(json => $result);
}

sub volume_expand
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__volume_expand($params->{argument}, $params->{entity});

    if (!defined($params->{argument}->{Dry})
        || $params->{argument}->{Dry} ne 'true')
    {
        $self->publish_event();
    }

    $self->render(json => $result);
}

sub volume_extend
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__volume_extend($params->{argument}, $params->{entity});

    if (!defined($params->{argument}->{Dry})
        || $params->{argument}->{Dry} ne 'true')
    {
        $self->publish_event();
    }

    $self->render(json => $result);
}

sub volume_heal
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__volume_heal($params->{argument}, $params->{entity});

    if (!defined($params->{argument}->{Dry})
        || $params->{argument}->{Dry} ne 'true')
    {
        $self->publish_event();
    }

    $self->render(json => $result);
}

sub volume_rebalance
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_rebalance($params->{argument},
        $params->{entity});

    if (!defined($params->{argument}->{Dry})
        || $params->{argument}->{Dry} ne 'true')
    {
        $self->publish_event();
    }

    $self->render(json => $result);
}

sub volume_snapshot_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_snapshot_list($params->{argument},
        $params->{entity});

    $self->render(json => $result);
}

sub volume_snapshot_create
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_snapshot_create($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_snapshot_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_snapshot_delete($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_snapshot_activate
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_snapshot_activate($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_snapshot_restore
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_snapshot_restore($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_snapshot_clone
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_snapshot_clone($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_snapshot_avail
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_snapshot_avail($params->{argument},
        $params->{entity});

    $self->render(json => $result);
}

sub volume_tier_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_tier_list($params->{argument},
        $params->{entity});

    $self->render(json => $result);
}

sub volume_tier_attach
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_tier_attach($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_tier_detach
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_tier_detach($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_tier_opts
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_tier_opts($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_arbiter_attach
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_arbiter_attach($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_pool_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_pool_list($params->{argument},
        $params->{entity});

    $self->render(json => $result);
}

sub volume_pool_create
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_pool_create($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_pool_remove
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_pool_remove($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

sub volume_pool_reconfig
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->__volume_pool_reconfig($params->{argument},
        $params->{entity});

    $self->publish_event();

    $self->render(json => $result);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Volume - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

