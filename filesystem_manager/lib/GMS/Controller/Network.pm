package GMS::Controller::Network;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Coro;
use Guard;
use Mouse::Util::TypeConstraints;

use GMS::Common::Logger;
use Sys::Hostname::FQDN qw/short/;
use GMS::Network::Type qw/prefix_to_netmask/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override build_models => sub
{
    {
        DNS => 'GMS::Model::Network::DNS',

        # :TODO 10/07/2019 03:34:17 AM: by P.G.
        # Monkey patch
        Hosts => 'GMS::Model::Cluster::Network::Hosts',

        #Hosts      => 'GMS::Model::Network::Hosts',
        Hostname => 'GMS::Model::Network::Hostname',
        Route    => 'GMS::Model::Cluster::Network::Route',

        #Route      => 'GMS::Model::Network::Route',
        Zone       => 'GMS::Model::Network::Zone',
        Device     => 'GMS::Model::Network::Device',
        InfiniBand => 'GMS::Model::Network::InfiniBand',
        Bonding    => 'GMS::Model::Network::Bonding',
        VLAN       => 'GMS::Model::Network::VLAN',
    };
};

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'get_model' => sub
{
    my $orig  = shift;
    my $self  = shift;
    my $alias = shift;

    my $model = $self->$orig($alias);

    if (!defined($model))
    {
        return;
    }

    return ($alias =~ m/(?:DNS|Hostname|Route)$/) ? $model->new() : $model;
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub dns_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = [
        map { {IPAddr => $_->[0]}; } (
            sort { $a->[1]->{priority} <=> $b->[1]->{priority} }
                $self->get_model('DNS')->all_entries
        )
    ];

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_DNS_INFO_OK',
    );

    $self->stash(json => $result);
}

sub dns_update
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->get_model('DNS')->update(@{$params});

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_DNS_UPDATE_OK',
        msgargs => [dns => join(', ', map { values(%{$_}) } @{$result})],
    );

    $self->app->gms_new_event(locale => $self->cookie('language'));

    $self->stash(json => $result);
}

sub hostname
{
    my $self = shift;

    my $model = $self->get_model('Hostname');

    my %hostname = (
        Static => $model->static,
        Pretty => $model->pretty,
    );

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_HOSTNAME_INFO_OK',
        msgargs => [hostname => $hostname{Static}],
    );

    $self->stash(json => \%hostname);
}

sub hostname_update
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Static => {
            isa => 'Str',
        },
        Pretty => {
            isa => 'Str',
            xor => ['Static'],
        }
    };

    $params = $self->validate($rule, $params);

    my $model = $self->get_model('Hostname');

    my %old = (
        Static => $model->static,
        Pretty => $model->pretty,
    );

    warn sprintf('[DEBUG] Old hostname: static=%s, pretty=%s',
        $old{Static}, $old{Pretty},);

    $model->update(map { lc($_) => $params->{$_}; } keys(%{$params}));

    my %new = (
        Static => $model->static,
        Pretty => $model->pretty,
    );

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_HOSTNAME_UPDATE_OK',
        msgargs => [
            from => exists($params->{Static}) ? $old{Static} : $old{Pretty},
            to   => exists($params->{Static}) ? $new{Static} : $new{Pretty}
        ],
    );

    $self->stash(json => \%new);
}

sub hosts_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my %hosts;

    foreach my $ipaddr ($self->get_model('Hosts')->list())
    {
        my $model = $self->get_model('Hosts')->find($ipaddr);

        if (!defined($model))
        {
            $self->throw_exception(
                'NotFound',
                resource => 'Hosts',
                name     => $ipaddr,
            );
        }

        $hosts{$model->ipaddr} = $model->hostnames;
    }

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_HOSTS_INFO_OK',
    );

    $self->stash(json => \%hosts);
}

sub hosts_add
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        IPAddr => {
            isa => 'GMS::Network::Type::IP',
        },
        Hostnames => {
            isa => 'ArrayRef[GMS::Network::Type::Hostname]',
        },
    };

    $params = $self->validate($rule, $params);

    my $found = $self->get_model('Hosts')->find($params->{IPAddr});

    if ($found)
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'Network hosts',
            name     => $params->{IPAddr}
        );
    }

    my $created = $self->get_model('Hosts')->new(
        ipaddr    => $params->{IPAddr},
        hostnames => $params->{Hostnames},
    );

    if (!defined($created))
    {
        $self->throw_exception(
            'CreateFailure',
            resource => 'Network hosts',
            name     => $params->{IPAddr}
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_HOSTS_ADD_OK',
        msgargs => [
            ip        => $params->{IPAddr},
            hostnames => join(', ', @{$params->{Hostnames}})
        ],
    );

    $self->stash(json => $created->to_hash);
}

