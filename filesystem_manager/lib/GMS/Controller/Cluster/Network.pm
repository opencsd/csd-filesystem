package GMS::Controller::Cluster::Network;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Compare;
use GMS::Cluster::HTTP;
use GMS::Cluster::Etcd;
use GMS::Network::Type qw/netmask_to_prefix/;
use Net::IP;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Network';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'etcd' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::Etcd->new(); },
);

#--------------------------------------------------------------------------
#   Overrieded Methods
#---------------------------------------------------------------------------
override 'build_models' => sub
{
    my $self = shift;

    my $model = super();

    @{$model}{qw/DNS Hosts Route VIP Zone/} = (
        'GMS::Model::Cluster::Network::DNS',
        'GMS::Model::Cluster::Network::Hosts',
        'GMS::Model::Cluster::Network::Route',
        'GMS::Model::Cluster::Network::VIP',
        'GMS::Model::Cluster::Network::Zone',
    );

    return $model;
};

override 'dns_update' => sub
{
    my $self = shift;

    super();

    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/api/network/dns/update',
        body => $self->req->json,
    );

    foreach my $r (@resps)
    {
        if ($r->status != 200 || ref($r->entity) ne 'ARRAY')
        {
            warn
                "[ERR] Failed to update DNS resolvers: ${\$self->dumper($r)}";
            next;
        }
    }

    # :NOTE Mon Jan 31 05:47:13 PM KST 2022 by P.G.
    # Exception handling

    warn "[DEBUG] DNS resolvers has reloaded: ${\$self->dumper(\@resps)}";

    return $self->render();
};

override 'hosts_reload' => sub
{
    my $self = shift;

    my @resps
        = GMS::Cluster::HTTP->new->request(uri => '/api/network/hosts/reload',
        );

    my @hosts;

    foreach my $r (@resps)
    {
        if ($r->status != 200 || ref($r->entity) ne 'ARRAY')
        {
            warn "[ERR] Failed to get hosts: ${\$self->dumper($r)}";
            next;
        }

        foreach my $host (@{$r->entity})
        {
            push(@hosts, $host)
                if (!grep { Compare($host, $_); } @hosts);
        }
    }

    # :NOTE Mon Jan 31 05:47:13 PM KST 2022 by P.G.
    # Exception handling

    warn "[DEBUG] Hosts has reloaded: ${\$self->dumper(\@resps)}";

    return $self->render(json => \@hosts);
};

override 'address_update' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

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

    super();

    # update management IP address of a cluster info if prev IP address is
    # being used for internal management purpose.
    my $cinfo = $self->get_key(key => '/ClusterInfo', format => 'json');

    foreach my $node (keys(%{$cinfo->{node_infos}}))
    {
        my $mgmt_addr = $cinfo->{node_infos}->{$node}->{mgmt_ip};

        if ($mgmt_addr->{ip} eq $old_addr{ipaddr})
        {
            $mgmt_addr->{ip}      = $new_addr{ipaddr};
            $mgmt_addr->{netmask} = $new_addr{netmask};

            #$mgmt_addr->{gateway} = $new_addr{gateway};

            if (
                $self->etcd->set_key(
                    key    => '/ClusterInfo',
                    value  => $cinfo,
                    format => 'json',
                ) <= 0
                )
            {
                $self->throw_error('Failed to set /ClusterInfo');
            }

            last;
        }
    }

    # do not update mds_addresses if the prev and new IP addresses are same.
    if ($old_addr{ipaddr} eq $new_addr{ipaddr})
    {
        warn sprintf(
            '[DEBUG] Both IP addresses are same so not to be changed: %s %s',
            $old_addr{ipaddr}, $new_addr{ipaddr});

        return;
    }

    # Update /var/lib/gms/mds_addresses
    # - get_mds_addrs method from 'GMS::Cluster:Base of libgms path..'
    my $mds_addrs = $self->etcd->get_mds_addrs();

    foreach my $idx (0 .. $#{$mds_addrs})
    {
        next if ($old_addr{ipaddr} ne $mds_addrs->[$idx]);

        splice(@{$mds_addrs}, $idx--, 1);
        push(@{$mds_addrs}, $new_addr{ipaddr});

        warn sprintf('[DEBUG] splice & push new_addrs in mds_addrs: %s',
            $self->dumper($mds_addrs),
        );

        last;
    }

    if ($self->etcd->set_mds_addrs($mds_addrs))
    {
        $self->throw_error(
            "Failed to set MDS addresses: ${\Dumper($mds_addrs)}");
    }

RELOAD:
    my @resp
        = GMS::Cluster::HTTP->new->request(uri => '/api/network/hosts/reload',
        );

    my @hosts;

    foreach my $r (@resp)
    {
        if ($r->status != 200 || ref($r->entity) ne 'ARRAY')
        {
            warn "[ERR] Failed to get hosts: ${\$self->dumper($r)}";
            next;
        }

        foreach my $host (@{$r->entity})
        {
            push(@hosts, $host)
                if (!grep { Compare($host, $_); } @hosts);
        }
    }

    warn "[DEBUG] Hosts has reloaded: ${\$self->dumper(\@resp)}";

    return;
};

