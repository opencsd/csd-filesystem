use utf8;

package GMS::Schema::Result::MysqlAliveChk;

use v5.14;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GMS::Schema::Result::MysqlAliveChk

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<mysql_alive_chk>

=cut

__PACKAGE__->table("mysql_alive_chk");

=head1 ACCESSORS

=head2 hostname

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns("hostname",
    {data_type => "varchar", is_nullable => 1, size => 255},
);

# Created by DBIx::Class::Schema::Loader v0.07043 @ 2017-09-04 16:43:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M+4d3XcVHsBoY611rLPhMQ

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
