package GMS::Controller::Cluster::CTDB;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Cluster::HTTP;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::CTDB';

#---------------------------------------------------------------------------
#   Overwritten Methods
#---------------------------------------------------------------------------
sub control
{
    my $self   = shift;
    my $params = $self->req->json;

    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/api/ctdb/control',
        body => $params,
    );

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        warn sprintf('[ERR] Failed to control CTDB: %s: %s',
            $resp->status, $resp->msg,);

        $self->throw_error(
            level => 'ERROR',
            code  => 'CLST_CTDB_CONTROL_FAILURE',
        );
    }

    warn "[INFO] CTDB is controlled: $params->{Command}";

    $self->api_status(
        level => 'INFO',
        code  => 'CLST_CTDB_CONTROL_OK',
    );

    $self->render(json => {});
}

sub reload
{
    my $self   = shift;
    my $params = $self->req->json;

    my @resps = GMS::Cluster::HTTP->new->request(
        uri     => '/api/ctdb/reload',
        body    => $params,
        timeout => 180,
    );

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        warn sprintf('[ERR] Failed to reload CTDB: %s: %s',
            $resp->status, $resp->msg,);

        $self->throw_error(
            level => 'ERROR',
            code  => 'CLST_CTDB_RELOAD_FAILURE',
        );
    }

    warn '[INFO] CTDB is reloaded';

    $self->api_status(
        level => 'INFO',
        code  => 'CLST_CTDB_RELOAD_OK',
    );

    $self->render(json => {});
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::CTDB

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
