package GMS::Controller::Cluster::Power;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Power';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
around 'shutdown' => sub
{
    my $orig = shift;
    my $self = shift;

    my @mds = grep { $_ !~ m/-m$/; } $self->etcd->get_mds();
    my @ds  = grep { $_ !~ m/-m$/; } $self->etcd->get_ds();

    foreach my $targets (\@ds, \@mds)
    {
        my @resps = GMS::Cluster::HTTP->new->request(
            targets => [
                map {
                    {
                        host => $_,
                        uri  => '/api/system/power/shutdown',
                        body => $self->req->json,
                    }
                } @{$targets}
            ],
            excludes => {self => 1},
        );

        my @failures;

        foreach my $resp (@resps)
        {
            next if (!defined($resp) || $resp->status == 204);

            warn "[ERR] Failed to shutdown: ${\$self->dumper($resp)}";

            push(@failures,
                sprintf('%s: %s', $resp->hostname, $resp->msg(trace => 0)));
        }

        $self->throw_error('Failed to shutdown: ' . join("\n", @failures))
            if (@failures);
    }

    $self->$orig();

    $self->render(status => 204, json => undef);
};

around 'reboot' => sub
{
    my $orig = shift;
    my $self = shift;

    my @mds = grep { $_ !~ m/-m$/; } $self->etcd->get_mds();
    my @ds  = grep { $_ !~ m/-m$/; } $self->etcd->get_ds();

    foreach my $targets (\@ds, \@mds)
    {
        my @resps = GMS::Cluster::HTTP->new->request(
            targets => [
                map {
                    {
                        host => $_,
                        uri  => '/api/system/power/reboot',
                        body => $self->req->json,
                    }
                } @{$targets}
            ],
            excludes => {self => 1},
        );

        my @failures;

        foreach my $resp (@resps)
        {
            next if (!defined($resp) || $resp->status == 204);

            warn "[ERR] Failed to shutdown: ${\$self->dumper($resp)}";

            push(@failures,
                sprintf('%s: %s', $resp->hostname, $resp->msg(trace => 0)));
        }

        $self->throw_error('Failed to shutdown: ' . join("\n", @failures))
            if (@failures);
    }

    $self->$orig();

    $self->render(status => 204, json => undef);
};

sub cancel
{
    my $self   = shift;
    my $params = $self->req->json;

    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/api/system/power/cancel',
        body => $params,
    );

    my @failures;

    foreach my $resp (@resps)
    {
        next if (!defined($resp) || $resp->status == 204);

        warn sprintf('[ERR] Failed to cancel power operations: %s',
            $self->dumper($resp));

        push(@failures,
            sprintf('%s: %s', $resp->hostname, $resp->msg(trace => 0)));
    }

    $self->throw_error('Failed to shutdown: ' . join("\n", @failures))
        if (@failures);

    $self->render(status => 204, json => undef);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Power - GMS API controller for power management

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

