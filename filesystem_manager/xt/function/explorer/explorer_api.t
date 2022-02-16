#!/usr/bin/perl -I /usr/gms/t/lib/

our $AUTHORITY = 'Geunyeong Bak';
our $VERSION   = '1.00';

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Most;

use Test::AnyStor::Account;
use Test::AnyStor::Explorer;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
$ENV{GMS_CLIENT_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};
my $GMS_CLIENT_ADDR = $ENV{GMS_CLIENT_ADDR};

my $TGT_DIR = 'target';

my $SUB_DIR  = '/test/explorer_api_test';
my $TEST_DIR = "$SUB_DIR/$TGT_DIR";

my $CLST_SUB_DIR  = "/cluster$SUB_DIR";
my $CLST_TEST_DIR = "$CLST_SUB_DIR/$TGT_DIR";

my $TEST_USER  = 'test_user';
my $TEST_GROUP = 'test_group';
my $TEST_PERM  = 'rwxr-xr--';

my $verbose = 1;

if( (! defined $GMS_TEST_ADDR) && (! defined $GMS_CLIENT_ADDR) )
{
    ok(0, 'argument missing');
    exit 1;
}

subtest 'create_test_account' => sub 
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR);

    $t->user_create(  prefix =>  $TEST_USER );
    $t->group_create( prefix => $TEST_GROUP );

    $TEST_USER  .= '-1';
    $TEST_GROUP .= '-1';
};

subtest 'make test_directory' => sub
{
    my $t = Test::AnyStor::Explorer->new(addr => $GMS_TEST_ADDR);
    $t->explorer_makedir(path => $TEST_DIR, recursive => 1);

    my $check_res = $t->explorer_checkdir(path => $TEST_DIR);
    diag( "directory check result: ".Dumper $check_res);

    my $dir_list = $t->explorer_list(path => $SUB_DIR);
    diag( "files in $SUB_DIR: ".Dumper $dir_list);

    diag("Check if makedir success");
    my $is_test_dir_made = (
             ($check_res->{directory} eq 'on' && $check_res->{exist} eq 'on')
          && (grep { $_->{FullPath} eq $TEST_DIR } @$dir_list)
         )
    ;

    ok( $is_test_dir_made, "'$TEST_DIR' creation check" );
};

subtest 'make change owner' => sub
{
    my $t = Test::AnyStor::Explorer->new(addr => $GMS_TEST_ADDR);

    $t->explorer_changeperm(
            path => $TEST_DIR,
            perm => $TEST_PERM,
        )
    ;

    $t->explorer_changeown(
            path  =>   $TEST_DIR,
            user  =>  $TEST_USER,
            group => $TEST_GROUP,
        )
    ;

    my $dir_info = $t->explorer_info(path => $TEST_DIR);
    diag( "$TEST_DIR info: ".Dumper $dir_info);

    diag("Check if chperm success");
    my $check_if_chperm_success = ($dir_info->{PermissionRWX} eq $TEST_PERM);
    ok($check_if_chperm_success, 'Permission change functionality check');

    diag("Check if chown success");
    my $check_if_chown_success   = ($dir_info->{Owner} eq $TEST_USER);
       $check_if_chown_success &&= ($dir_info->{OwnerGroup} eq $TEST_GROUP);
    ok($check_if_chperm_success, 'Owner change functionality check');

};

subtest 'make test_directory (cluster)' => sub
{
    my $t = Test::AnyStor::Explorer->new(addr => $GMS_TEST_ADDR);

    $t->cluster_explorer_makedir(path => $CLST_TEST_DIR, recursive => 1);

    my $check_res = $t->cluster_explorer_checkdir(path => $CLST_TEST_DIR);
    diag("directory check result: ".Dumper $check_res);

    my $dir_list = $t->cluster_explorer_list(path => $CLST_SUB_DIR);
    diag("files in $CLST_SUB_DIR: ".Dumper $dir_list);


    diag("Check if makedir success");
    my $is_test_dir_made = 1;
    for my $each_node (@{$t->{nodes}})
    {
        my $each_host = $each_node->{Storage_Hostname};

        my $is_each_test_dir_made = (
                 (   $check_res->{$each_host}{ directory } eq 'on'
                  && $check_res->{$each_host}{ exist     } eq 'on')
              && ( grep { $_->{FullPath} eq $CLST_TEST_DIR }
                        @{ $dir_list->{$each_host} } )
            )
        ;
        ok( $is_each_test_dir_made, "'$CLST_TEST_DIR' creation check in $each_host" );

        $is_test_dir_made &&= $is_each_test_dir_made;
    }

    ok( $is_test_dir_made, "'$CLST_TEST_DIR' creation check in all nodes" );
};

subtest 'change owner test (cluster)' => sub
{
    my $t = Test::AnyStor::Explorer->new(addr => $GMS_TEST_ADDR);

    $t->cluster_explorer_changeperm(
            path => $CLST_TEST_DIR,
            perm =>     $TEST_PERM,
        )
    ;

    $t->cluster_explorer_changeown(
            path  => $CLST_TEST_DIR,
            user  =>     $TEST_USER,
            group =>    $TEST_GROUP,
        )
    ;

    my $dir_info = $t->cluster_explorer_info(path => $CLST_TEST_DIR);
    diag( "$CLST_TEST_DIR info: ".Dumper $dir_info);


    diag("Check if chperm success");
    my $check_if_chperm_success = 1;

    for my $each_node (@{$t->{nodes}})
    {
        my $each_host = $each_node->{Storage_Hostname};

        my $check_if_each_chperm_success
          = ($dir_info->{$each_host}{PermissionRWX} eq $TEST_PERM);

        ok($check_if_each_chperm_success,
           'Permission change functionality check in '.$each_host);

        $check_if_chperm_success &&= $check_if_each_chperm_success;
    }

    ok($check_if_chperm_success, 'Permission change functionality check in all nodes');


    diag("Check if chown success");
    my $check_if_chown_success = 1;

    for my $each_node (@{$t->{nodes}})
    {
        my $each_host = $each_node->{Storage_Hostname};

        my $check_if_each_chown_success
            = ($dir_info->{$each_host}{Owner} eq $TEST_USER);

        $check_if_each_chown_success
          &&= ($dir_info->{$each_host}{OwnerGroup} eq $TEST_GROUP);

        ok($check_if_each_chown_success,
           'Owner change functionality check in '.$each_host);

        $check_if_chown_success &&= $check_if_each_chown_success;
    }

    ok($check_if_chown_success, 'Owner change functionality check in all nodes');

};

subtest 'delete_test_account' => sub 
{
    my $t = Test::AnyStor::Account->new(addr => $GMS_TEST_ADDR);
    $t->user_delete( names => 'test_user-1' );
    $t->user_delete( names => 'group_user-1' );
    $t->group_delete( names => 'test_group-1' );
};

done_testing();

exit 0;
