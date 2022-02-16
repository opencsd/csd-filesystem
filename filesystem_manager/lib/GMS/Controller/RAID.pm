package GMS::Controller::RAID;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::RAID::RAIDCtl;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'ctl' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::RAID::RAIDCtl->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub adapter_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->adplist(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub adapter_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->adpinfo(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub pd_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->pdlist(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub pd_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->pdinfo(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub ld_list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->ldlist(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub ld_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->ldinfo(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::RAID - 

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

