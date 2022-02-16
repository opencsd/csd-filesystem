package GMS::Controller::Share::Protocol;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Fcntl qw//;
use File::Path qw/make_path/;
use Guard;
use JSON qw/decode_json/;
use Mouse::Util::TypeConstraints;
use Storable qw/dclone/;
use Sys::Hostname::FQDN qw/short/;
use Try::Tiny;

use GMS::Account::AccountCtl;
use GMS::Cluster::Volume;
use GMS::System::Service qw/
    service_enabled enable_service disable_service
    service_status control_service
    /;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'protocol' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'service' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'config_model' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'section_model' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'rights_table' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'accountctl' => (
    is      => 'ro',
    isa     => 'GMS::Account::AccountCtl',
    default => sub { GMS::Account::AccountCtl->new(); },
    lazy    => 1,
);

# Default permission
has '_default_permission' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'deny',
);

has 'aggregator_file' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
);

has 'hook' => (
    is  => 'rw',
    isa => 'CodeRef',
);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override build_models => sub
{
    my $self = shift;

    my $models = super();

    $models->{Share} = 'GMS::Model::Share';
    $models->{Zone}  = 'GMS::Model::Network::Zone';

    return $models;
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub list
{
    my $self   = shift;
    my $params = $self->req->json;

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

    my @list;

    foreach my $name ($self->get_model($self->section_model)->list)
    {
        my $section = $self->get_model($self->section_model)->find($name);

        if (!defined($section))
        {
            warn "[ERR] Could not find section: $name";
            next;
        }

        push(@list, $section->to_hash);
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_LIST_OK',
        msgargs => [protocol => $self->protocol],
    );

    $self->stash(json => \@list);
}

sub info
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

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_INFO_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name},
        ],
    );

    $self->stash(json => $section->to_hash());
}

sub set_config
{
    my $self   = shift;
    my $params = $self->req->json;

    inner();

    my $model = $self->get_model($self->config_model)->find_or_create();

    $model->update(map { lc($_) => $params->{$_}; } keys(%{$params}));
    $model->store_to_file();

    if (exists($params->{Active}))
    {
        my $action = $params->{Active} eq 'off' ? 'stop' : 'start';

        if ($action eq 'start')
        {
            if (!service_enabled(service => $self->service)
                && enable_service(service => $self->service))
            {
                $self->throw_error(message =>
                        "Failed to enable service: ${\$self->service}");
            }
        }
        elsif ($action eq 'stop')
        {
            if (service_enabled(service => $self->service)
                && disable_service(service => $self->service))
            {
                $self->throw_error(message =>
                        "Failed to disable service: ${\$self->service}");
            }
        }

        if (control_service(service => $self->service, action => $action))
        {
            $self->throw_error(
                message => "Failed to $action service: ${\$self->service}");
        }
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_SET_CONFIG_OK',
        msgargs => [
            protocol => uc($self->protocol),
        ],
    );

    $self->publish_event();

    $self->stash(json => $model->to_hash());

    $model->unlock();
}

sub get_config
{
    my $self   = shift;
    my $params = $self->req->json;

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

    my $model = $self->get_model($self->config_model)->find_or_create();

    my $config = $model->to_hash();

    $config->{Active}
        = service_enabled(service => $self->service) ? 'on' : 'off';
    $config->{Status}
        = service_status(service => $self->service) ? 'off' : 'on';

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_GET_CONFIG_OK',
        msgargs => [
            protocol => $self->protocol,
        ],
    );

    $self->stash(json => $config);
}

sub enable
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        }
    };

    $params = $self->validate($rule, $params);

    my ($share, $section) = $self->_get_section($params->{Name});

    if (!$section)
    {
        $section = $self->get_model($self->section_model)->new(
            name    => $share->name,
            path    => $share->path,
            comment => $share->desc,
        );
    }

    $share->protocols->{$self->protocol} = 'yes';

    # :TODO 08/12/2019 03:01:24 PM: by P.G.
    # generalize local store process
    $share->store_to_file(
        path => $share->_config_file,
        key  => $share->name,
        data => $share->to_hash(),
    );

    my $volume = $self->_find_volume(name => $share->volume);

    if (!defined($volume))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'Volume',
            name     => $share->volume,
        );
    }

    # Stashing for augmentation
    $self->stash(
        share   => $share,
        section => $section,
        volume  => $volume,
    );

    $self->hook->($self);

    $section->enable();
    $section->store_to_file();

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_ENABLE_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name},
        ],
    );

    $self->publish_event();

    $self->stash(json => $section->to_hash());

    $share->unlock();
    $section->unlock();
}

