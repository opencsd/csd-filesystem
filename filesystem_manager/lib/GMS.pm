package GMS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';
our $VERSION   = '3.1.0';

BEGIN
{
    use Coro;
    use Coro::Multicore;
    use Coro::Select;
    use AnyEvent;

    no warnings 'redefine';

    *CORE::GLOBAL::sleep = sub
    {
        my $sec = shift;

        Coro::AnyEvent::sleep($sec);

        return $sec;
    };

    use Data::Dumper;

    # UTF encoding trick for Data::Dumper
    *Data::Dumper::qquote   = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl  = 1;
    $Data::Dumper::Deparse  = 1;
    $Data::Dumper::Sortkeys = 1;

    use warnings 'redefine';
}

# :WARNING 09/18/2019 03:47:52 PM: by P.G.
# We should un-comment below codes to get backtrace in try...catch with
# Try::Tiny.
# However this code will cause segfault by unknown reason.
# we will find a reason and resolve this issue later.
#
#use Carp;
#$Carp::Verbose = 1;
#delete($Carp::Internal{'Try::Tiny'});
#our @CARP_NOT = qw(Try::Tiny);

use Mojo::Base 'Mojolicious';

use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catdir);
use GMS::API::URI;
use GMS::API::Return;
use GMS::Common::Logger;
use GMS::Controller;
use MojoX::Log::Log4perl;
use Try::Tiny;

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'uri' => sub
{
    ${GMS::API::URI::URI};
};

has 'log_settings' => sub
{
    my $self = shift;

    return {
        mojo => $self,
        mask => $self->app->mode eq 'production' ? LOG_INFO : LOG_DEBUG,

        #procname => undef,
        #datetime => 0,
        #pid      => 0,
        level  => 0,
        stdout => undef,
        stderr => undef,
    };
};

