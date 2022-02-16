package GMS::Controller::Dashboard;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Girasole::Constants qw/:LEVEL/;
use Girasole::Analyzer::Stats;
use GMS::API::Return;
use GMS::Common::Units;
use GMS::Cluster::DashboardCtl;
use GMS::Cluster::Etcd;
use GMS::Cluster::MDSAdapter;
use Sys::Hostname::FQDN qw/short/;
use Try::Tiny;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has ctl => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::DashboardCtl->new(); },
);

has etcd => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::Etcd->new(); },
);

has mdsadapter => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::MDSAdapter->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub node_status
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__node_status($params->{argument}, $params->{entity});

    $self->render(json => $result);
}

sub procusage
{
    my $self   = shift;
    my $params = $self->req->json;

    my $limit
        = (!defined($params->{argument}->{Limit})
            || $params->{argument}->{Limit} eq '')
        ? 10
        : $params->{argument}->{Limit};
    my $interval
        = (!defined($params->{argument}->{Interval})
            || $params->{argument}->{Interval} eq '')
        ? 60
        : $params->{argument}->{Interval};

    my $tables = ['CpuStats'];

    push(@{$tables}, 'CpuStatsHour') if ($limit * $interval >= 86400);

    my @statistics = ();

    my $stat_ret = try
    {
        return $self->_get_statistics(
            result   => \@statistics,
            tables   => $tables,
            fields   => [qw/user system iowait total/],
            limit    => $limit,
            interval => $interval,
        );
    }
    catch
    {
        warn "[ERR] procusage: @_";
        return -1;
    };

    my $result = {is_available => $stat_ret < 0 ? 'false' : 'true',};

#    warn "[DEBUG] ${\$self->dumper($result)}";

    # 레이블링
    #   - 시작점 혹은 최종점일 경우 레이블링
    #   - 그 외에는 전체 개수의 1/5에 해당하는 지점마다 레이블링
    $self->ctl->__labeling(
        interval  => $interval,
        limit     => $limit,
        records   => \@statistics,
        fields    => [qw/User System IOWait/],
        converter => sub { $self->ctl->__convert_usage(@_); },
    );

    map { delete($_->{total}) if (exists($_->{total})); } @statistics;

    GMS::API::Return::api_status(level => 'INFO');

    if (@statistics == 2)
    {
        @statistics = ($statistics[0]);
    }

    $result->{data} = \@statistics;

    $self->render(json => $result);
}

sub fsusage
{
    my $self   = shift;
    my $params = $self->req->json;

    my $gvol_info
        = $self->etcd->get_key(key => '/GlusterFS/Brick', format => 'json');

    my @volumes = ();

    foreach my $brick (keys(%{$gvol_info}))
    {
        if ($gvol_info->{$brick}->{hostname} ne short()
            || $gvol_info->{$brick}->{volume_name} eq 'private')
        {
            delete($gvol_info->{$brick});
            next;
        }

        $gvol_info->{$brick}->{mount_path} =~ s/\/volume\///g;
        $gvol_info->{$brick}->{mount_path} =~ s/\//-/g;

        push(@volumes, $gvol_info->{$brick}->{mount_path});
    }

    my $lvol_info
        = $self->etcd->get_key(key => '/Volume/Local', format => 'json');

    foreach my $local_vol (keys(%{$lvol_info}))
    {
        push(@volumes, "$lvol_info->{$local_vol}->{pool_name}-$local_vol");
    }

    my $result = {};
    my @data   = ();

    $result->{is_available} = 'true';

    foreach my $vol (@volumes)
    {
        my $usage = $self->mdsadapter->execute_dbi(
            db      => 'girasole',
            table   => 'FsUsage',
            rs_func => 'search',
            rs_cond => {
                -and => [
                    scope => {'=' => $params->{Scope}},
                    name  => {'=' => $vol}
                ],
            },
            rs_attr => {
                order_by     => {-desc => 'time'},
                limit        => 1,
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            },
            func => 'first'
        );

        next if (!defined($usage));

        $vol =~ s/^[^-]+.//;

        push(
            @data,
            {
                key   => $vol,
                Using => $usage->{bused},
                Free  => $usage->{btotal} - $usage->{bused},
            }
        );
    }

    $result->{is_available} = 'false' if (!scalar(@data));

    GMS::API::Return::api_status(level => 'INFO');

    $result->{data} = \@data;

    $self->render(json => $result);
}

