package GMS::Model::Meta::Class;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse::Role;
use Mouse::Util;
use Scalar::Util qw/blessed refaddr/;
use Sys::Hostname::FQDN qw/short/;

use GMS::Cluster::Etcd;

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'etcd' => (
    is      => 'ro',
    isa     => 'GMS::Cluster::Etcd',
    writer  => '_set_etcd',
    default => sub { GMS::Cluster::Etcd->new(); },
    lazy    => 1,
);

has 'etcd_root' => (
    is  => 'rw',
    isa => 'Str | CodeRef | Undef',
);

has 'etcd_keygen' => (
    is  => 'rw',
    isa => 'CodeRef',
);

has 'excluded_attributes' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { []; },
    lazy    => 1,
);

has 'locks' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'etcd_root' => sub
{
    my $orig = shift;
    my $self = shift;

    if (@_)
    {
        return $self->$orig(@_);
    }

    my $root = $self->$orig();

    if (ref($root) eq 'CODE')
    {
        $root = $root->();
    }

    if ($root =~ m/\{hostname\}/)
    {
        $root =~ s/\{hostname\}/${\short()}/g;
    }

#    printf "[%s] ROOT: %s\n", $self->name, $root // 'undef';

    return $root;
};

#around 'make_immutable' => sub
#{
#    my $orig = shift;
#    my $self = shift;
#    my %args = @_;
#
#    # :NOTE 05/04/2019 10:37:18 PM: by P.G.
#    # we need to consider a performance decrease caused by this trick
#    $args{inline_constructor} = 0;
#
#    return $self->$orig(%args);
#};

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub set_key
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

#    print "set_key: $key\n";

    given ($value)
    {
        when (ref($_) eq 'HASH')
        {
            foreach my $k (keys(%{$value}))
            {
                $value->{$k} = $value->{$k};
            }
        }
        when (ref($_) eq 'ARRAY')
        {
            foreach my $i (0 .. $#{$value})
            {
                $value->[$i] = $value->[$i];
            }
        }
        when (ref($_) eq '')
        {
            my $rv = $self->etcd->set_key(
                key   => $key,
                value => $value
            );

            return $rv >= 0 ? $rv : -1;
        }
        when (blessed($_) && $_->can('FREEZE'))
        {
            my $rv = $self->etcd->set_key(
                key   => $key,
                value => $value->FREEZE()
            );

            return $rv >= 0 ? $rv : -1;
        }
        default
        {
            $self->throw_error("Not supported type: ${\blessed($value)}");
        }
    }

    return 0;
}

sub key_exists
{
    my $self = shift;
    my $key  = shift;
    my $opts = shift;

    return $self->etcd->key_exists(key => $key, options => $opts);
}

sub get_key
{
    my $self = shift;
    my $key  = shift;
    my $opts = shift;

    return $self->etcd->get_key(key => $key, options => $opts);
}

sub del_key
{
    my $self = shift;
    my $key  = shift;

    return $self->etcd->del_key(
        key     => $key,
        options => {recursive => 'true'}
    );
}

sub set_lock_scope
{
    my $self     = shift;
    my $instance = shift;
    my $scope    = shift;

    return $self->locks->{refaddr($instance)}->{scope} = $scope;
}

sub get_lock_scope
{
    my $self     = shift;
    my $instance = shift;

    return $self->locks->{refaddr($instance)}->{scope};
}

sub set_lock_owner
{
    my $self     = shift;
    my $instance = shift;
    my $owner    = shift;

    return $self->locks->{refaddr($instance)}->{owner} = $owner;
}

sub get_lock_owner
{
    my $self     = shift;
    my $instance = shift;

    return $self->locks->{refaddr($instance)}->{owner};
}

no Mouse::Role;
1;

=encoding utf8

=head1 NAME

GMS::Model::Meta::Class - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

