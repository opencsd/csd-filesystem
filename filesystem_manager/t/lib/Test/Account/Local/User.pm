package Test::Account::Local::User;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use File::Path "rmtree";
use IO::File;
use Test::Class::Moose extends => 'Test::GMS';
use Test::MockModule;

use GMS::Account::Local::User;

with 'Test::Role::FileReadWrite';
with 'Test::Role::Dir';

has 'mock_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc'
);

has 'passwd_file' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/passwd'
);

has 'shadow_file' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/shadow'
);

sub test_find_usr_passwd : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    my $fh;
    my %params = ();

    # $args{} (00)
    cmp_ok($obj->_find_user_passwd(),
        '==', undef, '_find_user_passwd failure - $args{} == undef');

    $params{'uid'} = 263;

    # $args{} (01)
    cmp_ok($obj->_find_user_passwd(%params),
        '==', undef, '_find_user_passwd failure - $args{name} == undef');

    $params{'name'} = 'iKaroS';

    $module->mock(passwd_file => $self->passwd_file);

    # $args{} (1x) too
    cmp_ok($obj->_find_user_passwd(%params),
        '==', undef, '_find_user_passwd failure - $fh == undef');

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    file_write($self->passwd_file,
        ("#test\n", "\n", "Espera::1\n", "Espera::263\n"));

    cmp_ok($obj->_find_user_passwd(%params),
        '!=', undef, '_find_user_passwd success - same uid');

    file_write($self->passwd_file, ("iKaroS::236:1:2:3:4\n"));

    cmp_ok($obj->_find_user_passwd(%params),
        '!=', undef, '_find_user_passwd success - same name');

    file_write($self->passwd_file, ());

    %params = (name => 'iKaroS');
    file_write($self->passwd_file, ('Espera::'));
    cmp_ok($obj->_find_user_passwd(%params),
        '==', undef, '_find_user_passwd success  - args{name}')
        ;    # 100x coverage

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub test_find_user_shadow : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    my $fh;

    my %params = (name => 'iKaroS');

    cmp_ok($obj->_find_user_shadow(),
        '==', undef, '_find_user_shadow failure - args{name} == undef');

    cmp_ok($obj->_find_user_shadow(%params),
        '==', undef, '_find_user_shadow failure - fh == undef');

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    file_write(
        $self->shadow_file,
        (
            "#test\n",    # line 00
            "\n",         # line 01

            ":\n",        # line 1x && args{name} 0x
            "Espera:\n",  # args{name} 10
            "iKaroS\n",   # args{name} 11
        )
    );

    $module->mock(shadow_file => $self->shadow_file);
    cmp_ok($obj->_find_user_shadow(%params),
        '!=', undef, '_find_user_shadow success - // coverage left');

    file_write(
        $self->shadow_file,
        (
            "iKaroS:1:2:3:4:5:6:7:8:9\n",    # args{name} 11
        )
    );

    $module->mock(shadow_file => $self->shadow_file);
    cmp_ok($obj->_find_user_shadow(%params),
        '!=', undef, '_find_user_shadow success - // coverage right');

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub test_crypt_passwd : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    my %params = (plaintext => '263_Dark_Knight');

    cmp_ok($obj->crypt_passwd(%params),
        'ne', undef, 'crypt_passwd success - SHA512');

    $params{'enctype'} = 'des';
    cmp_ok($obj->crypt_passwd(%params),
        'ne', undef, 'crypt_passwd success - DES');

    $params{'enctype'} = 'md5';
    cmp_ok($obj->crypt_passwd(%params),
        'ne', undef, 'crypt_passwd success - MD5');

#    $params{'enctype'} = 'blowfish';
#    cmp_ok($obj->crypt_passwd(%params), 'ne', undef,
#            'crypt_passwd success - BLOWFISH');

    $params{'enctype'} = 'sha256';
    cmp_ok($obj->crypt_passwd(%params),
        'ne', undef, 'crypt_passwd success - SHA256');

    $params{'enctype'} = 'iKaroS';
    cmp_ok($obj->crypt_passwd(1, %params),
        '==', undef, 'crypt_passwd failure');
}

