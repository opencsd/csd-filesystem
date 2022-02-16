package Mock::Model::Network::Hosts;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use Sys::Hostname::FQDN qw/short/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Network::Hosts';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root GMS::Model::Network::Hosts->meta->etcd_root;
etcd_keygen GMS::Model::Network::Hosts->meta->etcd_keygen;

#---------------------------------------------------------------------------
#   Attributes Overriding
#---------------------------------------------------------------------------
has '+hosts_config' => (default => '/tmp/etc/hosts',);

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Mock::Model::Network::Hosts - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

