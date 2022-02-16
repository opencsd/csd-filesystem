package Test::Share::SMB;

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
    default => 'Share::SMB::Samba',
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
                uri       => '/api/share/smb/list',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'info',
                uri       => '/api/share/smb/info',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'enable',
                uri       => '/api/share/smb/enable',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'disable',
                uri       => '/api/share/smb/disable',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'update',
                uri       => '/api/share/smb/update',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'get_config',
                uri       => '/api/share/smb/config/get',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'set_config',
                uri       => '/api/share/smb/config/set',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'control',
                uri       => '/api/share/smb/control',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'get_account_access',
                uri       => '/api/share/smb/access/account/get',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'set_account_access',
                uri       => '/api/share/smb/access/account/set',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'clients',
                uri       => '/api/share/smb/clients',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'rights',
                uri       => '/api/share/smb/rights',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'users',
                uri       => '/api/share/smb/users',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'groups',
                uri       => '/api/share/smb/groups',
            },
            {
                namespace => $self->namespace,
                cntlr     => $self->cntlr,
                action    => 'zones',
                uri       => '/api/share/smb/zones',
            },
        ];
    },
);

has 'gms_config_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/usr/gms/config',
);

has 'smb_config_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/samba',
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

    $self->mock_share_data();
    $self->mock_smb_data();

    $self->mock_share_config();
    $self->mock_smb_config();
}

sub test_teardown
{
    my $self = shift;

    $self->unmock_config();
    $self->unmock_data();
}

