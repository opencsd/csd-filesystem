package Test::Model::Network::DNS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use Sys::Hostname::FQDN qw/short/;

has 'hostname' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
);

sub test_setup
{
    my $self = shift;

    return $self->test_skip('This test will not performed');
}

sub test_with_no_data : Test(no_plan)
{
    my $self = shift;

    use_ok('Mock::Model::Volume::LVM::LV');

    my $lv = Mock::Model::Volume::LVM::LV->new(
        name => 'lv1',
        vg   => 'vg_cluster'
    );

    my $root = "/${\short}/LVM/LV";

    cmp_ok($lv->meta->etcd_root, 'eq', $root,
        "lv->meta->etcd_root eq '$root'");

    my @list = Mock::Model::Volume::LVM::LV->list();

    cmp_bag(\@list, ['vg_cluster/lv1'],
        "::list() returned with ('vg_cluster/lv1')");

    cmp_ok($lv->vg('tp_cluster'), 'eq', 'tp_cluster', "lv->vg('tp_cluster')");
    cmp_ok($lv->vg, 'eq', 'tp_cluster', "lv->vg eq 'tp_cluster'");

    @list = Mock::Model::Volume::LVM::LV->list();

    cmp_bag(\@list, ['tp_cluster/lv1'],
        "::list() returned with ('tp_cluster/lv1')");

    cmp_ok($lv->name('lv2'), 'eq', 'lv2', "lv->name('lv2')");
    cmp_ok($lv->name,        'eq', 'lv2', "lv->name() eq 'lv2'");

    @list = Mock::Model::Volume::LVM::LV->list();

    cmp_bag(\@list, ['tp_cluster/lv2'],
        "::list() returned with ('tp_cluster/lv2')");
}

sub test_list_with_init_data : Test(no_plan)
{
    my $self = shift;

    use_ok('Mock::Model::Volume::LVM::LV');

    $Mock::Model::Base::ETCD_DATA = {
        '/NODE-1/LVM/LV/vg_cluster/lv1/size_sec'        => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/lvnum'           => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/data_usage'      => 0.0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/status'          => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/ra_secs'         => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/allocated_le'    => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/current_le'      => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/alloc_policy'    => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/open'            => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/access'          => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/minor'           => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/major'           => 0,
        '/NODE-1/LVM/LV/vg_cluster/lv1/type'            => 'thick',
        '/NODE-1/LVM/LV/vg_cluster/lv1/meta_usage'      => 0.0,
        "/${\short}/LVM/LV/vg_cluster/lv1/size_sec"     => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/lvnum"        => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/data_usage"   => 0.0,
        "/${\short}/LVM/LV/vg_cluster/lv1/status"       => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/ra_secs"      => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/allocated_le" => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/current_le"   => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/alloc_policy" => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/open"         => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/access"       => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/minor"        => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/major"        => 0,
        "/${\short}/LVM/LV/vg_cluster/lv1/type"         => 'thick',
        "/${\short}/LVM/LV/vg_cluster/lv1/meta_usage"   => 0.0,
    };

    my @list = Mock::Model::Volume::LVM::LV->list();

    cmp_bag(\@list, ['vg_cluster/lv1'],
        "::list() returned with ('vg_cluster/lv1')");
}

1;

=encoding utf8

=head1 NAME

Test::Model::Network::DNS - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

