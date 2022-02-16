package GMS::Controller;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use MouseX::Foreign;
use namespace::clean -except => 'meta';

use GMS::API::Return;
use GMS::Validator;
use Memory::Usage;
use Module::Load;
use Module::Loaded;
use Mojo::Base;
use Scalar::Util qw/blessed/;
use Sys::Hostname::FQDN;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'Mojolicious::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'validator' => (
    is      => 'ro',
    isa     => 'GMS::Validator',
    default => sub { GMS::Validator->new() },
    handles => {
        validate => 'validate'
    }
);

has 'models' => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    lazy    => 1,
    builder => 'build_models',
);

has 'mem' => (
    is      => 'ro',
    isa     => 'Memory::Usage',
    lazy    => 1,
    default => sub { Memory::Usage->new(); },
);

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::Exceptionable', 'GMS::Role::Lockable';

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'render' => sub
{
    my $orig = shift;
    my $self = shift;

    if ($self->req->url->path !~ m/^\/api\//
        || $self->req->url->path =~ m/^\/api\/v3/)
    {
        return $self->$orig(@_);
    }

    my %args = @_;

    #use Devel::StackTrace;
    #warn "[DEBUG] Response(trace): ${\Devel::StackTrace->new->as_string()}";

    # Set the response header 'Access-Control-Allow-Credentials' temporarily.
    $self->res->headers->header('Access-Control-Allow-Credentials' => 'true');

    warn "[DEBUG] Response(client): ${\$self->tx->remote_address}";
    warn "[DEBUG] Response(method): ${\$self->req->method}";
    warn "[DEBUG] Response(url): ${\$self->req->url->path}";

    #warn "[DEBUG] Response(session): ${\$self->dumper($self->session)}";
    warn "[DEBUG] Response(headers): ${\$self->dumper($self->res->headers)}";
    warn "[DEBUG] Response(cookie): ${\$self->dumper($self->cookie)}";

    #warn "[DEBUG] Response(stash): ${\$self->dumper($self->stash)}";
    warn "[DEBUG] Response(return): ${\$self->dumper(\%args)}";

    # Response is not routed by controller or callback
    # (default: 404 Not Found)
    #if (!$self->stash('mojo.routed'))
    #{
    #    warn "[DEBUG] Could not find a route: ${\$self->req->url->path}";
    #    return $self->$orig(%args);
    #}

    # OPTIONS method won't be handled addtionally by this hook
    if ($self->req->method eq 'OPTIONS')
    {
        warn "[DEBUG] Response(preflight): ${\$self->dumper(\%args)}";

        return $self->$orig(%args);
    }

    my $api_type;

    if (exists($args{openapi}) || exists($self->stash->{'openapi'}))
    {
        $api_type = 'openapi';
    }
    elsif (exists($args{json}) || exists($self->stash->{json}))
    {
        $api_type = 'json';
    }
    else
    {
        return $self->$orig(%args);
    }

    if (exists($args{'mojo.maybe'}) && $args{'mojo.maybe'})
    {
        delete($args{'mojo.maybe'});
    }

    $args{$api_type}
        = exists($args{$api_type})
        ? $args{$api_type}
        : $self->stash($api_type);

    warn "[DEBUG] $api_type: ${\$self->dumper($args{$api_type})}";

    # get matched controller/callback from URI call stack
    #warn "[DEBUG] Response(stack): ${\$self->dumper($self->match->stack)}";

    #my $cntlr = $self->match->stack->[$self->match->position];
    #
    #warn "[DEBUG] Response(cntlr): ${\$self->dumper($cntlr)}";
    #
    # an exception handling for callback routing
    # - for the routing point a callback, this callback stored to a controller
    #   object such as '{ cb => sub {...} }'
    #if (exists($cntlr->{cb}) && ref($cntlr->{cb}) eq 'CODE')
    #{
    #    warn "[DEBUG] Response(Callback): ${\$self->dumper(\%args)}";
    #    return $self->$orig(%args);
    #}

    # get all API statuses
    my @statuses = $self->clear_api_statuses($self->inspect_lang());

    warn "[DEBUG] Response(statuses): ${\$self->dumper(\@statuses)}";

    my $rep_status = undef;

    # find abnormal status that appeared first
    foreach my $s (@statuses)
    {
        $rep_status = $s;

        last if ($s->{level} =~ m/^(EMERGE|ALERT|CRIT|ERR)$/);
    }

    my $msg     = delete($args{msg});
    my $success = delete($args{success});
    my $retstr  = 'false';

    if (!defined($success))
    {
        my $wrong_statuses
            = (ref($rep_status) eq 'HASH'
                && exists($rep_status->{level})
                && $rep_status->{level} ne 'INFO');

        $success = $wrong_statuses ? 0 : 1;
        $msg = $rep_status->{message} if (defined($rep_status->{message}));
    }

    if ($success)
    {
        $success = $api_type eq 'openapi' ? 1 : \1;
        $retstr  = 'true';
        $msg     = 'Success' if (!defined($msg));
    }
    else
    {
        $success = $api_type eq 'openapi' ? 0 : \0;
        $retstr  = 'false';
        $msg     = 'Failure' if (!defined($msg));
    }

    $args{$api_type} = {
        success  => $success,
        msg      => $msg,
        entity   => $args{$api_type},
        statuses => \@statuses // [],

        # compatiblity for old API
        return => $retstr
    };

    # if entity is arrayref, response contains 'count' automatically
    if (ref($args{$api_type}->{entity}) eq 'ARRAY')
    {
        $args{$api_type}->{count}
            = scalar(@{$args{$api_type}->{entity}});

        if (exists($args{total}))
        {
            $args{$api_type}->{total} = delete($args{total});
        }
    }

    if (exists($args{return}))
    {
        $args{$api_type}->{return} = delete($args{return});
    }

    chomp($args{$api_type}->{msg})
        if (defined($args{$api_type}->{msg}));

    warn "[DEBUG] Response(API): ${\$self->dumper(\%args)}";

    return $self->$orig(%args);
};

around ['lock', 'unlock'] => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if (!exists($args{owner}))
    {
        $args{owner} = $self->req->request_id;
    }

    return $self->$orig(%args);
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub build_models
{
    my $self = shift;

    return {};
}

sub get_model
{
    my $self  = shift;
    my $alias = shift;

    if (!exists($self->models->{$alias}))
    {
        die sprintf('Could not find a model in this controller: %s: %s',
            blessed($self), $alias);
    }

    my $model = $self->models->{$alias};

    load($model) if (!is_loaded($model));

    return $model;
}

sub set_model
{
    my $self  = shift;
    my $alias = shift;
    my $name  = shift;

    return $self->models->{$alias} = $name;
}

sub publish_event
{
    my $self = shift;
    my %args = @_;

    return $self->app->gms_new_event(locale => $self->inspect_lang());
}

sub hostname
{
    return short();
}

#---------------------------------------------------------------------------
#   Lifecycle
#---------------------------------------------------------------------------
sub BUILDARGS
{
    my $class = shift;
    return Mojo::Base->new(@_);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller - Base controller for GMS

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item B<Item 1>

=item B<Item 2>

=item B<Item 3>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