sub mock_share_config
{
    my $self = shift;

    my $path = $self->gms_config_dir;

    if (-e $path && !-d $path)
    {
        die "path exists but not a directory: $path";
    }

    if (!-d $path && make_path($path, {error => \my $err}) == 0)
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

    open(my $fh, '>', "$path/share.conf")
        || die "Failed to open file: $path/share.conf: $!";

    print $fh to_json(
        {
            RnD => {
                name      => 'RnD',
                volume    => 'test-vol',
                path      => '/',
                desc      => 'Share for unit-testing',
                protocols => {
                    SMB => 'yes',
                    NFS => 'no',
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
            "/${\$self->scope}/Share/RnD/protocols/SMB" => 'yes',
            "/${\$self->scope}/Share/RnD/protocols/NFS" => 'no',
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

sub mock_smb_config
{
    my $self = shift;

    foreach
        my $dir ($self->smb_config_dir, "${\$self->smb_config_dir}/shares.d")
    {
        if (-e $dir && !-d $dir)
        {
            die "path exists but not a directory: $dir";
        }

        if (!-d $dir && make_path($dir, {error => \my $err}) == 0)
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
    }

    my $main   = "${\$self->smb_config_dir}/smb.conf";
    my $global = "${\$self->smb_config_dir}/global.conf";
    my $rnd    = "${\$self->smb_config_dir}/shares.d/RnD.conf";

    open(my $fh, '>', $main)
        || die "Failed to open file: $main: $!";

    print $fh <<"ENDL";
# global
include = ${\$self->smb_config_dir}/global.conf

# RnD
include = ${\$self->smb_config_dir}/shares.d/RnD.conf
ENDL

    open($fh, '>', $global)
        || die "Failed to open file: $global: $!";

    print $fh <<"ENDL";
[global]
security = user
ENDL

    close($fh);

    open($fh, '>', $rnd)
        || die "Failed to open file: $rnd: $!";

    print $fh <<"ENDL";
[RnD]
path = /
valid users = \@testgroup-1
vfs objects = glusterfs
glusterfs:volume = test-vol
glusterfs:loglevel = 10
glusterfs:volfile_server = 192.168.0.1
ENDL

    close($fh);

    return;
}

sub mock_smb_data
{
    my $self = shift;

    my $root = "/${\$self->scope}/SMB/Samba/Section";

    $self->mock_data(
        data => {
            "$root/RnD/name"       => 'RnD',
            "$root/RnD/comment"    => 'Share for unit-testing',
            "$root/RnD/path"       => '/',
            "$root/RnD/available"  => 'yes',
            "$root/RnD/browseable" => 'yes',
        }
    );
}

sub unmock_config
{
    my $self = shift;

    foreach my $dir (@{$self}{qw/gms_config_dir smb_config_dir/})
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

sub test_share_smb_rights : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/rights');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB zone/user/group rights are retrieved|)
        ->json_is('/statuses/0/code'       => 'SHARE_PROTO_RIGHTS_LIST_OK')
        ->json_is('/entity/Default/0/Name' => 'readonly')
        ->json_is('/entity/Default/1/Name' => 'read/write')
        ->json_is('/entity/Zone/0/Name'    => 'allow')
        ->json_is('/entity/Zone/1/Name'    => 'deny')
        ->json_is('/entity/User/0/Name'    => 'auto')
        ->json_is('/entity/User/1/Name'    => 'admin')
        ->json_is('/entity/User/2/Name'    => 'readonly')
        ->json_is('/entity/User/3/Name'    => 'read/write')
        ->json_is('/entity/User/4/Name'    => 'deny')
        ->json_is('/entity/Group/0/Name'   => 'auto')
        ->json_is('/entity/Group/1/Name'   => 'readonly')
        ->json_is('/entity/Group/2/Name'   => 'read/write')
        ->json_is('/entity/Group/3/Name'   => 'deny');
}

sub test_share_smb_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/list');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB shares are retrieved|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_LIST_OK');
}

sub test_share_smb_enable : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/enable');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Name'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/enable',
        json => {
            Name => 'Unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Share not found: Unknown|)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/share/smb/enable',
        json => {
            Name => 'global',
        }
    );

    $t->status_is(500)->json_is('/success' => 0)
        ->json_like('/msg' => qr|"global" is reserved name for internal use|);

    $t = $self->t->post_ok(
        '/api/share/smb/enable',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB share is enabled: RnD|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_ENABLE_OK');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba/Section",
        options => {recursive => 'true'}
    );

    if (ok(exists($data->{RnD}), "/${\$self->scope}/SMB/Samba/RnD exists"))
    {
        my @targets = (
            ['name',    'eq', 'RnD'],
            ['comment', 'eq', 'Share for unit-testing'],
        );

        foreach my $target (@targets)
        {
            my ($key, $oper, $value) = @{$target};

            cmp_ok($data->{RnD}->{$key},
                $oper, $value, "/${\$self->scope}/SMB/RnD/$key $oper $value");
        }
    }

    my $lines = `cat ${\$self->smb_config_dir}/shares\.d\/RnD.conf`;

    like($lines, qr/^\[RnD\]/,                    '[RnD]');
    like($lines, qr/vfs objects\s*=\s*glusterfs/, 'vfs objects = glusterfs');
    like(
        $lines,
        qr/glusterfs:volume\s*=\s*test-vol/,
        'glusterfs:volume = test-vol'
    );
    like($lines, qr/glusterfs:loglevel\s*=\s*10/, 'glusterfs:loglevel = 10');
    like(
        $lines,
        qr/glusterfs:volfile_server\s*=\s*192\.168\.0\.1/,
        'glusterfs:volfile_server = 192.168.0.1'
    );

    $t = $self->t->post_ok(
        '/api/share/smb/enable',
        json => {
            Name => 'dev3',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB share is enabled: dev3|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_ENABLE_OK');

    $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba/Section",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{dev3}),
        "/${\$self->scope}/SMB/Samba/Section/dev3 exists"
    ))
    {
        my @targets = (
            ['name',    'eq', 'dev3'],
            ['comment', 'eq', 'Share for unit-testing'],
        );

        foreach my $target (@targets)
        {
            my ($key, $oper, $value) = @{$target};

            cmp_ok(
                $data->{dev3}->{$key},
                $oper,
                $value,
                "/${\$self->scope}/SMB/Samba/Section/dev3/$key $oper $value"
            );
        }
    }

    $lines = `cat ${\$self->smb_config_dir}/smb.conf`;

    like($lines, qr/include = .+\/global\.conf/, 'include = .+/global.conf');
    like(
        $lines,
        qr/include = .+\/shares\.d\/dev3\.conf/,
        'include = .+/shares.d/dev3.conf'
    );

    $lines = `cat ${\$self->smb_config_dir}/shares.d/dev3.conf`;

    like($lines, qr/^\[dev3\]/, '[dev3]');
    like(
        $lines,
        qr/comment = Share for unit-testing/,
        'comment = Share for unit-testing'
    );
    like($lines, qr/path = \//,                   'path = /');
    like($lines, qr/vfs objects\s*=\s*glusterfs/, 'vfs objects = glusterfs');
    like(
        $lines,
        qr/glusterfs:volume\s*=\s*test-vol/,
        'glusterfs:volume = test-vol'
    );
    like($lines, qr/glusterfs:loglevel\s*=\s*7/, 'glusterfs:loglevel = 7');
    like(
        $lines,
        qr/glusterfs:volfile_server\s*=\s*localhost/,
        'glusterfs:volfile_server = localhost'
    );
}

sub test_share_smb_disable : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/disable');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Name'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/disable',
        json => {
            Name => 'Unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Share not found: Unknown|)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/share/smb/disable',
        json => {
            Name => 'global',
        }
    );

    $t->status_is(500)->json_is('/success' => 0)
        ->json_like('/msg' => qr|"global" is reserved name for internal use|);

    $t = $self->t->post_ok(
        '/api/share/smb/disable',
        json => {
            Name => 'dev3',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB share is disabled: dev3|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_DISABLE_OK');

    $t = $self->t->post_ok(
        '/api/share/smb/disable',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB share is disabled: RnD|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_DISABLE_OK');

    my $lines = `cat ${\$self->smb_config_dir}/smb.conf`;

    unlike(
        $lines,
        qr|^include\s*=\s*${\$self->smb_config_dir}/RnD\.conf|,
        "not include 'include = ${\$self->smb_config_dir}/RnD.conf'"
    );

    # :NOTE 08/12/2019 12:56:08 AM: by P.G.
    # 'disable' does remove 'include' line from smb.conf instead of
    # change section configuration.
#    my $lines = `cat ${\$self->smb_config_dir}/shares\.d\/RnD.conf`;
#
#    like($lines, qr/^\[RnD\]/, '[RnD]');
#    like($lines, qr/available\s*=\s*no/, 'available = no');
#    like($lines, qr/browseable\s*=\s*no/, 'browseable = no');
}

sub test_share_smb_update : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/update');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Name'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/update',
        json => {
            Name => 'Unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Share not found: Unknown|)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/share/smb/update',
        json => {
            Name => 'global',
        }
    );

    $t->status_is(500)->json_is('/success' => 0)
        ->json_like('/msg' => qr|"global" is reserved name for internal use|);

    $t = $self->t->post_ok(
        '/api/share/smb/update',
        json => {
            Name => 'dev3',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr|SMB share not found: dev3|)
        ->json_is('/statuses/0/code' => 'NOT_FOUND');

    $t = $self->t->post_ok(
        '/api/share/smb/update',
        json => {
            Name    => 'RnD',
            Invalid => 'yes',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Unknown parameter: 'Invalid'|)
        ->json_is('/statuses/0/code' => 'UNKNOWN_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/update',
        json => {
            Name      => 'RnD',
            Guest_Ok  => 'yes',
            Read_Only => 'yes',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB share is updated: RnD|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_UPDATE_OK');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba/Section",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{RnD}),
        "/${\$self->scope}/SMB/Samba/Section/RnD exists"
    ))
    {
        my @targets = (
            ['name',      'eq', 'RnD'],
            ['comment',   'eq', 'Share for unit-testing'],
            ['guest_ok',  'eq', 'yes'],
            ['read_only', 'eq', 'yes'],
        );

        foreach my $target (@targets)
        {
            my ($key, $oper, $value) = @{$target};

            cmp_ok($data->{RnD}->{$key},
                $oper, $value,
                "/${\$self->scope}/SMB/Samba/Section/RnD/$key $oper $value");
        }
    }

    my $lines = `cat ${\$self->smb_config_dir}/smb.conf`;

    like($lines,
        qr/include = ${\$self->smb_config_dir}\/shares\.d\/RnD\.conf/);

    $lines = `cat ${\$self->smb_config_dir}/shares\.d\/RnD.conf`;

    my @targets = (
        [qr/^\[RnD\]/, '[RnD]'],
        [
            qr/comment = Share for unit-testing/,
            'comment = Share for unit-testing'
        ],
        [qr/guest ok = yes/, 'guest ok = yes'],
        [qr/path = \//,      'path = /'],
    );

    foreach my $target (@targets)
    {
        my ($regex, $comment) = @{$target};

        like($lines, $regex, $comment);
    }
}

sub test_share_smb_get_config : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/config/get');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB config is retrieved|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_GET_CONFIG_OK');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{global}),
        "/${\$self->scope}/SMB/Samba/global exists"
    ))
    {
        cmp_ok($data->{global}->{security},
            'eq', 'user', "/${\$self->scope}/SMB/Samba/global/security");

        # :TODO 11/09/2020 10:34:37 PM: by P.G.
        # Temporary disableing
        #cmp_ok($data->{global}->{server_string},
        #    'eq', '', "/${\$self->scope}/SMB/Samba/global/server_string");
        #cmp_ok($data->{global}->{workgroup},
        #    'eq', '', "/${\$self->scope}/SMB/Samba/global/workgroup");
    }

    my $lines = `cat ${\$self->smb_config_dir}/global.conf`;

    like($lines, qr/^\[global\]/,     '[global]');
    like($lines, qr/security = user/, 'security = user');
}

sub test_share_smb_set_config : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/config/set');

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB is configured|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_SET_CONFIG_OK');

    my $lines = `cat ${\$self->smb_config_dir}/smb.conf`;

    like($lines, qr/include = ${\$self->smb_config_dir}\/global\.conf/);

    $lines = `cat ${\$self->smb_config_dir}/global.conf`;

    like($lines, qr/^\[global\]/,     '[global]');
    like($lines, qr/security = user/, 'security = user');

    $t = $self->t->post_ok(
        '/api/share/smb/config/set',
        json => {
            InvalidOpts => 'Unknown'
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Unknown parameter: 'InvalidOpts'|)
        ->json_is('/statuses/0/code' => 'UNKNOWN_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/config/set',
        json => {
            Security => 'invalid'
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Invalid value for 'Security'|)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');

    $t = $self->t->post_ok(
        '/api/share/smb/config/set',
        json => {
            Security => 'ads'
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB is configured|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_SET_CONFIG_OK');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{global}),
        "/${\$self->scope}/SMB/Samba/global exists"
    ))
    {
        cmp_ok($data->{global}->{security},
            'eq', 'ads', "/${\$self->scope}/SMB/Samba/global/security");

        # :TODO 11/09/2020 10:34:37 PM: by P.G.
        # Temporary disableing
        #cmp_ok($data->{global}->{server_string},
        #    'eq', '', "/${\$self->scope}/SMB/Samba/global/server_string");
        #cmp_ok($data->{global}->{workgroup},
        #    'eq', '', "/${\$self->scope}/SMB/Samba/global/workgroup");
    }

    $lines = `cat ${\$self->smb_config_dir}/global.conf`;

    like($lines, qr/^\[global\]/,    '[global]');
    like($lines, qr/security = ads/, 'security = ads');
}

sub test_share_smb_control : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/control');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Action'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    map {
        $t = $self->t->post_ok(
            '/api/share/smb/control',
            json => {
                Action => $_,
            }
        );

        $t->status_is(200)->json_is('/success' => 1)
            ->json_like('/msg' => qr|SMB service is controlled: $_|)
            ->json_is('/statuses/0/code' => 'SHARE_PROTO_CONTROL_OK');
    } (qw/start stop restart reload/);
}

sub test_share_smb_get_access : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/access/account/get');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Name'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/get',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'User' \(or 'Group'\)|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/get',
        json => {
            Name  => 'RnD',
            User  => 'testuser-1',
            Group => 'testgroup-1',
        }
    );

    my $regexp = qr/'(?:User|Group)' v\.s\. '(?:User|Group)'/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like(
        '/msg' => qr/Exclusive parameters passed together: $regexp/)
        ->json_is('/statuses/0/code' => 'EXCLUSIVE_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/get',
        json => {
            Name => 'RnD',
            User => 'testuser-1',
        }
    );

    $regexp = qr/RnD: testuser-1\(auto\)/;

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB share access is retrieved: $regexp|)
        ->json_is('/statuses/0/code' => 'SHARE_GET_ACCESS_OK');

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/get',
        json => {
            Name  => 'RnD',
            Group => 'testgroup-1',
        }
    );

    $regexp = qr/RnD: testgroup-1\(readonly\)/;

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB share access is retrieved: $regexp|)
        ->json_is('/statuses/0/code' => 'SHARE_GET_ACCESS_OK');
}

