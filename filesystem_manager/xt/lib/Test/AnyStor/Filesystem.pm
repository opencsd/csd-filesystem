package Test::AnyStor::Filesystem;

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
#        CLASS: Filesystem
#       METHOD: mount
#        BRIEF: LV Mount
#   PARAMETERS: {
#                   vgname => 'vg_name', # option
#                   lvname => 'lv_name', # option
#                   fail_test => 1 or 0, # option
#               }
#      RETURNS:
#
#=============================================================================
sub mount
{
    my $self = shift;
    my %args = @_;

    my $vgname   = $args{vgname} // 'vg_cluster';
    my $lvname   = $args{lvname} // 'lv_testcode';
    my $expected = $args{fail_test} ? 0 : 1;

    my %base_args = ();
    my %ext_args  = (expected_return => $expected);
    my %entity    = (
        FS_Type   => 'xfs',
        FS_Device => "/dev/$vgname/$lvname"
    );

    my $res = $self->call_rest_api('filesystem/common/mount', \%base_args,
        \%entity, \%ext_args);

    if (!cmp_ok($res->{success}, '==', $expected))
    {
        return;
    }

    return $res->{entity};
}

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
#===  CLASS METHOD  ==========================================================
#        CLASS: Filesystem
#       METHOD: unmount
#        BRIEF: LV Unmount
#   PARAMETERS: {
#                  path => 'path',
#               }
#      RETURNS:
#
#=============================================================================
sub unmount
{
    my $self = shift;
    my %args = @_;

    my @path     = $args{path} // undef;
    my $expected = $args{fail_test} ? 0 : 1;

    my %base_args = ();
    my %ext_args  = (expected_return => $expected);
    my %entity    = (FS_Dir          => @path);

    my $res = $self->call_rest_api('filesystem/common/unmount', \%base_args,
        \%entity, \%ext_args);

    if (!cmp_ok($res->{success}, '==', $expected))
    {
        return;
    }

    return $res->{entity};
}

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
#===  CLASS METHOD  ==========================================================
#        CLASS: Filesystem
#       METHOD: format
#        BRIEF: LV Format
#   PARAMETERS: {
#                  vgname => 'vgname',
#                  lvname => 'lvname'
#                  fail_test => 1 or 0 #option
#               }
#      RETURNS:
#
#=============================================================================
sub format
{
    my $self = shift;
    my %args = @_;

    my $vgname   = $args{vgname} // 'vg_cluster';
    my $lvname   = $args{lvname} // 'lv_testcode';
    my $expected = $args{fail_test} ? 0 : 1;

    my %base_args = ();

    my %ext_args = (expected_return => $expected);

    my %entity = (
        FS_Type   => 'xfs',
        FS_Device => "/dev/$vgname/$lvname",
    );

    my $res = $self->call_rest_api('filesystem/common/format', \%base_args,
        \%entity, \%ext_args);

    if (!cmp_ok($res->{success}, '==', $expected))
    {
        return;
    }

    return $res->{entity};
}

#---------------------------------------------------------------------------
#   Method Modifiers
#---------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=encoding utf8

=head1 NAME

Filesystem - Filesystem의 기능 테스트에 대한 함수를 제공하는 라이브러리

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
