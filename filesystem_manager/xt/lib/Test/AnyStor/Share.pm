package Test::AnyStor::Share;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use JSON qw/decode_json/;
use Test::Most;

extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'event_check' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub cluster_share_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/cluster/share/list');

    return $res->{entity};
}

sub cluster_share_create
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/create',
        params => {
            Name   => $args{sharename},
            Pool   => $args{pool} // 'vg_cluster',
            Volume => $args{volume},
            Path   => $args{path},
            Desc   => $args{description},
        }
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_CREATE_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_CREATE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_update
{
    my $self = shift;
    my %args = @_;

    my %entity = ();

    my $res = $self->request(
        uri    => '/cluster/share/update',
        params => {
            Name   => $args{sharename},
            Volume => $args{volume},
            Path   => $args{path},
            Desc   => $args{description},
        }
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_UPDATE_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_UPDATE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_delete
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/delete',
        params => {
            Name => $args{sharename},
        }
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_DELETE_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_DELETE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_smb_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/cluster/share/smb/list');

    if (!$self->t->success)
    {
        explain($res);
    }

    return $res->{entity};
}

sub cluster_share_smb_info
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/smb/info',
        params => {
            Name => $args{sharename}
        },
    );

    return $res->{entity}->[0];
}

sub cluster_share_smb_enable
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/smb/enable',
        params => {Name => $args{sharename}},
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_PROTO_ENABLE_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_PROTO_ENABLE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_smb_update
{
    my $self = shift;
    my %args = @_;

    my %params = (Name => $args{sharename},);

    if (exists($args{active}))
    {
        $params{Available} = $args{active};
    }

    if (exists($args{guest_allow}))
    {
        $params{Guest_Ok} = $args{guest_allow};
    }

    if (exists($args{hidden_share}))
    {
        $params{Browseable} = $args{hidden_share} eq 'on' ? 'no' : 'yes';
    }

    my $res = $self->request(
        uri    => '/cluster/share/smb/update',
        params => \%params,
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_PROTO_UPDATE_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_PROTO_UPDATE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_smb_getlist
{
    my $self = shift;
    my %args = @_;

    my %base_args = (partition => $args{partition});

    my $res = $self->request(uri => '/cluster/share/smb/getlist');

    return $res->{entity};
}

sub cluster_share_smb_get_config
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/cluster/share/smb/config/get');

    return $res->{entity}->[0];
}

sub cluster_share_smb_set_config
{
    my $self = shift;
    my %args = @_;

    my %params;

    if (exists($args{active}))
    {
        $params{Active} = $args{active};
    }

    if (exists($args{workgroup}))
    {
        $params{Workgroup} = $args{workgroup};
    }

    if (exists($args{description}))
    {
        $params{Server_String} = $args{description};
    }

    my $res = $self->request(
        uri    => '/cluster/share/smb/config/set',
        params => \%params,
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_PROTO_SET_CONFIG_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_PROTO_SET_CONFIG_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_smb_set_user_access
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/smb/access/account/set',
        params => {
            Name  => $args{sharename},
            User  => $args{user},
            Right => $args{right},
        }
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_SET_ACCESS_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_SET_ACCESS_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_smb_set_group_access
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/smb/access/account/set',
        params => {
            Name  => $args{sharename},
            Group => $args{group},
            Right => $args{right},
        }
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_SET_ACCESS_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_SET_ACCESS_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_smb_set_network_access
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/smb/access/network/set',
        params => {
            Name  => $args{sharename},
            Zone  => $args{zone},
            Right => $args{right},
        }
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_SET_ACCESS_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_SET_ACCESS_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_smb_control
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/smb/control',
        params => {Action => $args{command}},
    );

    return 0;
}

sub cluster_share_nfs_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/cluster/share/nfs/ganesha/list');

    return $res->{entity};
}

sub cluster_share_nfs_info
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/nfs/ganesha/info',
        params => {Name => $args{sharename}},
    );

    return $res->{entity}->[0];
}

sub cluster_share_nfs_enable
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/nfs/ganesha/enable',
        params => {Name => $args{sharename}},
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_PROTO_ENABLE_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_PROTO_ENABLE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_nfs_update
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/nfs/ganesha/update',
        params => {
            Name      => $args{sharename},
            Available => $args{active},
        }
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_PROTO_UPDATE_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_PROTO_UPDATE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_nfs_getlist
{
    my $self = shift;
    my %args = @_;

    my %base_args = (partition => $args{partition});

    my $res = $self->request(
        uri => '/cluster/share/nfs/ganesha/getlist',
        \%base_args, {}, {}
    );

    return $res->{entity};
}

sub cluster_share_nfs_get_config
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => 'cluster/share/nfs/ganesha/config/get');

    return $res->{entity}->[0];
}

sub cluster_share_nfs_set_config
{
    my $self = shift;
    my %args = @_;

    my %params;

    if (exists($args{active}))
    {
        $params{Active} = $args{active};
    }

    my $res = $self->request(
        uri    => '/cluster/share/nfs/ganesha/config/set',
        params => \%params,
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_PROTO_SET_CONFIG_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_PROTO_SET_CONFIG_OK' event check"
        );
    }

    return 0;
}

sub cluster_share_nfs_set_network_access
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/nfs/ganesha/access/network/set',
        params => {
            Name   => $args{sharename},
            Zone   => $args{zone},
            Right  => $args{right},
            Squash => $args{squash} // 'no_root_squash',
        }
    );

    if ($self->event_check)
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'SHARE_SET_ACCESS_OK',
                $res->{prof}->{from},
                $res->{prof}->{to},
            ),
            "'SHARE_SET_ACCESS_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_share_nfs_control
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/share/nfs/ganesha/control',
        params => {Action => $args{command}},
    );

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Share - 

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
