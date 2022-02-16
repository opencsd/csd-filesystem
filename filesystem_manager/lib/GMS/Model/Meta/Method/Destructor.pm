package GMS::Model::Meta::Method::Destructor;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use GMS::Common::Logger;
use Mouse::Role;
use Mouse::Util;
use Scalar::Util qw/refaddr/;

around '_generate_destructor' => sub
{
    my $orig = shift;
    my $self = shift;
    my $args = shift;

    my $code = $self->$orig($args);

    return sub
    {
        my $self = shift;
        my $root = $self->meta->etcd_root;

        if (Mouse::Util::in_global_destruction())
        {
            release_sig_warn();
        }

        if (!$self->meta->get_lock_scope($self))
        {
            warn sprintf('[DEBUG] undefined lock scope: %s: %s(%s)',
                $root, $self, refaddr($self));

            return;
        }

        warn sprintf('[DEBUG] Trying to unlocking model: %s',
            $self->meta->get_lock_scope($self) // 'undef',
        );

        if ($self->unlock())
        {
            warn sprintf('[ERR] Failed to release model lock: %s',
                $self->meta->get_lock_scope($self) // 'undef',
            );
        }

        delete($self->meta->locks->{refaddr($self)});

        $code->($self);
    };
};

no Mouse::Role;
1;

=encoding utf8

=head1 NAME

GMS::Model::Meta::Method::Destructor - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 CONTRIBUTORS

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

