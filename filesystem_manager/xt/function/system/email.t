#!/usr/bin/perl -I /usr/gms/t/lib

our $AUTHORITY        = 'Woonghee Han';
our $TEST_DESCRIPTOIN = 'Cluster Email Test';

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
use Test::AnyStor::Email;
use Test::AnyStor::Network;
use Test::AnyStor::Util;
use Test::AnyStor::Base;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

subtest 'Prepare settings for email test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $ENV{GMS_TEST_ADDR});

    my $res = $t->cluster_network_dns_update(dns => ['8.8.8.8']);

    ok($res->{reload_stat} eq 'OK', 'setting the dns success');

    sleep 10;
};

subtest 'Cluster email test' => sub
{
    my $t = Test::AnyStor::Email->new(addr => $ENV{GMS_TEST_ADDR});

    (my $addr = $ENV{GMS_TEST_ADDR}) =~ s/:.*$//;

    $t->ssh_cmd(
        addr  => $addr,
        cmd   => 'route add default gw 192.168.0.1',
        timeo => 30
    );

    my $res = $t->email;

    ok ($res eq '0', 'email test success');
};

subtest 'Clear settings for email test' => sub
{
    my $t = Test::AnyStor::Network->new(addr => $ENV{GMS_TEST_ADDR});

    my $res = $t->cluster_network_dns_update(dns => []);

    print "DNS: ${\Dumper($res)}";

    ok ($res->{reload_stat} eq 'OK', 'Clear the dns setting success');
};

done_testing();
