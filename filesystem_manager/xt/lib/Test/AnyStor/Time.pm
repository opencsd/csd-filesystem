package Test::AnyStor::Time;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::Most;

extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub _wait_event
{
    sleep 10;
}

sub time_config
{
    my $self = shift;
    my %args = @_;

    my $DateTime     = $args{DateTime}          // '';
    my $NTP_Itv_Hour = $args{NTP_Interval_Hour} // 0;
    my $NTP_Enabled  = $args{NTP_Enabled}       // 'true';
    my $NTP_Itv_DOW  = $args{NTP_Itv_DOW}       // [];
    my $TimeZone     = $args{TimeZone}          // 'Asia/Seoul';
    my $NTP_Itv_Min  = $args{NTP_Interval_Min}  // 0;
    my $NTP_Svrs     = $args{NTP_Servers}       // [
        '0.centos.pool.ntp.org',
        '1.centos.pool.ntp.org',
        '2.centos.pool.ntp.org',
        '3.centos.pool.ntp.org'
    ];

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (
        DateTime          => $DateTime,
        TimeZone          => $TimeZone,
        NTP_Interval_Hour => $NTP_Itv_Hour,
        NTP_Interval_Min  => $NTP_Itv_Min,
        NTP_Interval_DOW  => $NTP_Itv_DOW,
        NTP_Enabled       => $NTP_Enabled,
        NTP_Servers       => $NTP_Svrs,
    );

    my $res = $self->call_rest_api('cluster/system/time/config', \%base_args,
        \%entity, \%ext_args);

    # is registed event
    #    _wait_event();
    #    ok(
    #        $self->is_matched_exist_in_recent_events(
    #            Code => 'TIME_CONFIG_OK',
    #        ),
    #        "'TIME_CONFIG_OK' event check"
    #    );

    diag(explain($res))
        if ($res->{stage_info}{stage} ne 'running');

    return $res->{success};
}

sub time_info
{
    my $self      = shift;
    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    my $res = $self->call_rest_api('cluster/system/time/info', \%base_args,
        \%entity, \%ext_args);

    diag(explain($res))
        if ($res->{stage_info}{stage} ne 'running');

    return $res->{entity};
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Time - 클러스터 시간 설정에 관련된 라이브러리

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
