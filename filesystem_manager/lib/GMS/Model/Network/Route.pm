package GMS::Model::Network::Route;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Tie::Etcd;
use GMS::Network::Route;

use Data::Compare;

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/Network/Route'; };

#---------------------------------------------------------------------------
#  Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'handler' => (
    is      => 'ro',
    isa     => 'GMS::Network::Route',
    default => sub { GMS::Network::Route->new(); },
);

has 'tables' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['GMS::Model::Meta::Attribute'],
    etcd_key => 'Tables',
    default  => sub { {} },
);

has 'rules' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['GMS::Model::Meta::Attribute'],
    etcd_key => 'Rules',
    default  => sub { {} },
);

has 'entries' => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => ['GMS::Model::Meta::Attribute'],
    etcd_key => 'Entries',
    default  => sub { {} },
);

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::Exceptionable';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub all_tables
{
    my $self = shift;
    my %args = @_;

    # :TODO 04/29/2019 02:52:24 PM: by P.G.
    # filtering
    my @tables = sort { $a->{id} <=> $b->{id}; } values(%{$self->tables});

    return wantarray ? @tables : \@tables;
}

sub create_table
{
    my $self = shift;
    my %args = @_;

    my $found = $self->handler->get_table($args{Name});

    if (
        defined($found)
        || (defined($args{ID})
            && grep { $args{ID} == $_->id; } $self->handler->all_tables)
        )
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'network routing table',
            name     => sprintf('%s(%d)', $found->name, $found->id),
        );
    }

    if (!defined($args{ID}))
    {
        my $maximum = 0;

        foreach my $table ($self->handler->all_tables)
        {
            $maximum = $table->id if ($table->id > $maximum);
        }

        $args{ID} = $maximum + 1;
    }

    my $table = GMS::Network::Route::Table->new(
        route => $self->handler,
        name  => $args{Name},
        id    => $args{ID},
    );

    $self->tables->{$table->name} = $table->to_hash;
    $self->rules->{$table->name}  = [map { $_->to_hash; } $table->all_rules];
    $self->entries->{$table->name}
        = [map { $_->to_hash; } $table->all_entries];

    return $self->tables->{$table->name};
}

sub delete_table
{
    my $self = shift;
    my %args = @_;

    my $table = $self->handler->get_table($args{Name});

    if (!defined($table))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network routing table',
            name     => $args{Name}
        );
    }

    delete($self->tables->{$args{Name}});
    delete($self->rules->{$args{Name}});
    delete($self->entries->{$args{Name}});

    return $table->delete();
}

sub all_rules
{
    my $self = shift;
    my %args = @_;

    my @rules = ();

    if (exists($args{Table}))
    {
        push(@rules, @{$self->rules->{$args{Table}}});
        goto RETURN;
    }

    # :TODO 04/29/2019 02:52:24 PM: by P.G.
    # filtering
    foreach my $table ($self->table_names)
    {
        push(@rules, @{$self->rules->{$table}})
            if (ref($self->rules->{$table}));
    }

RETURN:
    return wantarray ? @rules : \@rules;
}

sub create_rule
{
    my $self = shift;
    my %args = @_;

    my $table = $self->handler->get_table($args{Table});

    if (!defined($table))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network routing table',
            name     => $args{Table}
        );
    }

    if ($self->handler->find_rule(
        table => $table,
        from  => $args{From},
        dev   => $args{Device}
    ))
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'network routing rule',
            name     => "$args{Table}($args{From}:$args{Device})",
        );
    }

    my $created = $self->handler->add_rule(
        table => $table,
        from  => $args{From},
        dev   => $args{Device},
    );

    push(@{$self->rules->{$table->name}}, $created->to_hash());

    return $created->to_hash;
}

sub delete_rule
{
    my $self = shift;
    my %args = @_;

    my $table = $self->handler->get_table($args{Table});

    if (!defined($table))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network routing table',
            name     => $args{Table}
        );
    }

    if (!$self->handler->find_rule(
        table => $table,
        from  => $args{From},
        dev   => $args{Device}
    ))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network routing rule',
            name     => "$args{Table}($args{From}:$args{Device})",
        );
    }

    my $deleted = $self->handler->delete_rule(
        table => $table,
        from  => $args{From},
        dev   => $args{Device}
    );

    for (my $i = 0; $i < @{$self->rules->{$args{Table}}}; $i++)
    {
        if (Compare($self->rules->{$args{Table}}->[$i], $deleted->to_hash))
        {
            splice(@{$self->rules->{$args{Table}}}, $i ? $i-- : $i, 1);
        }
    }

    return $deleted->to_hash;
}

