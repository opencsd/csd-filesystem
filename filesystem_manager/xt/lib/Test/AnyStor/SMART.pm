package Test::AnyStor::SMART;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Dumper;
use Test::Most;
use JSON qw/decode_json/;

extends 'Test::AnyStor::Base';

# args
# id : ArraRef[Str]|Undef
sub smart_dev_info
{
    my $self = shift;
    my %args = @_;

    my $id = $args{id};

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    if (defined $id && ref $id eq 'ARRAY')
    {
        $entity{id} = $id;
    }

    my $res
        = $self->call_rest_api('smart/devices/info', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

# args
# id : ArraRef[Str]|Undef
sub smart_dev_attrs
{
    my $self = shift;
    my %args = @_;

    my $id = $args{id};

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    if (defined $id && ref $id eq 'ARRAY')
    {
        $entity{id} = $id;
    }

    my $res
        = $self->call_rest_api('smart/devices/attrs', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

# args
# id : ArraRef[Str]|Undef
# latest : 0 or 1
sub smart_dev_tests
{
    my $self = shift;
    my %args = @_;

    my $id     = $args{id};
    my $latest = $args{latest};

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    if (defined $id && ref $id eq 'ARRAY')
    {
        $entity{id} = $id;
    }

    if (defined $latest)
    {
        $entity{latest} = $latest;
    }

    my $res = $self->call_rest_api('smart/devices/tests/list', \%base_args,
        \%entity, \%ext_args);

    return $res->{entity};
}

# args
# id : ArrayRef[Str]
sub smart_dev_test_trigger
{
    my $self = shift;
    my %args = @_;

    my $id = $args{id};

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    if (defined $id && ref $id eq 'ARRAY')
    {
        $entity{id} = $id;
    }

    my $res = $self->call_rest_api('smart/devices/tests/trigger', \%base_args,
        \%entity, \%ext_args);

    return $res->{entity};
}

# args
sub smart_dev_info_reload
{
    my $self = shift;
    my %args = @_;

    my %base_args = ();
    my %ext_args  = ();
    my %entity    = ();

    my $res
        = $self->call_rest_api('smart/devices/reload', \%base_args, \%entity,
        \%ext_args);

    return $res->{entity};
}

1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::SMART - 

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
