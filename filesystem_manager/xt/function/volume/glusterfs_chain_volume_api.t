#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY   = 'hclee';
our $VERSION     = '1.00';
our $DESCRIPTION = 'GlusterFS 체인 볼륨 생성/삭제 테스트';

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

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

subtest 'GlusterFS chaining volume test' => sub
{
    my $t = Test::AnyStor::ClusterVolume->new(addr => $GMS_TEST_ADDR);

    my $node_cnt  = scalar(@{$t->nodes});

    my %vol_info = (
        volpolicy  => 'Distributed',
        capacity   => '1.0G',
        replica    => 2,
        node_count => $node_cnt,
        start_node => 0,
        chaining   => 'true',
    );

    my $res = $t->volume_create(%vol_info);

    sleep 1;

    if ($res)
    {
        $vol_info{volname} = $res;
        $t->verify_volstatus(volname => $res, exists => 1);
    }

    $t->volume_delete(volname => $vol_info{volname});
    $t->verify_volstatus(volname => $vol_info{volname}, exists => 0);
};

done_testing();

