package GMS::Controller::Cluster::Time;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return;

use GMS::Cluster::HTTP;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Time';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'http' => (
    is      => 'ro',
    isa     => 'GMS::Cluster::HTTP',
    default => sub { GMS::Cluster::HTTP->new(); },
    lazy    => 1,
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub config
{
    my $self   = shift;
    my $params = $self->req->json;

    my $ci = $self->etcd->get_key(key => '/ClusterInfo', format => 'json');

    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/api/system/time/config',
        body => $params,
    );

    my @failures;

    foreach my $resp (@resps)
    {
        next if (!defined($resp) || $resp->status == 204);

        warn "[ERR] Failed to config time: ${\$self->dumper($resp)}";

        push(@failures,
            sprintf('%s: %s', $resp->hostname, $resp->msg(trace => 0)));
    }

    $self->throw_error('Failed to config time: ' . join("\n", @failures))
        if (@failures);

    api_status(
        scope    => 'cluster',
        category => 'SYSTEM',
        level    => 'INFO',
        code     => TIME_CONFIG_OK,
    );

    $self->publish_event();
    $self->app->run_checkers();

    $self->render(status => 204, json => undef);
}

sub test
{
    my $self   = shift;
    my $params = $self->req->json;

    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/api/system/time/test',
        body => $params,
    );

    my @failures;

    foreach my $resp (@resps)
    {
        if (defined($resp) && $resp->status != 204)
        {
            warn "[ERR] Failed to test time: ${\$self->dumper($resp)}";

            push(@failures,
                sprintf('%s: %s', $resp->hostname, $resp->msg(trace => 0)));
        }
    }

    $self->throw_error('Failed to test time: ' . join("\n", @failures))
        if (@failures);

    $self->render(status => 204, json => undef);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Time - GMS API controller for cluster time management

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

