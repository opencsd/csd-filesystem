package GMS::Command;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use MouseX::Foreign;
use namespace::clean -except => 'meta';

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'Mojolicious::Command';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::Exceptionable';

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILDARGS
{
    my $class = shift;
    return Mojo::Base->new(@_);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Command - Base class for GMS command

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

