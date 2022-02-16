package GMS::Model::Network::Hosts;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Dumper;
use Fcntl;
use GMS::Model;

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/Network/Hosts'; };
etcd_keygen sub { ipaddr => shift; };

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base', 'GMS::Network::Hosts';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '+hostnames' => (
    traits   => ['GMS::Model::Meta::Attribute'],
    etcd_key => '{ipaddr}',
    default  => sub
    {
        my $self = shift;

        tie(my @hostnames,
            'GMS::Tie::Etcd',
            root => sprintf('%s/%s', $self->meta->etcd_root, $self->ipaddr));

        return \@hostnames;
    },
);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
around 'list' => sub
{
    my $orig = shift;
    my $self = shift;

    my @retval = $self->$orig();

    return wantarray ? @retval : \@retval if (@retval);

    my $attr = $self->meta->find_attribute_by_name('hosts_config');
    my $config
        = ref($self) eq '' ? $attr->default() : $attr->get_value($self);

    my @hosts;

    # :WARNING 12/25/2021 04:48:18 PM: by P.G.
    # when we try to create new instance in below callback, it will be hung
    # due to exclusive locking caused with _write_hosts() method.
    # so we should do it after this callback.
    $self->_handle_hosts(
        file     => $config,
        lock     => Fcntl::LOCK_SH,
        callback => sub
        {
            my $file = shift;
            my $fh   = shift;

            while (my $line = <$fh>)
            {
                $line =~ s/^(\s+|\s+)$//g;

                next
                    if ($line =~ m/^#/
                    || $line !~ m/^(?<ip>[^\s]+)\s+(?<hosts>.+)$/);

                my %host = (
                    ip        => $+{ip},
                    hostnames => [split(/(?:[^0-9a-z\.-]+)/i, $+{hosts})],
                );

                push(@hosts, \%host);
            }
        }
    );

    foreach my $host (@hosts)
    {
        my $model = $self->new(ipaddr => $host->{ip});

        my $i = 0;

        foreach my $hostname (@{$host->{hostnames}})
        {
            $model->hostnames->[$i++] = $hostname;
        }

        splice(@{$model->hostnames}, $i);

        push(@retval, $model->ipaddr);
    }

    return wantarray ? @retval : \@retval;
};

around 'update' => sub
{
    my $orig = shift;
    my $self = shift;

    my $retval = $self->$orig(@_);

    if ($self->_write_hosts())
    {
        $self->throw_error("Failed to write hosts: ${\$self->dumper($self)}");
    }

    return $retval;
};

around 'delete' => sub
{
    my $orig = shift;
    my $self = shift;

    if ($self->_delete_hosts())
    {
        $self->throw_error(
            "Failed to delete hosts: ${\$self->dumper($self)}");
    }

    return $self->$orig($self->ipaddr);
};

around 'to_hash' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    push(@{$args{excludes}}, 'hosts_config');

    my $retval = $self->$orig(%args);

    if (ref($retval) ne 'HASH')
    {
        $self->throw_error("Failed to serialize: ${\$self->dumper($self)}");
    }

    return {
        IPAddr    => $retval->{ipaddr},
        Hostnames => $retval->{hostnames},
    };
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Network::Hosts - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

