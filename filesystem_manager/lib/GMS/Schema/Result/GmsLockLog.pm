use utf8;

package GMS::Schema::Result::GmsLockLog;

use v5.14;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GMS::Schema::Result::GmsLockLog

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<gms_lock_log>

=cut

__PACKAGE__->table("gms_lock_log");

=head1 ACCESSORS

=head2 lk_name

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 owner_node

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 owner_pid

  data_type: 'varchar'
  is_nullable: 0
  size: 8

=head2 action

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 status

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 local_time

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
    "lk_name",
    {data_type => "varchar", is_nullable => 0, size => 64},
    "owner_node",
    {data_type => "varchar", is_nullable => 0, size => 32},
    "owner_pid",
    {data_type => "varchar", is_nullable => 0, size => 8},
    "action",
    {data_type => "varchar", is_nullable => 0, size => 32},
    "status",
    {data_type => "varchar", is_nullable => 0, size => 32},
    "local_time",
    {data_type => "integer", extra => {unsigned => 1}, is_nullable => 0},
    "time",
    {
        data_type                 => "timestamp",
        datetime_undef_if_invalid => 1,
        default_value             => \"current_timestamp",
        is_nullable               => 0,
    },
);

# Created by DBIx::Class::Schema::Loader v0.07043 @ 2017-09-04 16:43:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KEQ6bfpNv2SYCfqql3pmGw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
