package Test::AnyStor::Dashboard;

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

sub event_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/event/list',
        params => {
            NumOfRecords => $args{numofrecords} // 10,
            PageNum      => $args{pagenum}      // 1,
            From         => $args{from},
            To           => $args{to},
            Category     => $args{type},
            Type         => $args{type},
            Level        => $args{level},
        }
    );

    $self->t->json_has('/entity', 'has entity')
        ->json_has('/total', 'has total')->json_has('/count', 'has count');

    cmp_ok(ref($res->{entity}), 'eq', 'ARRAY', 'entity isa ARRAY');

    if (!$self->t->success)
    {
        return;
    }

    for (my $i = 0; $i < @{$res->{entity}}; $i++)
    {
        if (defined($args{from}))
        {
            # %Y/%m/%d %T 를 구문 분석하여 변환 후 비교?
        }

        if (defined($args{to}))
        {
            # %Y/%m/%d %T 를 구문 분석하여 변환 후 비교?
        }

        if (defined($args{category}))
        {
            $self->t->json_is(
                "/entity/$i/Category",
                $args{category},
                "event match: Category"
            );
        }

        if (defined($args{type}))
        {
            $self->t->json_is("/entity/$i/Type", $args{type},
                "event match: Type");
        }

        if (defined($args{level}))
        {
            $self->t->json_is("/entity/$i/Level", $args{level},
                "event match: Level");
        }

        map {
            my $f = ucfirst($_);

            $self->t->json_like(
                "/entity/$i/$f",
                qr/$args{pattern}/i,
                "event match: $f"
            );
        } @{$args{fields}};
    }

    return @{$res->{entity}};
}

sub task_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/task/list',
        params => {
            NumOfRecords => $args{numofrecords} // 10,
            PageNum      => $args{pagenum}      // 1,
            From         => $args{from},
            To           => $args{to},
            Category     => $args{category},
            Type         => $args{type},
            Level        => $args{level},
        },
    );

    $self->t->json_has('/entity', 'has entity')
        ->json_has('/total', 'has total')->json_has('/count', 'has count');

    cmp_ok(ref($res->{entity}), 'eq', 'ARRAY', 'entity isa ARRAY');

    if (!$self->t->success)
    {
        return;
    }

    for (my $i = 0; $i < @{$res->{entity}}; $i++)
    {
        if (defined($args{from}))
        {
            # %Y/%m/%d %T 를 구문 분석하여 변환 후 비교?
        }

        if (defined($args{to}))
        {
            # %Y/%m/%d %T 를 구문 분석하여 변환 후 비교?
        }

        if (defined($args{category}))
        {
            $self->t->json_is(
                "/entity/$i/Category",
                $args{category},
                "task match: Category"
            );
        }

        if (defined($args{type}))
        {
            $self->t->json_is(
                "/entity/$i/Type",
                $args{type},
                "task match: Type"
            );
        }

        if (defined($args{level}))
        {
            $self->t->json_is(
                "/entity/$i/Level",
                $args{level},
                "task match: Level"
            );
        }

        map {
            my $f = ucfirst($_);

            $self->t->json_like(
                "/entity/$i/$f",
                qr/$args{pattern}/i,
                "task match: $f"
            );
        } @{$args{fields}};
    }

    return @{$res->{entity}};
}

sub task_count
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/task/count',
        params => {
            NumOfRecords => $args{numofrecords} // 10,
            PageNum      => $args{pagenum}      // 1,
            From         => $args{from},
            To           => $args{to},
            Category     => $args{category}
        }
    );

    $self->t->json_has('/entity', 'has entity')
        ->json_has('/entity/info', 'has entity->info')
        ->json_has('/entity/warn', 'has entity->warn')
        ->json_has('/entity/err',  'has entity->err');

    return $res->{entity};
}

sub clientgraph
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/cluster/dashboard/clientgraph',);

    $self->t->json_has('/entity', 'has entity');

    cmp_ok(ref($res->{entity}), 'eq', 'ARRAY', 'entity isa ARRAY');

    if (!$self->t->success)
    {
        return;
    }

    return @{$res->{entity}};
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Test::AnyStor::Dashbaord - 대시보드 API 검사를 구현하는 클래스

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

