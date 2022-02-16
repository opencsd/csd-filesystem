package Test::Account::Local;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use File::Path "rmtree";
use File::Temp qw/ :POSIX /;
use String::Random;

use GMS::Account::Local;
use Test::Class::Moose extends => 'Test::GMS';
use Test::MockModule;

with 'Test::Role::FileReadWrite', 'Test::Role::Dir';

has 'mock_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc'
);

has 'test_passwd' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/passwd',
);

has 'test_group' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/group',
);

has 'test_shadow' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/shadow',
);

sub test_check : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my %targets = (
        passwd_file => $self->test_passwd,
        group_file  => $self->test_group,
        shadow_file => $self->test_shadow,
    );

    foreach my $target (values(%targets))
    {
        file_write($target, ());
    }

    my $obj = GMS::Account::Local->new(%targets);

    cmp_ok($obj->check(), '==', 0, 'check() success');

    foreach my $file (values(%targets))
    {
        unlink($file);

        cmp_ok($obj->check(), '==', -1, 'check() failure');

        file_write($file, ());
    }

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_connect : Tests(no_plan)
{
    my $self = shift;

    my $module = Test::MockModule->new('GMS::Account::Local');

    $module->mock('check' => sub { return 0 });

    my $obj = GMS::Account::Local->new();

    cmp_ok($obj->connect(), '==', 0, 'connect() success');
}

sub test_disconnect : Tests(no_plan)
{
    my $self = shift;

    my $obj = GMS::Account::Local->new();

    cmp_ok($obj->disconnect(), '==', 0, 'disconnect()_success');
}

sub test_get_avail_uid : Tests(no_plan)
{
    my $self = shift;

    my $obj = GMS::Account::Local->new();

    $obj->get_avail_uid();

    ok($obj->get_avail_uid(), 'get_avail_uid()_success');
}

sub test_get_avail_uid_check_uid_assign : Tests(no_plan)
{
    my $module = Test::MockModule->new('GMS::Account::Local');

    $module->mock(get_default => sub { return undef; });

    my $obj = GMS::Account::Local->new();

    cmp_ok($obj->get_avail_uid(), '>=', 1000,
        'get_avail_uid()_default check');
}

sub test_get_avail_uid_check_passwd_file_open : Tests(no_plan)
{
    my $file = tmpnam();

    my $obj = GMS::Account::Local->new(passwd_file => $file);

    cmp_ok($obj->get_avail_uid(), '==', -1, 'fail if file does not open');
}

sub test_get_avail_uid_check_valid_uid : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file = $self->test_passwd;

    my $module = Test::MockModule->new('GMS::Account::Local');
    $module->mock(get_default => sub { return undef; });

    my $obj = GMS::Account::Local->new(passwd_file => $file);

    file_write(
        $file,
        (
            "#\n", "\n", "string for test undefined uid\n",
            "dohyunkim:x:1000:\n",
        )
    );

    cmp_ok($obj->get_avail_uid(), '==', 1001, 'get vailed uid 1001');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_get_avail_gid : Tests(no_plan)
{
    my $self = shift;

    my $obj = GMS::Account::Local->new();

    $obj->get_avail_gid();

    ok($obj->get_avail_gid(), 'get_avail_gid()_success');
}

sub test_get_avail_gid_check_gid_assign : Tests(no_plan)
{
    my $module = Test::MockModule->new('GMS::Account::Local');

    $module->mock(get_default => sub { return undef; });

    my $obj = GMS::Account::Local->new();

    cmp_ok($obj->get_avail_gid(), '>=', 1000,
        'get_avail_gid()_default check');
}

sub test_get_avail_gid_check_group_file_open : Tests(no_plan)
{
    my $file = tmpnam();

    my $obj = GMS::Account::Local->new(group_file => $file);

    cmp_ok($obj->get_avail_gid(), '==', -1, 'fail if file does not open');
}

