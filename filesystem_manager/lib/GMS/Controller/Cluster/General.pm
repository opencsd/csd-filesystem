package GMS::Controller::Cluster::General;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Try::Tiny;

use GMS::API::Return;
use GMS::Cluster::Etcd;
use GMS::Cluster::General;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'handler' => (
    is       => 'ro',
    isa      => 'GMS::Cluster::General',
    init_arg => undef,
    default  => sub { GMS::Cluster::General->new(); },
    lazy     => 1,
);

has 'etcd' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::Etcd->new(); },
);

#---------------------------------------------------------------------------
#  Public Methods
#---------------------------------------------------------------------------
sub node_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $nodes = $self->handler->nodelist(%{$params});

    if (ref($nodes) ne 'ARRAY')
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GENERAL_NODELIST_FAILURE,
            msgargs => [node => $self->hostname],
        );

        $self->throw_error(message => 'Failed to get node list');
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GENERAL_NODELIST_OK,
        msgargs => [node => $self->hostname],
    );

    $self->render(json => $nodes);
}

sub get_nodes
{
    my $self   = shift;
    my $params = $self->req->json;

    my $nodes = $self->handler->get_nodes_like(%{$params});

    if (ref($nodes) ne 'ARRAY')
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GENERAL_NODELIST_FAILURE,
            msgargs => [node => $self->hostname],
        );

        $self->throw_error(message => 'Failed to get node list');
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GENERAL_NODELIST_OK,
        msgargs => [node => $self->hostname],
    );

    $self->render(json => $nodes);
}

sub master
{
    my $self   = shift;
    my $params = $self->req->json;

    my $ci = $self->etcd->get_key(key => '/ClusterInfo', format => 'json');
    my $master = $self->etcd->get_key(key => '/Cluster/Meta/master');
    my $minfo  = $ci->{node_infos}->{$master};

    GMS::API::Return::api_status(level => 'INFO');

    $self->render(
        json => {
            Hostname   => $master // $self->hostname,
            Mgmt_IP    => $minfo->{mgmt_ip}->{ip},
            Storage_IP => $minfo->{storage_ip}->{ip},
            Service_IP => $minfo->{service_ip} // [],
        }
    );
}

# 특정 노드에 접속중인 클라이언트 리스트를 조회한다.
sub clients
{
    my $self   = shift;
    my $params = $self->req->json;

    my $clients = $self->handler->clients(%{$params});

    if (!defined($clients))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GENERAL_CLIENTS_FAILURE,
            msgargs => [node => $self->hostname],
        );

        $self->throw_error(message => 'Failed to get connected clients');
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GENERAL_CLIENTS_OK,
        msgargs => [node => $self->hostname],
    );

    $self->render(json => $clients);
}

# 클러스터 파일 시스템에 설정된 Volume 정보를 조회한다.
sub node_desc
{
    my $self   = shift;
    my $params = $self->req->json;

    my $desc = $self->handler->nodedesc(%{$params});

    if (ref($desc) ne 'HASH')
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GENERAL_NODEDESC_FAILURE,
            msgargs => [node => $self->hostname],
        );

        $self->throw_error(message => 'Failed to get node description');
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GENERAL_NODEDESC_OK,
        msgargs => [node => $self->hostname],
    );

    $self->render(json => {Description => $desc});
}

# mds에 사용되는 etcd, mariadb 설정 파일을 로드한다.
sub reload_fluentd
{
    my $self   = shift;
    my $params = $self->req->json;

    my $status = $self->handler->fluentd_reload(%{$params});

    if ($status)
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GENERAL_RELOAD_FLUENTD_FAILURE,
            msgargs => [node => $self->hostname],
        );

        $self->throw_error(message => 'Failed to reload fluentd');
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GENERAL_RELOAD_FLUENTD_OK,
        msgargs => [node => $self->hostname],
    );

    $self->render(json => $status);
}

# MDS의 etcd, mariadb 설정 파일을 재구성한다.
sub reload_mds
{
    my $self   = shift;
    my $params = $self->req->json;

    my $peers = $self->etcd->reload_config(%{$params});

    if (ref($peers) ne 'ARRAY')
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GENERAL_RELOAD_MDS_FAILURE,
            msgargs => [node => $self->hostname],
        );

        $self->throw_error(message => 'Failed to reload MDS');
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GENERAL_RELOAD_MDS_OK,
        msgargs => [node => $self->hostname],
    );

    $self->render(openapi => $peers);
}

# publisher를 시스템 서비스 관리 데몬을 이용하여 활성화한다.
sub enable_publisher
{
    my $self   = shift;
    my $params = $self->req->json;

    my $status = $self->generalhandler->enable_publisher(%{$params});

    if ($status)
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_GENERAL_ENABLE_PUBLISHER_FAILURE,
            msgargs => [node => $self->hostname],
        );

        $self->throw_error(message => 'Failed to enable publisher');
    }

    api_status(
        level   => 'INFO',
        code    => CLST_GENERAL_ENABLE_PUBLISHER_OK,
        msgargs => [node => $self->hostname],
    );

    $self->render(json => $status);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::General - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

