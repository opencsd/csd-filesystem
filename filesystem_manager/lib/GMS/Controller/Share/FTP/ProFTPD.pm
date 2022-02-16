package GMS::Controller::Share::FTP::ProFTPD;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use File::Path qw/make_path/;
use GMS::FTP::Types;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Share::Protocol';

#---------------------------------------------------------------------------
#   Overrided Attributes
#---------------------------------------------------------------------------
has '+protocol' => (default => 'FTP',);

has '+service' => (default => 'proftpd',);

has '+config_model' => (default => 'Config',);

has '+section_model' => (default => 'Section',);

has '+rights_table' => (
    default => sub
    {
        {
            Default => [qw|deny readonly read/write|],
            Zone    => [qw|deny readonly read/write|],
        };
    },
);

has '+aggregator_file' => (default => '/etc/proftpd/proftpd.conf',);

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'home_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub
    {
        my $dir = '/home/';

        if (!-d $dir
            && make_path($dir, {error => \my $err}) == 0)
        {
            my ($d, $msg) = %{$err->[0]};

            if ($d eq '')
            {
                die "Generic error: $msg";
            }
            else
            {
                die "Failed to make directory: $d$msg";
            }
        }

        return $dir;
    },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub set_network_access
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        Name => {
            isa => 'Str',
        },
        Zone => {
            isa => 'Str',
        },
        Right => {
            isa    => 'FTP_NETWORK_ACCESS',
            coerce => 1,
        },
    };

    $params = $self->validate($rule, $params);

    my $section = $self->_get_section($params->{Name});

    if (!defined($section))
    {
        $self->throw_exception(
            'NotFound',
            resource => "${\$self->protocol} share",
            name     => $params->{Name},
        );
    }

    my $zone = $self->get_model('Zone')->find($params->{Zone});

    if (!defined($zone))
    {
        $self->throw_exception(
            'NotFound',
            resource => 'Network zone',
            name     => $params->{Zone},
        );
    }

    $section->set_network_access(
        zone  => $zone,
        right => $params->{Right},
    );

    #$section->store_to_file();

    $self->api_status(
        level   => 'INFO',
        code    => 'SHARE_SET_ACCESS_OK',
        msgargs => [
            protocol => $self->protocol,
            name     => $params->{Name},
            target   => $params->{Zone},
            right    => $params->{Right},
        ],
    );

    $self->publish_event();

    $self->stash(json => $params);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Share::FTP::ProFTPD - GMS ProFTPD management API controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

