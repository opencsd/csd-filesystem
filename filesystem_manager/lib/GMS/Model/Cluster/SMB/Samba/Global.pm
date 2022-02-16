package GMS::Model::Cluster::SMB::Samba::Global;

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
extends 'GMS::Model::SMB::Samba::Global';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/Cluster/SMB/Samba'; };
etcd_keygen sub { name => 'global' };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '+global_pkg' => (default => 'GMS::Model::Cluster::SMB::Samba::Global',);

has '+section_pkg' =>
    (default => 'GMS::Model::Cluster::SMB::Samba::Section',);

# :TODO 07/22/2019 11:23:08 PM: by P.G.
# lazy evaluation of etcd_root for removing duplicated attrs overriding
upgrade_attrs(
    key      => 'name',
    excludes => [GMS::SMB::Samba::Configurator->meta->get_attribute_list,],
);

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Cluster::SMB::Samba::Global - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