sub hosts_update
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        IPAddr => {
            isa => 'GMS::Network::Type::IP',
        },
        Hostnames => {
            isa => 'ArrayRef[GMS::Network::Type::Hostname]',
        },
    };

    $params = $self->validate($rule, $params);

    my $found = $self->get_model('Hosts')->find($params->{IPAddr});

    if (!$found)
    {
        $self->throw_exception(
            'NotFound',
            resource => 'Network hosts',
            name     => $params->{IPAddr}
        );
    }

    my $updated
        = $found->update(map { lc($_) => $params->{$_}; } keys(%{$params}));

    if (!defined($updated))
    {
        $self->throw_exception(
            'UpdateFailure',
            resource => 'Network hosts',
            name     => $params->{IPAddr},
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_HOSTS_UPDATE_OK',
        msgargs => [
            ip        => $updated->ipaddr,
            hostnames => join(', ', $updated->all_hostnames),
        ]
    );

    $self->app->gms_new_event(locale => $self->cookie('language'));

    $self->stash(json => $updated->to_hash);
}

sub hosts_remove
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        IPAddr => {
            isa => 'GMS::Network::Type::IP',
        },
    };

    $params = $self->validate($rule, $params);

    my $found = $self->get_model('Hosts')->find($params->{IPAddr});

    if (!$found)
    {
        $self->throw_exception(
            'NotFound',
            resource => 'Netowrk hosts',
            name     => $params->{IPAddr}
        );
    }

    my $deleted = $found->delete();

    if (!defined($deleted))
    {
        $self->throw_exception(
            'DeleteFailure',
            resource => 'Network hosts',
            name     => $params->{IPAddr},
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_HOSTS_REMOVE_OK',
        msgargs => [
            ip        => $deleted->{IPAddr},
            hostnames => join(', ', @{$deleted->{Hostnames}}),
        ]
    );

    $self->app->gms_new_event(locale => $self->cookie('language'));

    $self->stash(json => $deleted);
}

sub hosts_reload
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => '/Network');

    scope_guard { $self->gms_unlock(scope => '/Network'); };

    my @reloaded;

    foreach my $ip ($self->get_model('Hosts')->list())
    {
        my $model = $self->get_model('Hosts')->find($ip);

        if (!defined($model))
        {
            $self->throw_exception(
                'NotFound',
                resource => 'Hosts',
                name     => $ip,
            );
        }

        push(@reloaded, $model->to_hash());

        undef($model);
    }

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_HOSTS_RELOAD_OK',
    );

    $self->stash(json => \@reloaded);
}

sub device_list
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my @result;

#    my @coros = ();
#
#    use Time::HiRes qw/gettimeofday tv_interval/;

    foreach my $mtype (qw/Device InfiniBand Bonding VLAN/)
    {
        foreach my $name ($self->get_model($mtype)->list())
        {
#            push(
#                @coros,
#                async
#                {
#                    $Coro::current->{desc}
#                        = sprintf('%s/%s', $self->req->request_id, $name);
#
#                    catch_sig_warn(%{$self->app->log_settings});
#
#                    #my $t0 = [gettimeofday];
#
            my $model = $self->get_model($mtype)->find($name);
#
#                    #warn sprintf('[INFO] %.2fs', tv_interval($t0));
#
            push(@result, $model->to_hash);
#
#                    #warn sprintf('[INFO] %.2fs', tv_interval($t0));
#                }
#            );
        }
    }

#    map { $_->join(); } @coros;

    $self->api_status(code => 'NETWORK_DEV_LIST_OK');

    $self->stash(json => [sort { $a->{Device} cmp $b->{Device}; } @result]);
}

sub device_info
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        }
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $mtype  = $self->_get_device_type($params->{Device});
    my $device = $self->get_model($mtype)->find($params->{Device});

    if (!defined($device))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network device',
            name     => $params->{Device}
        );
    }

    my $retval = $device->to_hash;

    my @addrs;

    foreach my $cidr ($device->all_ipaddrs(cidr => 1), $device->fips)
    {
        my ($ip, $prefix) = split(/\//, $cidr);

        push(
            @addrs,
            {
                IPAddr  => $ip,
                Netmask => prefix_to_netmask($prefix),
                Prefix  => $prefix,

                # TODO
                Gateway => '',
            }
        );
    }

    $retval->{IPAddrs}    = \@addrs;
    $retval->{Statistics} = $device->statistics;

    $self->api_status(code => 'NETWORK_DEV_INFO_OK');

    $self->stash(json => $retval);
}

sub device_update
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        },
        OnBoot => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        IPAddr => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        Netmask => {
            isa      => 'ArrayRef[GMS::Network::Type::Netmask]',
            optional => 1,
        },
        Gateway => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        MTU => {
            isa      => 'Int',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $mtype  = $self->_get_device_type($params->{Device});
    my $device = $self->get_model($mtype)->find($params->{Device});

    if (!defined($device))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network device',
            name     => $params->{Device}
        );
    }

    $device->update(
        map {
            if ($_ =~ m/^(?:device|mode|primary)$/i)
            {
                lc($_) => $params->{$_};
            }
            else
            {
                uc($_) => $params->{$_};
            }
        } keys(%{$params})
    );

    $self->api_status(
        code    => 'NETWORK_DEV_UPDATE_OK',
        msgargs => [name => $params->{Device}],
    );

    $self->stash(json => $device->to_hash);
}

