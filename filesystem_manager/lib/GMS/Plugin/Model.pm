package GMS::Plugin::Model;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

#---------------------------------------------------------------------------
#   Inheritacnes
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'model' => (
    is  => 'ro',
    isa => 'HashRef',
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Plugin::Model - Model helper plugin for GMS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONTRIBUTORS

Ji-Hyeon Gim <potatogim@gluesys.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
