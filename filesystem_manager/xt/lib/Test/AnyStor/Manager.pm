package Test::AnyStor::Manager;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';
use Test::Most;
use Data::Dumper;

extends 'Test::AnyStor::Base';

sub info
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/manager/info',
        params => {
            ID => $args{ID}
        }
    );

    return if (!$self->t->success);

    my $info = $res->{entity};

    diag(sprintf("Admin: %s", Dumper($info)));

#    map {
#        cmp_ok($args{$_}, 'eq', $info->{$_}, "manager info check for $_");
#    } keys(%args);

    return $info;
}

sub update
{
    my $self = shift;
    my %args = @_;

    my %params = (
        ID            => $args{ID}            // 'admin',
        Name          => $args{Name}          // 'admin',
        Phone         => $args{Phone}         // '010-0000-0000',
        Email         => $args{Email}         // 'admin@admin.com',
        Organization  => $args{Organization}  // 'Gluesys Co., Ltd.',
        Engineer      => $args{Engineer}      // 'Gluesys',
        EngineerPhone => $args{EngineerPhone} // '070-8787-5370',
        EngineerEmail => $args{EngineerEmail} // 'admin@gluesys.com',
    );

    my $res = $self->request(
        uri    => '/cluster/manager/update',
        params => \%params,
    );

    $self->info(%args);

    return !$self->t->success;
}

sub delegate
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/manager/delegate',
        params => {
            ID => $args{ID},
        }
    );

    return $self->t->success ? 0 : -1;
}

sub dismiss
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/manager/dismiss',
        params => {
            ID => $args{ID},
        }
    );

    return $self->t->success ? 0 : -1;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Test::AnyStor::Manager - 관리자 기능 검사를 구현하는 클래스

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