sub test_share_smb_set_access : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/access/account/set');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Name'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/set',
        json => {
            Name => 'RnD',
        }
    );

    my $regexp = qr/'User' \(or 'Group'\)/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: $regexp|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/set',
        json => {
            Name  => 'RnD',
            User  => 'testuser-1',
            Group => 'testgroup-1',
        }
    );

    $regexp = qr/'(?:User|Group)' v\.s\. '(?:User|Group)'/;

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like(
        '/msg' => qr/Exclusive parameters passed together: $regexp/)
        ->json_is('/statuses/0/code' => 'EXCLUSIVE_PARAM');

    my $lines = `cat ${\$self->smb_config_dir}/shares.d/RnD.conf`;

    like($lines, qr/^\[RnD\]/, '[RnD]');
    like(
        $lines,
        qr/(?<!in)valid users\s*=\s*\@testgroup-1/,
        'valid users = @testgroup-1'
    );
    unlike(
        $lines,
        qr/read list\s*=\s*.+testuser-1.*/,
        'read list = testuser-1'
    );

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/set',
        json => {
            Name  => 'RnD',
            User  => 'testuser-1',
            Right => 'readonly',
        }
    );

    $regexp = qr/RnD: testuser-1\(readonly\)/;

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB share access is updated: $regexp|)
        ->json_is('/statuses/0/code' => 'SHARE_SET_ACCESS_OK')
        ->json_is('/entity/Name'     => 'RnD')
        ->json_is('/entity/User'     => 'testuser-1')
        ->json_is('/entity/Right'    => 'readonly');

    my $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba/Section",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{RnD}),
        "/${\$self->scope}/SMB/Samba/Section/Rnd exists"
    ))
    {
        cmp_bag(
            $data->{RnD}->{valid_users},
            [qw/@testgroup-1 testuser-1/],
            "/${\$self->scope}/SMB/Samba/Section/RnD/valid_users"
        );

        cmp_bag($data->{RnD}->{read_list},
            [qw/testuser-1/],
            "/${\$self->scope}/SMB/Samba/Section/RnD/read_list");
    }

    $lines = `cat ${\$self->smb_config_dir}/shares.d/RnD.conf`;

    like($lines, qr/^\[RnD\]/, '[RnD]');
    like(
        $lines,
        qr/(?<!in)valid users\s*=\s*\@testgroup-1/,
        'valid users = @testgroup-1'
    );
    like(
        $lines,
        qr/(?<!in)valid users\s*=\s*.+testuser-1.*/,
        'valid users = testuser-1'
    );
    like($lines, qr/read list\s*=\s*.+testuser-1.*/,
        'read list = testuser-1');

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/set',
        json => {
            Name  => 'RnD',
            Group => 'testgroup-1',
            Right => 'read/write',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' =>
            qr|SMB share access is updated: RnD: testgroup-1\(read/write\)|)
        ->json_is('/statuses/0/code' => 'SHARE_SET_ACCESS_OK')
        ->json_is('/entity/Name'     => 'RnD')
        ->json_is('/entity/Group'    => 'testgroup-1')
        ->json_is('/entity/Right'    => 'read/write');

    $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba/Section",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{RnD}),
        "/${\$self->scope}/SMB/Samba/Section/Rnd exists"
    ))
    {
        cmp_bag(
            $data->{RnD}->{valid_users},
            [qw/@testgroup-1 testuser-1/],
            "/${\$self->scope}/SMB/Samba/Section/RnD/valid_users"
        );

        cmp_bag($data->{RnD}->{write_list},
            [qw/@testgroup-1/],
            "/${\$self->scope}/SMB/Samba/Section/RnD/write_list");
    }

    $lines = `cat ${\$self->smb_config_dir}/shares.d/RnD.conf`;

    like($lines, qr/^\[RnD\]/, '[RnD]');
    like(
        $lines,
        qr/(?<!in)valid users\s*=\s*\@testgroup-1/,
        'valid users = @testgroup-1'
    );
    like(
        $lines,
        qr/(?<!in)valid users\s*=\s*.+testuser-1.*/,
        'valid users = testuser-1'
    );
    like(
        $lines,
        qr/write list\s*=\s*.+\@testgroup-1.*/,
        'write list = @testgroup-1'
    );

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/set',
        json => {
            Name  => 'RnD',
            User  => 'testuser-1',
            Right => 'deny',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like(
        '/msg' => qr|SMB share access is updated: RnD: testuser-1\(deny\)|)
        ->json_is('/statuses/0/code' => 'SHARE_SET_ACCESS_OK')
        ->json_is('/entity/Name'     => 'RnD')
        ->json_is('/entity/User'     => 'testuser-1')
        ->json_is('/entity/Right'    => 'deny');

    $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba/Section",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{RnD}),
        "/${\$self->scope}/SMB/Samba/Section/Rnd exists"
    ))
    {
        cmp_bag($data->{RnD}->{valid_users},
            [qw/@testgroup-1/],
            "/${\$self->scope}/SMB/Samba/Section/RnD/valid_users");

        cmp_bag($data->{RnD}->{invalid_users},
            [qw/testuser-1/],
            "/${\$self->scope}/SMB/Samba/Section/RnD/invalid_users");
    }

    $lines = `cat ${\$self->smb_config_dir}/shares.d/RnD.conf`;

    like($lines, qr/^\[RnD\]/, '[RnD]');
    like(
        $lines,
        qr/(?<!in)valid users\s*=\s*\@testgroup-1/,
        'valid users = @testgroup-1'
    );
    unlike(
        $lines,
        qr/(?<!in)valid users\s*=\s*.+testuser-1.*/,
        'valid users does not include "testuser-1"'
    );
    like(
        $lines,
        qr/invalid users\s*=\s*.+testuser-1.*/,
        'invalid users = testuser-1'
    );

    $lines = `cat ${\$self->smb_config_dir}/shares.d/RnD.conf`;

    diag("\nBEFORE: $lines\n");

    $t = $self->t->post_ok(
        '/api/share/smb/access/account/set',
        json => {
            Name  => 'RnD',
            User  => 'testuser-1',
            Right => 'auto',
        }
    );

    $data = $self->mock_get_key(
        key     => "/${\$self->scope}/SMB/Samba/Section",
        options => {recursive => 'true'}
    );

    if (ok(
        exists($data->{RnD}),
        "/${\$self->scope}/SMB/Samba/Section/Rnd exists"
    ))
    {
        cmp_bag($data->{RnD}->{valid_users},
            [qw/@testgroup-1/],
            "/${\$self->scope}/SMB/Samba/Section/RnD/valid_users");

        cmp_bag($data->{RnD}->{write_list},
            [qw/@testgroup-1/],
            "/${\$self->scope}/SMB/Samba/Section/RnD/write_list");

        map {
            ok(!defined($data->{RnD}->{$_}),
                "/${\$self->scope}/SMB/Samba/Section/RnD/$_");
        } qw/invalid_users read_list admin_users/;
    }

    $lines = `cat ${\$self->smb_config_dir}/shares.d/RnD.conf`;

    diag("\nAFTER: $lines\n");

    like($lines, qr/^\[RnD\]/, '[RnD]');
    like(
        $lines,
        qr/(?<!in)valid users\s*=\s*\@testgroup-1/,
        'valid users = @testgroup-1'
    );
    unlike($lines, qr/invalid users\s*=/, 'invalid users =');
    unlike($lines, qr/read_list\s*=/,     'read list =');
    like(
        $lines,
        qr/write list\s*=\s*.+\@testgroup-1.*/,
        'write list = @testgroup-1'
    );
}

