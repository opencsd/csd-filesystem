package Test::Network::Route;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use File::Path qw/make_path/;

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
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_table_list',
                uri       => '/api/network/route/table/list',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_table_info',
                uri       => '/api/network/route/table/info',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_table_create',
                uri       => '/api/network/route/table/create',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_table_update',
                uri       => '/api/network/route/table/update',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_table_delete',
                uri       => '/api/network/route/table/delete',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_rule_list',
                uri       => '/api/network/route/rule/list',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_rule_create',
                uri       => '/api/network/route/rule/create',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_rule_update',
                uri       => '/api/network/route/rule/update',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_rule_delete',
                uri       => '/api/network/route/rule/delete',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_entry_list',
                uri       => '/api/network/route/entry/list',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_entry_create',
                uri       => '/api/network/route/entry/create',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_entry_update',
                uri       => '/api/network/route/entry/update',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_entry_delete',
                uri       => '/api/network/route/entry/delete',
            },
            {
                namespace => 'Mock::Controller',
                cntlr     => $self->cntlr,
                action    => 'route_reload',
                uri       => '/api/network/route/reload',
            },
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

    $self->mock_config_file();
}

sub test_teardown
{
    my $self = shift;

    $self->unmock_data();
}

sub mock_config_file
{
    map {
        if (-e $_ && !-d $_)
        {
            die "path exists but not a directory: $_";
        }

        if (!-d $_ && make_path($_, {error => \my $err}) == 0)
        {
            my ($dir, $msg) = %{$err->[0]};

            if ($dir eq '')
            {
                die "Generic error: $msg";
            }
            else
            {
                die "Failed to make directory: $dir: $msg";
            }
        }
    } ('/tmp/etc/iproute2', '/tmp/etc/sysconfig/network-scripts');

    my $file_tables = '/tmp/etc/iproute2/rt_tables';
    my $mock_tables = <<"ENDL";
#
# reserved values
#
255     local
254     main
253     default
0       unspec

#
# custom
#
200     private
201     public

#
# local
#
#1      inr.ruhep
ENDL

    open(my $fh_tables, '>', $file_tables)
        || die "Failed to open file: $file_tables: $!";

    print $fh_tables $mock_tables;
    close($fh_tables);

    my $file_rule = '/tmp/etc/sysconfig/network-scripts/rule-ens32';
    my $mock_rule = <<"ENDL";
from 192.168.0.10/32 table private priority 101
ENDL

    open(my $fh_rule, '>', $file_rule)
        || die "Failed to open file: $file_rule: $!";

    print $fh_rule $mock_rule;
    close($fh_rule);

    my $file_entry = '/tmp/etc/sysconfig/network-scripts/route-ens32';
    my $mock_entry = <<"ENDL";
192.168.0.0/22 table private
default via 192.168.0.1 table private
ENDL

    open(my $fh_entry, '>', $file_entry)
        || die "Failed to open file: $file_entry: $!";

    print $fh_entry $mock_entry;
    close($fh_entry);
}

sub test_route_table_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/table/list');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing table list is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_TABLE_LIST_OK')
        ->json_is('/entity/0/name'   => 'unspec')
        ->json_is('/entity/1/name'   => 'private')
        ->json_is('/entity/2/name'   => 'public')
        ->json_is('/entity/3/name'   => 'default')
        ->json_is('/entity/4/name'   => 'main');

#    explain($t->tx->res->json);
}

