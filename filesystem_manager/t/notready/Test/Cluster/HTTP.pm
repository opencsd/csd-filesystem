package Test::Cluster::HTTP;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use Test::MockModule;

use JSON qw/to_json/;
use Sys::Hostname::FQDN qw/short/;

has 'hostname' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
);

has 'mock' => (
    is      => 'rw',
    isa     => 'Object',
    lazy    => 1,
    default => sub
    {
        my $self = shift;
        my $mock = Test::MockModule->new('GMS::Cluster::HTTP');

        $mock->mock('short' => sub { return "${\$self->hostname}-1"; });

        return $mock;
    },
);

sub test_startup
{
    my $self = shift;

    use_ok('GMS::Cluster::HTTP');
    use_ok('Mock::Model::Base');

    my $cinfo = {
        cluster => {
            cluster_name => $self->hostname,
            active       => 4,
            total        => 4,
            service_fip  => [
                {
                    interface => "bond1",
                    netmask   => "255.255.252.0",
                    start     => "192.168.3.15",
                    end       => "192.168.3.16",
                }
            ],
        },
        node_infos => {
            "${\$self->hostname}-1" => {
                activated  => 1,
                mgmt_ip    => "192.168.2.37",
                service_ip => ["192.168.3.16"],
                storage_ip => {
                    ip        => "10.10.1.37",
                    interface => "bond0"
                },
            },
            "${\$self->hostname}-2" => {
                activated  => 1,
                mgmt_ip    => "192.168.2.40",
                service_ip => ["192.168.3.15"],
                storage_ip => {
                    ip        => "10.10.1.40",
                    interface => "bond0",
                },
            },
            "${\$self->hostname}-3" => {
                activated  => 1,
                mgmt_ip    => "192.168.2.41",
                service_ip => [],
                storage_ip => {
                    ip        => "10.10.1.41",
                    interface => "bond0",
                },
            },
            "${\$self->hostname}-4" => {
                activated  => 1,
                mgmt_ip    => "192.168.2.38",
                service_ip => [],
                storage_ip => {
                    ip        => "10.10.1.38",
                    interface => "bond0",
                },
            },
        },
        config => {
            mds        => [map { "${\$self->hostname}-$_"; } (1 .. 3)],
            cluster_fs => ["gluster"],
            native_fs  => "xfs"
        }
    };

    $self->mock_data(
        data => {
            '/ClusterInfo' => to_json($cinfo, {utf8 => 1}),
        }
    );
}

sub test_without_targets : Test(no_plan)
{
    my $self = shift;

    my $http = GMS::Cluster::HTTP->new();

    ok(defined($http), 'GMS::Cluster::HTTP->new()');

    my @return = ();

    @return = $http->request(
        uri  => '/api/cluster/general/master',
        body => {lang => 'eng'}
    );

    cmp_ok(scalar(grep { defined($_); } @return),
        '==', 4, '->request(uri => "...") is returned with 4 elements');

    @return = $http->request(
        uri       => '/api/cluster/general/master',
        restricts => {self => 1}
    );

    cmp_ok(
        scalar(grep { defined($_); } @return),
        '==',
        3,
        '->request(uri => "...", restricts => { self => 1 }) is returned with 3 element'
    );

    @return = $http->request(
        uri       => '/api/cluster/general/master',
        restricts => {mds => 1}
    );

    cmp_ok(
        scalar(grep { defined($_); } @return),
        '==',
        1,
        '->request(uri => "...", restricts => { mds => 1 }) is returned with 1 element'
    );
}

sub test_with_targets : Test(no_plan)
{
    my $self = shift;

    my $http = GMS::Cluster::HTTP->new();

    ok(defined($http), 'GMS::Cluster::HTTP->new()');

    my $targets = [
        {
            host    => "${\$self->hostname}-1",
            port    => 3000,
            uri     => '/api/cluster/general/master',
            body    => {lang => 'eng'},
            timeout => 30,
        },
        {
            host    => "192.168.2.40",
            port    => 3000,
            uri     => '/api/cluster/general/master',
            body    => {lang => 'eng'},
            timeout => 30,
        },
    ];

    my @return = ();

    @return = $http->request(
        targets   => $targets,
        restricts => {self => 1},
    );

    cmp_ok(
        scalar(grep { defined($_); } @return),
        '==',
        1,
        '->request(targets => [...], restricts => { self => 1 }) is returned with 1 elements'
    );

    @return = $http->request(
        targets   => $targets,
        restricts => {mds => 1},
    );

    cmp_ok(
        scalar(grep { defined($_); } @return),
        '==',
        0,
        '->request(targets => [...], restricts => { mds => 1 }) is returned with empty list'
    );
}

1;

=encoding utf8

=head1 NAME

Test::Cluster::HTTP - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

