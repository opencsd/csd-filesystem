package GMS::Controller::Time;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use POSIX qw/strftime/;
use Sys::Hostname::FQDN qw/short/;

use GMS::API::Return;
use GMS::Common::IPC;
use GMS::System::Time;
use GMS::System::NTP;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub continents
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = GMS::System::Time::all_continents();

    if (ref($rv) ne 'ARRAY' || !@{$rv})
    {
        $self->throw_error(message => 'Failed to get continents');
    }

    api_status(
        level => 'INFO',
        code  => TIME_CONTINENTS_OK,
    );

RETURN:
    $self->render(json => $rv);
}

sub timezones
{
    my $self   = shift;
    my $params = $self->req->json;

    my @rv = ();

    my $continent = $params->{Continent};
    my $timezones = GMS::System::Time::all_timezones($continent);

    if (ref($timezones) ne 'ARRAY' || scalar(@{$timezones}) == 0)
    {
        $self->throw_error(message => 'Failed to get timezones');
    }

    for (my $i = 0; $i < @{$timezones}; $i++)
    {
        push(
            @rv,
            {
                Offset => sprintf('(UTC%s %s)',
                    $timezones->[$i]->{offset},
                    $timezones->[$i]->{timezone}),
                Timezone => $timezones->[$i]->{timezone},
            }
        );
    }

    my $sorter = sub
    {
        my ($a, $b) = @_;

        my $a_hour = int(substr($a->{Offset}, 4, 3));
        my $b_hour = int(substr($b->{Offset}, 4, 3));
        my $a_min  = int(substr($a->{Offset}, 8, 2));
        my $b_min  = int(substr($b->{Offset}, 8, 2));

        $a_hour <=> $b_hour || $a_min <=> $b_min;
    };

    @rv = sort { $sorter->($a, $b); } @rv;

    api_status(
        level => 'INFO',
        code  => TIME_TZS_OK,
    );

RETURN:
    $self->render(json => \@rv);
}

sub info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $tz  = GMS::System::Time::get_timezone();
    my $ntp = GMS::System::NTP->new();

    my %rv = (
        Timezone    => $tz,
        Datetime    => strftime('%Y-%m-%d %H:%M:%S', localtime()),
        NTP_Enabled => $ntp->public,
        NTP_Servers => join(',', @{$ntp->ntp_servers}),
        NTP_Master  => $ntp->ntp_master,

        # Dummy
        NTP_Interval_DOW  => [],
        NTP_Interval_Hour => 0,
        NTP_Interval_Min  => 0,
    );

    api_status(
        level => 'INFO',
        code  => TIME_GET_INFO_OK
    );

    $self->render(json => \%rv);
}

sub config
{
    my $self   = shift;
    my $params = $self->req->json;

    my $timezone = $params->{Timezone};

    if (GMS::System::Time::set_timezone($timezone))
    {
        $self->throw_error(message => 'Failed to set timezone');
    }

    # allow to set either with local time or NTP time.
    if (defined($params->{NTP_Enabled})
        && lc($params->{NTP_Enabled}) eq 'true')
    {
        if (GMS::System::Time::set_ntp_servers(
            public      => $params->{NTP_Enabled},
            ntp_servers => $params->{NTP_Servers}
        ))
        {
            $self->throw_error(message => "Failed to configure NTP server");
        }
    }
    else
    {
        my $datetime = $params->{Datetime};

        if (GMS::System::Time::set_datetime($datetime))
        {
            $self->throw_error(message => "Failed to configure datetime");
        }
    }

    api_status(
        level => 'INFO',
        code  => TIME_CONFIG_OK
    );

    $self->render(status => 204, json => undef);
}

sub test
{
    my $self   = shift;
    my $params = $self->req->json;

    foreach my $server (@{$params->{NTP_Servers}})
    {
        my $rv = GMS::Common::IPC::exec(cmd => 'ntpdate', args => $server);

        if (!defined($rv) || $rv->{status})
        {
            $self->throw_error(
                message => "Failed to communicate with NTP Server: $server");
        }
    }

    $self->render(status => 204, json => undef);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Time - GMS API Controller for system time management

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

