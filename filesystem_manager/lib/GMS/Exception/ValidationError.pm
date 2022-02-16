package GMS::Exception::ValidationError;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

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

        my $msg = '';

        foreach my $e (@{$self->errors})
        {
            $msg .= sprintf("%s\n", $e->{message});
        }

        return $msg;
    },
);

has '+status' => (default => 422,);

has '+code' => (default => VALIDATION_ERROR,);

has 'errors' => (
    is       => 'rw',
    isa      => 'ArrayRef',
    required => 1,
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub throw_hook
{
    my $self = shift;
    my %args = @_;

    foreach my $e (@{$self->errors})
    {
        my ($code, $msgargs);

        given ($e->{type})
        {
            when ('InvalidValue')
            {
                $code    = INVALID_VALUE;
                $msgargs = [name => $e->{name}];
            }
            when ('ExclusiveParameter')
            {
                $code    = EXCLUSIVE_PARAM;
                $msgargs = [name => $e->{name}, other => $e->{conflict}];
            }
            when ('SelectiveParameter')
            {
                $code    = SELECTIVE_PARAM;
                $msgargs = [
                    name   => $e->{name},
                    others => join(', ', @{$e->{others}})
                ];
            }
            when ('MissingParameter')
            {
                $code    = MISSING_PARAM;
                $msgargs = [name => $e->{name}];
            }
            when ('UnknownParameter')
            {
                $code    = UNKNOWN_PARAM;
                $msgargs = [name => $e->{name}];
            }
        }

        api_status(
            level    => $self->level,
            category => $self->category,
            code     => $code,
            msgargs  => $msgargs,
        );
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Exception::ValidationError - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

