package Mock::Model::Network::DNS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::Model;
use GMS::Network::DNS;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Network::DNS';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root sub { GMS::Model::Network::DNS->meta->etcd_root; };

#---------------------------------------------------------------------------
#   Attributes Overriding
#---------------------------------------------------------------------------
has '+resolv_config' => (default => '/tmp/etc/resolv.conf',);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub mock_dummy
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    my %dummy = ();

    for (my $i = 0; $i < @{$args{entries}}; $i++)
    {
        $dummy{"/Network/DNS/entries/$i"} = $args{entries}->[$i];
    }

    return \%dummy;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Mock::Model::Network::DNS - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

