package GMS::Exception::Base;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Devel::StackTrace;
use Sys::Hostname::FQDN qw/short/;

use overload '""' => 'stringify';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '_trace' => (
    is      => 'ro',
    isa     => 'Devel::StackTrace',
    reader  => 'trace',
    default => sub { Devel::StackTrace->new(); }
);

has 'status' => (
    is      => 'ro',
    isa     => 'Int',
    default => 500,
);

has 'message' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Base exception',
);

has 'details' => (
    is  => 'ro',
    isa => 'HashRef | Undef',
);

has 'category' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'GMS',
);

has 'level' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ERROR',
);

has 'code' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'msgargs' => (
    is      => 'ro',
    isa     => 'ArrayRef | Undef',
    default => undef
);

has 'scope' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short() },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub stringify
{
    my $self = shift;
    my %args = @_;

    return $self->message
        if (!exists($args{trace}) || !$args{trace});

    my $trace = '';
    my $start = 0;

    while (my $frame = $self->trace->next_frame)
    {
        if ($frame->subroutine eq 'GMS::Role::Exceptionable::throw_exception')
        {
            $start = 1;
            next;
        }

        $trace .= "${\$frame->as_string}\n" if ($start);
    }

    return sprintf("%d: %s\n%s", $self->status, $self->message, $trace);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Exception::Base - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

