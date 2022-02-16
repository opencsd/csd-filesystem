package Test::AnyStor::Block;

use v5.14;

use strict;
use warnings;
use utf8;

use Mouse;
use namespace::clean -except => 'meta';

our $AUTHORITY = 'cpan:gluesys';

use Data::Dumper;
use Test::Most;
use JSON qw/decode_json/;

extends 'Test::AnyStor::Base';

#===  CLASS METHOD  ==========================================================
#        CLASS: Block
#       METHOD: block_device_list
#        BRIEF: device 목록 조회
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
#                           Name => {device_name},
#                           Type => {ssd|hdd},
#                           Size => ### {GB|MB|KB},
#                       }, ...
#                   ],
#                   statuses => [ { ... }, ... ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub block_device_list
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 'true';

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $return_expect = 'false';
    }

    my %base_args = ();

    my %ext_args = (expected_return => $return_expect);

    my %entity = (scope => $args{scope},);

    my $res = $self->call_rest_api('block/device/list', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}
*block_device_list = \&block_device_list;

#===  CLASS METHOD  ==========================================================
#        CLASS: Block
#       METHOD: block_device_list
#        BRIEF: device 목록 조회
#   PARAMETERS: {
#                   host     => 'x.x.x.x:80',
#                   seckey   => 'secure-key',
#                   argument => { devname => {target_devname} },
#                   entity   => { }
#               }
#      RETURNS: {
#                   msg => "msg_string",
#                   entity => [
#                       {
#                           Name => {device_name},
#                           Type => {SSD|HDD}
#                           Size => ### {GB|MB|KB},
#                           is_os_disk => {0|1},
#                       }
#                   ],
#                   statuses => [ { ... }, ... ],
#                   return => {[true|false]}
#               }
#=============================================================================
sub block_device_info
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $return_expect = 0;
    }

    my %base_args = (devname => $args{devname});

    my %ext_args = (expected_return => $return_expect);

    my %entity = (scope => $args{scope},);

    my $res = $self->call_rest_api('block/device/info', \%base_args, \%entity,
        \%ext_args);

    $self->t->status_is(200)->json_is('/success' => $return_expect)
        ->or(sub { diag(explain($res)); });

    return $res->{entity}->[0];
}
*block_device_info = \&block_device_info;

1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Block - 

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
