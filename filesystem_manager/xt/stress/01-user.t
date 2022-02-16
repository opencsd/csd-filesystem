#!/usr/bin/perl

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:potatogim';

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/\/[^\/]+$//;

    unshift(@INC,
        (map { "$ROOTDIR/$_"; } qw/libgms lib/),
        '/usr/girasole/lib');
}

use Env;
use Data::Dumper;
use Test::Most;
use Common::OptArgs;
use Test::AnyStor::Account;

my %FLAG = (
    LIST   => 1,
    INFO   => 1,
    CREATE => 1,
    UPDATE => 1,
    DELETE => 1,
    ITER   => 1,
    COUNT  => 100,
);

if (@ARGV == 1 && $ARGV[0] !~ m/^(-h|--help)$/)
{
    $ENV{GMS_TEST_ADDR} = shift;
}

my $parser = Common::OptArgs->new(
    options => [
        {
            pinned   => 1,
            short    => 's',
            long     => 'server',
            desc     => 'GMS Server IP or Domain name',
            valdesc  => '<IP|DOMAIN>',
            callback => sub { $ENV{GMS_TEST_ADDR} = shift; },
        },
        {
            pinned   => 1,
            long     => 'iter',
            desc     => 'the number of test iteration',
            valdesc  => '<NUMBER>',
            callback => sub { $FLAG{ITER} = shift; },
        },
        {
            pinned   => 1,
            long     => 'count',
            desc     => 'the number of users using in a test',
            valdesc  => '<NUMBER>',
            callback => sub { $FLAG{COUNT} = shift; },
        },
        {
            pinned   => 1,
            long     => 'interval',
            desc     => 'loop test periodically with every some seconds',
            valdesc  => '<NUMBER>',
            callback => sub { $FLAG{INTERVAL} = shift; },
        },
        {
            pinned   => 1,
            long     => 'without-list',
            desc     => 'performs test without that for listing users',
            callback => sub { $FLAG{LIST} = 0; },
        },
        {
            pinned   => 1,
            long     => 'without-info',
            desc     => 'performs test without that for retrieving users',
            callback => sub { $FLAG{INFO} = 0; },
        },
        {
            pinned   => 1,
            long     => 'without-create',
            desc     => 'performs test without that for creating users',
            callback => sub { $FLAG{CREATE} = 0; },
        },
        {
            pinned   => 1,
            long     => 'without-update',
            desc     => 'performs test without that for updating users',
            callback => sub { $FLAG{UPDATE} = 0; },
        },
        {
            pinned   => 1,
            long     => 'without-delete',
            desc     => 'performs test without that for deleting users',
            callback => sub { $FLAG{DELETE} = 0; },
        },
    ],
    use_cmd   => 0,
    help_cmd  => 0,
    help_sopt => 1,
    help_lopt => 1,
);

$parser->parse(args => \@ARGV);

if (!defined($ENV{GMS_TEST_ADDR}))
{
    diag("Environment variable 'GMS_TEST_ADDR' is not specified!");
    goto OUT;
}

# 검사 준비
my $count = 0;

diag(sprintf("Preparing $0 test for %s...\n\n", $ENV{GMS_TEST_ADDR}));

while ($count++ < $FLAG{ITER})
{
    diag("Iteration: $count\n\n");

    diag("\nTest for basic user management will be performed...\n\n");

    my @users;

    # 사용자 나열
    if ($FLAG{LIST})
    {
        subtest 'ListUser' => sub
        {
            my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});

            @users = $t->user_list(location => 'LOCAL');

            return 0;
        };
    }

    # 사용자 추가
    if ($FLAG{CREATE})
    {
        subtest 'CreateUser' => sub
        {
            my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});

            @users = $t->user_create(
                prefix => 'testuser',
                number => $FLAG{COUNT}
            );

            return 0;
        };
    }

    # 사용자 수정
    if ($FLAG{UPDATE})
    {
        subtest 'UpdateUser' => sub
        {
            my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});

            foreach my $user (@users)
            {
                $t->user_update(name => $user);
            }

            return 0;
        };
    }

    # 사용자 삭제
    if ($FLAG{DELETE})
    {
        subtest 'DeleteUser' => sub
        {
            my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});

            $t->user_delete(names => \@users);

            return 0;
        }
    }

    my $start = time;

    while ($FLAG{INTERVAL})
    {
        last if (time - $start >= $FLAG{INTERVAL});
        sleep(1);
    }
}

OUT:
done_testing();
