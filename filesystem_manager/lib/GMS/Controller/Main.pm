package GMS::Controller::Main;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Mojo::Util qw/b64_encode url_escape/;

use GMS::API::Return;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'copyright' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => 'Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.',
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub welcome
{
    my $c      = shift;
    my $params = $c->req->json;

    my ($token, $jwt) = $c->authenticate();

    if (defined($token))
    {
        $c->redirect_to('/manager');
        return;
    }

    # Set-Cookie header does not allow newline character
    my ($signing_key, $latest) = $c->get_signing_pubkey;

    #$signing_key = join('', split(/\n+/, $signing_key));
    #$signing_key =~ s/-+BEGIN[^-]+-+//g;
    #$signing_key =~ s/-+END[^-]+-+//g;

    warn "[DEBUG] signing_key: $signing_key";

    $signing_key = url_escape(b64_encode($signing_key));

    $c->cookie(
        signing_key => $signing_key,
        {
            expires => $latest + 600
        }
    );

    # Render template "main/welcome.html.ep" with message
    $c->render(
        template  => 'main/login',
        title     => 'Gluesys Management System',
        copyright => $c->copyright,
        lang      => $c->inspect_lang(),
    );
}

sub manager
{
    my $c = shift;

    my ($token, $jwt) = $c->authenticate();

    if (!defined($token))
    {
        $c->redirect_to('/');
        return;
    }

    $c->render(
        template => 'main/manager',
        lang     => $c->inspect_lang(),
    );
}

sub config
{
    my $c = shift;

    $c->render(
        template => 'main/config',
        lang     => $c->inspect_lang(),
    );
}

sub init
{
    my $c = shift;

    $c->render(
        template => 'main/init',
        lang     => $c->inspect_lang(),
    );
}

sub dummy
{
    my $c = shift;

    api_status(
        category => 'DUMMY',
        level    => 'INFO',
        code     => DUMMY_TEST,
        quiet    => 1
    );

    $c->app->gms_new_event(locale => $c->inspect_lang());

    $c->render(status => 200, json => {});
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Main - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

