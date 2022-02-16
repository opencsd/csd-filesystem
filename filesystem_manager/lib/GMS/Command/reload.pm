package GMS::Command::reload;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Module::Load;
use Module::Loaded;
use GMS::Common::OptArgs;
use GMS::Common::Logger;
use GMS::Cluster::Etcd;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Command';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has description => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Reload and update this system',
);

has usage => (
    is      => 'ro',
    isa     => 'Str',
    default => <<"EOL",
Usage: $0 reload [OPTIONS]

  $0 reload [OPTIONS]

Options:
  -v, --verbose

EOL
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my @args = @_;

    $|++;

    if (!-f '/var/lib/gms/initialized')
    {
        print 'GMS not yet initialized';
        return 0;
    }

    $self->reload_host();
    $self->reload_route();
    $self->reload_dns();
    $self->reload_ntp();
    $self->reload_groups();
    $self->reload_users();
    $self->reload_volume();
    $self->reload_license();

    return 0;
}

sub reload_groups
{
    my $self = shift;
    my %args = @_;

    !is_loaded('GMS::Account::AccountCtl')
        && load('GMS::Account::AccountCtl');

    my $handle = GMS::Account::AccountCtl->new();

    print 'Reloading group data...';

    my $etcd = GMS::Cluster::Etcd->new();

    my $groups = $etcd->get_key(
        key    => '/Groups',
        format => 'json',
    );

    if ($handle->group_reload(data => $groups))
    {
        print "\t[Failure]\n";
        return 1;
    }

    print "\t[OK]\n";
    return 0;
}

sub reload_users
{
    my $self = shift;
    my %args = @_;

    !is_loaded('GMS::Account::AccountCtl')
        && load('GMS::Account::AccountCtl');

    my $handle = GMS::Account::AccountCtl->new();

    print 'Reloading user data...';

    my $etcd = GMS::Cluster::Etcd->new();

    my $users = $etcd->get_key(key => '/Users', format => 'json');

    if ($handle->user_reload(data => $users))
    {
        print "\t[Failure]\n";
        return 1;
    }

    print "\t[OK]\n";
    return 0;
}

sub reload_dns
{
    my $self = shift;
    my %args = @_;

    my $pkg = 'GMS::Model::Cluster::Network::DNS';

    !is_loaded($pkg) && load($pkg);

    print 'Reloading DNS...';

    my $model = $pkg->new();

    if (!defined($model))
    {
        print "\t[Failure]\n";
        return 1;
    }

    print "\t[OK]\n";
    return 0;
}

sub reload_host
{
    my $self = shift;
    my %args = @_;

    my $pkg = 'GMS::Model::Cluster::Network::Hosts';

    !is_loaded($pkg) && load($pkg);

    print 'Reloading hosts...';

    foreach my $ipaddr ($pkg->list())
    {
        my $model = $pkg->find($ipaddr);

        if (!defined($model))
        {
            print "\t[Failure]\n";
            return 1;
        }
    }

    print "\t[OK]\n";
    return 0;
}

sub reload_license
{
    my $self = shift;
    my %args = @_;

    !is_loaded('GMS::System::License') && load('GMS::System::License');

    my $handle = GMS::System::License->new();

    print 'Reloading GMS license...';

    if (!$handle->reload_license())
    {
        print "\t[Failure]\n";
        return 1;
    }

    print "\t[OK]\n";
    return 0;
}

sub reload_ntp
{
    my $self = shift;
    my %args = @_;

    !is_loaded('GMS::System::NTP') && load('GMS::System::NTP');

    my $handle = GMS::System::NTP->new();

    print 'Reloading NTP config...';

    if ($handle->reload())
    {
        print "\t[Failure]\n";
        return 1;
    }

    print "\t[OK]\n";
    return 0;
}

sub reload_route
{
    my $self = shift;
    my %args = @_;

    my $pkg = 'GMS::Model::Cluster::Network::Route';

    !is_loaded($pkg) && load($pkg);

    print 'Reloading network routing...';

    my $model = $pkg->new();

    if (!defined($model))
    {
        print "\t[Failure]\n";
        return 1;
    }

    print "\t[OK]\n";
    return 0;
}

sub reload_volume
{
    my $self = shift;
    my %args = @_;

    !is_loaded('GMS::Cluster::FSCtl') && load('GMS::Cluster::FSCtl');

    my $handle = GMS::Cluster::FSCtl->new();

    print 'Reloading cluster volumes...';

    if ($handle->__volume_reload({Pool_Type => 'ALL'}))
    {
        print "\t[Failure]\n";
        return 1;
    }

    print "\t[OK]\n";
    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Command::reload - Reload and update this system

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