override device_list => sub
{
    my $self = shift;

    my @devices;

    my @resp
        = GMS::Cluster::HTTP->new->request(uri => '/api/network/device/list',
        );

    foreach my $resp (@resp)
    {
        if (ref($resp->entity) ne 'ARRAY')
        {
            warn "[ERR] Failed to get devices from ${\$resp->host}";
            next;
        }

        foreach my $device (@{$resp->entity})
        {
            $device->{Host} = $resp->hostname;

            push(@devices, $device);
        }
    }

    $self->api_status(code => 'NETWORK_DEV_LIST_OK');

    $self->stash(json => \@devices);
};

foreach my $action (qw/info update/)
{
    override "device_$action" => sub
    {
        my $self = shift;

        $self->throw_exception('NotSupported',
            feature => "API: /cluster/network/device/$action");
    };
}

override bonding_list => sub
{
    my $self = shift;

    my @bondings;

    my @resp = GMS::Cluster::HTTP->new->request(
        uri => '/api/network/bonding/list');

    foreach my $resp (@resp)
    {
        if (ref($resp->entity) ne 'ARRAY')
        {
            warn "[ERR] Failed to get bondings from ${\$resp->host}";
            next;
        }

        foreach my $bond (@{$resp->entity})
        {
            $bond->{Host} = $resp->hostname;

            push(@bondings, $bond);
        }
    }

    $self->api_status(code => 'NETWORK_BOND_LIST_OK');

    $self->stash(json => \@bondings);
};

foreach my $action (qw/info create update delete/)
{
    override "bonding_$action" => sub
    {
        my $self = shift;

        $self->throw_exception('NotSupported',
            feature => "API: /cluster/network/bonding/$action");
    };
}

override vlan_list => sub
{
    my $self = shift;

    my @vlans;

    my @resp
        = GMS::Cluster::HTTP->new->request(uri => '/api/network/vlan/list');

    foreach my $resp (@resp)
    {
        if (ref($resp->entity) ne 'ARRAY')
        {
            warn "[ERR] Failed to get VLAN device from ${\$resp->host}";
            next;
        }

        foreach my $vlan (@{$resp->entity})
        {
            $vlan->{Host} = $resp->hostname;

            push(@vlans, $vlan);
        }
    }

    $self->api_status(code => 'NETWORK_VLAN_LIST_OK');

    $self->stash(json => \@vlans);
};

foreach my $action (qw/info create update delete/)
{
    override "vlan_$action" => sub
    {
        my $self = shift;

        $self->throw_exception('NotSupported',
            feature => "API: /cluster/network/vlan/$action");
    };
}

foreach my $action (qw/list info create delete/)
{
    override "route_table_$action" => sub
    {
        my $self = shift;

        $self->throw_exception('NotSupported',
            feature => "API: /cluster/network/route/table/$action");
    };
}

