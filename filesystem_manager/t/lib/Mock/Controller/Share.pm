package Mock::Controller::Share;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use File::Path qw/make_path remove_tree/;
use Sys::Hostname::FQDN qw/short/;
use Test::MockModule;

use Mock::Model::Share;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Share';

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'Mock::Controllable';

#---------------------------------------------------------------------------
#   Overrided Attributes
#---------------------------------------------------------------------------
has '+ftp_config' => (default => '/tmp/etc/proftpd.conf',);

#---------------------------------------------------------------------------
#   Method Overriding
#---------------------------------------------------------------------------
override 'build_models' => sub
{
    my $self = shift;

    return {
        Share          => 'Mock::Model::Share',
        'NFS::Kernel'  => 'GMS::Model::NFS::Kernel::Export',
        'NFS::Ganesha' => 'Mock::Model::NFS::Ganesha::Export',
        SMB            => 'Mock::Model::SMB::Samba::Section',
    };
};

# :TODO 09/30/2020 03:54:20 AM: by P.G.
# we need to mock up volume model to test share properly.
# + rewrite FTP feature
override 'enable_ftp' => sub
{
    return 0;
};

# :TODO 09/30/2020 03:54:20 AM: by P.G.
# we need to mock up volume model to test share properly.
# + rewrite FTP feature
override 'disable_ftp' => sub
{
    return 0;
};

sub mock_exec
{
    my $mock = Test::MockModule->new('GMS::Common::IPC');

    $mock->mock(
        exec => sub
        {
            my %args = @_;

            my %retval = (
                status => 0,
                cmd    => $args{cmd},
                out    => '',
                err    => '',
            );

            if (ref($args{args}) eq 'ARRAY' && scalar(@{$args{args}}))
            {
                $retval{cmd} .= ' ' . join(' ', @{$args{args}});
            }

            if ($args{cmd} eq 'ifenslave')
            {

            }
            elsif ($args{cmd} eq 'lspci')
            {

            }

            return \%retval;
        }
    );

    return $mock;
}

sub BUILD
{
    my $self = shift;

    $self->add_mock(mock_exec());
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Mock::Controller::Share - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

