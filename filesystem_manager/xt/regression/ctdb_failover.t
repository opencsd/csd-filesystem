#!/usr/bin/perl

use v5.14;

use strict;
use warnings;
use utf8;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/\/[^\/]+$//;

    unshift(@INC,
        (map { "$ROOTDIR/$_"; } qw/libgms lib/),
        '/usr/girasole/lib');
}

use Env;
use Test::Most;
use Data::Dumper;
use Test::AnyStor::Base;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if (@ARGV);

my $GMS_TEST_ADDR = $ENV{GMS_TEST_ADDR};

if (!defined($GMS_TEST_ADDR))
{
    fail('Argument is missing');
    return 0;
}

subtest 'ctdb failover with disconnected storage network' => sub
{
    my $t = Test::AnyStor::Base->new(addr => $GMS_TEST_ADDR);

    foreach my $node (@{$t->nodes})
    {
        my $ip = $node->{Mgmt_IP}->{ip};

        ok(
            1,
            "try to disconnect storage network on $node->{Mgmt_Hostname}:$ip"
        );

        my $info = ctdb_info($ip);
        if (!defined $info || $info->{run_state} ne 'RUNNING')
        {
            fail("ctdb is not running.");
            return;
        }

        nic_action($ip, 'bond0', 'down');

        my $fail      = 0;
        my $max_retry = 5;

        for ($fail = 1; $fail <= $max_retry; $fail++)
        {
            sleep 60;

            $info = ctdb_info($ip);

            if (!defined($info) || $info->{run_state} ne 'RUNNING')
            {
                next;
            }

            if (defined($info->{svc_ip}) && @{$info->{svc_ip}} == 0)
            {
                last;
            }

            ok(
                "waiting to release the public ip from public interface ... ($fail/$max_retry)"
            );
        }

        if ($fail >= $max_retry)
        {
            fail(
                "ctdb could not remove the public ips from public interface. test fail"
            );
            return;
        }

        nic_action($ip, 'bond0', 'up');

        $fail      = 0;
        $max_retry = 5;

        for ($fail = 1; $fail <= $max_retry; $fail++)
        {
            sleep 60;

            $info = ctdb_info($ip);

            if (!defined($info) || $info->{run_state} ne 'RUNNING')
            {
                next;
            }

            if (defined($info->{svc_ip}) && @{$info->{svc_ip}} > 0)
            {
                last;
            }

            ok(
                "waiting to take a public ip from another ctdb node ... ($fail/$max_retry)"
            );
        }

        if ($fail >= $max_retry)
        {
            fail("ctdb could not take a public ip. test fail");
            return;
        }

        sleep 10;
    }
};

done_testing();

sub ctdb_info
{
    my $ip  = shift;
    my $res = {
        run_state => undef,
        pnn       => undef,
        stg_ip    => undef,
        status    => undef,
        svc_ip    => undef,
    };

    my ($out, undef)
        = Test::AnyStor::Base::ssh_cmd(addr => $ip, cmd => 'ctdb runstate');
    if (!defined $out || $out eq "")
    {
        return;
    }

    $res->{run_state} = $out;

    ($out, undef)
        = Test::AnyStor::Base::ssh_cmd(addr => $ip, cmd => 'ctdb nodestatus');
    if ($out
        =~ /^pnn:(?<pnn>\d+)\s+(?<ip>\d+\.\d+\.\d+\.\d+)\s+(?<status>.+)\s+\(.+/
        )
    {
        $res->{pnn}    = $+{pnn};
        $res->{stg_ip} = $+{ip};
        $res->{status} = $+{status};
    }

    my $cmd = "ip addr show bond1 | grep \"inet \" | awk '{print \$2}'";
    ($out, undef) = Test::AnyStor::Base::ssh_cmd(addr => $ip, cmd => $cmd);

    if (defined $out)
    {
        $res->{svc_ip} = [split(/\s+/, $out)];
    }

    print "\tctdb info($ip): " . Dumper $res;

    return $res;
}

sub nic_action
{
    my $ip     = shift;
    my $iface  = shift;
    my $action = shift;

    my @cmd = ("ifconfig ", $iface);
    if ($action eq 'up' || $action eq 'down')
    {
        push @cmd, $action;
    }
    else
    {
        fail("invalid arguement nic_action(). action should be 'up' or 'down'"
        );
        return -1;
    }

    Test::AnyStor::Base::ssh_cmd(addr => $ip, cmd => "@cmd");
    return 0;
}
