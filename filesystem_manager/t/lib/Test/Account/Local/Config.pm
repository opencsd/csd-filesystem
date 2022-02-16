package Test::Account::Local::Config;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use File::Path "rmtree";

use GMS::Account::Local::Config;
use Test::Class::Moose extends => 'Test::GMS';
use Test::MockModule;

with 'Test::Role::FileReadWrite', 'Test::Role::Dir';

has 'mock_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc'
);

has 'test_useradd_defs' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/useradd_defs',
);

has 'test_login_defs' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/login_defs',
);

sub test_load_config : Tests(no_plan)
{
    my $self = shift;

    my $obj = GMS::Account::Local::Config->new();

    cmp_ok($obj->load_config(), '==', 0, 'load_config() success');

    my %params1 = (useradd_defs => '/tmp/nonexistdir/randname/useradd_defs');

    my %params2 = (login_defs => '/tmp/nonexistdir/randname/useradd_defs');

    cmp_ok($obj->load_config(%params1),
        '==', -1, 'failed on open useradd_defs');
    cmp_ok($obj->load_config(%params2),
        '==', -1, 'failed on open login_defs');
}

sub test_load_config_useradd : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file = $self->test_useradd_defs;

    file_write(
        $file,
        (
            "\n",     "#\n",             "string for test undefined\n",
            "blah\n", "SHELL=/bin/sh\n", " =blah\n",
        )
    );

    my %params = (useradd_defs => $file,);

    my $obj = GMS::Account::Local::Config->new();

    cmp_ok($obj->load_config(%params), '==', 0, 'load_config() success');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_load_config_login : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file = $self->test_login_defs;

    file_write(
        $file,
        (
            "\n",           "#\n", "string for test undefined blah\n",
            "values[0] \n", " values[1]\n", "GID_MIN    1000\n",
        )
    );

    my %params = (login_defs => $file,);

    my $obj = GMS::Account::Local::Config->new();

    cmp_ok($obj->load_config(%params), '==', 0, 'load_config() success');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_write_config_non_existing_files : Tests(no_plan)
{
    my $obj = GMS::Account::Local::Config->new();

    my %params1 = (useradd_defs => '/tmp/nonexistdir/randname/useradd_defs',);

    my %params2 = (login_defs => '/tmp/nonexistdir/randname/login_defs',);

    cmp_ok($obj->write_config(%params1),
        '==', -1, 'failed on open useradd_defs');
    cmp_ok($obj->write_config(%params2),
        '==', -1, 'failed on open login_defs');
}

sub test_write_config_useradd : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file = $self->test_useradd_defs;

    file_write(
        $file,
        (
            "\n",      "#\n", "string for test undefined\n",
            "=blah\n", "SHELL=/bin/sh\n",
        )
    );

    my %params = (
        useradd_defs => $file,
        login_defs   => '/tmp/nonexistdir/randname/login_defs',
    );

    my $obj = GMS::Account::Local::Config->new();

    cmp_ok($obj->write_config(%params), '==', -1,
        'failed on open login_defs');

    my $module = Test::MockModule->new('IO::File');

    $module->mock(seek     => sub { return 0; });
    $module->mock(truncate => sub { return 0; });

    cmp_ok($obj->write_config(%params), '==', -1, 'fh->seek primary fail');

    $module->unmock('seek');

    cmp_ok($obj->write_config(%params), '==', -1,
        'fh->truncate primary fail');

    $module->unmock('truncate');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_write_config_login : Tests(no_plan)
{
    my $self = shift;

    make_dir($self->mock_dir)
        && die "Failed to make_dir: $self->mock_dir: $!";

    my $file1 = $self->test_useradd_defs;
    my $file2 = $self->test_login_defs;

    file_write(
        $file1,
        (
            "\n",      "#\n", "string for test undefined\n",
            "=blah\n", "SHELL=/bin/sh\n",
        )
    );

    file_write(
        $file2,
        (
            "\n",           "#\n", "string for test undefined blah\n",
            "values[0] \n", " values[1]\n", "GID_MIN    1000\n",
        )
    );

    my %params = (
        useradd_defs => $file1,
        login_defs   => $file2,
    );

    my $obj = GMS::Account::Local::Config->new();

    cmp_ok($obj->write_config(%params), '==', 0, 'write_config() success');

    #### for second seek failure

    my $cnt = 0;

    my $module = Test::MockModule->new('IO::File');
    $module->mock(
        seek => sub
        {
            if ($cnt >= 1) { return 0; }
            $cnt++;

            return 1;
        }
    );

    cmp_ok($obj->write_config(%params), '==', -1, 'fh->seek secondary fail');

    $module->unmock('seek');

    #### for second truncate failure

    $cnt = 0;

    $module->mock(
        truncate => sub
        {
            if ($cnt >= 1) { return 0; }
            $cnt++;

            return 1;
        }
    );

    cmp_ok($obj->write_config(%params),
        '==', -1, 'fh->truncate secondary fail');

    rmtree($self->mock_dir)
        || die "Failed to rmtree: $self->mock_dir: $!";
}

sub test_get_default : Tests(no_plan)
{
    my $self = shift;

    my $obj = GMS::Account::Local::Config->new();

    my %key = (key => 'non_exist_key_for_unitTest',);

    cmp_ok($obj->get_default(%key), '==', 0, 'get_default() success');

    my $module = Test::MockModule->new('GMS::Account::Local::Config');

    $module->mock(exists_login_defs => sub { return 1; });
    $module->mock(get_login_defs    => sub { return 1; });

    cmp_ok($obj->get_default(%key), '==', 1, 'exists_login_defs() excute');

    $module->unmock('exists_login_defs');

    $module->mock(exists_useradd_defs => sub { return 1; });
    $module->mock(get_useradd_defs    => sub { return 1; });

    cmp_ok($obj->get_default(%key), '==', 1, 'exists_useradd_defs() excute');
}

sub test_set_default : Tests(no_plan)
{
    my $self = shift;

    my $obj = GMS::Account::Local::Config->new();

    my %key = (key => 'non_exist_key_for_unitTest',);

    cmp_ok($obj->set_default(%key), '==', -1, 'set_default() success');

    my $module = Test::MockModule->new('GMS::Account::Local::Config');

    $module->mock(exists_login_defs => sub { return 1; });
    $module->mock(set_login_defs    => sub { return 1; });

    cmp_ok($obj->set_default(%key), '==', 1, 'exists_login_defs() excute');

    $module->unmock('exists_login_defs');

    $module->mock(exists_useradd_defs => sub { return 1; });
    $module->mock(set_useradd_defs    => sub { return 1; });

    cmp_ok($obj->set_default(%key), '==', 1, 'exists_useradd_defs() excute');
}

1;

=encoding utf8

=head1 NAME

Test::Account::Local::Config -

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

