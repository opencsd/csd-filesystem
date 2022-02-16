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

# 초기값 설정

my $total_test   = 3;
my $boot_wait    = 300;
my $fail_wait    = 15;
my $reboot_delay = -1;
my $test_mode    = 'reboot';

my $config;
my @nodes        = ();
my $current_test = 0;

my $bail_out = 'yes';

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
    'test_mode=s'    => \$test_mode,
);

@nodes = split(/\s*,\s*/, join(',', @nodes));

# VM 빌드 정보 config 찾기
#
if (!scalar(@nodes))
{
    if (!defined($config))
    {
        my $hostname = `hostname`;
        chomp($hostname);

        my $HOSTNAME = uc($hostname);

        if (-f "/usr/jenkins/jenkins_build_info/$hostname.config")
        {
            diag("config=/usr/jenkins/jenkins_build_info/$hostname.config\n");
            $config = "/usr/jenkins/jenkins_build_info/$hostname.config";
            $ENV{GMS_BUILD_CONFIG} = $config;
        }
        elsif (-f "/usr/jenkins/jenkins_build_info/$HOSTNAME.config")
        {
            diag("config=/usr/jenkins/jenkins_build_info/$HOSTNAME.config\n");
            $config = "/usr/jenkins/jenkins_build_info/$HOSTNAME.config";
            $ENV{GMS_BUILD_CONFIG} = $config;
        }
        else
        {
            paint_err();
            diag("There is no config file\n");
            diag("config=/usr/jenkins/jenkins_build_info/$HOSTNAME.config\n");
            paint_reset();
            exit 1;
        }
    }

    my $t_nodes = _get_init_conf('test_nodes', $config);

    if (!defined($t_nodes))
    {
        diag("Failed to get TEST Target Configuration\n");
        help();
    }

    @nodes = @$t_nodes;
}

# 테스트 관리 정보 자료구조
#
my %args = (
    wait      => $boot_wait,
    fail_wait => $fail_wait,
    delay     => $reboot_delay,
    total     => $total_test,
    count     => $current_test
);

my $vm_infos = _get_init_conf('vm_info',    $config);
my $vm_nodes = _get_init_conf('test_nodes', $config);
my $eth_info = _get_init_conf('network',    $config);
my $svc_info = _get_init_conf('create',     $config);

# 클러스터 설정 정보 입수
#
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
        "1. %s test Param :(total_test=%d)(boot_wait=%d)(reboot_delay=%d)(bail_out=%s)\n",
        $test_mode,
        $total_test,
        $boot_wait,
        $reboot_delay,
        $bail_out
    )
);

$t->info_diag(
    sprintf(
        "Test Param : Service(%s), Storage(%s) SVC_IP (%s)",
        $args{svc_eth},
        $args{stg_eth},
        join(' ', @t_list)
    )
);

# 테스트 구성을 위한 기본 클러스터 설정

$t->info_diag(sprintf("0. Create Preset : User/Zone/Volume/Share\n"));

$args{result}{preset}{start} = get_time();
$res                         = $t->test_preset($vm_nodes, $vm_infos, \%args);
$args{result}{preset}{end}   = get_time();

goto ERROR_RET if ($res != 0);

$res = $t->service_io_check(\%args);

goto ERROR_RET if ($res != 0);

# 관리 IP 정보 입수

my @test_nodes;

foreach my $node (@{$t->nodes})
{
    push(@test_nodes, $node->{Mgmt_IP}->{ip});
}

$t->info_diag(sprintf("0. active node list %s \n", join(',', @test_nodes)));

goto ERROR_RET if (scalar(@test_nodes) < 1);

if ($test_mode eq 'reboot')
{
    # 1. Random Reboot Testing
    while ($args{count}++ < $total_test)
    {
        $args{result}{reboot}{$args{count} - 1} = get_time();
        $res = $t->reboot_basic_test(\@test_nodes, \%args, $vm_infos);

        goto ERROR_RET if ($res != 0);
    }
}
elsif ($test_mode eq 'failover')
{
    # 2. Service Network Testing
    $args{result}{svc_net}{start} = get_time();
    $res = $t->service_network_test($vm_infos, \%args);
    $args{result}{svc_net}{end} = get_time();

    goto ERROR_RET if ($res != 0);

    # 4. Node Power Testing

    $args{result}{power}{start} = get_time();
    $res                        = $t->power_test($vm_infos, \%args);
    $args{result}{power}{end}   = get_time();

    goto ERROR_RET if ($res != 0);

    # 3. Storage Network Testing

    $args{result}{stg_net}{start} = get_time();
    $res = $t->storage_network_test($vm_infos, \%args);
    $args{result}{stg_net}{end} = get_time();

    goto ERROR_RET if ($res != 0);

    # 4. Random Reboot Testing
    $args{result}{reboot}{start} = get_time();
    $res = $t->reboot_basic_test(\@nodes, \%args, $vm_infos);
    $args{result}{reboot}{end} = get_time();

    goto ERROR_RET if ($res != 0);
}

done_testing();

$t->info_diag(sprintf("Test ended successfully: $total_test"));

exit 0;

ERROR_RET:
$t->info_diag(sprintf("Test Result :\n%s", Dumper($args{result})));
nodes_archive($test_mode, \@test_nodes);
paint_err();
BAIL_OUT("test bailed out");
paint_reset();

sub help
{
    warn "help\n";
    exit -1;
}

1;
