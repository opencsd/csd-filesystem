package GMS::Controller::Share::SMB::Samba;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Fcntl qw();
use Guard;
use Mouse::Util::TypeConstraints;

use GMS::SMB::Samba::Types;
use GMS::SMB::Samba::VFS::GlusterFS;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Share::Protocol';

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::File';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '+protocol' => (default => 'SMB',);

has '+service' => (default => 'smb',);

has '+config_model' => (default => 'Global',);

has '+section_model' => (default => 'Section',);

has '+rights_table' => (
    default => sub
    {
        {
            Default => [qw|readonly read/write|],

            # :TODO 07/21/2019 07:51:02 PM: by P.G.
            # support 'partially'
            Zone  => [qw|allow deny|],
            User  => [qw|auto admin readonly read/write deny|],
            Group => [qw|auto readonly read/write deny|],
        };
    },
);

has '+aggregator_file' => (default => '/etc/samba/smb.conf',);

has 'reserved_names' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [qw/global homes printers/]; },
);

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
    $models->{Section} = 'GMS::Model::Cluster::SMB::Samba::Section';
    $models->{Global}  = 'GMS::Model::Cluster::SMB::Samba::Global';

    return $models;
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub get_account_access
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        User => {
            isa => 'Str',
            xor => 'Group',
        },
        Group => {
            isa => 'Str',
        },

        # for permission validation on filesystem layer
        Path => {
            isa      => 'Str',
            optional => 1,
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

    my $section = $self->_get_section($params->{Name});

    if (!defined($section))
    {
        $self->throw_exception(
            'NotFound',
            resource => "${\$self->protocol} share",
            name     => $params->{Name},
        );
    }

    my $type = exists($params->{User}) ? 'user' : 'group';

    my $access
        = $section->get_account_access($type => $params->{ucfirst($type)});

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_GET_ACCESS_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name},
            target   => $access->{account},
            right    => $access->{right},
        ],
    );

    $self->publish_event();

    $self->stash(
        json => {
            Name           => $section->name,
            ucfirst($type) => $access->{account},
            Right          => $access->{right},
        },
    );
}

sub set_account_access
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        User => {
            isa => 'Str',
            xor => [qw/Group/],
        },
        Group => {
            isa => 'Str',
        },
        Right => {
            isa    => 'SMB_USER_ACCESS | SMB_GROUP_ACCESS',
            coerce => 1,
        },
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

    my $section = $self->_get_section($params->{Name});

    if (!defined($section))
    {
        $self->throw_exception(
            'NotFound',
            resource => "${\$self->protocol} share",
            name     => $params->{Name},
        );
    }

    my $type = exists($params->{User}) ? 'user' : 'group';

    my $access = $section->set_account_access(
        $type => $params->{ucfirst($type)},
        right => $params->{Right},
    );

    $section->store_to_file();

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_SET_ACCESS_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name},
            target   => $params->{ucfirst($type)},
            right    => $params->{Right},
        ],
    );

    $self->publish_event();

    $self->stash(json => $params);
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
            isa    => 'SMB_NETWORK_ACCESS',
            coerce => 1,
        },
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

    my $section = $self->_get_section($params->{Name});

    if (!defined($section))
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

    $section->set_network_access(
        zone  => $zone,
        right => $params->{Right},
    );

    $section->store_to_file();

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

    $self->stash(json => $params);
}

sub clients
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
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

    my $section = $self->_get_section($params->{Name});

    if (!defined($section))
    {
        $self->throw_exception(
            'NotFound',
            resource => "${\$self->protocol} share",
            name     => $params->{Name},
        );
    }

    my @rv;
    my $stats = $section->client_stats();

    if (ref($stats) eq 'HASH'
        && ref($stats->{$params->{Name}}) eq 'ARRAY')
    {
        @rv = sort { $a->{pid} <=> $b->{pid}; } @{$stats->{$params->{Name}}};
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_GET_CLIENTS_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name}
        ],
    );

    $self->stash(json => \@rv);
}

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around '_get_section' => sub
{
    my $orig = shift;
    my $self = shift;
    my @args = @_;

    foreach my $reserved (@{$self->reserved_names})
    {
        die "\"$reserved\" is reserved name for internal use"
            if ($args[0] eq $reserved);
    }

    my ($share, $section) = $self->$orig(@args);

    if (defined($section) && $share->desc ne ($section->comment // ''))
    {
        $section->comment($share->desc);
    }

    return ($share, $section);
};

around 'reload' => sub
{
    my $orig = shift;
    my $self = shift;

    my $global = $self->get_model('Global')->find();

    if (!defined($global))
    {
        warn '[WARN] Section does not exist: global';
    }

    return $self->$orig(@_);
};

augment 'set_config' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Active => {
            isa      => enum([qw/on off/]),
            optional => 1,
        },
        Security => {
            isa      => 'SMB_SECURITY',
            optional => 1,
        },
        Server_String => {
            isa      => 'Str',
            optional => 1,
        },
        Workgroup => {
            isa      => 'Str',
            optional => 1,
        },
        NTLM_Auth => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        Bind_Interfaces_Only => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        Interfaces => {
            isa      => 'ArrayRef',
            optional => 1,
        },
        Socket_Options => {
            isa      => 'SMB_SOCKOPTS',
            optional => 1,
        },
        Large_Readwrite => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        Aio_Read_Size => {
            isa      => 'Int',
            optional => 1,
        },
        Aio_Write_Size => {
            isa      => 'Int',
            optional => 1,
        },
        Max_Xmit => {
            isa      => 'Int',
            optional => 1,
        },
        Stat_Cache => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        Max_Stat_Cache_Size => {
            isa      => 'Int',
            optional => 1,
        },
    };

    return $self->validate($rule, $params);
};

augment 'update' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        Available => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        Read_Only => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        Admin_Users => {
            isa      => 'ArrayRef',
            optional => 1,
        },
        Guest_Ok => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        Browseable => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        Kernel_Oplocks => {
            isa      => 'Str',
            optional => 1,
        },
    };

    return $self->validate($rule, $params);
};

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _enable
{
    my $self = shift;

    my $share   = $self->stash('share');
    my $section = $self->stash('section');
    my $volume  = $self->stash('volume');

    # :TODO 08/01/2019 01:11:55 AM: by P.G.
    # Add VFS object to $section instance if it is serviced on a GlusterFS volume

    if ($volume->{Volume_Type} eq 'Local'
        || $volume->{Volume_Type} eq 'External')
    {
        my $path = sprintf(
            '/export/%s/%s/%s',
            $share->pool,
            $share->volume,
            $share->path
        );

        $path =~ s/\/+/\//g;
        $path =~ s/\/+$//g;

        $section->path($path);
    }
    elsif ($volume->{Volume_Type} eq 'Gluster'
        && !$section->vfs_enabled(name => 'glusterfs'))
    {
        my $vfs_glfs = GMS::SMB::Samba::VFS::GlusterFS->new(
            section => $section,
            volume  => $share->volume,
        );

        $section->enable_vfs(vfs => $vfs_glfs);
        $section->kernel_share_modes('no');
        $section->path($share->path);
    }
}

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

                if ($line =~ m/^include\s*=\s*.+\/$file$/)
                {
                    $found = 1;

                    pop(@lines) if ($lines[-1] =~ m/^#+\s*$name\s*/);
                    next;
                }

                push(@lines, $line);
            }

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

GMS::Controller::Share::SMB::Samba - GMS SMB share management API controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

