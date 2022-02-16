package GMS::Controller::Etcd;

use v5.14;

use utf8;
use strict;
use warnings;

use Mouse;
use namespace::clean;

use GMS::Cluster::Etcd;
use GMS::Cluster::HTTP;
use URI;

extends 'GMS::Controller';

has 'etcd' => (
    is      => 'ro',
    isa     => 'GMS::Cluster::Etcd',
    default => sub { GMS::Cluster::Etcd->new(); },
);

sub create_cluster
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        IP => {
            isa => 'Str',
        },
    };

    $params = $self->validate($rule, $params);

    if ($self->etcd->create(host => $params->{Name}, ip => $params->{IP}))
    {
        $self->throw_error('Failed to create etcd cluster config');
    }

    $self->render(status => 204, openapi => undef);
}

sub add_member
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Cluster => {
            isa     => 'Str',
            default => sub { $self->hostname(); },
        },
        Name => {
            isa => 'Str',
        },
        URI => {
            isa => 'Str',
        },
        Force => {
            isa     => 'Bool',
            default => 0,
        },
    };

    $params = $self->validate($rule, $params);

    $params->{URI} = URI->new($params->{URI});

    my $resp = GMS::Cluster::HTTP->new->request(
        host   => $params->{Cluster},
        port   => $self->etcd->client_port,
        uri    => '/v2/members',
        method => 'GET',
    );

    if (!$resp->success)
    {
        $self->throw_error(
            "${\$resp->host}: ${\$resp->status}: ${\$resp->msg}");
    }

    my $found = 0;

    foreach my $member (@{$resp->data->{members}})
    {
        my $host = $member->{name};
        my @uris = map { URI->new($_); } @{$member->{peerURLs}};

        foreach my $uri (@uris)
        {
            if ($uri == $params->{URI})
            {
                warn "[WARN] $uri is a member of the cluster already";
                $found = 1;
            }

            $self->etcd->add_initial_cluster(host => $host, uri => $uri);
        }
    }

    if (!$found)
    {
        $resp = GMS::Cluster::HTTP->new->request(
            host    => $params->{Cluster},
            port    => $self->etcd->client_port,
            method  => 'POST',
            uri     => '/v2/members',
            body    => {peerURLs => [$params->{URI}->as_string]},
            timeout => 60,
        );

        if (!$params->{Force} && !$resp->success)
        {
            $self->throw_error(
                "${\$resp->host}: ${\$resp->status}: ${\$resp->msg}");
        }
    }

    $self->etcd->add_initial_cluster(
        host => $params->{Name},
        uri  => $params->{URI},
    );

    if ($self->etcd->write_config())
    {
        return $self->_return(1, 'Failed to update etcd cluster config');
    }

    $self->render(status => 204, openapi => undef);
}

sub del_member
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Cluster => {
            isa     => 'Str',
            default => sub { $self->hostname(); },
        },
        Name => {
            isa => 'Str',
        },
        Force => {
            isa     => 'Bool',
            default => 0,
        },
    };

    $params = $self->validate($rule, $params);

    my $resp = GMS::Cluster::HTTP->new->request(
        host    => $params->{Cluster},
        port    => $self->etcd->client_port,
        method  => 'GET',
        uri     => '/v2/members',
        timeout => 60,
    );

    if (!$resp->success || ref($resp->data->{members}) ne 'ARRAY')
    {
        $self->throw_error(
            "${\$resp->host}: ${\$resp->status}: ${\$resp->msg}");
    }

    my $nid = undef;

    foreach my $member (@{$resp->data->{members}})
    {
        if ($member->{name} eq $params->{Name})
        {
            $nid = $member->{id};
            last;
        }
    }

    warn sprintf(
        '[DEBUG] Etcd member ID: %s=%s',
        $params->{Name}, $nid // 'undef',
    );

    if (defined($nid))
    {
        $resp = GMS::Cluster::HTTP->new->request(
            host    => $params->{Cluster},
            port    => $self->etcd->client_port,
            method  => 'DELETE',
            uri     => "/v2/members/$nid",
            timeout => 60,
        );

        if (!$params->{Force} && !$resp->success)
        {
            $self->throw_error(
                "${\$resp->host}: ${\$resp->status}: ${\$resp->msg}");
        }
    }

    if ($self->etcd->contract(host => $params->{Name}))
    {
        warn "[ERR] Failed to remove etcd member: $params->{Name}";
    }

    if ($self->etcd->write_config())
    {
        warn '[ERR] Failed to update etcd cluster config';
    }

    $self->render(status => 204, openapi => undef);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Etcd

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
