package GMS::Role::Lockable;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse::Role;
use namespace::clean -except => 'meta';

use Coro;
use AnyEvent;
use Coro::AnyEvent;
use Data::Dumper;
use GMS::Common::Logger qw/catch_sig_warn get_log_options/;
use GMS::Cluster::Etcd;
use Scalar::Util qw/refaddr weaken isweak/;
use Sys::Hostname::FQDN qw/short/;
use Try::Tiny;

#---------------------------------------------------------------------------
#   Requirements
#---------------------------------------------------------------------------
requires qw/validate/;

#state $TABLE;
#$TABLE = {};
#state $SEM;
#$SEM = Coro::Semaphore->new(1);
#state $REAPER;
#$REAPER = async
#{
#    $Coro::current->{desc} = 'lock-reaper';
#
#    catch_sig_warn();
#
#    my $etcd = GMS::Cluster::Etcd->new();
#    my $ts   = 0;
#
#    while (1)
#    {
#        if (int(time - $ts) >= 10)
#        {
#            warn "[DEBUG] Lock reaper is running...: ${\Dumper($TABLE)}";
#            $ts = time;
#        }
#
#        $SEM->down();
#
#        try
#        {
#            foreach my $refaddr (keys(%{$TABLE}))
#            {
#                next if (defined($TABLE->{$refaddr}->{instance}));
#
#                my $lock = $TABLE->{$refaddr};
#
#                if (ref($lock->{locks}) ne 'ARRAY')
#                {
#                    warn sprintf('[DEBUG] Invalid lock: %s: %s',
#                        $refaddr, Dumper($lock));
#
#                    next;
#                }
#
#                next if (!@{$lock->{locks}});
#
#                warn sprintf('[DEBUG] Trying to release orphaned locks: %s',
#                    Dumper($lock));
#
#                for (my $i = 0; $i < scalar(@{$lock->{locks}}); $i++)
#                {
#                    warn sprintf('[DEBUG] releasing orphaned lock: %s',
#                        Dumper($lock));
#
#                    if ($etcd->unlock(%{$lock->{locks}->[$i];}))
#                    {
#                        warn sprintf('[ERR] Failed to unlock: %s',
#                            Dumper($lock->{locks}->[$i]));
#
#                        next;
#                    }
#
#                    warn sprintf('[DEBUG] Orphaned lock has been release: %s',
#                        Dumper($lock));
#
#                    splice(@{$lock->{locks}}, $i ? $i-- : 0, 1);
#                }
#
#                if (!scalar(@{$lock->{locks}}))
#                {
#                    warn sprintf(
#                        '[DEBUG] All orphaned locks has been released: %s',
#                        $refaddr);
#
#                    delete($TABLE->{$refaddr});
#                }
#            }
#        }
#        catch
#        {
#            warn "[ERR] Unexpected error: @_";
#        };
#
#        $SEM->up();
#
#        Coro::AnyEvent::sleep(1);
#    }
#};

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has '_etcd' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { GMS::Cluster::Etcd->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub lock
{
    my $self = shift;
    my %args = @_;

    state $rule = {
        owner => {
            isa => 'NotEmptyStr',
        },
        scope => {
            isa => 'NotEmptyStr',
        },
        tag => {
            default => sub { "${\short()} $Coro::current->{desc}"; },
        },
    };

    my $args = $self->validate($rule, \%args);

    my $rv = $self->_etcd->lock(%{$args});

    goto RETURN if ($rv);

#    my $refaddr = refaddr($self);
#
#    $SEM->down();
#
#    $TABLE->{$refaddr}->{instance} = $self
#        if (!exists($TABLE->{$refaddr}));
#
#    $TABLE->{$refaddr}->{locks} = []
#        if (ref($TABLE->{$refaddr}) ne 'ARRAY');
#
#    weaken($TABLE->{$refaddr}->{instance});
#
#    push(@{$TABLE->{$refaddr}->{locks}}, $args);
#
#    $SEM->up();

RETURN:

#    warn "[DEBUG] Lock table: ${\Dumper($TABLE)}";

    return $rv;
}

sub unlock
{
    my $self = shift;
    my %args = @_;

    state $rule = {
        owner => {
            isa => 'NotEmptyStr',
        },
        scope => {
            isa => 'NotEmptyStr',
        },
    };

    my $args = $self->validate($rule, \%args);

    my $rv = $self->_etcd->unlock(%{$args});

    goto RETURN if ($rv);

#    $SEM->down();
#
#    foreach my $refaddr (keys(%{$TABLE}))
#    {
#        my $lock = $TABLE->{$refaddr};
#
#        for (my $i = 0; $i < scalar(@{$lock->{locks}}); $i++)
#        {
#            next if ($args->{owner} ne $lock->{locks}->[$i]->{owner});
#
#            splice(@{$lock->{locks}}, $i ? $i-- : 0, 1);
#        }
#
#        delete($TABLE->{$refaddr}) if (scalar(@{$lock->{locks}}) == 0);
#    }
#
#    $SEM->up();

RETURN:

#    warn "[DEBUG] Lock table: ${\Dumper($TABLE)}";

    return $rv;
}

1;

=encoding utf8

=head1 NAME

GMS::Role::Lockable - Lockable role

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

