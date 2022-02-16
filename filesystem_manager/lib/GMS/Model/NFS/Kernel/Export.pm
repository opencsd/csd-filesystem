package GMS::Model::NFS::Kernel::Export;

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
extends 'GMS::Model::Base', 'GMS::NFS::Kernel::Export';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/NFS/Kernel/Export'; };
etcd_keygen sub { name => shift; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '_section_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/etc/exports.d',
);

upgrade_attrs(
    key      => 'name',
    excludes => ['config_dir'],
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

around 'delete' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $attr = $self->meta->find_attribute_by_name('config_dir');

    die 'Could not find attribute: config_dir'
        if (!defined($attr));

    $self->destroy();

    return $self->$orig($self->name);
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

GMS::Model::NFS::Kernel::Export - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

