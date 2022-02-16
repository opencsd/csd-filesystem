package Test::Account::Local::Group;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use File::Path "rmtree";

use GMS::Account::Local::Group;
use Test::Class::Moose extends => 'Test::GMS';
use Test::MockModule;

with 'Test::Role::FileReadWrite';
with 'Test::Role::Dir';

has 'test_group' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/group',
);

has 'test_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/',
);

sub test_all_groups : Tests(no_plan)
{
    my $self = shift;

    my $test_dir = $self->test_dir;

    make_dir($test_dir)
        && die "Failed to mkdir: $test_dir: $!";

    my $group_file = $self->test_group;

    my $obj = GMS::Account::Local::Group->new(group_file => $group_file);

    my @contents = (
        "\n:x:10071:Hyuno1:Hyuno2:",
        ":x:10072:Hyuno1:Hyuno2:\n",
        "group1:x:10073:Hyuno1:Hyuno2:\n",
        "group2:x:10074:Hyuno1:Hyuno2:\n",
        "group3:x:10075:Hyuno1:Hyuno2:\n",
        "group4:x:10075:\n"
    );

    file_write($group_file, @contents);

    cmp_ok(ref($obj->all_groups()),
        'eq', 'HASH', 'all_groups() Failure(while loop is not ok)');

    my $obj2 = GMS::Account::Local::Group->new(
        group_file   => $group_file,
        group_filter => sub { return 1; }
    );

    cmp_ok(ref($obj2->all_groups()), 'eq', 'HASH', 'all_groups() Success');

    $obj2 = GMS::Account::Local::Group->new(
        group_file   => $group_file,
        group_filter => sub { return; }
    );

    cmp_ok(ref($obj2->all_groups()),
        'eq', 'HASH',
        'all_groups() Failure(CodeRef in the group_filter is undef)');

    my $module_file = Test::MockModule->new('IO::File');

    $module_file->mock(new => sub { return undef; });

    cmp_ok($obj->all_groups(), '==', undef,
        'all_groups() Failure(fh is undefined)');

    rmtree($test_dir)
        || die "rmtree failure";
}

sub test_group_exists : Tests(no_plan)
{
    my %args1 = (
        name => undef,
        gid  => undef,
    );

    my %args2 = (
        name => undef,
        gid  => "1007",
    );

    my %args3 = (
        name => "Hyuno",
        gid  => undef,
    );

    my $obj = GMS::Account::Local::Group->new();

    cmp_ok($obj->group_exists(%args1), '==', -1, 'group_exists() Failure');

    my $module = Test::MockModule->new('GMS::Account::Local::Group');

    $module->mock(
        find_group => sub
        {
            my %args = @_;

            return (name => "Hyuno", gid => 1007);
        }
    );

    cmp_ok($obj->group_exists(%args2), '==', 1, 'group_exists() Success');

    $module->mock(
        find_group => sub
        {
            my %args = @_;

            return undef;
        }
    );

    cmp_ok($obj->group_exists(%args3), '==', 0, 'group_exists() Failure');
}

sub test_find_group : Tests(no_plan)
{
    my $self = shift;

    my $test_dir = $self->test_dir;

    make_dir($test_dir)
        && die "Failed to mkdir: $test_dir: $!";

    my %args0 = (
        name => undef,
        gid  => undef,
    );

    my %args1 = (
        name => undef,
        gid  => 1007,
    );

    my %args2 = (
        name => 'group1',
        gid  => undef,
    );

    my %args3 = (
        name => 'group1',
        gid  => 1007,
    );

    my $group_file = $self->test_group;

    my $obj = GMS::Account::Local::Group->new(group_file => $group_file);

    cmp_ok($obj->find_group(%args0),
        '==', undef, 'find_group() Failure(group name & gid  is undefined)');

    my @contents = (
        "\n:x:10071:Hyuno1:Hyuno2:\n",
        "#:x:10072:Hyuno1:Hyuno2:\n",
        "group1:x:1008:Hyuno1:Hyuno2:\n",
        "group2:x:1007:Hyuno1:Hyuno2:\n",
        "group2:x:10074:Hyuno1:Hyuno2:\n",
        "group1:x:1008:Hyuno1:Hyuno2:\n",
        ":x:1007:Hyuno1:Hyuno2:\n",
        "group1:x:1007:Hyuno1:Hyuno2:\n"
    );

    file_write($group_file, @contents);

    cmp_ok(ref($obj->find_group(%args1)),
        'eq', 'HASH', 'find_group() Success');
    cmp_ok(ref($obj->find_group(%args3)),
        'eq', 'HASH', 'find_group() Failure(line start "#")');
    cmp_ok(ref($obj->find_group(%args2)),
        'eq', 'HASH', 'find_group() Failure(group name is not matched)');

    my $module_file = Test::MockModule->new('IO::File');

    $module_file->mock(new => sub { return undef; });

    cmp_ok($obj->find_group(%args3),
        '==', undef, 'find_group() Failure(fh is undefined)');

    rmtree($test_dir)
        || die "rmtree failure";
}

