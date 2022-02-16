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
use Getopt::Long;
use Mojo::UserAgent;
use Sys::Hostname;
use Try::Tiny;
use Test::Most;
use Test::AnyStor::Base;
use Test::AnyStor::ClusterFailure;
use Test::AnyStor::Util;

use Data::Dumper;
$Data::Dumper::Terse = 1;

select(STDERR);
$| = 1;
select(STDOUT);
$| = 1;

my @nodes        = ();
my $total_test   = -1;
my $current_test = 0;
my $boot_wait    = -1;
my $fail_wait    = -1;
my $reboot_delay = -1;
my $bail_out     = 'yes';
my $config;

# 검사 준비

GetOptions(
    'h'              => \&help,
    'nodes=s'        => \@nodes,
    'test_count=i'   => \$total_test,
    'boot_wait=i'    => \$boot_wait,
    'fail_wait=i'    => \$fail_wait,
    'bail_out=s'     => \$bail_out,
    'config=s'       => \$config,
    'reboot_delay=i' => \$reboot_delay,
);

@nodes = split(/\s*,\s*/, join(',', @nodes));

if (!scalar(@nodes))
{
    if (!defined($config))
    {
        my $host = hostname;
        $config = "/usr/jenkins/jenkins_build_info/$host.config";
    }

    my $t_nodes = _get_init_conf('test_nodes', $config);

    if (!defined($t_nodes))
    {
        diag("Failed to get TEST Target Configuration\n");
        help();
    }

    @nodes = @$t_nodes;
}

$total_test   = 1   if ($total_test == -1);
$boot_wait    = 300 if ($boot_wait == -1);
$fail_wait    = 15  if ($fail_wait == -1);
$reboot_delay = 30  if ($reboot_delay == -1);

my %args = (
    wait      => $boot_wait,
    fail_wait => $fail_wait,
    delay     => $reboot_delay,
    total     => $total_test,
    count     => $current_test
);

# 0. prepare

my $vm_infos = _get_init_conf('vm_info',    $config);
my $vm_nodes = _get_init_conf('test_nodes', $config);
my $eth_info = _get_init_conf('network',    $config);
my $svc_info = _get_init_conf('create',     $config);

my @t_list
    = get_svc_list($svc_info->{service}{start}, $svc_info->{service}{end});

$args{svc_list} = \@t_list;
$args{svc_eth}  = $eth_info->{service}{slaves}[0];
$args{stg_eth}  = $eth_info->{storage}{slaves}[0];

my $t = Test::AnyStor::ClusterFailure->new(
    addr     => "$nodes[0]:80",
    no_login => 1
);

my $res;

$t->info_diag(
    sprintf(
        'Starting Failure Test: (total_test=%d)(boot_wait=%d)(reboot_delay=%d)',
        $total_test,
        $boot_wait,
        $reboot_delay
    )
);

$t->info_diag(
    sprintf(
        'Test Param: Service(%s), Storage(%s) SVC_IP (%s)',
        $args{svc_eth},
        $args{stg_eth},
        join(' ', @t_list)
    )
);

$args{result}{preset}{start} = get_time();
$res = $t->test_preset($vm_nodes, $vm_infos, \%args, 'arbiter');
$args{result}{preset}{end} = get_time();

goto ERROR_RET if ($res != 0);

# 2. Service Network Testing

$args{result}{svc_net}{start} = get_time();
$res                          = $t->service_network_test($vm_infos, \%args);
$args{result}{svc_net}{end}   = get_time();

goto ERROR_RET if ($res != 0);

# 4. Node Power Testing

$args{result}{power}{start} = get_time();
$res                        = $t->power_test($vm_infos, \%args);
$args{result}{power}{end}   = get_time();

goto ERROR_RET if ($res != 0);

# 3. Storage Network Testing

$args{result}{stg_net}{start} = get_time();
$res                          = $t->storage_network_test($vm_infos, \%args);
$args{result}{stg_net}{end}   = get_time();

goto ERROR_RET if ($res != 0);

# 1. Random Reboot Testing

$args{result}{reboot}{start} = get_time();
$res = $t->reboot_basic_test(\@nodes, \%args, $vm_infos);
$args{result}{reboot}{end} = get_time();

goto ERROR_RET if ($res != 0);

done_testing();
$t->info_diag(sprintf('Failure test ended successfully'));

exit 0;

ERROR_RET:
$t->info_diag(sprintf("Test Result :\n%s", Dumper($args{result})));
nodes_archive('stability', \@nodes);
paint_err();
BAIL_OUT('Failure test bailed out');
paint_reset();

sub help
{
    warn "help\n";
    exit -1;
}

1;
