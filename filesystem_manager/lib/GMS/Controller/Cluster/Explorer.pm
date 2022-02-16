package GMS::Controller::Cluster::Explorer;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return;
use GMS::Explorer::ExplorerCtl;

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
    default => sub { GMS::Explorer::ExplorerCtl->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub list
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->distribute_list_dir($params->{argument},
        $params->{entity});

    $self->render(json => $result);
}

sub info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->distribute_info_dir($params->{argument},
        $params->{entity},);

    $self->render(json => $result);
}

sub check_dir
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->distribute_is_dir($params->{argument},
        $params->{entity},);

    $self->render(json => $result);
}

sub make_dir
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->distribute_mk_dir($params->{argument},
        $params->{entity},);

    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => $result);
}

sub change_perm
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->distribute_ch_perm($params->{argument},
        $params->{entity},);

    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => $result);
}

sub change_own
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->distribute_ch_own($params->{argument},
        $params->{entity},);

    $self->app->gms_new_event(locale => $self->req->json->{lang});
    $self->render(json => $result);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Cluster::Explorer - 

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