sub test_create_group : Tests(no_plan)
{
    my $self = shift;

    my $test_dir = $self->test_dir;

    make_dir($test_dir)
        && die "Failed to mkdir: $test_dir: $!";

    my %args1 = (
        name => undef,
        gid  => 1007,
    );

    my %args2 = (
        name => 'group1',
        gid  => undef,
    );

    my %args3 = (
        name => 'group1',
        gid  => 1007,
        mode => undef,
    );

    my %args4 = (
        name => 'group1',
        gid  => 1007,
        mode => 'reload',
    );

    my %args5 = (
        name    => 'group1',
        gid     => 1007,
        mode    => 'load',
        gpasswd => 1234,
        members => 'Hyuno',
    );

    my %args6 = (
        name    => 'group1',
        gid     => 1007,
        mode    => 'load',
        gpasswd => 1234,
        members => ['Hyuno1', 'Hyuno2'],
    );

    my $group_file = $self->test_group;

    my $obj = GMS::Account::Local::Group->new(group_file => $group_file);

    cmp_ok($obj->create_group(%args1),
        '==', -1, 'create_group() Failure(group name is undefined)');
    cmp_ok($obj->create_group(%args2),
        '==', -1, 'create_group() Failure(gid  is undefined)');

    my $module = Test::MockModule->new('GMS::Account::Local::Group');

    $module->mock(
        group_exists => sub
        {
            my $name = shift;

            return 1;
        }
    );

    cmp_ok($obj->create_group(%args3),
        '==', -1, 'create_group() Failure(group aleady exists)');

    $module->mock(
        group_exists => sub
        {
            my $name = shift;

            return;
        }
    );

    my @contents = ("\n:x:10071:Hyuno1:Hyuno2:");

    file_write($group_file, @contents);

    cmp_ok($obj->create_group(%args4),
        '==', 0, 'create_group() Failure(mode is reload)');
    cmp_ok($obj->create_group(%args5),
        '==', 0, 'create_group() Failure(member no equal "ARRAY")');
    cmp_ok($obj->create_group(%args6), '==', 0, 'create_group() Success');

    my $module_file = Test::MockModule->new('IO::File');

    $module_file->mock(new => sub { return undef; });

    cmp_ok($obj->create_group(%args6),
        '==', -1, 'create_group() Failure(fh is undefined)');

    rmtree($test_dir)
        || die "rmtree failure";
}

