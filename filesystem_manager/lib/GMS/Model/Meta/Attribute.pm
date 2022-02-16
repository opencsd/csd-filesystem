package GMS::Model::Meta::Attribute;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse::Role;
use Mouse::Util;
use namespace::clean -except => 'meta';
use Data::Compare;
use Data::Dumper;

use GMS::Tie::Etcd;

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'etcd_key' => (
    is        => 'rw',
    isa       => 'Str | Undef',
    predicate => 'has_etcd_key',
);

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
after 'install_accessors' => sub
{
    my $self  = shift;
    my $class = $self->associated_class;

    # :TODO 07/06/2018 02:33:32 PM: by P.G.
    # We need to consider type constraints for the attribute.

    return if (substr($self->name, 0, 1) eq '_' || !$self->has_etcd_key);

#    warn sprintf('[DEBUG] package     : %s', $class->{package}  // 'undef');
#    warn sprintf('[DEBUG] name        : %s', $self->name        // 'undef');
#    warn sprintf('[DEBUG] accessor    : %s', $self->accessor    // 'undef');
#    warn sprintf('[DEBUG] reader      : %s', $self->reader      // 'undef');
#    warn sprintf('[DEBUG] writer      : %s', $self->writer      // 'undef');
#    warn sprintf('[DEBUG] has_default : %s', $self->has_default // 'undef');
#    warn sprintf('[DEBUG] etcd_key    : %s', $self->etcd_key    // 'undef');
#    warn sprintf('[DEBUG] init_arg    : %s', $self->init_arg    // 'undef');

    if ($self->has_accessor)
    {
        $class->add_around_method_modifier(
            $self->accessor,
            sub
            {
                my $orig = shift;
                my $obj  = shift;

                my $key = $self->gen_key($obj);

                warn sprintf('[DEBUG] Accessor: %s(%s): %s => %s',
                    $self->name, $self->{is},
                    $key,        @_ ? Dumper(\@_) : 'none');

                if (@_ == 0)
                {
                    return $obj->$orig();
                }

                my $constraint = $self->type_constraint;
                my $val        = shift;

                if (!defined($val))
                {
                    $class->del_key($key);
                    $self->clear_value($obj);

                    goto NEXT;
                }

                if (ref($val) eq '')
                {
                    # :TODO Thu 09 Apr 2020 04:26:50 PM KST: by P.G.
                    # value comparison between prev and new value
#                    my $val_orig = $obj->$orig();
#
#                    if (!defined($val_orig) || Compare($val, $val_orig))
#                    {
                    if ($class->set_key($key, $val) == -1)
                    {
                        $self->throw_error(
                            sprintf(
                                'Failed to set etcd key: %s => %s',
                                $key, $val
                            )
                        );
                    }

#                    }

                    goto NEXT;
                }

                if ($constraint->is_a_type_of('HashRef')
                    && ref($val) eq 'HASH'
                    && !tied(%{$val}))
                {
                    tie(
                        %{$val},
                        'GMS::Tie::Etcd',
                        root => $key,
                        data => $val
                    );

                    goto NEXT;
                }

                if ($constraint->is_a_type_of('ArrayRef')
                    && ref($val) eq 'ARRAY'
                    && !tied(@{$val}))
                {
                    tie(
                        @{$val},
                        'GMS::Tie::Etcd',
                        root => $key,
                        data => $val
                    );

                    goto NEXT;
                }

            NEXT:
                return $self->{is} eq 'rw'
                    ? $obj->$orig($val)
                    : $obj->$orig();
            }
        );
    }

    if ($self->has_writer)
    {
        $class->add_around_method_modifier(
            $self->writer,
            sub
            {
                my $orig = shift;
                my $obj  = shift;
                my $val  = shift;

                return $self->clear_value($obj) if (!defined($val));

                my $constraint = $self->type_constraint;
                my $key        = $self->gen_key($obj);

                warn sprintf('[DEBUG] Writer: %s: %s => %s',
                    $self->name, $key,
                    defined($val) ? Dumper($val) : 'undef');

                if (ref($val) eq ''
                    && $class->set_key($key, $val) == -1)
                {
                    $self->throw_error(
                        "Failed to set etcd key: $key => $val");
                }

                if ($constraint->is_a_type_of('HashRef')
                    && ref($val) eq 'HASH'
                    && !tied(%{$val}))
                {
                    tie(
                        %{$val},
                        'GMS::Tie::Etcd',
                        root => $key,
                        data => $val
                    );
                }
                elsif ($constraint->is_a_type_of('ArrayRef')
                    && ref($val) eq 'ARRAY'
                    && !tied(@{$val}))
                {
                    tie(
                        @{$val},
                        'GMS::Tie::Etcd',
                        root => $key,
                        data => $val
                    );
                }

                return $obj->$orig($val);
            }
        );
    }

    if ($self->has_reader)
    {
        $class->add_around_method_modifier(
            $self->reader,
            sub
            {
                my $orig = shift;
                my $obj  = shift;
                my $key  = $self->gen_key($obj, $orig);
                my $val  = $obj->$orig();

                warn sprintf('[DEBUG] Reader: %s: %s => %s',
                    $self->name, $key,
                    defined($val) ? Dumper($val) : 'undef');

                my $constraint = $self->type_constraint;

                if ($constraint->is_a_type_of('HashRef')
                    && ref($val) eq 'HASH'
                    && !tied(%{$val}))
                {
                    tie(
                        %{$val},
                        'GMS::Tie::Etcd',
                        root => $key,
                        data => $val
                    );
                }
                elsif ($constraint->is_a_type_of('ArrayRef')
                    && ref($val) eq 'ARRAY'
                    && !tied(@{$val}))
                {
                    tie(
                        @{$val},
                        'GMS::Tie::Etcd',
                        root => $key,
                        data => $val
                    );
                }

                if ($self->has_value($obj) && !defined($val))
                {
                    warn "[DEBUG] clear_value: ${\$self->name}";
                    $self->clear_value($obj);
                }
                elsif (!$self->has_value($obj) && defined($val))
                {
                    warn "[DEBUG] set_value: ${\$self->name}: $val";
                    $self->set_value($obj, $val);
                }

                return $val;
            }
        );
    }

    if ($self->has_clearer)
    {
        $class->add_around_method_modifier(
            $self->clearer,
            sub
            {
                my $orig = shift;
                my $obj  = shift;

                my $key = $self->gen_key($obj);

                $class->del_key($key);

                return $obj->$orig();
            }
        );
    }

    return;
};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub gen_key
{
    my $self = shift;
    my $obj  = shift;
    my $orig = shift;

    my $root = $obj->meta->etcd_root;
    my $key  = sprintf('%s/%s', $root, $self->etcd_key);

    # :WARNING 07/08/2018 09:49:32 PM: by P.G.
    # Tricky way
    my @matched = ($key =~ m/\{([^\}]+)\}/g);

    foreach my $field (@matched)
    {
        my $replaced;

        if ($field eq $self->name)
        {
            my $name = $self->name;
            $replaced = $orig ? $obj->$orig : $obj->$name;
        }
        else
        {
            $replaced = $obj->$field;
        }

        $key =~ s/\{$field\}/$replaced/g;
    }

    return $key;
}

no Mouse::Role;
1;

=encoding utf8

=head1 NAME

GMS::Model::Meta::Attribute - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