sub _test_all_users : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    my $fh;

    $module->mock(passwd_file => $self->passwd_file);

    cmp_ok($obj->all_users(), '==', undef,
        '_all_users failure - fh == undef');

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    file_write(
        $self->passwd_file,
        (
            "\n",                      # line_coverage
            ":\n",                     # 1x
            "iKaroS:\n",               # 00 // left
            "iKaroS:0:0:0:1:2:3\n",    # 00 // right
        )
    );

    cmp_ok($obj->all_users(), '!=', undef, '_all_users success');

    open($fh, '>', $self->passwd_file)
        || die "File open Error $!";

    file_write($self->passwd_file, ("iKaroS:\n", "iKaroS:\n",));

    my $count = 0;

    $module->mock(
        user_filter => sub
        {
            return sub
            {
                my @args = @_;
                if ($count > 0)
                {
                    return 0;
                }

                $count++;
                return 1;
            };
        }
    );

    cmp_ok($obj->all_users(), '!=', undef,
        '_all_users success - user{name} cover');    # user{name} coverage;

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub _test_user_exists : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    cmp_ok($obj->user_exists(), '==', -1,
        'user_exists failure - args{name} is undef');

    my %params = (name => 'iKaroS');

    $module->mock(_find_user_passwd => sub { return 1; });
    $module->mock(_find_user_shadow => sub { return 1; });

    cmp_ok($obj->user_exists(%params),
        '==', 3, 'user_exists success - found is 3');

    $module->mock(_find_user_passwd => sub { return undef; });
    $module->mock(_find_user_shadow => sub { return 1; });

    cmp_ok($obj->user_exists(%params),
        '==', 2, 'user_exists success - found is 2');

    $module->mock(_find_user_passwd => sub { return 1; });
    $module->mock(_find_user_shadow => sub { return undef; });

    cmp_ok($obj->user_exists(%params),
        '==', 1, 'user_exists success - found is 1');

    $module->mock(_find_user_passwd => sub { return undef; });
    $module->mock(_find_user_shadow => sub { return undef; });

    cmp_ok($obj->user_exists(%params),
        '==', 0, 'user_exists failure - found is 0');
}

sub _test_find_user : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    my %params;

    cmp_ok($obj->find_user(), '==', undef,
        'find_user failure - args{name} is undef');    # 11

    $module->mock(_find_user_passwd => sub { return undef; });
    $params{uid} = '263';

    cmp_ok($obj->find_user(%params),
        '==', undef, 'find_user failure - user_passwd is undef');

    # 10, user_passwd T

    $module->mock(_find_user_passwd => sub { return {}; });
    $module->mock(_find_user_shadow => sub { return undef; });

    cmp_ok($obj->find_user(%params),
        '==', undef, 'find_user failure - args{name} is undef');

    $params{name} = 'iKaroS';

    cmp_ok($obj->find_user(%params),
        '==', undef, 'find_user failure - user_shadow is undef');

    # 0x user_passwd F
    # user_shadow T

    $params{name} = 'iKaroS';

    $module->mock(_find_user_shadow => sub { return {name => 'iKaroS'}; });

    cmp_ok($obj->find_user(%params), '!=', undef, 'find_user success');
}

