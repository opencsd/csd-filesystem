package Test::Share::NFS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use File::Path qw/make_path remove_tree/;
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
    default => 'Share::NFS::Ganesha',
);

has 'scope' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
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
                uri       => '/api/share/nfs/ganesha/list',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'info',
                uri       => '/api/share/nfs/ganesha/info',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'enable',
                uri       => '/api/share/nfs/ganesha/enable',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'disable',
                uri       => '/api/share/nfs/ganesha/disable',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'update',
                uri       => '/api/share/nfs/ganesha/update',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'get_config',
                uri       => '/api/share/nfs/ganesha/config/get',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'set_config',
                uri       => '/api/share/nfs/ganesha/config/set',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'control',
                uri       => '/api/share/nfs/ganesha/control',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'get_network_access',
                uri       => '/api/share/nfs/ganesha/access/network/get',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'set_network_access',
                uri       => '/api/share/nfs/ganesha/access/network/set',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'clients',
                uri       => '/api/share/nfs/ganesha/clients',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'rights',
                uri       => '/api/share/nfs/ganesha/rights',
            },
        ];
    },
);

has 'gms_config_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/usr/gms/config',
);

has 'nfs_config_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/ganesha',
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

    $self->next::method(@_);

    $self->mock_share_data();
    $self->mock_nfs_data();
    $self->mock_zone_data();

    $self->mock_share_config();
    $self->mock_nfs_config();
    $self->mock_zone_config();
}

sub test_teardown
{
    my $self = shift;

    $self->next::method(@_);

    $self->unmock_config();
    $self->unmock_data();
}

sub mock_share_config
{
    my $self = shift;

    my $dir = $self->gms_config_dir;

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

    open(my $fh, '>', "$dir/share.conf")
        || die "Failed to open file: $dir/share.conf: $!";

    print $fh to_json(
        {
            RnD => {
                name      => 'RnD',
                volume    => 'test-vol',
                path      => '/RnD',
                desc      => 'Share for unit-testing',
                protocols => {
                    SMB => 'no',
                    NFS => 'yes',
                }
            },
            dev3 => {
                name      => 'dev3',
                volume    => 'test-vol',
                path      => '/dev3',
                desc      => 'Share for unit-testing',
                protocols => {
                    SMB => 'no',
                    NFS => 'no',
                }
            },
        },
        {utf8 => 1, pretty => 1}
    );

    close($fh);
}

sub mock_share_data
{
    my $self = shift;

    $self->mock_data(
        data => {
            "/${\$self->scope}/Share/RnD/name"   => 'RnD',
            "/${\$self->scope}/Share/RnD/volume" => 'test-vol',
            "/${\$self->scope}/Share/RnD/path"   => '/RnD',
            "/${\$self->scope}/Share/RnD/desc"   => 'Share for unit-testing',
            "/${\$self->scope}/Share/RnD/protocols/SMB" => 'no',
            "/${\$self->scope}/Share/RnD/protocols/NFS" => 'yes',
        }
    );

    $self->mock_data(
        data => {
            "/${\$self->scope}/Share/dev3/name"   => 'dev3',
            "/${\$self->scope}/Share/dev3/volume" => 'test-vol',
            "/${\$self->scope}/Share/dev3/path"   => '/dev3',
            "/${\$self->scope}/Share/dev3/desc"   => 'Share for unit-testing',
            "/${\$self->scope}/Share/dev3/protocols/SMB" => 'no',
            "/${\$self->scope}/Share/dev3/protocols/NFS" => 'no',
        }
    );
}

sub mock_nfs_config
{
    my $self = shift;

    my $dir = "${\$self->nfs_config_dir}/exports.d";

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

    my $main    = "${\$self->nfs_config_dir}/ganesha.conf";
    my $default = "${\$self->nfs_config_dir}/default.conf";
    my $rnd     = "$dir/RnD.conf";

    my $fh;

    open($fh, '>', $main)
        || die "Failed to open file: $main: $!";

    print $fh <<"ENDL";
# default
%include "$default"

# RnD
%include "$rnd"
ENDL

    open($fh, '>', $default)
        || die "Failed to open file: $default: $!";

    print $fh <<"ENDL";
EXPORT_DEFAULTS
{
    SecType = sys, krb5, krb5i, krb5p;

    # Restrict all exports to NFS v4 unless otherwise specified
    Protocols = 4;
}
ENDL

    close($fh);

    open($fh, '>', $rnd)
        || die "Failed to open file: $rnd: $!";

    print $fh <<"ENDL";
EXPORT
{
    Export_id = 1;
    Tag = RnD;
    Path = /RnD;

    FSAL
    {
       Name = Gluster;
       Volume = test-vol;
       Hostname = 10.10.1.37;
    }

    CLIENT
    {
       Squash = no_root_squash;
       Clients = *;
       SecType = sys, krb5;
       Access_Type = RW;
    }

    CLIENT
    {
       Squash = no_root_squash;
       Clients = *;
       SecType = sys;
       Access_Type = RW;
    }
}
ENDL

    close($fh);

    return;
}

