package GMS::Model::SMB::Samba::Section;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Encode qw/decode_utf8/;
use GMS::Model;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base', 'GMS::SMB::Samba::Section';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/SMB/Samba/Section'; };
etcd_keygen sub { name => shift; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '_section_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/etc/samba/sections.d',
);

has '+global_pkg' => (default => 'GMS::Model::SMB::Samba::Global',);

has '+section_pkg' => (default => 'GMS::Model::SMB::Samba::Section',);

upgrade_attrs(
    key      => 'name',
    excludes => [GMS::SMB::Samba::Configurator->meta->get_attribute_list,],
);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
#override 'find' => sub
#{
#    my $self = shift;
#    my $name = shift;
#
#    my $retval = super();
#
#    if (!defined($retval))
#    {
#        my $attr = $self->meta->find_attribute_by_name('config_dir');
#
#        die 'Could not find attribute: config_dir'
#            if (!defined($attr));
#
#        my $path = sprintf('%s/%s.conf', $attr->default, $name);
#
#        $retval = $self->new(name => $name) if (-f $path);
#    }
#
#    return $retval;
#};

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'to_hash' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $retval = $self->$orig(%args);

    if (ref($retval) ne 'HASH')
    {
        die "Failed to convert to hash: $self->name";
    }

    my @exclude = @{$self->meta->excluded_attributes};

    foreach my $key (keys(%{$retval}))
    {
        # :WARNING 07/04/2019 08:23:45 AM: by P.G.
        # Monkey patch
        if (
            grep {
                substr($key, 0, 1) eq '_'
                    || ($key ne 'name' && $key eq $_);
            } @exclude
            )
        {
            delete($retval->{$key});
            next;
        }

        my $attr = $self->meta->find_attribute_by_name($key);

        if (!defined($attr))
        {
            die "Could not find attribute: ${\__PACKAGE__}::$key";
        }

#        if ($self->default_not_changed($attr, $retval->{$key}))
#        {
#            delete($retval->{$key});
#        }

        $retval->{$self->camelize($key, {underbar => 1})}
            = delete($retval->{$key});
    }

    $retval->{Name} = $self->name;
    $retval->{Path} = decode_utf8($retval->{Path});

    return $retval;
};

around 'update' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $retval = $self->$orig(@_);

    if ($self->available eq 'yes')
    {
        $self->enable();
    }
    elsif ($self->available eq 'no')
    {
        $self->disable();
    }

    return $retval;
};

around 'delete' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $attr = $self->meta->find_attribute_by_name('config_dir');

    die 'Could not find attribute: config_dir'
        if (!defined($attr));

    $self->exclude();
    $self->destroy();

    return $self->$orig($self->name);
};

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->meta->set_key(
        sprintf('%s/%s/name', $self->meta->etcd_root, $self->name),
        $self->name);

    return;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::SMB::Samba::Section - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

