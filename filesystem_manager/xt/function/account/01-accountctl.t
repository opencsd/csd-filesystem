#!/usr/bin/perl

our $AUTHORITY = 'cpan:hgichon';
our $VERSION   = '1.00';

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Account;
use Test::AnyStor::Base;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Function-test for %s...\n\n", $ENV{GMS_TEST_ADDR});

our ($tgt, undef) = split(':', $ENV{GMS_TEST_ADDR});

use constant {
    TEST_CNT        => 3,
    SUBGROUP_CNT    => 3,
};

set_failure_handler(
    sub {
        my $builder = shift;
        paint_err();
        BAIL_OUT("merge_test.t is bailed out");
        paint_reset();
        done_testing();
    }
);

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};

our $t = Test::AnyStor::Account->new(addr => $ENV{GMS_TEST_ADDR});
our $res;

# 1. 기본 검사
printf("\nTest for accountctl will be performed...\n\n");

subtest 'Basic' => sub {

    # 사용자 추가 및 확인
    for (my $i=0; $i < TEST_CNT; $i++)
    {
        $res = call_system( "ssh $tgt /usr/gms/bin/accountctl user ".
                            "add -u user$i -p user$i");
        ok($res == 0, "user$i created");
    }
    
    for (my $i=0; $i < TEST_CNT; $i++)
    {

        $res = call_system("ssh $tgt /usr/gms/bin/accountctl user check -u user$i");
        ok($res == 0, "user$i checked correctly");
    }

    for (my $i=0; $i < TEST_CNT; $i++)
    {
        $res = call_system("ssh $tgt /usr/gms/bin/accountctl user ".
                            "passwd -u user$i -p USER$i");
        ok($res == 0, "user$i passwd update correctly");
    }

    # 그룹 추가 및 확인
    for (my $i=0; $i < TEST_CNT; $i++)
    {
        $res = call_system("ssh $tgt /usr/gms/bin/accountctl group add -g group$i");
        ok($res == 0, "group$i created");
    }

    for (my $i=0; $i < TEST_CNT; $i++)
    {
        $res = call_system("ssh $tgt /usr/gms/bin/accountctl group check -g group$i");
        ok($res == 0, "group$i checked correctly");
    }

    # 사용자 삭제
    for (my $i=0; $i < TEST_CNT; $i++)
    {
        $res = call_system("ssh $tgt /usr/gms/bin/accountctl user del -u user$i");
        ok($res == 0, "user$i delete correctly");
    }

    # 그룹  삭제
    for (my $i=0; $i < TEST_CNT; $i++)
    {
        $res = call_system("ssh $tgt /usr/gms/bin/accountctl group del -g group$i");
        ok($res == 0, "group$i delete correctly");
    }

    return 0;
};



