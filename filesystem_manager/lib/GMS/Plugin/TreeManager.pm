package GMS::Plugin::TreeManager;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Encode;
use Locale::TextDomain qw(gms);

#---------------------------------------------------------------------------
#   gettext domain filter setting
#---------------------------------------------------------------------------
Locale::Messages::bind_textdomain_filter(gms => \&Encode::decode_utf8);

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub get_menu_tree
{
    [
        {
            id       => 'manager_cluster',
            text     => __('Cluster Management'),
            smenu    => 'manager_cluster_overview',
            stext    => __('Overview'),
            expanded => 'true',
            entity   => [
                {
                    id    => 'manager_cluster_overview',
                    text  => __('Overview'),
                    ptext => __('Cluster Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-sys-info.png'
                },
                {
                    id    => 'manager_cluster_event',
                    text  => __('Event'),
                    ptext => __('Cluster Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-log.png'
                },
                {
                    id    => 'manager_cluster_clusterNode',
                    text  => __('Node Management'),
                    ptext => __('Cluster Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-admin_user.png'
                },
                {
                    id          => 'manager_cluster_network',
                    text        => __('Network'),
                    ptext       => __('Cluster Management'),
                    leaf        => 'true',
                    icon        => '/admin/images/icon-network-info.png',
                    afterSubTpl => 'aa'
                },
                {
                    id    => 'manager_cluster_mail',
                    text  => __('Notification'),
                    ptext => __('Cluster Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-notice.png'
                },
                {
                    id    => 'manager_cluster_time',
                    text  => __('Time'),
                    ptext => __('Cluster Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-time.png'
                },
                {
                    id    => 'manager_cluster_license',
                    text  => __('License'),
                    ptext => __('Cluster Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-license.png'
                },
                {
                    id    => 'manager_cluster_log',
                    text  => __('Log'),
                    ptext => __('Cluster Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-backup.png'
                },
                {
                    id    => 'manager_cluster_power',
                    text  => __('Power'),
                    ptext => __('Cluster Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-power.png'
                }
            ]
        },
        {
            id       => 'manager_cluster_volumeManagement',
            text     => __('Volume Management'),
            smenu    => 'manager_cluster_volumePool',
            stext    => __('Volume Pool'),
            expanded => 'true',
            entity   => [
                {
                    id    => 'manager_cluster_volumePool',
                    text  => __('Volume Pool'),
                    ptext => __('Volume Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-volume.png'
                },
                {
                    id    => 'manager_cluster_volume',
                    text  => __('Volume'),
                    ptext => __('Volume Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-volume.png'
                },
                {
                    id    => 'manager_cluster_snapshot',
                    text  => __('Snapshot'),
                    ptext => __('Volume Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-snapshot.png'
                }
            ]
        },
        {
            id       => 'manager_account',
            text     => __('Account') . ' & ' . __('Authentication'),
            smenu    => 'manager_account_user',
            stext    => 'manager_account_user',
            expanded => 'true',
            entity   => [
                {
                    id    => 'manager_account_user',
                    text  => __('User'),
                    ptext => __('Account') . ' & ' . __('Authentication'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-user.png'
                },
                {
                    id    => 'manager_account_group',
                    text  => __('Group'),
                    ptext => __('Account') . ' & ' . __('Authentication'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-group.png'
                },
                {
                    id    => 'manager_account_external',
                    text  => __('Authentication'),
                    ptext => __('Account') . ' & ' . __('Authentication'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-external.png'
                },
                {
                    id    => 'manager_account_admin',
                    text  => __('Adminitrator'),
                    ptext => __('Account') . ' & ' . __('Authentication'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-admin.png'
                }
            ]
        },
        {
            id       => 'manager_share',
            text     => __('Share Management'),
            smenu    => 'manager_share_share',
            stext    => 'manager_share_share',
            expanded => 'true',
            entity   => [
                {
                    id    => 'manager_share_smb',
                    text  => __('SMB'),
                    ptext => __('Share Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-cifs.png'
                },
                {
                    id    => 'manager_share_nfs',
                    text  => __('NFS'),
                    ptext => __('Share Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-nfs.png'
                },
                {
                    id    => 'manager_share_ftp',
                    text  => __('FTP'),
                    ptext => __('Share Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-ftp.png'
                },
                {
                    id    => 'manager_share_share',
                    text  => __('Share'),
                    ptext => __('Share Management'),
                    leaf  => 'true',
                    icon  => '/admin/images/icon-sharefolder.png'
                }
            ]
        },
    ];
}

sub register
{
    my ($self, $app, $args) = @_;

    $app->helper(get_menu_tree => sub { $self->get_menu_tree(); });

    return;
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::TreeManager - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

