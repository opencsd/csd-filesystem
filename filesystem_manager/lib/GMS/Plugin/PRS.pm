package GMS::Plugin::PRS;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return;
use GMS::Cluster::Etcd;
use GMS::Common::Logger;
use Try::Tiny;

#---------------------------------------------------------------------------
#   Inheritacnes
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'etcd' => (
    is      => 'ro',
    isa     => 'GMS::Cluster::Etcd',
    default => sub { GMS::Cluster::Etcd->new(); },
);

has 'prs' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {}; },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub register
{
    my ($self, $app, $args) = @_;

    $app->helper(prs => sub { $self->prs; });

    # PRS에 새로운 상태 배열 추가 후 반환
    $app->helper(
        set_prs => sub
        {
            my $c      = shift;
            my $req_id = shift;

            #warn "[DEBUG] The number of PRS: ${\scalar(keys(%{$self->prs}))}";

            # :TODO 09/07/2019 12:02:36 AM: by P.G.
            # exception handling for API return
            try
            {
                if (!defined($req_id))
                {
                    die "Invalid request ID: $req_id";
                }

                if (!exists($c->prs->{$req_id}))
                {
                    $c->prs->{$req_id} = {
                        stash    => $c->stash,
                        statuses => [],
                    };

                    warn sprintf(
                        '[DEBUG] PRS is initialized: %s: %s',
                        $req_id, $c->prs->{$req_id},
                    );
                }

                #warn sprintf(
                #    '[DEBUG] set_prs: %s: %s: %s',
                #    $req_id,
                #    $c->prs->{$req_id}->{statuses},
                #    $c->dumper($c->prs->{$req_id}->{statuses}),
                #);

                my $prs = $c->prs->{$req_id};

                map {
                    if ($c->stash($_) ne $prs->{stash}->{$_})
                    {
                        warn "[DEBUG] Stash will be updated: $_";

                        $c->stash($_ => $prs->{stash}->{$_});
                    }
                } keys(%{$prs->{stash}});

                if (!defined(set_api_statuses(\$prs->{statuses})))
                {
                    die sprintf('Failed to set API statuses: %s: %s',
                        $req_id, $c->dumper($prs->{statuses}));
                }

                return $prs;
            }
            catch
            {
                warn "[ERR] PRS exception happend: $_";
                return;
            };
        }
    );

    # PRS의 상태 배열 제거 후 배열 반환
    $app->helper(
        unset_prs => sub
        {
            my $c      = shift;
            my $req_id = shift;

            warn sprintf(
                '[DEBUG] unset_prs: %s: %s: %s',
                $req_id,
                $c->prs->{$req_id}->{statuses},
                $c->dumper($c->prs->{$req_id}->{statuses}),
            );

            try
            {
                return delete($self->prs->{$req_id});
            }
            catch
            {
                warn "[ERR] Failed to clear PRS: $_";
            };
        }
    );

    warn "[INFO] ${\__PACKAGE__} plugin is registered";

    return;
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::PRS - GMS plugin to support PRS(Per-Request-Stash)

=head1 SYNOPSIS

This plugin provides per-request-stash with etcd for GMS.

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

