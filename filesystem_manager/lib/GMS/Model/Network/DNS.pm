package GMS::Model::Network::DNS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Network::DNS;

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/Network/DNS'; };

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base', 'GMS::Network::DNS';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'build_entries' => sub
{
    my $self = shift;

    tie(my %nodes, 'GMS::Tie::Etcd',
        root => sprintf('%s', $self->meta->etcd_root));

    %nodes = super();

    return \%nodes;
};

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
sub update
{
    my $self = shift;

    die 'Failed to clear DNS entries'
        if (!defined($self->clear_entries()));

    my $priority = 0;

    foreach my $entry (@_)
    {
        next if ($entry eq '');

        die "Failed to add DNS entry: $entry"
            if (!$self->add_entry(
            addr     => $entry,
            priority => $priority++
            ));
    }

    my @entries
        = map { {IPAddr => $_->[0]}; }
        (sort { $a->[1]->{priority} <=> $b->[1]->{priority} }
            $self->all_entries);

    return wantarray ? @entries : \@entries;
}

#---------------------------------------------------------------------------
#   Contructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->_write_resolv();
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Network::DNS - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

