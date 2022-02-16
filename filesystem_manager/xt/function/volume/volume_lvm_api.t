#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'LVM::LV test code';

use strict;
use warnings;
use utf8;

BEGIN {
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC, "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib");
}

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Volume;
use Test::AnyStor::Filesystem;

use Volume::LVM::LV;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

my $TEST_THINPOOL = 'mypool';
my $VG_NAME       = undef;

subtest 'Thin Pool LV create' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $node;
    my $target_addr = substr($GMS_TEST_ADDR, 0, index($GMS_TEST_ADDR, ':'));

    foreach my $n (@{$t->nodes})
    {
        if ($n->{Mgmt_IP}->{ip} eq $target_addr))
        {
            $node = $n;
            last;
        }
    }

    if (!ok($node, "LVM Volume API test starts with $node->{Mgmt_Hostname}"))
    {
        goto SKIP;
    }

    my ($node_idx, undef) = $node->{Mgmt_Hostname} =~ m/-(\d+)(|-m)$/;

    $VG_NAME = sprintf('%s%d', 'vg_cluster', $node_idx);

    ok($t->lvcreate(
        type     => Volume::LVM::LV::THIN_POOL_LV,
        memberof => $VG_NAME,
        name     => $TEST_THINPOOL,
        size     => '15GiB',
    ), "LV is created: $VG_NAME/$TEST_THINPOOL");
};

subtest 'Thin Pool LV format' => sub
{
    my $t = Test::AnyStor::Filesystem->new(addr => $GMS_TEST_ADDR);

    ok($t->format(
        vgname    => $VG_NAME,
        lvname    => $TEST_THINPOOL,
        fail_test => 1
    ), "Failed to format thin LV: $VG_NAME/$TEST_THINPOOL");
};

subtest 'Thin Pool LV mount' => sub
{
    my $t = Test::AnyStor::Filesystem->new(addr => $GMS_TEST_ADDR);

    ok($t->mount(
        vgname    => $VG_NAME,
        lvname    => $TEST_THINPOOL,
        fail_test => 1
    ), "Failed to mount thin LV: $VG_NAME/$TEST_THINPOOL");
};

subtest 'Thick LV create & delete' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    $t->lvcreate(memberof => $VG_NAME);
    $t->lvdelete(vg => $VG_NAME);
};

subtest 'Thin LV create & delete' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    $t->lvcreate(
        type     => Volume::LVM::LV::THIN_LV,
        name     => 'Thin_LV',
        memberof => $VG_NAME,
        size     => '1GiB',
        options  => ['--thinpool', $TEST_THINPOOL],
    );

    $t->lvdelete(name => ['Thin_LV'], vg => $VG_NAME);

    for my $i (0 .. 10)
    {
        $t->lvcreate(
            type     => Volume::LVM::LV::THIN_LV,
            name     => "Thin_LV_$i",
            memberof => $VG_NAME,
            size     => '1GiB',
            options  => ['--thinpool', $TEST_THINPOOL],
        );
    }
};

subtest 'Thin Pool LV delete' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    $t->lvdelete(name => [$TEST_THINPOOL], vg => $VG_NAME);
};

my $LVS = undef;

subtest 'Get LV to test OS LV' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    $LVS = $t->lvlist();

    if (!isa_ok($LVS, 'ARRAY'))
    {
        fail('LV list is not ARRAY');
        return 0;
    }

    my @preserved_lvs = grep { uc($_->{LV_Purpose}) eq 'OS' } @{$LVS};

    diag("LVs(preserved): ${\Dumper(\@preserved_lvs)}");

    return 1;
};

subtest 'OS LV format' => sub
{
    if (!isa_ok($LVS, 'ARRAY'))
    {
        fail('LV list is not ARRAY');
        return 0;
    }

    my @preserved_lvs = grep { uc($_->{LV_Purpose}) eq 'OS' } @{$LVS};

    if (@preserved_lvs)
    {
        diag('Preserved LVs do not exists. will be skipped');
        return 1;
    }

    my $t = Test::AnyStor::Filesystem->new(addr => $GMS_TEST_ADDR);

    foreach my $lv (@preserved_lvs)
    {
        isa_ok($preserved_lvs[0], 'HASH');

        if (!ok(defined($preserved_lvs[0]{LV_Name}), 'LV_Name is defined'))
        {
            next;
        }

        if (!ok(defined($preserved_lvs[0]{LV_MemberOf}), 'LV_MemberOf is defined'))
        {
            next;
        }

        ok($t->mount(
            vgname    => $preserved_lvs[0]{LV_Name},
            lvname    => $preserved_lvs[0]{LV_MemberOf},
            fail_test => 1,
        ), sprintf('Failed to mount LV: %s/%s'
                    , $preserved_lvs[0]{LV_Name}
                    , $preserved_lvs[0]{LV_MemberOf}));
    }

    return 1;
};

