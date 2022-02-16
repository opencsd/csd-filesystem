package Test::Role::FileReadWrite;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Moose::Role;
use IO::File;

sub file_write
{
    my $file    = shift;
    my @strings = @_;
    my $fh;

    if (!$file)
    {
        die("Invalid file name : '$file'\n");
    }

    $fh = IO::File->new($file, '>');

    if (!defined($fh))
    {
        die("File open failed\n");
    }

    foreach my $s (@strings)
    {
        print $fh ($s);
    }

    close($fh);
}

1;
