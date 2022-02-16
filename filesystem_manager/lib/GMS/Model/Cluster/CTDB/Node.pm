package GMS::Model::Cluster::CTDB::Node;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Network::Type qw/prefix_to_netmask/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/Cluster/CTDB/Node'; };
etcd_keygen sub { name => shift; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'ipaddr' => (
    is       => 'rw',
    isa      => 'GMS::Network::Type::IP',
    required => 1,
);

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->meta->set_key(
        sprintf('%s/%s/name', $self->meta->etcd_root, $self->name),
        $self->name);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Cluster::CTDB::Node - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

