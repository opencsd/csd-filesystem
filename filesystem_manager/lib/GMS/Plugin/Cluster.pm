package GMS::Plugin::Cluster;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Coro;
use AnyEvent;
use Coro::AnyEvent;

use GMS::API::Return;
use GMS::API::URI::Cluster;
use GMS::Common::Logger;
use GMS::Cluster::Etcd;
use GMS::Cluster::Stage;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'uri' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { GMS::API::URI::Cluster->get_uris(); },
);

has 'etcd' => (
    is      => 'ro',
    isa     => 'GMS::Cluster::Etcd',
    default => sub { GMS::Cluster::Etcd->new(); },
);

has 'stager' => (
    is      => 'ro',
    isa     => 'GMS::Cluster::Stage',
    default => sub { GMS::Cluster::Stage->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub register
{
    my ($self, $app, $conf) = @_;

    if ($self->_setup_routes($app))
    {
        warn sprintf("[ERR] Failed to setup routes: %s", __PACKAGE__);
        exit 255;
    }

    if ($self->_setup_hooks($app))
    {
        warn sprintf("[ERR] Failed to setup hooks: %s", __PACKAGE__);
        exit 255;
    }

    $app->helper(etcd   => sub { $self->etcd; });
    $app->helper(stager => sub { $self->stager; });

    $app->helper(
        gms_lock => sub
        {
            my $c    = shift;
            my %args = @_;

            if (!exists($args{owner}))
            {
                $args{owner} = $c->req->request_id;
            }

            $self->etcd->lock(%args);
        }
    );

    $app->helper(
        gms_unlock => sub
        {
            my $c    = shift;
            my %args = @_;

            if (!exists($args{owner}))
            {
                $args{owner} = $c->req->request_id;
            }

            $self->etcd->unlock(%args);
        }
    );

    warn "[INFO] ${\__PACKAGE__} plugin is registered";

    return;
}

sub _setup_log_level
{
    my $self = shift;
    my $app  = shift;

    my $debug = $self->etcd->get_key(
        key     => '/Cluster/Meta/debug',
        options => {recursive => 1}
    );

    if (!(ref($debug) eq 'HASH' && keys(%{$debug})))
    {
        $debug = {Event => 1};
    }

    set_category('API',    1);
    set_category('Common', 1);

    if (ref($debug) eq 'HASH'
        && (grep { $debug->{$_} > 0; } keys(%{$debug})))
    {
        foreach my $cat (keys(%{$debug}))
        {
            set_category($cat, $debug->{$cat});
        }
    }

    return 0;
}

sub _setup_routes
{
    my $self = shift;
    my $app  = shift;

    $self->_setup_default_routes($app);
    $self->_setup_manual_routes($app);

    if ($self->_setup_api_routes($app))
    {
        warn '[ERR] Failed to setup cluster API routes';
        return -1;
    }

    return 0;
}

sub _setup_default_routes
{
    my $self   = shift;
    my $app    = shift;
    my $router = $app->routes;

    $router->get('/')->to('Cluster::Main#welcome');
    $router->get('/manager')->to('Cluster::Main#manager');
    $router->get('/config')->to('Cluster::Main#config');
    $router->get('/init')->to('Cluster::Main#init');

    return;
}

sub _setup_manual_routes
{
    my $self   = shift;
    my $app    = shift;
    my $router = $app->routes;

    $router->any('/manual/#lang')->to('Manual#main', lang => 'ko');
    $router->any('/manual/#lang/intro')->to('Manual#intro');
    $router->any('/manual/#lang/install')->to('Manual#install');
    $router->any('/manual/#lang/cluster')->to('Manual#cluster');
    $router->any('/manual/#lang/cluster/volume')->to('Manual#cluster_volume');
    $router->any('/manual/#lang/account')->to('Manual#account');
    $router->any('/manual/#lang/share')->to('Manual#share');
    $router->any('/manual/#lang/node')->to('Manual#node');

    $router->any('/manual/:lang/troubleshoot/:chapter')
        ->to('Manual#trbl', lang => 'ko', chapter => 'common');
    $router->any('/manual/:lang/questions/:chapter')
        ->to('Manual#questions', lang => 'ko', chapter => 'common');

    return;
}

sub _setup_api_routes
{
    my $self = shift;
    my $app  = shift;

    my @excludes = (
        "^\/cluster\/stage\/get\$/",
        "^\/cluster\/general\/master\$/",
        "^\/cluster\/stage\/info\$/",
    );

    if ($app->_setup_routes(
        root     => $app->auth_route,
        uri      => {cluster => $self->uri->{cluster}},
        excludes => \@excludes
    ))
    {
        return -1;
    }

    return 0;
}

sub _setup_hooks
{
    my $self = shift;
    my $app  = shift;

    $app->hook(
        before_routes => sub
        {
            my $c   = shift;
            my $uri = $c->req->url->path->to_abs_string();

            return if ($c->req->url->path !~ m/^\/api\//);
            return if ($c->req->url->path =~ m/^\/api\/v3/);

            my ($stage, $scope, $data) = $self->stager->get_represent_stage();

            $c->stash(
                'gms.stage.stage' => $stage,
                'gms.stage.scope' => $scope,
                'gms.stage.data'  => $data,
            );

            warn "[DEBUG] uri: $uri";
            warn "[DEBUG] stage: ${\$self->dumper($stage)}";
            warn "[DEBUG] scope: ${\$self->dumper($scope)}";
            warn "[DEBUG] data: ${\$self->dumper($data)}";

            my $stage_policy = $self->stager->get_policy_from_stage(
                stage => $stage,
                scope => $scope,
                data  => $data,
                uri   => $uri,
            );

            warn "[DEBUG] policy: $stage_policy";

            if (
                $stage_policy eq 'no'
                || ($stage_policy eq 'ro'
                    && GMS::API::URI::Cluster->is_set_api($uri))
                )
            {
                $c->render(
                    status => 403,
                    json   => {
                        success => \0,
                        return  => 'false',
                        msg     => 'This request is denied by '
                            . "stage policy: $stage: no",
                        entity     => undef,
                        statuses   => undef,
                        stage_info => {
                            stage => $stage,
                            data  => $data
                        },
                    },
                );
            }
        }
    );

    $app->hook(
        before_render => sub
        {
            my ($c, $return) = @_;

            if ($c->tx->req->url->path !~ m/^\/api\//)
            {
                warn sprintf('[DEBUG] This request is not for API: %s',
                    $c->tx->req->url->path);

                return;
            }

            return if ($c->req->url->path =~ m/^\/api\/v3/);

            my $api_type;

            if (exists($return->{openapi}))
            {
                $api_type = 'openapi';
            }
            elsif (exists($return->{json}))
            {
                $api_type = 'json';
            }
            else
            {
                warn '[DEBUG] Unknown API type';
                return;
            }

            $return->{$api_type}->{stage_info} = {
                stage => $c->stash('gms.stage.stage'),
                data  => $c->stash('gms.stage.data'),
                proc  => $self->stager->get_proc() // undef,
            };

            return;
        }
    );

    return 0;
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::Cluster - GMS plugin for cluster management

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2020. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
