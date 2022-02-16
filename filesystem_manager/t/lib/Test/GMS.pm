package Test::GMS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose;
use Test::Mojo;
use Mock::GMS;

has 't' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { Test::Mojo->new(Mock::GMS->new()); },
);

1;

=encoding utf8

=head1 NAME

Test::GMS - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 startup

=head2 setup

=head2 teardown

=head2 test_potato_list

=head2 test_potato_create

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

