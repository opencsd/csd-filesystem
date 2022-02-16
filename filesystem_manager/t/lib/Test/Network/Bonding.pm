package Test::Network::Bonding;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::Network::Device';

has 'bond_uri' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub
    {
        {
            list   => '/api/network/bonding/list',
            info   => '/api/network/bonding/info',
            create => '/api/network/bonding/create',
            update => '/api/network/bonding/update',
            delete => '/api/network/bonding/delete',
        }
    },
);

sub test_startup
{
    my $self = shift;

    $self->next::method(@_);

    map {
        $self->t->app->routes->post("/api/network/bonding/$_")->to(
            namespace  => $self->namespace,
            controller => $self->cntlr,
            action     => "bonding_$_",
        );
    } keys(%{$self->bond_uri});
}

sub test_setup
{
    my $self = shift;

    my $method = $self->test_report->current_method;

    if ($method->name =~ m/_device_/)
    {
        return $self->test_skip('This test will not performed');
    }

    $self->next::method(@_);

    $self->mock_bond_config_file(
        DEVICE       => 'bond0',
        IPADDR       => '192.168.0.10',
        NETMASK      => '255.255.252.0',
        GATEWAY      => '192.168.3.254',
        BONDING_OPTS => 'mode=0 miimon=100',
    );

    map { $self->mock_slave_config_file(DEVICE => $_, MASTER => 'bond0'); }
        qw/ens192 ens193/;

    $self->mock_bond_config_file(
        DEVICE       => 'bond1',
        IPADDR       => '10.10.0.10',
        NETMASK      => '255.255.255.0',
        GATEWAY      => '10.10.0.254',
        BONDING_OPTS => 'mode=1 miimon=100 primary=ens194',
    );

    map { $self->mock_slave_config_file(DEVICE => $_, MASTER => 'bond1'); }
        qw/ens194 ens195/;

#    $self->mock_bond_config_file(
#        DEVICE       => 'bond2',
#        IPADDR       => '192.168.0.10',
#        NETMASK      => '255.255.252.0',
#        GATEWAY      => '192.168.3.254',
#        BONDING_OPTS => 'mode=4 miimon=100 lacp_late=fast xmit_hash_policy=layer2+3',
#    );

#    $self->mock_slave_config_file(DEVICE => 'ens196', MASTER => 'bond2');
#    $self->mock_slave_config_file(DEVICE => 'ens197', MASTER => 'bond2');
}

sub mock_bond_config_file
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    my %data = (
        DEVICE         => $args{DEVICE},
        TYPE           => 'Bond',
        BOOTPROTO      => 'static',
        ONBOOT         => 'yes',
        IPADDR         => $args{IPADDR},
        NETMASK        => $args{NETMASK},
        GATEWAY        => $args{GATEWAY},
        BONDING_MASTER => 'yes',
        BONDING_OPTS   => $args{BONDING_OPTS},
    );

    $self->mock_write_nic_config(\%data);
}

sub mock_slave_config_file
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    my %data = (
        DEVICE    => $args{DEVICE},
        TYPE      => 'Ethernet',
        BOOTPROTO => 'none',
        ONBOOT    => 'yes',
        MASTER    => $args{MASTER},
        SLAVE     => 'yes',
    );

    $self->mock_write_nic_config(\%data);
}

sub test_bonding_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok($self->bond_uri->{list});

#    explain($t->tx->res->json);

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Bonding interface list is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_BOND_LIST_OK')
        ->json_like('/entity/0/Device' => qr/^bond(?:[0-1])$/)
        ->json_like('/entity/1/Device' => qr/^bond(?:[0-1])$/);

    my $data = $self->mock_get_key(
        key     => "/${\$self->hostname}/Network/Bonding",
        options => {recursive => 'true'}
    );

#    explain($data);

    ok(exists($data->{bond0}), 'bond0 appeared in etcd database');
    ok(exists($data->{bond1}), 'bond1 appeared in etcd database');
}

