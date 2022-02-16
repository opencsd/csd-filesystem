package Mock::Model::Network::Bonding;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Model::Network::Bonding;

#---------------------------------------------------------------------------
#   Model Definitions
#---------------------------------------------------------------------------
etcd_root sub { GMS::Model::Network::Bonding->meta->etcd_root; };
etcd_keygen sub { device => shift; };

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Network::Bonding';

#---------------------------------------------------------------------------
#   Overrided Attrs
#---------------------------------------------------------------------------
has '+path' => (default => '/tmp/etc/sysconfig/network-scripts',);

has '+sysfs_path' => (default => '/tmp/sys/class/net',);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'to_hash' => sub
{
    my $self = shift;

    my $retval = super();

    map { delete($retval->{$_}); } qw/mock etcd_data/;

    return $retval;
};

override 'probe_kernel_module' => sub
{
    return 0;
};

override 'update_module_option' => sub
{
    return 0;
};

override 'add_device' => sub
{
    my $self = shift;
    my %args = @_;

    system("touch ${\$self->sysfs_path}/${\$self->device}");

    return super();
};

override 'remove_device' => sub
{
    my $self = shift;
    my %args = @_;

    unlink("${\$self->sysfs_path}/${\$self->device}");

    return super();
};

override 'up' => sub
{
    return 0;
};

override 'down' => sub
{
    return 0;
};

#---------------------------------------------------------------------------
#   Overloaded Methods
#---------------------------------------------------------------------------
sub get_slave_meta
{
    return 'Mock::Model::Network::Device';
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

Mock::Model::Network::Bonding - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

