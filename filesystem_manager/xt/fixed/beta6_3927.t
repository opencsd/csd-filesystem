#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'Geunyeong Bak';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN = "
    Initializer가 정상적으로 management interface를 자동 활성화하는지 검사함
";

use strict;
use warnings;
use utf8;

our $GMSROOT;
our $GSMROOT;

use Env;
use Cluster::ClusterGlobal;
use Test::Most;
use Test::AnyStor::Network;

#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Fixed-test(#3927) for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub {
    ok(1, 'Ready');
};


# 1. 노드 상태를 조회하여 Status가 OK인지 확인
printf("\nTest for initializer enabling mgmt interface will be performed...\n\n");

subtest 'Check mgmt interface enabled' => sub {
    my $t = Test::AnyStor::Network->new(addr => $ENV{GMS_TEST_ADDR});
    my $dbi = new Cluster::ClusterGlobal;
    my $ci = $dbi->get_conf('ClusterInfo');
    my $hostname = `hostname`;
    chomp $hostname;
    my $mgmt_addr = $ci->{node_infos}{$hostname}{mgmt_ip};

    my $addr_list = $t->network_address_list();

    my $find_flag = 0;
    foreach my $each_addr (@$addr_list)
    {
        if( $each_addr->{IPaddr} eq $mgmt_addr )
        {
            if( $each_addr->{Active} eq 'on' ){
                $find_flag = 1;
            }
            last;
        };
    }
    ok($find_flag, 'mgnt interface enabled check');
};

done_testing();