sub mock_nfs_data
{
    my $self = shift;

    my $root = "/${\$self->scope}/NFS/Ganesha/Export";

    $self->mock_data(
        data => {
            "$root/RnD/export_id" => 1,
            "$root/RnD/name"      => 'RnD',
            "$root/RnD/path"      => '/RnD',
        }
    );
}

sub mock_zone_config
{
    my $self = shift;

    my $dir = $self->gms_config_dir;

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

    open(my $fh, '>', "$dir/zone.conf")
        || die "Failed to open file: $dir/zone.conf: $!";

    print $fh to_json(
        {
            public => {
                name => "public",
                desc => "",
                type => "cidr",
                cidr => "0.0.0.0/0"
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

    close($fh);
}

sub mock_zone_data
{
    my $self = shift;

    $self->mock_data(
        data => {
            "/${\$self->scope}/Network/Zone/public/name"     => 'public',
            "/${\$self->scope}/Network/Zone/public/desc"     => '',
            "/${\$self->scope}/Network/Zone/public/type"     => 'cidr',
            "/${\$self->scope}/Network/Zone/public/cidr"     => '0.0.0.0/24',
            "/${\$self->scope}/Network/Zone/private/name"    => 'private',
            "/${\$self->scope}/Network/Zone/private/desc"    => '',
            "/${\$self->scope}/Network/Zone/private/type"    => 'addrs',
            "/${\$self->scope}/Network/Zone/private/addrs/0" => '192.168.0.1',
            "/${\$self->scope}/Network/Zone/private/addrs/1" =>
                '192.168.0.10',
            "/${\$self->scope}/Network/Zone/private/addrs/2" =>
                '192.168.0.20',
        }
    );
}

sub unmock_config
{
    my $self = shift;

    foreach my $dir (@{$self}{qw/gms_config_dir nfs_config_dir/})
    {
        if (-d $dir && remove_tree($dir, {error => \my $err}) == 0)
        {
            my ($dir, $msg) = %{$err->[0]};

            if ($dir eq '')
            {
                die "Generic error: $msg";
            }
            else
            {
                die "Failed to remove: $dir: $msg";
            }
        }
    }
}

sub test_share_nfs_rights : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/nfs/ganesha/rights');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|NFS zone/user/group rights are retrieved|)
        ->json_is('/statuses/0/code'       => 'SHARE_PROTO_RIGHTS_LIST_OK')
        ->json_is('/entity/Default/0/Name' => 'deny')
        ->json_is('/entity/Default/1/Name' => 'readonly')
        ->json_is('/entity/Default/2/Name' => 'read/write')
        ->json_is('/entity/Zone/0/Name'    => 'deny')
        ->json_is('/entity/Zone/1/Name'    => 'readonly')
        ->json_is('/entity/Zone/2/Name'    => 'read/write');
}

sub test_share_nfs_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/nfs/ganesha/list');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|NFS shares are retrieved|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_LIST_OK')
        ->json_is('/entity/0/Name'   => 'RnD');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/NFS/Ganesha/Export",
        options => {recursive => 'true'}
    );

    if (ok(exists($data->{RnD}), "/${\$self->scope}/NFS/RnD exists"))
    {
        my @targets = (
            ['export_id', '==', 1],
            ['tag',       'eq', 'RnD'],
            ['path',      'eq', '/RnD'],
            ['pseudo',    'eq', '/RnD'],

#            [ 'pref_read', '==', 4194304 ],
#            [ 'pref_readdir', '==', 16384 ],
#            [ 'pref_write', '==', 4194304 ],
#            [ 'max_read', '==', 4194304 ],
#            [ 'max_write', '==', 4194304 ],
#            [ 'max_offset_read', '==', 18446744073709551615 ],
#            [ 'max_offset_write', '==', 18446744073709551615 ],
#            [ 'max_offset_write', '==', 18446744073709551615 ],
        );

        foreach my $target (@targets)
        {
            my ($key, $oper, $value) = @{$target};

            cmp_ok($data->{RnD}->{$key},
                $oper, $value, "/${\$self->scope}/NFS/RnD/$key == $value");
        }

#        @targets = (
#            ['Name', 'eq', 'Gluster'],
#            ['Hostname', 'eq', '10.10.1.37'],
#            ['Volume', 'eq', 'test-vol'],
#        );
#
#        foreach my $target (@targets)
#        {
#            my ($key, $oper, $value) = @{$target};
#
#            cmp_ok($data->{RnD}->{fsal}->{$key}
#                , $oper
#                , $value
#                , "/${\$self->scope}/NFS/RnD/fsal/$key == $value");
#        }
    }
}

