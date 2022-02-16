package GMS::Controller::Cluster::Auth::LDAP;

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
extends 'GMS::Controller::Auth::LDAP';

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
            Enabled  => 0,
            URI      => undef,
            BaseDN   => undef,
            BindDN   => undef,
            PasswdDN => undef,
            ShadowDN => undef,
            GroupDN  => undef,
            SSL      => 'None',
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

    if (ref($config) ne 'HASH' || ref($config->{LDAP}) ne 'HASH')
    {
        $config->{LDAP} = $self->default_cfg;

        $self->etcd->set_key(
            key    => '/Auth',
            value  => $config,
            format => 'json',
        );
    }

    api_status(
        level   => 'INFO',
        code    => AUTH_INFO_OK,
        msgargs => [feature => 'LDAP'],
    );

    $self->render(openapi => $config->{LDAP});
};

override 'enable' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        URI => {
            isa => 'NotEmptyStr',
        },
        BindDN => {
            isa => 'NotEmptyStr',
        },
        BindPw => {
            isa => 'NotEmptyStr',
        },
        BaseDN => {
            isa => 'NotEmptyStr',
        },
        PasswdDN => {
            isa => 'NotEmptyStr',
        },
        ShadowDN => {
            isa => 'NotEmptyStr',
        },
        GroupDN => {
            isa => 'NotEmptyStr',
        },
        SSL => {
            isa => 'NotEmptyStr',
        },
    };

    my $args = $self->validate($rule, $params);

    # 클러스터 인증 설정 정보 조회
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

    # 개별 노드에 대해 활성화
    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/auth/ldap/enable',
        body => $args,
    );

    my @msgs = ();

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        push(@msgs, sprintf('%s: %s', $resp->hostname, $resp->msg));
    }

    $self->throw_error(join("\n", @msgs)) if (@msgs);

    map { $config->{LDAP}->{$_} = $args->{$_}; }
        (qw/URI BaseDN BindDN PasswdDN ShadowDN GroupDN SSL/);

    $config->{LDAP}->{SSL}     = 'None' if (!defined($config->{LDAP}->{SSL}));
    $config->{LDAP}->{Enabled} = 1;

    if (
        $self->etcd->set_key(
            key    => '/Auth',
            value  => $config,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error('Failed to set LDAP authentication config');
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

    my $config = $self->etcd->get_key(key => '/Auth', format => 'json');

    my @resps = GMS::Cluster::HTTP->new->request(
        uri  => '/auth/ldap/disable',
        body => $params,
    );

    my @msgs = ();

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        push(@msgs, sprintf('%s: %s', $resp->hostname, $resp->msg));
    }

    $self->throw_error(join("\n", @msgs)) if (@msgs);

    $config->{LDAP}->{Enabled} = 0;

    if (
        $self->etcd->set_key(
            key    => '/Auth',
            value  => $config,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error('Failed to set LDAP authentication config');
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

GMS::Controller::Cluster::Auth::LDAP - 

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

