package GMS::Controller::Cluster::Initializer;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Try::Tiny;
use Sys::Hostname::FQDN qw/short/;

use GMS::API::Return;
use GMS::Common::ArgCheck qw/is_argument_type check_arguments/;
use GMS::Common::Units;
use GMS::Cluster::Initializer;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'inithandler' => (
    is       => 'ro',
    isa      => 'GMS::Cluster::Initializer',
    init_arg => undef,
    default  => sub { GMS::Cluster::Initializer->new(); },
    lazy     => 1,
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub configure
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->inithandler->config(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_CONFIG_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => short()]
        );

        # Exception
        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        category => 'INITIALIZE',
        code     => CLST_INIT_CONFIG_OK,
        msgargs  => [node => short()]
    );

    $self->app->run_checkers();

    $self->publish_event();
    return $self->render(status => 204, openapi => undef);
}

sub create
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->inithandler->create(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_CREATE_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => short()]
        );

        # Exception
        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        category => 'INITIALIZE',
        code     => CLST_INIT_CREATE_OK,
        msgargs  => [node => short()]
    );

    $self->app->run_checkers();

    $self->publish_event();
    return $self->render(openapi => $rv->{data});
}

sub join
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv;

    if (!$self->ping_to_node($params->{Cluster_IP}))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_INIT_CONNECTION_FAILURE,
            scope   => 'cluster',
            msgargs => [
                target_address => $params->{Cluster_IP},
            ]
        );

        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    $rv = $self->inithandler->join(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_JOIN_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => short()]
        );

        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        category => 'INITIALIZE',
        code     => CLST_INIT_JOIN_OK,
        msgargs  => [node => short()],
    );

    $self->app->run_checkers();

    $self->publish_event();
    return $self->render(openapi => $rv->{data});
}

sub register
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->inithandler->register(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_REG_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => $rv->{new_nodename}],
        );

        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        category => 'INITIALIZE',
        code     => CLST_INIT_REG_OK,
        msgargs  => [node => $rv->{new_nodename}],
    );

    $self->publish_event();
    return $self->render(openapi => $rv->{data});
}

sub unregister
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->inithandler->unregister(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_UNREG_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => $params->{Target_Node}],
        );

        $self->publish_event();

        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        category => 'INITIALIZE',
        code     => CLST_INIT_UNREG_OK,
        msgargs  => [node => $params->{Target_Node}],
    );

    $self->publish_event();

    return $self->render(openapi => $rv->{data});
}

sub expand
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv;

    if (!$self->ping_to_node($params->{Manage_IP}))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_INIT_CONNECTION_FAILURE,
            msgargs => [target_address => $params->{Manage_IP}]
        );

        # Exception
        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    $rv = $self->inithandler->expand(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_EXPAND_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => $params->{Manage_IP}]
        );

        # Exception
        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        code     => CLST_INIT_EXPAND_OK,
        category => 'INITIALIZE',
        msgargs  => [node => $params->{Manage_IP}]
    );

    $self->publish_event();
    $self->app->run_checkers();

    return $self->render(status => 204, openapi => undef);
}

sub contract
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv;

    if (!$self->ping_to_node($params->{Manage_IP}))
    {
        api_status(
            level   => 'ERROR',
            code    => CLST_INIT_CONNECTION_FAILURE,
            msgargs => [target_address => $params->{Manage_IP}]
        );

        # Exception
        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    $rv = $self->inithandler->contract(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_CONTRACT_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => $params->{Manage_IP}]
        );

        # Exception
        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        code     => CLST_INIT_CONTRACT_OK,
        category => 'INITIALIZE',
        msgargs  => [node => $params->{Manage_IP}]
    );

    $self->publish_event();
    $self->app->run_checkers();

    $self->render(status => 204, openapi => undef);
}

sub activate
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->inithandler->activate(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_ACTIVATE_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => short()]
        );

        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        category => 'INITIALIZE',
        code     => CLST_INIT_ACTIVATE_OK,
        msgargs  => [node => short()],
    );

    $self->publish_event();
    return $self->render(openapi => $rv->{data});
}

sub deactivate
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->inithandler->deactivate(%{$params});

    if ($rv->{status})
    {
        api_status(
            level    => 'ERROR',
            code     => CLST_INIT_ACTIVATE_FAILURE,
            category => 'INITIALIZE',
            msgargs  => [node => short()]
        );

        $self->publish_event();
        return $self->render(status => 500, openapi => undef);
    }

    api_status(
        level    => 'INFO',
        category => 'INITIALIZE',
        code     => CLST_INIT_ACTIVATE_OK,
        msgargs  => [node => short()]
    );

    $self->publish_event();
    return $self->render(openapi => $rv->{data});
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub ping_to_node
{
    my $self = shift;
    my $node = shift;

    my $result = GMS::Common::Command::exec(
        cmd  => 'ping',
        args => ['-w', '10', '-c', '3', $node]
    );

    if (!$result->{status})
    {
        return 1;
    }

    warn "[ERR] $node is not responding: ${\$self->dumper($result)}";

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Initializer - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

