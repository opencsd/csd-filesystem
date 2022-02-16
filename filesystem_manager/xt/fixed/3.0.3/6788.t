#!/usr/bin/perl

BEGIN
{
    use File::Basename          qw/dirname/;
    use File::Spec::Functions   qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Test::Most;
use Test::AnyStor::Explorer;
use File::Temp  qw/tmpnam/;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

my $t    = Test::AnyStor::Explorer->new();
my $path = tmpnam();

# 1. make parent dir
$t->makedir(path => $path);

# 2. setfacl with readable user/group
my %user_perm = (
    Type  => 'User',
    ID    => 'root',
    Right => 'W',
);

my %group_perm = (
    Type  => 'Group',
    ID    => 'root',
    Right => 'R',
);

my %other_perm = (
    Type  => 'Other',
    Right => 'None',
);

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path,
    Permissions => [ \%user_perm, \%group_perm, \%other_perm ],
), 'Set ACL to parent dir to be unreadable by others');

# 3. make child dir
my $path2 = "$path/unreadable";

$t->makedir(path => $path2);

# 4. setfacl to child dir
@user_perm{qw/ID Right/}  = qw/nfsnobody R/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm ],
    expected    => 'false',
), 'Failed to set ACL to child dir to be readable for nfsnobody user');

@group_perm{qw/ID Right/} = qw/nfsnobody R/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%group_perm ],
    expected    => 'false',
), 'Failed to set ACL to child dir to be readable for nfsnobody group');

@user_perm{qw/ID Right/}  = qw/nfsnobody W/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm ],
    expected    => 'false',
), 'Failed to set ACL to child dir to be writable for nfsnobody user');

@group_perm{qw/ID Right/} = qw/nfsnobody W/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%group_perm ],
    expected    => 'false',
), 'Failed to set ACL to child dir to be writable for nfsnobody group');

@user_perm{qw/ID Right/}  = qw/nfsnobody R/;
@group_perm{qw/ID Right/}  = qw/nfsnobody R/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm, \%group_perm ],
    expected    => 'false',
), 'Failed to set ACL to child dir to be readable by nfsnobody/nfsnobody');

@user_perm{qw/ID Right/}  = qw/nfsnobody W/;
@group_perm{qw/ID Right/}  = qw/nfsnobody R/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm, \%group_perm ],
    expected    => 'false',
), 'Failed to set ACL to child dir to be writable by nfsnobody and readable by nfsnobody');

@user_perm{qw/ID Right/}  = qw/nfsnobody W/;
@group_perm{qw/ID Right/}  = qw/nfsnobody W/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm, \%group_perm ],
    expected    => 'false',
), 'Failed to set ACL to child dir to be writable by nfsnobody/nfsnobody');

# 5. setfacl to parent dir to be readable
@user_perm{qw/ID Right/}  = qw/root W/;
@group_perm{qw/ID Right/} = qw/root R/;
$other_perm{Right} = 'R';

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path,
    Permissions => [ \%user_perm, \%group_perm, \%other_perm ],
), 'Set ACL to parent dir to be readable by others');

# 6. setfacl to child dir to be readable & writable
@user_perm{qw/ID Right/}  = qw/nfsnobody R/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm ],
), 'Set ACL to child dir to be readable by nfsnobody user');

@group_perm{qw/ID Right/} = qw/nfsnobody R/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%group_perm ],
), 'Set ACL to child dir to be readable by nfsnobody group');

@user_perm{qw/ID Right/}  = qw/nfsnobody W/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm ],
), 'Set ACL to child dir to be writable by nfsnobody user');

@group_perm{qw/ID Right/} = qw/nfsnobody W/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%group_perm ],
), 'Set ACL to child dir to be writable by nfsnobody group');

@user_perm{qw/ID Right/}  = qw/nfsnobody R/;
@group_perm{qw/ID Right/} = qw/nfsnobody R/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm, \%group_perm ],
), 'Set ACL to child dir to be readable by nfsnobody user/group');

@user_perm{qw/ID Right/}  = qw/nfsnobody W/;
@group_perm{qw/ID Right/} = qw/nfsnobody R/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm, \%group_perm ],
), 'Set ACL to child dir to be writable by nfsnobody user and readable by nfsnobody group');

@user_perm{qw/ID Right/}  = qw/nfsnobody W/;
@group_perm{qw/ID Right/} = qw/nfsnobody W/;

ok($t->setfacl(
    Type        => 'POSIX',
    Path        => $path2,
    Permissions => [ \%user_perm, \%group_perm ],
), 'Set ACL to child dir to be writable by nfsnobody user & group');

undef $t;
