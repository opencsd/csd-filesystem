package GMS::Model::Cluster::FTP::ProFTPD::Config;

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
extends 'GMS::Model::FTP::ProFTPD::Config';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/Cluster/FTP/ProFTPD'; };
etcd_keygen sub { name => 'Default'; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
upgrade_attrs(
    key      => 'name',
    excludes => [],
);

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Cluster::FTP::ProFTPD::Config - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