sub test_share_nfs_enable : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/nfs/ganesha/enable');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Name'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/enable',
        json => {
            Name => 'Unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Share not found: Unknown|)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/enable',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|NFS share is enabled: RnD|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_ENABLE_OK');

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/enable',
        json => {
            Name => 'dev3',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|NFS share is enabled: dev3|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_ENABLE_OK');

    $t = $self->t->post_ok('/api/share/nfs/ganesha/list');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/NFS/Ganesha/Export",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{dev3}),
        "/${\$self->scope}/NFS/Ganesha/dev3 exists"
    ))
    {
        my @targets = (
            ['export_id', '==', 2],
            ['tag',       'eq', 'dev3'],
            ['path',      'eq', '/dev3'],
            ['pseudo',    'eq', '/dev3'],

#            [ 'pref_read', '==', 4194304 ],
#            [ 'pref_readdir', '==', 16384 ],
#            [ 'pref_write', '==', 4194304 ],
#            [ 'max_read', '==', 4194304 ],
#            [ 'max_write', '==', 4194304 ],
#            [ 'max_offset_read', '==', 18446744073709551615 ],
#            [ 'max_offset_write', '==', 18446744073709551615 ],
        );

        foreach my $target (@targets)
        {
            my ($key, $oper, $value) = @{$target};

            cmp_ok($data->{dev3}->{$key},
                $oper, $value,
                "/${\$self->scope}/NFS/Ganesha/dev3/$key $oper $value");
        }

#        @targets = (
#            ['Name', 'eq', 'Gluster'],
#            ['Hostname', 'eq', 'localhost'],
#            ['Volume', 'eq', 'test-vol'],
#        );
#
#        foreach my $target (@targets)
#        {
#            my ($key, $oper, $value) = @{$target};
#
#            cmp_ok($data->{dev3}->{fsal}->{$key}
#                , $oper
#                , $value
#                , "/${\$self->scope}/NFS/Ganesha/dev3/fsal/$key == $value");
#        }
    }

    my $lines = `cat ${\$self->nfs_config_dir}/ganesha.conf`;

    like($lines,
        qr/%include "${\$self->nfs_config_dir}\/exports.d\/dev3\.conf"/);

    $lines = `cat ${\$self->nfs_config_dir}/exports.d/dev3.conf`;

    my @targets = (
        [qr/Export_Id\s*=\s*2;/, 'Export_Id = 2;'],
        [qr/Tag\s*=\s*dev3;/,    'Tag = dev3;'],

        #[ qr/Path\s*=\s*\/dev3;/, 'Path = /dev3;' ],
        [qr/Pseudo\s*=\s*\/dev3;/, 'Pseudo = /dev3;'],
        [
            qr/FSAL\s*{\s*[^}]+Name\s*=\s*Gluster/,
            'FSAL { ...; Name = Gluster; ...; }'
        ],
        [
            qr/FSAL\s*{\s*[^}]+Hostname\s*=\s*localhost/,
            'FSAL { ...; Hostname = localhost; ...; }'
        ],
        [
            qr/FSAL\s*{\s*[^}]+Volume\s*=\s*test-vol/,
            'FSAL { ...; Volume = test-vol; ...; }'
        ],
    );

    foreach my $target (@targets)
    {
        my ($regex, $comment) = @{$target};

        if (!like($lines, $regex, $comment))
        {
            diag($lines);
        }
    }
}

