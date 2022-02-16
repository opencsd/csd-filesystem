package GMS::Controller::Manual;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use MouseX::Foreign;

use Encode qw/decode_utf8/;
use Text::Markdown::Hoedown;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/usr/gms/doc/manual',
);

has 'extensions' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub
    {
        int(
            0 | Text::Markdown::Hoedown::HOEDOWN_EXT_TABLES
                | Text::Markdown::Hoedown::HOEDOWN_EXT_FENCED_CODE
                | Text::Markdown::Hoedown::HOEDOWN_EXT_FOOTNOTES
                | Text::Markdown::Hoedown::HOEDOWN_EXT_AUTOLINK
                | Text::Markdown::Hoedown::HOEDOWN_EXT_STRIKETHROUGH

                #| Text::Markdown::Hoedown::HOEDOWN_EXT_UNDERLINE
                | Text::Markdown::Hoedown::HOEDOWN_EXT_HIGHLIGHT
                | Text::Markdown::Hoedown::HOEDOWN_EXT_QUOTE
                | Text::Markdown::Hoedown::HOEDOWN_EXT_SUPERSCRIPT
                | Text::Markdown::Hoedown::HOEDOWN_EXT_MATH
                | Text::Markdown::Hoedown::HOEDOWN_EXT_SPACE_HEADERS
        );
    }
);

has 'html_options' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub
    {
        int(0 | Text::Markdown::Hoedown::HOEDOWN_HTML_USE_XHTML);
    },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub main
{
    my $c = shift;

    my $lang = $c->param('lang') // 'ko';

    $c->render(
        template => "manual/$lang",
        format   => 'html',
        handler  => 'ep',
    );
}

sub intro
{
    my $c = shift;

    my $lang = $c->param('lang') // 'ko';

    my $converted = $c->_render_md($lang, 'intro', qw/intro/);

    $c->render(

        #template => "manual/${\$c->cookie('language')}",
        #format   => 'html',
        #handler  => 'ep',
        #content  => $converted,
        inline => $converted,
    );
}

sub install
{
    my $c = shift;

    my $lang = $c->param('lang') // 'ko';

    my $converted = $c->_render_md($lang, 'install',
        qw/preparation rpmInstall isoInstall configuration/);

    $c->render(inline => $converted,);
}

sub cluster
{
    my $c = shift;

    my $lang = $c->param('lang') // 'ko';

    my $converted = $c->_render_md(
        $lang,
        'cluster',
        qw/intro overview clusterNode event network notification time power log license/
    );

    $c->render(inline => $converted);
}

sub cluster_volume
{
    my $c = shift;

    my $lang = $c->param('lang') // 'ko';

    my $converted = $c->_render_md($lang, 'clusterVolume',
        qw/intro volumePool volume snapshot/);

    $c->render(inline => $converted);
}

sub account
{
    my $c = shift;

    my $lang = $c->param('lang') // 'ko';

    my $converted = $c->_render_md($lang, 'account',
        qw/intro user group external admin/);

    $c->render(inline => $converted);
}

sub share
{
    my $c = shift;

    my $lang = $c->param('lang') // 'ko';

    my $converted = $c->_render_md($lang, 'share', qw/intro protocol share/);

    $c->render(inline => $converted);
}

sub node
{
    my $c = shift;

    my $lang = $c->param('lang') // 'ko';

    my $converted = $c->_render_md(
        $lang,
        'node',
        qw/intro condition disk volume process raid bond device address power smart/
    );

    $c->render(inline => $converted);
}

sub trbl
{
    my $c = shift;

    my $lang    = $c->param('lang') // 'ko';
    my $chapter = $c->param('chapter');

    if (!defined($lang))
    {
        $lang = 'ko';
    }

    my $converted = $c->_render_md($lang, 'troubleshoot', $chapter);

    $c->render(inline => $converted);
}

sub questions
{
    my $c = shift;

    my $lang    = $c->param('lang') // 'ko';
    my $chapter = $c->param('chapter');

    if (!defined($lang))
    {
        $lang = 'ko';
    }

    my $converted = $c->_render_md($lang, 'questions', $chapter);

    $c->render(inline => $converted);
}

#---------------------------------------------------------------------------
#   Functions
#---------------------------------------------------------------------------
sub _render_md
{
    my $c        = shift;
    my $lang     = shift;
    my $category = shift;
    my @files    = @_;

    my $dir      = "${\$c->dir}/$lang/$category";
    my $markdown = '';

    local $/;

    foreach my $file (@files)
    {
        my $fh;
        my $fname = sprintf('%s/%s.md', $dir, $file);

        if (!open($fh, '<', $fname))
        {
            warn "[ERR] Failed to open: $fname: $!";
            next;
        }

        $markdown .= <$fh>;
        $markdown .= "\n\n";

        close($fh) if (defined($fh));
    }

    $markdown = markdown(
        decode_utf8($markdown),
        extensions   => $c->extensions,
        html_options => $c->html_options
    );

    $markdown =~ s|"\./images/(?<path>[^"]+)"
            |"/manual/$lang/$category/images/$+{path}"|gx;

    return $markdown;
}

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub BUILDARGS
{
    my $class = shift;

    return Mojo::Base->new(@_);
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Manual - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=item B<Item 1>

=item B<Item 2>

=item B<Item 3>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2020. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