foreach my $action (qw/list create update delete/)
{
    override "route_rule_$action" => sub
    {
        my $self = shift;

        $self->throw_exception('NotSupported',
            feature => "API: /cluster/network/route/rule/$action");
    };
}

foreach my $action (qw/create delete/)
{
    override "route_entry_$action" => sub
    {
        my $self   = shift;
        my $params = $self->req->json;

        super();

        my @resp = GMS::Cluster::HTTP->new->request(
            uri => '/api/network/route/reload');

        foreach my $r (@resp)
        {
            next if (!defined($r));

            if ($r->status != 200)
            {
                $self->throw_error(
                    message => 'Failed to reload network route'
                        . ": ${\$r->hostname}"
                        . ": ${\$self->dumper($r->data)}");
            }
        }

        $self->stash(json => undef);
    };
}

override 'route_reload' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my @resp = GMS::Cluster::HTTP->new->request(
        uri => '/api/network/route/reload');

    foreach my $r (@resp)
    {
        next if (!defined($r));

        if ($r->status != 200)
        {
            $self->throw_error(message => 'Failed to reload network route'
                    . ": ${\$r->hostname}"
                    . ": ${\$self->dumper($r->data)}");
        }
    }

    return;
};

#override 'route_entry_list' => sub
#{
#    my $self   = shift;
#    my $params = $self->req->json;
#
#    my @entries;
#
#    my @resp = GMS::Cluster::HTTP->new->request(
#        uri => '/api/network/route/entry/list',
#    );
#
#    foreach my $resp (@resp)
#    {
#        next if (!defined($resp));
#
#        if ($resp->status != 200)
#        {
#            $self->throw_error(
#                message => "Failed to get route entry list: ${\$resp->hostname}"
#            );
#        }
#
#        if (ref($resp->data->{entity}) ne 'ARRAY')
#        {
#            $self->throw_error(
#                message => "Invalid response entity: ${\$resp->hostname}: ${\$self->dumper($resp->data)}"
#            );
#        }
#
#        push(@entries, @{$resp->data->{entity}});
#    }
#
#    $self->api_status(
#        level => 'INFO',
#        code  => 'NETWORK_ROUTE_ENTRY_LIST_OK',
#    );
#
#    $self->stash(json => \@entries);
#};

override '_init_devices' => sub
{
    return;
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub list_vip_groups
{
    my $self   = shift;
    my $params = $self->req->json;

    my @result;

    foreach my $name ($self->get_model('VIP')->list())
    {
        my $model = $self->get_model('VIP')->find($name);

        if (!defined($model))
        {
            $self->throw_exception(
                'NotFound',
                resource => 'VIP group',
                name     => $params->{Name}
            );
        }

        push(@result, $model->to_hash());
    }

    $self->api_status(
        level => 'INFO',
        code  => 'CLST_VIP_GROUP_LIST_OK',
    );

    $self->render(json => \@result);
}

sub create_vip_group
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'NotEmptyStr',
        },
    };

    $params = $self->validate($rule, $params);

    my $model = $self->get_model('VIP')->find($params->{Name});

    if (defined($model))
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'VIP Group',
            name     => $params->{Name},
        );
    }

    $model = $self->get_model('VIP')->new(name => $params->{Name});

    $self->api_status(
        level   => 'INFO',
        code    => 'CLST_VIP_GROUP_CREATE_OK',
        msgargs => [name => $params->{Name}],
    );

    $self->render(json => $model->to_hash);
}

sub delete_vip_group
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'NotEmptyStr',
        },
    };

    $params = $self->validate($rule, $params);

    my $found = $self->get_model('VIP')->find($params->{Name});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'VIP group',
            name     => $params->{Name}
        );
    }

    $found->delete();

    my $retval = $found->to_hash();

    $self->api_status(
        level   => 'INFO',
        code    => 'CLST_VIP_GROUP_DELETE_OK',
        msgargs => [name => $params->{Name}],
    );

    $self->render(json => $retval);
}

