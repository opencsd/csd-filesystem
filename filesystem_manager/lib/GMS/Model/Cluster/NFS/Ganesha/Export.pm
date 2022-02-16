package GMS::Model::Cluster::NFS::Ganesha::Export;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use File::Path qw/make_path/;
use GMS::Model;

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/Cluster/NFS/Ganesha/Export'; };
etcd_keygen sub { name => shift; };

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::NFS::Ganesha::Export';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '+config_dir' => (default => '/mnt/private/ganesha/exports.d',);

has '+_section_dir' => (default => '/etc/ganesha/exports.d',);

#has '+fsal' => (
#    trigger => sub {
#        my ($self, $new, $old) = @_;
#
#        my $key = sprintf('%s/%s/%s'
#            , $self->meta->etcd_root
#            , $self->name
#            , 'fsal');
#
#        $self->meta->set_key($key, $new);
#    }
#);

upgrade_attrs(
    key      => 'name',
    excludes => [
        GMS::NFS::Ganesha::Configurable->meta->get_attribute_list,
        GMS::NFS::Ganesha::Block->meta->get_attribute_list,
    ],
);

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'enable' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $retval = $self->$orig(%args);

    my $from = "${\$self->config_dir}/${\$self->name}.conf";
    my $to   = "${\$self->_section_dir}/${\$self->name}.conf";

    if (!-d $self->_section_dir
        && make_path($self->_section_dir, {error => \my $err}) == 0)
    {
        my ($name, $msg) = %{$err->[0]};

        if ($name eq '')
        {
            die "Generic error: $msg";
        }
        else
        {
            die "Failed to make directory: $name: $msg";
        }
    }

    if (-l $to)
    {
        unlink($to)
            || die "Failed to delete symbolic link: $to: $!";
    }

    if (!-e $to)
    {
        symlink($from, $to)
            || die "Failed to create symbolic link: $from -> $to: $!";
    }

    return $retval;
};

override 'delete' => sub
{
    my $self = shift;
    my %args = @_;

    my $file = "${\$self->_section_dir}/${\$self->name}.conf";

    if (-l $file || -e $file)
    {
        unlink($file) || die "Failed to delete file: $file: $!";
    }

    # :TODO 08/19/2019 08:06:45 PM: by P.G.
    # We need to delete file from other nodes

    return super();
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Cluster::NFS::Ganesha::Export - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

