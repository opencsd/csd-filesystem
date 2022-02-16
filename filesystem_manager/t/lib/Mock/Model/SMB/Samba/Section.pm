package Mock::Model::SMB::Samba::Section;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Model::SMB::Samba::Section;

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { GMS::Model::SMB::Samba::Section->meta->etcd_root; };
etcd_keygen sub { name => shift; };

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::SMB::Samba::Section';

#---------------------------------------------------------------------------
#   Overrided Attributes
#---------------------------------------------------------------------------
has '+config_dir' => (default => '/tmp/etc/samba/shares.d',);

has '+global_pkg' => (default => 'Mock::Model::SMB::Samba::Global',);

has '+section_pkg' => (default => 'Mock::Model::SMB::Samba::Section',);

has '+aggregator_file' => (default => '/tmp/etc/samba/smb.conf',);

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'to_hash' => sub
{
    my $self = shift;

    my $retval = super();

    map { delete($retval->{$_}); } qw/mock etcd_data/;

    return $retval;
};

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

Mock::Model::Share::SMB::Section - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

