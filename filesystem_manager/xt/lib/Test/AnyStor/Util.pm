package Test::AnyStor::Util;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';
use Env;
use Test::Most;
use Test::Mojo;
use Net::OpenSSH;
use Data::Dumper;
use Term::ANSIColor;
use Mojo::UserAgent;
use Try::Tiny;
use JSON qw/decode_json/;
use Net::OpenSSH;
use Data::Dumper;
use Test::AnyStor::Base;

use base 'Exporter';

our @EXPORT = qw(
    stat_chk cluster_status_api isboot_use_ping isboot_use_ssh reboot_node
    reboot_node_ssh shutdown_node_ssh get_time vm_ctl get_svc_list
    _get_init_conf _get_config_conf
);

our $GMS_STAT_FILE = '/var/log/gms_status_chk.log';
our $GMS_ROOT      = '/usr/gms';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub stat_chk
{
    my $ip   = shift;
    my %opts = (
        user                  => 'root',
        port                  => '22',
        master_stderr_discard => 1,
    );
    my $ret = 0;

    my $ssh = Net::OpenSSH->new($ip, %opts);

    if ($ssh->error)
    {
        warn sprintf("[%s] SSH Connect Failed (%d)", $ip, $ssh->error);
        return -1;
    }

    my ($out, $err)
        = $ssh->capture2(
        "perl $GMS_ROOT/t/regression/status_chk.t --logfile=$GMS_STAT_FILE");

    if ($ssh->error)
    {
        warn
            sprintf("[%s] status_chk.t excute Failed (%d)", $ip, $ssh->error);
        return -1;
    }

    ($out, $err) = $ssh->capture2("cat $GMS_STAT_FILE");

    if ($ssh->error)
    {
        warn sprintf("[%s] status_chk.t result view Failed (%d)",
            $ip, $ssh->error);
        return -1;
    }

    printf "$out";

    my $cmd = sprintf("perl %s /usr/gms/t/merge_test.t $ip:80",
        map { "-I$_"; } @INC);

    return call_system($cmd);
}

# 아이피, 모드를 받아서 상태가 정상인지 리턴
# 정상 1, 에러 0
# 모드 : 없으면 cluster fine 인지 확인
#        node :  node status ok 인지 확인

sub cluster_status_api
{
    my $token = shift;
    my $ip    = shift;
    my $mode  = shift;
    my $res   = undef;

    my $ua = Mojo::UserAgent->new();

    $ua->inactivity_timeout(60);
    $ua->request_timeout(60);

    my $tx = $ua->post("http://$ip/api/cluster/status",
        {Authorization => $token});

    cmp_ok($tx->res->code, '==', 200)
        || return 0;

    $res = decode_json($tx->res->body, {utf8 => 1});

    diag("Status: ${\explain($res)}");

    ok(exists($res->{stage_info}), 'response has stage_info')
        || return 0;

    cmp_ok(ref($res->{stage_info}),
        'eq', 'HASH', 'response->stage_info isa HASH')
        || return 0;

    cmp_ok($res->{stage_info}{stage},
        'eq', 'running', 'response->stage_info->stage is running')
        || return 0;

    cmp_ok(ref($res->{entity}), 'eq', 'HASH', 'entity isa HASH')
        || return 0;

    my $status = $res->{entity};

    ok(exists($status->{Msg}), 'status has Msg')
        || return 0;

    ok(exists($status->{Status}), 'status has Status')
        || return 0;

    if ($status->{Msg} eq 'RUNNING' || $status->{Status} eq 'OK')
    {
        return 1;
    }

    p_e_printf(
        "MSG: %s, Status: %s, Reason: %s\n",
        $status->{Msg},
        $status->{Status},
        $status->{Reason}
    );

    return 0;
}

sub isboot_use_ping
{
    my $ip    = shift;
    my $timeo = shift;

    $timeo = 1 if (!defined($timeo));

    while ($timeo-- > 0)
    {
        my $res = system("ping -qw 1 $ip > /dev/null");

        printf("Ping ... (%s) : res = %d\n", $ip, $res);

        return 1 if ($res == 0);
    }

    return 0;
}

sub isboot_use_ssh
{
    my $ip   = shift;
    my %opts = (
        user                  => 'root',
        port                  => '22',
        timeout               => 1,
        master_stderr_discard => 1,
    );

    my $ssh = Net::OpenSSH->new($ip, %opts);

    return $ssh->error ? 0 : 1;
}

sub reboot_node
{
    my ($ip, $mode, $sleep_time) = @_;

    my $cmd = 'reboot';

    $cmd = $cmd . ' -nf' if (defined($mode) && $mode eq 'force');

    if (defined($sleep_time))
    {
        $cmd = "sleep $sleep_time && nohup " . $cmd . " >/dev/null 2>&1 &";
    }
    else
    {
        $cmd = "nohup " . $cmd . " >/dev/null 2>&1 &";
    }

    my %opts = (
        user                  => 'root',
        port                  => '22',
        timeout               => 1,
        master_stderr_discard => 1,
    );

    my $ssh = Net::OpenSSH->new($ip, %opts);

    return -1 if ($ssh->error);

    $ssh->system($cmd);

    return -1 if ($ssh->error);

    return 0;
}

sub shutdown_node_ssh
{
    my ($ip, $mode, $sleep_time) = @_;

    my $cmd = 'shutdown -h now';

#   TODO : force option ignored
#    $cmd = $cmd . ' -nf' if (defined($mode) && $mode eq 'force');

    if (defined($sleep_time))
    {
        $cmd = "sleep $sleep_time && nohup " . $cmd . " >/dev/null 2>&1 &";
    }
    else
    {
        $cmd = "nohup " . $cmd . " > /dev/null 2>&1 &";
    }

    diag("ssh command : ssh -f $ip $cmd");

    system("ssh -f $ip \"$cmd\"");

    return 0;
}

