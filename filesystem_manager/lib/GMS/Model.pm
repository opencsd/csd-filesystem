package GMS::Model;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse ();
use Mouse::Exporter;
use Mouse::Util qw/find_meta does_role/;
use Mouse::Util::MetaRole;
use URI::Escape qw/uri_escape uri_unescape/;
use GMS::API::Return qw/api_status get_gms_message/;

Mouse::Exporter->setup_import_methods(
    also  => 'Mouse',
    as_is => [
        qw/
            etcd_root
            etcd_keygen
            api_status
            get_gms_message
            upgrade_attrs
            /
    ],
);

sub init_meta
{
    my $self = shift;
    my %args = @_;

    my $for_class = $args{for_class};
    my $meta      = find_meta($for_class);

    if (!$meta)
    {
        #$meta = Mouse::Meta::Class->create($for_class);
        $meta = Mouse->init_meta($for_class);
    }

    $meta = Mouse::Util::MetaRole::apply_metaroles(
        for             => $for_class,
        class_metaroles => {
            class       => ['GMS::Model::Meta::Class'],
            attribute   => ['GMS::Model::Meta::Attribute'],
            constructor => ['GMS::Model::Meta::Method::Constructor'],
            destructor  => ['GMS::Model::Meta::Method::Destructor'],

            #method      => ['GMS::Model::Meta::Method'],
        },

        #role_metaroles => {
        #    role   => [],
        #    method => [],
        #},
    );

    return $meta;
}

sub etcd_root
{
    my $meta = caller->meta;
    my $root = shift;

    $meta->etcd_root($root);
}

sub etcd_keygen
{
    my $meta   = caller->meta;
    my $keygen = shift;

    $meta->etcd_keygen($keygen);
}

sub upgrade_attrs
{
    my $class = caller;
    my $meta  = $class->meta;
    my %args  = @_;

    $args{excludes} = [] if (ref($args{excludes}) ne 'ARRAY');

    foreach my $attr_name (@{$args{excludes}})
    {
        next if (grep { $attr_name eq $_; } @{$meta->excluded_attributes});

        push(@{$meta->excluded_attributes}, $attr_name);
    }

    foreach my $attr ($meta->get_all_attributes)
    {
        my $name = $attr->name;

        next
            if (substr($name, 0, 1) eq '_'
            || grep { $name eq $_; } @{$meta->excluded_attributes});

#        warn "[DEBUG] Upgrading attribute: $name";

        my $constraint = $attr->type_constraint;

        if (!defined($constraint))
        {
            warn "[WARN] Could not find type constraint: $name";
            next;
        }

        # :TODO 08/02/2019 07:08:44 PM: by P.G.
        # Set trigger with to_hash()/FREEZE() serialize methods.
        # we can check availability with duck-typing for each attrs.
        # below 'next' will removed if we implement reflection
        #if ($constraint->type_parameter
        #    && $constraint->type_parameter->is_a_type_of('Object'))
        #{
        #    #
        #    # refer: GMS::Tie::Etcd::BUILD
        #    #
        #    next;
        #}

        if ($constraint->is_a_type_of('Value'))
        {
            $meta->add_attribute(
                "+$name" => (
                    traits   => ['GMS::Model::Meta::Attribute'],
                    etcd_key => "{$args{key}}/$name",
                )
            );
        }
        elsif ($constraint->is_a_type_of('ArrayRef')
            || $constraint->is_a_type_of('HashRef'))
        {
            $meta->add_attribute(
                "+$name" => (
                    traits   => ['GMS::Model::Meta::Attribute'],
                    etcd_key => "{$args{key}}/$name",
                )
            );
        }
    }
}

1;

=encoding utf8

=head1 NAME

GMS::Model - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

