package Test::AnyStor::Volume;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::Most;

extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: lvcreate
#        BRIEF: LV 생성
#   PARAMETERS: {
#                   type => 'THICK' | 'THIN_POOL' | 'THIN',
#                   name => 'lv_name',
#                   size => '1GiB',       # option
#                   memberof => 'vg_name' # option
#                   options  => ... #option
#               }
#      RETURNS: {
#                   name => 'lv_name
#               }
#
#=============================================================================
sub lvcreate
{
    my $self   = shift;
    my %args   = @_;
    my %entity = ();

    my $name     = $args{name}     // 'lv_testcode';
    my $size     = $args{size}     // '1GiB';
    my $memberof = $args{memberof} // 'vg_cluster';
    my $type     = $args{type}     // GMS::Volume::LVM::LV::THICK_LV;
    my $options  = $args{options}  // '';

    $entity{LV_Name}     = $name;
    $entity{LV_Size}     = $size;
    $entity{LV_MemberOf} = $memberof;
    $entity{LV_Type}     = $type    if ($type ne GMS::Volume::LVM::LV::THICK_LV);
    $entity{LV_Options}  = $options if ($options ne '');

    my %base_args = ();
    my %ext_args  = ();

    my $res = $self->call_rest_api('lvm/lv/create', \%base_args, \%entity,
        \%ext_args);

    if (!$res->{success})
    {
        return;
    }

    return $name;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: lvdelete
#        BRIEF: LV 삭제
#   PARAMETERS: {
#                   name   => ['volume_name'],
#               }
#      RETURNS:
#
#=============================================================================
sub lvdelete
{
    my $self = shift;
    my %args = @_;

    my $name = $args{name} // ['lv_testcode'];
    my $vg   = $args{vg}   // 'vg_cluster';

    for my $idx (0 .. scalar(@{$name}) - 1)
    {
        $name->[$idx] = "/dev/$vg/" . $name->[$idx];
    }

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (LV_Names => $name);

    my $res = $self->call_rest_api('lvm/lv/delete', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: lvlist
#        BRIEF: LV 조회
#   PARAMETERS:
#      RETURNS:
#
#=============================================================================
sub lvlist
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    my $res = $self->call_rest_api('lvm/lv/list', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: vglist
#        BRIEF: VG 조회
#   PARAMETERS:
#      RETURNS:
#
#=============================================================================
sub vglist
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    my $res = $self->call_rest_api('lvm/vg/list', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: vgcreate
#        BRIEF: VG 생성
#   PARAMETERS:
#      RETURNS:
#
#=============================================================================
sub vgcreate
{
    my $self = shift;
    my %args = @_;
    my $name = $args{name};
    my $pvs  = $args{pvs};    # array ref or string

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (VG_Name => $name, VG_PVs => $pvs);

    my $res = $self->call_rest_api('lvm/vg/create', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: vgextend
#        BRIEF: VG 확장
#   PARAMETERS:
#      RETURNS:
#
#=============================================================================
sub vgextend
{
    my $self = shift;
    my %args = @_;
    my $name = $args{name};
    my $pvs  = $args{pvs};    # array ref or string

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (VG_Name => $name, VG_PVs => $pvs);

    my $res = $self->call_rest_api('lvm/vg/extend', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: vgdelete
#        BRIEF: VG 제거
#   PARAMETERS:
#      RETURNS:
#
#=============================================================================
sub vgdelete
{
    my $self = shift;
    my %args = @_;

    my $name = $args{name};    # array ref or string

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (VG_Names => $name);

    my $res = $self->call_rest_api('lvm/vg/delete', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: pvlist
#        BRIEF: PV 조회
#   PARAMETERS:
#      RETURNS:
#
#=============================================================================
sub pvlist
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    my $res = $self->call_rest_api('lvm/pv/list', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: pvcreate
#        BRIEF: PV 생성
#   PARAMETERS:
#      RETURNS:
#
#=============================================================================
sub pvcreate
{
    my $self   = shift;
    my %args   = @_;
    my $device = $args{device};    # array ref or string

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (PV_Names => $device);

    my $res = $self->call_rest_api('lvm/pv/create', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: Volume
#       METHOD: pvdelete
#        BRIEF: PV 제거
#   PARAMETERS:
#      RETURNS:
#
#=============================================================================
sub pvdelete
{
    my $self = shift;
    my %args = @_;

    my $device    = $args{device};         # array ref or string
    my %base_args = ();
    my %ext_args  = ();
    my %entity    = (PV_PVs => $device);

    my $res = $self->call_rest_api('lvm/pv/delete', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Volume - 볼륨의 기능 테스트 함수를 제공하는 라이브러리

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