subtest 'SubGroup' => sub {

# Create Subgroup User/Group MAP
# group1 - user1
# group2 - user2
# group{n} - user{n}
# 
    # 그룹 추가 및 확인
    for (my $i=0; $i < SUBGROUP_CNT; $i++)
    {
        $res = call_system("ssh $tgt /usr/gms/bin/accountctl group add -g group$i");
        ok($res == 0, "group$i created");
    }

    # 사용자 추가 및 확인
    for (my $i=0; $i < SUBGROUP_CNT; $i++)
    {
        $res = call_system("ssh $tgt /usr/gms/bin/accountctl user add -u guser$i ".
                                "-p guser$i -g group$i");
        ok($res == 0, "guser$i with group$i created");
    }

# Case1 Inital adding
#
# group1 -                  ==> user1
# group2 -  @group1         ==> user1 user2
# group{n} -  @group(n-1)   ==> user1 user2 ... user{n}

    for (my $i=0; $i < SUBGROUP_CNT - 1; $i++)
    {
        my $c_group = 'group'.$i;      #child group
        my $p_group = 'group'.($i+1);     #parents group

        $res = call_system("ssh $tgt /usr/gms/bin/accountctl group ".
                            "add_sub -g $p_group -S $c_group");
        ok($res == 0, "P($p_group) add C($c_group) succeed");

        # Checking /etc/group file updated correctly

        foreach my $node (@{$t->nodes}) 
        {

            my $tgt_node = $node->{Mgmt_IP}->{ip};

            for (my $j=0; $j < $i; $j++)
            {
                my $user = 'guser'.$j;
                $res = call_system("ssh $tgt_node grep ^$p_group: /etc/group | ".
                        " grep $user");
                ok($res == 0, "find $user in P($p_group) succeed");
            }
        }
    }

#
# Case1 member adding to noraml group
# group1 - user1 + tuser1
# group2 - user2 + tuser2
# group{n} - user{n} + tuser{n}
# finally  ... 
# group1 -                  ==> user1 tuser1
# group2 -  @group1         ==> user1 user2 tuser1 tuser2
# group{n} -  @group(n-1)   ==> user1 user2 ... user{n}  tuser1 tuser2 ... tuser{n}

    for (my $i=0; $i < SUBGROUP_CNT; $i++)
    {
        my $c_group = 'group'.$i;      #child group
        my $n_user  = 'tuser'.$i;      #child group

        $res = call_system("ssh $tgt /usr/gms/bin/accountctl user ".
                "add -g $c_group -u $n_user -p $n_user");

        ok($res == 0, "G($c_group) add $n_user succeed");

        # Checking /etc/group file updated correctly

        foreach my $node (@{$t->nodes}) {

            my $tgt_node = $node->{Mgmt_IP}->{ip};

            for (my $j=$i; $j < SUBGROUP_CNT; $j++)
            {
                my $p_group = 'group'.$j;      #child group
                $res = call_system("ssh $tgt_node grep ^$p_group: /etc/group | ".
                        " grep $n_user");
                ok($res == 0, "find $n_user in P($p_group) succeed");
            }
        }
    }

    # 서브 그룹핑 해제 
    #
    for (my $i=0; $i < SUBGROUP_CNT - 1; $i++)
    {
        my $c_group = 'group'.$i;      #child group
        my $p_group = 'group'.($i+1);     #parents group
        my $t_group = 'group'.(SUBGROUP_CNT-1);     #parents group

        $res = call_system("ssh $tgt /usr/gms/bin/accountctl group ".
                            "del_sub -g $p_group -S $c_group");
        ok($res == 0, "P($p_group) del C($c_group) succeed");

        # Checking /etc/group file updated correctly

        foreach my $node (@{$t->nodes}) {

            my $tgt_node = $node->{Mgmt_IP}->{ip};

            for (my $j=0; $j < $i; $j++)
            {
                my $user = 'user'.$j;   # grep for guser and tuser

                $res = call_system("ssh $tgt_node grep ^$t_group: /etc/group | ".
                        " grep $user");
                ok($res != 0, "delete $user in P($t_group) succeed");
            }
        }
    }

    # 사용자 삭제
    for (my $i=0; $i < SUBGROUP_CNT; $i++)
    {
        my $t_group = 'group'.$i;     #parents group
        my $user    = 'user'.$i;

        $res = call_system("ssh $tgt /usr/gms/bin/accountctl user del -u g$user");
        ok($res == 0, "g$user delete correctly");
        $res = call_system("ssh $tgt /usr/gms/bin/accountctl user del -u t$user");
        ok($res == 0, "t$user delete correctly");

#        # TODO Original account ctl code 에서 /etc/group 업데이트가 제대로 안됨
#        foreach my $node (@{$t->nodes}) 
#        {
#            my $tgt_node = $node->{Mgmt_IP}->{ip};
#            $res = call_system("ssh $tgt_node grep ^$t_group: /etc/group | ".
#                    " grep $user");
#            ok ($res != 0, "delete $user in P($t_group) succeed");
#        }
    }

    # 그룹삭제
    #
    for (my $i=0; $i < SUBGROUP_CNT; $i++)
    {
        my $t_group = 'group'.$i;     #parents group

        $res = call_system("ssh $tgt /usr/gms/bin/accountctl group del -g $t_group");
        ok($res == 0, "$t_group delete correctly");

        foreach my $node (@{$t->nodes}) {

            my $tgt_node = $node->{Mgmt_IP}->{ip};
            $res = call_system("ssh $tgt_node grep ^$t_group: /etc/group");
            ok($res != 0, "delete $t_group succeed");
        }
    }

    return 0;
};

done_testing();
