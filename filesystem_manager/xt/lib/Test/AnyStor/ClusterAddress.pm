package Test::AnyStor::ClusterAddress;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => "meta";
use Env;
use Test::Most;
use Data::Dumper;

extends 'Test::AnyStor::Base';

my $event_check = 0;

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterAddress
#       METHOD: cluster_svc_addr_list
#        BRIEF: 서비스 주소 목록 조회
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => {
#                       mds_flag => [0|1]
#                   }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           interface => 'target_interface',
#                           start => 'xxx.xxx.xxx.xxx', #start ip
#                           end => 'xxx.xxx.xxx.xxx', #end ip
#                           netmask => 'xxx.xxx.xxx.xxx'
#                       }, ...
#                   ],
#                   statuses => [ { ... }, ... ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_svc_addr_list
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 'true';
    if (defined $args{return_false} && $args{return_false} != 0)
    {
        $return_expect = 'false';
    }

    my %base_args = ();
    my %ext_args  = (expected_return => $return_expect);
    my %entity    = ();

    my $res = $self->call_rest_api("cluster/svc_addr/list", \%base_args,
        \%entity, \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterAddress
#       METHOD: cluster_svc_addr_create
#        BRIEF: 서비스 주소 생성
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => {
#                       interface => 'target_interface',
#                       start => 'xxx.xxx.xxx.xxx', #start ip
#                       end => 'xxx.xxx.xxx.xxx', #end ip
#                       netmask => 'xxx.xxx.xxx.xxx'
#                   }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           reload_stat => {[OK|Failed]},
#                         ------ created service IP pool ------
#                           interface => 'target_interface',
#                           start => 'xxx.xxx.xxx.xxx', #start ip
#                           end => 'xxx.xxx.xxx.xxx', #end ip
#                           netmask => 'xxx.xxx.xxx.xxx',
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
#                                   entity => [ command => 'reloadips' ],
#                                   statuses => [ ... ],
#                                   return => {[true|false]}
#                               }, ...
#                           }
#                       }
#                   ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_svc_addr_create
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 'true';
    if (defined $args{return_false} && $args{return_false} != 0)
    {
        $return_expect = 'false';
    }

    my %base_args = ();
    my %ext_args  = (expected_return => $return_expect);
    my %entity    = (
        interface => $args{interface},
        start     => $args{start},
        end       => $args{end},
        netmask   => $args{netmask}
    );

    my $res = $self->call_rest_api("cluster/svc_addr/create", \%base_args,
        \%entity, \%ext_args);
    if ($event_check && $return_expect eq 'true')
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'CLST_SVC_IP_CREATE_OK', $res->{prof}{from}
            ),
            "'CLST_SVC_IP_CREATE_OK' event check"
        );
    }

    if   ($self->t->success) { return 1; }
    else                     { return 0; }
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterAddress
#       METHOD: cluster_svc_addr_update
#        BRIEF: 서비스 주소 갱신
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => {
#                       old_interface => 'target_interface',
#                       old_start => 'xxx.xxx.xxx.xxx', #start ip
#                       old_end => 'xxx.xxx.xxx.xxx', #end ip
#                       old_netmask => 'xxx.xxx.xxx.xxx',
#                       new_interface => 'target_interface',
#                       new_start => 'xxx.xxx.xxx.xxx', #start ip
#                       new_end => 'xxx.xxx.xxx.xxx', #end ip
#                       new_netmask => 'xxx.xxx.xxx.xxx'
#                   }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           reload_stat => {[OK|Failed]},
#                         ---- service IP pool after update ----
#                           interface => 'target_interface',
#                           start => 'xxx.xxx.xxx.xxx', #start ip
#                           end => 'xxx.xxx.xxx.xxx', #end ip
#                           netmask => 'xxx.xxx.xxx.xxx',
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
#                                   entity => [ command => 'reloadips' ],
#                                   statuses => [ ... ],
#                                   return => {[true|false]}
#                               }, ...
#                           }
#                       }
#                   ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_svc_addr_update
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 'true';
    if (defined $args{return_false} && $args{return_false} != 0)
    {
        $return_expect = 'false';
    }

    my %base_args = ();
    my %ext_args  = (expected_return => $return_expect);
    my %entity    = (
        old_interface => $args{old_interface},
        old_start     => $args{old_start},
        old_end       => $args{old_end},
        old_netmask   => $args{old_netmask},
        new_interface => $args{new_interface},
        new_start     => $args{new_start},
        new_end       => $args{new_end},
        new_netmask   => $args{new_netmask}
    );

    my $res = $self->call_rest_api("cluster/svc_addr/update", \%base_args,
        \%entity, \%ext_args);

    if ($event_check && $return_expect eq 'true')
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'CLST_SVC_IP_UPDATE_OK', $res->{prof}{from}
            ),
            "'CLST_SVC_IP_UPDATE_OK' event check"
        );
    }

    if   ($self->t->success) { return 1; }
    else                     { return 0; }
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterAddress
#       METHOD: cluster_svc_addr_delete
#        BRIEF: 서비스 주소 삭제
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => {
#                       DelSvcAddr => [
#                           {
#                               interface => 'target_interface',
#                               start => 'xxx.xxx.xxx.xxx', #start ip
#                               end => 'xxx.xxx.xxx.xxx', #end ip
#                               netmask => 'xxx.xxx.xxx.xxx'
#                           }, ...
#                       ]
#                   }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           reload_stat => {[OK|Failed]},
#                           Sucess => [
#                               {
#                                   interface => 'target_interface',
#                                   start => 'xxx.xxx.xxx.xxx', #start ip
#                                   end => 'xxx.xxx.xxx.xxx', #end ip
#                                   netmask => 'xxx.xxx.xxx.xxx',
#                               }, ...
#                           ],
#                           Fail => [
#                               {
#                                   interface => 'target_interface',
#                                   start => 'xxx.xxx.xxx.xxx', #start ip
#                                   end => 'xxx.xxx.xxx.xxx', #end ip
#                                   netmask => 'xxx.xxx.xxx.xxx',
#                               }, ...
#                           ]
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
#                                   entity => [ command => 'reloadips' ],
#                                   statuses => [ ... ],
#                                   return => {[true|false]}
#                               }, ...
#                           }
#                       }
#                   ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_svc_addr_delete
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 'true';
    if (defined $args{return_false} && $args{return_false} != 0)
    {
        $return_expect = 'false';
    }

    my %base_args = ();
    my %ext_args  = (expected_return => $return_expect);
    my %entity    = (
        DelSvcAddr => [
            {
                interface => $args{interface},
                start     => $args{start},
                end       => $args{end},
                netmask   => $args{netmask}
            }
        ]
    );

    my $res = $self->call_rest_api("cluster/svc_addr/delete", \%base_args,
        \%entity, \%ext_args);

    if ($event_check && $return_expect eq 'true')
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'CLST_SVC_IP_DELETE_OK', $res->{prof}{from}
            ),
            "'CLST_SVC_IP_DELETE_OK_ALL' event check"
        );
    }

    if   ($self->t->success) { return 1; }
    else                     { return 0; }
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterAddress
#       METHOD: cluster_str_addr_list
#        BRIEF: 스토리지 주소 목록 조회
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => { }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           interface => 'target_interface',
#                           start => 'xxx.xxx.xxx.xxx', #start ip
#                           end => 'xxx.xxx.xxx.xxx', #end ip
#                           netmask => 'xxx.xxx.xxx.xxx'
#                       }, ...
#                   ],
#                   statuses => [ { ... }, ... ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_str_addr_list
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 'true';
    if (defined $args{return_false} && $args{return_false} != 0)
    {
        $return_expect = 'false';
    }

    my %base_args = ();
    my %ext_args  = (expected_return => $return_expect);
    my %entity    = ();

    my $res = $self->call_rest_api("cluster/svc_addr/list", \%base_args,
        \%entity, \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterAddress
#       METHOD: cluster_str_addr_modify
#        BRIEF: 스토리지 주소 갱신
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { },
#                   entity   => {
#                       old_interface => 'target_interface',
#                       old_start => 'xxx.xxx.xxx.xxx', #start ip
#                       old_end => 'xxx.xxx.xxx.xxx', #end ip
#                       old_netmask => 'xxx.xxx.xxx.xxx',
#                       new_interface => 'target_interface',
#                       new_start => 'xxx.xxx.xxx.xxx', #start ip
#                       new_end => 'xxx.xxx.xxx.xxx', #end ip
#                       new_netmask => 'xxx.xxx.xxx.xxx'
#                   }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                         ---- storage IP pool after update ----
#                           interface => 'target_interface',
#                           start => 'xxx.xxx.xxx.xxx', #start ip
#                           end => 'xxx.xxx.xxx.xxx', #end ip
#                           netmask => 'xxx.xxx.xxx.xxx',
#                       }
#                   ],
#                   statuses => [ { ... }, ... ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub cluster_str_addr_update
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 'true';
    if (defined $args{return_false} && $args{return_false} != 0)
    {
        $return_expect = 'false';
    }

    my %base_args = ();
    my %ext_args  = (expected_return => $return_expect);
    my %entity    = (
        old_interface => $args{old_interface},
        old_start     => $args{old_start},
        old_end       => $args{old_end},
        old_netmask   => $args{old_netmask},
        new_interface => $args{new_interface},
        new_start     => $args{new_start},
        new_end       => $args{new_end},
        new_netmask   => $args{new_netmask},
        force         => $args{force}
    );

    my $res = $self->call_rest_api("cluster/svc_addr/update", \%base_args,
        \%entity, \%ext_args);

    if   ($self->t->success) { return 1; }
    else                     { return 0; }
}

1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::ClusterAddress - 

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
