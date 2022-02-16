#!/usr/bin/perl -I/usr/gms/t/lib
our $AUTHORITY = 'bakeun';
our $VERSION   = '1.00';
our $TEST_DESCRIPTOIN
    = 'Check license basic functionality';
use strict;
use warnings;
use utf8;

use Env;
use Data::Dumper;
use Test::Mojo;
use Test::Most;
use Test::AnyStor::License;

use Common::ArgCheck qw( check_arguments is_argument_type );

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

$ENV{LICENSE_ISSUE_SERVER} = shift(@ARGV) if @ARGV;
my $LICENSE_ISSUE_SERVER = $ENV{LICENSE_ISSUE_SERVER};

if ( !defined $GMS_TEST_ADDR ) {
    fail('Argument is missing');
    return 0;
}

subtest "Backup current license list" => sub {
    my $t = Test::AnyStor::License->new();

    ok(
      $t->backup_license_list(),
      "Backup current license"
    );
};

subtest "Test license API" => sub {
    my $t = Test::AnyStor::License->new();

    my $uniq_key = $t->system_license_uniq_key();
    ok(
      Test::AnyStor::License::is_uniq_key_valid( $uniq_key ),
      "uniq_key($uniq_key) validation check"
    );

    my $uniq_seed = $t->get_uniq_seed($uniq_key);
    ok(1, "seed of $uniq_key: $uniq_seed");

    my $license_key = $t->issue_license($uniq_seed, 'Test', $LICENSE_ISSUE_SERVER);
    ok(1, "license key for Test: $license_key");

    $t->system_license_register(license_key => $license_key);
    ok( lc($t->system_license_check(target => 'Test')) eq 'yes', "'Test' license register check");

    my $license_list = $t->system_license_list();
    my $item_must_be = {
        Name       => "not_empty_string",
        Activation => "string",
        Expiration => "string",
        Licensed   => "not_empty_string",
        Status     => "not_empty_string",
        RegDate    => "not_empty_string"
    };

    foreach (@$license_list){
        my @invalid_items = ( check_arguments($item_must_be, $_) );
        ok( ! scalar(@invalid_items), "items of the '$_->{Name}' validation check" );
        ok(0, "invalid_items: ".join(',', @invalid_items)) if ( scalar(@invalid_items) );
    }

    ok(1, "license list: ".Dumper $license_list);

    my $license_summary = $t->system_license_summary();

    foreach (keys %$license_summary){
        ok (
          is_argument_type('string', $license_summary->{$_}),
          "'$_' items of summary validation check"
        );
    }

    ok(1, "license summary: ".Dumper $license_summary);
};

subtest "Initialize license list" => sub {
    my $t = Test::AnyStor::License->new();
    ok(
      $t->init_license_list(),
      "Initialize license"
    );
};

subtest "Demo license Check Test" => sub {
    my $t = Test::AnyStor::License->new();

    ok( lc($t->system_license_check(target => 'Demo')) eq 'yes', "'Demo' license check" );

    my $license_list = $t->system_license_list();
    my $demo_value_must_be = {
        Name       => 'Demo',
        Activation => '^\d{4}\/\d{2}\/\d{2}$',
        Expiration => '^\d{4}\/\d{2}\/\d{2}$',
        Licensed   => 'Active',
        Status     => 'Active',
        RegDate    => '^\d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}$',
    };
    ok(1, "License list validation when 'Demo' license activated");

    foreach (@$license_list) {

        if ( $_->{Name} ne 'Demo' ) {
            ok(0, "There are other license (not 'Demo')");
            last;
        }

        foreach my $demo_key ( keys %$demo_value_must_be ) {
            ok(
              $_->{$demo_key} =~ /$demo_value_must_be->{$demo_key}/,
              "value validation ('$demo_key'): $_->{$demo_key}"
            );
        }
    }

    my $license_summary = $t->system_license_summary();
    my $summary_value_must_be = {
        'ADS' => 'yes',
        'VolumeSize' => 'Unlimited',
        'Node' => 'Unlimited',
        'Demo' => 'yes',
        'Test' => 'no',
        'Support' => 'no',
        'CIFS' => 'yes',
        'NFS' => 'yes',
        'ISCSI' => 'yes'
    };
    ok(1, "License summary validation when 'Demo' license activated");

    foreach (keys %$license_summary){
        ok(
          $license_summary->{$_} =~ /$summary_value_must_be->{$_}/,
          "value validation ('$_'): $license_summary->{$_}"
        );
    }
};

subtest "Rollback license list" => sub {
    my $t = Test::AnyStor::License->new();

    ok(
      $t->rollback_license_list(),
      "Rollback current license"
    );
};

subtest "Reload license list" => sub {
    my $t = Test::AnyStor::License->new();

    ok(
      $t->cluster_license_reload,
      "Reload license db in all cluster nodes"
    );
};

done_testing();
