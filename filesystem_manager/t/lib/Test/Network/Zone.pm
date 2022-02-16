package Test::Network::Zone;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use Test::Most;
use File::Path qw/make_path/;
use Sys::Hostname::FQDN qw/short/;
use JSON qw/to_json/;

has 'namespace' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Mock::Controller',
);

has 'cntlr' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Network',
);

has 'uri' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub
    {
        {
            list   => '/api/network/zone/list',
            info   => '/api/network/zone/info',
            create => '/api/network/zone/create',
            update => '/api/network/zone/update',
            delete => '/api/network/zone/delete',
        };
    }
);

has 'scope' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
);

sub test_startup
{
    my $self = shift;

    $self->next::method(@_);

    my $t = $self->t;

    $t->app->routes->post($self->uri->{list})->to(
        namespace  => $self->namespace,
        controller => $self->cntlr,
        action     => 'zone_list'
    );

    $t->app->routes->post($self->uri->{info})->to(
        namespace  => $self->namespace,
        controller => $self->cntlr,
        action     => 'zone_info'
    );

    $t->app->routes->post($self->uri->{create})->to(
        namespace  => $self->namespace,
        controller => $self->cntlr,
        action     => 'zone_create'
    );

    $t->app->routes->post($self->uri->{update})->to(
        namespace  => $self->namespace,
        controller => $self->cntlr,
        action     => 'zone_update'
    );

    $t->app->routes->post($self->uri->{delete})->to(
        namespace  => $self->namespace,
        controller => $self->cntlr,
        action     => 'zone_delete'
    );
}

sub test_setup
{
    my $self = shift;

    $self->mock_config_file();
    $self->mock_etcd_data();
}

sub test_teardown
{
    my $self = shift;

    $self->unmock_data();
}

sub mock_config_file
{
    my $dir = '/tmp/usr/gms/config';

    if (-e $dir && !-d $dir)
    {
        die "path exists but not a directory: $dir";
    }

    if (!-d $dir && make_path($dir, {error => \my $err}) == 0)
    {
        my ($path, $msg) = %{$err->[0]};

        if ($path eq '')
        {
            die "Generic error: $msg";
        }
        else
        {
            die "Failed to make directory: $path: $msg";
        }
    }

    my $file_zone = '/tmp/usr/gms/config/zone.conf';

    open(my $fh_zone, '>', $file_zone)
        || die "Failed to open file: $file_zone: $!";

    print $fh_zone to_json(
        {
            public => {
                name => "public",
                desc => "",
                type => "cidr",
                cidr => "0.0.0.0/24"
            },
            private => {
                name  => "private",
                desc  => "",
                type  => "addrs",
                addrs => ["192.168.0.1", "192.168.0.10", "192.168.0.20"]
            },
        },
        {utf8 => 1, pretty => 1}
    );

    close($fh_zone);
}

sub mock_etcd_data
{
    my $self  = shift;
    my $scope = $self->scope();

    $self->mock_data(
        data => {
            "/$scope/Network/Zone/public/name"     => 'public',
            "/$scope/Network/Zone/public/desc"     => '',
            "/$scope/Network/Zone/public/type"     => 'cidr',
            "/$scope/Network/Zone/public/cidr"     => '0.0.0.0/24',
            "/$scope/Network/Zone/private/name"    => 'private',
            "/$scope/Network/Zone/private/desc"    => '',
            "/$scope/Network/Zone/private/type"    => 'addrs',
            "/$scope/Network/Zone/private/addrs/0" => '192.168.0.1',
            "/$scope/Network/Zone/private/addrs/1" => '192.168.0.10',
            "/$scope/Network/Zone/private/addrs/2" => '192.168.0.20',
        }
    );
}

sub test_zone_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok($self->uri->{list});

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network zone list is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_ZONE_LIST_OK')
        ->json_like('/entity/0/Name' => qr/^(?:private|public|dev3-addrs)/)
        ->json_like('/entity/1/Name' => qr/^(?:private|public|dev3-addrs)/);

#    explain($t->tx->res->json);
}

