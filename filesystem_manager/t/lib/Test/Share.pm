package Test::Share;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use Env;
use File::Path qw/make_path remove_tree/;
use Sys::Hostname::FQDN qw/short/;
use JSON qw/to_json/;

has 'scope' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
);

has 'namespace' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Mock::Controller',
);

has 'cntlr' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Share',
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
                action    => 'list',
                uri       => '/api/share/list',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'create',
                uri       => '/api/share/create',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'update',
                uri       => '/api/share/update',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'delete',
                uri       => '/api/share/delete',
            },
        ];
    },
);

has 'config_file' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/usr/gms/config/share.conf',
);

has 'ftp_config' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/proftpd.conf',
);

sub test_startup
{
    my $self = shift;

    $self->next::method(@_);

    foreach my $uri ($self->uris)
    {
        $self->t->app->routes->post($uri->{uri})->to(
            namespace  => $uri->{namespace},
            controller => $uri->{cntlr},
            action     => $uri->{action},
        );
    }
}

sub test_setup
{
    my $self = shift;

    $self->next::method(@_);

    $self->mock_config();
    $self->mock_ftp_config();
    $self->mock_share_data();
}

sub test_teardown
{
    my $self = shift;

    $self->next::method(@_);

    $self->unmock_config();
    $self->unmock_data();
}

sub mock_config
{
    my $self = shift;

    my ($dir) = $self->config_file =~ m/^(.+)\/.+$/;

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

    open(my $fh, '>', $self->config_file)
        || die "Failed to open file: ${\$self->config_file}: $!";

    print $fh to_json(
        {
            RnD => {
                name   => 'RnD',
                pool   => 'test-pool',
                volume => 'test-vol',
                path   => '/',
                desc   => 'Share for unit-testing',
            }
        },
        {utf8 => 1, pretty => 1}
    );

    close($fh);
}

sub mock_ftp_config
{
    my $self = shift;

    my ($dir) = $self->ftp_config =~ m/^(.+)\/.+$/;

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

    system(
        "cp -af $ENV{GMSROOT}/misc/etc/proftpd.conf ${\$self->ftp_config}");
}

sub mock_share_data
{
    my $self = shift;

    $self->mock_data(
        data => {
            "/${\$self->scope}/Share/RnD/name"   => 'RnD',
            "/${\$self->scope}/Share/RnD/pool"   => 'test-pool',
            "/${\$self->scope}/Share/RnD/volume" => 'test-vol',
            "/${\$self->scope}/Share/RnD/path"   => '/RnD',
            "/${\$self->scope}/Share/RnD/desc"   => 'Share for unit-testing',
            "/${\$self->scope}/Share/RnD/protocols/SMB" => 'no',
            "/${\$self->scope}/Share/RnD/protocols/NFS" => 'yes',
        }
    );
}

sub unmock_config
{
    my $self = shift;

    my ($dir) = $self->config_file =~ m/^(.+)\/.+$/;

    if (-d $dir && remove_tree($dir, {error => \my $err}) == 0)
    {
        my ($path, $msg) = %{$err->[0]};

        if ($path eq '')
        {
            die "Generic error: $msg";
        }
        else
        {
            die "Failed to remove: $path: $msg";
        }
    }
}

sub test_share_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/list');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/All shares are listed/)
        ->json_is('/statuses/0/code' => 'SHARE_LIST_OK')
        ->json_is('/entity/0/Name'   => 'RnD')
        ->json_is('/entity/0/Pool'   => 'test-pool')
        ->json_is('/entity/0/Volume' => 'test-vol')
        ->json_is('/entity/0/Path'   => '/')
        ->json_is('/entity/0/Desc'   => 'Share for unit-testing');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/Share",
        options => {recursive => 'true'}
    );

    if (ok(exists($data->{RnD}), "/${\$self->scope}/Share/RnD exists"))
    {
        cmp_ok($data->{RnD}->{name},
            'eq', 'RnD', "/${\$self->scope}/Share/RnD/name");
        cmp_ok($data->{RnD}->{pool},
            'eq', 'test-pool', "/${\$self->scope}/Share/RnD/pool");
        cmp_ok($data->{RnD}->{volume},
            'eq', 'test-vol', "/${\$self->scope}/Share/RnD/volume");
        cmp_ok($data->{RnD}->{path},
            'eq', '/', "/${\$self->scope}/Share/RnD/path");
        cmp_ok(
            $data->{RnD}->{desc},
            'eq',
            'Share for unit-testing',
            "/${\$self->scope}/Share/RnD/desc"
        );
    }
}

