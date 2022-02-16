package GMS::Controller::Cluster::Auth::ADS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Sys::Hostname::FQDN qw/short/;
use Try::Tiny;

use GMS::API::Return qw/:AUTH api_status/;
use GMS::Cluster::HTTP;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Auth::ADS';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
has 'default_cfg' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub
    {
        {
            Enabled => 0,
            Realm   => undef,
            DC      => undef,
            NBName  => undef,
        };
    },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
override 'info' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my $config = $self->etcd->get_key(key => '/Auth', format => 'json');

    if (ref($config) ne 'HASH' || ref($config->{ADS}) ne 'HASH')
    {
        $config->{ADS} = $self->default_cfg;

        $self->etcd->set_key(
            key    => '/Auth',
            value  => $config,
            format => 'json',
        );
    }

    api_status(
        level   => 'INFO',
        code    => AUTH_INFO_OK,
        msgargs => [feature => 'ADS'],
    );

    $self->render(openapi => $config->{ADS});
};

override 'enable' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my $cinfo = $self->etcd->get_key(
        key    => '/ClusterInfo',
        format => 'json',
    );

    if (ref($cinfo) ne 'HASH')
    {
        $self->throw_error('Failed to get config: ClusterInfo');
    }

    my $cname
        = (ref($cinfo->{cluster}) eq 'HASH'
            && defined($cinfo->{cluster}->{cluster_name}))
        ? $cinfo->{cluster}->{cluster_name}
        : substr(short(), 0, rindex(short(), '-'));

    state $rule = {
        Realm => {
            isa => 'NotEmptyStr',
        },
        DC => {
            isa => 'NotEmptyStr',
        },
        NBName => {
            isa     => 'NotEmptyStr',
            default => sub { $cname },
        },
        Admin => {
            isa => 'NotEmptyStr',
        },
        Password => {
            isa => 'NotEmptyStr',
        },
    };

    my $args = $self->validate($rule, $params);

    # 클러스터 인증 설정 정보 조회
    my $config = $self->etcd->get_key(
        key    => '/Auth',
        format => 'json',
    );

    if (ref($config) ne 'HASH' || ref($config->{ADS}) ne 'HASH')
    {
        $config->{ADS} = $self->default_cfg;

        $self->etcd->set_key(
            key    => '/Auth',
            value  => $config,
            format => 'json',
        );
    }

    # 개별 노드에 대해 활성화
    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/api/auth/ads/enable',
        body => {
            Realm    => $args->{Realm},
            DC       => $args->{DC},
            Admin    => $args->{Admin},
            Password => $args->{Password},
        }
    );

    my @msgs = ();

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        push(@msgs, sprintf('%s: %s', $resp->hostname, $resp->msg));
    }

    $self->throw_error(join("\n", @msgs)) if (@msgs);

    # 클러스터 DNS 갱신
    #$self->_register_dns(
    #    hostname => sprintf('%s.%s', $cname, $params->{Realm}),
    #    addrs    => \@addrs,
    #);

    # etcd 설정 갱신
    map { $config->{ADS}->{$_} = $args->{$_}; } qw/Realm DC NBName Admin/;

    $config->{ADS}->{Enabled} = 1;

    if (
        $self->etcd->set_key(
            key    => '/Auth',
            value  => $config,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error('Failed to set ADS authentication config');
    }

RETURN:
    $self->publish_event();

    return $self->render(
        openapi => undef,
        status  => 204,
    );
};

override 'disable' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my $cinfo = $self->etcd->get_key(
        key    => '/ClusterInfo',
        format => 'json',
    );

    if (ref($cinfo) ne 'HASH')
    {
        $self->throw_error('Failed to get config: ClusterInfo');
    }

    my $cname
        = (ref($cinfo->{cluster}) eq 'HASH'
            && defined($cinfo->{cluster}->{cluster_name}))
        ? $cinfo->{cluster}->{cluster_name}
        : substr(short(), 0, rindex(short(), '-'));

    state $rule = {
        Realm => {
            isa => 'NotEmptyStr',
        },
        DC => {
            isa => 'NotEmptyStr',
        },
        NBName => {
            isa     => 'NotEmptyStr',
            default => sub { $cname },
        },
        Admin => {
            isa => 'NotEmptyStr',
        },
        Password => {
            isa => 'NotEmptyStr',
        },
    };

    my $args = $self->validate($rule, $params);

    my $config = $self->etcd->get_key(
        key    => '/Auth',
        format => 'json',
    );

    if ($config->{ADS}->{Realm} ne $args->{Realm})
    {
        $self->throw_error(
            status  => 404,
            message => sprintf('Realm not found: %s', $args->{Realm}),
        );
    }

    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/api/auth/ads/disable',
        body => {
            Realm    => $args->{Realm},
            DC       => $args->{DC},
            Admin    => $args->{Admin},
            Password => $args->{Password},
        },
    );

    my @msgs = ();

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        push(@msgs, sprintf('%s: %s', $resp->hostname, $resp->msg));
    }

    $self->throw_error(join("\n", @msgs)) if (@msgs);

    # 클러스터 DNS 제거
#    $self->_unregister_dns(
#        hostname => sprintf('%s.%s', $cname, $params->{Realm}),
#    );

    $config->{ADS}->{Enabled} = 0;

    if (
        $self->etcd->set_key(
            key    => '/Auth',
            value  => $config,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error('Failed to set ADS authentication config');
    }

RETURN:
    $self->publish_event();

    return $self->render(
        openapi => 'OK',
        status  => 204,
    );
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Auth::ADS - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item B<Item 1>

=item B<Item 2>

=item B<Item 3>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

