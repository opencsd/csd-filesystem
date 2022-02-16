package GMS::Controller::LVM;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Block::BlockCtl;
use GMS::Cluster::Etcd;
use GMS::Volume::VolumeCtl;
use Sys::Hostname::FQDN qw/short/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'handle' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Volume::VolumeCtl->new(); },
);

has 'etcd' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Cluster::Etcd->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub pv_list
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->handle->lvmhandler->pvscan();

    my $rv = $self->handle->pvs();

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/PV",
        format => 'json',
    );

    foreach my $pv (keys(%{$data}))
    {
        delete($data->{$pv}) if (!(grep { $pv eq $_->{PV_Name}; } @{$rv}));
    }

    foreach my $pv (@{$rv})
    {
        $data->{$pv->{PV_Name}}
            = $self->handle->lvmhandler->get_pv($pv->{PV_Name});
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/PV",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/PV: ${\Dumepr($data)}");
    }

    if (!keys(%{$self->handle->lvmhandler->pvhandler->_pvs}))
    {
        $self->handle->lvmhandler->pvhandler->_set_pvs($data);
    }

    $self->render(json => $rv);
}

sub pv_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->pvdisplay(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub pv_create
{
    my $self   = shift;
    my $params = $self->req->json;

    GMS::Block::BlockCtl->new->zap_all(
        devices => $params->{entity}->{PV_Names});

    my $result = $self->handle->pvcreate(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    GMS::Block::BlockCtl->new->list({}, {scope => 'ALL'});

    $self->render(json => $result);
}

sub pv_change
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->pvchange(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub pv_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->pvremove(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    my $blkctl = GMS::Block::BlockCtl->new();

    $blkctl->zap_all(devices => $params->{entity}->{PV_PVs});
    $blkctl->list({}, {scope => 'ALL'});

    $self->render(json => $result);
}

sub vg_list
{
    my $self = shift;

    $self->handle->lvmhandler->vgscan();

    my $rv = $self->handle->vgs();

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/VG",
        format => 'json',
    );

    foreach my $vg (keys(%{$data}))
    {
        delete($data->{$vg}) if (!(grep { $vg eq $_->{VG_Name}; } @{$rv}));
    }

    foreach my $vg (@{$rv})
    {
        $data->{$vg->{VG_Name}}
            = $self->handle->lvmhandler->get_vg($vg->{VG_Name});
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/VG",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error("Failed to set /${\short()}/VG");
    }

    if (!keys(%{$self->handle->lvmhandler->vghandler->_vgs}))
    {
        $self->handle->lvmhandler->vghandler->_set_vgs($data);
    }

    $self->render(json => $rv);
}

sub vg_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgdisplay(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub vg_create
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgcreate(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub vg_change
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgchange(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub vg_rename
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgrename(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub vg_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgremove(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub vg_extend
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgextend(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub vg_reduce
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgreduce(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub vg_split
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgsplit(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub vg_merge
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgmerge(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub vg_check
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->vgck(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub lv_list
{
    my $self = shift;

    $self->handle->lvmhandler->lvscan();

    my $rv = $self->handle->lvs();

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/LV",
        format => 'json',
    );

    foreach my $lv (keys(%{$data}))
    {
        delete($data->{$lv}) if (!(grep { $lv eq $_->{LV_Name}; } @{$rv}));
    }

    foreach my $lv (@{$rv})
    {
        my $name = sprintf('%s/%s', $lv->{LV_MemberOf}, $lv->{LV_Name});
        $data->{$name} = $self->handle->lvmhandler->get_lv($name);
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/LV",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error("Failed to set /${\short()}/LV");
    }

    if (!keys(%{$self->handle->lvmhandler->lvhandler->_lvs}))
    {
        $self->handle->lvmhandler->lvhandler->_set_lvs($data);
    }

    $self->render(json => $rv);
}

sub lv_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvdisplay(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub lv_create
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvcreate(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub lv_change
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvchange(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub lv_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvremove(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub lv_rename
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvrename(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub lv_extend
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvextend(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub lv_reduce
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvreduce(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub lv_resize
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvreduce(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub lv_convert
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvconvert(
        argument => $params->{argument},
        entity   => $params->{entity},
    );

    $self->render(json => $result);
}

sub lv_update
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->handle->lvmodify(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

around [
    'pv_create', 'pv_change',

    #'pv_resize', 'pv_move'
    ] => sub
{
    my $orig = shift;
    my $self = shift;

    my $rv = $self->$orig(@_);

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/PV",
        format => 'json',
    );

    foreach my $pv ($self->handle->lvmhandler->pvs)
    {
        my $pvinfo = $self->handle->lvmhandler->get_pv($pv);

        $data->{$pv} = $pvinfo;
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/PV",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/PV: ${\Dumper($data)}");
    }

    return $rv;
};

around 'pv_delete' => sub
{
    my $orig   = shift;
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->$orig(@_);

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/PV",
        format => 'json',
    );

    foreach my $pv (@{$params->{entity}->{PV_PVs}})
    {
        delete($data->{$pv});
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/PV",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/PV: ${\Dumper($data)}");
    }

    return $rv;
};

around [
    'vg_create', 'vg_change', 'vg_rename',

    #'vg_export', 'vg_import',
    'vg_extend', 'vg_reduce', 'vg_split', 'vg_merge',

    #'vg_mknodes', 'vg_cfg_restore', 'vg_convert',
    ] => sub
{
    my $orig   = shift;
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->$orig(@_);

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/VG",
        format => 'json',
    );

    foreach my $vg ($self->handle->lvmhandler->vgs())
    {
        $data->{$vg} = $self->handle->lvmhandler->get_vg($vg);
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/VG",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/VG: ${\Dumper($data)}");
    }

    # reload block device info
    GMS::Block::BlockCtl->new->list({}, {scope => 'ALL'});

    return $rv;
};

after ['vg_create', 'vg_extend', 'vg_reduce', 'vg_split'] => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/PV",
        format => 'json',
    );

    foreach my $pv (@{$params->{entity}->{VG_PVs}})
    {
        $data->{$pv}->{vg} = $params->{entity}->{VG_Name};
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/PV",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/PV: ${\Dumper($data)}");
    }
};

after ['vg_rename', 'vg_split', 'vg_merge'] => sub
{
    my $self   = shift;
    my $params = $self->req->json;

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/PV",
        format => 'json',
    );

    foreach my $pv (keys(%{$data}))
    {
        $data->{$pv}->{vg} = $params->{entity}->{VG_To}
            if ($data->{$pv}->{vg} eq $params->{entity}->{VG_From});
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/PV",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/PV: ${\Dumper($data)}");
    }
};

around 'vg_delete' => sub
{
    my $orig = shift;
    my $self = shift;

    my $params = $self->req->json;

    my $rv = $self->$orig(@_);

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/VG",
        format => 'json',
    );

    map { delete($data->{$_}); } @{$params->{entity}->{VG_Names}};

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/VG",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/VG: ${\Dumper($data)}");
    }

    # PV 정보 갱신
    $data = $self->etcd->get_key(
        key    => "/${\short()}/PV",
        format => 'json',
    );

    my @vg_names = @{$params->{entity}->{VG_Names}};

    foreach my $pv (keys(%{$data}))
    {
        $data->{$pv}->{vg} = undef
            if (grep { $data->{$pv}->{vg} eq $_; } @vg_names);
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/PV",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/PV: ${\Dumper($data)}");
    }

    # reload block device info
    GMS::Block::BlockCtl->new->list({}, {scope => 'ALL'});

    return $rv;
};

around [
    'lv_create',
    'lv_change',
    'lv_delete',
    'lv_rename',
    'lv_extend',
    'lv_reduce',
    'lv_resize',
    'lv_convert',
    ] => sub
{
    my $orig = shift;
    my $self = shift;

    my $rv = $self->$orig(@_);

    my $data = $self->etcd->get_key(
        key    => "/${\short()}/LV",
        format => 'json',
    );

    my @lvs = $self->handle->lvmhandler->lvs();

    foreach my $lv (keys(%{$data}))
    {
        if (!grep { $_ eq $lv; } @lvs)
        {
            warn "[DEBUG] Could not find LV so will be cleaned up: $lv";
            delete($data->{$lv});
            next;
        }
    }

    foreach my $lv (@lvs)
    {
        $data->{$lv} = $self->handle->lvmhandler->get_lv($lv);
    }

    if (
        $self->etcd->set_key(
            key    => "/${\short()}/LV",
            value  => $data,
            format => 'json',
        ) <= 0
        )
    {
        $self->throw_error(
            "Failed to set /${\short()}/LV: ${\Dumper($data)}");
    }

    return $rv;
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::LVM - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

