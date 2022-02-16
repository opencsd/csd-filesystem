package GMS::Plugin;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use MouseX::Foreign;
use namespace::clean -except => 'meta';

use Scalar::Util qw(blessed);
use Data::Dumper;

#---------------------------------------------------------------------------
#   Inheritacnes
#---------------------------------------------------------------------------
extends 'Mojolicious::Plugin';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub dumper
{
    my $self = shift;

    Dumper(@_);
}

after 'register' => sub
{
    my ($self, $app, $conf) = @_;

    warn "[INFO] ${\blessed($self)} plugin is registered";

    return;
};

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

GMS::Plugin - Base class for GMS plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
