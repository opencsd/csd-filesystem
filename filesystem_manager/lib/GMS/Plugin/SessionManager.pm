package GMS::Plugin::SessionManager;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Cluster::Etcd;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'etcd' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { GMS::Cluster::Etcd->new(); },
);

has 'latest_update' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

has 'expiration' => (
    is      => 'ro',
    isa     => 'Int',
    default => 3600,
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub register
{
    my ($self, $app, $args) = @_;

    $app->helper(get_session   => sub { $self->_get_session(@_); });
    $app->helper(set_session   => sub { $self->_set_session(@_); });
    $app->helper(unset_session => sub { $self->_unset_session(@_); });

    return;
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _get_session
{
    my $self = shift;
    my $c    = shift;
    my %args = @_;

    map {
        if (!(defined($args{$_}) && length($args{$_})))
        {
            warn "[WARN] Failed to get session: Invalid parameter: $_";
            return;
        }
    } qw/id/;

    my $sessions = $self->etcd->get_key(
        key    => '/Sessions',
        format => 'json',
    );

    return if (!(defined($sessions) && ref($sessions) eq 'HASH'));

    my $found   = undef;
    my $updated = 0;

    foreach my $sid (keys(%{$sessions}))
    {
        my $expires = $sessions->{$sid}->{expires};

        # 세션 삭제
        #   - 만료 기한이 정의되지 않은 세션
        #   - 만료 기한을 초과한 세션
        if (!defined($expires) || $expires <= time)
        {
            $updated++;
            delete($sessions->{$sid});
            next;
        }

        $found = $sessions->{$sid} if ($args{id} eq $sid);
    }

    if ($updated)
    {
        if (
            $self->etcd->set_key(
                key    => '/Session',
                value  => $sessions,
                format => 'json',
            ) <= 0
            )
        {
            warn '[WARN] Failed to update session';
        }
    }

    return $found;
}

sub _set_session
{
    my $self = shift;
    my $c    = shift;
    my %args = @_;

    map {
        if (!(defined($args{$_}) && length($args{$_})))
        {
            warn "[WARN] Invalid parameter: $_";
            return -1;
        }
    } qw/id/;

    my $sessions = $self->etcd->get_key(
        key    => '/Sessions',
        format => 'json',
    );

    if (!defined($sessions->{$args{id}}))
    {
        $sessions->{$args{id}} = {};
    }

    my $sess = $sessions->{$args{id}};

    # update the session
    map { $sess->{$_} = $args{$_} if (defined($args{$_})); }
        grep { $_ ne 'id'; } keys(%args);

    # renew the expiration time of the session
    $sess->{expires} = time + $self->expiration;

    if (
        $self->etcd->set_key(
            key    => '/Session',
            value  => $sessions,
            format => 'json',
        ) <= 0
        )
    {
        warn '[WARN] Failed to set session into etcd';
        return -1;
    }

    # Mojo 세션 갱신
    #$c->session($sess);

    return 0;
}

sub _unset_session
{
    my $self = shift;
    my $c    = shift;
    my %args = @_;

    map {
        if (!(defined($args{$_}) && length($args{$_})))
        {
            warn "[WARN] Failed to unset session: Invalid parameter: $_";
            return -1;
        }
    } qw/id/;

    my $sessions = $self->etcd->get_key(
        key    => '/Sessions',
        format => 'json',
    );

    if (defined($sessions->{$args{id}}))
    {
        delete($sessions->{$args{id}});

        if (
            $self->etcd->set_key(
                key    => '/Session',
                value  => $sessions,
                format => 'json',
            ) <= 0
            )
        {
            warn '[WARN] Failed to unset session into etcd';
            return -1;
        }
    }

    #$c->session(expires => 1);

    return 0;
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::SessionManager - GMS plugin to support server-side-session

=head1 SYNOPSIS

This plugin provides server-side-session with etcd for GMS.

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

