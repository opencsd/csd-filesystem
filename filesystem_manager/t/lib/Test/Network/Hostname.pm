package Test::Network::Hostname;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use Sys::Hostname::FQDN qw/short/;

has 'namespace' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Mock::Controller',
);

has 'cntlr' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Network',
);

has 'hostname' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
);

has 'uris' => (
    is         => 'ro',
    isa        => 'ArrayRef',
    auto_deref => 1,
    lazy       => 1,
    default    => sub
    {
        my $self = shift;

        [
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'hostname',
                uri       => '/api/network/hostname',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'hostname_update',
                uri       => '/api/network/hostname/update',
            },
        ];
    }
);

sub test_startup
{
    my $self = shift;

    $self->next::method(@_);

    my $t = $self->t;

    foreach my $uri ($self->uris)
    {
        $t->app->routes->post($uri->{uri})->to(
            namespace  => $uri->{namespace},
            controller => $uri->{cntlr},
            action     => $uri->{action},
        );
    }
}

sub test_shutdown
{
    my $self = shift;

    $self->next::method(@_);

    $self->unmock_data();
}

sub test_hostname_info : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/hostname');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Hostname is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_HOSTNAME_INFO_OK')
        ->json_is('/entity/Pretty'   => $self->hostname)
        ->json_is('/entity/Static'   => $self->hostname);

#    explain($t->tx->res->json);
}

sub test_hostname_update : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/hostname/update');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_is('/statuses/1/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: (Static|Pretty)/)
        ->json_like(
        '/statuses/1/message' => qr/Missing parameter: (Static|Pretty)/);

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/hostname/update',
        json => {
            Pretty => "${\$self->hostname}-pretty",
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Hostname is updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_HOSTNAME_UPDATE_OK')
        ->json_is('/entity/Pretty'   => "${\$self->hostname}-pretty");

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/hostname/update',
        json => {
            Pretty => '',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Hostname is updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_HOSTNAME_UPDATE_OK')
        ->json_is('/entity/Pretty'   => '');

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/hostname/update',
        json => {
            Static => "${\$self->hostname}-static",
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Hostname is updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_HOSTNAME_UPDATE_OK')
        ->json_is('/entity/Static'   => "${\$self->hostname}-static");

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/hostname/update',
        json => {
            Static => $self->hostname,
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Hostname is updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_HOSTNAME_UPDATE_OK')
        ->json_is('/entity/Static'   => $self->hostname);

#    explain($t->tx->res->json);
}

1;

=encoding utf8

=head1 NAME

Test::Network::Hostname - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