sub test_share_nfs_disable : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/nfs/ganesha/disable');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Name'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/disable',
        json => {
            Name => 'Unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Share not found: Unknown|)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    my $lines = `cat ${\$self->nfs_config_dir}/ganesha.conf`;

    like($lines,
        qr/%include "${\$self->nfs_config_dir}\/exports.d\/RnD\.conf"/);

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/disable',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|NFS share is disabled: RnD|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_DISABLE_OK');

    $lines = `cat ${\$self->nfs_config_dir}/ganesha.conf`;

    diag($lines);

    unlike($lines,
        qr/%include "${\$self->nfs_config_dir}\/exports.d\/RnD\.conf"/);
}

sub test_share_nfs_control : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/nfs/ganesha/control');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Action'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    map {
        $t = $self->t->post_ok(
            '/api/share/nfs/ganesha/control',
            json => {
                Action => $_,
            }
        );

        $t->status_is(200)->json_is('/success' => 1)
            ->json_like('/msg' => qr|NFS service is controlled: $_|)
            ->json_is('/statuses/0/code' => 'SHARE_PROTO_CONTROL_OK');
    } (qw/start stop restart reload/);
}

sub test_share_nfs_set_access : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/nfs/ganesha/access/network/set');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' =>
            qr/Missing parameter: (?:Name|Zone|Right|Squash)/)
        ->json_like('/statuses/1/message' =>
            qr/Missing parameter: (?:Name|Zone|Right|Squash)/)
        ->json_like('/statuses/2/message' =>
            qr/Missing parameter: (?:Name|Zone|Right|Squash)/)
        ->json_like('/statuses/3/message' =>
            qr/Missing parameter: (?:Name|Zone|Right|Squash)/);

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/access/network/set',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: (?:Zone|Right|Squash)/)
        ->json_like(
        '/statuses/1/message' => qr/Missing parameter: (?:Zone|Right|Squash)/)
        ->json_like('/statuses/2/message' =>
            qr/Missing parameter: (?:Zone|Right|Squash)/);

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/access/network/set',
        json => {
            Name => 'RnD',
            Zone => 'Unknown',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like(
        '/statuses/0/message' => qr/Missing parameter: (?:Right|Squash)/)
        ->json_like(
        '/statuses/1/message' => qr/Missing parameter: (?:Right|Squash)/);

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/access/network/set',
        json => {
            Name  => 'RnD',
            Zone  => 'Unknown',
            Right => 'read/write',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Squash/);

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/access/network/set',
        json => {
            Name   => 'RnD',
            Zone   => 'Unknown',
            Right  => 'read/write',
            Squash => 'no_root_squash',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Network zone not found: Unknown|)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/enable',
        json => {
            Name => 'dev3',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|NFS share is enabled: dev3|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_ENABLE_OK');

    $t = $self->t->post_ok(
        '/api/share/nfs/ganesha/access/network/set',
        json => {
            Name   => 'dev3',
            Zone   => 'public',
            Right  => 'read/write',
            Squash => 'no_root_squash',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like(
        '/msg' => qr|NFS share access is updated: dev3: public\(RW\)|)
        ->json_is('/statuses/0/code' => 'SHARE_SET_ACCESS_OK');

    my $lines = `cat /tmp/etc/ganesha/exports.d/dev3.conf`;

    my @targets = (
        [qr/Export_Id\s*=\s*2;/, 'Export_Id = 2;'],
        [qr/Tag\s*=\s*dev3;/,    'Tag = dev3;'],

        #[ qr/Path\s*=\s*\/dev3;/, 'Path = /dev3;' ],
        [qr/Pseudo\s*=\s*\/dev3;/, 'Pseudo = /dev3;'],
        [
            qr/CLIENT\s*{\s*[^}]+Access_Type\s*=\s*RW/,
            'CLIENT { ...; Squash = RW; ...; }'
        ],
        [
            qr/CLIENT\s*{\s*[^}]+Clients\s*=\s*\*/,
            'CLIENT { ...; Clients = *; ...; }'
        ],
        [
            qr/CLIENT\s*{\s*[^}]+SecType\s*=\s*none,\s*sys/,
            'CLIENT { ...; SecType = none, sys; ...; }'
        ],
        [
            qr/CLIENT\s*{\s*[^}]+Squash\s*=\s*no_root_squash/,
            'CLIENT { ...; Squash = no_root_squash; ...; }'
        ],
    );

    foreach my $target (@targets)
    {
        my ($regex, $comment) = @{$target};

        like($lines, $regex, $comment);
    }
}

1;

=encoding utf8

=head1 NAME

Test::Share::NFS - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

