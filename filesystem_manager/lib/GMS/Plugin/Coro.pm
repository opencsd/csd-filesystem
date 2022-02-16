package GMS::Plugin::Coro;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Coro;
use Coro::Multicore;
use AnyEvent;

use GMS::Common::Logger;
use Mojo::IOLoop;
use POSIX qw(setlocale LC_ALL);

#---------------------------------------------------------------------------
#   Inheritacnes
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Static
#---------------------------------------------------------------------------
state $IDLE;

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
# Wrap application in coroutine and reschedule main coroutine in event loop
sub register
{
    my ($self, $app) = @_;

    my $subscribers = $app->plugins->subscribers('around_dispatch');

    unshift(
        @{$subscribers},
        sub
        {
            my ($next, $c) = @_;

            my $req_id = $c->req->request_id;
            my $locale = setlocale(LC_ALL);

            async
            {
                $Coro::current->{desc} = $req_id;

                # coroutine does not copy signal handlers for logging
                # __WARN__, __DIE__, ...
                catch_sig_warn(%{$app->log_settings});

                warn sprintf('[DEBUG] Coroutine is started: %s',
                    $Coro::current->{desc},
                );

                Coro::on_enter
                {
                    #warn "[DEBUG] on_enter: $req_id";
                    $c->app->set_prs($req_id);
                    setlocale(LC_ALL, $locale);
                };

                Coro::on_leave
                {
                    #warn "[DEBUG] on_leave: $req_id";
                    $locale = setlocale(LC_ALL);
                };

                my $rv = $next->();

                warn sprintf('[DEBUG] Coroutine is terminated: %s', $req_id);

                return $rv;
            }
            ->on_destroy(
                sub
                {
                    $c->app->unset_prs($req_id) if (defined($c->app));
                }
            );
        }
    );

    $app->plugins->unsubscribe('around_dispatch');
    $app->hook(around_dispatch => $_) for (@{$subscribers});

    my $etcd = eval { $app->etcd; };

    if (defined($etcd) && $etcd->can('watch'))
    {
        warn '[INFO] Watcher enabled';
        $etcd->watch(log_settings => $app->log_settings);
    }

    #$self->hook_idle_coroutine($app);
    Mojo::IOLoop->recurring(0 => sub { cede; });

    return;
}

sub hook_idle_coroutine
{
    my ($self, $app) = @_;

    $IDLE = Coro->new(
        sub
        {
            catch_sig_warn(%{$app->log_settings});

            my $_poll = AnyEvent->can("_poll")
                || AnyEvent->can("one_event");    # AnyEvent < 6.0

            my $prev = 0;

            while ()
            {
                $_poll->();
                Coro::schedule if (Coro::nready);
            }
        }
    );

    $IDLE->{desc} = 'idle';

    $Coro::idle = $IDLE;
}

__PACKAGE__->meta->make_immutable;

# Magical class for calling a method non-blocking without a callback and
# rescheduling the current coroutine until it is done
#package with::coro;
#
#use v5.14;
#
#use Coro;
#use Coro::Multicore;
#use AnyEvent;
#use Coro::AnyEvent;
#
#sub AUTOLOAD
#{
#    my ($method) = our $AUTOLOAD =~ /^with::coro::(.+)$/;
#    my ($done, $err, @args);
#
#    # For Mojo::Pg
#    if ($method =~ m/^query/)
#    {
#        shift->$method(@_ => sub { $done++; shift; $err = shift; @args = @_ }
#        );
#    }
#
#    # For Mojo::UserAgent
#    elsif ($method =~ m/^get|put|post|delete|head|options|patch$/)
#    {
#        shift->$method(@_ => sub { $done++; shift; @args = @_ });
#    }
#
#    cede until ($done);
#
#    die $err if ($err);
#
#    return wantarray ? @args : $args[0];
#}

1;

=encoding utf8

=head1 NAME

GMS::Plugin::Coro - Coro plugin for GMS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONTRIBUTORS

Ji-Hyeon Gim <potatogim@gluesys.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
