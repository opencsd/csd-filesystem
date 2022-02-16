package Test::AnyStor::ClusterPower;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::Most;
use Mojo::UserAgent;
use JSON qw/decode_json/;

use Test::AnyStor::Util;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'Test::AnyStor::Base';
extends 'Test::AnyStor::ClusterFailure';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
# inherited from Test::AnyStor::Base
has '+no_logout' => (default => 1,);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub cluster_shutdown
{
    my $self = shift;
    my $res  = $self->call_rest_api('cluster/power/shutdown', {}, {}, {});

    return $res->{entity};
}

sub cluster_reboot
{
    my $self = shift;

    print "Call the reboot API with UserAgent in MOJO\n";

    return $self->call_rest_api('cluster/power/reboot', {}, {}, {});

}

sub node_reboot
{
    my $self = shift;

    print "Call the reboot API with UserAgent in MOJO\n";

    return $self->call_rest_api('system/power/reboot', {}, {}, {});
}

sub rest_check
{
    my $self = shift;
    my ($node, $args) = @_;

    return $self->node_status_check($node, $args);
}

sub get_uptime
{
    my $self   = shift;
    my $target = shift // undef;

    my $ip_list     = ();
    my %uptime_list = ();

    my $time = ();
    my $err  = ();

    if (defined($target))
    {
        my $target_hs = undef;

        ($target_hs, $err) = $self->ssh_cmd(
            addr => $target,
            cmd  => 'hostname'
        );

        if (!defined($target_hs))
        {
            warn
                '[INFO] Failed to execute command with ssh: Did not receive the hostname';
            return;
        }

        ($time, $err) = $self->ssh_cmd(
            addr => $target,
            cmd  => 'stat --format=%z /var/log/dmesg'
        );

        if (!defined($time))
        {
            warn
                '[INFO] Failed to execute command with ssh: Did not receive the uptime';
            return;
        }

        my ($h, $m, $s) = ($time =~ /(\d\d):(\d\d):(\d\d)/);

        $uptime_list{$target_hs} = "$h,$m,$s";
    }
    else
    {
        my %mgmtip_hs = $self->mgmtip_list('HASH');

        for my $host (keys(%mgmtip_hs))
        {
            ($time, $err) = $self->ssh_cmd(
                addr => $mgmtip_hs{$host},
                cmd  => 'stat --format=%z /var/log/dmesg'
            );

            if (!defined($time))
            {
                warn "[INFO] Command failed : Did not receive the uptime";
                return;
            }

            my ($h, $m, $s) = ($time =~ /(\d\d):(\d\d):(\d\d)/);

            $uptime_list{$host} = "$h,$m,$s";
        }
    }

    return %uptime_list;
}

sub cmp_uptime
{
    my $self      = shift;
    my $check_cnt = shift;
    my $target    = shift // undef;

    # :TODO 2018년 06월 16일 19시 33분 30초: by P.G.
    # 각 변수가 어떤 역할을 하는지 주석 필요
    my %bef = @_;    # ??
    my %aft = ();    # ??
    my $jdg = 0;     # ??

    my $node_cnt    = ();
    my $node_cnt_bf = scalar(keys(%bef));

    # 총 체크 회수 결정
    for (my $retry = 0; $retry < $check_cnt; $retry++)
    {
        $jdg = 0;
        %aft = ();

        # 각 노드 재부팅 시간 체크
        foreach my $host (keys(%bef))
        {
            %aft
                = defined($target)
                ? $self->get_uptime($target)
                : $self->get_uptime;

            # 모든 노드 혹은 지정된 노드($target)가 부팅 중
            if (!%aft)
            {
                printf("%s to be not bootstrapped...\n",
                    defined($target) ? "$target seems" : 'All nodes seem');
                $jdg = 1;
                last;
            }

            # 한 개 이상의 노드가 부팅 상태
            $node_cnt = keys(%aft);

            if ($node_cnt != $node_cnt_bf)
            {
                printf('Failed to get uptime for some nodes: %s',
                    Dumper($node_cnt));
                $jdg = 1;
                last;
            }

            my ($bh, $bm, $bs) = split(/,/, $bef{$host});
            my ($fh, $fm, $fs) = split(/,/, $aft{$host});

            # 재부팅 전에 uptime 체크가 되었을 때
            #   - 기동 시작 시간(uptime)은 /var/log/dmesg 파일의 stat 시간으로
            #     확인하고 있음 (get_uptime() 메서드 참조)
            if ($bh == $fh && $bm == $fm && $bs == $fs)
            {
                printf('%s seems to be not bootstrapped: '
                        . "%d/%d(H), %d/%d(M), %d/%d(S)\n",
                    $host, $bh, $fh, $bm, $fm, $bs, $fs);
                $jdg = 1;
                last;
            }

            printf("%s booted successfully: %d/%d(H), %d/%d(M), %d/%d(S)\n",
                $host, $bh, $fh, $bm, $fm, $bs, $fs);
        }

        if ($jdg == 0)
        {
            print "All nodes has bootstrapped successfully!\n";
            last;
        }

        print "Retrying $retry and going to sleep 20 seconds...\n";
        sleep 20;
    }

    return $jdg;
}

sub mgmtip_list
{
    my $self = shift;
    my $mode = shift;

    my $node_cnt    = scalar(@{$self->nodes});
    my @node_hostnm = $self->gethostnm(start_node => 0, cnt => $node_cnt);

    my @ip_arr = ();
    my %ip_hs  = ();

    if (!defined($mode))
    {
        warn '[ERR] Invalid mode';
        return 1;
    }

    my $hostnm_k = 'Mgmt_Hostname';
    my $mgmtip_k = 'Mgmt_IP';

    foreach my $hostnm (@node_hostnm)
    {
        foreach my $info (@{$self->nodes})
        {
            if ($hostnm eq $info->{$hostnm_k})
            {
                if ($mode eq 'ARR')
                {
                    push(@ip_arr, $info->{$mgmtip_k}->{ip});
                    last;
                }
                else
                {
                    $ip_hs{$hostnm} = $info->{$mgmtip_k}->{ip};
                }
            }
        }
    }

    if ($mode eq 'ARR')
    {
        return @ip_arr;
    }
    else
    {
        return %ip_hs;
    }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::ClusterPower - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item B<Item 1>

=item B<Item 2>

=item B<Item 3>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
