package Test::AnyStor::ClusterVersion;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => "meta";

use Mojo::UserAgent;
use Data::Dumper;
use JSON qw/decode_json/;

my $ua = Mojo::UserAgent->new;

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVersion
#       METHOD: cluster_version_info
#        BRIEF: 버전 정보 조회
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => {
#                       scope => {[cluster|node]}
#                   }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           scope => [cluster|node]
#                         ---- if( scope == cluster & node ) ----
#                           AnyStor => 2.x.x.x, #if( scope == cluster ) -> cluster version,
#                                                #if( scope == node ) -> node version
#                         -------- if( scope == node ) ----------
#                           gms => 2.y.y.y,
#                           gsm => 2.z.z.z,
#                       }
#                   ],
#                   statuses => [ { ... }, ... ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_version_info
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (scope => $args{scope});

    my $res
        = $self->call_rest_api("cluster/version/info", \%base_args, \%entity,
        \%ext_args);

    return $res->{entity}->[0];
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVersion
#       METHOD: cluster_version_upgrade
#        BRIEF: AnyStor 버전 업그레이드
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => {
#                     -- The upg file must be in /mnt/private/upg_files/ --
#                       upg_file => {target_upg_name}
#                   }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           reload_stat => {[OK|Failed]},
#                           upg_file => {target_upg_name}
#                       }
#                   ],
#                   statuses => [
#                       { ... }, ... ,
#                     ------ if( reload_stat == Failed ) ------
#                     ------- this is at the last index -------
#                       {
#                           level => 'ERROR',
#                           category => 'default',
#                           type => 'COMMAND',
#                           details => {
#                               {Failed_host_name} => {
#                                   msg => "msg_string",
#                                   entity => [],
#                                   statuses => [ ... ],
#                                   return => {[true|false]}
#                               }, ...
#                           }
#                       }
#                   ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_version_upgrade
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (upg_file => $args{upg_file});

    my $res = $self->call_rest_api("cluster/version/upgrade", \%base_args,
        \%entity, \%ext_args);

    return 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::ClusterVersion - 

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
