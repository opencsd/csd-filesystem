package Test::Role::Dir;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Moose::Role;
use Test::More;

sub make_dir
{
    my $dir = shift;

    if (!$dir)
    {
        diag("invalid dir name");
        return -1;
    }

    if (-d $dir)
    {
        diag("$dir is aleady exist\n");
        return 0;
    }

    mkdir($dir);

    return 0;
}

1;
