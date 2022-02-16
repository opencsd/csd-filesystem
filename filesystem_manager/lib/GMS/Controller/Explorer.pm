package GMS::Controller::Explorer;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Dumper;
use File::stat;
use POSIX qw/getgroups/;

use GMS::API::Return qw/:EXPLORER api_status/;
use GMS::Common::IPC;
use GMS::Common::Useful;
use GMS::Common::SwitchPermission qw/
    convert_full_rwx_to_mask convert_auto_to_rwx mask
    /;
use GMS::Explorer::ExplorerCtl;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'ctl' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Explorer::ExplorerCtl->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->list_dir($params->{argument}, $params->{entity});

    $self->render(json => $result);
}

sub info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->info_dir($params->{argument}, $params->{entity},);

    $self->render(json => $result);
}

sub check_dir
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->is_dir($params->{argument}, $params->{entity},);

    $self->render(json => $result);
}

sub make_dir
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->mk_dir($params->{argument}, $params->{entity},);

    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => $result);
}

sub change_perm
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->ch_perm($params->{argument}, $params->{entity},);

    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => $result);
}

sub change_own
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->ch_own($params->{argument}, $params->{entity},);

    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => $result);
}

sub conv_user
{
    my $self = shift;
    my %args = @_;

    my $retval;

    setpwent;

    while (my ($name, undef, $uid) = getpwent())
    {
        if (defined($args{name}) && $args{name} eq $name)
        {
            $retval = $uid;
            last;
        }

        if (defined($args{uid}) && $args{uid} == $uid)
        {
            $retval = $name;
            last;
        }
    }

    endpwent;

    return $retval;
}

sub find_member
{
    my $self = shift;
    my %args = @_;

    my $retval;

    setpwent;

    while (my ($name, undef, $uid, $gid) = getpwent())
    {
        if (defined($args{gid}) && $args{gid} == $gid)
        {
            $retval = [$name, $uid];
            last;
        }
    }

    endpwent;

    return ref($retval) eq 'ARRAY' ? @{$retval} : undef;
}

sub conv_group
{
    my $self = shift;
    my %args = @_;

    my $retval;

    setgrent;

    while (my ($name, undef, $gid, undef) = getgrent())
    {
        if (defined($args{name}) && $args{name} eq $name)
        {
            $retval = $gid;
            last;
        }

        if (defined($args{gid}) && $args{gid} == $gid)
        {
            $retval = $name;
            last;
        }
    }

    endgrent;

    return $retval;
}

sub getfacl
{
    my $self   = shift;
    my $params = $self->req->json;

    my $type = $params->{argument}->{Type};
    my $path = $params->{argument}->{Path};

    my $acls = $self->ctl->get_acl(path => $path);

    my @retval;

    if (ref($acls) ne 'HASH')
    {
        warn "[ERR] Failed to get ACL: $path";

        api_status(
            level   => 'ERROR',
            code    => EXPLORER_GET_ACL_FAILURE,
            msgargs => [path => $path]
        );

        goto ERROR;
    }

    if (uc($type) eq 'POSIX')
    {
        my $st   = stat($path);
        my $mode = convert_auto_to_rwx($st->mode & oct(777));

        my $uperm = $self->mode_to_ace(substr($mode, 0, 3));
        my $gperm = $self->mode_to_ace(substr($mode, 3, 3));
        my $operm = $self->mode_to_ace(substr($mode, 6, 3));

        push(
            @retval,
            {
                Type     => 'User',
                ID       => $self->conv_user(uid => $st->uid),
                Location => 'LDAP',
                Right    => $uperm,
            },
            {
                Type     => 'Group',
                ID       => $self->conv_group(gid => $st->gid),
                Location => 'LDAP',
                Right    => $gperm,
            },
            {
                Type     => 'Other',
                ID       => 'other',
                Location => 'LDAP',
                Right    => $operm,
            }
        );

        goto RETURN;
    }

    foreach my $uid (keys(%{$acls->{user}}))
    {
        my $entry = $acls->{user}->{$uid};

        push(
            @retval,
            {
                Type     => 'User',
                ID       => $self->conv_user(uid => $uid),
                Location => 'LDAP',
                Right    => $self->ace_to_perm($entry),
            }
        );
    }

    foreach my $gid (keys(%{$acls->{group}}))
    {
        my $entry = $acls->{group}->{$gid};

        push(
            @retval,
            {
                Type     => 'Group',
                ID       => $self->conv_group(gid => $gid),
                Desc     => '',
                Location => 'LDAP',
                Right    => $self->ace_to_perm($entry),
            }
        );
    }

RETURN:

    #api_status(
    #    level   => 'INFO',
    #    code    => EXPLORER_GET_ACL_OK,
    #    msgargs => [ path => $path ]
    #);

ERROR:
    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => \@retval);
}