sub all_entries
{
    my $self = shift;
    my %args = @_;

    my @entries = ();

    if (exists($args{Table})
        && ref($self->entries->{$args{Table}}) eq 'ARRAY')
    {
        push(@entries, @{$self->entries->{$args{Table}}});
        goto RETURN;
    }

    # :TODO 04/29/2019 02:52:24 PM: by P.G.
    # filtering
    foreach my $table ($self->table_names)
    {
        next if (ref($self->entries->{$table}) ne 'ARRAY');

        foreach my $entry (@{$self->entries->{$table}})
        {
            push(
                @entries,
                {
                    Table   => $table,
                    To      => $entry->{to},
                    Via     => $entry->{via},
                    Default => $entry->{default} ? 1 : 0,
                    Device  => $entry->{dev},
                }
            );
        }
    }

RETURN:
    return @entries;
}

sub _convert_entry_param
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    my %converted;

    map {
        my $key = lc($_);

        if (defined($args{$_}))
        {
            $key = 'dev' if ($_ eq 'Device');
            $converted{$key} = $args{$_};
        }
    } qw/Default To Via Device/;

    return %converted;
}

sub create_entry
{
    my $self = shift;
    my %args = @_;

    my $table = $self->handler->get_table($args{Table});

    if (!defined($table))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network routing table',
            name     => $args{Table},
        );
    }

    my %parm = $self->_convert_entry_param(%args);

    if ($self->handler->find_entry(table => $table, %parm))
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'network routing entry',
            name     => sprintf(
                '%s(to:%s via:%s dev:%s)',
                $args{Table}  // 'undef',
                $args{To}     // 'undef',
                $args{Via}    // 'undef',
                $args{Device} // 'undef'
            ),
        );
    }

    my $created = $self->handler->add_entry(table => $table, %parm);

    push(@{$self->entries->{$table->name}}, $created->to_hash);

    return $created->to_hash;
}

sub delete_entry
{
    my $self = shift;
    my %args = @_;

    my $table = $self->handler->get_table($args{Table});

    if (!defined($table))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network routing table',
            name     => $args{Table}
        );
    }

    my %parm = $self->_convert_entry_param(%args);

    my $found = $self->handler->find_entry(table => $table, %parm);

    if (!$found)
    {
        $self->throw_exception(
            'NotFound',
            resource => 'network routing entry',
            name     => sprintf(
                '%s(to:%s via:%s dev:%s)',
                $args{Table}  // 'undef',
                $args{To}     // 'undef',
                $args{Via}    // 'undef',
                $args{Device} // 'undef'
            ),
        );
    }

    my $deleted
        = $self->handler->delete_entry(table => $table, %parm)->to_hash();

    if (ref($self->entries->{$args{Table}}) eq 'ARRAY')
    {
        for (my $i = 0; $i < @{$self->entries->{$args{Table}}}; $i++)
        {
            my $entry = $self->entries->{$args{Table}}->[$i];

            my $matched = 1;

            foreach my $key (keys(%{$entry}))
            {
                if (!Compare($entry->{$key}, $deleted->{$key}))
                {
                    $matched = 0;
                    last;
                }
            }

            if ($matched)
            {
                splice(@{$self->entries->{$args{Table}}}, $i--, 1);
                last;
            }
        }
    }

    return $deleted;
}

sub table_names
{
    return keys(%{shift->tables});
}

sub get_table
{
    my $self = shift;
    my $name = shift;

    return exists($self->tables->{$name})
        ? $self->tables->{$name}
        : undef;
}

sub reload
{
    my $self = shift;

    foreach my $table (values(%{$self->handler->tables}))
    {
        $self->tables->{$table->name} = $table->to_hash;
        $self->rules->{$table->name}
            = [map { $_->to_hash; } $table->all_rules];

        # :TODO 12/19/2019 05:37:24 PM: by P.G.
        next if ($table->name ne 'main');

        warn "[DEBUG] Reloading ${\$table->name} routing table...";

        my @proc_entries = $table->get_entries_from_proc();
        my @entries      = $self->all_entries();

        foreach my $entry (@entries)
        {
            map { $entry->{lc($_)} = delete($entry->{$_}); } keys(%{$entry});

            next
                if (
                grep {
                    $_->{to} eq $entry->{to}
                        && $_->{via} eq $entry->{via};
                } @proc_entries
                );

            $self->handler->add_entry(table => $table, %{$entry});
        }

        foreach my $entry (@proc_entries)
        {
            next
                if (
                grep {
                    $_->{to} eq $entry->{to}
                        && $_->{via} eq $entry->{via};
                } @entries
                );

            $self->handler->delete_entry(table => $table, %{$entry});
        }

        $self->entries->{$table->name}
            = [map { $_->to_hash; } $table->all_entries];
    }

    return $self;
}

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILD
{
    shift->reload();
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Network::Route - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 handler

=head2 tables

=head2 rules

=head2 entries

=head1 METHODS

=head2 all_tables

=head2 create_table

=head2 delete_table

=head2 all_rules

=head2 create_rule

=head2 delete_rule

=head2 create_entry

=head2 delete_entry

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

