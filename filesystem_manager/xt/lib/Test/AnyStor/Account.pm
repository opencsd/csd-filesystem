package Test::AnyStor::Account;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';
use Test::Most;
use Test::AnyStor::Base;
use Data::Dumper;

extends 'Test::AnyStor::Base';

sub user_count
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/account/user/count',
        params => {
            arguments => {Location => $args{location} // 'LOCAL'},
        },
    );

    return -1 if (!$self->t->success);

    if (defined($args{number}))
    {
        is($res->{entity}->{NumOfUsers}, $args{number},
            'The number of users');
    }

    if (defined($res->{entity}) && ref($res->{entity}) eq 'HASH')
    {
        return $res->{entity}->{NumOfUsers};
    }
    else
    {
        paint_err();
        fail("No entity data for user/count");
        paint_reset();
        return -1;
    }
}

sub user_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/account/user/list',
        params => {
            arguments => {Location => $args{location} // 'LOCAL'},
        },
    );

    return -1 if (!$self->t->success);

    if (defined($args{users}))
    {
        if (ref($args{users}) eq '')
        {
            $args{users} = [$args{users}];
        }

        my @users = map { $_->{User_Name}; } @{$res->{entity}};

        foreach my $user (@{$args{users}})
        {
            ok($user ~~ @users, "User '$user' is exists");
        }
    }

    return 0;
}

sub user_info
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/account/user/info',
        params => {
            arguments => {Location  => $args{location} // 'LOCAL'},
            entity    => {User_Name => $args{name}},
        },
    );

    return !$self->t->success ? undef : $res->{entity};
}

sub user_create
{
    my $self = shift;
    my %args = @_;

    $args{prefix} = $args{prefix} // 'CST';
    $args{number} = $args{number} // 1;

    my @users;
    my $count = $self->user_count();
    my $pad   = length($args{number}) < 2 ? 2 : length($args{number});

    for (my $i = 0; $i < $args{number}; $i++)
    {
        my $username = sprintf('%s-%0*d', $args{prefix}, $pad, $i + 1);

        my %base_args = (Location => $args{location} // 'LOCAL');
        my %entity    = (
            User_Name        => $username,
            User_FullName    => $username,
            User_Office      => 'Gluesys',
            User_OfficePhone => '070-1234-5678',
            User_HomePhone   => '010-1234-5678',
            User_Email       => $username . '@gluesys.com',
            User_Desc        => sprintf('User%d', $i + 1),
            User_Password    => $self->encrypt(data => 'gluesys!!'),
        );

        my $res = $self->request(
            uri    => '/cluster/account/user/create',
            params => {
                arguments => {Location => $args{location} // 'LOCAL'},
                entity    => \%entity,
            }
        );

        next if (!$self->t->success);

        sleep 3;

        $self->check_api_code_in_recent_events(
            category => 'DEFAULT',
            prefix   => 'USER_',
            from     => $res->{prof}->{from},
            to       => $res->{prof}->{to},
            status   => $res->{success},
            ok       => ['CREATED'],
            failure  => ['CREATION_FAILURE'],
        );

        my $info = $self->user_info(name => $username);

        if (!defined($info) || ref($info) ne 'HASH')
        {
            paint_err();
            fail("ERROR: Undefined user information: ${\Dumper($info)}");
            paint_reset();
            next;
        }

        is($info->{User_Name}, $username, 'Validate user existance');

        push(@users, $username);
    }

    $self->user_count(number => $count + $args{number});

    return @users;
}

sub user_update
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/account/user/update',
        params => {
            arguments => {Location => $args{location} // 'LOCAL'},
            entity    => {
                User_Name => $args{name},
                User_Desc => "$args{name}_updated",
            },
        },
    );

    return -1 if (!$self->t->success);

    # is registed event
    sleep 3;

    $self->check_api_code_in_recent_events(
        category => 'DEFAULT',
        prefix   => 'USER_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['UPDATED'],
        failure  => ['UPDATING_FAILURE'],
    );

    my $info = $self->user_info(name => $args{name});

    if (!defined($info))
    {
        paint_err();
        fail("ERROR: Undefined user information: ${\Dumper($info)}");
        paint_reset();
        return -1;
    }

    is($info->{User_Desc}, "$args{name}_updated",
        'Validate user description');

    return 0;
}

sub user_delete
{
    my $self = shift;
    my %args = @_;

    my $names = $args{names};
    $names = [$names] if (ref($names) eq '');

    my $res = $self->request(
        uri    => '/cluster/account/user/delete',
        params => {
            arguments => {Location   => $args{location} // 'LOCAL'},
            entity    => {User_Names => $names},
        },
    );

    return -1 if (!$self->t->success);

    sleep 3;

    $self->check_api_code_in_recent_events(
        category => 'DEFAULT',
        prefix   => 'USER_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['DELETED'],
        failure  => ['DEL_FAILURE'],
    );

    return 0;
}

sub group_count
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/account/group/count',
        params => {
            arguments => {Location => $args{location} // 'LOCAL'},
        },
    );

    return -1 if (!$self->t->success);

    if (defined($args{number}))
    {
        is($res->{entity}->{NumOfGroups},
            $args{number}, 'The number of groups');
    }

    return $res->{entity}->{NumOfGroups};
}

sub group_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/account/group/list',
        params => {
            arguments => {Location => $args{location} // 'LOCAL'},
        },
    );

    return !$self->t->success ? -1 : 0;
}

