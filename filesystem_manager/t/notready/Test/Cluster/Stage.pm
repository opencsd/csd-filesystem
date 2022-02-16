#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::Most;

system('rm -rf /tmp/gms');

use_ok('GMS::Cluster::Etcd');
use_ok('GMS::Cluster::Stage');

my $etcd = GMS::Cluster::Etcd->new(
    local_mode_flag => '/tmp/gms/local_mode',
    local_db        => '/tmp/gms/local_db'
);

cmp_ok($etcd->enable_local_mode, '==', 0);

my $stager = GMS::Cluster::Stage->new(
    etcd       => $etcd,
    stage_path => '/tmp/gms/local_stage'
);

cmp_ok($stager->set_stage(scope => 'cluster', stage => 'running'),
    '==', 0,
    "->set_stage(scope => 'cluster', stage => 'running') returned with 0");

my $stage = $stager->get_stage(scope => 'cluster');

explain($stage);

cmp_ok($stager->set_stage(scope => 'node', stage => 'running'),
    '==', 0,
    "->set_stage(scope => 'node', stage => 'running') returned with 0");

$stage = $stager->get_stage(scope => 'node');

explain($stage);

# 1. Etcd mock-up
use_ok('Module::Load');

load('Mock::Model::Base');

# hash reference of dummy etcd data for testing
my $mock_data = Mock::Model::Base::mock_data();

cmp_ok($etcd->disable_local_mode(),
    '==', 0, "->disable_local_mode() returned with 0");

# 2. test for cluster/node stage
map {
    cmp_ok($stager->set_stage(scope => 'cluster', stage => $_),
        '==', 0,
        "->set_stage(scope => 'cluster', stage => '$_') returned with 0");

    $stage = $stager->get_stage(scope => 'cluster');

    cmp_ok($stage->{stage}, 'eq', $_, "cluster stage is '$_'");
} $stager->cluster_stages;

map {
    cmp_ok($stager->set_stage(scope => 'node', stage => $_),
        '==', 0,
        "->set_stage(scope => 'node', stage => '$_') returned with 0");

    $stage = $stager->get_stage(scope => 'node');

    cmp_ok($stage->{stage}, 'eq', $_, "node stage is '$_'");
} $stager->node_stages;

# 3. test for invalid stage
map {
    local $stage = $_;

    if (!grep { $stage eq $_ } $stager->comm_stages)
    {
        cmp_ok(
            $stager->set_stage(scope => 'cluster', stage => $stage),
            '==',
            -1,
            "->set_stage(scope => 'cluster', stage => '$stage') returned with -1"
        );

        cmp_ok(
            $stage, 'ne',
            $stager->get_stage(scope => 'cluster')->{stage},
            "cluster stage is not '$stage'"
        );
    }
} $stager->node_stages;

map {
    local $stage = $_;

    if (!grep { $stage eq $_ } $stager->comm_stages)
    {
        cmp_ok(
            $stager->set_stage(scope => 'node', stage => $stage),
            '==',
            -1,
            "->set_stage(scope => 'node', stage => '$stage') returned with -1"
        );

        cmp_ok(
            $stage, 'ne',
            $stager->get_stage(scope => 'node')->{stage},
            "node stage is not '$stage'"
        );
    }
} $stager->cluster_stages;

done_testing();