sub test_update_group : Tests(no_plan)
{
    my $self = shift;

    my $test_dir = $self->test_dir;

    make_dir($test_dir)
        && die "Failed to mkdir: $test_dir: $!";

    my %args1 = (
        name => undef,
        gid  => 1007,
    );

    my %args2 = (
        name => 'group1_edit',
        gid  => undef,
    );

    my %args3 = (
        name    => 'group1',
        gid     => 1007,
        members => 'Hyuno',
    );

    my %args4 = (
        name    => 'group1',
        gid     => 1007,
        members => ['Hyuno1', 'Hyuno2'],
    );

    my $group_file = $self->test_group;

    my $obj = GMS::Account::Local::Group->new(group_file => $group_file);

    cmp_ok($obj->update_group(%args1),
        '==', -1, 'update_group() Failure(name is undef as parameter)');

    my $module = Test::MockModule->new('GMS::Account::Local::Group');

    $module->mock(
        find_group => sub
        {
            my %args = @_;

            return undef;
        }
    );

    cmp_ok($obj->update_group(%args2),
        '==', -1, 'update_group() Failure(group is undefined)');

    $module->mock(
        find_group => sub
        {
            my %args = @_;

            my %group = (
                name => "group1",
                gid  => 1007,
            );

            return \%group;
        }
    );

    my @contents = (
        "\n:x:10071:Hyuno1:Hyuno2:\n",
        ":x:10071:Hyuno1:Hyuno2:\n",
        "group1_diff:x:10071:Hyuno1:Hyuno2:\n",
        "group1:x:10071:Hyuno1:Hyuno2:\n",
        "group1_edit:x:10071:Hyuno1:Hyuno2:\n",
        "#:x:10071:Hyuno1:Hyuno2:\n"
    );

    file_write($group_file, @contents);

    cmp_ok($obj->update_group(%args2),
        '==', 0, 'update_group() Failure(group edit & member undefined)');

    cmp_ok($obj->update_group(%args3),
        '==', 0, 'update_group() Failure(member is not ARRAY)');

    my $module_file     = Test::MockModule->new('IO::File');
    my $module_handle   = Test::MockModule->new('IO::Handle');
    my $module_seekable = Test::MockModule->new('IO::Seekable');

    $module_seekable->mock(seek => sub { return undef; });

    cmp_ok($obj->update_group(%args4),
        '==', -1, 'update_group() Failure(Failed to seek)');

    $module_seekable->mock(seek => sub { return 1; });
    $module_handle->mock(truncate => sub { return undef; });
    $module_seekable->mock(tell => sub { return 1; });

    cmp_ok($obj->update_group(%args4),
        '==', -1, 'update_group() Failure(Failed to truncate)');

    $module_handle->mock(truncate => sub { return 1; });

    cmp_ok($obj->update_group(%args4),
        '==', 0, 'update_group() Success(member is ok)');

    $module_file->mock(new => sub { return undef; });

    cmp_ok($obj->update_group(%args3),
        '==', -1, 'update_group() Failure(fh is undefined)');

    rmtree($test_dir)
        || die "rmtree failure";
}

sub test_rename_group : Tests(no_plan)
{
    my $self = shift;

    my $test_dir = $self->test_dir;

    make_dir($test_dir)
        && die "Failed to mkdir: $test_dir: $!";

    my %args1 = (
        new => undef,
        old => 'group1',
    );

    my %args2 = (
        new => 'group1',
        old => undef,
    );

    my %args3 = (
        new => 'group3',
        old => 'group2',
    );

    my %args4 = (
        new => 'group1',
        old => 'group1',
    );

    my %args5 = (
        new     => 'group2',
        old     => 'group1',
        members => ['Hyuno1', 'Hyuno2'],
    );

    my $group_file = $self->test_group;

    my $obj = GMS::Account::Local::Group->new(group_file => $group_file);

    cmp_ok($obj->rename_group(%args1),
        '==', -1, 'update_group() Failure(new is undef)');
    cmp_ok($obj->rename_group(%args2),
        '==', -1, 'update_group() Failure(old is undef)');

    my $module = Test::MockModule->new('GMS::Account::Local::Group');

    $module->mock(
        group_exists => sub
        {
            my $self = shift;
            my %args = @_;

            my $o_name = 'group1';

            my $found = 0;

            if ($args{name} eq $o_name)
            {
                $found = 1;
            }

            return $found;
        }
    );

    cmp_ok($obj->rename_group(%args3),
        '==', -1, 'rename_group() Failure(cannot find the group)');
    cmp_ok($obj->rename_group(%args4),
        '==', -1, 'rename_group() Failure(group already exists)');

    my @contents = (
        "\n:x:10071:Hyuno1:Hyuno2:\n",
        "#:x:10071:Hyuno1:Hyuno2:\n",
        ":x:10071:Hyuno1:Hyuno2:\n",
        "group1:x:10071:Hyuno1:Hyuno2:\n",
        "group1_diff:x:10071:Hyuno1:Hyuno2:\n"
    );

    file_write($group_file, @contents);

    my $module_file     = Test::MockModule->new('IO::File');
    my $module_handle   = Test::MockModule->new('IO::Handle');
    my $module_seekable = Test::MockModule->new('IO::Seekable');

    $module_seekable->mock(seek => sub { return undef; });

    cmp_ok($obj->rename_group(%args5),
        '==', -1, 'rename_group() Failure(Failed to seek)');

    $module_seekable->mock(seek => sub { return 1; });
    $module_handle->mock(truncate => sub { return undef; });
    $module_seekable->mock(tell => sub { return 1; });

    cmp_ok($obj->rename_group(%args5),
        '==', -1, 'rename_group() Failure(Failed to truncate)');

    $module_handle->mock(truncate => sub { return 1; });

    cmp_ok($obj->rename_group(%args5),
        '==', 0, 'rename_group() Success(member is ok)');

    $module_file->mock(new => sub { return undef; });

    cmp_ok($obj->rename_group(%args5),
        '==', -1, 'rename_group() Failure(fh is undefined)');

    rmtree($test_dir)
        || die "rmtree failure";
}

