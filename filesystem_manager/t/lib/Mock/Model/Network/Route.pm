package Mock::Model::Network::Route;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Network::Route;

use File::Path qw/make_path/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Network::Route';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { GMS::Model::Network::Route->meta->etcd_root; };

#---------------------------------------------------------------------------
#   Attributes Overriding
#---------------------------------------------------------------------------
has '+handler' => (
    default => sub
    {
        foreach my $dir ('/tmp/etc/iproute2', '/tmp/home/__internal')
        {
            if (-e $dir && !-d $dir)
            {
                die "path exists but not a directory: $dir";
            }

            if (!-d $dir && make_path($dir, {error => \my $err}) == 0)
            {
                my ($dir, $msg) = %{$err->[0]};

                if ($dir eq '')
                {
                    die "Generic error: $msg";
                }
                else
                {
                    die "Failed to make directory: $dir: $msg";
                }
            }
        }

        system('touch /tmp/etc/iproute2/rt_tables');

        return GMS::Network::Route->new(
            iproute2_dir   => '/tmp/etc/iproute2',
            netscripts_dir => '/tmp/etc/sysconfig/network-scripts',
            internal_path  => '/tmp/home/__internal',
            private_path   => '/tmp/home/__internal',
        );
    }
);

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Mock::Model::Network::Route - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

