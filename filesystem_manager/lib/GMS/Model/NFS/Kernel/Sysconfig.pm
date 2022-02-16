package GMS::Model::NFS::Kernel::Sysconfig;

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
extends 'GMS::Model::Base', 'GMS::NFS::Kernel::Sysconfig';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/NFS/Kernel'; };
etcd_keygen sub { name => 'Sysconfig'; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'find_or_create' => sub
{
    my $orig = shift;
    my $self = shift;

    return $self->$orig('Sysconfig');
};

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::NFS::Kernel::Sysconfig - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

