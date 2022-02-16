#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY        = 'hclee';
our $TEST_DESCRIPTOIN = 'SMART API test';

use strict;
use warnings;
use utf8;

BEGIN {
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname(rel2abs(__FILE__));
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift( @INC,
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Test::Most;
use Data::Dumper;
use Test::AnyStor::SMART;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

subtest 'Get S.M.A.R.T. device information' => sub
{
    my $t = Test::AnyStor::SMART->new(addr => $ENV{GMS_TEST_ADDR});
    my $entity = $t->smart_dev_info();

    ok(ref($entity) eq 'ARRAY' && @{$entity},
        'S.M.A.R.T. device information get');
};

subtest 'Get S.M.A.R.T. device attribute' => sub
{
    my $t = Test::AnyStor::SMART->new(addr => $ENV{GMS_TEST_ADDR});
    my $entity = $t->smart_dev_attrs();

    # XXX: VM 디스크는 SMART가 동작하지 않음
    ok(ref($entity) eq 'ARRAY', 'S.M.A.R.T. device attribute get');
};

subtest 'Get S.M.A.R.T. device test status' => sub
{
    my $t = Test::AnyStor::SMART->new(addr => $ENV{GMS_TEST_ADDR});
    my $entity = $t->smart_dev_tests();

    # XXX: VM 디스크는 SMART가 동작하지 않음
    ok(ref($entity) eq 'ARRAY', 'S.M.A>R.T. device test status get');

    ok(1, 'Dumper smart device test status: ' . Dumper $entity);
};

subtest 'Get S.M.A.R.T. device latest test status' => sub
{
    my $t = Test::AnyStor::SMART->new(addr => $ENV{GMS_TEST_ADDR});
    my $entity = $t->smart_dev_tests(latest => 1);

    # XXX: VM 디스크는 SMART가 동작하지 않음
    ok(ref($entity) eq 'ARRAY', 'S.M.A.R.T. device latest test status get');

    ok(1, 'Dumper smart device latest test status: ' . Dumper $entity);
};

subtest 'S.M.A.R.T device info reload trigger test' => sub
{
    my @tmp = split(/:/, $ENV{GMS_TEST_ADDR});
    my $ipaddr = $tmp[0];

    my $t = Test::AnyStor::SMART->new(addr => $ENV{GMS_TEST_ADDR});

    my ($prev_updated_at, undef) = $t->ssh_cmd(
        addr => $ipaddr,
        cmd  => "etcdctl get /\$\(hostname\)/SMART/Operations | jq .updated_at"
    );

    ok($prev_updated_at, "S.M.A.R.T. device info prev reloading time is $prev_updated_at");

    my $expected_time = $t->smart_dev_info_reload();

    ok($expected_time, "S.M.A.R.T. device info expected reloading time is $expected_time");

    my $updated = 0;

    for (my $i=0; $i<2; $i++)
    {
        sleep(300);

        my ($curr_updated_at, undef) = $t->ssh_cmd(
            addr => $ipaddr,
            cmd  => "etcdctl get /\$\(hostname\)/SMART/Operations | jq .updated_at"
        );

        if ($curr_updated_at > $prev_updated_at)
        {
            $updated = 1;
            ok(1, "S.M.A.R.T. device info reloaded time is $curr_updated_at");
            last;
        }
    }

    ok($updated, "S.M.A.R.T device info reloaded");
};

done_testing();
