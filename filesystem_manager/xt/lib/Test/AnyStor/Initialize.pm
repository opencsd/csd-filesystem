package Test::AnyStor::Initialize;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::Most;
use Mojo::UserAgent;
use JSON qw/decode_json/;
use Data::Dumper;

extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub init_config
{
    my $self = shift;
    my $args = shift;

    my %payload = (
        Network => {
            Management => {
                Interface => $args->{Network}{Management}{Interface},
                Ipaddr    => $args->{Network}{Management}{Ipaddr},
                Netmask   => $args->{Network}{Management}{Netmask},
                Gateway   => $args->{Network}{Management}{Gateway},
            },
            Service => {
                Mode    => $args->{Network}{Service}{Mode},
                Primary => $args->{Network}{Service}{Primary},
                Slaves  => $args->{Network}{Service}{Slaves},
            },
            Storage => {
                Mode    => $args->{Network}{Storage}{Mode},
                Primary => $args->{Network}{Storage}{Primary},
                Slaves  => $args->{Network}{Storage}{Slaves},
                Ipaddr  => $args->{Network}{Storage}{Ipaddr},
                Netmask => $args->{Network}{Storage}{Netmask},
            },
        },
        Volume => {
            Base_Pvs => $args->{Volume}{Base_Pvs},
            Tier_Pvs => $args->{Volume}{Tier_Pvs},
        },
    );

    my $res = $self->request(
        uri    => '/cluster/init/config',
        params => \%payload,
    );

    return $res->{entity};
}

sub init_create
{
    my $self = shift;
    my $args = shift;

    my %payload = (
        Cluster_Name => $args->{cluster_name},
        Storage_IP   => {
            Start   => $args->{storage}->{start},
            End     => $args->{storage}->{end},
            Netmask => $args->{storage}->{netmask},
            Gateway => $args->{storage}->{gateway},
        },
        Service_IP => {
            Start   => $args->{service}->{start},
            End     => $args->{service}->{end},
            Netmask => $args->{service}->{netmask},
            Gateway => $args->{service}->{gateway},
        }
    );

    my $res = $self->request(
        uri    => '/cluster/init/create',
        params => \%payload
    );

    return $res->{entity};
}

sub init_join
{
    my $self = shift;
    my $args = shift;

    my $res = $self->request(
        uri    => '/cluster/init/join',
        params => {Cluster_IP => $args->{Cluster_IP}},
    );

    return $res->{entity};
}

sub init_detach
{
    my $self = shift;
    my $args = shift;

    my $res = $self->request(
        uri    => '/cluster/init/detach',
        params => {Manage_IP => $args->{target}},
    );

    return $res->{entity};
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Initialize - Test class for cluster initializing/expanding

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