sub _test_make_homedir : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    cmp_ok($obj->make_homedir(), '==', -1,
        'make_homedir failure - args{name} is undef');    # $args{name} T

    my %params = (name => 'iKaroS');
    $module->mock(_find_user_passwd => sub { return undef; });

    cmp_ok($obj->make_homedir(%params),
        '==', -1, 'make_homedir failure - user is undef');

    # user T, $args{name} F

    $module->mock(_find_user_passwd => sub { return {}; });
    cmp_ok($obj->make_homedir(%params),
        '==', -1, 'make_homedir failure - user->{homedir} is undef');

    # user F,
    # user->{homedir} T

    $module->mock(_find_user_passwd => sub { return {homedir => ''}; });

    cmp_ok($obj->make_homedir(%params),
        '==', -1, 'make_homedir failure - mkdir is undef');

    # user->{homedir} F
    # mkdir T

    $module->mock(
        _find_user_passwd => sub { return {homedir => $self->mock_dir}; });

    cmp_ok($obj->make_homedir(%params),
        '==', -1, 'make_homedir failure - rcopy is undef'); # mkdir F, rcopy T

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";

    $module->mock(
        rcopy => sub
        {
            file_write('/tmp/etc/passwd', ());
            return 1;
        }
    );

    cmp_ok($obj->make_homedir(%params), '==', 0, 'make_homedir success');

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub _test_create_user : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    cmp_ok($obj->create_user(), '==', -1,
        'create_user failure - name is undef');

    my %params = (
        name => 'iKaroS',
        uid  => 263
    );

    $module->mock('user_exists' => sub { return 1; });
    cmp_ok($obj->create_user(%params),
        '==', -1, 'create_user failure - user_exists() > 0');  # args{mods} 1x

    $params{'mode'} = 'Espera';
    $module->mock('passwd_file' => $self->passwd_file);
    $module->mock('user_exists' => sub { return 0; });
    cmp_ok($obj->create_user(%params),
        '==', -1, 'create_user failure - fh is undef');        # args{mods} 01
                                                               # fh T

    $params{'mode'} = 'reload';
    $module->mock('passwd_file' => $self->passwd_file);

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    file_write($self->passwd_file, ());

    cmp_ok($obj->create_user(%params), '==', 0, 'create_user success');

    # args{mods} 00
    # fh F
    # // right

    $params{gecos}   = '1';
    $params{homedir} = '1';
    $params{shell}   = '1';
    cmp_ok($obj->create_user(%params),
        '==', 0, 'create_user success - args coverage');

    # args{mods} 00
    # fh F
    # // left

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub _test_update_user : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local::User->new();
    my $module = Test::MockModule->new('GMS::Account::Local::User');

    cmp_ok($obj->update_user(), '==', -1,
        'update_user failure - args{name} is undef');    # args{name} T

    my %params = (
        test => undef,
        name => 'iKaroS'
    );
    $module->mock(find_user => sub { return undef; });
    cmp_ok($obj->update_user(%params),
        '==', -1, 'update_user failure - user is undef');    # user T

    $module->mock(find_user   => sub { return {}; });
    $module->mock(passwd_file => $self->passwd_file);
    cmp_ok($obj->update_user(%params),
        '==', -1, 'update_user failure - fh is undef');      # user T
                                                             # args{key} T/F
                                                             # fh T

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    file_write(
        $self->passwd_file,
        (
            "\n",           # line 1x
            "#test\n",      # line coverage 01
            ":\n",          # line 00, name T
            "Espera:\n",    # name nq user{name}
            "iKaroS:\n",    # name coverage
        )
    );
    $module->mock(find_user => sub { return {name => 'iKaroS'}; });
    cmp_ok($obj->update_user(%params), '==', 0, 'update_user success');

    # user T

    my $io = Test::MockModule->new('IO::File');
    $io->mock(seek => sub { return 0; });

    cmp_ok($obj->update_user(%params),
        '==', -1, 'update_user failure - seek failure');

    $io->unmock('seek');

    $io->mock(truncate => sub { return 0; });
    cmp_ok($obj->update_user(%params),
        '==', -1, 'update_user failure - truncate failure');

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub test_delete_user : Tests(no_plans)
{
    my $obj    = GMS::Account::Local::User->new();
    my %params = (name => 'nonexistuser',);

    cmp_ok($obj->delete_user(), '==', -1,
        'delete_user failed by undefined name');

    cmp_ok($obj->delete_user(%params),
        '==', -1, 'delete_user failed by find user');
}

sub test_delete_user_define_mode_user_exists : Tests(no_plans)
{
    my $obj = GMS::Account::Local::User->new();

    my %params1 = (
        name => 'nonexistuser',
        mode => 'anymode',
    );
    my %params2 = (
        name => 'nonexistuser',
        mode => 'reload',
    );

    cmp_ok($obj->delete_user(%params1),
        '==', -1, 'delete_user failed by nonexists_user');

    my $module = Test::MockModule->new('GMS::Account::Local::User');
    $module->mock(passwd_file => undef);

    cmp_ok($obj->delete_user(%params2),
        '==', -1, 'delete_user failed by open passwd file');

    $module->mock(user_exists => sub { return 1; });

    cmp_ok($obj->delete_user(%params1), '==', -1, 'delete_user exists_user');
}