sub test_get_avail_gid_check_valid_gid : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file = $self->test_group;

    my $module = Test::MockModule->new('GMS::Account::Local');
    $module->mock(get_default => sub { return undef; });

    my $obj = GMS::Account::Local->new(group_file => $file);

    file_write(
        $file,
        (
            "#\n", "\n", "string for test undefined gid\n",
            "dohyunkim:x:1000:\n",
        )
    );

    cmp_ok($obj->get_avail_gid(), '==', 1001, 'get vailed gid 1001');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_join_to : Tests(no_plan)
{
    my $self = shift;

    my %params = (
        user   => 'iKaroS',
        groups => ['']
    );

    my $module = Test::MockModule->new('GMS::Account::Local');

    $module->define(
        gi => sub
        {
            return {members => []};
        }
    );

    $module->redefine(
        find_group => sub
        {
            my $self = shift;

            my %name = @_;

            if ($name{name} eq '')
            {
                return undef;
            }

            return $self->gi();
        }
    );

    $module->redefine(
        update_group => sub
        {
            my $self = shift;

            if (!defined($self->gi->{name})
                || !defined($self->gi->{gpasswd}))
            {
                return 1;
            }

            return 0;
        }
    );

    my $obj = GMS::Account::Local->new();

    cmp_ok($obj->join_to(%params),
        '==', 0, 'join_to() Error - group_info undef');

    $params{'groups'} = ['Espera'];

    cmp_ok($obj->join_to(%params),
        '==', -1, 'join_to() failure - undef group_info\'s member');

    $module->mock(
        gi => sub
        {
            return {
                members => [],
                gpasswd => 'a3df',
                name    => 'iKaroS'
            };
        }
    );

    cmp_ok($obj->join_to(%params), '==', 0, 'join_to() success');
}

sub test_withdraw_from : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file = $self->test_group;

    my $obj = GMS::Account::Local->new(group_file => $file);

    file_write($file, ("salesg:x:1361:sara,dohyunkim",));

    my $randGroupname;
    my $string_gen = String::Random->new();

    while (1)
    {
        $randGroupname = $string_gen->randpattern("CCcc!ccn");
        last if (!defined($obj->find_group(name => $randGroupname)));
    }

    my %params = (
        user   => 'dohyunkim',
        groups => ['salesg', $randGroupname,],
    );

    cmp_ok($obj->withdraw_from(%params), '==', 0, 'withdraw_from() success');

    my $module = Test::MockModule->new('GMS::Account::Local');
    $module->mock(update_group => sub { return -1; });

    $obj = GMS::Account::Local->new(group_file => $file);

    cmp_ok($obj->withdraw_from(%params),
        '==', -1, 'withdraw_from() failure on update group');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_is_member : Tests(no_plan)
{
    my $self = shift;

    my $user       = "hyuno";
    my $other_user = "hyuno2";
    my $group1     = "group1";
    my $group2     = "group2";

    my $obj = GMS::Account::Local->new();

    my @user_info1 = ('user', undef);
    my @user_info2 = ('user', "");

    my @user_info3 = ('user', $user, 'group', undef);
    my @user_info4 = ('user', $user, 'group', "");

    my $nouser         = $obj->is_member(@user_info1);
    my $char_user      = $obj->is_member(@user_info2);
    my $isusr_nogrp    = $obj->is_member(@user_info3);
    my $isusr_char_grp = $obj->is_member(@user_info4);

    # isuser test
    cmp_ok($nouser,    '==', -1, "is_member() Failure(no user info)");
    cmp_ok($char_user, '==', -1, "is_member() Failure(char user info)");

    # isgroup test
    cmp_ok($isusr_nogrp, '==', -1, "is_member() Failure(user haven't group)");
    cmp_ok($isusr_char_grp, '==', -1,
        "is_member() Failure(user have char group)");

    # use group_info
    my @usrgrp_info  = ('user', $user,       'group', $group1);
    my @usrgrp_info2 = ('user', $user,       'group', $group2);
    my @usrgrp_info3 = ('user', $user,       'group', $group1);
    my @usrgrp_info4 = ('user', $other_user, 'group', $group2);

    # use MockModule(GMS::Account::Local)
    my $module = Test::MockModule->new('GMS::Account::Local');

    $module->define(
        user => sub
        {
            $user = 'hyuno';

            return $user;
        }
    );

    $module->define(
        member => sub
        {
            my @member = ('hyuno');

            return \@member;
        }
    );

    $module->define(
        usr_grp_table => sub
        {
            my %table = (
                hyuno  => 'group1',
                hyuno2 => 'group2',
            );

            return %table;
        }
    );

    # find_group() overriding
    $module->redefine(
        find_group => sub
        {
            my $self = shift;
            my %args = @_;

            $user = $self->user();
            my %table = $self->usr_grp_table();

            return undef if (!($args{name} eq $table{$user}));

            my %group = (
                name    => $args{name},
                gpasswd => "",
                gid     => 1007,
                members => $self->member(),
            );

            return \%group;
        }
    );

    my $isusr_isgrp = $obj->is_member(@usrgrp_info);

    cmp_ok($isusr_isgrp, '==', 1, "is_member() Success");

    my $isusr2_isgrp = $obj->is_member(@usrgrp_info2);

    cmp_ok($isusr2_isgrp, '==', 0, "is_member() Failure(undefined group)");

    $module->mock('member', sub { my $member = ''; return $member; });

    my $isusr3_isgrp = $obj->is_member(@usrgrp_info3);

    cmp_ok($isusr3_isgrp, '==', 0, "is_member() Failure(isgroup no member)");

    $module->mock('user', sub { $user = 'hyuno2'; return $user; });
    $module->mock('member', sub { my @member = ('hyuno'); return \@member; });

    my $isusr4_isgrp = $obj->is_member(@usrgrp_info4);

    cmp_ok($isusr4_isgrp, '==', 0,
        "is_member() Failure(user not match group)");
}

