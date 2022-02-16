package GMS::Controller::License;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return;
use GMS::Cluster::HTTP;
use GMS::System::LicenseCtl;
use Sys::Hostname::FQDN qw/short/;

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
    default => sub { GMS::System::LicenseCtl->new(); },
);

sub license_list
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(
        json => $self->ctl->__list_license(
            $params->{argument}, $params->{entity}
        )
    );
}

sub license_summary
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(
        json => $self->ctl->__summary_license(
            $params->{argument}, $params->{entity}
        )
    );
}

sub license_check
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(
        json => $self->ctl->__check_license(
            $params->{argument}, $params->{entity}
        )
    );
}

sub license_register
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result
        = $self->ctl->__reg_license($params->{argument}, $params->{entity});

    my $http = GMS::Cluster::HTTP->new();

    my $host = short();

    my @resps = $http->request(
        uri  => '/api/system/license/reload',
        body => {
            argument => {},
            entity   => {},
        },
        filter => sub { ($host =~ /^.+-\d*1$/ && $host eq shift) ? 0 : 1 },
    );

    if (grep { !$_->success; } @resps)
    {
        $result->[0]->{reload_stat} = 'Failed';

        $self->app->api_status(
            code  => LICENSE_RELOAD_FAILURE,
            level => 'WARN',
        );

        goto RETURN;
    }

    $result->[0]->{reload_stat} = 'OK';

RETURN:
    $self->publish_event();
    $self->render(json => $result);
}

sub license_reload
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(
        json => $self->ctl->__reload_license(
            $params->{argument}, $params->{entity}
        )
    );

    $self->publish_event();
    $self->app->run_checkers('LicenseAlert');
}

sub license_test
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(
        json => $self->ctl->__test_license(
            $params->{argument}, $params->{entity}
        )
    );
}

sub unique_key
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->render(
        json => $self->ctl->__get_uniquekey(
            $params->{argument}, $params->{entity}
        )
    );
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::System - 

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

