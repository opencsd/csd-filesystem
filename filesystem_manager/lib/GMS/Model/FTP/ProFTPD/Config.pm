package GMS::Model::FTP::ProFTPD::Config;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/FTP/ProFTPD'; };
etcd_keygen sub { name => 'Config'; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'name' => (
    is  => 'ro',
    isa => 'Str',
);

upgrade_attrs(
    key      => 'name',
    excludes => [],
);

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'to_hash' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    $args{camelcase} = 1;
    $args{underbar}  = 1;

    return $self->$orig(%args);
};

around 'find' => sub
{
    my $orig = shift;
    my $self = shift;

    return $self->$orig('Config');
};

around 'find_or_create' => sub
{
    my $orig = shift;
    my $self = shift;

    return $self->$orig('Config');
};

#
sub store_to_file
{
    my $self = shift;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::FTP::ProFTPD::Config - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