sub bonding_list
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my @result;

    foreach my $name ($self->get_model('Bonding')->list())
    {
        my $model = $self->get_model('Bonding')->find($name);

        push(@result, $model->to_hash);
    }

    $self->api_status(code => 'NETWORK_BOND_LIST_OK');

    $self->stash(json => \@result);
}

sub bonding_info
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    state $rule = {
        Device => {
            isa => 'Str',
        }
    };

    $params = $self->validate($rule, $params);

    my $bond = $self->get_model('Bonding')->find($params->{Device});

    if (!defined($bond))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network bonding',
            name     => $params->{Device}
        );
    }

    my $retval = $bond->to_hash();

    my @addrs;

    foreach my $cidr ($bond->all_ipaddrs(cidr => 1), $bond->fips)
    {
        my ($ip, $prefix) = split(/\//, $cidr);

        push(
            @addrs,
            {
                IPAddr  => $ip,
                Netmask => prefix_to_netmask($prefix),
                Prefix  => $prefix,

                # TODO
                Gateway => '',
            }
        );
    }

    $retval->{IPAddrs}    = \@addrs;
    $retval->{Statistics} = $bond->statistics;

    $self->api_status(code => 'NETWORK_BOND_INFO_OK');

    $self->stash(json => $retval);
}

sub bonding_create
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa     => 'GMS::Network::Type::Bonding',
            default => sub
            {
                my @list = $self->get_model('Bonding')->list;

                my $max_idx = 0;

                foreach (@list)
                {
                    next if ($_ !~ m/(?<idx>\d+)$/);

                    $max_idx = $+{idx} if ($max_idx < $+{idx});
                }

                $params->{Device} = sprintf('bond%d', $max_idx + 1);
            }
        },
        Mode => {
            isa     => 'GMS::Network::Type::Bonding::Mode',
            default => 'balance-rr',
            coerce  => 1,
        },
        Slaves => {
            isa      => 'ArrayRef[Str]',
            optional => 1,
        },
        OnBoot => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        IPAddr => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        Netmask => {
            isa      => 'ArrayRef[GMS::Network::Type::Netmask]',
            optional => 1,
        },
        Gateway => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        Primary => {
            isa      => 'Str',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $found = $self->get_model('Bonding')->find($params->{Device});

    if (defined($found))
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'network bonding',
            name     => $params->{Device}
        );
    }

    my $created = $self->get_model('Bonding')->new(
        map {
            if ($_ =~ m/^(?:device|mode|slaves|primary)$/i)
            {
                lc($_) => $params->{$_};
            }
            else
            {
                uc($_) => $params->{$_};
            }
        } keys(%{$params})
    );

    if ($created->ONBOOT eq 'yes')
    {
        $created->up();
    }
    else
    {
        $created->down();
    }

    $self->api_status(
        code    => 'NETWORK_BOND_CREATE_OK',
        msgargs => [name => $params->{Device}],
    );

    $self->stash(json => $created->to_hash);
}

sub bonding_update
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        },
        Mode => {
            isa      => 'GMS::Network::Type::Bonding::Mode',
            optional => 1,
        },
        Slaves => {
            isa      => 'ArrayRef[Str]',
            optional => 1,
        },
        OnBoot => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        IPAddr => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        Netmask => {
            isa      => 'ArrayRef[GMS::Network::Type::Netmask]',
            optional => 1,
        },
        Gateway => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        Primary => {
            isa      => 'Str | Undef',
            optional => 1,
        },
        MTU => {
            isa      => 'Int',
            optional => 1,
        }
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $found = $self->get_model('Bonding')->find($params->{Device});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network bonding',
            name     => $params->{Device}
        );
    }

    $found->update(
        map {
            if ($_ =~ m/^(?:device|mode|primary|slaves)$/i)
            {
                lc($_) => $params->{$_};
            }
            else
            {
                uc($_) => $params->{$_};
            }
        } keys(%{$params})
    );

    $self->api_status(
        code    => 'NETWORK_BOND_UPDATE_OK',
        msgargs => [name => $params->{Device}],
    );

    $self->stash(json => $found->to_hash);
}

sub bonding_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        },
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $found = $self->get_model('Bonding')->find($params->{Device});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network bonding',
            name     => $params->{Device}
        );
    }

    # :TODO 09/14/2019 03:30:34 PM: by P.G.
    # exception handling for internal-purpose(service/storage/mgmt) bonding

    my $deleted = $found->delete();

    $self->api_status(
        code    => 'NETWORK_BOND_DELETE_OK',
        msgargs => [name => $params->{Device}],
    );

    $self->stash(json => $deleted);
}

