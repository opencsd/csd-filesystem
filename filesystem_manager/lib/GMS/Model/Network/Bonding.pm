package GMS::Model::Network::Bonding;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Network::Type;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Base', 'GMS::Network::Bonding';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { '/{hostname}/Network/Bonding'; };
etcd_keygen sub { device => shift };

#---------------------------------------------------------------------------
#   Overrided Attributes
#---------------------------------------------------------------------------
upgrade_attrs(
    key      => 'device',
    excludes => ['fields', 'slaves'],
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub str_mode
{
    my $self = shift;

    my $modes = GMS::Network::Type::supported_bonding_modes();

    foreach my $key (keys(%{$modes}))
    {
        return $key if ($modes->{$key} == $self->mode);
    }
}

override 'get_slave_meta' => sub
{
    my $self = shift;
    my $name = shift;

    (my $meta = super()) =~ s/^GMS:://g;

    return "GMS::Model::$meta";
};

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
around 'to_hash' => sub
{
    my $orig = shift;
    my $self = shift;

    my $retval = $self->$orig();

    return {
        Device      => $retval->{device},
        Type        => $retval->{TYPE},
        BootProto   => $retval->{BOOTPROTO},
        OnBoot      => $retval->{ONBOOT},
        MTU         => $retval->{MTU},
        Speed       => $self->convert_to_bps($self->speed),
        HWAddr      => $retval->{HWADDR},
        IPAddrs     => $retval->{IPADDR},
        Netmasks    => $retval->{NETMASK},
        Gateways    => $retval->{GATEWAY},
        LinkStatus  => $self->operstate,
        Mode        => $retval->{mode},
        PrintMode   => $self->str_mode(),
        Slaves      => [keys(%{$self->slaves})],
        Primary     => $self->primary      // 'None',
        ActiveSlave => $self->active_slave // 'None',
        Model       => $self->model,
    };
};

around 'update' => sub
{
    my $orig = shift;
    my $self = shift;
    my %args = @_;

    if (exists($args{slaves}))
    {
        foreach my $slave (values(%{$self->slaves}))
        {
            next if (grep { $slave->device eq $_ } @{$args{slaves}});

            if (!defined($self->delete_slave($slave->device)))
            {
                $self->throw_exception(
                    'DeleteFailure',
                    resource => 'network bonding slave',
                    name     => $slave->device,
                );
            }
        }

        $args{slaves} = {
            map {
                my $device = $_;
                $device => $self->get_slave_meta($_)->find($_);
            } @{$args{slaves}}
        };
    }

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

    foreach my $slave (values(%{$self->slaves}))
    {
        if (!defined($self->delete_slave($slave->device)))
        {
            $self->throw_exception(
                'DeleteFailure',
                resource => 'network bonding slave',
                name     => $slave->device,
            );
        }
    }

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

GMS::Model::Network::Bonding - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

