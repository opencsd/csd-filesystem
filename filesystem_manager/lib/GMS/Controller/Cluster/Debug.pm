package GMS::Controller::Cluster::Debug;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Fcntl qw(:flock);
use GMS::API::Return qw(:LEVEL :DEBUG api_status);
use GMS::Cluster::MDSAdapter;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'mds' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::MDSAdapter->new(); },
);

has 'etcd' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::Etcd->new(); },
);

has 'event_log_file' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '/var/log/gms/event.log'; },
);

has 'scopes' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub
    {
        my $self  = shift;
        my $debug = $self->etcd->ls(key => '/Cluster/Meta/debug');

        if (ref($debug) ne 'ARRAY')
        {
            warn '[ERR] Failed to get debug setting';
            return;
        }

        return $debug;
    }
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub set_debug
{
    my $self   = shift;
    my $params = $self->req->json;

    if (!defined($params->{scope}))
    {
        $self->throw_exception(
            'InvalidParameter',
            param => 'scope',
            value => $params->{scope},
        );
    }

    if (!scalar(grep { $_ eq $params->{scope}; } @{$self->scopes}))
    {
        api_status(
            level   => 'ERR',
            code    => DEBUG_SET_FAILURE,
            msgargs => [scope => $params->{scope}],
        );

        $self->throw_error(
            message => "Invalid debug scope: $params->{scope}");
    }

    my $value = ($params->{value} =~ m/^(1|yes|enable)$/i) ? 1 : 0;

    if (
        $self->etcd->set_key(
            key   => "/Cluster/Meta/debug/$params->{scope}",
            value => $value,
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /Cluster/Meta/debug/$params->{scope}");
    }

    api_status(
        level   => 'INFO',
        code    => DEBUG_SET_OK,
        msgargs => [scope => $params->{scope}],
    );

    $self->render(json => {$params->{scope} => $value});
}

sub get_debug
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result;

    if (exists($params->{scope})
        && !scalar(grep { $_ eq $params->{scope}; } @{$self->scopes}))
    {
        api_status(
            level   => 'ERR',
            code    => DEBUG_GET_FAILURE,
            msgargs => [scope => $params->{scope}],
        );

        $self->throw_error("Invalid debug scope: $params->{scope}");
    }

    if ($params->{scope})
    {
        my $value = $self->etcd->get_key(
            key => "/Cluster/Meta/debug/$params->{scope}");

        $result->{$params->{scope}} = $value;
    }
    else
    {
        $result = $self->etcd->get_key(
            key     => '/Cluster/Meta/debug',
            options => {recursive => 1},
        );
    }

    api_status(
        level   => 'INFO',
        code    => DEBUG_GET_OK,
        msgargs => [scope => $params->{scope}],
    );

    $self->render(json => $result);
}

sub validate_event
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = {
        total   => 0,     # 전체 개수
        valid   => [],    # 일치 목록
        invalid => [],    # 불일치 목록
    };

    # /var/log/gms/event.log 파일 열기
    open(my $fh, -f $self->event_log_file ? '+<' : '>', $self->event_log_file)
        || die "Failed to open file: ${\$self->event_log_file}: $!";

    if (!defined($fh))
    {
        warn "[ERR] Failed to open log file: ${\$self->event_log_file}: $!";

        api_status(
            level => GMS_LV_ERR,
            code  => DEBUG_EVENT_VALIDATE_FAILURE,
        );

        goto RETURN;
    }

    if (!flock($fh, LOCK_EX))
    {
        warn "[ERR] Failed to lock log file: ${\$self->event_log_file}: $!";

        api_status(
            level => GMS_LV_ERR,
            code  => DEBUG_EVENT_VALIDATE_FAILURE,
        );

        goto RETURN;
    }

    my @events;

    while (my $line = <$fh>)
    {
        chomp($line);

        my %event;

        @event{qw/time scope code/} = split(/\|/, $line);

        next if ($event{code} =~ m/^(SIGNED|CLST_INIT)/);

        push(@events, \%event);
    }

    close($fh);

    $result->{total} = scalar(@events);

    @events = sort { $a->{time} <=> $b->{time}; } @events;

    # girasole.events 테이블 열어서 비교하여 결과 반환
    my $rs = $self->mds->execute_dbi(
        db      => 'girasole',
        table   => 'Events',
        rs_func => 'search',
        rs_attr => {
            order_by     => {-desc => 'time'},
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        },
        func => 'all'
    );

    foreach my $event (@events)
    {
        my $found = undef;

        foreach my $e (@{$rs})
        {
            if ($event->{time} == $e->{time}
                && $event->{scope} eq $e->{scope}
                && $event->{code} eq $e->{code})
            {
                $found = $e;
                last;
            }
        }

        if (defined($found))
        {
            push(@{$result->{valid}}, $event);
        }
        else
        {
            push(@{$result->{invalid}}, $event);
        }
    }

    api_status(
        level => GMS_LV_INFO,
        code  => DEBUG_EVENT_VALIDATE_OK,
    );

RETURN:
    $self->render(json => $result);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Debug - 디버깅을 위한 API 구현

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

