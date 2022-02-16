package GMS::Exception::InvalidParameter;

use v5.14;

use strict;
use warnings;
use utf8;

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return qw/:COMMON/;

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

        return sprintf('Invalid parameter: %s is %s',
            $self->param, $self->value // 'undef');
    },
);

has '+status' => (default => 400,);

has '+code' => (default => INVALID_ENTITY,);

has 'param' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'value' => (
    is       => 'ro',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Exception::InvalidParameter - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