sub disable
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        }
    };

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

    $params = $self->validate($rule, $params);

    my ($share, $section) = $self->_get_section($params->{Name});

    my $deleted;

    if ($share->protocols->{$self->protocol} eq 'no')
    {
        goto RETURN;
    }

    if (!$section)
    {
        $self->throw_exception(
            'NotFound',
            resource => "${\$self->protocol} share",
            name     => $params->{Name},
        );
    }

    $share->protocols->{$self->protocol} = 'no';

    # :TODO 08/12/2019 03:01:24 PM: by P.G.
    # generalize local store process
    $share->store_to_file(
        path => $share->_config_file,
        key  => $share->name,
        data => $share->to_hash(),
    );

    $deleted = $section->delete();

RETURN:
    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_DISABLE_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name}
        ],
    );

    $self->publish_event();

    $self->stash(json => $deleted);

    $share->unlock();
}

sub update
{
    my $self   = shift;
    my $params = $self->req->json;

    inner();

    my $section = $self->_get_section($params->{Name});

    if (!$section)
    {
        $self->throw_exception(
            'NotFound',
            resource => "${\$self->protocol} share",
            name     => $params->{Name},
        );
    }

    $section->update(map { lc($_) => $params->{$_}; } keys(%{$params}));

    $section->store_to_file();

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_UPDATE_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name}
        ],
    );

    $self->publish_event();

    $self->stash(json => $section->to_hash());

    $section->unlock();
}

sub control
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Action => {
            isa => enum([qw/start stop restart reload/]),
        },
        Active => {
            isa      => enum([qw/on off/]),
            optional => 1,
        }
    };

    $params = $self->validate($rule, $params);

    if (exists($params->{Active}))
    {
        if ($params->{Active} eq 'on'
            && enable_service(service => $self->service))
        {
            $self->throw_error(
                message => "Failed to enable service: ${\$self->service}");
        }
        elsif ($params->{Active} eq 'off'
            && disable_service(service => $self->service))
        {
            $self->throw_error(
                message => "Failed to disable service: ${\$self->service}");
        }
    }

    if (service_status(service => $self->service)
        && $params->{Action} eq 'reload')
    {
        warn sprintf('[WARN] Not running service cannot be reloaded: %s',
            $self->service);

        goto RETURN;
    }

    if (control_service(
        service => $self->service,
        action  => $params->{Action}
    ))
    {
        $self->throw_error(message =>
                "Failed to $params->{Action} service: ${\$self->service}");
    }

RETURN:
    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_CONTROL_OK',
        msgargs => [
            protocol => $self->protocol,
            action   => $params->{Action}
        ],
    );

    $self->publish_event();

    $self->stash(json => undef);
}

sub rights
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rights_table = dclone($self->rights_table);

    foreach my $key (keys(%{$rights_table}))
    {
        $rights_table->{$key}
            = [map { {Name => $_}; } @{$rights_table->{$key}}];
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_PROTO_RIGHTS_LIST_OK',
        msgargs => [
            protocol => $self->protocol,
        ],
    );

    $self->stash(json => $rights_table);
}

