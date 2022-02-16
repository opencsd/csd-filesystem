package GMS::Command::admin;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Mojo::Util qw/getopt/;

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
    default => 'Manage the admin user',
);

has usage => (
    is      => 'ro',
    isa     => 'Str',
    default => <<"EOL",
Usage: $0 admin [OPTIONS]

  $0 admin [OPTIONS]

Options:
  --id              The id of the administrator
  -n, --name        The name of the administrator
  -f, --force       Manage admin user forcibly
  -v, --verbose     Print additional details

EOL
);

has 'etcd' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { GMS::Cluster::Etcd->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub run
{
    my $self = shift;
    my @args = @_;

    my %admin = (
        ID           => 'admin',
        Name         => 'admin',
        Phone        => '010-0000-0000',
        Email        => 'admin@admin.com',
        Organization => 'Gluesys Co., Ltd.',
    );

    my %engineer = (
        Engineer      => 'Gluesys',
        EngineerPhone => '070-8787-5370',
        EngineerEmail => 'admin@gluesys.com',
    );

    my $force = '';

    getopt(
        \@args,
        'id=s'     => \$admin{ID},
        'n|name=s' => \$admin{Name},
        'f|force'  => \$force,
    );

    $|++;

    if (!$force && -f '/var/lib/gms/initialized')
    {
        print 'GMS already initialized';
        return 0;
    }

    my %managers = ($admin{Name} => {%admin, %engineer});

    if (!$self->etcd->set_key(
        key    => '/Manager',
        value  => \%managers,
        format => 'json',
    ))
    {
        $self->throw_error(
            "Failed to set manager setting: ${\$self->dumper(\%managers)}");
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Command::admin - Manage the GMS admin user

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

