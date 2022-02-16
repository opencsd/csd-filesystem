package GMS::Model::Base;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Dumper;
use Mouse::Exporter;
use URI::Escape qw/uri_unescape/;

use GMS::Model;
use GMS::Validator;

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '_validator' => (
    is      => 'ro',
    isa     => 'GMS::Validator',
    default => sub { GMS::Validator->new() },
    handles => {
        validate => 'validate',
    }
);

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Role::Exceptionable',
    'GMS::Role::Serializable',
    'GMS::Role::Lockable';

#---------------------------------------------------------------------------
#   Class Methods
#---------------------------------------------------------------------------
sub list
{
    my $class = shift;
    my %args  = @_;

    my $root = $class->meta->etcd_root;

#    foreach my $key (keys(%args))
#    {
#        if ($root =~ m/\{$key\}/)
#        {
#            $root =~ s/\{$key\}/$args{$key}/g;
#        }
#    }

    my $keys = $class->meta->etcd->ls(key => $root);

    # :NOTE 06/16/2019 10:46:47 PM: by P.G.
    # do not validate type for $keys to find bug easily.
    return defined($keys)
        ? map { uri_unescape($_); } @{$keys}
        : ();
}

#sub create
#{
#    my $class = shift;
#    my $root  = $class->meta->etcd_root;
#    my $key   = shift;
#
#    if ($class->find($key))
#    {
#        return;
#    }
#
#    return $class->new($class->meta->etcd_keygen->($key));
#}

sub find
{
    my $class = shift;
    my $key   = shift;

    if (!defined($key) || !length($key))
    {
        # :TODO Thu 09 Apr 2020 02:03:37 PM KST by P.G.
        # replace die with throw_xxx
        #$self->throw_error('Invalid key: ' . $key // 'undef');
        die 'Invalid key: ' . $key // 'undef';
    }

    my $found = 0;

    # 키 검색
    foreach ($class->list)
    {
        if ($key eq $_)
        {
            $found = 1;
            last;
        }
    }

    if (!$found)
    {
        warn sprintf('[DEBUG] Could not find model: %s', $key // 'undef');
        return;
    }

    my %args = ();

    if ($class->meta->etcd_keygen)
    {
        %args = $class->meta->etcd_keygen->($key);
    }

    # 있다면 인스턴스 생성하여 반환, 없으면 undef 반환
    return $class->new(%args);
}

sub find_or_create
{
    my $class = shift;
    my $key   = shift;

    if (!defined($key) || !length($key))
    {
        # :TODO Thu 09 Apr 2020 02:03:37 PM KST by P.G.
        # replace die with throw_xxx
        #$self->throw_error('Invalid key: ' . $key // 'undef');
        die 'Invalid key: ' . $key // 'undef';
    }

    my $obj = $class->find($key);

    my %args = ();

    if ($class->meta->etcd_keygen)
    {
        %args = $class->meta->etcd_keygen->($key);
    }

    return $obj ? $obj : $class->new(%args);
}

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub update
{
    my $self = shift;
    my %args = @_;

    foreach my $key (keys(%args))
    {
        next if (substr($key, 0, 1) eq '_');

        foreach my $attr ($self->meta->get_all_attributes)
        {
            next if ($key ne $attr->name);

#            warn sprintf('[INFO] %s(etcd_key): %s', $attr->name, $attr->etcd_key);
#            warn sprintf('[INFO] %s(accesor): %s', $attr->name, $attr->accessor // 'undef');
#            warn sprintf('[INFO] %s(reader): %s', $attr->name, $attr->reader // 'undef');
#            warn sprintf('[INFO] %s(writer): %s', $attr->name, $attr->writer // 'undef');
#            warn sprintf('[INFO] %s(value): %s', $attr->name, $self->dumper($args{$key}));

            my $getter = undef;
            my $setter = undef;

            if ($attr->has_accessor)
            {
                $getter = $attr->accessor;
                $setter = $attr->accessor;
            }
            else
            {
                $getter = $attr->reader;
                $setter = $attr->writer;
            }

            if (ref($args{$key}) eq 'ARRAY')
            {
                splice(@{$self->$getter}, 0, scalar(@{$self->$getter}),
                    @{$args{$key}});
            }
            elsif (ref($args{$key}) eq 'HASH')
            {
                %{$self->$getter} = %{$args{$key}};

                map {
                    delete($self->$getter->{$_})
                        if (!exists($args{$key}{$_}));
                } keys(%{$self->$getter});
            }
            elsif ($setter)
            {
                $self->$setter($args{$key});
            }
        }
    }

    return $self;
}

sub delete
{
    my $self = shift;
    my $root = $self->meta->etcd_root;
    my $key  = $root;

    if ($self->meta->etcd_keygen)
    {
        my $val = $self->meta->etcd_keygen->(@_);
        $key .= "/$val";
    }

    if (!defined($key))
    {
        $self->throw_error(
            sprintf(
                'Failed to get key with keygen: %s: %s',
                $root, @_ ? join(', ', @_) : 'undef'
            )
        );
    }

    my $retval = $self->to_hash();

    # 있다면 삭제, 없으면 undef 반환
    if ($self->meta->etcd->del_key(
        key     => "$key",
        options => {recursive => 'true'}
    ))
    {
        return;

        #$self->throw_error("Failed to delete etcd key: %s', $key");
    }

    return $retval;
}

sub dumper
{
    my $self = shift;

    return Dumper(@_);
}

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'to_hash' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    foreach my $class ($self->meta->linearized_isa)
    {
        next
            if (!$class->meta->can('excluded_attributes')
            || !@{$class->meta->excluded_attributes});

        push(@{$args{excludes}}, @{$class->meta->excluded_attributes});
    }

    return $self->$orig(%args);
};

around 'lock' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    $args{scope} = $self->meta->get_lock_scope($self);
    $args{owner} = $self->meta->get_lock_owner($self);

    warn "[DEBUG] Locking for model: ${\$self->dumper(\%args)}";

    return $self->$orig(%args);
};

around 'unlock' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    $args{scope} = $self->meta->get_lock_scope($self);
    $args{owner} = $self->meta->get_lock_owner($self);

    warn sprintf('[DEBUG] Unlocking for model: %s: %s',
        $self, $self->dumper(\%args));

    return $self->$orig(%args);
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Base - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

