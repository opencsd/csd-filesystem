package Test::Cluster::Network::Zone;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::Network::Zone';

has '+cntlr' => (default => 'Mock::Controller::Cluster::Network',);

has '+uri' => (
    default => sub
    {
        list       => '/api/cluster/network/zone/list',
            info   => '/api/cluster/network/zone/info',
            create => '/api/cluster/network/zone/create',
            update => '/api/cluster/network/zone/update',
            delete => '/api/cluster/network/zone/delete',
            ;
    },
);

has '+scope' => (default => 'Cluster',);

sub test_setup
{
    my $self = shift;

    return $self->test_skip('This test will not performed');
}

#sub test_zone_list : Test(no_plan)
#{
#    shift->SUPER::test_zone_list(@_);
#}
#
#sub test_zone_info : Test(no_plan)
#{
#    shift->SUPER::test_zone_info(@_);
#}
#
#sub test_zone_create : Test(no_plan)
#{
#    shift->SUPER::test_zone_create(@_);
#}
#
#sub test_zone_update : Test(no_plan)
#{
#    shift->SUPER::test_zone_update(@_);
#}
#
#sub test_zone_delete : Test(no_plan)
#{
#    shift->SUPER::test_zone_delete(@_);
#}

#__PACKAGE__->add_filter(
#    sub {
#        my ($class, $method) = @_;
#        return $class eq __PACKAGE__;
#    }
#);

1;

=encoding utf8

=head1 NAME

Test::Network::Cluster::Zone - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

