package Test::AnyStor::Status;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Try::Tiny;
use Test::Most;
use Mojo::UserAgent;

use JSON qw/decode_json/;
use Encode qw/decode_utf8/;
use Data::Compare;
use Data::Dumper;
use Array::Diff;

use Test::AnyStor::Base;

extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Functions
#---------------------------------------------------------------------------
sub get_all_status
{
    my $self = shift;

    my $sorter = sub
    {
        my ($anum) = shift->{Mgmt_Hostname} =~ /(\d+)$/;
        my ($bnum) = shift->{Mgmt_Hostname} =~ /(\d+)$/;

        ($anum || 0) <=> ($bnum || 0);
    };

    my $nodes = [sort { $sorter->($a, $b); } @{$self->nodes}];

    my @mds_nodes = ();

    for (my $i = 0; $i < 3; $i++)
    {
        push(@mds_nodes, $nodes->[$i]);

        last if ($i + 1 > @$nodes);
    }

    my $max_retry = 3 * @mds_nodes;
    my $ret       = undef;

    for (my $i = 0; $i < $max_retry; $i++)
    {
        my $etcd_node_idx = $i / @mds_nodes;

        $ret = $self->etcd_get(
            ip   => $mds_nodes[$etcd_node_idx]->{Mgmt_IP}->{ip},
            port => '2379',
            key  => '/Status'
        );

        if (defined($ret))
        {
            return $ret;
        }

        sleep(5);
    }

    return;
}

sub get_nodes_status
{
    my $self = shift;
    my $ret  = $self->get_all_status();

    if (ref($ret) ne 'HASH'
        || !exists($ret->{nodes})
        || !defined($ret->{nodes}))
    {
        return;
    }

    return $ret->{nodes};
}

sub check_components_status
{
    my $self     = shift;
    my $hostname = shift;
    my $ip       = shift;

    my $max_retry = 6;
    my @comps     = (
        'ctdb',
        'disk-healthy',
        'eflowd',
        'girasole-publisher',
        'gluster',
        'glustereventsd',
        'gms',
        'hba-port',
        'netdata',
        'nfs',
        'ntpd',
        'osdisk',
        'power',
        'service-network',
        'smb',
        'storage',
        'storage-network',
    );

    # fixme : reload is not ready in publisher or gms or starting logic
    my @exception_comps
        = ('gms', 'girasole-publisher', 'disk-healthy', 'hba-port',);

    my @add_if_master = ('mariadb');
    my @add_if_mds = ('girasole-hub', 'girasole-notifier', 'etcd', 'grafana');

    if ($hostname =~ /^.+-[1-3]$/)
    {
        push(@comps, @add_if_mds);
        push(@comps, @add_if_master) if ($hostname =~ /^.+-1$/);
    }

    my $hit         = 'false';
    my $comp_status = undef;

    for (my $try = 1; $try <= $max_retry; $try++)
    {
        sleep 10;

        my ($out, $err) = $self->ssh_cmd(
            addr => $ip,
            cmd  => 'cat /var/lib/gms/component_status'
        );

        if (!defined($out) && (defined($err) && $err ne ''))
        {
            p_e_printf("Failed to get node components status: $hostname");
            next;
        }

        $hit = 'false';

        $comp_status = try
        {
            return decode_json(decode_utf8($out));
        }
        catch
        {
            p_e_printf("[ERR] " . $_);
            return;
        };

        next if (ref($comp_status) ne 'HASH');

        my $lhs = [sort(@comps)];
        my $rhs = [sort(keys(%{$comp_status}))];

        my $diff = Array::Diff->diff($lhs, $rhs);

        if (!$diff->count)
        {
            $hit = 'true';
            last;
        }

        p_w_printf(
            "[%s] components status is not ready: checking(%s), not shown(%s)",
            $hostname,
            join(', ', @{$diff->added}),
            join(', ', @{$diff->deleted})
        );

        foreach my $to_delete_comp (@{$diff->deleted})
        {
            if (grep { $_ eq $to_delete_comp } @exception_comps)
            {
                @comps = grep { $_ ne $to_delete_comp } @comps;
                p_w_printf("exception list added: $to_delete_comp");
            }
        }

        foreach my $to_add_comp (@{$diff->added})
        {
            push(@comps, $to_add_comp);
            p_w_printf("add list: $to_add_comp");
        }
    }

    if ($hit eq 'false')
    {
        p_e_printf("expected components: ${\Dumper(\@comps)}");
        p_e_printf("got: ${\Dumper($comp_status)}");

        fail("Component status missing has been detected: $hostname");

        return -1;
    }

    # 상태 값을 확인하여 테스트 결과를 리턴
    foreach my $comp (@comps)
    {
        next if (uc($comp_status->{$comp}{status}) eq 'OK');

        p_e_printf(Dumper($comp_status->{$comp}));
        fail("Abnormal component's status detected: $hostname, $comp");
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Status - 

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
