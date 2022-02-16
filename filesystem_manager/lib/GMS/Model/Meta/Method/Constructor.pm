package GMS::Model::Meta::Method::Constructor;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse::Role;
use Mouse::Util;
use Scalar::Util qw/refaddr/;

around '_generate_constructor' => sub
{
    my $orig = shift;
    my $self = shift;

    my $code = $self->$orig(@_);

    return sub
    {
        my $class = shift;
        my %args  = @_;

        my $instance = $code->($class, @_);

        my $root  = $instance->meta->etcd_root;
        my $owner = refaddr($instance);

        if ($instance->meta->etcd_keygen)
        {
            my $attr = ($instance->meta->etcd_keygen->())[0];

            $root = sprintf('%s/%s', $root, $instance->$attr);
        }

        # tmp
        if (!defined($instance->meta->get_lock_scope($instance)))
        {
            warn "[DEBUG] Lock scope from root: $root($owner)";

            $instance->meta->set_lock_scope($instance, $root);
            $instance->meta->set_lock_owner($instance, $owner);

            if ($instance->lock())
            {
                $instance->throw_error("Failed to get model lock: $root");
            }
        }

        # Initialize Attributes
        my @excludes = @{$instance->meta->excluded_attributes};

        foreach my $attr ($instance->meta->get_all_attributes)
        {
            my $name       = $attr->name;
            my $constraint = $attr->type_constraint;

            warn "[DEBUG] Building model attr: $name";

            if (!defined($constraint))
            {
                warn "[WARN] Could not find type constraint: $name";
                next;
            }

            next if (substr($name, 0, 1) eq '_');
            next if (scalar(grep { $name eq $_; } @excludes));
            next if ($attr->is_lazy);
            next if (!$attr->can('etcd_key'));

            my $key = $attr->gen_key($instance);
            my $value;

            if (exists($args{$name}))
            {
                $value = $args{$name};
            }
            elsif ($instance->meta->key_exists($key))
            {
                $value = $instance->meta->get_key($key, {recursive => 1});
            }
            elsif ($attr->has_value($instance))
            {
                $value = $attr->get_value($instance);
            }

            warn sprintf('[DEBUG] KV: %s = %s',
                $key, $instance->dumper($value));

            if ($constraint->is_a_type_of('ArrayRef') && !tied(@{$value}))
            {
                warn sprintf('[DEBUG] Tying to array: %s: %s',
                    $key, $instance->dumper($value));

                #map {
                #    warn sprintf('[DEBUG] TESTING: %s: %s',
                #        ref($_) // 'undef', $_,);
                #} @{$value};

                tie(
                    my @array,
                    'GMS::Tie::Etcd',
                    root => $key,
                    data => $value // []
                );

                $value = \@array;
            }
            elsif ($constraint->is_a_type_of('HashRef') && !tied(%{$value}))
            {
                warn sprintf('[DEBUG] Tying to hash: %s: %s',
                    $key, $instance->dumper($value));

                tie(
                    my %hash,
                    'GMS::Tie::Etcd',
                    root => $key,
                    data => $value // {}
                );

                $value = \%hash;
            }

            warn sprintf('[DEBUG] Model attribute: %s = %s',
                $key, $instance->dumper($value));

            $attr->set_value($instance, $value) if (defined($value));
        }

        return $instance;
    };
};

no Mouse::Role;
1;

=encoding utf8

=head1 NAME

GMS::Model::Meta::Method::Constructor - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

