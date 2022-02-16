package Mock::Controller::Cluster::Network;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::MockModule;

use Mock::Model::Cluster::Network::VIP;
use Mock::Model::Cluster::Network::Zone;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller::Cluster::Network';

#---------------------------------------------------------------------------
#   Role Consuming
#---------------------------------------------------------------------------
with 'Mock::Controllable';

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
override 'build_models' => sub
{
    my $self = shift;

    return {
        VIP  => 'Mock::Model::Cluster::Network::VIP',
        Zone => 'Mock::Model::Cluster::Network::Zone',
    };
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Mock::Controller::Cluster::Network - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