sub test_delete_user_passwd_file_handle : Tests(no_plans)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    my $file = $self->passwd_file;

    my $fh;

    file_write(
        $self->passwd_file,
        (
            "\n",
            "#blah\n",
            "sara:x:blah:blah::/home/sara:blah\n",
            ":x:blah:blah::/home/sara:blah\n",
            "nonexistuser:x:blah:blah::/home/sara:blah\n",
        )
    );

    my $obj = GMS::Account::Local::User->new(
        passwd_file => $file,
        shadow_file => ''
    );

    my %params = (
        name => 'nonexistuser',
        mode => 'reload',
    );

    my $module_user = Test::MockModule->new('GMS::Account::Local::User');
    $module_user->mock(shadow_file => undef);

    cmp_ok($obj->delete_user(%params),
        '==', -1, 'delete_user failed by open shadow_file');

    my $module = Test::MockModule->new('IO::File');
    $module->mock(seek => sub { return 0; });

    cmp_ok($obj->delete_user(%params), '==', -1,
        'delete_user failed by seek');

    $module->unmock('seek');

    $module->mock(truncate => sub { return 0; });

    cmp_ok($obj->delete_user(%params),
        '==', -1, 'delete_user failed by truncate');

    $module->unmock("truncate");

    my $cnt = 0;

    cmp_ok($obj->delete_user(%params),
        '==', -1, 'delete_user success until passwd_file_handle');

    $module_user->unmock('shadow_file');

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub test_delete_user_shadow_file_handle : Tests(no_plans)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    my $passwd_file = $self->passwd_file;

    my $fh;

    file_write(
        $self->passwd_file,
        (
            "\n",
            "#blah\n",
            "sara:x:blah:blah::/home/sara:blah\n",
            ":x:blah:blah::/home/sara:blah\n",
            "nonexistuser:x:blah:blah::/home/sara:blah\n",
        )
    );

    file_write(
        $self->shadow_file,
        (
            "\n",
            "#blah\n",
            "sara:x:blah:blah::/home/sara:blah\n",
            ":x:blah:blah::/home/sara:blah\n",
            "nonexistuser:x:blah:blah::/home/sara:blah\n",
        )
    );

    my $shadow_file = $self->shadow_file;

    my $obj = GMS::Account::Local::User->new(
        passwd_file => $passwd_file,
        shadow_file => $shadow_file
    );

    my %params1 = (
        name           => 'nonexistuser',
        mode           => 'reload',
        delete_homedir => 'anyhomedir',
    );

    my %params2 = (
        name => 'nonexistuser',
        mode => 'reload',
    );

    ##### shadow_file_handle

    cmp_ok($obj->delete_user(%params1), '==', 0, 'delete_user all succeed');

    my $cnt_seek = 0;

    my $module = Test::MockModule->new('IO::File');
    $module->mock(
        seek => sub
        {
            return 0 if ($cnt_seek >= 1);

            $cnt_seek++;
            return 1;
        }
    );

    cmp_ok($obj->delete_user(%params1),
        '==', -1, 'delete_user failed by seek');

    $module->unmock('seek');

    my $cnt_truncate = 0;
    $module->mock(
        truncate => sub
        {
            return 0 if ($cnt_truncate >= 1);

            $cnt_truncate++;
            return 1;
        }
    );

    cmp_ok($obj->delete_user(%params1),
        '==', -1, 'delete_user failed by truncate');

    $module->unmock('truncate');

    cmp_ok($obj->delete_user(%params2),
        '==', 0, 'delete_user check_delete_homedir');

    file_write(
        $self->shadow_file,
        (
            "\n",
            "#blah\n",
            "sara:x:blah:blah:::blah\n",
            ":x:blah:blah:::blah\n",
            "nonexistuser:x:blah:blah:::\n",
        )
    );

    $obj = GMS::Account::Local::User->new(
        passwd_file => $passwd_file,
        shadow_file => $shadow_file
    );

    cmp_ok($obj->delete_user(%params1),
        '==', 0, 'delete_user check_delete_homedir');

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub test_passwd : Tests(no_plans)
{
    my $obj = GMS::Account::Local::User->new(shadow_file => '');

    my %params = (name => 'nonexistuser',);

    cmp_ok($obj->passwd(), '==', -1, 'passwd failed by undefined name');

    my $module = Test::MockModule->new('GMS::Account::Local::User');
    $module->mock(shadow_file => undef);

    cmp_ok($obj->passwd(%params),
        '==', -1, 'passwd failed by undefined shadow_file');

    $module->unmock("shadow_file");
}

