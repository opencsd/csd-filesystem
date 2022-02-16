#!/usr/bin/perl -I/usr/gms/t/lib
our $AUTHORITY = 'bakeun';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'Check access control functionality according to license';
use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Mojo;
use Test::Most;
use Test::AnyStor::License;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

$ENV{LICENSE_ISSUE_SERVER} = shift(@ARGV) if @ARGV;
my $LICENSE_ISSUE_SERVER = $ENV{LICENSE_ISSUE_SERVER};

if ( !defined $GMS_TEST_ADDR ) {
    fail('Argument is missing');
    return 0;
}

subtest "Make 'Demo' environment" => sub {
    my $t = Test::AnyStor::License->new();

    ok(
      $t->backup_license_list(),
      "Backup current license"
    );

    ok(
      $t->init_license_list(),
      "Initialize license"
    );

    my $license_list = $t->system_license_list();
    ok(1, "license list: ".Dumper $license_list);
};

subtest "Demo license Check Test" => sub {
    my $t = Test::AnyStor::License->new();
    ok( lc($t->system_license_check(target => 'Demo')) eq 'yes', "Demo license check" );
};

subtest "Check Demo notifying task" => sub {
    my $t = Test::AnyStor::License->new();

    ok( $t->trigger_license_noty_girasole_plugin(), "Trigger License_Noty girasole plugin" );

    my @demo_tasks = grep { $_->{Code} =~ /DEMO_LICENSE/ } @{$t->get_tasks()};

    ok( scalar(@demo_tasks), "Demo license notify task check" );
    ok( 1, "demo notify_task: ".Dumper $demo_tasks[0] ) if (scalar(@demo_tasks));
};

subtest "Make Demo license expired" => sub {
    my $t = Test::AnyStor::License->new();

    ok(
      $t->backup_demo_license(),
      "Backup demo license"
    );

    ok(
      $t->make_demo_license_expired(),
      "Expire demo license"
    );

    my $license_list = $t->system_license_list();
    ok(1, "license list: ".Dumper $license_list);
};

subtest "Check Demo expired task" => sub {
    my $t = Test::AnyStor::License->new();

    ok( $t->trigger_license_noty_girasole_plugin(), "Trigger License_Noty girasole plugin" );

    my @demo_tasks = grep { $_->{Code} =~ /DEMO_LICENSE_EXPIRED/ } @{$t->get_tasks()};

    ok( scalar(@demo_tasks), "Demo license expired task check" );
    ok( 1, "demo expired_task: ".Dumper $demo_tasks[0] ) if (scalar(@demo_tasks));
};

subtest "Rollback license" => sub {
    my $t = Test::AnyStor::License->new();

    ok(
      $t->rollback_demo_license(),
      "Rollback demo license"
    );

    ok(
      $t->rollback_license_list(),
      "Rollback license list"
    );

    my $license_list = $t->system_license_list();
    ok(1, "license list: ".Dumper $license_list);
};

done_testing();