sub add_vip_host
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'NotEmptyStr',
        },
        Host => {
            isa => 'NotEmptyStr',
        },
        Device => {
            isa => 'NotEmptyStr',
        },
        Length => {
            isa => 'NotEmptyStr',
        },
    };

    $params = $self->validate($rule, $params);

    my $found = $self->get_model('VIP')->find($params->{Name});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'VIP group',
            name     => $params->{Name}
        );
    }

    $found->add_host(
        host   => $params->{Host},
        device => $params->{Device},
        length => $params->{Length},
    );

    $found->unlock();

    # reload
    my @resp = GMS::Cluster::HTTP->new->request(uri => '/api/ctdb/reload',);

    warn "[DEBUG] CTDB has reloaded: ${\$self->dumper(\@resp)}";

    @resp = GMS::Cluster::HTTP->new->request(
        uri  => '/api/ctdb/control',
        body => {Command => 'reloadnodes'},
    );

    warn "[DEBUG] CTDB has controlled: ${\$self->dumper(\@resp)}";

    $self->api_status(
        level   => 'INFO',
        code    => 'CLST_VIP_HOST_ADD_OK',
        msgargs => [
            group => $params->{Name},
            host  => $params->{Host},
        ],
    );

    $self->stash(json => {});
}

sub remove_vip_host
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'NotEmptyStr',
        },
        Host => {
            isa => 'NotEmptyStr',
        },
        Device => {
            isa => 'NotEmptyStr',
        },
        Length => {
            isa => 'NotEmptyStr',
        },
    };

    $params = $self->validate($rule, $params);

    my $found = $self->get_model('VIP')->find($params->{Name});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'VIP group',
            name     => $params->{Name}
        );
    }

    $found->remove_host(
        host   => $params->{Host},
        device => $params->{Device},
        length => $params->{Length},
    );

    $found->unlock();

    # reload
    my @resp = GMS::Cluster::HTTP->new->request(uri => '/api/ctdb/reload',);

    warn "[DEBUG] CTDB has reloaded: ${\$self->dumper(\@resp)}";

    @resp = GMS::Cluster::HTTP->new->request(
        uri  => '/api/ctdb/control',
        body => {Command => 'reloadnodes'},
    );

    warn "[DEBUG] CTDB has controlled: ${\$self->dumper(\@resp)}";

    $self->api_status(
        level   => 'INFO',
        code    => 'CLST_VIP_HOST_REMOVE_OK',
        msgargs => [
            group => $params->{Name},
            host  => $params->{Host},
        ],
    );

    $self->stash(json => {});
}

sub add_vip_addr
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'NotEmptyStr',
        },

#        Host => {
#            isa => 'NotEmptyStr',
#        },
#        Device => {
#            isa => 'NotEmptyStr',
#        },
        IPAddrs => {
            isa =>
                'ArrayRef[GMS::Network::Type::CIDR|GMS::Network::Type::CIDRRange]',
        },
    };

    $params = $self->validate($rule, $params);

    # :TODO 05/08/2019 01:15:16 PM: by P.G.
    # check existance of network device
#    if (!$self->nic_exist($params->{Interface}))
#    {
#        $self->throw_exception(
#            'NotFound',
#            resource => 'network interface',
#            name     => $params->{Interface}
#        );
#    }
#
#    if ($self->is_overlapped($params))
#    {
#        $self->throw_error(
#            level => 'ERROR',
#            code  => 'CLST_VIP_EXIST_OVERLAPPED_ONE'
#        );
#    }

    my $found = $self->get_model('VIP')->find($params->{Name});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'VIP group',
            name     => $params->{Name},
        );
    }

    foreach my $ipaddr (@{$params->{IPAddrs}})
    {
        $found->add_ipaddr($ipaddr);
    }

    my $retval = $found->to_hash();

    $found->unlock();

    # reload
    my @resp = GMS::Cluster::HTTP->new->request(uri => '/api/ctdb/reload',);

    warn "[DEBUG] CTDB has reloaded: ${\$self->dumper(\@resp)}";

    @resp = GMS::Cluster::HTTP->new->request(
        uri  => '/api/ctdb/control',
        body => {Command => 'reloadips'},
    );

    warn "[DEBUG] CTDB has controlled: ${\$self->dumper(\@resp)}";

    $self->api_status(
        level   => 'INFO',
        code    => 'CLST_VIP_IP_ADD_OK',
        msgargs => [
            group => $params->{Name},
            ip    => join(', ', @{$params->{IPAddrs}}),
        ],
    );

    $self->render(json => $retval);
}

