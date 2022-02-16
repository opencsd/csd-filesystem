package Test::Network::Hosts;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use Sys::Hostname::FQDN qw/short/;

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

has 'hostname' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
);

has 'mock_file' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/hosts'
);

has 'uris' => (
    is         => 'ro',
    isa        => 'ArrayRef',
    auto_deref => 1,
    lazy       => 1,
    default    => sub
    {
        my $self = shift;

        [
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'hosts_info',
                uri       => '/api/network/hosts/info',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'hosts_add',
                uri       => '/api/network/hosts/add',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'hosts_update',
                uri       => '/api/network/hosts/update',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'hosts_remove',
                uri       => '/api/network/hosts/remove',
            },

#            {
#                namespace => $self->namespace,
#                cntlr     => $self->cntlr,
#                action    => 'hosts_reload',
#                uri       => '/api/network/hosts/reload',
#            },
        ];
    }
);

sub test_startup
{
    my $self = shift;

    $self->next::method(@_);

    my $t = $self->t;

    foreach my $uri ($self->uris)
    {
        $t->app->routes->post($uri->{uri})->to(
            namespace  => $uri->{namespace},
            controller => $uri->{cntlr},
            action     => $uri->{action},
        );
    }
}

sub test_setup
{
    my $self = shift;

    $self->mock_hosts_file();
}

sub test_teardown
{
    my $self = shift;

    $self->unmock_data();
}

sub mock_hosts_file
{
    my $self = shift;
    my $file = $self->mock_file;

    my $mock_hosts = <<"ENDL";
#
# /etc/hosts: static lookup table for host names
#

#<ip-address>	<hostname.domain.org>	<hostname>
127.0.0.1	localhost.localdomain	localhost
::1		localhost.localdomain	localhost

192.168.2.37	HDDSET-1.gluesys.com	HDDSET-1
192.168.2.38	HDDSET-2.gluesys.com	HDDSET-2
192.168.2.39	HDDSET-3.gluesys.com	HDDSET-3
192.168.2.40	HDDSET-4.gluesys.com	HDDSET-4

# End of file
ENDL

    open(my $fh, '>', $file)
        || die "Failed to open: $file: $!";

    print $fh $mock_hosts;

    close($fh);
}

sub test_hosts_info : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/hosts/info');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network hosts retrieved/)
        ->json_is('/statuses/0/code'       => 'NETWORK_HOSTS_INFO_OK')
        ->json_is('/entity/192.168.2.37/0' => 'HDDSET-1.gluesys.com')
        ->json_is('/entity/192.168.2.37/1' => 'HDDSET-1')
        ->json_is('/entity/192.168.2.38/0' => 'HDDSET-2.gluesys.com')
        ->json_is('/entity/192.168.2.38/1' => 'HDDSET-2')
        ->json_is('/entity/192.168.2.39/0' => 'HDDSET-3.gluesys.com')
        ->json_is('/entity/192.168.2.39/1' => 'HDDSET-3')
        ->json_is('/entity/192.168.2.40/0' => 'HDDSET-4.gluesys.com')
        ->json_is('/entity/192.168.2.40/1' => 'HDDSET-4');

#    explain($t->tx->res->json);
}

