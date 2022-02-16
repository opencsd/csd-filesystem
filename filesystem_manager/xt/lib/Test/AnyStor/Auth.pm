package Test::AnyStor::Auth;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';
use Test::Most;
use Test::AnyStor::Base;
use Data::Dumper;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub ads_enable
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (
        ADS_Realm => $args{realm},
        ADS_DCs   => $args{dcs},
        ADS_Admin => $args{admin},
        ADS_Pwd   => $args{pwd},
    );

    my $res = $self->call_rest_api('cluster/auth/ads/enable', \%base_args,
        \%entity, \%ext_args);

    if (!$self->t->success)
    {
        paint_err();
        fail('Failed to enable ADS authentication');
        paint_reset();
        return -1;
    }

    return 0;
}

sub ads_disable
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (
        ADS_Admin => $args{admin},
        ADS_Pwd   => $args{pwd},
    );

    my $res = $self->call_rest_api('cluster/auth/ads/disable', \%base_args,
        \%entity, \%ext_args);

    if (!$self->t->success)
    {
        paint_err();
        fail('Failed to disable ADS authentication');
        paint_reset();
        return -1;
    }

    return 0;
}

sub ldap_enable
{
    my $self = shift;
    my %args = @_;

    my $res = $self->call_rest_api('cluster/auth/ldap/enable',
        undef, $args{entity}, undef);

    if (!$self->t->success)
    {
        paint_err();
        fail('Failed to enable LDAP authentication');
        paint_reset();
        return -1;
    }

    return 0;
}

sub ldap_disable
{
    my $self = shift;
    my %args = @_;

    my %entity = ();

    my $res = $self->call_rest_api('cluster/auth/ldap/disable',
        undef, \%entity, undef);

    if (!$self->t->success)
    {
        paint_err();
        fail('Failed to disable LDAP authentication');
        paint_reset();
        return -1;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Test::AnyStor::Account - 계정 검사를 구현하는 클래스

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

