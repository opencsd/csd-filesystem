package GMS::Controller::CTDB;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Sys::Hostname::FQDN qw/short/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
# prerequisite for GMS::CTDB::Configurable
has 'internal_path' => (
    is      => 'ro',
    default => '/home/__internal',
);

# prerequisite for GMS::CTDB::Configurable
has 'private_path' => (
    is      => 'ro',
    default => '/mnt/private',
);

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::CTDB::Configurable';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override build_models => sub
{
    my $self = shift;

    return {VIP => 'GMS::Model::Cluster::Network::VIP',};
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub control
{
    my $self   = shift;
    my $params = $self->req->json;

    my $status = $self->control_ctdb(action => $params->{Command});

    if ($status)
    {
        warn '[ERR] Failed to control CTDB';

        $self->throw_error(
            level => 'ERROR',
            code  => 'CLST_CTDB_CONTROL_FAILURE',
        );
    }

    warn "[INFO] CTDB status has updated: $params->{Command}";

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

    my @reloaded;

    # find all VIP groups that this node belonged and then
    # - add all nodes of this groups
    # - add all IP addrs ofthis group
    my $host = short();

    foreach my $group ($self->get_model('VIP')->list())
    {
        my $model = $self->get_model('VIP')->find($group);

        if (!defined($model))
        {
            $self->throw_exception(
                'NotFound',
                resource => 'VIP group',
                name     => $group,
            );
        }

        if (!$model->host_exists($host))
        {
            warn
                "[DEBUG] This host is not a member of this VIP group: $group: $host";
            next;
        }

        $model->reload();

        push(@reloaded, $model->to_hash());
    }

    warn '[INFO] CTDB has reloaded';

    $self->api_status(
        level => 'INFO',
        code  => 'CLST_CTDB_RELOAD_OK',
    );

    $self->render(json => \@reloaded);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::CTDB - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
