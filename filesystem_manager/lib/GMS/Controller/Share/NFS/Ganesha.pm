package GMS::Controller::Share::NFS::Ganesha;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Fcntl qw//;

use GMS::NFS::Type;
use GMS::NFS::Ganesha::Type;
use GMS::NFS::Ganesha::FSAL::Gluster;
use GMS::NFS::Ganesha::FSAL::VFS;
use Mouse::Util::TypeConstraints;

use GMS::System::Service qw/service_status control_service/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Share::Protocol';

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::File';

#---------------------------------------------------------------------------
#   Overrided Attributes
#---------------------------------------------------------------------------
has '+protocol' => (default => 'NFS',);

has '+service' => (default => 'nfs-ganesha',);

has '+config_model' => (default => 'Default',);

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

has '+aggregator_file' => (default => '/etc/ganesha/ganesha.conf',);

has '+hook' => (default => sub { \&_enable; },);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override build_models => sub
{
    my $self = shift;

    my $models = super();

    $models->{Share}   = 'GMS::Model::Cluster::Share';
    $models->{Zone}    = 'GMS::Model::Cluster::Network::Zone';
    $models->{Core}    = 'GMS::Model::Cluster::NFS::Ganesha::Core';
    $models->{Default} = 'GMS::Model::Cluster::NFS::Ganesha::Default';
    $models->{MDCache} = 'GMS::Model::Cluster::NFS::Ganesha::MDCache';
    $models->{Export}  = 'GMS::Model::Cluster::NFS::Ganesha::Export';

    return $models;
};

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
augment 'set_config' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Active => {
            isa      => enum([qw/on off/]),
            optional => 1,
        },

#        Access_Type => {
#
#        },
#        Protocols => {
#
#        },
#        Transports => {
#
#        },
#        Anonymous_UID => {
#
#        },
#        Anonymous_GID => {
#
#        },
#        SecType => {
#
#        },
#        PrivilegedPort => {
#
#        },
#        Manage_GIDs => {
#
#        },
#        Squash => {
#
#        },
#        NFS_Commit => {
#
#        },
#        Delegations => {
#
#        },
#        Attr_Expiration_Time => {
#
#        },
    };

    return $self->validate($rule, $params);
};

override 'control' => sub
{
    my $self = shift;
    my %args = @_;

    if (service_status(service => 'nfs-server') == 0
        && control_service(service => 'nfs-server', action => 'stop'))
    {
        $self->throw_error(message => 'Failed to stop nfs-server');
    }

    return super();
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub _enable
{
    my $self = shift;

    my $share  = $self->stash('share');
    my $export = $self->stash('section');
    my $volume = $self->stash('volume');

    my $fsal;

    if ($volume->{Volume_Type} eq 'Local')
    {
        $fsal = GMS::NFS::Ganesha::FSAL::VFS->new(export => $export);

        $export->enable_fsal(fsal => $fsal);

        my $path = sprintf(
            '/export/%s/%s/%s',
            $share->pool,
            $share->volume,
            $share->path
        );

        $path =~ s/\/+/\//g;
        $path =~ s/\/+$//g;

        $export->path($path);
        $export->pseudo("/${\$share->name}");
    }
    elsif ($volume->{Volume_Type} eq 'Gluster')
    {
        $fsal = GMS::NFS::Ganesha::FSAL::Gluster->new(
            export  => $export,
            volume  => $share->volume,
            volpath => $share->path,
        );

        $export->enable_fsal(fsal => $fsal);

#        my $path = sprintf('/%s/%s', $share->volume, $share->path);
#
#        $path =~ s/\/+/\//g;
#        $path =~ s/\/+$//g;

        $export->path("/${\$share->name}");
        $export->pseudo("/${\$share->name}");
    }
    elsif ($volume->{Volume_Type} eq 'External')
    {
        # :TODO 10/22/2019 11:11:05 AM: by P.G.
        # Proxy FSAL
#        if ($volume->vpool->external_type eq 'NFS')
#        {
#           $fsal = GMS::NFS::Ganesha::FSAL::Proxy->new(
#           );
#
#           $export->enable_fsal(fsal => $fsal);
#        }
#        else
#        {
        my $path = sprintf(
            '/export/%s/%s/%s',
            $share->pool,
            $share->volume,
            $share->path
        );

        $path =~ s/\/+/\//g;
        $path =~ s/\/+$//g;

        $export->path($path);
        $export->pseudo("/${\$share->name}");

#        }
    }

    return;
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
            isa => 'GMS::NFS::Ganesha::Type::Squash',
        }
    };

    $params = $self->validate($rule, $params);

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

    $params->{Right}
        = $params->{Right} eq 'read/write' ? 'RW'
        : $params->{Right} eq 'readonly'   ? 'RO'
        :                                    'None';

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

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _handle_aggregator
{
    my $self = shift;
    my $file = shift;

    my ($name, $ext) = ($file =~ m/^(.+)\.(.+)$/);

    my $found = 0;

    handle_file(
        path     => $self->aggregator_file,
        mode     => '+<',
        lock     => Fcntl::LOCK_EX,
        callback => sub
        {
            my ($path, $fh) = @_;

            my @lines = ();

            while (my $line = <$fh>)
            {
                chomp($line);

                $line =~ s/(?:^\s+|\s+$)//g if ($line !~ m/^\s*#/);

                if ($line =~ m/^\s*%include\s+(?:['"]*).+$file(?:['"]*)$/)
                {
                    $found = 1;

                    pop(@lines) if ($lines[-1] =~ m/^#+\s*$name\s*/);
                    next;
                }

                push(@lines, $line);
            }

#            warn "[INFO] AGGREGATOR: ${\$self->dumper(\@lines)}";

            return if (!$found);

            seek($fh, 0, Fcntl::SEEK_SET)
                || die "Failed to seek file: ${\$self->aggregator_file}: $!";

            my $empty = 0;

            for (my $i = 0; $i < @lines; $i++)
            {
                $empty = $lines[$i] =~ m/^\s*$/ ? $empty + 1 : 0;

                next if ($empty > 1);

                print $fh "$lines[$i]\n";
            }

            truncate($fh, tell($fh))
                || die
                "Failed to truncate file: ${\$self->aggregator_file}: $!";
        }
    );

    return $found;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Share::NFS::Ganesha - GMS NFS-ganesha share management API controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

