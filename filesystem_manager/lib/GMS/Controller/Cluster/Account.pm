package GMS::Controller::Cluster::Account;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Guard;
use GMS::API::Return qw/:ACCOUNT/;
use GMS::Cluster::HTTP;
use List::MoreUtils qw/uniq/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Account';

#---------------------------------------------------------------------------
#  Role Consuming
#---------------------------------------------------------------------------
with 'GMS::Controller::Cluster::Role::Account';

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------
override 'user_create' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->sync_smb(local => 0);

    my $result = super();

    #$self->gms_lock(scope => '/Account/User');
    #
    #my $guard = guard { $self->gms_unlock(scope => '/Account/User'); };

    $self->sync_smb(local => 1);

    $self->update_user_data($params->{entity}->{User_Name});

    #undef($guard);

    my $http = GMS::Cluster::HTTP->new();

    my @resps = $http->request(
        uri  => '/api/cluster/account/user/reload',
        body => {argument => $params->{argument}},
    );

    my @failed;

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        warn sprintf(
            '[ERR] Failed to reload users: %s: %s',
            $resp->host, $self->dumper($resp->data),
        );

        push(@failed, $resp);
    }

    if (@failed)
    {
        $self->throw_error(
            sprintf('Failed to reload users in some nodes: %s',
                join(', ', map { $_->host; } @failed))
        );
    }

    $self->render(json => $result);
};

override 'user_update' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->sync_smb(local => 0);

    my $result = super();

    $self->sync_smb(local => 1);

    $self->update_user_data($params->{entity}->{User_Name});

    #undef($guard);

    my $http = GMS::Cluster::HTTP->new();

    my @resps = $http->request(
        uri  => '/api/cluster/account/user/reload',
        body => {argument => $params->{argument}},
    );

    my @failed;

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        warn sprintf(
            '[ERR] Failed to reload users: %s: %s',
            $resp->host, $self->dumper($resp->data),
        );

        push(@failed, $resp);
    }

    if (@failed)
    {
        $self->throw_error(
            sprintf('Failed to reload users in some nodes: %s',
                join(', ', map { $_->host; } @failed))
        );
    }

    $self->render(json => $result);
};

override 'user_delete' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->sync_smb(local => 0);

    my $result = super();

    $self->sync_smb(local => 1);

    $self->delete_user_data($params->{entity}->{User_Names});

    #undef($guard);

    my $http = GMS::Cluster::HTTP->new();

    my @resps = $http->request(
        uri  => '/api/cluster/account/user/reload',
        body => {argument => $params->{argument}},
    );

    my @failed;

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        warn sprintf(
            '[ERR] Failed to reload users: %s: %s',
            $resp->host, $self->dumper($resp->data),
        );

        push(@failed, $resp);
    }

    if (@failed)
    {
        $self->throw_error(
            sprintf('Failed to reload users in some nodes: %s',
                join(', ', map { $_->host; } @failed))
        );
    }

RETURN:
    $self->render(json => $result);
};

sub user_reload
{
    my $self = shift;
    my %args = @_;

    my $params = $self->req->json;

    $self->gms_lock(scope => '/Account/User');

    scope_guard { $self->gms_unlock(scope => '/Account/User'); };

    $self->sync_smb(local => 0);

    my $users = $self->etcd->get_key(key => '/Users', format => 'json');

    my $result = $self->ctl->user_reload(
        argument => $params->{argument},
        entity   => $users,
    );

    $self->sync_smb(local => 1);

    $self->render(json => $result);
}

override 'group_create' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = super();

    $self->update_group_data($params->{entity}->{Group_Name});

    my $http = GMS::Cluster::HTTP->new();

    my @resps = $http->request(
        uri  => '/api/cluster/account/group/reload',
        body => {argument => $params->{argument}},
    );

    my @failed;

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        warn sprintf(
            '[ERR] Failed to reload groups: %s: %s',
            $resp->host, $self->dumper($resp->data),
        );

        push(@failed, $resp);
    }

    if (@failed)
    {
        $self->throw_error(
            sprintf('Failed to reload groups in some nodes: %s',
                join(', ', map { $_->host; } @failed))
        );
    }

RETURN:
    $self->render(json => $result);
};

override 'group_update' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = super();

    $self->update_group_data($params->{entity}->{Group_Name});

    my $http = GMS::Cluster::HTTP->new();

    my @resps = $http->request(
        uri  => '/api/cluster/account/group/reload',
        body => {argument => $params->{argument}},
    );

    my @failed;

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        warn sprintf(
            '[ERR] Failed to reload groups: %s: %s',
            $resp->host, $self->dumper($resp->data),
        );

        push(@failed, $resp);
    }

    if (@failed)
    {
        $self->throw_error(
            sprintf('Failed to reload groups in some nodes: %s',
                join(', ', map { $_->host; } @failed))
        );
    }

RETURN:
    $self->render(json => $result);
};

override 'group_delete' => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = super();

    $self->delete_group_data($params->{entity}->{Group_Names});

    my $http = GMS::Cluster::HTTP->new();

    my @resps = $http->request(
        uri  => '/api/cluster/account/group/reload',
        body => {argument => $params->{argument}},
    );

    my @failed;

    foreach my $resp (@resps)
    {
        next if ($resp->success);

        warn sprintf(
            '[ERR] Failed to reload groups: %s: %s',
            $resp->host, $self->dumper($resp->data),
        );

        push(@failed, $resp);
    }

    if (@failed)
    {
        $self->throw_error(
            sprintf('Failed to reload groups in some nodes: %s',
                join(', ', map { $_->host; } @failed))
        );
    }

RETURN:
    $self->render(json => $result);
};

sub group_reload
{
    my $self = shift;
    my %args = @_;

    my $params = $self->req->json;

    $self->gms_lock(scope => '/Account/User');

    scope_guard { $self->gms_unlock(scope => '/Account/User'); };

    my $groups = $self->etcd->get_key(key => '/Groups', format => 'json');

    my $result = $self->ctl->group_reload(
        argument => $params->{argument},
        entity   => $groups,
    );

    $self->render(json => $result);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Account - Account management API controller for GMS cluster

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

