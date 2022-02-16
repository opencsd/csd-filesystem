package Test::AnyStor::Explorer;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use JSON qw/decode_json/;
use Test::Most;
use Data::Dumper;

extends 'Test::AnyStor::Base';

my $event_check = 1;

sub list
{
    my $self = shift;
    my %args = @_;

    my %base_args = (
        dirpath => $args{path},
        type    => $args{type},
    );

    my %entity = ();

    my $res
        = $self->call_rest_api("explorer/list", \%base_args, \%entity, {},);

    return $res->{entity};
}

sub info
{
    my $self = shift;
    my %args = @_;

    my %base_args = (dirpath => $args{path},);

    my %entity = ();

    my $res
        = $self->call_rest_api("explorer/info", \%base_args, \%entity, {},);

    return $res->{entity}[0];
}

sub checkdir
{
    my $self = shift;
    my %args = @_;

    my %base_args = (dirpath => $args{path},);

    my %entity = ();

    my $res = $self->call_rest_api("explorer/checkdir", \%base_args, \%entity,
        {},);

    return $res->{entity}[0];
}

sub makedir
{
    my $self = shift;
    my %args = @_;

    my %base_args = (
        dirpath    => $args{path},
        permission => $args{perm},
        recursive  => $args{recursive},
    );

    my %entity = ();

    my $res = $self->call_rest_api("explorer/makedir", \%base_args, \%entity,
        {},);

    if ($event_check)
    {
        sleep 5;

        ok(
            $self->is_code_exist_in_recent_events(
                'EXPLORER_DIRECTORY_CREATE_OK',
                $res->{prof}{from},
            ),
            "'EXPLORER_DIRECTORY_CREATE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub changeperm
{
    my $self = shift;
    my %args = @_;

    my %base_args = (
        dirpath    => $args{path},
        permission => $args{perm},
        recursive  => $args{recursive},
    );

    my %entity = ();

    my $res
        = $self->call_rest_api("explorer/changeperm", \%base_args, \%entity,
        {},);

    if ($event_check)
    {
        sleep 5;

        ok(
            $self->is_code_exist_in_recent_events(
                'EXPLORER_DIRECTORY_CHPERM_OK',
                $res->{prof}{from},
            ),
            "'EXPLORER_DIRECTORY_CHPERM_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub changeown
{
    my $self = shift;
    my %args = @_;

    my %base_args = (
        dirpath   => $args{path},
        user      => $args{user},
        group     => $args{group},
        recursive => $args{recursive},
    );

    my %entity = ();

    my $res
        = $self->call_rest_api("explorer/changeown", \%base_args, \%entity,
        {},);

    if ($event_check)
    {
        sleep 5;

        ok(
            $self->is_code_exist_in_recent_events(
                'EXPLORER_DIRECTORY_CHOWN_OK', $res->{prof}{from},
            ),
            "'EXPLORER_DIRECTORY_CHOWN_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub setfacl
{
    my $self = shift;
    my %args = @_;

    my %api_args = (
        Type        => $args{Type},
        Path        => $args{Path},
        Permissions => $args{Permissions},
    );

    my %entity = ();

    my $expected = $args{expected} // 1;

    my $res = $self->call_rest_api(
        'explorer/setfacl',
        \%api_args,
        \%entity,
        {
            expected_return => $expected,
        },
    );

#    if ($event_check)
#    {
#        sleep 5;
#
#        ok($self->is_code_exist_in_recent_events(
#                'EXPLORER_SET_ACL_OK',
#                $res->{prof}{from},
#            )
#            , "'EXPLORER_SET_ACL_OK' event check");
#    }

    diag(explain($res));

    return $res->{success} == $expected;
}

sub cluster_list
{
    my $self = shift;
    my %args = @_;

    my %base_args = (
        dirpath => $args{path},
        type    => $args{type},
    );

    my %entity = ();

    my $res
        = $self->call_rest_api("cluster/explorer/list", \%base_args, \%entity,
        {},);

    return $res->{entity}[0];
}

sub cluster_info
{
    my $self = shift;
    my %args = @_;

    my %base_args = (dirpath => $args{path},);

    my %entity = ();

    my $res
        = $self->call_rest_api("cluster/explorer/info", \%base_args, \%entity,
        {},);

    return $res->{entity}[0];
}

sub cluster_checkdir
{
    my $self = shift;
    my %args = @_;

    my %base_args = (dirpath => $args{path},);

    my %entity = ();

    my $res = $self->call_rest_api("cluster/explorer/checkdir", \%base_args,
        \%entity, {},);

    return $res->{entity}[0];
}

sub cluster_makedir
{
    my $self = shift;
    my %args = @_;

    my %base_args = (
        dirpath    => $args{path},
        permission => $args{perm},
        recursive  => $args{recursive},
    );

    my %entity = ();

    my $res = $self->call_rest_api("cluster/explorer/makedir", \%base_args,
        \%entity, {},);

    if ($event_check)
    {
        sleep 5;

        ok(
            $self->is_code_exist_in_recent_events(
                'CLST_EXPLORER_DIRECTORY_CREATE_OK',
                $res->{prof}{from}
            ),
            "'CLST_EXPLORER_DIRECTORY_CREATE_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_changeperm
{
    my $self = shift;
    my %args = @_;

    my %base_args = (
        dirpath    => $args{path},
        permission => $args{perm},
        recursive  => $args{recursive},
    );

    my %entity = ();

    my $res = $self->call_rest_api("cluster/explorer/changeperm", \%base_args,
        \%entity, {},);

    if ($event_check)
    {
        sleep 5;

        ok(
            $self->is_code_exist_in_recent_events(
                'CLST_EXPLORER_DIRECTORY_CHPERM_OK',
                $res->{prof}{from},
            ),
            "'CLST_EXPLORER_DIRECTORY_CHPERM_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

sub cluster_changeown
{
    my $self = shift;
    my %args = @_;

    my %base_args = (
        dirpath   => $args{path},
        user      => $args{user},
        group     => $args{group},
        recursive => $args{recursive},
    );

    my %entity = ();

    my $res = $self->call_rest_api("cluster/explorer/changeown", \%base_args,
        \%entity, {},);

    if ($event_check)
    {
        sleep 5;

        ok(
            $self->is_code_exist_in_recent_events(
                'CLST_EXPLORER_DIRECTORY_CHOWN_OK',
                $res->{prof}{from},
            ),
            "'CLST_EXPLORER_DIRECTORY_CHOWN_OK' event check"
        );
    }

    return $res->{success} ? 0 : -1;
}

1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Explorer - 

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