subtest 'OS LV mount' => sub
{
    if (!isa_ok($LVS, 'ARRAY'))
    {
        fail('LV list is not ARRAY');
        return 0;
    }

    my @preserved_lvs = grep { uc($_->{LV_Purpose}) eq 'OS' } @{$LVS};

    if (@preserved_lvs)
    {
        diag('Preserved LVs do not exists. will be skipped');
        return 1;
    }

    my $t = Test::AnyStor::Filesystem->new(addr => $GMS_TEST_ADDR);

    foreach my $lv (@preserved_lvs)
    {
        isa_ok($preserved_lvs[0], 'HASH');

        if (!ok(defined($preserved_lvs[0]{LV_Name}), 'LV_Name is defined'))
        {
            next;
        }

        if (!ok(defined($preserved_lvs[0]{LV_MemberOf}), 'LV_MemberOf is defined'))
        {
            next;
        }

        $t->mount(
            vgname    => $preserved_lvs[0]{LV_Name},
            lvname    => $preserved_lvs[0]{LV_MemberOf},
            fail_test => 1,
        );
    }

    return 1;
};

subtest 'pvcreate /dev/sdc' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $list = $t->pvlist();

    diag("PVs(before): ${\Dumper($list)}");

    $t->pvcreate(device => '/dev/sdc');

    $list = $t->pvlist();

    diag("PVs(after): ${\Dumper($list)}");
};

subtest 'vgcreate vg_test with /dev/sdc' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $list = $t->vglist();

    diag("VGs: ${\Dumper($list)}");

    $t->vgcreate(name => 'vg_test', pvs => '/dev/sdc');

    $list = $t->vglist();

    diag("VGs: ${\Dumper($list)}");
};

subtest 'pvcreate /dev/sdd' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $list = $t->pvlist();

    diag("PVs(before): ${\Dumper($list)}");

    $t->pvcreate(device => '/dev/sdd');

    $list = $t->pvlist();

    diag("PVs(after): ${\Dumper($list)}");
};

subtest 'vgextend vg_test with /dev/sdd' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $list = $t->vglist();

    diag("VGs(before): ${\Dumper($list)}");

    $t->vgextend(name => 'vg_test', pvs => '/dev/sdd');

    $list = $t->vglist();

    diag("VGs(after): ${\Dumper($list)}");
};

subtest 'lvcreate on vg_test' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $list = $t->lvlist();

    diag("LVs(before): ${\Dumper($list)}");

    ok(defined($t->lvcreate(
        memberof => 'vg_test',
        name     => 'lv_test',
        size     => '1GiB',
    )), 'LV is created: vg_test/lv_test');

    $list = $t->lvlist();

    diag("LVs(after): ${\Dumper($list)}");
};

subtest 'lv format' => sub
{
    my $t = Test::AnyStor::Filesystem->new(addr => $GMS_TEST_ADDR);

    ok(defined($t->format(
        vgname => 'vg_test',
        lvname => 'lv_test'
    )), 'LV is formatted: vg_test/lv_test');
};

subtest 'lv mount' => sub
{
    my $t = Test::AnyStor::Filesystem->new(addr => $GMS_TEST_ADDR);

    ok(defined($t->mount(
        vgname => 'vg_test',
        lvname => 'lv_test'
    )), 'LV is mounted: vg_test/lv_test');
};

subtest 'lv umount' => sub
{
    my $t = Test::AnyStor::Filesystem->new(addr => $GMS_TEST_ADDR);

    ok(defined($t->unmount(path => '/volume/vg_test/lv_test'))
        , 'LV is unmounted: /volume/vg_test/lv_test');
};

subtest 'lvdelete' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $list = $t->lvlist();

    diag("LVs(before): ${\Dumper($list)}");

    $t->lvdelete(name => ['lv_test'], vg => 'vg_test');

    $list = $t->lvlist();

    diag("LVs(after): ${\Dumper($list)}");
};

subtest 'vgdelete vg_test' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $list = $t->vglist();

    diag("VGs(before): ${\Dumper($list)}");

    $t->vgdelete(name => 'vg_test');

    $list = $t->vglist();

    diag("VGs(after): ${\Dumper($list)}");
};

subtest 'pvdelete /dev/sdc, /dev/sdd' => sub
{
    my $t = Test::AnyStor::Volume->new(addr => $GMS_TEST_ADDR);

    my $list = $t->pvlist();

    diag("PVs(before): ${\Dumper($list)}");

    $t->pvdelete(device => ['/dev/sdc', '/dev/sdd']);

    $list = $t->pvlist();

    diag("PVs(after): ${\Dumper($list)}");
};

SKIP:
done_testing();
