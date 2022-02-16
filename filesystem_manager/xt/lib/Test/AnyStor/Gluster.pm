package Test::AnyStor::Gluster;

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
#   Attributes
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
#===  CLASS METHOD  ==========================================================
#        CLASS: Gluster
#       METHOD: probe
#        BRIEF: Gluster peer probe
#   PARAMETERS: {
#                   Storage_IP   => '10.10.1.10',
#               }
#      RETURNS: {
#               }
#
#=============================================================================
sub probe
{
    my $self = shift;
    my %args = @_;

    my $ipaddr = $args{ip} // undef;

    my %base_args = (Storage_IP => $ipaddr);
    my %ext_args  = ();
    my %entity    = ();

    my $res
        = $self->call_rest_api("gluster/peer/probe", \%base_args, \%entity,
        \%ext_args);

    return 1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Gluster
#       METHOD: detach
#        BRIEF: Gluster peer detach
#   PARAMETERS: {
#                   ip => '10.10.1.10',
#               }
#      RETURNS: {
#               }
#
#=============================================================================
sub detach
{
    my $self = shift;
    my %args = @_;

    my $ipaddr = $args{ip} // undef;

    my %base_args = (Storage_IP => $ipaddr);
    my %ext_args  = ();
    my %entity    = ();

    my $res
        = $self->call_rest_api("gluster/peer/detach", \%base_args, \%entity,
        \%ext_args);

    return 1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Gluster
#       METHOD: restart
#        BRIEF: Restart glusterd
#   PARAMETERS: {
#                   ip => '10.10.1.10', # options
#               }
#      RETURNS: {
#               }
#
#=============================================================================
sub restart
{
    my $self = shift;
    my %args = @_;

    my $ipaddr    = $args{ip} // ${\$self->addr};
    my %base_args = (Storage_IP => $ipaddr);
    my %ext_args  = ();
    my %entity    = ();

    my $res = $self->call_rest_api("gluster/restart", \%base_args, \%entity,
        \%ext_args);

    return 1;
}
__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

Gluster - 글러스터 관련 기능(probe,detach,restart) 테스트에 대한 함수를 제공하는 라이브러리

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
