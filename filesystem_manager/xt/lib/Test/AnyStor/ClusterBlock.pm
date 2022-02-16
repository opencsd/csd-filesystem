package Test::AnyStor::ClusterBlock;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::Most;
use Mojo::UserAgent;
use JSON qw/decode_json/;
use Data::Dumper;

extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterBlock
#       METHOD: list_block_device
#        BRIEF: 모든 노드의 block device 정보를 조회
#   PARAMETERS: {
#                   scope  => ALL/NO_OSDISK/NO_PART/NO_INUSE
#               }
#      RETURNS: {
#                   key => value,
#               }
#
#=============================================================================
sub list_block_device
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (scope => $args{scope} // 'ALL');

    my $res = $self->call_rest_api('cluster/block/device/list', \%base_args,
        \%entity, \%ext_args);

    if ($res->{stage_info}{stage} ne 'running')
    {
        diag(explain($res));
    }

    return $res->{entity} // undef;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::ClusterBlock - 

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
