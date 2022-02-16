#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::Most;
use Sys::Hostname::FQDN qw/short/;

use_ok('GMS::Cluster::Etcd');

my $etcd = GMS::Cluster::Etcd->new(
    local_mode_flag => '/tmp/gms/local_mode',
    local_db        => '/tmp/gms/local_db'
);

cmp_ok($etcd->enable_local_mode, '==', 0);

cmp_ok(
    $etcd->set_key_to_local(
        db         => 'Potato',
        key        => 'potato',
        value      => 'sweetpotato',
        skip_stage => 1
    ),
    '==',
    0
);

cmp_ok(
    $etcd->get_key_from_local(
        db         => 'Potato',
        key        => 'potato',
        skip_stage => 1
    ),
    'eq',
    'sweetpotato'
);

cmp_ok(
    $etcd->del_key_from_local(
        db         => 'Potato',
        key        => 'potato',
        skip_stage => 1
    ),
    '==',
    0
);

ok(
    !defined($etcd->get_key_from_local(
        db         => 'Potato',
        key        => 'potato',
        skip_stage => 1
    ))
);

# 1. Etcd mock-up
use_ok('Module::Load');

load('Mock::Model::Base');

# hash reference of dummy etcd data for testing
cmp_ok($etcd->disable_local_mode(),
    '==', 0, "->disable_local_mode() returned with 0");

explain(Mock::Model::Base::mock_data());

my $stage = {
    cluster => {
        stage => 'running',
        data  => {},
        msg   => 'Running',
    },
    nodes => {
        short() => {
            stage => 'running',
            data  => {},
        }
    }
};

cmp_ok($etcd->set_conf(key => '/Stage', value => $stage),
    '==', 0, "->set_conf(key => '/Stage', value => {...}) returned with 0");

explain(Mock::Model::Base::mock_data());

my $data = $etcd->get_conf(key => '/Stage');

isa_ok($data, 'HASH', "->get_conf(key => '/Stage') is returned with HASHREF");

explain($data);

cmp_deeply($stage, $data);

cmp_ok($etcd->set_key(key => '/Test/1', value => 'test'),
    '==', 0, "->set_key(key => '/Test/1', value => 'test') returned with 0");

explain(Mock::Model::Base::mock_data());

cmp_ok($etcd->get_key(key => '/Test/1'),
    'eq', 'test', "->get_key(key => '/Test/1') returned with 'test'");

explain(Mock::Model::Base::mock_data());

done_testing();