sub vlan_list
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my @result;

    foreach my $name ($self->get_model('VLAN')->list())
    {
        my $model = $self->get_model('VLAN')->find($name);

        push(@result, $model->to_hash);
    }

    $self->api_status(code => 'NETWORK_VLAN_LIST_OK');

    $self->stash(json => \@result);
}

sub vlan_info
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        }
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $vlan = $self->get_model('VLAN')->find($params->{Device});

    if (!defined($vlan))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'VLAN device',
            name     => $params->{Device}
        );
    }

    my $retval = $vlan->to_hash();

    my @addrs;

    foreach my $cidr ($vlan->all_ipaddrs(cidr => 1), $vlan->fips)
    {
        my ($ip, $prefix) = split(/\//, $cidr);

        push(
            @addrs,
            {
                IPAddr  => $ip,
                Netmask => prefix_to_netmask($prefix),
                Prefix  => $prefix,

                # TODO
                Gateway => '',
            }
        );
    }

    $retval->{IPAddrs}    = \@addrs;
    $retval->{Statistics} = $vlan->statistics;

    $self->api_status(code => 'NETWORK_VLAN_INFO_OK');

    $self->stash(json => $vlan->to_hash);
}

sub vlan_create
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'GMS::Network::Type::VLAN',
        },
        OnBoot => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        MTU => {
            isa      => 'Int',
            optional => 1,
        },
        IPAddr => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        Netmask => {
            isa      => 'ArrayRef[GMS::Network::Type::Netmask]',
            optional => 1,
        },
        Gateway => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $found = $self->get_model('VLAN')->find($params->{Device});

    if (defined($found))
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'VLAN device',
            name     => $params->{Device}
        );
    }

    my $created = $self->get_model('VLAN')->new(
        map {
            if ($_ =~ m/^(?:device)$/i)
            {
                lc($_) => $params->{$_};
            }
            else
            {
                uc($_) => $params->{$_};
            }
        } keys(%{$params})
    );

    if ($created->ONBOOT eq 'yes')
    {
        $created->up();
    }
    else
    {
        $created->down();
    }

    $self->api_status(
        code    => 'NETWORK_VLAN_CREATE_OK',
        msgargs => [name => $params->{Device}],
    );

    $self->stash(json => $created->to_hash);
}

sub vlan_update
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        },
        OnBoot => {
            isa      => enum([qw/yes no/]),
            optional => 1,
        },
        IPAddr => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        Netmask => {
            isa      => 'ArrayRef[GMS::Network::Type::Netmask]',
            optional => 1,
        },
        Gateway => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4]',
            optional => 1,
        },
        MTU => {
            isa      => 'Int',
            optional => 1,
        }
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $found = $self->get_model('Bonding')->find($params->{Device});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network bonding',
            name     => $params->{Device}
        );
    }

    $found->update(

        # TODO
    );

    $self->api_status(
        code    => 'NETWORK_VLAN_UPDATE_OK',
        msgargs => [name => $params->{Device}],
    );

    $self->stash(json => $found->to_hash);
}

sub vlan_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        },
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $found = $self->get_model('VLAN')->find($params->{Device});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'VLAN device',
            name     => $params->{Device}
        );
    }

    # :TODO 09/14/2019 03:30:34 PM: by P.G.
    # exception handling for internal-purpose(service/storage/mgmt) VLAN

    my $deleted = $found->delete();

    $self->api_status(
        code    => 'NETWORK_VLAN_DELETE_OK',
        msgargs => [name => $params->{Device}],
    );

    $self->stash(json => $deleted);

}

sub address_list
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my @result;

    foreach my $mtype (qw/Device InfiniBand Bonding VLAN/)
    {
        foreach my $name ($self->get_model($mtype)->list())
        {
            my $model = $self->get_model($mtype)->find($name);

            if (!defined($model))
            {
                $self->throw_exception(
                    'NotFound',
                    resource => $mtype eq 'Device'
                    ? 'Network device'
                    : "$mtype device",
                    name => $name,
                );
            }

            push(@result, $self->_get_addrs($model));
        }
    }

    $self->api_status(code => 'NETWORK_ADDR_LIST_OK');

    $self->stash(json => \@result);
}

