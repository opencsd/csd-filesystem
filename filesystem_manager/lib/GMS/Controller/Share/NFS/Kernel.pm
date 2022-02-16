package GMS::Controller::Share::NFS::Kernel;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::NFS::Type;

use GMS::System::Service qw/service_status control_service/;
use Guard;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Share::Protocol';

#---------------------------------------------------------------------------
#   Overrided Attributes
#---------------------------------------------------------------------------
has '+protocol' => (default => 'NFS',);

has '+service' => (default => 'nfs-server',);

has '+config_model' => (default => 'Sysconfig',);

has '+section_model' => (default => 'Export',);

has '+rights_table' => (
    default => sub
    {
        {
            Default => [qw|deny readonly read/write|],
            Zone    => [qw|deny readonly read/write|],
        };
    },
);

has '+hook' => (default => sub { \&_enable; },);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override build_models => sub
{
    my $self = shift;

    my $models = super();

    $models->{Sysconfig} = 'GMS::Model::NFS::Kernel::Sysconfig';
    $models->{Export}    = 'GMS::Model::NFS::Kernel::Export';

    return $models;
};

override 'control' => sub
{
    my $self = shift;
    my %args = @_;

    if (service_status(service => 'nfs-ganesha') == 0
        && control_service(service => 'nfs-ganesha', action => 'stop'))
    {
        $self->throw_error(message => 'Failed to stop nfs-ganesha');
    }

    return super();
};

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub _enable
{
    my $self = shift;

    my $share  = $self->stash('share');
    my $export = $self->stash('section');
    my $volume = $self->stash('volume');

    if ($volume->{Volume_Type} =~ m/^(?:Gluster|External)$/i)
    {
        # :TODO 10/22/2019 11:11:05 AM: by P.G.
        # Not supported
        $self->throw_exception(
            'NotSupported',
            message => sprintf('NFS cannot be serviced with %s type volume',
                $volume->{Volume_Type})
        );
    }

    if ($volume->{Volume_Type} eq 'Local')
    {
        my $path = sprintf(
            '/export/%s/%s/%s',
            $share->pool,
            $share->volume,
            $share->path
        );

        $path =~ s/\/+/\//g;
        $path =~ s/\/+$//g;

        $export->path($path);
    }
}

sub set_network_access
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        Zone => {
            isa => 'Str',
        },
        Right => {
            isa => 'GMS::NFS::Type::Access',
        },
        Squash => {
            isa => 'GMS::NFS::Type::Squash',
        }
    };

    $params = $self->validate($rule, $params);

    if ($self->lock(scope => 'Share'))
    {
        $self->throw_error(message => 'Failed to get API lock: Share');
    }

    scope_guard
    {
        if ($self->unlock(scope => 'Share'))
        {
            $self->throw_error(
                message => 'Failed to release API lock: Share');
        }
    };

    my $export = $self->_get_section($params->{Name});

    if (!defined($export))
    {
        $self->throw_exception(
            'NotFound',
            resource => "${\$self->protocol} share",
            name     => $params->{Name},
        );
    }

    my $zone = $self->get_model('Zone')->find($params->{Zone});

    if (!defined($zone))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'Network zone',
            name     => $params->{Zone},
        );
    }

    $export->set_network_access(
        zone   => $zone,
        right  => $params->{Right},
        squash => $params->{Squash},
    );

    $export->store_to_file();

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_SET_ACCESS_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name},
            target   => $params->{Zone},
            right    => $params->{Right},
        ],
    );

    $self->publish_event();

    $self->stash(json => $export->to_hash());
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Share::NFS::Kernel - GMS Kernel NFS share management API controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