sub test_share_smb_clients : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/share/smb/clients');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr|Missing parameter: 'Name'|)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');

    $t = $self->t->post_ok(
        '/api/share/smb/clients',
        json => {
            Name => 'RnD',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr|SMB clients are retrieved|)
        ->json_is('/statuses/0/code' => 'SHARE_PROTO_GET_CLIENTS_OK')

        ->json_is('/entity/0/pid'        => '25018')
        ->json_is('/entity/0/service'    => 'RnD')
        ->json_is('/entity/0/ip'         => '192.168.0.10')
        ->json_is('/entity/0/ip_version' => 'ipv4')
        ->json_is('/entity/0/port'       => '57993')
        ->json_is('/entity/0/protocol'   => 'SMB3_11')
        ->json_is('/entity/0/user'       => 'testuser-1')
        ->json_is('/entity/0/group'      => 'testgroup-1')
        ->json_is('/entity/0/encryption' => '-')
        ->json_is('/entity/0/signing'    => 'partial(AES-128-CMAC)')
        ->json_is('/entity/0/connected'  => '1562524294')

        ->json_is('/entity/1/pid'        => '25019')
        ->json_is('/entity/1/service'    => 'RnD')
        ->json_is('/entity/1/ip'         => '192.168.0.11')
        ->json_is('/entity/1/ip_version' => 'ipv4')
        ->json_is('/entity/1/port'       => '57994')
        ->json_is('/entity/1/protocol'   => 'SMB3_11')
        ->json_is('/entity/1/user'       => 'testuser-1')
        ->json_is('/entity/1/group'      => 'testgroup-1')
        ->json_is('/entity/1/encryption' => '-')
        ->json_is('/entity/1/signing'    => 'partial(AES-128-CMAC)')
        ->json_is('/entity/1/connected'  => '1562527954');
}

1;

=encoding utf8

=head1 NAME

Test::Share::SMB - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