sub address_add
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        },
        IPAddr => {
            isa => 'GMS::Network::Type::IPv4',
        },
        Netmask => {
            isa => 'GMS::Network::Type::Netmask',
        },
        Gateway => {
            isa      => 'GMS::Network::Type::IPv4',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $mtype = $self->_get_device_type($params->{Device});
    my $model = $self->get_model($mtype)->find($params->{Device});

    if (!defined($model))
    {
        $self->throw_exception(
            'NotFound',
            resource => $mtype eq 'Device'
            ? 'Ethernet device'
            : "$mtype device",
            name => $params->{Device}
        );
    }

    $model->assign_ip(
        ipaddr  => $params->{IPAddr},
        netmask => $params->{Netmask}
    );

    $model->add_ipaddr($params->{IPAddr});
    $model->add_netmask($params->{Netmask});
    $model->add_gateway($params->{Gateway}) if (exists($params->{Gateway}));

    $model->set();

    $self->api_status(
        code    => 'NETWORK_ADDR_ADD_OK',
        msgargs => [addr => "$params->{IPAddr}/$params->{Netmask}"],
    );

    $self->stash(json => $model->to_hash());
}

# :TODO 08/04/2020 06:36:00 PM: thkim (#7281-54)
#
# etcd v3에서 빈 값('')에 대한 처리 방법이 정해지면 그때 게이트웨이 설정을
# 다시 시작함.
# 게이트웨이 값은 받지만, 실제로 아무 작업을 하지 않는다.
sub address_update
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'NotEmptyStr',
        },
        IPAddr => {
            isa => 'ArrayRef[GMS::Network::Type::IPv4]',
        },
        Netmask => {
            isa => 'ArrayRef[GMS::Network::Type::Netmask]',
        },
        Gateway => {
            isa      => 'ArrayRef[GMS::Network::Type::IPv4|Undef]',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    my @validation_errs;

    map {
        if (scalar(@{$params->{$_}}) != 2)
        {
            push(
                @validation_errs,
                {
                    type => 'InvalidValue',
                    name => $_,
                }
            );
        }
    } qw/IPAddr Netmask/;

    if (@validation_errs)
    {
        $self->throw_exception(
            'ValidationError',
            message => 'Invalid parameter detected',
            errors  => \@validation_errs,
        );
    }

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $mtype  = $self->_get_device_type($params->{Device});
    my $device = $self->get_model($mtype)->find($params->{Device});

    if (!defined($device))
    {
        $self->throw_exception(
            'NotFound',
            resource => $mtype eq 'Device'
            ? 'Ethernet device'
            : "$mtype device",
            name => $params->{Device}
        );
    }

    my %old_addr = (
        ipaddr  => $params->{IPAddr}->[0],
        netmask => $params->{Netmask}->[0],

        #gateway => $params->{Gateway}->[0],
    );

    my %new_addr = (
        ipaddr  => $params->{IPAddr}->[1],
        netmask => $params->{Netmask}->[1],

        #gateway => $params->{Gateway}->[1],
    );

    # delete old_addr in params
    shift(@{$params->{IPAddr}});
    shift(@{$params->{Netmask}});

    #shift(@{$params->{Gateway}});

    # add new_addr in params for $device->update()
    foreach my $i (0 .. $device->count_ipaddrs - 1)
    {
        if ($device->get_ipaddr($i) ne $old_addr{ipaddr})
        {
            push(@{$params->{IPAddr}},  $device->get_ipaddr($i));
            push(@{$params->{Netmask}}, $device->get_netmask($i));

            #push(@{$params->{Gateway}}, $device->get_gateway($i));
        }
    }

    # Delete allocated IP address
    $device->dismiss_ip(
        ipaddr  => $old_addr{ipaddr},
        netmask => $old_addr{netmask}
    );

    # Update ifcfg-* file and etcd
    $device->update(map { uc($_) => $params->{$_}; } keys(%{$params}));

    warn "[DEBUG] '$params->{Device} is updated successfully";

    # do not update hosts if the prev and new IP addresses are same.
    if ($old_addr{ipaddr} eq $new_addr{ipaddr})
    {
        warn sprintf(
            '[DEBUG] Both IP addresses are same so not to be changed: %s %s',
            $old_addr{ipaddr}, $new_addr{ipaddr});

        goto RETURN;
    }

    # Update /etc/hosts and etcd hosts
    my $prev_hosts = $self->get_model('Hosts')->find($old_addr{ipaddr});

    if (!$prev_hosts)
    {
        warn "[WARN] Could not find Hosts model for $old_addr{ipaddr}";
        goto RETURN;
    }

    # Backup hostname in etcd
    my $host_names = [@{$prev_hosts->hostnames}];
    my $host_ip    = $new_addr{ipaddr};

    my $deleted = $prev_hosts->delete();

    if (!defined($deleted))
    {
        $self->throw_exception(
            'DeleteFailure',
            resource => 'Network hosts',
            name     => $new_addr{ipaddr}
        );
    }

    $prev_hosts->unlock();

    my $new_hosts = $self->get_model('Hosts')->new(
        ipaddr    => $host_ip,
        hostnames => $host_names,
    );

    if (!defined($new_hosts))
    {
        $self->throw_exception(
            'CreateFailure',
            resource => 'Network hosts',
            name     => $host_ip,
        );
    }

    $new_hosts->unlock();

RETURN:
    $self->api_status(
        code    => 'NETWORK_ADDR_UPDATE_OK',
        msgargs => [addr => "$params->{IPAddr}/$params->{Netmask}"],
    );

    $self->stash(json => $device->to_hash());

    $device->unlock();
}

