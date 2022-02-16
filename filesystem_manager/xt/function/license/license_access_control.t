#!/usr/bin/perl -I/usr/gms/t/lib

our $AUTHORITY   = 'cpan:gluesys';
our $DESCRIPTOIN = 'Check access control functionality according to license';

use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Mojo;
use Test::Most;
use Test::AnyStor::License;
use Test::AnyStor::Network;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

$ENV{LICENSE_ISSUE_SERVER} = shift(@ARGV) if @ARGV;

my $LICENSE_ISSUE_SERVER = $ENV{LICENSE_ISSUE_SERVER};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

subtest "Initialize license list" => sub
{
    my $t = Test::AnyStor::License->new();

    ok($t->backup_license_list(), "Backup current license");

    ok($t->init_license_list(), "Initialize license");

    my $license_list = $t->system_license_list();

    diag("License list: ${\Dumper($license_list)}");
};

subtest "API filtering Test (Deny)" => sub
{
    my $t = Test::AnyStor::License->new();

    ok($t->system_license_test(return_false => 1), "The denied API test");
};

subtest "Register Test license" => sub
{
    my $t = Test::AnyStor::License->new();
    my $uniq_key = $t->system_license_uniq_key();

    ok(Test::AnyStor::License::is_uniq_key_valid($uniq_key)
        , "uniq_key($uniq_key) validation check");

    my $uniq_seed = $t->get_uniq_seed($uniq_key);

    ok(1, "seed of $uniq_key: $uniq_seed");

    my $license_key = $t->issue_license($uniq_seed, 'Test', $LICENSE_ISSUE_SERVER);

    ok(1, "license key for Test: $license_key");

    $t->system_license_register(license_key => $license_key);

    ok(lc($t->system_license_check(target => 'Test')) eq 'yes'
        , "Test license check");
};

subtest "API filtering Test (Allow)" => sub
{
    my $t = Test::AnyStor::License->new();

    ok($t->system_license_test(), "The allowed API test");
};

subtest "Make Demo license expired" => sub
{
    my $t = Test::AnyStor::License->new();

    ok($t->backup_demo_license(), "Backup demo license");

    ok($t->init_license_list(), "Initialize license");

    ok($t->make_demo_license_expired(), "Expire demo license");

    my $license_list = $t->system_license_list();

    diag("License list: ${\Dumper($license_list)}");
};

subtest "API filtering Test (expired demo license)" => sub
{
    my $t = Test::AnyStor::Network->new();

    ok($t->cluster_network_zone_list(return_false => 1)
        , "The denied API test");
};

subtest "Rollback license" => sub
{
    my $t = Test::AnyStor::License->new();

    ok($t->rollback_demo_license(), "Rollback demo license");

    ok($t->rollback_license_list(), "Rollback license list");

    ok($t->cluster_license_reload, "Reload license db in all cluster nodes");

    my $license_list = $t->system_license_list();

    diag("License list: ${\Dumper($license_list)}");
};

done_testing();
