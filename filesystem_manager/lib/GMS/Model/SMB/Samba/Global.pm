package GMS::Model::SMB::Samba::Global;

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
extends 'GMS::Model::Base', 'GMS::SMB::Samba::Global';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/SMB/Samba'; };
etcd_keygen sub { name => 'global'; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '+global_pkg' => (default => 'GMS::Model::SMB::Samba::Global',);

has '+section_pkg' => (default => 'GMS::Model::SMB::Samba::Section',);

upgrade_attrs(
    key      => 'name',
    excludes => [GMS::SMB::Samba::Configurator->meta->get_attribute_list,],
);

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

    my @excluded = @{$self->meta->excluded_attributes};

    foreach my $key (keys(%{$retval}))
    {
        # :WARNING 07/04/2019 08:23:45 AM: by P.G.
        # Monkey patch
        if (
            grep {
                substr($key, 0, 1) eq '_'
                    || ($key ne 'name' && $key eq $_);
            } @excluded
            )
        {
            delete($retval->{$key});
            next;
        }

        my $attr = $self->meta->find_attribute_by_name($key);

        if (!defined($attr))
        {
            die "Could not find attribute: $key";
        }

#        if ($self->default_not_changed($attr, $retval->{$key}))
#        {
#            delete($retval->{$key});
#        }

        $retval->{$self->camelize($key, {underbar => 1})}
            = delete($retval->{$key});
    }

    return $retval;
};

override 'update' => sub
{
    my $self = shift;
    my %args = @_;

    my $retval = super();

    $self->store_to_file();
    $self->include();

    return $retval;
};

override 'delete' => sub
{
    my $self = shift;

    my $attr = $self->meta->find_attribute_by_name('config_dir');

    die 'Could not find attribute: config_dir'
        if (!defined($attr));

    $self->destroy();

    return super();
};

# :WARNING 08/02/2019 01:31:54 AM: by P.G.
# For now, we need to override find()/find_or_create() methods of each
# config model to pass 'key' parameter
around 'find' => sub
{
    my $orig = shift;
    my $self = shift;

    return $self->$orig('global');
};

around 'find_or_create' => sub
{
    my $orig = shift;
    my $self = shift;

    return $self->$orig('global');
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

GMS::Model::SMB::Samba::Global - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