sub address_remove
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Device => {
            isa => 'Str',
        },
        IPAddr => {
            isa => 'GMS::Network::Type::IPv4',
        },
        Netmask => {
            isa => 'GMS::Network::Type::Netmask',
        },
        Gateway => {
            isa      => 'GMS::Network::Type::IPv4',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    $self->gms_lock(scope => 'Network');

    scope_guard { $self->gms_unlock(scope => 'Network'); };

    my $mtype = $self->_get_device_type($params->{Device});
    my $model = $self->get_model($mtype)->find($params->{Device});

    if (!defined($model))
    {
        $self->throw_exception(
            'NotFound',
            resource => $mtype eq 'Device'
            ? 'Ethernet device'
            : "$mtype device",
            name => $params->{Device}
        );
    }

    $model->dismiss_ip(
        ipaddr  => $params->{IPAddr},
        netmask => $params->{Netmask}
    );

    my $idx = $model->findi_ipaddr($params->{IPAddr});

    if ($idx >= 0)
    {
        $model->del_ipaddr($idx);
        $model->del_netmask($idx);
        $model->del_gateway($idx);

        $model->set();
    }

    $self->api_status(
        code    => 'NETWORK_ADDR_REMOVE_OK',
        msgargs => [addr => "$params->{IPAddr}/$params->{Netmask}"],
    );

    $self->stash(json => $model->to_hash());

    $model->unlock();
}

sub route_table_list
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa      => 'Str',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->all_tables(%{$params});

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_ROUTE_TABLE_LIST_OK',
    );

    $self->stash(json => $result);
}

sub route_table_info
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->get_table($params->{Name});

    if (!defined($result))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network routing table',
            name     => $params->{Name}
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ROUTE_TABLE_INFO_OK',
        msgargs => [name => $params->{Name}],
    );

    $self->stash(json => $result);
}

sub route_table_create
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        ID => {
            isa      => 'Int',
            optional => 1,
        }
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->create_table(%{$params});

    if (!defined($result))
    {
        $self->throw_exception(
            'CreateFailure',
            resource => 'network routing table',
            name     => $params->{Name},
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ROUTE_TABLE_CREATE_OK',
        msgargs => [name => $params->{Name}],
    );

    $self->stash(json => $result);
}

sub route_table_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->delete_table(%{$params});

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ROUTE_TABLE_DELETE_OK',
        msgargs => [name => $params->{Name}],
    );

    $self->stash(json => $result);
}

sub route_rule_list
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Table => {
            isa      => 'Str',
            optional => 1,
        },
        Device => {
            isa      => 'Str',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->all_rules;

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_ROUTE_RULE_LIST_OK',
    );

    $self->stash(json => $result);
}

sub route_rule_create
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Table => {
            isa => 'Str',
        },
        From => {
            isa => 'GMS::Network::Type::CIDR',
        },
        Device => {
            isa => 'Str',
        }
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->create_rule(%{$params});

    if (!defined($result))
    {
        $self->throw_exception(
            'CreateFailure',
            resource => 'network routing rule',
            name     => sprintf(
                '%s(from:%s device:%s)',
                $params->{Table},
                $params->{From},
                $params->{Device}
            )
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ROUTE_RULE_CREATE_OK',
        msgargs => [
            table => $params->{Table},
            rule  => sprintf(
                'from:%s device:%s',
                $params->{From}, $params->{Device}
            )
        ],
    );

    $self->stash(json => $result);
}

sub route_rule_update
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result;

    $self->stash(json => $result);
}

sub route_rule_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Table => {
            isa => 'Str',
        },
        From => {
            isa => 'GMS::Network::Type::CIDR',
        },
        Device => {
            isa => 'Str',
        }
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->delete_rule(%{$params});

    if (!defined($result))
    {
        $self->throw_exception(
            'DeleteFailure',
            resource => 'network routing rule',
            name     => sprintf(
                '%s(from:%s device:%s)',
                $params->{Table},
                $params->{From},
                $params->{Device}
            )
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ROUTE_RULE_DELETE_OK',
        msgargs => [
            table => $params->{Table},
            rule  => sprintf(
                'from:%s device:%s',
                $params->{From}, $params->{Device}
            )
        ],
    );

    $self->stash(json => $result);
}

sub route_entry_list
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Table => {
            isa      => 'Str',
            optional => 1,
        },
        To => {
            isa      => 'GMS::Network::Type::CIDR',
            optional => 1,
        },
        Via => {
            isa      => 'GMS::Network::Type::IP',
            optional => 1,
        },
        Device => {
            isa      => 'Str',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    my $model   = $self->get_model('Route');
    my @entries = $model->all_entries;

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_ROUTE_ENTRY_LIST_OK',
    );

    $self->stash(json => \@entries);
}

