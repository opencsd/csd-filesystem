package Mock::Model::Network::Hostname;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Sys::Hostname::FQDN qw/short/;

use GMS::Model;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Model::Network::Hostname';

#---------------------------------------------------------------------------
#   Model Definition
#---------------------------------------------------------------------------
etcd_root GMS::Model::Network::Hostname->meta->etcd_root;

#---------------------------------------------------------------------------
#   Overrided Methods
#---------------------------------------------------------------------------
state $static = short();
state $pretty = short();

override 'get_hostname' => sub
{
    my $self = shift;
    my $type = shift;

    return $type eq 'static' ? $static : $pretty;
};

override 'set_hostname' => sub
{
    my $self     = shift;
    my $type     = shift;
    my $hostname = shift;

    if ($type eq 'static')
    {
        return $static = $hostname;
    }

    return $pretty = $hostname;
};

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Mock::Model::Network::Hostname - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

