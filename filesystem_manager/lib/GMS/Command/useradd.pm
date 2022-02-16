package GMS::Command::useradd;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Guard;
use Mojo::Util qw/getopt/;

use GMS::API::Return;
use GMS::Cluster::Etcd;
use GMS::Auth::PAM::PWQuality;

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
    default => 'Add a user',
);

has usage => (
    is      => 'ro',
    isa     => 'Str',
    default => <<"EOL",
Usage: $0 useradd [OPTIONS]

  $0 useradd [OPTIONS]

Options:
  --id              The id of the user
  -n, --name        The name of the user
  -p, --password    The password of the user
  -g, --group       The group name to be joined
  -v, --verbose     Print additional details

EOL
);

has 'etcd' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { GMS::Cluster::Etcd->new(); },
);

has 'pwquality' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Auth::PAM::PWQuality->new(); },
);

has 'ctl' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Account::AccountCtl->new(); },
);

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::Cluster::Account';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my @args = @_;

    my %user = (
        uid      => '',
        name     => '',
        groups   => [],
        password => '',
    );

    my $verbose = '';

    getopt(
        \@args,
        'n|name=s'     => \$user{name},
        'p|password=s' => \$user{password},
        'g|group:s@'   => \$user{groups},
        'v|verbose'    => \$verbose,
    );

    if ($user{password}
        && $self->pwquality->is_valid_passwd(passwd => $user{password}))
    {
        $self->throw_error(
            'Password is not satisified with pwquality policy');
    }

    $self->app->gms_lock(scope => 'Account/User', owner => $$);

    scope_guard
    {
        $self->app->gms_unlock(scope => 'Account/User', owner => $$);
    };

    $self->ctl->user_create(
        argument => {
            Location => 'LOCAL',
        },
        entity => {
            User_Name     => $user{name},
            User_Password => $user{password},
            User_Groups   => $user{groups},
        }
    );

    my @statuses = all_api_statuses();

    my $warn = 0;
    my $err  = 0;

    foreach my $status (@statuses)
    {
        if ($status->{level} =~ m/^WARN/)
        {
            $warn++;
            print STDERR "$status->{message}\n";
        }
        elsif ($status->{level} =~ m/^ERR/)
        {
            $err++;
            print STDERR "$status->{message}\n";
        }
    }

    die "Failed to create the user: $user{name}\n" if ($err);

    $self->update_user_data($user{name});

    print STDOUT "$statuses[$#statuses]->{message}\n";

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Command::useradd - add a user

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