sub test_reload_users : Tests(no_plan)
{
    my $self = shift;

    my $obj = GMS::Account::Local->new(passwd_file => $self->test_passwd);

    cmp_ok($obj->reload_users(), '==', -1,
        'reload_users failed - $fh is undef');

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    file_write(
        $self->test_passwd,
        (
            "\n",         # line coverage 1x
            "#test\n",    # line coverage 01
            ":\n",        # line coverage 00, !user{name} 1x

            ######## $local_exists{name} = 파일에 입력한 ID

            "test:\n",    # !user{name} 0? user_filter에 따라 달라질 것
                          # $all_users->{user{name}} = undef
                          # !exists($local_exists{}) T

            "iKaroS:\n",  # !user{name} 0?
                          # $all_users->{user{name}} = defined

            "iKaroS::xxx:gec\n"
            , # $value = definded, #expected = defined, $value eq $expected 00
              # $value = definded, #expected = defined, $value nq $expected 01

            "iKaroS::\n",    # $value = undef, #expected = defined 1x
        )
    );

    my $module = Test::MockModule->new('GMS::Account::Local');

    $module->noop('around');
    $module->mock(
        user_filter => sub
        {
            return sub { return 1; };
        }
    );
    $module->mock(all_users => sub { return undef; });    # $args{data} 00

    cmp_ok($obj->reload_users(), '==', 0,
        'reload_users return 0 - user_filter == 1');      # !user{name} 01
                                                          # !user{name} 1x

    $module->noop('around');
    $module->mock(
        user_filter => sub
        {
            return sub { return 0; };
        }
    );
    $module->mock(delete_user => sub { return -1; });
    $module->mock(all_users   => sub { return {}; });     # $args{data} 01

    cmp_ok($obj->reload_users(), '==', -1,
        'reload_users failure - delete_user == -1');      # delete_user T

    $module->noop('around');
    $module->mock(delete_user => sub { return 0; });
    $module->mock(create_user => sub { return -1; });

    my %args = (
        data => {
            iKaroS => {uid => 'xxx', gid => 'cer'},
            Espera => {}                              # !exists ~~ T
        }
    );

    cmp_ok($obj->reload_users(%args),
        '==', -1, 'reload_users failure - create_user == -1')
        ;    # !user{name} 00

    $module->noop('around');
    $module->mock(delete_user => sub { return 0; });
    $module->mock(create_user => sub { return 0; });
    $module->mock(passwd      => sub { return -1; });

    cmp_ok($obj->reload_users(%args),
        '==', -1, 'reload_users failure - passwd == -1');

    $module->noop('around');
    $module->mock(delete_user => sub { return 0; });
    $module->mock(create_user => sub { return 0; });
    $module->mock(passwd      => sub { return 0; });

    cmp_ok($obj->reload_users(%args), '==', 0, 'reload_users success');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_reload_groups : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file = $self->test_group;

    file_write(
        $file,
        (
            "#\n",
            "\n",
            ":blah\n",
            "dohyunkim:x:1000:dohyunkim,sara\n",
            "jasonkim:x:1001:sean,sara\n",
            "string for test undefined gid\n",
            " :dohyunkim:x:1000:\n",
        )
    );

    my $obj = GMS::Account::Local->new(group_file => $file);

    # for normal case
    cmp_ok($obj->reload_groups(), '==', 0, 'reload_groups() success');

    # test reload_groups include args{data}
    cmp_ok($obj->reload_groups(data => {}),
        '==', 0, 'reload_groups() include args{data}');

    # test reload_groups under mock all_groups
    my $module = Test::MockModule->new('GMS::Account::Local');
    $module->mock(all_groups => sub { return undef; });

    cmp_ok($obj->reload_groups(), '==', 0, 'reload_groups() success');

    # test reload_groups with nonexistfile
    my $non_existing_file = '/tmp/etc/noexistdirfortest/exfile';
    $obj = GMS::Account::Local->new(group_file => $non_existing_file);

    cmp_ok($obj->reload_groups(), '==', -1,
        'reload_groups() failed on fileopen');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_reload_groups_to_be_deleted_added : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file = $self->test_group;

    file_write(
        $file,
        (
            "\n",
            "dohyunkim:x:1000:donee,sara\n",
            "sara:x:1001:kay,json\n",
            "jsaonkim:x:1001:sean,sara\n",
        )
    );

    my $module = Test::MockModule->new('GMS::Account::Local');

    $module->mock(
        all_groups => sub
        {
            my %groups;
            $groups{dohyunkim} = {
                name    => 'dohyunkim',
                gpasswd => 'x',
                gid     => 1000,
                members => ['elie', 'joke'],
            };
            $groups{sara} = {
                name    => 'sara',
                gpasswd => 'x',
                gid     => 1001,
                members => ['kay', 'json'],
            };

            return \%groups;
        }
    );

    my $obj = GMS::Account::Local->new(group_file => $file);

    cmp_ok($obj->reload_groups(), '==', 0, 'reload_groups() success');

    ##### delete_create_group_mock

    $module->noop('around');
    $module->mock(create_group => sub { return -1; });

    cmp_ok($obj->reload_groups(), '==', -1,
        'reload_groups() failed on create_group');

    $module->unmock("create_group");

    file_write($file, ("dohyunkim:x:1000:donee,sara\n",));

    $module->mock(delete_group => sub { return -1; });

    cmp_ok($obj->reload_groups(), '==', -1,
        'reload_groups() failed on delete_group');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_find_user_smbpasswd : Tests(no_plan)
{
    my $self = shift;

    my %params1 = (name => 'dohyunkim',);
    my $params2 = (name => 'sara',);

    my $obj = GMS::Account::Local->new();

    my $module = Test::MockModule->new('GMS::Common::IPC');

    $module->mock(
        exec => sub
        {
            my %args   = @_;
            my $cmd    = $args{cmd};
            my @args   = ();
            my $cb_out = $args{cb_out};

            if ($cb_out)
            {
                local $_ = "dohyunkim:x";
                $cb_out->($_);
            }
            my $retval = {
                cmd  => 'cmdval',
                args => 'argsval',
            };

            return $retval;
        }
    );

    cmp_ok($obj->find_user_smbpasswd(%params1),
        '==', 1, 'find_user_smbpasswd() success');

    $module->mock(
        exec => sub
        {
            my %args   = @_;
            my @args   = ();
            my $cmd    = $args{cmd};
            my $cb_out = $args{cb_out};

            if ($cb_out)
            {
                local $_ = "dohyunkim:x";
                $cb_out->($_);
            }

            my $retval = {status => 'ok',};

            return $retval;
        }
    );

    $obj->find_user_smbpasswd($params2);

    $module->mock(exec => sub { return undef; });

    cmp_ok($obj->find_user_smbpasswd(),
        '==', -1, 'find_user_smbpasswd() failure with error');
}

sub test_retry_smbpasswd : Tests(no_plan)
{
    my $mode1     = 'add';
    my $mode2     = 'del';
    my $mode3     = 'edit';
    my $name      = 'Hyuno';
    my %exec_args = (
        cmd     => 'smbpasswd',
        args    => ['-t', $name],
        timeout => 10,
    );

    my @args1 = ($mode1, $name, \%exec_args);
    my @args2 = ($mode2, $name, \%exec_args);
    my @args3 = ($mode3, $name, \%exec_args);

    my $module = Test::MockModule->new('GMS::Common::IPC');

    $module->redefine(
        exec => sub
        {
            my %args = @_;

            return;
        }
    );

    my $test1 = GMS::Account::Local::retry_smbpasswd(@args1);

    cmp_ok($test1, '==', -1, 'retry_smbpasswd() Failure(none Hash value)');

    $module->mock(
        exec => sub
        {
            my %args = @_;

            my %result = (status => 1,);

            return \%result;
        }
    );

    my $test2 = GMS::Account::Local::retry_smbpasswd(@args1);

    cmp_ok($test2, '==', -1, 'retry_smbpasswd() Failure(is timeout)');

    $module->mock(
        exec => sub
        {
            my %args = @_;

            return if ($args{args}[0] eq '-e');

            my %result = (status => 0,);

            return \%result;
        }
    );

    my $test3 = GMS::Account::Local::retry_smbpasswd(@args1);

    cmp_ok($test3, '==', -1,
        'retry_smbpasswd() Failure(mode = "add" & none Hash Value)');

    $module->mock(
        exec => sub
        {
            my %args   = @_;
            my %result = (status => 0,);

            if ($args{args}[0] eq '-x')
            {
                %result = (status => 255,);

                return \%result;
            }

            return \%result;
        }
    );

    my $test4 = GMS::Account::Local::retry_smbpasswd(@args2);

    cmp_ok($test4, '==', -1,
        'retry_smbpasswd() Failure(mode = "del" & is timeout)');

    $module->mock(
        exec => sub
        {
            my %args   = @_;
            my %result = (status => 0,);

            return if ($args{args}[0] ne '-t');

            return \%result;
        }
    );

    my $test5 = GMS::Account::Local::retry_smbpasswd(@args3);

    cmp_ok($test5, '==', 0, 'retry_smbpasswd() mode != (add & del)');

    $module->mock(
        exec => sub
        {
            my %args = @_;

            my %result = (status => 0,);

            return \%result;
        }
    );

    my $test6 = GMS::Account::Local::retry_smbpasswd(@args1);

    cmp_ok($test6, '==', 0, 'retry_smbpasswd() Success');
}

sub _test_rename_user : Tests(no_plans)
{
    my $self = shift;

    my $obj    = GMS::Account::Local->new();
    my $module = Test::MockModule->new('GMS::Account::Local');
    my $io     = Test::MockModule->new('IO::File');

    my $seek_called     = 0;
    my $truncate_called = 0;

    cmp_ok($obj->rename_user(), '==', -1,
        'rename_user failure - args is undef');

    my %params = (
        'old' => 'Espera',
        'new' => 'iKaroS'
    );

    $module->mock(user_exists => sub { return 0; });
    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - args{old} is undef');

    $module->mock(user_exists => sub { return 1; });
    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - args{new} is undef');

    $module->mock(
        user_exists => sub
        {
            my $self = shift;
            my %args = @_;

            return 1 if ($args{name} eq $params{old});

            return 0;
        }
    );
    $module->mock(passwd_file => $self->test_passwd);

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - fh is undef');

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    file_write(
        $self->test_passwd,
        (
            "\n",           # line coverage 1x
            "#iKaroS\n",    # line coverage 01
            ":\n",          # name T
            "iKaroS:\n",    # name ne args{old}
            "Espera:"
        )
    );

    $io->mock(seek => sub { return 0; });

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - seek failure');

    $io->mock(tell => sub { return 1; });
    $io->mock(seek => sub { return 1; });
    file_write($self->test_passwd, ());    # no while loop
    $io->mock(truncate => sub { return 0; });

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - truncate failure');

    $module->mock(shadow_file => undef);
    $io->mock(truncate => sub { return 1; });
    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - [S] fh is undef');

    ############### End passwd_file  ###############

    $module->mock(group_file  => $self->test_group);
    $module->mock(shadow_file => $self->test_shadow);
    file_write(
        $self->test_shadow,
        (
            "\n",           # line coverage 1x
            "#iKaroS\n",    # line coverage 01
            ":\n",          # name T
            "iKaroS:\n",    # name ne args{old}
            "Espera:"
        )
    );

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - [S] LOCK_EX is failure');

    $io->mock(
        seek => sub
        {
            return 0 if ($seek_called >= 1);

            $seek_called++;
            return 1;
        }
    );

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - [S] seek is failure');
    $seek_called = 0;
    $io->mock(seek => sub { return 1; });

    $io->mock(
        truncate => sub
        {
            return 0 if ($truncate_called >= 1);

            $truncate_called++;
            return 1;
        }
    );

    file_write($self->test_shadow, ());    # no while loop

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - [S] truncate is failure');

    $io->mock(truncate => sub { return 1; });
    $truncate_called = 0;

    ############### End shadow_file ###############

    $module->mock(group_file => $self->test_group);

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - [G] fh is undef');

    file_write(
        $self->test_group,
        (
            "\n",                    # line coverage 1x
            "#iKaroS\n",             # line coverage 01
            ":\n",                   # name T
            "iKaroS:\n",             # name ne args{old}, member F
            "iKaroS:::,Espera\n",    # mems[$i] T/F
        )
    );

    $io->mock(
        seek => sub
        {
            return 0 if ($seek_called >= 2);

            $seek_called++;
            return 1;
        }
    );

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - [G] seek is failure');
    $seek_called = 0;
    $io->mock(seek => sub { return 1; });

    $io->mock(
        truncate => sub
        {
            if ($truncate_called >= 2)
            {
                return 0;
            }

            $truncate_called++;
            return 1;
        }
    );

    file_write($self->test_shadow, ());    # no while loop

    cmp_ok($obj->rename_user(%params),
        '==', -1, 'rename_user failure - [G] truncate is failure');

    $io->mock(truncate => sub { return 1; });
    $truncate_called = 0;

    cmp_ok($obj->rename_user(%params), '==', 0, 'rename_user success');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

1;

=encoding utf8

=head1 NAME

Test::Account::Local -

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
