package GMS::Controller::Power;

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
sub shutdown
{
    my $self   = shift;
    my $params = $self->req->json;

    my $timeout = $params->{timeout} // 'now';

    if ($timeout eq 'now')
    {
        $timeout = 1;
    }

    my $rv = GMS::Common::IPC::exec(
        cmd  => 'shutdown',
        args => ['-h', $timeout]
    );

    if (!defined($rv) || $rv->{status})
    {
        warn sprintf('[ERR] External command error: %s: %s',
            $rv->{cmd}, $self->dumper($rv));

        $self->throw_error(message => 'Failed to shutdown');
    }

    api_status(
        level   => 'INFO',
        code    => SYSTEM_SHUTDOWN_SUCCESS,
        msgargs => [host => short()],
    );

    $self->publish_event();

    $self->stash(status => 204, json => undef);
}

sub reboot
{
    my $self   = shift;
    my $params = $self->req->json;

    my $timeout = $params->{timeout} // 'now';

    if ($timeout eq 'now')
    {
        $timeout = 1;
    }

    my $rv = GMS::Common::IPC::exec(
        cmd  => 'shutdown',
        args => ['-r', $timeout]
    );

    if (!defined($rv) || $rv->{status})
    {
        warn sprintf('[ERR] External command error: %s: %s',
            $rv->{cmd}, $self->dumper($rv));

        $self->throw_error(message => 'Failed to reboot');
    }

    api_status(
        level   => 'INFO',
        code    => SYSTEM_REBOOT_SUCCESS,
        msgargs => [host => short()],
    );

    $self->publish_event();

    $self->stash(status => 204, json => undef);
}

sub cancel
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = GMS::Common::IPC::exec(cmd => 'shutdown', args => ['-c']);

    if (!defined($rv) || $rv->{status})
    {
        warn sprintf('[ERR] External command error: %s: %s',
            $rv->{cmd}, $self->dumper($rv));

        $self->throw_error(message => 'Failed to cancel power operation');
    }

    api_status(
        level   => 'INFO',
        code    => SYSTEM_POWER_CANCELED,
        msgargs => [host => short()],
    );

    $self->publish_event();

    $self->stash(status => 204, json => undef);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Power - GMS API Controller for system power management

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