sub test_passwd_define_mode_sp_pwd : Tests(no_plans)
{
    my $obj = GMS::Account::Local::User->new();

    my %params1 = (
        name => 'nonexistuser',
        mode => 'anymode',
    );
    my %params2 = (
        name => 'nonexistuser',
        mode => 'reload',
    );

    my $module = Test::MockModule->new('GMS::Account::Local::User');
    $module->mock(
        passwd_file => undef,
        shadow_file => undef
    );

    cmp_ok($obj->passwd(%params1), '==', -1, 'passwd define_mode');
    cmp_ok($obj->passwd(%params2), '==', -1, 'passwd define_mode');

    my %params3 = (
        name   => 'nonexistuser',
        mode   => 'anymode',
        sp_pwd => 'anypwd',
    );
    my %params4 = (
        name   => 'nonexistuser',
        mode   => 'anymode',
        sp_pwd => '!',
    );

    cmp_ok($obj->passwd(%params3), '==', -1, 'passwd define_sp_pwd');
    cmp_ok($obj->passwd(%params4), '==', -1, 'passwd define_sp_pwd');

    $module->unmock("passwd_file");
    $module->unmock("shadow_file");
}

sub test_passwd_define_user : Tests(no_plans)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    my $file = $self->shadow_file;

    file_write($self->shadow_file, (''));

    my $obj = GMS::Account::Local::User->new(shadow_file => $file);

    my %params = (name => 'nonexistuser',);

    my $module = Test::MockModule->new('GMS::Account::Local::User');
    $module->mock(_find_user_shadow => sub { return undef; });

    $module->mock(
        _find_user_shadow => sub
        {
            my %user = (
                name => 'dohyun',
                key  => 'key',
            );
            return \%user;
        }
    );

    cmp_ok($obj->passwd(%params), '==', 0, 'passwd defined_user success');

    $module->unmock("_find_user_shadow");

    cmp_ok($obj->passwd(%params), '==', 0, 'passwd define_user success');

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub test_passwd_defined_user : Tests(no_plans)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "mkdir failed: $self->mock_dir: $!";

    my $file = $self->shadow_file;

    file_write($self->shadow_file,
        ("\n", "#\n", "undef:blah\n", "nonexistuser:blah\n", ":blah\n",));

    my $obj = GMS::Account::Local::User->new(shadow_file => '');

    my %params = (name => 'nonexistuser',);

    my $module = Test::MockModule->new('GMS::Account::Local::User');
    $module->mock(
        _find_user_shadow => sub
        {
            my %user = (
                name => 'dohyun',
                key  => 'key',
            );
            return \%user;
        }
    );

    cmp_ok($obj->passwd(%params),
        '==', -1, 'passwd defined_user failed by open shadow_file');

    $obj = GMS::Account::Local::User->new(shadow_file => $file);
    cmp_ok($obj->passwd(%params), '==', 0, 'passwd defined_user success');

    $module = Test::MockModule->new('IO::File');
    $module->mock(seek => sub { return 0; });

    cmp_ok($obj->passwd(%params),
        '==', -1, 'passwd defined_user failed by seek');

    $module->unmock("seek");

    $module->mock(truncate => sub { return 0; });

    cmp_ok($obj->passwd(%params),
        '==', -1, 'passwd defined_user failed by truncate');

    $module->unmock("truncate");

    rmtree($self->mock_dir)
        || die "rmtree failed: $self->mock_dir: $!";
}

sub test_stringify_passwd_entiry : Tests(no_plans)
{
    my $obj = GMS::Account::Local::User->new();

    my %params1 = (user => 'anyuser',);

    my %params2 = (
        user => {
            name => 'anyuser',
            dob  => '2000-00-00',
        },
    );

    ok($obj->_stringify_passwd_entiry(), 'stringify_passwd_entiry success');

    ok(
        $obj->_stringify_passwd_entiry(%params1),
        'stringify_passwd_entiry define_user_hash'
    );

    ok(
        $obj->_stringify_passwd_entiry(%params2),
        'stringify_passwd_entiry define_user_success'
    );
}

sub test_stringify_shadow_entry : Tests(no_plans)
{
    my $obj = GMS::Account::Local::User->new();

    my %params1 = (user => 'anyuser',);

    my %params2 = (
        user => {
            name => 'anyuser',
            dob  => '2000-00-00',
        },
    );

    ok($obj->_stringify_shadow_entry(), 'stringify_shadow_entry success');

    ok(
        $obj->_stringify_shadow_entry(%params1),
        'stringify_shadow_entry define_user_hash'
    );

    ok(
        $obj->_stringify_shadow_entry(%params2),
        'stringify_shadow_entry define_user_success'
    );
}

1;