sub fsstats
{
    my $self   = shift;
    my $params = $self->req->json;

    my $limit
        = (!defined($params->{argument}->{Limit})
            || $params->{argument}->{Limit} eq '')
        ? 10
        : $params->{argument}->{Limit};
    my $interval
        = (!defined($params->{argument}->{Interval})
            || $params->{argument}->{Interval} eq '')
        ? 60
        : $params->{argument}->{Interval};
    my $tables = ['FsStats'];

    push(@{$tables}, 'FsStatsHour') if ($limit * $interval >= 86400);

    my @statistics = ();

    my $stat_ret = try
    {
        return $self->_get_statistics(
            result   => \@statistics,
            tables   => $tables,
            fields   => [qw/fs_read fs_write/],
            limit    => $limit,
            interval => $interval,
        );
    }
    catch
    {
        warn "[ERR] fsstats: @_";
        return -1;
    };

    my $result = {is_available => $stat_ret < 0 ? 'false' : 'true',};

    foreach my $r (@statistics)
    {
        $r->{read}  = (delete($r->{fs_read})  // 0) / $interval;
        $r->{write} = (delete($r->{fs_write}) // 0) / $interval;
    }

#    warn "[DEBUG] ${\$self->dumper($result)}";

    # 레이블링
    #   - 시작점 혹은 최종점일 경우 레이블링
    #   - 그 외에는 전체 개수의 1/5에 해당하는 지점마다 레이블링
    $self->ctl->__labeling(
        interval => $interval,
        limit    => $limit,
        records  => \@statistics,
        fields   => [qw/Read Write/],

        #converter => sub { $self->ctl->__convert_byte_stats(@_); },
    );

    GMS::API::Return::api_status(level => 'INFO');

    if (@statistics == 2)
    {
        @statistics = ($statistics[0]);
    }

    $result->{data} = \@statistics;
    $self->render(json => $result);
}

sub netstats
{
    my $self   = shift;
    my $params = $self->req->json;

    my $limit
        = (!defined($params->{argument}->{Limit})
            || $params->{argument}->{Limit} eq '')
        ? 10
        : $params->{argument}->{Limit};
    my $interval
        = (!defined($params->{argument}->{Interval})
            || $params->{argument}->{Interval} eq '')
        ? 60
        : $params->{argument}->{Interval};

    my $tables = ['NetStats'];

    push(@{$tables}, 'NetStatsHour') if ($limit * $interval >= 86400);

    my @statistics = ();

    my $stat_ret = try
    {
        return $self->_get_statistics(
            result   => \@statistics,
            tables   => $tables,
            fields   => [qw/send recv/],
            limit    => $limit,
            interval => $interval,
        );
    }
    catch
    {
        warn "[ERR] netstats: @_";
        return -1;
    };

    my $result = {is_available => $stat_ret < 0 ? 'false' : 'true',};

    foreach my $r (@statistics)
    {
        $r->{send} /= $interval;
        $r->{recv} /= $interval;
    }

#    warn "[DEBUG] ${\$self->dumper($result)}";

    # 레이블링
    #   - 시작점 혹은 최종점일 경우 레이블링
    #   - 그 외에는 전체 개수의 1/5에 해당하는 지점마다 레이블링
    $self->ctl->__labeling(
        interval => $interval,
        limit    => $limit,
        records  => \@statistics,
        fields   => [qw/Send Recv/],

        #converter => sub { $self->ctl->__convert_byte_stats(@_); },
    );

    GMS::API::Return::api_status(level => 'INFO');

    if (@statistics == 2)
    {
        @statistics = ($statistics[0]);
    }

    $result->{data} = \@statistics;

    $self->render(json => $result);
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _get_statistics
{
    my $self = (@_ % 2) ? shift : undef;
    my %args = @_;

    $args{limit}++ if ($args{limit} == 1);

    my $statistiker = Girasole::Analyzer::Stats->new(
        tables   => $args{tables},
        fields   => $args{fields},
        limit    => $args{limit},
        interval => $args{interval},
    );

    my $scope = short();

    my $categorized = $statistiker->categorize(
        filters    => [{scope => $scope}],
        categories => [qw/name/]
    );

#    warn "[DEBUG] Categorized: ${\$self->dumper($categorized)}";

    if (!keys(%{$categorized}))
    {
        for (my $i = 0; $i < $statistiker->limit; $i++)
        {
            my %dummy = (
                time => $statistiker->begin + ($i * $statistiker->interval));

            map { $dummy{$_} = 0.0; } @{$args{fields}};

            push(@{$args{result}}, \%dummy);
        }

        return 1;
    }

    foreach my $name (keys(%{$categorized}))
    {
        my $records    = $categorized->{$name};
        my %dimensions = (scope => $scope, name => $name);

        # 구간 정규화
        my $normalized = $statistiker->normalize(
            records    => $records,
            dimensions => \%dimensions,
        );

#        warn "[INFO] Normalized: ${\$self->dumper($normalized)}";

        $statistiker->calc_delta(
            records => $records,
            result  => $args{result}
        );
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Dashboard - 대시보드 API를 구현하는 컨트롤러

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