sub test_zone_info : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok($self->uri->{info});

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Name/);

    $t = $self->t->post_ok(
        $self->uri->{info},
        json => {
            Name => 'unknown'
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network zone not found: unknown/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        $self->uri->{info},
        json => {
            Name => 'private'
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network zone is retrieved: private/)
        ->json_is('/statuses/0/code' => 'NETWORK_ZONE_INFO_OK')
        ->json_is('/entity/Name'     => 'private');

#    explain($t->tx->res->json);
}

sub test_zone_create : Test(no_plan)
{
    my $self = shift;
    my %args = @_;

    my $t = $self->t->post_ok($self->uri->{create});

    $t->status_is(422)->json_is('/success' => 0)
        ->or(sub { explain($t->tx->res->json); });

    my $resp = $t->tx->res->json;

    ok(
        (
            grep {
                $_->{code} eq 'MISSING_PARAM'
                    && $_->{message} =~ m/^Missing parameter: Name/;
            } @{$resp->{statuses}}
        ),
        "Found MISSING_PARAM status for 'Name' parameter in the response"
    );

    $t = $self->t->post_ok(
        $self->uri->{create},
        json => {
            Name => 'dev3',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->or(sub { explain($t->tx->res->json); });

    $resp = $t->tx->res->json;

    ok(
        !scalar(
            grep {
                $_->{code} eq 'MISSING_PARAM'
                    && $_->{message} =~ m/^Missing parameter: Name/;
            } @{$resp->{statuses}}
        ),
        "Not found MISSING_PARAM status for 'Name' parameter in the response"
    );

    map {
        my $parm = $_;

        ok(
            scalar(
                grep {
                    $_->{code} eq 'MISSING_PARAM'
                        && $_->{message} =~ m/^Missing parameter: $parm/;
                } @{$resp->{statuses}}
            ),
            "Found MISSING_PARAM status for '$parm' parameter in the response"
        );
    } qw/Addrs Range CIDR Domain/;

    # :TODO 05/02/2019 06:35:17 PM: by P.G.
    # We need to validate all combinations for supported parameters such as
    # Addrs, Range, CIDR, Domain.
    $t = $self->t->post_ok(
        $self->uri->{create},
        json => {
            Name   => 'dev3-addrs',
            CIDR   => '192.168.0.0/24',
            Domain => 'gluesys.com',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->or(sub { explain($t->tx->res->json); });

    $resp = $t->tx->res->json;

    ok(
        (
            grep {
                $_->{code} eq 'EXCLUSIVE_PARAM'
                    && $_->{message}
                    =~ m/^Exclusive parameters passed together: (?:CIDR|Domain) v.s. (?:CIDR|Domain)/;
            } @{$resp->{statuses}}
        ),
        "Found EXCLUSIVE_PARAM status for 'CIDR and Domain' in the response"
    );

    $t = $self->t->post_ok(
        $self->uri->{create},
        json => {
            Name  => 'private',
            Addrs => ['192.168.0.30'],
        }
    );

    $t->status_is(409)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network zone already exists: private/)
        ->json_is('/statuses/0/code' => 'ALREADY_EXISTS');

    $t = $self->t->post_ok(
        $self->uri->{create},
        json => {
            Name  => $args{Name}  // 'dev3-addrs',
            Addrs => $args{Addrs} // ['192.168.0.30'],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network zone is created: dev3-addrs/)
        ->json_is('/statuses/0/code' => 'NETWORK_ZONE_CREATE_OK');

#    explain($self->mock_data());
#    explain($t->tx->res->json);

    return 0;
}

sub test_zone_update : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok($self->uri->{update});

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        $self->uri->{update},
        json => {
            Name  => 'unknown',
            Addrs => ['192.168.0.1'],
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network zone not found: unknown/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        $self->uri->{update},
        json => {
            Name  => 'private',
            Addrs => ['192.168.0.1'],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network zone is updated: private/)
        ->json_is('/statuses/0/code' => 'NETWORK_ZONE_UPDATE_OK');

#    explain($self->mock_data());
#    explain($t->tx->res->json);
}

sub test_zone_delete : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok($self->uri->{delete});

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Name/);

    $t = $self->t->post_ok(
        $self->uri->{delete},
        json => {
            Name => 'unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network zone not found: unknown/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        $self->uri->{delete},
        json => {
            Name => 'public',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network zone is deleted: public/)
        ->json_is('/statuses/0/code' => 'NETWORK_ZONE_DELETE_OK');

#    explain($self->mock_data());
#    explain($t->tx->res->json);
}

1;

=encoding utf8

=head1 NAME

Test::Network::Zone - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

