package GMS::Model::Share;

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
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::File::JSON';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/Share'; };
etcd_keygen sub { name => shift; };

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '_config_file' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => '/usr/gms/config/share.conf',
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'pool' => (
    is     => 'ro',
    isa    => 'Str',
    writer => '_set_pool',
);

has 'volume' => (
    is     => 'ro',
    isa    => 'Str',
    writer => '_set_volume',
);

has 'path' => (
    is     => 'ro',
    isa    => 'Str',
    writer => '_set_path',
);

has 'desc' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has 'protocols' => (
    is      => 'ro',
    isa     => 'HashRef',
    writer  => 'set_protocols',
    default => sub { {}; },
);

has 'status' => (
    is      => 'ro',
    isa     => 'Str',
    writer  => 'set_status',
    default => 'Normal',
);

upgrade_attrs(key => 'name');

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'update' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $retval = $self->$orig(%args);

    my $config = load_from_file(path => $self->_config_file);

    delete($args{'path'});

    map { $config->{$self->name}->{$_} = $args{$_}; } keys(%args);

    store_to_file(
        path => $self->_config_file,
        data => $config,
    );

    return $retval;
};

around 'delete' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $retval = $self->$orig($self->name);

    my $config = load_from_file(path => $self->_config_file);

    delete($config->{$self->name});

    store_to_file(
        path => $self->_config_file,
        data => $config,
    );

    return $retval;
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub relpath
{
    return (shift->path =~ m/^\/export\/[^\/]+(\/.*)$/)[0];
}

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    my $config = load_from_file(
        path => $self->_config_file,
        key  => $self->name,
    );

    #warn "[DEBUG] CONFIG(BEFORE): ${\$self->dumper($config)}";

    if (ref($config) eq 'HASH')
    {
        map { $config->{$_} = $args->{$_}; } keys(%{$args});

        foreach my $attr ($self->meta->get_all_attributes)
        {
            next if (substr($attr->name, 0, 1) eq '_');

            my $attr_name = $attr->name;

            if ($attr_name eq 'protocols' && exists($config->{protocols}))
            {
                map { $self->protocols->{$_} = $config->{protocols}->{$_}; }
                    keys(%{$config->{protocols}});
            }

            next
                if ($attr_name eq 'name'
                || (!$attr->has_accessor && !$attr->has_writer));

            my $setter
                = $attr->has_accessor ? $attr->accessor : $attr->writer;

            $self->$setter($config->{$attr_name});
        }
    }

    $self->meta->set_key(
        sprintf('%s/%s/name', $self->meta->etcd_root, $self->name),
        $self->name);

    #map {
    #    $self->protocols->{$_} = 'no'
    #        if (!exists($self->protocols->{$_})
    #            || !defined($self->protocols->{$_}));
    #} qw/SMB NFS AFP FTP/;

    #warn "[DEBUG] CONFIG(AFTER): ${\$self->dumper($self->to_hash())}";

    store_to_file(
        path => $self->_config_file,
        key  => $self->name,
        data => $self->to_hash(),
    );

    return;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Share - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