sub remove_vip_addr
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'NotEmptyStr',
        },

#        Host => {
#            isa => 'NotEmptyStr',
#        },
#        Device => {
#            isa => 'NotEmptyStr',
#        },
        IPAddrs => {
            isa =>
                'ArrayRef[GMS::Network::Type::CIDR|GMS::Network::Type::CIDRRange]',
        },
    };

    $params = $self->validate($rule, $params);

    # :TODO 05/08/2019 01:15:16 PM: by P.G.
    # check existance of network device
#    if (!$self->nic_exist($params->{Interface}))
#    {
#        $self->throw_exception(
#            'NotFound',
#            resource => 'network interface',
#            name     => $params->{Interface}
#        );
#    }

    my $found = $self->get_model('VIP')->find($params->{Name});

    if (!defined($found))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'VIP group',
            name     => $params->{Name}
        );
    }

    foreach my $ipaddr (@{$params->{IPAddrs}})
    {
        $found->remove_ipaddr($ipaddr);
    }

    my $retval = $found->to_hash();

    $found->unlock();

    # reload
    my @resp = GMS::Cluster::HTTP->new->request(uri => '/api/ctdb/reload',);

    warn "[DEBUG] CTDB has reloaded: ${\$self->dumper(\@resp)}";

    @resp = GMS::Cluster::HTTP->new->request(
        uri  => '/api/ctdb/control',
        body => {Command => 'reloadips'},
    );

    warn "[DEBUG] CTDB has controlled: ${\$self->dumper(\@resp)}";

    $self->api_status(
        level   => 'INFO',
        code    => 'CLST_VIP_IP_REMOVE_OK',
        msgargs => [
            group => $params->{Name},
            ip    => join(', ', @{$params->{IPAddrs}}),
        ],
    );

    $self->render(json => $retval);
}

sub reload_vip
{
    my $self   = shift;
    my $params = $self->req->json;

    # find all VIP groups that this node belonged and then
    # - add all nodes of this groups
    # - add all IP addrs ofthis group
    foreach my $group ($self->get_model('VIP')->list())
    {
        my $found = $self->get_model('VIP')->find($group);

        if (!defined($found))
        {
            $self->throw_exception(
                'NotFound',
                resource => 'VIP group',
                name     => $group,
            );
        }

        next if (!$found->host_exists(short()));

        $found->reload();
        $found->unlock();
    }

    # reload
    my @resp = GMS::Cluster::HTTP->new->request(uri => '/api/ctdb/reload',);

    foreach my $r (@resp)
    {
        next if (!defined($r));

        if ($r->status != 200)
        {
            $self->throw_error(
                message => "Failed to reload CTDB: ${\$r->host} :"
                    . $self->dumper($r->data));
        }
    }

    warn "[DEBUG] CTDB has reloaded: ${\$self->dumper(\@resp)}";

    @resp = GMS::Cluster::HTTP->new->request(
        uri  => '/api/ctdb/control',
        body => {Command => 'reloadnodes'},
    );

    foreach my $r (@resp)
    {
        next if (!defined($r));

        if ($r->status != 200)
        {
            $self->throw_error(
                message => "Failed to control CTDB: ${\$r->host} :"
                    . $self->dumper($r->data));
        }
    }

    warn "[DEBUG] CTDB has controlled: ${\$self->dumper(\@resp)}";

    return;
}

