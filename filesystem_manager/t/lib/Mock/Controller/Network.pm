package Mock::Controller::Network;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use File::Path qw/make_path remove_tree/;
use Sys::Hostname::FQDN qw/short/;
use Test::MockModule;

use Mock::Model::Network::DNS;
use Mock::Model::Network::Hostname;
use Mock::Model::Network::Hosts;
use Mock::Model::Network::Route;
use Mock::Model::Network::Zone;
use Mock::Model::Network::Device;
use Mock::Model::Network::Bonding;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Network';

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'Mock::Controllable';

#---------------------------------------------------------------------------
#   Method Overriding
#---------------------------------------------------------------------------
override 'build_models' => sub
{
    my $self = shift;

    return {
        DNS        => 'Mock::Model::Network::DNS',
        Hostname   => 'Mock::Model::Network::Hostname',
        Hosts      => 'Mock::Model::Network::Hosts',
        Route      => 'Mock::Model::Network::Route',
        Zone       => 'Mock::Model::Network::Zone',
        Device     => 'Mock::Model::Network::Device',
        InfiniBand => 'Mock::Model::Network::InfiniBand',
        Bonding    => 'Mock::Model::Network::Bonding',
        VLAN       => 'Mock::Model::Network::VLAN',
    };
};

sub all_devices
{
    my $dir = '/tmp/sys/class/net';

    if (-e $dir && !-d $dir)
    {
        die "path exists but not a directory: $dir";
    }

    if (!-d $dir && make_path($dir, {error => \my $err}) == 0)
    {
        my ($path, $msg) = %{$err->[0]};

        if ($path eq '')
        {
            die "Generic error: $msg";
        }
        else
        {
            die "Failed to make directory: $path: $msg";
        }
    }

    return split(/\n/, `ls -1 /tmp/sys/class/net`);
}

sub mock_cntlr
{
    my $mock = Test::MockModule->new('GMS::Controller::Network');

    $mock->mock('control_service' => sub { return 0; });

    return $mock;
}

sub mock_device
{
    my $mock = Test::MockModule->new('GMS::Network::Device');

    $mock->mock(all_devices => &all_devices);

    return $mock;
}

sub mock_exec
{
    my $mock = Test::MockModule->new('GMS::Common::IPC');

    $mock->mock(
        exec => sub
        {
            my %args = @_;

            my %retval = (
                status => 0,
                cmd    => $args{cmd},
                out    => '',
                err    => '',
            );

            if (ref($args{args}) eq 'ARRAY' && scalar(@{$args{args}}))
            {
                $retval{cmd} .= ' ' . join(' ', @{$args{args}});
            }

            given ($args{cmd})
            {
                when ('lsb_release')
                {
                    $retval{out} = <<"ENDL";
LSB Version:    :core-4.1-amd64:core-4.1-noarch
Distributor ID: CentOS
Description:    CentOS Linux release 7.3.1611 (Core)
Release:        7.3.1611
Codename:       Core
ENDL
                }
                when ('ifenslave')
                {
                    my $enslave = $args{args}->[0] =~ m/-d/ ? 0 : 1;
                    my $bond    = $args{args}->[1];
                    my $slave   = $args{args}->[2];

                    # add slave info to sysfs for this bonding
                    if ($enslave)
                    {
                    }

                    # remove slave info from sysfs for this bonding
                    else
                    {
                    }
                }
                when ('modprobe')
                {

                }
                when ('ip')
                {

                }
                when ('ethtool')
                {

                }
                when ('lspci')
                {

                }
            }

            return \%retval;
        }
    );

    return $mock;
}

sub BUILD
{
    my $self = shift;

    $self->add_mock(mock_device());
    $self->add_mock(mock_exec());
    $self->add_mock(mock_cntlr());
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Mock::Controller::Network - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

