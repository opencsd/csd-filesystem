package GMS::Controller::Share;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Guard;

# For FTP temporarily
use Fcntl qw(:seek);
use GMS::Cluster::Volume;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'build_models' => sub
{
    {
        Share          => 'GMS::Model::Share',
        'NFS::Kernel'  => 'GMS::Model::NFS::Kernel::Export',
        'NFS::Ganesha' => 'GMS::Model::NFS::Ganesha::Export',
        SMB            => 'GMS::Model::SMB::Samba::Section',
        FTP            => 'GMS::Model::FTP::ProFTPD::Section',
    };
};

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'ftp_config' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/etc/proftpd.conf',
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub list
{
    my $self   = shift;
    my $params = $self->req->json;

    my @list;

    foreach my $name ($self->get_model('Share')->list())
    {
        my $model = $self->get_model('Share')->find($name);

        push(@list, $model->to_hash(ucfirst => 1));

        $model->unlock();
    }

    $self->api_status(
        level => 'INFO',
        code  => 'SHARE_LIST_OK',
    );

    $self->stash(json => \@list);
}

sub create
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        Pool => {
            isa => 'Str',
        },
        Volume => {
            isa => 'Str',
        },
        Path => {
            isa     => 'Str',
            default => '/'
        },
        Desc => {
            isa      => 'Str',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    if ($self->get_model('Share')->find($params->{Name}))
    {
        $self->throw_exception(
            'AlreadyExists',
            resource => 'share',
            name     => $params->{Name}
        );
    }

    my $model = $self->get_model('Share')
        ->new(map { lc($_) => $params->{$_}; } keys(%{$params}));

    # :WARNING 06/01/2020 01:34:01 PM: by P.G.
    # Add VRootAlias to enable FTP temporarily
    $self->stash(share => $model);
    $self->enable_ftp();

    $model->unlock();

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_CREATE_OK',
        msgargs => [name => $params->{Name}],
    );

    $self->publish_event();

    $self->stash(json => $model->to_hash(ucfirst => 1));
}

sub enable_ftp
{
    my $self = shift;
    my %args = @_;

    my $share  = $self->stash('share');
    my $volume = $self->_find_volume(name => $share->volume);

    if (!defined($volume))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'Volume',
            name     => $share->volume,
        );
    }

    my $path;

    if ($volume->{Volume_Type} eq 'Local'
        || $volume->{Volume_Type} eq 'External')
    {
        $path = sprintf(
            '/export/%s/%s/%s',
            $share->pool,
            $share->volume,
            $share->path
        );
    }
    else
    {
        $path = sprintf('/export/%s/%s', $share->volume, $share->path);
    }

    $path =~ s/\/+/\//g;
    $path =~ s/\/+$//g;

    open(my $fh, '+<', $self->ftp_config)
        || die "Failed to open file: ${\$self->ftp_config}: $!";

    #warn "[INFO] SHARE: ${\$self->dumper($share)}";
    #
    #$share->protocols->{FTP} = 'yes';

    my $buf = '';

    while (my $line = <$fh>)
    {
        if ($line =~ m/\s*VRootOptions/)
        {
            $line .= "  VRootAlias	$path	${\$share->name}\n";
        }

        $buf .= $line;
    }

    truncate($fh, 0)
        || die "Failed to truncate: ${\$self->ftp_config}: $!";

    seek($fh, 0, SEEK_SET)
        || die "Failed to seek: ${\$self->ftp_config}: $!";

    print $fh $buf;

    close($fh);

    return;
}