sub group_info
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/account/group/info',
        params => {
            arguments => {Location   => $args{location} // 'LOCAL'},
            entity    => {Group_Name => $args{name}},
        },
    );

    return -1 if (!$self->t->success);

    return $res->{entity} // undef;
}

sub group_create
{
    my $self = shift;
    my %args = @_;

    $args{prefix} = $args{prefix} // 'CST';
    $args{number} = $args{number} // 1;

    my @groups;
    my $count = $self->group_count();

    for (my $i = 0; $i < $args{number}; $i++)
    {
        my $groupname
            = sprintf('%s-%0*d', $args{prefix}, length($args{number}),
            $i + 1);

        my $res = $self->request(
            uri    => '/cluster/account/group/create',
            params => {
                arguments => {Location => $args{location} // 'LOCAL'},
                entity    => {
                    Group_Name => $groupname,
                    Group_Desc => sprintf('Group%d', $i + 1),
                },
            },
        );

        if (!$self->t->success)
        {
            next;
        }

        sleep 3;

        $self->check_api_code_in_recent_events(
            category => 'DEFAULT',
            prefix   => 'GROUP_',
            from     => $res->{prof}->{from},
            to       => $res->{prof}->{to},
            status   => $res->{success},
            ok       => ['CREATED'],
            failure  => ['CREATION_FAILURE'],
        );

        my $info = $self->group_info(name => $groupname);

        if (!defined($info))
        {
            paint_err();
            fail("ERROR: Undefined group information: ${\Dumper($info)}");
            paint_reset();
            next;
        }

        is($info->{Group_Name}, $groupname, 'Validate group existance');

        push(@groups, $groupname);
    }

    $self->group_count(number => $count + $args{number});

    return @groups;
}

sub group_update
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/account/group/update',
        params => {
            arguments => {Location => $args{location} // 'LOCAL'},
            entity    => {
                Group_Name => $args{name},
                Group_Desc => "$args{name}_updated",
            },
        },
    );

    return -1 if (!$self->t->success);

    sleep 3;

    $self->check_api_code_in_recent_events(
        category => 'DEFAULT',
        prefix   => 'GROUP_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['UPDATED'],
        failure  => ['UPDATING_FAILURE'],
    );

    my $info = $self->group_info(name => $args{name});

    if (!defined($info))
    {
        paint_err();
        fail("ERROR: Undefined group information: ${\Dumper($info)}");
        paint_reset();
        return -1;
    }

    is($info->{Group_Desc}, "$args{name}_updated",
        'Validate group description');

    return 0;
}

sub group_delete
{
    my $self = shift;
    my %args = @_;

    my $names = ref($args{names}) eq '' ? [$args{names}] : $args{names};

    my $res = $self->request(
        uri    => '/cluster/account/group/delete',
        params => {
            arguments => {Location    => $args{location} // 'LOCAL'},
            entity    => {Group_Names => $names},
        },
    );

    return -1 if (!$self->t->success);

    sleep 3;

    $self->check_api_code_in_recent_events(
        category => 'DEFAULT',
        prefix   => 'GROUP_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['DELETED'],
        failure  => ['DEL_FAILURE'],
    );

    return 0;
}

sub join
{
    my $self = shift;
    my %args = @_;

    my @members = map { {User_Name => $_, User_Member => 'TRUE',}; }
        @{$args{members}};

    my $res = $self->request(
        uri    => '/cluster/account/group/update',
        params => {
            arguments => {Location => $args{location} // 'LOCAL'},
            entity    => {
                Group_Name    => $args{group},
                Group_Members => \@members,
            },
        },
    );

    return -1 if (!$self->t->success);

    my $info = $self->group_info(name => $args{group});

    if (!defined($info))
    {
        paint_err();
        fail("ERROR: Undefined group information: ${\Dumper($info)}");
        paint_reset();
        return -1;
    }

    foreach my $user (@{$info->{Group_Members}})
    {
        ok($user ~~ @{$args{members}},
            "User $user is joined to $args{group}");
    }

    return 0;
}

sub leave
{
    my $self = shift;
    my %args = @_;

    my @members = map { {User_Name => $_, User_Member => 'FALSE',}; }
        @{$args{members}};

    my $res = $self->request(
        uri    => '/cluster/account/group/update',
        params => {
            arguments => {Location => $args{location} // 'LOCAL'},
            entity    => {
                Group_Name    => $args{group},
                Group_Members => \@members,
            }
        },
    );

    return -1 if (!$self->t->success);

    my $info = $self->group_info(name => $args{group});

    if (!defined($info))
    {
        paint_err();
        fail("ERROR: Undefined group information: ${\Dumper($info)}");
        paint_reset();
        return -1;
    }

    foreach my $user (@{$info->{Group_Members}})
    {
        ok(!($user ~~ @{$args{members}}),
            "User $user is leaved from $args{group}");
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Test::AnyStor::Account - 계정 검사를 구현하는 클래스

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

