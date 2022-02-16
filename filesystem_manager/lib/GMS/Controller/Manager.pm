package GMS::Controller::Manager;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Account::AccountCtl;
use GMS::API::Return;
use GMS::Auth::PAM::PWQuality;
use Guard;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'valid_attrs' => (
    is         => 'ro',
    isa        => 'ArrayRef',
    auto_deref => 1,
    default    => sub
    {
        [
            qw(
                ID Name Email Phone Organization
                Engineer EngineerPhone EngineerEmail
            )
        ];
    },
);

has 'account' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Account::Local->new(); },
);

has 'pwquality' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Auth::PAM::PWQuality->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $manager;

    # :TODO 2019년 04월 04일 14시 02분 37초: by P.G.
    # We need to remove this trick after providing a delegation
    # 1. 사용자 목록에서 해당 사용자 존재 여부 검사
    my $user = $self->account->find_user(name => $params->{ID});

    if (!defined($user))
    {
        $self->throw_error(
            level   => 'ERROR',
            code    => USER_NOT_FOUND,
            msgargs => [user => $params->{ID}],
        );
    }

    # 2. 존재할 경우, 해당 사용자가 관리자 목록에 있는지 확인
    my $managers = $self->etcd->get_key(
        key    => '/Manager',
        format => 'json',
    );

    if (!defined($managers->{$params->{ID}}))
    {
        $self->throw_error(
            level   => 'ERROR',
            code    => MANAGER_NOT_DELEGATED,
            msgargs => [user => $params->{ID}],
        );
    }

    $manager = $managers->{$params->{ID}};

    api_status(
        level => 'INFO',
        code  => MANAGER_INFO_SUCCESS,
    );

    $self->render(json => $manager);
}

sub update
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => 'Manager');
    $self->gms_lock(scope => 'Account/User');

    scope_guard
    {
        $self->gms_unlock(scope => 'Manager');
        $self->gms_unlock(scope => 'Account/User');
    };

    # :TODO 2019년 04월 04일 14시 02분 37초: by P.G.
    # We need to remove this trick after providing a delegation
    # 1. 사용자 목록에서 해당 사용자 존재 여부 검사
    my $user = $self->account->find_user(name => $params->{ID});

    if (!defined($user))
    {
        $self->throw_error("Could not find a user: $params->{ID}");
    }

    # 2. 존재할 경우, 해당 사용자가 관리자 목록에 있는지 확인
    my $managers = $self->etcd->get_key(key => '/Manager', format => 'json');
    my $manager  = $managers->{$params->{ID}};

    if (!defined($manager))
    {
        $self->throw_error(
            level   => 'ERROR',
            code    => MANAGER_NOT_DELEGATED,
            msgargs => [user => $params->{ID}],
        );
    }

    if (defined($params->{Password}))
    {
        $params->{Password} = $self->rsa_decrypt(data => $params->{Password});

        if ($self->pwquality->is_valid_passwd(passwd => $params->{Password}))
        {
            $self->throw_error(
                "This password does not come up to policy: $params->{Password}"
            );
        }

        my $users = $self->etcd->get_key(
            key    => '/UserInfo',
            format => 'json',
        );

        $users->{$params->{ID}}->{sp_pwd}
            = $self->account->crypt_passwd(plaintext => $params->{Password});

        if (
            $self->etcd->set_key(
                key    => '/UserInfo',
                value  => $users,
                format => 'json',
            ) <= 0
            )
        {
            $self->throw_error(
                sprintf('Failed to update user info: %s',
                    $self->dumper($users->{$params->{ID}}))
            );
        }

        my @resps = GMS::Cluster::HTTP->new->request(
            uri => '/api/cluster/account/user/reload');

        my @msgs = map { sprintf('%s: %s', $_->hostname, $_->msg); }
            (grep { !$_->success; } @resps);

        $self->throw_error(join("\n", @msgs)) if (@msgs);
    }

    map { $manager->{$_} = $params->{$_}; }
        grep { exists($params->{$_}); } $self->valid_attrs;

    if (
        $self->etcd->set_key(
            key    => '/Manager',
            value  => $managers,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set manager setting: ${\$self->dumper($managers)}");
    }

    api_status(
        level   => 'INFO',
        code    => MANAGER_UPDATE_SUCCESS,
        msgargs => [manager => $params->{ID}],
    );

    return $self->render(json => $manager);
}

sub delegate
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => 'Manager');
    $self->gms_lock(scope => 'Account/User');

    scope_guard
    {
        $self->gms_unlock(scope => 'Manager');
        $self->gms_unlock(scope => 'Account/User');
    };

    my $manager;

    # 1. 사용자 목록에서 해당 사용자 존재 여부 검사
    my $user = $self->account->find_user(name => $params->{ID});

    if (!defined($user))
    {
        $self->throw_error(
            level   => 'ERROR',
            code    => USER_NOT_FOUND,
            msgargs => [user => $params->{ID}],
        );
    }

    # 2. 존재할 경우, 해당 사용자가 관리자 목록에 있는지 확인
    my $managers = $self->etcd->get_key(
        key    => '/Manager',
        format => 'json',
    );

    if (defined($managers->{$params->{ID}}))
    {
        api_status(
            level   => 'INFO',
            code    => MANAGER_ALREADY_DELEGATED,
            msgargs => [user => $params->{ID}],
        );

        goto RETURN;
    }

    # 3. 관리자 정보 기록
    my @attrs = grep { $_ ne 'ID'; } $self->valid_attrs;

    map {
        if (exists($params->{$_}))
        {
            $managers->{$params->{ID}}->{$_} = $params->{$_};
        }
    } @attrs;

    if (
        $self->etcd->set_key(
            key    => '/Manager',
            value  => $managers,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set manager setting: ${\$self->dumper($managers)}");
    }

    $manager = $managers->{$params->{ID}};

    api_status(
        level   => 'INFO',
        code    => MANAGER_DELEGATED,
        msgargs => [user => $params->{ID}],
    );

    $self->app->gms_new_event();

RETURN:
    $self->render(json => $managers->{$params->{ID}});
}

sub dismiss
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => 'Manager');
    $self->gms_lock(scope => 'Account/User');

    scope_guard
    {
        $self->gms_unlock(scope => 'Manager');
        $self->gms_unlock(scope => 'Account/User');
    };

    my $manager;

    # 1. 사용자 목록에서 해당 사용자 존재 여부 검사
    my $user = $self->account->find_user(name => $params->{ID});

    if (!defined($user))
    {
        $self->throw_error(
            level   => 'ERROR',
            code    => USER_NOT_FOUND,
            msgargs => [user => $params->{ID}],
        );
    }

    # 2. 존재할 경우, 해당 사용자가 관리자 목록에 있는지 확인
    my $managers = $self->etcd->get_key(key => '/Manager', format => 'json');

    if (!defined($managers->{$params->{ID}}))
    {
        api_status(
            level   => 'INFO',
            code    => MANAGER_NOT_DELEGATED,
            msgargs => [user => $params->{ID}],
        );

        goto RETURN;
    }

    # 3. 관리자 정보 제거
    $manager = delete($managers->{$params->{ID}});

    if (
        $self->etcd->set_key(
            key    => '/Manager',
            value  => $managers,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set manager setting: ${\$self->dumper($manager)}");
    }

    api_status(
        level   => 'INFO',
        code    => MANAGER_DISMISSED,
        msgargs => [user => $params->{ID}],
    );

    $self->app->gms_new_event();

RETURN:
    $self->render(json => $manager);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Manager - GMS manager controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

