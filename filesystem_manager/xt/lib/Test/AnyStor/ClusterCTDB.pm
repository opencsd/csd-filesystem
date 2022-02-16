package Test::AnyStor::ClusterCTDB;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Mojo::UserAgent;
use Data::Dumper;
use JSON qw/decode_json/;

use Test::AnyStor::Base;

extends 'Test::AnyStor::Base';

my $ua = Mojo::UserAgent->new;

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterCTDB
#       METHOD: cluster_ctdb_control
#        BRIEF: ctdb daemon 제어
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => {
#                       command => [start|stop|reload|reloadnodes|reloadips]
#                   }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           command => [start|stop|reload|reloadnodes|reloadips]
#                       }
#                   ],
#                   statuses => [ { ... }, ... ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_ctdb_control
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (command => $args{command});

    my $res
        = $self->call_rest_api('cluster/ctdb/control', \%base_args, \%entity,
        \%ext_args);

    return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::ClusterCTDB - 

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
