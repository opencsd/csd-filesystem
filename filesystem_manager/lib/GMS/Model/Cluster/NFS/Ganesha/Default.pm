package GMS::Model::Cluster::NFS::Ganesha::Default;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Sys::Hostname::FQDN qw/short/;

use GMS::Model;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::NFS::Ganesha::Default';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/Cluster/NFS/Ganesha'; };
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

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Cluster::NFS::Ganesha::Default - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

