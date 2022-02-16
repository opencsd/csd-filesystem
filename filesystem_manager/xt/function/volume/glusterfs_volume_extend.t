#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'GlusterFS volume 확장 (scale-in) 테스트';

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Net::OpenSSH;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Share;
use Test::AnyStor::ClusterVolume;
use Volume::LVM::LV;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

subtest 'GlusterFS volume bricks extending test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $node_cnt  = scalar(@{$t->nodes});
    my @created   = ();
    my @need_vols = (
        {
            volpolicy  => 'Distributed',
            capacity   => '2.0G',
            replica    => 1,
            node_count => $node_cnt,
            start_node => 0,
        },
    );

    foreach my $need (@need_vols)
    {
        my $res = $t->volume_create(%{$need});

        sleep 1;

        if ($res)
        {
            $need->{volname} = $res;

            push(@created, $need);

            $t->verify_volstatus(volname => $res, exists => 1);

            sleep 1;
        }
    }

    $t->volume_extend(volname => $_->{volname}, extendsize => '4.0G')
        for (@created);

    foreach my $vol (@created)
    {
        $t->verify_volstatus(volname => $vol->{volname}, exists => 1);

        my $res = $t->volume_delete(volname => $vol->{volname});

        is($res, 0, 'cluster volume delete');

        $t->verify_volstatus(volname => $vol->{volname}, exists => 0);
    }
};

done_testing();
