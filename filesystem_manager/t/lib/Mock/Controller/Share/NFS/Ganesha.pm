package Mock::Controller::Share::NFS::Ganesha;

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
use Mock::Sub;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Share::NFS::Ganesha';

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
        Share   => 'Mock::Model::Share',
        Zone    => 'Mock::Model::Network::Zone',
        Export  => 'Mock::Model::NFS::Ganesha::Export',
        Default => 'Mock::Model::NFS::Ganesha::Default',
    };
};

sub mock_service
{
    my $mock = Test::MockModule->new('GMS::System::Service');

    state $enabled = 0;

    $mock->mock(service_enabled => sub { return $enabled++; });
    $mock->mock(enable_service  => sub { return 0; });
    $mock->mock(control_service => sub { return 0; });

    return $mock;
}

sub mock_exec
{
    my $mock = Test::MockModule->new('GMS::Common::IPC');

    my $nfsstatus = <<"ENDL";

ENDL

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

            if ($args{cmd} eq 'lsb_release')
            {
                $retval{out} = <<"ENDL";
LSB Version:    :core-4.1-amd64:core-4.1-noarch
Distributor ID: CentOS
Description:    CentOS Linux release 7.3.1611 (Core)
Release:        7.3.1611
Codename:       Core
ENDL
            }
            elsif ($args{cmd} eq 'ganesha_stats')
            {
#                if (ref($args{args}) ne 'ARRAY'
#                    || grep { $_ eq '-p' } @{$args{args}})
#                {
#                    $retval{out} .= $nfsstatus;
#                }
            }

            return \%retval;
        }
    );

    return $mock;
}

sub mock_cluster_volume
{
    my $mock = Test::MockModule->new('GMS::Cluster::Volume');

    $mock->mock(
        volumelist => sub
        {
            my $hostname = short();

            return [
                {
                    'Pool_Name'      => 'vg_test',
                    'Volume_Name'    => 'test-vol',
                    'Volume_Type'    => 'Gluster',
                    'Volume_Mount'   => '/export/test-vol',
                    'Volume_Policy'  => 'Distribute',
                    'Volume_Used'    => '12%',
                    'Transport_Type' => 'tcp',
                    'Provision'      => 'thick',
                    'Policy'         => 'Distributed',
                    'Size'           => '10.0G',
                    'Nodes'          => [
                        {
                            'SW_Status'        => 'OK',
                            'Mgmt_Hostname'    => $hostname,
                            'HW_Status'        => 'OK',
                            'Node_Used'        => '0%',
                            'Storage_Hostname' => $hostname,
                        }
                    ],
                    'Node_List'         => [$hostname],
                    'Oper_Stage'        => undef,
                    'Replica_Count'     => 1,
                    'Disperse_Count'    => 0,
                    'Dist_Node_Count'   => 1,
                    'Stripe_Count'      => 0,
                    'Code_Count'        => 0,
                    'Distributed_Count' => 1,
                    'Arbiter'           => 'na',
                    'Arbiter_Count'     => 0,
                    'Shard'             => 'false',
                    'Shard_Block_Size'  => undef,
                    'Chaining'          => 'not_chained',
                    'Hot_Tier'          => 'false',
                    'Status_Code'       => 'OK',
                    'Status_Msg'        => 'Started',
                    'Options'           => {
                        'diagnostics.client-sys-log-level' => 'WARNING',
                        'diagnostics.brick-sys-log-level'  => 'WARNING',
                        'features.uss'                     => 'on',
                        'network.ping-timeout'             => 30,
                        'snap-max-soft-limit'              => 100,
                        'snap-max-hard-limit'              => 256,
                        'transport.address-family'         => 'inet',
                        'nfs.disable'                      => 'on'
                    },
                }
            ];
        }
    );

    return $mock;
}

sub mock_http_req
{
    my $mock = Test::MockModule->new('GMS::Cluster::HTTP');

    $mock->mock(request => sub { return; });

    return $mock;
}

sub BUILD
{
    my $self = shift;

    $self->add_mock(mock_service());
    $self->add_mock(mock_exec());
    $self->add_mock(mock_cluster_volume());
    $self->add_mock(mock_http_req());
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Mock::Controller::Share::NFS::Ganesha - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

