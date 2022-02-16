package GMS::Model::Network::Zone;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base', 'GMS::Network::Zone';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/Network/Zone'; };
etcd_keygen sub { name => shift; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
upgrade_attrs(key => 'name');

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'update' => sub
{
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self->store_to_file(
        path => $self->config_file,
        name => $self->name,
        data => $self->_to_hash,
    );

    return $self;
};

around 'destroy' => sub
{
    my $orig = shift;
    my $self = shift;

    my $name = $self->name;

    my $retval = $self->$orig(@_);

    $self->delete($self->name);

    return $retval;
};

around 'to_hash' => sub
{
    my $orig = shift;
    my $self = shift;

    my $retval = $self->$orig(@_);

    return {
        Name   => $retval->{name},
        Desc   => $retval->{desc},
        Type   => $retval->{type},
        Addrs  => $retval->{addrs},
        Range  => $retval->{range},
        CIDR   => $retval->{cidr},
        Domain => $retval->{domain},
    };
};

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

GMS::Model::Network::Zone - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