## :WARNING 08/31/2019 12:05:14 AM: by P.G.
## current GWM UI does not support update specific VIP range because it did not
## consider a using of multiple VIP addresses on an one network device.
#sub update_vip
#{
#    my $self   = shift;
#    my $params = $self->req->json;
#
#    state $rule = {
#        Interface => {
#            isa => 'Str',
#        },
#        IPAddrs => {
#            isa      => 'ArrayRef[GMS::Network::Type::CIDR|GMS::Network::Type::CIDRRange]',
#            optional => 1,
#        },
#    };
#
#    $params = $self->validate($rule, $params);
#
#    # :TODO 05/08/2019 01:15:16 PM: by P.G.
#    # check existance of network device
##    if (!$self->nic_exist($params->{Interface}))
##    {
##        $self->throw_exception(
##            'NotFound',
##            resource => 'network interface',
##            name     => $params->{Interface}
##        );
##    }
#
#    my $updated = $self->get_model('VIP')->find($params->{Interface});
#
#    if (!defined($updated))
#    {
#        $self->throw_exception(
#            'NotFound',
#            resource => 'VIP',
#            name     => $params->{Interface}
#        );
#    }
#
##    $updated->update(
##        map {
##            lc($_) => $params->{$_};
##        } (grep { $_ !~ m/^(?:Interface)$/; } keys(%{$params}))
##    );
#
#    # :TODO 08/31/2019 12:05:14 AM: by P.G.
#    # we should find overlapped addresses array and then update it.
#    foreach my $ipaddr (@{$params->{IPAddrs}})
#    {
#        $updated->add_ipaddr($ipaddr);
#    }
#
#    my @resp = GMS::Cluster::HTTP->new->request(
#        uri => '/api/ctdb/reload',
#    );
#
#    warn "[DEBUG] CTDB has reloaded: ${\$self->dumper(\@resp)}";
#
#    @resp = GMS::Cluster::HTTP->new->request(
#        uri  => '/api/ctdb/control',
#        body => { Command => 'reloadips' },
#    );
#
#    warn "[DEBUG] CTDB has controlled: ${\$self->dumper(\@resp)}";
#
#    $self->api_status(
#        level => 'INFO',
#        code  => 'CLST_VIP_UPDATE_OK'
#    );
#
#    $self->render(json => $updated->to_hash);
#}

#sub nic_exist
#{
#    my $self = shift;
#    my $name = shift;
#
#    # :TODO 05/09/2019 05:26:24 PM: by P.G.
#    # check existance of NIC
#    my $model;
#
#    if ($name =~ m/\.\d+$/)
#    {
#        $model = $self->get_model('VLAN')->find($name);
#    }
#    elsif ($name =~ m/^bond/)
#    {
#        $model = $self->get_model('Bonding')->find($name);
#    }
#    else
#    {
#        $model = $self->get_model('Device')->find($name);
#    }
#
#    return defined($model);
#}

#sub is_overlapped
#{
#    my $self   = shift;
#    my $params = shift;
#
#    my @targets = ();
#
#    push(@targets,
#        map {
#            $_ =~ s/\/\d+$//g;
#            Net::IP->new($_);
#        } @{$params->{IPAddrs}});
#
#    my @vips = $self->get_model('VIP')->list();
#
#    foreach my $interface (@vips)
#    {
#        my $vip = $self->get_model('VIP')->new(interface => $interface);
#
#        my @addrs = map {
#            $_ =~ s/\/\d+$//g;
#            Net::IP->new($_);
#        } @{$vip->ipaddrs};
#
#        foreach my $target (@targets)
#        {
#            foreach my $addr (@addrs)
#            {
#                if ($target->overlaps($addr))
#                {
#                    return $interface;
#                }
#            }
#        }
#    }
#
#    return;
#}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Network - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=over

=item L<GMS::Controller::Network>

=back

=cut