sub reboot_node_ssh
{
    my ($ip, $mode, $sleep_time) = @_;

    my $cmd = 'reboot';

    $cmd = $cmd . ' -nf' if (defined($mode) && $mode eq 'force');

    if (defined($sleep_time))
    {
        $cmd = "sleep $sleep_time && nohup " . $cmd . " >/dev/null 2>&1 &";
    }
    else
    {
        $cmd = "nohup " . $cmd . " > /dev/null 2>&1 &";
    }

    diag("ssh command : ssh -f $ip $cmd");

    system("ssh -f $ip \"$cmd\"");

    return 0;
}

sub vm_ctl
{
    my ($ip, $args, $cmd, $parm) = @_;
    $parm = "" if not defined $parm;

    my $h_cmd
        = "vmware-cmd -H $args->{vm_host} -U $args->{vm_user} -P $args->{vm_pass} ";
    my $res;
    my $date;

    $h_cmd = $h_cmd . "$args->{vm_nodes}{$ip} $cmd \"$parm\"";

    my $retry_cnt = 3;

VM_RETRY:
    $date = get_time();
    diag("[$retry_cnt][$date] VMCMD : $h_cmd");

    do
    {
        local $SIG{ALRM} = sub { die 'vm_ctl timeout' };
        alarm(60);
        $res = `$h_cmd 2>&1`;
        alarm(0);
    };

    if (!defined($res))
    {
        system('pkill vmware-cmd');
        goto VM_RETRY if ($retry_cnt-- > 0);
    }

    else
    {
        chomp($res);
        diag("res = $res\n");

        # TODO : 좀 더 정확한 상태 결과 값 체크
        if ($cmd =~ /device/)
        {
            return 0 if $res =~ /already/;
        }
        if ($cmd =~ /stop|start/)
        {
            return 0 if $res =~ /state/;
        }
    }

    # TODO : result check should be more robust
    if (!defined $res)
    {
        p_e_printf("vm_ctl failed\n");
        return 1;
    }

    my @tmp_res = split(/\s*=\s*/, $res);

    if (!defined($tmp_res[1]) || $tmp_res[1] !~ /1/)
    {
        goto VM_RETRY if ($retry_cnt-- > 0);
        return 1;
    }

    return 0;
}

sub get_svc_list
{
    my ($start, $end) = @_;
    my @svc_list = ();

    my @svc_start = split(/\./, $start);
    my @svc_end   = split(/\./, $end);

    for (my $i = $svc_start[3]; $i le $svc_end[3]; $i++)
    {
        push @svc_list, "$svc_end[0].$svc_end[1].$svc_end[2].$i";
    }
    return @svc_list;
}

sub get_time
{
    my $time = shift;

    $time = time() if (!defined($time));

    my ($S, $M, $H, $d, $m, $Y) = localtime($time);

    $m += 1;
    $Y += 1900;

    return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $Y, $m, $d, $H, $M, $S);
}

sub _get_init_conf
{
    my ($conf_type, $conf_file) = @_;

    if (!-e $conf_file)
    {
        warn "Failed to access file: $conf_file: $!";
        return;
    }

    local $/;
    my $fh;

    if (!open($fh, '<', $conf_file))
    {
        warn "Failed to open: $conf_file: $!";
        return;
    }

    my $initconf = undef;

    try
    {
        $initconf = decode_json(<$fh>, {utf8 => 1});
    }
    catch
    {
        warn "Failed to decode file to JSON: $conf_file: $_";
    }
    finally
    {
        close($fh);
    };

    if (!(defined($initconf) && defined($initconf->{$conf_type})))
    {
        warn "No such key: $conf_type in $conf_file\n";
        return;
    }

    return $initconf->{$conf_type};
}

sub _get_config_conf
{
    my ($conf_file) = @_;

    if (!-e $conf_file)
    {
        print "Failed to access file: $conf_file: $!";
        return;
    }

    local $/;
    my $fh;

    if (!open($fh, '<', $conf_file))
    {
        print "Failed to open: $conf_file: $!";
        return;
    }

    my $initconf = undef;

    try
    {
        $initconf = decode_json(<$fh>, {utf8 => 1});
    }
    catch
    {
        warn "Failed to decode file to JSON: $conf_file: $_";
    }
    finally
    {
        close($fh);
    };

    my $network_conf = $initconf->{network};

    return {
        Network => {
            Management => {
                Interface => lc($network_conf->{management}{interface}),
                Ipaddr    => $network_conf->{management}{ipaddr},
                Netmask   => $network_conf->{management}{netmask},
                Gateway   => $network_conf->{management}{gateway},
            },
            Service => {
                Mode    => $network_conf->{service}{mode},
                Primary => $network_conf->{service}{primary},
                Slaves  => $network_conf->{service}{slaves}
            },
            Storage => {
                Mode    => $network_conf->{storage}{mode},
                Primary => $network_conf->{storage}{primary},
                Slaves  => $network_conf->{storage}{slaves},
                Ipaddr  => $network_conf->{storage}{ipaddr},
                Netmask => $network_conf->{storage}{netmask},
            }
        },
        Volume => {
            Base_Pvs => $initconf->{pvs},
            Tier_Pvs => []
        }
    };
}

1;

=encoding utf8

=head1 NAME

Test::AnyStor::Util - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

