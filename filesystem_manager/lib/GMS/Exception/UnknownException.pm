package GMS::Exception::UnknownException;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Exception::Base';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '+message' => (
    lazy    => 1,
    default => sub
    {
        my $class = shift->class;

        $class =~ s/^GMS::Exception:://;

        return sprintf('Unknown exception class: %s', $class);
    },
);

has 'class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Exception::UnknownException - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