sub users
{
    my $self   = shift;
    my $params = $self->_conv_post_parm(params => $self->req->json);

    state $rule = {
        Name => {
            isa => 'Str',
        },
        argument => {
            isa      => 'HashRef',
            optional => 1,
        },
        entity => {
            isa      => 'HashRef',
            optional => 1,
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

    my $section = try
    {
        $self->_get_section($params->{Name});
    }
    catch
    {
        my $e = shift;

        if (ref($e) eq 'GMS::Exception::NotFound')
        {
            warn "[DEBUG] Could not find the share: $params->{Name}";
        }

        return;
    };

    my $count = $self->accountctl->user_count(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    my $users = $self->accountctl->user_list(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    foreach my $user (@{$users})
    {
        if (!$section)
        {
            $user->{AccessRight} = $self->_default_permission;
            next;
        }

        my $access = $section->get_account_access(user => $user->{User_Name});

        $user->{AccessRight} = $access->{right};
    }

    $self->stash(json => $users, count => $count->{NumOfUsers});
}

sub groups
{
    my $self   = shift;
    my $params = $self->_conv_post_parm(params => $self->req->json);

    state $rule = {
        Name => {
            isa => 'Str',
        },
        argument => {
            isa      => 'HashRef',
            optional => 1,
        },
        entity => {
            isa      => 'HashRef',
            optional => 1,
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

    my $section = try
    {
        $self->_get_section($params->{Name});
    }
    catch
    {
        my $e = shift;

        if (ref($e) eq 'GMS::Exception::NotFound')
        {
            warn "[DEBUG] Could not find the share: $params->{Name}";
        }

        return;
    };

    my $count = $self->accountctl->group_count(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    my $groups = $self->accountctl->group_list(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    foreach my $group (@{$groups})
    {
        if (!$section)
        {
            $group->{AccessRight} = $self->_default_permission;
            next;
        }

        my $access
            = $section->get_account_access(group => $group->{Group_Name});

        $group->{AccessRight} = $access->{right};
    }

    $self->stash(json => $groups, count => $count->{NumOfGroups} // 0);
}

# :TODO 07/21/2019 09:02:26 PM: by P.G.
# mapping static access controls with zone model
sub zones
{
    my $self   = shift;
    my $params = $self->req->json;

    my $section = $self->_get_section($params->{Name});

    if (!defined($section))
    {
        $self->throw_exception(
            'NotFound',
            resource => "${\$self->protocol} share",
            name     => $params->{Name},
        );
    }

    my @result;

    foreach my $name ($self->get_model('Zone')->list())
    {
        my $zone = $self->get_model('Zone')->find($name);

        my $tmp = $zone->to_hash();

        my ($right, $squash) = $section->get_network_access(zone => $zone);

        $tmp->{AccessRight} = $right;
        $tmp->{Squash}      = $squash if ($self->protocol eq 'NFS');

        push(@result, $tmp);
    }

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_ZONE_LIST_OK',
    );

    $self->stash(json => \@result, count => scalar(@result));
}

sub reload
{
    my $self   = shift;
    my $params = $self->req->json;

    my $volumes = $self->_list_volumes();

    if (ref($volumes) ne 'ARRAY')
    {
        $self->throw_error(message => 'Failed to get volume list');
    }

    my @shares = $self->get_model('Share')->list();

    foreach my $name (@shares)
    {
        my $share = $self->get_model('Share')->find($name);

        if (!defined($share))
        {
            warn "[WARN] Unknown ${\$self->protocol} share exists: $name";
            next;
        }

        my $section = $self->get_model($self->section_model)->find($name);

        if (!defined($section))
        {
            warn "[WARN] Missed ${\$self->protocol} share found."
                . " it will be reloaded: $name";

            $section = $self->get_model($self->section_model)
                ->new(name => $share->name,);
        }

        my $volume;

        foreach (@{$volumes})
        {
            if ($_->{Volume_Name} eq $share->volume)
            {
                $volume = $_;
                last;
            }
        }

        if (!defined($volume))
        {
            warn sprintf(
                '[WARN] Share %s will be disabled because volume %s not found',
                $share->name, $share->volume);

            $section->disable();
        }

        if (!grep { $_->{Storage_Hostname} eq short(); } @{$volume->{Nodes}})
        {
            warn sprintf(
                '[DEBUG] This host is not a member of the service: %s: %s',
                $share->volume, $share->name);

            $section->disable();

            next;
        }

        # :NOTE 08/09/2019 05:17:09 PM: by P.G.
        # some protocol specific actions such as configurations
        # of NFS FSAL, Samba VFS are augmented via each them
        if ($share->protocols->{$self->protocol} eq 'yes')
        {
            $section->enable();
        }
        else
        {
            $section->disable();
        }
    }

    # :TODO 12/27/2019 04:34:52 PM: by P.G.
    # We need to remove orphan sections for cluster database within
    # Cluster-level controllers such as Cluster::Share::*
    $self->_reload_section_files();

    $self->api_status(
        level => 'INFO',
        code  => 'SHARE_RELOAD_OK',
    );

    $self->stash(json => \@shares);
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _conv_post_parm
{
    my $self = shift;
    my %args = @_;

    my $post = $self->req->params->to_hash;

    return if (ref($post) ne 'HASH');

    my $filter;

    foreach my $key (keys(%{$post}))
    {
        given ($key)
        {
            when ('Name')
            {
                $args{params}->{Name} = $post->{$key};
            }
            when ('page')
            {
                $args{params}->{argument}->{PageNumber} = $post->{$key};
            }
            when ('limit')
            {
                $args{params}->{argument}->{NumOfRecords} = $post->{$key};
            }
            when ('sort')
            {
                my $sorters = decode_json($post->{$key});

                foreach my $s (@{$sorters})
                {
                    $args{params}->{argument}->{SortType}  = $s->{direction};
                    $args{params}->{argument}->{SortField} = $s->{property};
                }
            }
            when ('LocationType')
            {
                $args{params}->{argument}->{Location} = $post->{$key};
            }
            when ('FilterType')
            {
                $filter->{FilterType} = $post->{$key};
            }
            when ('FilterStr')
            {
                $filter->{FilterStr} = $post->{$key};
            }
            when ('MatchType')
            {
                $filter->{FilterResult} = $post->{$key};
            }
        }
    }

    if (exists($filter->{FilterType}) && exists($filter->{FilterStr}))
    {
        push(@{$args{params}->{argument}->{Filters}}, $filter);
    }

    return $args{params};
}

sub _get_section
{
    my $self = shift;
    my $name = shift;

    my $share = $self->get_model('Share')->find($name);

    if (!$share)
    {
        $self->throw_exception(
            'NotFound',
            resource => 'share',
            name     => $name,
        );
    }

    my $section = $self->get_model($self->section_model)->find($share->name);

    return wantarray ? ($share, $section) : $section;
}

sub _list_volumes
{
    my $self = shift;
    my %args = @_;

    my $type = $args{type} // 'ALL';

    return GMS::Cluster::Volume->new->volumelist(Pool_Type => $type);
}

sub _find_volume
{
    my $self = shift;
    my %args = @_;

    # :TODO 08/01/2019 05:29:44 PM: by P.G.
    # simple validator with GMS::Validator

    my $type = $args{type} // 'ALL';
    my $name = $args{name};

    my $vols  = $self->_list_volumes(type => $type);
    my $found = undef;

    if (ref($vols) ne 'ARRAY')
    {
        die 'Failed to get volume list';
    }

    foreach my $vol (@{$vols})
    {
        if ($vol->{Volume_Name} eq $name)
        {
            $found = $vol;
            last;
        }
    }

    return $found;
}

sub _reload_section_files
{
    my $self = shift;

    my $attr = $self->get_model($self->section_model)
        ->meta->find_attribute_by_name('_section_dir');

    die "Could not find attribute: ${\$self->config_model}: _section_dir"
        if (!defined($attr));

    my $section_dir = $attr->default;

    if (-e $section_dir && !-d $section_dir)
    {
        die "Path exists but not a directory: $section_dir";
    }

    if (!-d $section_dir
        && make_path($section_dir, {error => \my $err}) == 0)
    {
        my ($dir, $msg) = %{$err->[0]};

        if ($dir eq '')
        {
            die "Generic error: $msg";
        }
        else
        {
            die "Failed to make directory: $section_dir: $msg";
        }
    }

    opendir(my $dh, $section_dir)
        || die "Failed to open directory: $section_dir: $!";

    while (my $entry = readdir($dh))
    {
        next if ($entry =~ m/^\.+$/ || $entry !~ m/\.(?:conf|exports)$/);

        my $path = sprintf('%s/%s', $section_dir, $entry);

        if (lstat($path) && !stat($path))
        {
            unlink($path) || die "Failed to unlink file: $path: $!";

            $self->_handle_aggregator($entry);
        }
    }

    closedir($dh);
}

sub _handle_aggregator
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    if (blessed($self) eq __PACKAGE__)
    {
        die "${\__PACKAGE__}::_handle_aggregator is an abstract method";
    }
}

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    if (blessed($self) eq __PACKAGE__)
    {
        die "${\__PACKAGE__} is an abstract class";
    }
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Share::Protocol - GMS filing service management API abstraction class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

