package GMS::Exception;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse ();
use Mouse::Util qw/find_meta does_role/;
use Mouse::Util::MetaRole;
use namespace::clean -except => 'meta';

use Mouse::Exporter;

Mouse::Exporter->setup_import_methods(also => 'Mouse');

sub init_meta
{
    my $self = shift;
    my %args = @_;

    my $for_class = $args{for_class};
    my $meta      = find_meta($for_class);

    $meta = Mouse::Meta::Class->create($for_class) unless ($meta);

    Mouse::Util::MetaRole::apply_base_class_roles(
        for_class => $for_class,
        roles     => ['GMS::Role::Exceptionable'],
    );

    return $meta;
}

1;

=encoding utf8

=head1 NAME

GMS::Exception - Provides GMS exception-classes

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
