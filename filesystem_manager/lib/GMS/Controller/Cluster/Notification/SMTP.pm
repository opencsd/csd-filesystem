package GMS::Controller::Cluster::Notification::SMTP;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return;

use GMS::Model::Cluster::Network::DNS;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Notification::SMTP';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
around 'config' => sub
{
    my $orig = shift;
    my $self = shift;

    # SMTP Notification need to establish DNS server
    my $dns = GMS::Model::Cluster::Network::DNS->new();

    if (!$dns->count_entries)
    {
        $self->throw_error(message => 'Please try to configure your DNS');
    }

    $self->$orig(@_);
};

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Notification::SMTP - GMS API controller for SMTP notification

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

