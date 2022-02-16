#!/usr/bin/perl

our $AUTHORITY = 'cpan:potatogim';
our $VERSION   = '1.00';

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Account;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Function-test for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};

# 1. 기본 검사
printf("\nTest for basic account management will be performed...\n\n");

subtest 'Basic' => sub {
    my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});

    # 그룹 추가
    my @groups = $t->group_create(prefix => 'testgroup', number => 3);

    # 사용자 추가
    my @users = $t->user_create(prefix => 'testuser', number => 10);

    # 그룹 수정
    foreach my $group (@groups)
    {
        ok($t->group_update(name => $group) == 0, "update group $group");
    }

    # 사용자 수정
    foreach my $user (@users)
    {
        ok($t->user_update(name => $user) == 0, "update user $user");
    }

    # 사용자 그룹 참여/탈퇴
    for (my $i=0, my $cut=int(scalar(@users)/scalar(@groups))
        ; $i < @groups
        ; $i++)
    {
        $t->join(
            group   => $groups[$i],
            members => [grep { defined($_); } @users[$i*$cut .. (($i+1)*$cut)-1]],
        );

        $t->leave(
            group   => $groups[$i],
            members => [grep { defined($_); } @users[$i*$cut .. (($i+1)*$cut)-1]],
        );
    }

    # 사용자 삭제
    foreach my $user (@users)
    {
        ok($t->user_delete(names => $user) == 0, "delete user $user");
    }

    # 그룹 삭제
    foreach my $group (@groups)
    {
        ok($t->group_delete(names => $group) == 0, "delete group $group");
    }

    return 0;
};

# 2. 계정 정책 검사
printf("\nTest for account policy will be performed...\n\n");

subtest 'Policy' => sub {
#    my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});
    ok(1, "There is no test yet!");

    return 0;
};

# 3. 제한 검사
printf("\nTest for account limitation will be performed...\n\n");

subtest 'Limitation' => sub {
#    my $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});
    ok(1, "There is no test yet!");

    return 0;
};

done_testing();
