package GMS::Controller::Cluster::Stage;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return;
use GMS::Cluster::Etcd;
use GMS::Cluster::Stage;
use GMS::Cluster::Volume;
use GMS::Common::Units;
use Number::Bytes::Human qw/format_bytes/;
use Sys::Hostname::FQDN qw/short/;
use Try::Tiny;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub set
{
    my $self   = shift;
    my $params = $self->req->json;

    if (!defined($params->{Stage}))
    {
        api_status(
            scope    => 'cluster',
            category => 'STAGE',
            level    => 'ERROR',
            code     => MISSING_ENTITY,
            msgargs  => [
                entity => 'Stage',
                node   => short(),
            ]
        );

        return;
    }

    my $scope = $params->{Scope} // 'node';
    my $stage = $params->{Stage};
    my $data  = $params->{Data};

    if ($self->stager->set_stage(
        scope => $scope,
        stage => $stage,
        data  => $data
    ))
    {
        api_status(
            scope    => 'cluster',
            category => 'STAGE',
            level    => 'ERROR',
            code     => CLST_STAGE_SET_FAILURE,
            msgargs  => [
                scope => $scope,
                stage => $stage,
            ]
        );

        goto RETURN;
    }

    api_status(
        scope    => 'cluster',
        category => 'STAGE',
        level    => 'INFO',
        code     => CLST_STAGE_SET_OK,
        msgargs  => [
            scope => $scope,
            stage => $stage,
        ]
    );

RETURN:
    $self->app->gms_new_event();

    $self->render(openapi => $self->stager->get_stage(scope => $scope));
}

sub get
{
    my $self   = shift;
    my $params = $self->req->json;

    if (!defined($params->{Scope}))
    {
        api_status(
            scope    => 'cluster',
            category => 'STAGE',
            level    => 'ERROR',
            code     => MISSING_ENTITY,
            msgargs  => [
                entity => 'Scope',
                node   => short(),
            ]
        );

        goto RETURN;
    }

    my $scope = $params->{Scope};

    my $rv = $self->stager->get_stage(scope => $scope);

    if (!defined($rv))
    {
        api_status(
            scope    => 'cluster',
            category => 'STAGE',
            level    => 'ERROR',
            code     => CLST_STAGE_GET_FAILURE,
            msgargs  => [
                scope => $params->{Scope} // 'node'
            ]
        );

        goto RETURN;
    }

    api_status(
        scope    => 'cluster',
        category => 'STAGE',
        level    => 'INFO',
        code     => CLST_STAGE_GET_OK,
    );

RETURN:
    $self->render(openapi => $rv);
}

sub list
{
    my $self   = shift;
    my $params = $self->req->json;

    if (!defined($params->{Scope}))
    {
        api_status(
            scope    => 'cluster',
            category => 'STAGE',
            level    => 'ERROR',
            code     => MISSING_ENTITY,
            msgargs  => [
                entity => 'Scope',
                node   => short(),
            ]
        );

        goto RETURN;
    }

    my $rv = $self->stager->list_stage(scope => $params->{Scope});

    if (ref($rv) ne 'ARRAY')
    {
        api_status(
            scope    => 'cluster',
            category => 'STAGE',
            level    => 'ERROR',
            code     => CLST_STAGE_LIST_FAILURE,
            msgargs  => [
                scope => $params->{Scope} // 'node'
            ]
        );

        goto RETURN;
    }

    api_status(
        scope    => 'cluster',
        category => 'STAGE',
        level    => 'INFO',
        code     => CLST_STAGE_LIST_OK,
    );

RETURN:
    $self->render(openapi => $rv);
}

sub info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $used  = 0;
    my $total = 0;

    my $etcd = GMS::Cluster::Etcd->new();

    my $ci    = $etcd->get_key(key => '/ClusterInfo', format => 'json');
    my $vpool = $etcd->get_key(key => '/VPools',      format => 'json');

    foreach my $node (keys(%{$ci->{node_infos}}))
    {
        my $blk = $etcd->get_key(key => "/$node/Block", format => 'json');

        if (ref($blk) eq 'HASH'
            && ref($blk->{Block}) eq 'HASH'
            && ref($blk->{Block}->{device}) eq 'HASH')
        {
            foreach my $name (keys(%{$blk->{Block}->{device}}))
            {
                my $dev = $blk->{Block}->{device}->{$name};

                next
                    if ($dev->{is_preserved}
                    || $dev->{type} !~ m/^(?:hdd|multipath|nvme)$/);

                $total += $dev->{size};
            }
        }

        my $vg_info = $etcd->get_key(key => "/$node/VG", format => 'json');

        foreach my $vg_name (keys(%{$vg_info}))
        {
            if (ref($vg_info->{$vg_name}) ne 'HASH')
            {
                warn "[WARN] Invalid VG data: $node/VG";
                next;
            }

            next if (!grep { $vg_name =~ m/^$_\d+/; } keys(%{$vpool}));

            my $vg = $vg_info->{$vg_name};

            $used += int($vg->{usedpe} * $vg->{pesize});
        }
    }

    my $stage     = $self->stager->get_stage(scope => 'cluster');
    my $available = $self->stager->get_available_stages(
        scope   => 'cluster',
        cluster => $stage->{stage},
    );

    my $rv = try
    {
        my %num_opts = (
            si               => 1,
            precision        => 2,
            precision_cutoff => 3,
            round_style      => 'round',
        );

        return {
            Name           => $ci->{cluster}->{cluster_name},
            Stage          => $stage->{stage},
            Status_Msg     => uc($stage->{stage}),
            Total_Capacity => format_bytes($total * 1024, %num_opts),
            Usage_Capacity => format_bytes($used * 1024,  %num_opts),
            Management     => $available,
        };
    }
    catch
    {
        warn "[ERR] Unexpected exception: @_";
        return;
    };

    api_status(
        scope    => 'cluster',
        category => 'STAGE',
        level    => 'INFO',
        code     => CLST_STAGE_INFO_OK,
    );

RETURN:
    $self->render(openapi => $rv);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Stage - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