sub test_delete_group : Tests(no_plan)
{
    my $self = shift;

    my $test_dir = $self->test_dir;

    make_dir($test_dir)
        && die "Failed to mkdir: $test_dir: $!";

    my %args0 = (
        name => undef,
        gid  => undef,
    );

    my %args1 = (
        name => undef,
        gid  => 1007,
    );

    my %args2 = (
        name => 'group1',
        gid  => undef,
        mode => 'load',
    );

    my %args3 = (
        name => 'group1',
        gid  => 1007,
        mode => 'reload',
    );

    my $group_file = $self->test_group;

    my $obj = GMS::Account::Local::Group->new(group_file => $group_file);

    cmp_ok($obj->delete_group(%args0),
        '==', -1, 'delete_group() Failure(group name & gid  is undefined)');

    my $module = Test::MockModule->new('GMS::Account::Local::Group');

    $module->mock(
        group_exists => sub

        {
            my $self = shift;
            my %args = @_;

            my $o_group = 'group1';

            return 1 if ($args{name} eq $o_group);

            return;
        }
    );

    cmp_ok($obj->delete_group(%args1),
        '==', -1, 'delete_group() Failure(mode undefined)');
    cmp_ok($obj->delete_group(%args2),
        '==', -1, 'delete_group() Failure(mode is not reload)');

    my @contents = (
        "\n:x:10071:Hyuno1:Hyuno2:\n",
        "#:x:10071:Hyuno1:Hyuno2:\n",
        ":x:10071:Hyuno1:Hyuno2:\n",
        "group1:x:10071:Hyuno1:Hyuno2:\n",
        "group1_diff:x:10071:Hyuno1:Hyuno2:\n"
    );

    file_write($group_file, @contents);

    cmp_ok($obj->delete_group(%args3), '==', 0, 'delete_group() Success');

    my $module_file     = Test::MockModule->new('IO::File');
    my $module_handle   = Test::MockModule->new('IO::Handle');
    my $module_seekable = Test::MockModule->new('IO::Seekable');

    $module_seekable->mock(seek => sub { return undef; });

    cmp_ok($obj->delete_group(%args3),
        '==', -1, 'delete_group() Failure(Failed to seek)');

    $module_seekable->mock(seek => sub { return 1; });
    $module_handle->mock(truncate => sub { return undef; });
    $module_seekable->mock(tell => sub { return 1; });

    cmp_ok($obj->delete_group(%args3),
        '==', -1, 'delete_group() Failure(Failed to truncate)');

    $module_handle->mock(truncate => sub { return 1; });

    cmp_ok($obj->delete_group(%args3),
        '==', 0, 'delete_group() Success(member is ok)');

    $module_file->mock(new => sub { return undef; });

    cmp_ok($obj->delete_group(%args3),
        '==', -1, 'delete_group() Failure(fh is undefined)');

    rmtree($test_dir)
        || die "rmtree failure";
}

1;

=encoding utf8

=head1 NAME

Test::Account::Local::Group -

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
