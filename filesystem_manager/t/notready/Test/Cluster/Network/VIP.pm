package Test::Cluster::Network::VIP;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::Network::VIP';

use Net::IP;
use GMS::Network::Type;

has 'mock_file' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/mnt/private/CTDB/public_addresses',
);

sub test_startup
{
    my $self = shift;

    my $t = $self->t;

    $t->app->routes->post('/api/cluster/network/vip/list')->to(
        namespace => 'Mock::Controller::Cluster::Network',
        action    => 'vip_list'
    );

    $t->app->routes->post('/api/cluster/network/vip/create')->to(
        namespace => 'Mock::Controller::Cluster::Network',
        action    => 'vip_create'
    );

    $t->app->routes->post('/api/cluster/network/vip/update')->to(
        namespace => 'Mock::Controller::Cluster::Network',
        action    => 'vip_update'
    );

    $t->app->routes->post('/api/cluster/network/vip/delete')->to(
        namespace => 'Mock::Controller::Cluster::Network',
        action    => 'vip_delete'
    );
}

sub test_setup
{
    my $self = shift;

    return $self->test_skip('This test will not performed');
}

sub test_teardown
{
    my $self = shift;

    mock_del_key(
        key     => '/Cluster/Network/VIP',
        options => {recursive => 'true'}
    );

    unlink($self->mock_file);
}

sub test_test_vip_list : Test(no_plan)
{
    my $self = shift;

#    explain(mock_get_key(
#        key     => "/Cluster/Network/VIP",
#        options => { recursive => 1 }
#    ));

    my $t = $self->t->post_ok('/api/cluster/network/vip/list');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Reading list of service IP has succeeded/)
        ->json_is('/statuses/0/code' => 'CLST_VIP_LIST_OK');

    explain($t->tx->res->json);
}

sub test_vip_create_param_validation : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/cluster/network/vip/create');

    my $regex = qr/Missing parameter: (?:Interface|IPAddrs)/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => $regex)
        ->json_is('/statuses/1/code' => 'MISSING_PARAM')
        ->json_like('/statuses/1/message' => $regex);

    $t = $self->t->post_ok(
        '/api/cluster/network/vip/create',
        json => {
            Interface => 'ens32',
            IPAddrs   => [map { "192.168.0.$_"; } (10 .. 20)],
        }
    );

    $regex = qr/(?:Invalid parameter value: IPAddrs)/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg'                => qr/$regex/)
        ->json_like('/statuses/0/code'    => qr/INVALID_VALUE/)
        ->json_like('/statuses/0/message' => qr/$regex/);

    $t = $self->t->post_ok(
        '/api/cluster/network/vip/create',
        json => {

#            Interface => 'ens32',
            IPAddrs => [map { "192.168.0.$_/24"; } (10 .. 20)],
        }
    );

    $regex = qr/Missing parameter: (?:Interface)/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/$regex/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => $regex);

    $t = $self->t->post_ok(
        '/api/cluster/network/vip/create',
        json => {
            Interface => 'ens32',
            IPAddrs   => 'invalid-addrs',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid parameter value: IPAddrs/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like(
        '/statuses/0/message' => qr/Invalid parameter value: IPAddrs/);
}

sub test_vip_create : Test(no_plan)
{
    my $self = shift;
    my %args = @_;

    my $t = $self->t->post_ok(
        '/api/cluster/network/vip/create',
        json => {
            Interface => $args{interface} // 'ens32',
            IPAddrs   => $args{ipaddrs}
                // [map { "192.168.0.$_/24"; } (10 .. 20)],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Adding new service IP has succeeded/)
        ->json_is('/statuses/0/code' => 'CLST_VIP_CREATE_OK');

#    explain($t->tx->res->json);
#    explain(mock_data());

    my $req  = $t->tx->req->json;
    my $data = mock_get_key(
        key     => "/Cluster/Network/VIP/$req->{Interface}",
        options => {recursive => 1}
    );

    # :TODO 06/12/2019 02:34:50 PM: by P.G.
    # merge continuous addresses
    my $expected = sprintf('%s-%s/%d',
        (split(/\//, $req->{IPAddrs}->[0]))[0],
        (split(/\//, $req->{IPAddrs}->[-1]))[0],
        (split(/\//, $req->{IPAddrs}->[0]))[1]);

    cmp_ok($data->{ipaddrs}->[0],
        'eq', $expected, "ipaddrs[0] is \"$expected\"");

    my $ip     = Net::IP->new((split(/\//, $expected))[0]);
    my $prefix = (split(/\//, $expected))[1];

    do
    {
        cmp_ok(
            `cat ${\$self->mock_file} | grep "${\$ip->ip()}/$prefix" | wc -l`,
            '==',
            1
        );
    } while (++$ip);
}

sub test_vip_update : Test(no_plan)
{
    my $self = shift;

    $self->test_vip_create();

    my $t = $self->t->post_ok(
        '/api/cluster/network/vip/update',
        json => {
            Interface => 'ens32',
            IPAddrs   => ['192.168.0.20-192.168.0.30/24'],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Updating service IP has succeeded/)
        ->json_is('/statuses/0/code' => 'CLST_VIP_UPDATE_OK');

    my $req  = $t->tx->req->json;
    my $data = mock_get_key(
        key     => '/Cluster/Network/VIP/ens32',
        options => {recursive => 1}
    );

    my $expected = $req->{IPAddrs}->[0];

    cmp_ok($data->{ipaddrs}->[0],
        'eq', $expected, "ipaddrs[0] is \"$expected\"");

#    explain(`cat ${\$self->mock_file}`);

    map {
        cmp_ok(
            int(`cat ${\$self->mock_file} | grep "192.168.0.$_/24" | wc -l`),
            '==',
            1
        );
    } (20 .. 30);
}

sub test_vip_delete : Test(no_plan)
{
    my $self = shift;

    $self->test_vip_create(
        interface => 'ens34',
        ipaddrs   => [map { "192.168.1.$_/24"; } (10 .. 20)],
    );

    my $t = $self->t->post_ok(
        '/api/cluster/network/vip/delete',
        json => {
            Interface => 'ens34',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Removing service IP has succeeded/)
        ->json_is('/statuses/0/code' => 'CLST_VIP_DELETE_OK');

#    explain($t->tx->res->json);

    my $data = mock_get_key(
        key     => '/Cluster/Network/VIP/ens34',
        options => {recursive => 1}
    );

    ok(!defined($data), 'VIP for ens34 not found');

#    explain(`cat ${\$self->mock_file}`);

    cmp_ok(`cat ${\$self->mock_file} | grep 192.168.1. | wc -l`, '==', 0);
}

sub netmask_to_prefix
{
    my $full_mask = unpack('N', pack('C4', split(/\./, shift)));
    my $prefix    = 0;

    for (0 .. 31)
    {
        $prefix++ if ($full_mask >> $_ & 0x1);
    }

    return $prefix;
}

1;

=encoding utf8

=head1 NAME

Test::Cluster::Network::VIP - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