sub mode_to_ace
{
    my $self = shift;
    my $mode = shift;

    return
        substr($mode, 0, 1) eq 'r' && substr($mode, 1, 1) eq 'w' ? 'RW'
        : substr($mode, 1, 1) eq 'w'                             ? 'W'
        : substr($mode, 0, 1) eq 'r'                             ? 'R'
        :                                                          'None';
}

sub ace_to_perm
{
    my $self  = shift;
    my $entry = shift;

    return
        $entry->{r} && $entry->{w} ? 'RW'
        : $entry->{w}              ? 'W'
        : $entry->{r}              ? 'R'
        :                            'None';
}

sub setfacl
{
    my $self   = shift;
    my $params = $self->req->json;

    my $type  = $params->{argument}->{Type};
    my $path  = $params->{argument}->{Path};
    my $perms = $params->{argument}->{Permissions};

    goto RETURN if (!scalar(@{$perms}));

    if (uc($type) eq 'POSIX')
    {
        # mode follows below format
        #   mode = 'rwxrwxrwx'
        my $mode = '---------';
        my $euid = -1;
        my $egid = -1;

        foreach my $perm (@{$perms})
        {
            my $m = $perm->{Right} =~ /None/i ? '---' : '--x';

            if (index($perm->{Right}, 'R') != -1)
            {
                substr($m, 0, 1) = 'r';
            }

            if (index($perm->{Right}, 'W') != -1)
            {
                substr($m, 0, 1) = 'r';
                substr($m, 1, 1) = 'w';
            }

            my $pos
                = uc($perm->{Type}) eq 'USER'  ? 0
                : uc($perm->{Type}) eq 'GROUP' ? 3
                :                                6;

            substr($mode, $pos, 3) = $m;

            if (uc($perm->{Type}) eq 'USER')
            {
                $euid = $self->conv_user(name => $perm->{ID});
            }
            elsif (uc($perm->{Type}) eq 'GROUP')
            {
                $egid = $self->conv_group(name => $perm->{ID});
            }
        }

        # 1. EUID/EGID 변경
        # 2. 상위 디렉터리까지의 경로 접근 권한 확인
        # 3. 불가능할 경우 오류 반환
        # 4. 가능한 경우에는 해당 디렉터리의 권한만 변경
        if (
            defined($euid)
            && !$self->is_valid_perm_user(
                path => $path,
                uid  => $euid,
                perm => substr($mode, 0, 3)
            )
            )
        {
            warn "[ERR] Invalid owner permission: $path(uid:$euid)";
            goto ERROR;
        }

        if (
            defined($egid)
            && !$self->is_valid_perm_group(
                path => $path,
                gid  => $egid,
                perm => substr($mode, 3, 3)
            )
            )
        {
            warn "[ERR] Invalid group permission: $path(gid:$egid)";
            goto ERROR;
        }

        if (!chown($euid, $egid, $path))
        {
            warn
                "[ERR] Failed to change UID/GID: $path(uid:$euid, gid:$egid): $!";
            goto ERROR;
        }

        if (!change_permission($path, convert_full_rwx_to_mask($mode), 0))
        {
            warn "[ERR] Failed to change permission: $path";
            goto ERROR;
        }

        goto RETURN;
    }

    my $result = $self->ctl->set_acl(
        path  => $path,
        perms => $self->render_perms($perms),
    );

    if (!defined($result))
    {
        warn "[ERR] Failed to set ACL: $path";

        api_status(
            level   => 'ERROR',
            code    => EXPLORER_SET_ACL_FAILURE,
            msgargs => [path => $path]
        );

        goto ERROR;
    }

RETURN:
    api_status(
        level   => 'INFO',
        code    => EXPLORER_SET_ACL_OK,
        msgargs => [path => $path]
    );

ERROR:
    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => $path);
}

