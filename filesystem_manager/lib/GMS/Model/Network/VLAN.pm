package GMS::Model::Network::VLAN;

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
extends 'GMS::Model::Base', 'GMS::Network::VLAN';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/Network/VLAN'; };
etcd_keygen sub { device => shift };

#---------------------------------------------------------------------------
#   Overrided Attributes
#---------------------------------------------------------------------------
has '+master_meta' => (default => 'GMS::Model::Network::Device',);

upgrade_attrs(
    key      => 'device',
    excludes => ['fields', 'master_meta'],
);

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'to_hash' => sub
{
    my $orig = shift;
    my $self = shift;

    my $retval = $self->$orig();

    return {
        Device     => $retval->{device},
        Type       => $retval->{TYPE},
        BootProto  => $retval->{BOOTPROTO},
        OnBoot     => $retval->{ONBOOT},
        MTU        => $retval->{MTU},
        Speed      => $self->convert_to_bps($self->speed),
        HWAddr     => $retval->{HWADDR},
        IPAddrs    => $retval->{IPADDR},
        Netmasks   => $retval->{NETMASK},
        Gateways   => $retval->{GATEWAY},
        LinkStatus => $self->operstate,
        Model      => $self->model,
        Tag        => $self->tag,
        Master     => $retval->{MASTER},
    };
};

around 'update' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    my $retval = $self->$orig(%args);

    $self->set();

    if ($self->ONBOOT eq 'yes')
    {
        $self->up();
    }
    else
    {
        $self->down();
    }

    return $retval;
};

around 'delete' => sub
{
    my $orig = shift;
    my $self = shift;

    my $retval = $self->$orig($self->device);

    $self->down();
    $self->remove();

    return $retval;
};

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->meta->set_key(
        sprintf('%s/%s/device', __PACKAGE__->meta->etcd_root, $self->device),
        $self->device
    );
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Model::Network::VLAN - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