sub update
{
    my $self   = shift;
    my $params = $self->req->json;

    map {
        if (exists($params->{$_}))
        {
            $self->throw_exception('NotSupported',
                message => "Could not change a ${\lc($_)} of a share");
        }
    } qw(Pool Volume);

    state $rule = {
        Name => {
            isa => 'Str',
        },
        Pool => {
            isa      => 'Str',
            optional => 1,
        },
        Volume => {
            isa      => 'Str',
            optional => 1,
        },
        Path => {
            isa      => 'Str',
            optional => 1,
        },
        Desc => {
            isa      => 'Str',
            optional => 1,
        },
    };

    $params = $self->validate($rule, $params);

    my $found = $self->get_model('Share')->find($params->{Name});

    if (!$found)
    {
        $self->throw_exception(
            'NotFound',
            resource => 'share',
            name     => $params->{Name}
        );
    }

    $found->update(
        map  { lc($_) => $params->{$_}; }
        grep { $_ ne 'Name' } keys(%{$params})
    );

    $found->unlock();

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_UPDATE_OK',
        msgargs => [name => $params->{Name}],
    );

    $self->publish_event();

    $self->stash(json => $found->to_hash(ucfirst => 1));
}

sub delete
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
    };

    $params = $self->validate($rule, $params);

    my $found = $self->get_model('Share')->find($params->{Name});

    if (!$found)
    {
        $self->throw_exception(
            'NotFound',
            resource => 'share',
            name     => $params->{Name}
        );
    }

    # :WARNING 06/01/2020 01:34:01 PM: by P.G.
    # Remove VRootAlias to disable FTP temporarily
    $self->stash(share => $found);
    $self->disable_ftp();

    foreach my $proto (qw(NFS::Ganesha NFS::Kernel SMB))
    {
        my $section = $self->get_model($proto)->find($found->name);

        next if (!defined($section));

        warn "[DEBUG] $proto share will be deleted: ${\$found->name}";

        $self->stash($proto => $section->delete());
    }

    my $deleted = $found->to_hash(ucfirst => 1);

    $found->delete();

    $found->unlock();

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_DELETE_OK',
        msgargs => [name => $params->{Name}],
    );

    $self->publish_event();

    $self->stash(json => $deleted);
}

sub disable_ftp
{
    my $self = shift;
    my %args = @_;

    my $share  = $self->stash('share');
    my $volume = $self->_find_volume(name => $share->volume);

    if (!defined($volume))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'Volume',
            name     => $share->volume,
        );
    }

    my $path;

    if ($volume->{Volume_Type} eq 'Local'
        || $volume->{Volume_Type} eq 'External')
    {
        $path = sprintf(
            '/export/%s/%s/%s',
            $share->pool,
            $share->volume,
            $share->path
        );
    }
    else
    {
        $path = sprintf('/export/%s/%s', $share->volume, $share->path);
    }

    $path =~ s/\/+/\//g;
    $path =~ s/\/+$//g;

    open(my $fh, '+<', $self->ftp_config)
        || die "Failed to open file: ${\$self->ftp_config}: $!";

    #warn "[INFO] SHARE: ${\$self->dumper($share)}";
    #
    #$share->protocols->{FTP} = 'no';

    my $buf = '';

    while (my $line = <$fh>)
    {
        if ($line =~ m/\s*VRootAlias\s+$path\s+${\$share->name}/)
        {
            next;
        }

        $buf .= $line;
    }

    truncate($fh, 0)
        || die "Failed to truncate: ${\$self->ftp_config}: $!";

    seek($fh, 0, SEEK_SET)
        || die "Failed to seek: ${\$self->ftp_config}: $!";

    print $fh $buf;

    close($fh);

    return;
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
# For FTP temporarily
sub _list_volumes
{
    my $self = shift;
    my %args = @_;

    my $type = $args{type} // 'ALL';

    return GMS::Cluster::Volume->new->volumelist(Pool_Type => $type);
}

# For FTP temporarily
sub _find_volume
{
    my $self = shift;
    my %args = @_;

    # :TODO 08/01/2019 05:29:44 PM: by P.G.
    # simple validator with GMS::Validator

    my $type = $args{type} // 'ALL';
    my $name = $args{name};

    my $vols  = $self->_list_volumes(type => $type);
    my $found = undef;

    if (ref($vols) ne 'ARRAY')
    {
        die 'Failed to get volume list';
    }

    foreach my $vol (@{$vols})
    {
        if ($vol->{Volume_Name} eq $name)
        {
            $found = $vol;
            last;
        }
    }

    return $found;
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Share - GMS share management API controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

