package GMS::Controller::Cluster::Role::Account;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse::Role;
use namespace::clean -except => 'meta';

use List::MoreUtils qw(uniq);

requires qw(ctl throw_error);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub update_user_data
{
    my $self = shift;
    my $name = shift;

    my $user = $self->ctl->controller->find_user(name => $name);

    if (!defined($user))
    {
        $self->throw_error("Could not find the user: $name");
    }

    my $data = $self->etcd->get_key(
        key    => '/Users',
        format => 'json',
    );

    foreach my $key (keys(%{$user}))
    {
        if ($key eq 'gecos')
        {
            my @gecos;

            if (defined($user->{gecos}) && length($user->{gecos}))
            {
                @gecos = split(/\s*,\s*/, $user->{gecos}, 6);
            }
            else
            {
                @gecos = ('') x 6;
            }

            @{$data->{$name}}
                {qw/fullname office officephone homephone email desc/}
                = @gecos;

            next;
        }

        $data->{$name}->{$key} = $user->{$key};
    }

    if (
        $self->etcd->set_key(
            key    => '/Users',
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error("Failed to update the user: $name");
    }

    return $data;
}

sub delete_user_data
{
    my $self  = shift;
    my $names = shift;

    my $data = $self->etcd->get_key(
        key    => '/Users',
        format => 'json',
    );

    foreach my $name (@{$names})
    {
        # :TODO 10/31/2014 04:41:06 AM Ji-Hyeon Gim
        # UID로 삭제 시도할 경우에 대한 처리
        if (!exists($data->{$name}))
        {
            warn "[WARN] Could not find the user: $name";
            next;
        }

        delete($data->{$name});
    }

    if (
        $self->etcd->set_key(
            key    => '/Users',
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error("Failed to delete the users: $names");
    }

    return $data;
}

sub update_group_data
{
    my $self = shift;
    my $name = shift;

    my $group = $self->ctl->controller->find_group(name => $name);

    if (!defined($group))
    {
        $self->throw_error("Could not find the group: $name");
    }

    my $data = $self->etcd->get_key(
        key    => '/Groups',
        format => 'json',
    );

    foreach my $key (keys(%{$group}))
    {
        # 아래 그룹 구성원의 정보는 앞서 update_group이 수행되었다면
        # 중복 제거 및 실존 사용자 확인이 되었음을 알 수 있다.
        # 따라서 여기에서는 중복 사용자 제거만 한 이후 데이터베이스에
        # 저장하고 있다.
        if ($key eq 'members')
        {
            $data->{$name}->{$key} = [uniq(@{$group->{members}})];
        }
        else
        {
            $data->{$name}->{$key} = $group->{$key};
        }
    }

    if (
        $self->etcd->set_key(
            key    => '/Groups',
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error("Failed to update the group: $name");
    }

    return $data;
}

sub delete_group_data
{
    my $self  = shift;
    my $names = shift;

    my $data = $self->etcd->get_key(
        key    => '/Groups',
        format => 'json',
    );

    foreach my $name (@{$names})
    {
        if (!exists($data->{$name}))
        {
            warn "[WARN] Could not find group: $name";
            next;
        }

        # :TODO 10/31/2014 04:41:06 AM Ji-Hyeon Gim
        # GID로 삭제 시도할 경우에 대한 처리
        delete($data->{$name});
    }

    if (
        $self->etcd->set_key(
            key    => '/Groups',
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error("Failed to delete the groups: $names");
    }
}

sub sync_smb
{
    my $self = shift;
    my %args = @_;

    my $local = $args{local} // 0;

    my @srcdst = ('/mnt/private/samba/db/private', '/var/lib/samba/private');

    if ($local)
    {
        push(@srcdst, shift(@srcdst));
    }

    foreach my $dir (@srcdst)
    {
        if (!-d $dir && !make_path($dir, {error => \my $err}))
        {
            warn sprintf('[ERR] Failed to make directory: %s: %s',
                $dir, $self->dumper($err));

            return -1;
        }
    }

    # Samba 패스워드 데이터베이스 복사
    foreach my $file (qw|passdb.tdb|)
    {
        my $src = sprintf('%s/%s', $srcdst[0], $file);
        my $dst = sprintf('%s/%s', $srcdst[1], $file);

        if (!-e $src && !-e $dst)
        {
            warn sprintf('[ERR] Could not sync samba database'
                    . ' because both local and cluster database do not exist'
                    . '(src: %s, dst: %s)',
                $src, $dst);

            return -1;
        }
        elsif (!-e $src)
        {
            warn sprintf(
                '[DEBUG] File does not exist so will replace with local file'
                    . ': %s => %s',
                $dst, $src);

            my $tmp = $src;
            $src = $dst;
            $dst = $tmp;
        }

        my $result = GMS::Common::IPC::exec(
            cmd     => 'cp',
            args    => ['-af', $src, $dst],
            timeout => 10,
        );

        if (!defined($result) || $result->{status})
        {
            warn sprintf('[ERR] Failed to copy samba account database: %s',
                $self->dumper($result));

            return -1;
        }
    }

    return 0;

}

1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Role::Account - Account management role for GMS cluster

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