sub route_entry_create
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Table => {
            isa     => 'Str',
            default => 'main',
        },
        Default => {
            isa     => 'Bool',
            default => 0,
        },
        To => {
            isa => 'GMS::Network::Type::CIDR',
        },
        Via => {
            isa => 'GMS::Network::Type::IP',
            or  => ['Device'],
        },
        Device => {
            isa => 'Str',
            or  => ['Via'],
        },
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->create_entry(%{$params});

    if (!defined($result))
    {
        $self->throw_exception(
            'CreateFailure',
            resource => 'network routing entry',
            name     => sprintf(
                '%s(src:%s via:%s dev:%s)',
                $params->{Table},
                $params->{To}     // 'undef',
                $params->{Via}    // 'undef',
                $params->{Device} // 'undef'
            )
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ROUTE_ENTRY_CREATE_OK',
        msgargs => [
            table => $params->{Table},
            entry => sprintf(
                'to:%s via:%s device:%s',
                $params->{To}     // 'undef',
                $params->{Via}    // 'undef',
                $params->{Device} // 'undef'
            )
        ],
    );

    $self->stash(json => $result);
}

sub route_entry_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Table => {
            isa => 'Str',
        },
        Default => {
            isa     => 'Bool',
            default => 0,
        },
        To => {
            isa      => 'GMS::Network::Type::CIDR',
            optional => 1,
        },
        Via => {
            isa      => 'GMS::Network::Type::IP',
            optional => 1,
        },
        Device => {
            isa      => 'Str',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    my $result = $self->get_model('Route')->delete_entry(%{$params});

    if (!defined($result))
    {
        $self->throw_exception(
            'DeleteFailure',
            resource => 'network routing entry',
            name     => sprintf(
                '%s(src:%s via:%s dev:%s)',
                $params->{Table},
                $params->{To}     // 'undef',
                $params->{Via}    // 'undef',
                $params->{Device} // 'undef'
            )
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ROUTE_ENTRY_DELETE_OK',
        msgargs => [
            table => $params->{Table},
            entry => sprintf(
                'to:%s via:%s device:%s',
                $params->{To}     // 'undef',
                $params->{Via}    // 'undef',
                $params->{Device} // 'undef'
            )
        ],
    );

    $self->stash(json => $result);
}

sub route_reload
{
    my $self   = shift;
    my $params = $self->req->json;

    my $model = $self->get_model('Route')->reload();

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_ROUTE_RELOAD_OK',
    );

    $self->stash(json => undef);
}

sub zone_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my @result;

    foreach my $name ($self->get_model('Zone')->list())
    {
        my $model = $self->get_model('Zone')->find($name);

        push(@result, $model->to_hash);

        $model->unlock();
    }

    $self->api_status(
        level => 'INFO',
        code  => 'NETWORK_ZONE_LIST_OK',
    );

    $self->stash(json => \@result);
}

sub zone_info
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
    };

    $params = $self->validate($rule, $params);

    my $zone = $self->get_model('Zone')->find($params->{Name});

    if (!defined($zone))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network zone',
            name     => $params->{Name}
        );
    }

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ZONE_INFO_OK',
        msgargs => [zone => $params->{Name}],
    );

    $self->stash(json => $zone->to_hash());

    $zone->unlock();
}

sub zone_create
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        Desc => {
            isa      => 'Str',
            optional => 1,
        },
        Addrs => {
            isa => 'ArrayRef[GMS::Network::Type::IP]',
            xor => ['Range', 'CIDR', 'Domain'],
        },
        Range => {
            isa => 'GMS::Network::Type::IPRange',
            xor => ['Addrs', 'CIDR', 'Domain'],
        },
        CIDR => {
            isa => 'GMS::Network::Type::CIDR',
            xor => ['Addrs', 'Range', 'Domain'],
        },
        Domain => {
            isa => 'Str',
            xor => ['Addrs', 'Range', 'CIDR'],
        },
    };

    $params = $self->validate($rule, $params);

    my @list = $self->get_model('Zone')->list();

    if (grep { $params->{Name} eq $_; } @list)
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'network zone',
            name     => $params->{Name},
        );
    }

    my $result = $self->get_model('Zone')
        ->new(map { lc($_) => $params->{$_}; } keys(%{$params}));

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ZONE_CREATE_OK',
        msgargs => [zone => $params->{Name}],
    );

    $self->app->gms_new_event(locale => $self->cookie('language'));

    $self->stash(json => $result->to_hash());

    $result->unlock();
}

