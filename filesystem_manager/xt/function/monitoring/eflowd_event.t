#!/usr/bin/perl -I /usr/gms/t/lib

use strict;
use warnings;
use utf8;

our $AUTHORITY        = 'hclee';
our $VERSION          = '1.00';
our $TEST_DESCRIPTOIN = 'eflowd event test';

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname(rel2abs(__FILE__));
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/perl5/lib/perl5",
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib",
        "/usr/gsm/lib");

}

use Env;
use Test::Most;
use Test::AnyStor::Base;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;
my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined $GMS_TEST_ADDR)
{
    fail('Argument is missing');
    return 0;
}

subtest 'eflowd event test' => sub
{
    my $t = Test::AnyStor::Base->new(addr => $ENV{GMS_TEST_ADDR});

    my ($from, $to) = (undef, undef);

    # prepare
    my $ip = [split(/:/, $GMS_TEST_ADDR)]->[0];

    my $code_prefix = 'EFLOWD_EVENT_TEST_';
    my $msg_prefix  = 'this is test event for eflowd: ';
    my @test_set    = ();

    for (my $i = 1; $i <= 10; $i++)
    {
        my $tmp = {
            pass => 'true',
            args => {
                code    => $code_prefix . $i,
                msg     => $msg_prefix . $i,
                level   => 'info',
                details => {hello => $i},
            },
        };

        push @test_set, $tmp;
    }

    # event trigger
    $from = $t->get_ts_from_server();

    sleep 1;

    for my $test (@test_set)
    {
        my $args = $test->{args};
        my @cmd  = (
            'eflowdctl',
            'event',
            'create',
            '--from=cluster',
            "--level=$args->{level}",
            "--code=$args->{code}",
            "--msg=\"$args->{msg}\"",
        );

        my $details = $args->{details};
        for my $key (keys %{$details})
        {
            my $val = $details->{$key};
            push(@cmd, "--details=$key=$val");
        }

        my ($ret, undef) = $t->ssh_cmd(addr => $ip, cmd => "@cmd");

        if (defined $ret && $ret ne "" && $ret =~ /event id : (?<id>.+)/)
        {
            ok(1, "event create : " . $+{id});
        }
        else
        {
            fail("event create : undefined");
        }
    }
    $to = $t->get_ts_from_server();

    sleep 5;

    # event test verification
    my $got = $t->get_events(
        NumOfRecords => 10,          # 동작 안함
        PageNum      => 1,
        From         => $from,
        To           => $to,
        Category     => 'DEFAULT',

        #Level        => $args{level},
    );

    for my $test (@test_set)
    {
        my $check = $test->{args};

        my @found = grep { $_->{Code} eq $check->{code} } @{$got};

        if ($found[0]->{Code} ne $check->{code})
        {
            $test->{pass} = 'false';
        }

        if ($found[0]->{Message} ne $check->{msg})
        {
            $test->{pass} = 'false';
        }

        if ($found[0]->{Level} ne uc($check->{level}))
        {
            $test->{pass} = 'false';
        }

        my $details = $found[0]->{Details};
        if ($details->{hello} ne $check->{details}{hello})
        {
            $test->{pass} = 'false';
        }

        if ($test->{pass} eq 'false')
        {
            print "\t\tgot : " . Dumper @found;
            print "\t\texpected : " . Dumper $check;
            fail("event test verifcation: $check->{code}");
        }
        else
        {
            ok(1, "event test verifcation: $check->{code}");
        }
    }
};

done_testing();
