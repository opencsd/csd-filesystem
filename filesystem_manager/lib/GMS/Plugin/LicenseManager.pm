package GMS::Plugin::LicenseManager;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Coro;
use Mojo::IOLoop;

use GMS::API::Return;
use GMS::Common::Logger;
use GMS::System::License;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'interval' => (
    is      => 'rw',
    isa     => 'Int',
    default => 10,
);

has 'handler' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { GMS::System::License->new() },
);

has 'stager' => (
    is      => 'ro',
    isa     => 'GMS::Cluster::Stage',
    default => sub { GMS::Cluster::Stage->new(); },
);

has 'stage_data' => (
    is      => 'rw',
    default => sub { {stage => undef, scope => undef, data => undef}; },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub register
{
    my ($self, $app, $conf) = @_;

    Mojo::IOLoop->recurring(
        $self->interval => sub
        {
            async
            {
                $Coro::current->{desc} = 'license-manager';

                catch_sig_warn(%{$app->log_settings});

                #Coro::on_enter
                #{
                #    warn "[DEBUG] on_enter: $Coro::current->{desc}";
                #};

                #Coro::on_leave
                #{
                #    warn "[DEBUG] on_leave: $Coro::current->{desc}";
                #};

                my ($stage, $scope, $data)
                    = $self->stager->get_represent_stage();

                $self->stage_data(
                    {
                        stage => $stage,
                        scope => $scope,
                        data  => $data,
                    }
                );
            }
        }
    );

    $app->hook(
        before_routes => sub
        {
            my $c   = shift;
            my $uri = $c->req->url->path;

            return if (!$c->req->url->path->contains('/api'));

            my $policy = $self->handler->get_policy_from_license(
                stage => $self->stage_data->{stage},
                uri   => $uri,
            );

            return if (uc($policy) ne 'DENY');

            warn "[WARN] '$uri' is denided according to the license";

            api_status(
                category => 'LICENSE',
                level    => 'WARN',
                code     => LICENSE_DENIED,
                msgargs  => [target => $uri],
            );

            $c->app->gms_new_event(locale => $c->cookie('language'));

            $c->render(
                json => {
                    return     => 'false',
                    msg        => "'$uri' is denided according to license",
                    entity     => [],
                    statuses   => [],
                    stage_info => {
                        stage => $self->stage_data->{stage},
                        data  => $self->stage_data->{data},
                    },
                    lang => $c->cookie('language'),
                },
                format => 'json'
            );

            return;
        }
    );

    warn "[INFO] ${\__PACKAGE__} plugin is registered";

    return;
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::License - GMS license manager plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