has 'auth_route' => sub
{
    my $self = shift;

    $self->app->routes->under(
        '/',
        sub
        {
            my $c = shift;

            if ($c->req->method eq 'OPTIONS')
            {
                return 1;
            }

            my ($token, $jwt) = $c->authenticate();

            if (!$token || !$jwt)
            {
                $c->render(
                    json   => {msg => 'Unauthorized'},
                    status => 401,
                );

                return;
            }

            return 1;
        } => 'auth_route'
    );
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub startup
{
    my $app = shift;

    # Logger
    if ($app->setup_logger())
    {
        warn '[ERR] Failed to setup logger';
        exit 1;
    }

    $app->controller_class('GMS::Controller');

    # Command namespace
    push(@{$app->commands->namespaces}, 'GMS::Command');

    # Static
    my $public = catdir($app->home, 'public');

    $app->static->paths->[0]
        = -d $public ? $public : catdir(dist_dir('GMS'), 'public');
    $app->static->paths->[1] = catdir($app->home, 'doc');

    # Template
    my $tmpldir = catdir($app->home, 'templates');

    $app->renderer->paths->[0]
        = -d $tmpldir ? $tmpldir : catdir(dist_dir('GMS'), 'templates');

    # Session
    #$app->sessions->default_expiration(1800);
    #$app->sessions->cookie_name('gms');

    # Helpers
    if ($app->setup_helpers())
    {
        warn '[ERR] Failed to setup helper';
        exit 1;
    }

    # Hooks
    if ($app->setup_hooks())
    {
        warn '[ERR] Failed to setup hooks';
        exit 2;
    }

    # Plugins
    if ($app->setup_plugins())
    {
        warn '[ERR] Failed to setup plugins';
        exit 3;
    }

    # Router
    my @excludes
        = ("^\/manager\/sign_(in|out)\$", "^\/system\/time\/info\$/");

    if ($app->setup_routes(uri => $app->uri, excludes => \@excludes))
    {
        warn '[ERR] Failed to setup routes';
        exit 4;
    }

    $app->secrets($app->config->{secrets});

    return;
}

sub setup_logger
{
    my $app = shift;

    # Signal handling for logging
    catch_sig_warn(%{$app->log_settings});

    # Set log4perl logger
    $app->log(MojoX::Log::Log4perl->new("${\$app->home}/config/log.conf"));

    return 0;
}

sub setup_helpers
{
    my $app = shift;

    $app->helper(api_status         => sub { shift; api_status(@_); });
    $app->helper(get_api_status     => sub { shift; get_api_status(@_); });
    $app->helper(all_api_statuses   => sub { shift; all_api_statuses(@_); });
    $app->helper(clear_api_statuses => sub { shift; clear_api_statuses(); });

    $app->helper(
        inspect_lang => sub
        {
            my $c = shift;

            my $lang = $c->cookie('language');

            return $lang if (defined($lang));

            my $accept_lang = $c->req->headers->accept_language();

            if (!defined($accept_lang))
            {
                $lang = 'en';
                goto RETURN;
            }

            my @lang = split(/\s*(?:,|;)\s*/, $accept_lang);

            if (!scalar(@lang))
            {
                $lang = 'en';
                goto RETURN;
            }

            if ($lang[0] =~ m/^(?:ko|ko-KR)$/i)
            {
                $lang = 'ko';
            }
            else
            {
                $lang = 'en';
            }

        RETURN:
            $c->cookie(language => $lang);

            return $lang;
        }
    );

    return 0;
}

sub around_dispatch
{
    # :TODO 01/12/2016 03:50:09 PM: by P.G.
    # Look into all routes for checking non-exists.
    my ($next, $c) = @_;

    my $req_id = $c->req->request_id;
    my $path   = $c->req->url->path;

    warn "[DEBUG] around_dispatch: $c: $req_id: $path";

    if ($path =~ m/^\/api\//)
    {
        warn "[DEBUG] Request(client): ${\$c->tx->remote_address}";
        warn "[DEBUG] Request(method): ${\$c->req->method}";
        warn "[DEBUG] Request(url): ${\$c->req->url->path}";

        warn "[DEBUG] Request(session): ${\$c->dumper($c->session)}";
        warn "[DEBUG] Request(headers): ${\$c->dumper($c->req->headers)}";
        warn "[DEBUG] Request(cookie): ${\$c->dumper($c->req->cookie)}";
        warn "[DEBUG] Request(params): ${\$c->dumper($c->req->params)}";
        warn "[DEBUG] Request(json): ${\$c->dumper($c->req->json)}";
    }

    $c->mem->record('Starting');

    my $rv = $next->();

    $c->mem->record('Finished');

    if ($c->mem->state()->[-1]->[-1] - $c->mem->state()->[0]->[-1] > 10240)
    {
        warn sprintf("[WARN] High memory usage detected: %s\n%s",
            $path, $c->mem->report,);
    }

    return $rv;
}

sub around_action
{
    my ($next, $c, $action, $last) = @_;

    my $path = $c->req->url->path;

    if ($path =~ m/^\/api\//
        && $c->stash('openapi.path')
        && !$c->openapi->cors_exchange->openapi->valid_input())
    {
        warn '[ERR] Invalid request';
        return;
    }

    my $rv = try
    {
        $next->();
    }
    catch
    {
        handle_exception($c, shift);
    };

    return $rv;
}

sub after_static
{
    my $c = shift;

    my $cache_control = '';

    if (ref($c->app->config->{cache_control}) eq 'HASH')
    {
        while (my ($key, $value) = each(%{$c->app->config->{cache_control}}))
        {
            next if ($key eq 'force');

            $cache_control .= "$key=$value, ";
        }
    }

    $cache_control .= 'must-revalidate';

    if ($c->app->mode ne 'development'
        || $c->app->config->{cache_control}->{force})
    {
        $c->res->headers->cache_control($cache_control);
    }
}

sub setup_hooks
{
    my $app = shift;

    $app->hook(around_dispatch => \&around_dispatch);
    $app->hook(around_action   => \&around_action);
    $app->hook(after_static    => \&after_static);

    return 0;
}

sub setup_plugins
{
    my $app = shift;

    # AuthHelper
    $app->plugin('GMS::Plugin::AuthHelper');

    # EncryptHelper
    $app->plugin('GMS::Plugin::EncryptHelper');

    # TreeManager
    $app->plugin('GMS::Plugin::TreeManager');

    # OpenAPI
    $app->plugin('GMS::Plugin::OpenAPI');

    # SecureCORS
    $app->plugin('SecureCORS');

    # Config
    $app->plugin('Config', {file => "${\$app->home}/config/gms.conf"});

    # OpenAPI
    my $spec = $app->write_spec();

    warn "[DEBUG] OpenAPI Spec: $spec";

    $app->plugin(
        'OpenAPI',
        {
            url                    => $spec,
            schema                 => 'v3',
            add_preflighted_routes => 1
        }
    );

    $app->plugin(
        'SwaggerUI' => {
            route => $app->routes->any('api'),
            url   => '/api/v3',
            title => 'GMS App',
        }
    );

    # ref: https://github.com/jhthorsen/mojolicious-plugin-openapi/pull/102
    #$app->defaults(openapi_cors_allow_credentials => 'true');
    $app->defaults(openapi_cors_allowed_origins => [qr/.*/]);

    return 0;
}

sub setup_routes
{
    my $app  = shift;
    my %args = @_;

    my $router   = $app->routes;
    my $uri      = $args{uri};
    my $excludes = $args{excludes} // [];

    if ($app->_setup_routes(
        root     => $app->auth_route,
        uri      => $uri,
        excludes => $excludes
    ))
    {
        return -1;
    }

    return 0;
}

sub _setup_routes
{
    my $app  = shift;
    my %args = @_;

    my $route    = $args{root};
    my $uri      = $args{uri};
    my $excludes = $args{excludes} // [];

    if (!defined($route))
    {
        warn '[ERR] Undefined root route';
        return -1;
    }

    if (ref($uri) ne 'HASH')
    {
        warn '[ERR] Invalid URI';
        return -1;
    }

    my @q = ({k => undef, v => \$uri});

    while (my $t = pop(@q))
    {
        if (ref(${$t->{v}}) eq 'HASH')
        {
            while (my ($k, $v) = each(%{${$t->{v}}}))
            {
                push(
                    @q,
                    {
                        k => defined($t->{k}) ? "$t->{k}/$k" : "/$k",
                        v => \$v
                    }
                );
            }
        }
        elsif (ref(${$t->{v}}) eq 'ARRAY')
        {
            push(
                @q,
                {
                    k => $t->{k},
                    v => \${$t->{v}}->[0],
                    m => ${$t->{v}}->[2] // 'POST',
                }
            );
        }
        else
        {
            $app->log->debug("URI $t->{k} => ${$t->{v}}: $t->{m}");

            if (grep { $t->{k} =~ m/$_/; } @{$excludes})
            {
                $route->post("/api/$t->{k}")->to(${$t->{v}});
                next;
            }

            $route->any([uc($t->{m})] => "/api/$t->{k}")->to(
                ${$t->{v}},
                'cors.methods'     => uc($t->{m}),
                'cors.origin'      => '*',
                'cors.credentials' => 1,
                'cors.headers'     => 'Authorization, Content-Type',
            );

            $route->cors("/api/$t->{k}")->to(
                ${$t->{v}},
                'cors.methods'     => uc($t->{m}),
                'cors.origin'      => '*',
                'cors.credentials' => 1,
                'cors.headers'     => 'Authorization, Content-Type',
            );
        }
    }

    return 0;
}

sub handle_exception
{
    my $c = shift;
    my $e = shift;

    if (ref($e) eq 'Mojo::Exception')
    {
        warn sprintf("[ERR] %s", $e->trace->inspect->verbose(1))
            if (ref($c->app) eq 'GMS');    # Monkey patch for unit-testing

        my @trace = split(/\n+/, $e->message);

        my %rv = (
            status  => 500,
            msg     => shift(@trace),
            return  => 'false',
            success => 0,
        );

        if ($c->app->mode eq 'development')
        {
            $rv{trace} = \@trace;
        }

        $c->render(%rv, json => undef);
    }
    elsif (ref($e) =~ m/^GMS::Exception/)
    {
        if ($c->app->mode eq 'development')
        {
            warn "[ERR] ${\$e->stringify(trace => 1)}";
        }
        else
        {
            warn "[ERR] ${\$e->status}: ${\$e->message}";
        }

        my %rv = (
            status  => $e->status,
            msg     => $e->message,
            return  => 'false',
            success => 0,
        );

        if ($c->app->mode eq 'development')
        {
            $rv{trace} = $e->stringify(trace => 1);
        }

        $c->render(%rv, json => undef);
    }
    else
    {
        $e = ref($e) ? $e : Mojo::Exception->new($e)->trace;

        warn "[ERR] $e";

        my @trace = split(/\n+/, $e);

        my %rv = (
            status  => ($e =~ m/^(?<status>\d)+/ ? $+{status} : 500),
            msg     => shift(@trace),
            return  => 'false',
            success => 0,
        );

        if ($c->app->mode eq 'development')
        {
            $rv{trace} = \@trace;
        }

        $c->render(%rv, json => undef);
    }

    return $e;
}

1;

=encoding utf8

=head1 NAME

GMS - Gluesys Management System

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 C<< uri >>

=head1 METHODS

=head2 C<< undef = GMS->startup() >>

=head2 C<< $rv = GMS->setup_logger() >>

=head2 C<< $rv = GMS->setup_helpers() >>

=head2 C<< $rv = GMS->setup_hooks() >>

=head2 C<< $rv = GMS->setup_plugins() >>

=head2 C<< $rv = GMS->setup_routes() >>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
