#!/usr/bin/perl

BEGIN
{
    use File::Basename          qw/dirname/;
    use File::Spec::Functions   qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/lib", "$ROOTDIR/libgms", "$ROOTDIR/t/lib",
        '/usr/girasole/lib');
}

use Env;
use Test::Most;
use Test::Deep;
use Test::AnyStor::Explorer;
use File::Temp  qw/tmpnam/;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

my $t = Test::AnyStor::Explorer->new();

# :TODO 2019년 02월 01일 11시 58분 27초: by P.G.
# We have to make method which verifies file/directory exists.
my $IP = ($GMS_TEST_ADDR =~ m/^([^:]+)/)[0];

my ($out, $err) = $t->ssh_cmd(
    addr => $IP,
    cmd  => 'ls -1 /etc/sysconfig/network-scripts',
);

ok(defined($out) && length($out), 'SSH command is executed successfully');

my @files = split(/\n+/, $out);

cmp_deeply(
    \@files,
    supersetof(qw/
        ifcfg-ens160 ifcfg-ens192 ifcfg-ens224
        ens160.backcfg ens192.backcfg ens224.backcfg
    /),
    'NIC configurations exist'
);

undef $t;