sub zone_update
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        Desc => {
            isa      => 'Str',
            optional => 1,
        },
        Addrs => {
            isa => 'ArrayRef[GMS::Network::Type::IP]',
            xor => ['Range', 'CIDR', 'Domain'],
        },
        Range => {
            isa => 'GMS::Network::Type::IPRange',
            xor => ['Addrs', 'CIDR', 'Domain'],
        },
        CIDR => {
            isa => 'GMS::Network::Type::CIDR',
            xor => ['Addrs', 'Range', 'Domain'],
        },
        Domain => {
            isa => 'Str',
            xor => ['Addrs', 'Range', 'CIDR'],
        },
    };

    $params = $self->validate($rule, $params);

    my $zone = $self->get_model('Zone')->find($params->{Name});

    if (!defined($zone))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network zone',
            name     => $params->{Name}
        );
    }

    my $updated = $zone->update(
        map  { lc($_) => $params->{$_}; }
        grep { $_ ne 'Name'; } keys(%{$params})
    );

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ZONE_UPDATE_OK',
        msgargs => [zone => $params->{Name}],
    );

    $self->app->gms_new_event(locale => $self->cookie('language'));

    $self->stash(json => $updated->to_hash);

    $updated->unlock();
}

sub zone_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
    };

    $params = $self->validate($rule, $params);

    my $zone = $self->get_model('Zone')->find($params->{Name});

    if (!defined($zone))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network zone',
            name     => $params->{Name}
        );
    }

    my $deleted = $zone->destroy();

    $self->api_status(
        level   => 'INFO',
        code    => 'NETWORK_ZONE_DELETE_OK',
        msgargs => [zone => $params->{Name}],
    );

    $self->app->gms_new_event(locale => $self->cookie('language'));

    $self->stash(json => $deleted);
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _init_devices
{
    my $self = shift;

    foreach my $dev ($self->all_devices())
    {
        my $model;

        if ($dev =~ m/\.\d+$/)
        {
            $model = $self->get_model('VLAN');
        }
        elsif ($dev =~ m/^bond\d+$/)
        {
            $model = $self->get_model('Bonding');
        }
        else
        {
            $model = $self->get_model('Device');
        }

        if (!defined($model))
        {
            warn "[WARN] Failed to get model: $dev";
            next;
        }

        if (!grep { $dev eq $_ } $model->list())
        {
            warn "[WARN] Model seems to be missed, will be created: $dev";
            $model->new(device => $dev);
        }
    }
}

sub all_devices
{
    my $self = @_ % 2 ? shift : undef;

    my $dh;

    opendir($dh, '/sys/class/net');
    my @devices = readdir($dh);
    closedir($dh);

    @devices = grep { !/^\.\.?$/ } @devices;
    @devices = grep { /\d+/; } @devices;
    @devices = sort { ($a =~ m/(\d+)/)[0] <=> ($b =~ m/(\d+)/)[0]; } @devices;

    return @devices;
}

sub _get_addrs
{
    my $self  = shift;
    my $model = shift;

    my @addrs;

    foreach my $idx (0 .. $model->count_ipaddrs - 1)
    {
        push(
            @addrs,
            {
                Device  => $model->device,
                IPAddr  => $model->get_ipaddr($idx),
                Netmask => $model->get_netmask($idx),
                Gateway => $model->get_gateway($idx),
                Static  => 'true',
            }
        );
    }

    foreach my $fip ($model->fips)
    {
        my ($ip, $prefix) = split(/\//, $fip);

        push(
            @addrs,
            {
                Device  => $model->device,
                IPAddr  => $ip,
                Netmask => prefix_to_netmask($prefix),
                Gateway => undef,
                Static  => 'false',
            }
        );
    }

    return @addrs;
}

sub _get_device_type
{
    my $self = shift;
    my $name = shift;

    if ($name =~ m/^bond\d+$/)
    {
        return 'Bonding';
    }
    elsif ($name =~ m/\.\d+$/)
    {
        return 'VLAN';
    }
    elsif ($name =~ m/^ib\d+$/)
    {
        return 'InfiniBand';
    }
    else
    {
        return 'Device';
    }
}

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->_init_devices();
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Network - GMS network management API controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 device

=head2 route

=head2 dns

=head1 METHODS

=head2 dns_info

=head2 dns_update

=head2 dns_reload

=head2 host_info

=head2 host_update

=head2 host_add

=head2 device_list

=head2 device_info

=head2 device_update

=head2 bonding_list

=head2 bonding_info

=head2 bonding_create

=head2 bonding_update

=head2 bonding_delete

=head2 address_list

=head2 route_table_list

=head2 route_table_info

=head2 route_table_create

=head2 route_table_delete

=head2 route_rule_list

=head2 route_rule_create

=head2 route_rule_update

=head2 route_rule_delete

=head2 route_entry_list

=head2 route_entry_create

=head2 route_entry_delete

=head2 route_reload

=head2 zone_list

=head2 zone_info

=head2 zone_create

=head2 zone_update

=head2 zone_delete

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