sub is_valid_perm_user
{
    my $self = shift;
    my %args = @_;

    return 1
        if (substr($args{perm}, 0, 1) ne 'r'
        && substr($args{perm}, 1, 1) ne 'w');

    setpwent;
    setgrent;

    # uid가 정의된 경우, 해당 사용자의 소속 그룹에 대한 권한을 하나씩 확인
    my $uid   = $args{uid};
    my @pwent = getpwuid($uid);
    my $gid   = $pwent[3];
    my @grent = getgrgid($gid);

    endpwent;
    endgrent;

    local $( = $gid;
    local $) = $gid;
    local $< = $uid;
    local $> = $uid;

    (my $tmp_path = $args{path}) =~ s/(^\/|\/$)//g;
    my @dirs = split(/\//, $tmp_path);

    for (my $i = 0; $i < $#dirs; $i++)
    {
        my $dir = '/' . join('/', @dirs[0 .. $i]);

        next if (-r $dir);

        my $uname = $pwent[0] // 'unknown';
        my $gname = $grent[0] // 'unknown';

        warn "[ERR] Directory is not readable by user '$uname': $dir: $!";

        api_status(
            level   => 'ERROR',
            code    => EXPLORER_DIR_NOT_READABLE,
            msgargs => [
                dir   => $dir,
                user  => $uname,
                group => $gname,
                perm  => $args{perm},
            ],
        );

        return 0;
    }

    return 1;
}

sub is_valid_perm_group
{
    my $self = shift;
    my %args = @_;

    return 1
        if (substr($args{perm}, 0, 1) ne 'r'
        && substr($args{perm}, 1, 1) ne 'w');

    setpwent;
    setgrent;

    my $gid   = $args{gid};
    my @grent = getgrgid($gid);
    my ($uname, $uid) = $self->find_member(gid => $gid);

    if (!defined($uid))
    {
        my $nam = (split(/\s+/, $grent[3]))[0];
        $uid   = getpwnam($nam);
        $uname = (getpwuid($uid))[0];
    }

    endpwent;
    endgrent;

    local $( = $gid;
    local $) = $gid;
    local $< = $uid;
    local $> = $uid;

    (my $tmp_path = $args{path}) =~ s/(^\/|\/$)//g;
    my @dirs = split(/\//, $tmp_path);

    for (my $i = 0; $i < $#dirs; $i++)
    {
        my $dir = '/' . join('/', @dirs[0 .. $i]);

        next if (-r $dir);

        my $gname = $grent[0] // 'unknown';

        warn "[ERR] Directory is not readable by group '$gname': $dir: $!";

        api_status(
            level   => 'ERROR',
            code    => EXPLORER_DIR_NOT_READABLE,
            msgargs => [
                dir   => $dir,
                user  => $uname,
                group => $gname,
                perm  => $args{perm},
            ],
        );

        return 0;
    }

    return 1;
}

sub unsetfacl
{
    my $self   = shift;
    my $params = $self->req->json;

    my $path  = $params->{argument}->{Path};
    my $perms = $params->{argument}->{Permissions};

    for (my $i = 0; $i <= $#$perms; $i++)
    {
        if ($perms->[$i]->{Type} eq 'Other')
        {
            splice(@{$perms}, $i--, 1);
            next;
        }

        $perms->[$i]->{ID}
            = $perms->[$i]->{Type} eq 'User'
            ? $self->conv_user(name => $perms->[$i]->{ID})
            : $self->conv_group(name => $perms->[$i]->{ID});
    }

    my $result = $self->ctl->unset_acl(
        path  => $path,
        perms => $self->render_perms($perms)
    );

    if (!defined($result))
    {
        warn "[ERR] Failed to unset ACL: $path";

        api_status(
            level   => 'ERROR',
            code    => EXPLORER_UNSET_ACL_FAILURE,
            msgargs => [path => $path]
        );

        goto ERROR;
    }

RETURN:
    api_status(
        level   => 'INFO',
        code    => EXPLORER_UNSET_ACL_OK,
        msgargs => [path => $path]
    );

ERROR:
    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => $path);
}

sub render_perms
{
    my $self  = shift;
    my $perms = shift;

    my %retval;

    for (my $i = 0; $i <= $#$perms; $i++)
    {
        if (uc($perms->[$i]->{Type}) eq 'USER')
        {
            my $uid = $self->conv_user(name => $perms->[$i]->{ID});

            $retval{user}->{$uid} = {
                r => $perms->[$i]->{Right} =~ m/^(R|RW)$/ ? 1 : 0,
                w => $perms->[$i]->{Right} =~ m/^(W|RW)$/ ? 1 : 0,

                # :FIXME 2018년 12월 05일 15시 16분 15초: by P.G.
                # We need to specify executable permission
                x => 1,
            };
        }
        elsif (uc($perms->[$i]->{Type}) eq 'GROUP')
        {
            my $gid = $self->conv_group(name => $perms->[$i]->{ID});

            $retval{group}->{$gid} = {
                r => $perms->[$i]->{Right} =~ m/^(R|RW)$/ ? 1 : 0,
                w => $perms->[$i]->{Right} =~ m/^(W|RW)$/ ? 1 : 0,

                # :FIXME 2018년 12월 05일 15시 16분 15초: by P.G.
                # We need to specify executable permission
                x => 1,
            };
        }
        elsif (uc($perms->[$i]->{Type}) eq 'OTHER')
        {
            $retval{other} = {
                r => $perms->[$i]->{Right} =~ m/^(R|RW)$/ ? 1 : 0,
                w => $perms->[$i]->{Right} =~ m/^(W|RW)$/ ? 1 : 0,

                # :FIXME 2018년 12월 05일 15시 16분 15초: by P.G.
                # We need to specify executable permission
                x => 1,
            };
        }
    }

    return \%retval;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Explorer - 

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

