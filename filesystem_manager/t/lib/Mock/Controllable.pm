package Mock::Controllable;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse::Role;
use namespace::clean -except => 'meta';
use Storable qw/dclone/;

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'mock' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { []; },
    handles => {
        add_mock    => 'push',
        all_mocks   => 'elements',
        clear_mocks => 'clear',
    }
);

has 'render_called' => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    handles => {
        inc_rc   => 'inc',
        dec_rc   => 'dec',
        reset_rc => 'reset',
    }
);

has 'req_args' => (
    is      => 'rw',
    default => undef,
);

has 'render_args' => (
    is      => 'rw',
    default => undef,
);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'render' => sub
{
    my $self = shift;
    my %args = @_;

    $self->inc_rc;
    $self->render_args($args{json});

    $args{render_called} = $self->render_called;
    $args{render_args}   = $self->render_args;
    $args{req_args}      = $self->req_args;

    super(%args);
};

sub DEMOLISH
{
    my $self      = shift;
    my $is_global = shift;

    if (!$is_global)
    {
        foreach my $mock ($self->all_mocks)
        {
            $mock->unmock_all();
        }
    }

#    unmock_data();

    return;
}

1;

=encoding utf8

=head1 NAME

Mock::Controllable - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

