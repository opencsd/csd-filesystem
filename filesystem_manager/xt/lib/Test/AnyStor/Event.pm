package Test::AnyStor::Event;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::AnyStor::Base;
use Test::Most;

extends 'Test::AnyStor::Base';

sub event_validate
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/cluster/debug/validate_event');

    if (!$self->t->success)
    {
        paint_err();
        fail("ERROR:");
        paint_reset();
        return -1;
    }

    if (ref($res->{entity}->{valid}) ne 'ARRAY')
    {
        paint_err();
        fail("Event validation for valid events: ${\explain($res)}");
        paint_reset();
    }

    if (ref($res->{entity}->{invalid}) ne 'ARRAY'
        || @{$res->{entity}->{invalid}})
    {
        paint_err();
        fail("Event validation for invalid events: ${\explain($res)}");
        paint_reset();
    }

    my $total = scalar(@{$res->{entity}->{valid}})
        + scalar(@{$res->{entity}->{invalid}});

    if ($total != $res->{entity}->{total})
    {
        paint_err();
        fail("Event validation for the number of events: ${\explain($res)}");
        paint_reset();
        return -1;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Test::AnyStor::Event - 이벤트/태스크 검사를 구현하는 클래스

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

