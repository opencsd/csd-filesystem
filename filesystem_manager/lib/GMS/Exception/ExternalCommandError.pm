package GMS::Exception::ExternalCommandError;

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
        my $self = shift;

        return sprintf('External command error: %s', $self->result->{cmd});
    },
);

has 'result' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Exception::ExternalCommandError - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

