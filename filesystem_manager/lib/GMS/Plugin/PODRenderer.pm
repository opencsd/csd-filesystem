package GMS::Plugin::PODRenderer;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use File::Slurp qw/slurp/;
use Mojo::Asset::File;
use Mojo::ByteStream;
use Mojo::DOM;
use Mojo::URL;
use Mojo::Util;
use Pod::Simple::XHTML;
use Pod::Simple::Search;

#---------------------------------------------------------------------------
#   Inheritacnes
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub register
{
    my ($self, $app, $conf) = @_;

    my $preprocess = $conf->{preprocess} || 'ep';

    $app->renderer->add_handler(
        $conf->{name}
            || 'pod' => sub
        {
            my ($renderer, $c, $output, $options) = @_;

            # Preprocess and render
            my $handler = $renderer->handlers->{$preprocess};

            return unless $handler->($renderer, $c, $output, $options);

            $$output = _pod_to_html($$output);

            return 1;
        }
    );

#    $app->helper(
#        pod_to_html => sub { shift; Mojo::ByteStream->new(_pod_to_html(@_)) }
#    );

    $app->routes->any(
        '/doc/:pod'           => {pod => 'GMS', format => 'html'},
        => [pod => qr/[^.]+/] => \&_perldoc
    );

    warn "[INFO] ${\__PACKAGE__} plugin is registered";

    return;
}

#---------------------------------------------------------------------------
#   Private Methods
#---------------------------------------------------------------------------
sub _perldoc
{
    my $c = shift;

    # Find POD
    my $pod = join '::', split('/', $c->param('pod'));
    my $dir = $c->app->home->rel_dir('doc');

    my $path = Pod::Simple::Search->find($pod, $dir);

    my $src = '';

    if (defined($path)
        && length($path)
        && $path =~ m/^$dir/
        && -r $path)
    {
        $src = slurp($path);
    }

    $c->respond_to(
        txt  => {data => $src},
        html => sub { _html($c, $src) }
    );
}

sub _html
{
    my ($c, $src) = @_;

    # 없는 문서인 경우
    if (!length($src))
    {
        my $template = $c->app->renderer->_bundled('not_found');
        return $c->render(inline => $template);
    }

    # Rewrite links
    my $dom = Mojo::DOM->new(_pod_to_html($src));
    my $doc = $c->url_for('/doc/');

    $_->{href} =~ s!^https://metacpan\.org/pod/!$doc!
        and $_->{href} =~ s!::!/!gi
        for $dom->find('a[href]')->map('attr')->each;

    # Rewrite code blocks for syntax highlighting and correct indentation
    for my $e ($dom->find('pre > code')->each)
    {
        my $str = $e->content;

        next
            if $str =~ /^\s*(?:\$|Usage:)\s+/m
            || $str !~ /[\$\@\%]\w|-&gt;\w/m;

        my $attrs = $e->attr;
        my $class = $attrs->{class};

        $attrs->{class}
            = defined $class ? "$class prettyprint" : 'prettyprint';
    }

    # Rewrite headers
    my $toc = Mojo::URL->new->fragment('toc');
    my @parts;

    for my $e ($dom->find('h1, h2, h3')->each)
    {
        push @parts, [] if $e->tag eq 'h1' || !@parts;

        my $anchor = $e->{id};
        my $link   = Mojo::URL->new->fragment($anchor);

        push @{$parts[-1]}, my $text = $e->all_text, $link;

        my $permalink = $c->link_to('#' => $link, class => 'permalink');

        $e->content($permalink . $c->link_to($text => $toc, id => $anchor));
    }

    # Try to find a title
    my $title = 'GMS Documentation';

    $dom->find('h1 + p')->first(sub { $title = shift->text });

    # Combine everything to a proper response
    $c->content_for(pod => "$dom");
    $c->render(title => $title, parts => \@parts);
}

sub _pod_to_html
{
    return ''
        unless defined(my $pod = ref $_[0] eq 'CODE' ? shift->() : shift);

    my $parser = Pod::Simple::XHTML->new;

    $parser->perldoc_url_prefix('https://metacpan.org/pod/');
    $parser->$_('') for qw(html_header html_footer);
    $parser->strip_verbatim_indent(\&_indentation);
    $parser->output_string(\(my $output));

    return $@ unless eval { $parser->parse_string_document("$pod"); 1 };

    return $output;
}

sub _indentation
{
    return (sort map { /^(\s+)/ } @{shift()})[0];
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::PODRenderer - Renderer plugin for online documentation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