sub test_share_create : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/create');

    my $regex = qr/Missing parameter: (?:Name|Volume|Pool)/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_is('/statuses/1/code' => 'MISSING_PARAM')
        ->json_is('/statuses/2/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => $regex)
        ->json_like('/statuses/1/message' => $regex)
        ->json_like('/statuses/2/message' => $regex);

    $t = $self->t->post_ok(
        '/api/share/create',
        json => {
            Volume => 'test-vol',
        }
    );

    $regex = qr/Missing parameter: (?:Name|Pool)/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_is('/statuses/1/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => $regex)
        ->json_like('/statuses/1/message' => $regex);

    $t = $self->t->post_ok(
        '/api/share/create',
        json => {
            Name => 'dev3',
        }
    );

    $regex = qr/Missing parameter: (?:Pool|Volume)/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_is('/statuses/1/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => $regex)
        ->json_like('/statuses/1/message' => $regex);

    $t = $self->t->post_ok(
        '/api/share/create',
        json => {
            Name   => 'RnD',
            Pool   => 'test-pool',
            Volume => 'test-vol',
            Desc   => 'Share for unit-testing',
        }
    );

    $t->status_is(409)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Share already exists: RnD/);

    $t = $self->t->post_ok(
        '/api/share/create',
        json => {
            Name   => 'dev3',
            Pool   => 'test-pool',
            Volume => 'test-vol',
            Desc   => 'Share for unit-testing',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Share is created: dev3/)
        ->json_is('/entity/Name'   => 'dev3')
        ->json_is('/entity/Pool'   => 'test-pool')
        ->json_is('/entity/Volume' => 'test-vol')
        ->json_is('/entity/Path'   => '/')
        ->json_is('/entity/Desc'   => 'Share for unit-testing');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/Share",
        options => {recursive => 'true'}
    );

    if (ok(exists($data->{dev3}), "/${\$self->scope}/Share/dev3 exists"))
    {
        cmp_ok($data->{dev3}->{name},
            'eq', 'dev3', "/${\$self->scope}/Share/dev3/name");
        cmp_ok($data->{dev3}->{pool},
            'eq', 'test-pool', "/${\$self->scope}/Share/dev3/pool");
        cmp_ok($data->{dev3}->{volume},
            'eq', 'test-vol', "/${\$self->scope}/Share/dev3/volume");
        cmp_ok($data->{dev3}->{path},
            'eq', '/', "/${\$self->scope}/Share/dev3/path");
        cmp_ok(
            $data->{dev3}->{desc},
            'eq',
            'Share for unit-testing',
            "/${\$self->scope}/Share/dev3/desc"
        );
    }
}

sub test_share_update : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/update');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Name/);

    $t = $self->t->post_ok(
        '/api/share/update',
        json => {
            Name => 'Unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Share not found: Unknown/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND')
        ->json_like('/statuses/0/message' => qr/Share not found: Unknown/);

    $t = $self->t->post_ok(
        '/api/share/update',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Share is updated: RnD/)
        ->json_is('/entity/Name'   => 'RnD')
        ->json_is('/entity/Pool'   => 'test-pool')
        ->json_is('/entity/Volume' => 'test-vol')
        ->json_is('/entity/Path'   => '/')
        ->json_is('/entity/Desc'   => 'Share for unit-testing');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/Share/RnD",
        options => {recursive => 'true'}
    );

    if (ok(defined($data), "/${\$self->scope}/Share/RnD exists"))
    {
        cmp_ok($data->{name}, 'eq', 'RnD',
            "/${\$self->scope}/Share/RnD/name");
        cmp_ok($data->{pool}, 'eq', 'test-pool',
            "/${\$self->scope}/Share/RnD/pool");
        cmp_ok($data->{volume}, 'eq', 'test-vol',
            "/${\$self->scope}/Share/RnD/volume");
        cmp_ok($data->{path}, 'eq', '/', "/${\$self->scope}/Share/RnD/path");
        cmp_ok(
            $data->{desc}, 'eq',
            'Share for unit-testing',
            "/${\$self->scope}/Share/RnD/desc"
        );
    }

    $t = $self->t->post_ok(
        '/api/share/update',
        json => {
            Name => 'RnD',
            Path => '/rnd',
            Desc => 'Updated description',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Share is updated: RnD/)
        ->json_is('/entity/Name'   => 'RnD')
        ->json_is('/entity/Pool'   => 'test-pool')
        ->json_is('/entity/Volume' => 'test-vol')
        ->json_is('/entity/Path'   => '/rnd')
        ->json_is('/entity/Desc'   => 'Updated description');

    $data = $self->mock_get_key(
        key     => "/${\$self->scope}/Share/RnD",
        options => {recursive => 'true'}
    );

    if (ok(defined($data), "/${\$self->scope}/Share/RnD exists"))
    {
        cmp_ok($data->{name}, 'eq', 'RnD',
            "/${\$self->scope}/Share/RnD/name");
        cmp_ok($data->{pool}, 'eq', 'test-pool',
            "/${\$self->scope}/Share/RnD/pool");
        cmp_ok($data->{volume}, 'eq', 'test-vol',
            "/${\$self->scope}/Share/RnD/volume");
        cmp_ok($data->{path}, 'eq', '/rnd',
            "/${\$self->scope}/Share/RnD/path");
        cmp_ok(
            $data->{desc}, 'eq',
            'Updated description',
            "/${\$self->scope}/Share/RnD/desc"
        );
    }
}

sub test_share_delete : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/delete');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Name/);

    $t = $self->t->post_ok(
        '/api/share/delete',
        json => {
            Name => 'Unknown'
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Share not found: Unknown/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND')
        ->json_like('/statuses/0/message' => qr/Share not found: Unknown/);

    $t = $self->t->post_ok(
        '/api/share/delete',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Share is deleted: RnD/);

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/Share",
        options => {recursive => 'true'}
    );

    ok(!exists($data->{RnD}), "/${\$self->scope}/Share/RnD does not exist");
}

1;

=encoding utf8

=head1 NAME

Test::Share - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