sub test_hosts_add : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/hosts/add');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: (?:IPAddr|Hostnames)/)
        ->json_is('/statuses/1/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/1/message' => qr/Missing parameter: (?:IPAddr|Hostnames)/);

    $t = $self->t->post_ok(
        '/api/network/hosts/add',
        json => {
            IPAddr => '127.0.0.1',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: Hostnames/);

    $t = $self->t->post_ok(
        '/api/network/hosts/add',
        json => {
            IPAddr    => '127.0.0.1',
            Hostnames => ['invalid#hostname'],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'Hostnames'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like(
        '/statuses/0/message' => qr/Invalid parameter value: Hostnames/);

    $t = $self->t->post_ok(
        '/api/network/hosts/add',
        json => {
            IPAddr    => 'invalid-addr',
            Hostnames => ['localhost'],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'IPAddr'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like(
        '/statuses/0/message' => qr/Invalid parameter value: IPAddr/);

    $t = $self->t->post_ok(
        '/api/network/hosts/add',
        json => {
            IPAddr    => '127.0.0.1',
            Hostnames => ['test-hostname'],
        }
    );

    $t->status_is(409)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network hosts already exists: 127\.0\.0\.1/)
        ->json_is('/statuses/0/code' => 'ALREADY_EXISTS')
        ->json_like('/statuses/0/message' =>
            qr/Network hosts already exists: 127\.0\.0\.1/);

    $t = $self->t->post_ok(
        '/api/network/hosts/add',
        json => {
            IPAddr    => '192.168.0.254',
            Hostnames => ['test-hostname'],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like(
        '/msg' => qr/Network hosts added: 192\.168\.0\.254: test-hostname/)
        ->json_is('/statuses/0/code' => 'NETWORK_HOSTS_ADD_OK');
}

sub test_hosts_update : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/hosts/update');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: (?:IPAddr|Hostnames)/)
        ->json_is('/statuses/1/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/1/message' => qr/Missing parameter: (?:IPAddr|Hostnames)/);

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/hosts/update',
        json => {
            IPAddr => '192.168.2.37',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: Hostnames/);

    $t = $self->t->post_ok(
        '/api/network/hosts/update',
        json => {
            IPAddr    => '192.168.2.37',
            Hostnames => ['invalid#hostname'],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'Hostnames'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like(
        '/statuses/0/message' => qr/Invalid parameter value: Hostnames/);

    $t = $self->t->post_ok(
        '/api/network/hosts/update',
        json => {
            IPAddr    => 'invalid-addr',
            Hostnames => ['localhost'],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'IPAddr'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like(
        '/statuses/0/message' => qr/Invalid parameter value: IPAddr/);

    $t = $self->t->post_ok(
        '/api/network/hosts/update',
        json => {
            IPAddr    => '192.168.2.37',
            Hostnames => ['SSDSET-1.gluesys.com', 'SSDSET-1'],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network hosts updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_HOSTS_UPDATE_OK');

    cmp_ok(`cat ${\$self->mock_file} | grep 'SSDSET-1.gluesys.com' | wc -l`,
        '==', 1, 'Found SSDSET-1.gluesys.com from hosts file');

    cmp_ok(
        $self->mock_get_key(
            key => "/${\$self->hostname}/Network/Hosts/192.168.2.37/0"
        ),
        'eq',
        'SSDSET-1.gluesys.com'
    );

    cmp_ok(`cat ${\$self->mock_file} | grep 'SSDSET-1\$' | wc -l`,
        '==', 1, 'Found SSDSET-1 from hosts file');

    cmp_ok(
        $self->mock_get_key(
            key => "/${\$self->hostname}/Network/Hosts/192.168.2.37/1"
        ),
        'eq',
        'SSDSET-1'
    );
}

sub test_hosts_remove : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/hosts/remove');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: IPAddr/);

    $t = $self->t->post_ok(
        '/api/network/hosts/remove',
        json => {
            IPAddr => 'invalid-addr',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'IPAddr'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like(
        '/statuses/0/message' => qr/Invalid parameter value: IPAddr/);

    $t = $self->t->post_ok(
        '/api/network/hosts/remove',
        json => {
            IPAddr => '192.168.2.37',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network hosts removed/)
        ->json_is('/statuses/0/code' => 'NETWORK_HOSTS_REMOVE_OK');

    cmp_ok(`cat ${\$self->mock_file} | grep 192.168.2.37 | wc -l`,
        '==', 0, 'Hosts for 192.168.2.37 removed');

    ok(
        !$self->mock_get_key(
            key => "/${\$self->hostname}/Network/Hosts/192.168.2.37/0"
        ),
        'Hosts for 192.168.2.37 removed'
    );
}

#sub test_hosts_reload : Test(no_plan)
#{
#    my $self = shift;
#
#    my $t = $self->t->post_ok('/api/network/host/reload');
#
#    $t->status_is(200)
#        ->json_is('/success'         => 1)
#        ->json_like('/msg'           => qr/HOST config is reloaded/)
#        ->json_is('/statuses/0/code' => 'NETWORK_HOST_RELOAD_OK');
#
#    explain($t->tx->res->json) unless ($t->success);
#}

1;

=encoding utf8

=head1 NAME

Test::Network::Hosts - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

