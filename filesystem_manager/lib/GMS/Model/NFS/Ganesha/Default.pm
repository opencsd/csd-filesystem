package GMS::Model::NFS::Ganesha::Default;

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
extends 'GMS::Model::Base', 'GMS::NFS::Ganesha::Default';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/NFS/Ganesha'; };
etcd_keygen sub { name => 'Default'; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
upgrade_attrs(
    key      => 'name',
    excludes => [
        GMS::NFS::Ganesha::Configurable->meta->get_attribute_list,
        GMS::NFS::Ganesha::Block->meta->get_attribute_list,
    ],
);

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'to_hash' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    $args{camelcase} = 1;
    $args{underbar}  = 1;

    return $self->$orig(%args);
};

# :WARNING 08/02/2019 01:31:54 AM: by P.G.
# For now, we need to override find()/find_or_create() methods of each
# config model to pass 'key' parameter
around 'find' => sub
{
    my $orig = shift;
    my $self = shift;

    return $self->$orig('Default');
};

around 'find_or_create' => sub
{
    my $orig = shift;
    my $self = shift;

    return $self->$orig('Default');
};

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::NFS::Ganesha::Default - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

