package Test::AnyStor::Email;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::Most;

extends 'Test::AnyStor::Base';

sub email
{
    my $self = shift;
    my %args = @_;

    my %entity = (
        Enabled     => 'true',
        Alert_Level => 3,
        Server      => 'mail.gluesys.com',
        Port        => 587,
        Security    => 'StartTLS',
        Auth        => 'true',
        ID          => 'polishedwh@gluesys.com',
        Pass        => 'rmffntltm1',
        Receiver    => 'AnyStor-E Members <ac2@gluesys.com>',
        Sender      => 'AnyStor-E <anystor-e@gluesys.com>',
    );

    my $res = $self->call_rest_api('system/smtp/test', {}, \%entity, {});

    return 1 if ($res->{success} == 0);
    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::Email - 

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