sub test_route_table_info : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/table/info');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Name/);

    $t = $self->t->post_ok(
        '/api/network/route/table/info',
        json => {
            Name => 'unknown'
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network routing table not found: unknown/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/network/route/table/info',
        json => {
            Name => 'main'
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing table is retrieved: main/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_TABLE_INFO_OK')
        ->json_is('/entity/name'     => 'main');

#    explain($t->tx->res->json);
}

sub test_route_table_create : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/table/create');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Name/);

    $t = $self->t->post_ok(
        '/api/network/route/table/create',
        json => {
            Name => 'main',
        }
    );

    $t->status_is(409)->json_is('/success' => 0)
        ->json_like(
        '/msg' => qr/Network routing table already exists: main\(\d+\)/)
        ->json_is('/statuses/0/code' => 'ALREADY_EXISTS');

    $t = $self->t->post_ok(
        '/api/network/route/table/create',
        json => {
            Name => 'test',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing table is created: test/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_TABLE_CREATE_OK')
        ->json_is('/entity/name'     => 'test');

#    explain($t->tx->res->json);
}

sub test_route_table_delete : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/table/delete');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Name/);

    $t = $self->t->post_ok(
        '/api/network/route/table/delete',
        json => {
            Name => 'unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network routing table not found: unknown/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/network/route/table/delete',
        json => {
            Name => 'local',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing table is deleted: local/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_TABLE_DELETE_OK');

#    explain($t->tx->res->json);
}

sub test_route_rule_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/rule/list');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing rule list is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_RULE_LIST_OK');

#    explain($t->tx->res->json);
}

sub test_route_rule_create : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/rule/create');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: (Table|From|Device)/)
        ->json_like(
        '/statuses/1/message' => qr/Missing parameter: (Table|From|Device)/)
        ->json_like(
        '/statuses/2/message' => qr/Missing parameter: (Table|From|Device)/);

    $t = $self->t->post_ok(
        '/api/network/route/rule/create',
        json => {
            Table => 'main',
            From  => '192.168.0.10/32',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Device/);

    $t = $self->t->post_ok(
        '/api/network/route/rule/create',
        json => {
            Table  => 'main',
            From   => 'unknown-addr',
            Device => 'ens32',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'From'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like(
        '/statuses/0/message' => qr/Invalid parameter value: From/);

    $t = $self->t->post_ok(
        '/api/network/route/rule/create',
        json => {
            Table  => 'private',
            From   => '192.168.0.10/32',
            Device => 'ens32',
        }
    );

    $t->status_is(409)->json_is('/success' => 0)
        ->json_like(
        '/msg' => qr/Network routing rule already exists: private/)
        ->json_is('/statuses/0/code' => 'ALREADY_EXISTS');

    $t = $self->t->post_ok(
        '/api/network/route/rule/create',
        json => {
            Table  => 'main',
            From   => '192.168.1.10/32',
            Device => 'ens32',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing rule is created/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_RULE_CREATE_OK');

}

sub test_route_rule_delete : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/rule/delete');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: (Table|From|Device)/)
        ->json_like(
        '/statuses/1/message' => qr/Missing parameter: (Table|From|Device)/)
        ->json_like(
        '/statuses/2/message' => qr/Missing parameter: (Table|From|Device)/);

    $t = $self->t->post_ok(
        '/api/network/route/rule/delete',
        json => {
            Table => 'private',
            From  => '192.168.0.10/32',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Device/);

    $t = $self->t->post_ok(
        '/api/network/route/rule/delete',
        json => {
            Table  => 'main',
            From   => 'unknown-addr',
            Device => 'ens32',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'From'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like(
        '/statuses/0/message' => qr/Invalid parameter value: From/);

    $t = $self->t->post_ok(
        '/api/network/route/rule/delete',
        json => {
            Table  => 'main',
            From   => '192.168.254.10/32',
            Device => 'ens32',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network routing rule not found: main/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/network/route/rule/delete',
        json => {
            Table  => 'private',
            From   => '192.168.0.10/32',
            Device => 'ens32',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing rule is deleted: private/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_RULE_DELETE_OK');

#    explain($t->tx->res->json);
}

sub test_route_entry_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/entry/list');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing entry list is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_ENTRY_LIST_OK');

#    explain($t->tx->res->json);
}

sub test_route_entry_create : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/entry/create');

    my $regexp_miss  = qr/Missing\ parameter:\ To/;
    my $regexp_param = qr/(?:Via|Device)\ or\ (?:Via|Device)/;
    my $regexp_sel   = qr/Selective\ parameters\ not\ passed:\ $regexp_param/;

    my $expmsg = qr/$regexp_miss|$regexp_sel/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter|Selective parameters/)
        ->json_like('/statuses/0/code' => qr/MISSING_PARAM|SELECTIVE_PARAM/)
        ->json_like('/statuses/0/message' => qr/$expmsg/)
        ->json_like('/statuses/1/code' => qr/MISSING_PARAM|SELECTIVE_PARAM/)
        ->json_like('/statuses/1/message' => qr/$expmsg/);

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/route/entry/create',
        json => {
            Table  => 'main',
            To     => 'invalid-src',
            Via    => '192.168.10.1',
            Device => 'ens32',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'To'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like('/statuses/0/message' => qr/Invalid parameter value: To/);

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/route/entry/create',
        json => {
            Table  => 'private',
            To     => '192.168.0.0/22',
            Device => 'ens32',
        }
    );

    $t->status_is(409)->json_is('/success' => 0)
        ->json_like(
        '/msg' => qr/Network routing entry already exists: private/)
        ->json_is('/statuses/0/code' => 'ALREADY_EXISTS');

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/route/entry/create',
        json => {
            Table  => 'main',
            To     => '192.168.1.10/32',
            Device => 'ens32',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing entry is created/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_ENTRY_CREATE_OK');

#    explain($t->tx->res->json);
}

sub test_route_entry_delete : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/route/entry/delete');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Table/);

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/route/entry/delete',
        json => {
            Table => 'main',
            To    => 'invalid-addr',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Invalid value for 'To'/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE')
        ->json_like('/statuses/0/message' => qr/Invalid parameter value: To/);

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/route/entry/delete',
        json => {
            Table  => 'main',
            To     => '192.168.254.10/32',
            Device => 'ens32',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network routing entry not found: main/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

#    explain($t->tx->res->json);

    $t = $self->t->post_ok(
        '/api/network/route/entry/delete',
        json => {
            Table  => 'private',
            To     => '192.168.0.0/22',
            Device => 'ens32',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network routing entry is deleted: private/)
        ->json_is('/statuses/0/code' => 'NETWORK_ROUTE_ENTRY_DELETE_OK');

#    explain($t->tx->res->json);
}

1;

=encoding utf8

=head1 NAME

Test::Network::Route - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