sub test_bonding_info
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/bonding/info');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Device/);

    $t = $self->t->post_ok(
        '/api/network/bonding/info',
        json => {
            Device => 'ens32',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network bonding not found: ens32/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND')
        ->json_like(
        '/statuses/0/message' => qr/Network bonding not found: ens32/);

    $t = $self->t->post_ok(
        '/api/network/bonding/info',
        json => {
            Device => 'bond0',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Bonding interface is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_BOND_INFO_OK');

#    explain($t->tx->res->json);
}

sub test_bonding_create : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/bonding/create');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Bonding interface is created/)
        ->json_is('/statuses/0/code'  => 'NETWORK_BOND_CREATE_OK')
        ->json_is('/entity/Device'    => 'bond2')
        ->json_is('/entity/Type'      => 'Bond')
        ->json_is('/entity/BootProto' => 'none')
        ->json_is('/entity/MTU'       => 1500)->json_is('/entity/Mode' => 0);

    my $data = $self->mock_get_key(
        key     => "/${\$self->hostname}/Network/Bonding",
        options => {recursive => 'true'},
    );

    ok(exists($data->{bond2}), 'bond2 appeared in etcd database');

    $data = $data->{bond2};

    cmp_ok($data->{device}, 'eq', 'bond2', 'device eq bond2');

    cmp_ok($data->{TYPE},      'eq', 'Bond', 'type eq Bond');
    cmp_ok($data->{BOOTPROTO}, 'eq', 'none', 'bootproto eq none');
    cmp_ok($data->{MTU},       '==', 1500,   'mtu == 1500');
    cmp_ok($data->{mode},      '==', 0,      'mode == 0');

    $data = `cat ${\$self->script_dir}/ifcfg-bond2`;

    like($data, qr/DEVICE="bond2"/m,       'DEVICE="bond2"');
    like($data, qr/TYPE="Bond"/m,          'TYPE="Bond"');
    like($data, qr/BOOTPROTO="none"/m,     'BOOTPROTO="none"');
    like($data, qr/MTU="1500"/m,           'MTU="1500"');
    like($data, qr/BONDING_MASTER="yes"/m, 'BONDING_MASTER="yes"');
    like(
        $data,
        qr/BONDING_OPTS="mode=0 miimon=100 use_carrier=0"/m,
        'BONDING_OPTS="mode=0 miimon=100 use_carrier=0""'
    );

    $t = $self->t->post_ok(
        '/api/network/bonding/delete',
        json => {
            Device => 'bond2',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Bonding interface is deleted/)
        ->json_is('/statuses/0/code' => 'NETWORK_BOND_DELETE_OK');
}

sub test_bonding_update : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/bonding/update');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Device/);

    $t = $self->t->post_ok(
        '/api/network/bonding/update',
        json => {
            Device  => 'bond0',
            OnBoot  => 'no',
            IPAddr  => ['192.168.0.10',  '192.168.0.11'],
            Netmask => ['255.255.255.0', '255.255.252.0'],
            Gateway => ['192.168.0.1',   '192.168.3.254'],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Bonding interface is updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_BOND_UPDATE_OK');

    my $data = $self->mock_get_key(
        key     => "/${\$self->hostname}/Network/Bonding/bond0",
        options => {recursive => 'true'}
    );

    cmp_ok($data->{device},    'eq', 'bond0',  'device: bond0');
    cmp_ok($data->{BOOTPROTO}, 'eq', 'static', 'bootproto: static');
    cmp_ok($data->{ONBOOT},    'eq', 'no',     'onboot: no');
    cmp_ok($data->{TYPE},      'eq', 'Bond',   'type: Bond');
    cmp_ok($data->{IPADDR}->[0],
        'eq', '192.168.0.10', 'ipaddr[0]: 192.168.0.10');
    cmp_ok($data->{IPADDR}->[1],
        'eq', '192.168.0.11', 'ipaddr[0]: 192.168.0.11');
    cmp_ok($data->{NETMASK}->[0],
        'eq', '255.255.255.0', 'netmask[0]: 255.255.255.0');
    cmp_ok($data->{NETMASK}->[1],
        'eq', '255.255.252.0', 'netmask[1]: 255.255.252.0');
    cmp_ok($data->{GATEWAY}->[0],
        'eq', '192.168.0.1', 'gateway[0]: 192.168.0.1');
    cmp_ok($data->{GATEWAY}->[1],
        'eq', '192.168.3.254', 'gateway[1]: 192.168.3.254');
}

sub test_bonding_delete : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/bonding/delete');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Device/);

    $t = $self->t->post_ok(
        '/api/network/bonding/delete',
        json => {
            Device => 'bond1',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Bonding interface is deleted/)
        ->json_is('/statuses/0/code' => 'NETWORK_BOND_DELETE_OK');

    my $data = $self->mock_get_key(
        key     => "/${\$self->hostname}/Network/Bonding/bond1",
        options => {recursive => 'true'}
    );

    ok(!defined($data), 'bond1 does not exist');

    ok(
        !-e "${\$self->script_dir}/ifcfg-bond1",
        "${\$self->script_dir}/ifcfg-bond1 is deleted"
    );

    map {
        $data = `cat ${\$self->script_dir}/ifcfg-$_`;

        like($data, qr/DEVICE="$_"/m,      "DEVICE=\"$_\"");
        like($data, qr/TYPE="Ethernet"/m,  'TYPE="Ethernet"');
        like($data, qr/BOOTPROTO="none"/m, 'BOOTPROTO="none"');
        like($data, qr/ONBOOT="no"/m,      'ONBOOT="no"');
        unlike($data, qr/MASTER/m, 'MASTER="..." does not exist');
        unlike($data, qr/SLAVE/m,  'SLAVE="..." does not exist');
    } qw/ens194 ens195/;
}

#__PACKAGE__->add_filter(
#    sub {
#        my ($class, $method) = @_;
#        return $class eq __PACKAGE__;
#    }
#);

1;

=encoding utf8

=head1 NAME

Test::Network::Bonding - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

