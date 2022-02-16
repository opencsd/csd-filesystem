package GMS::Plugin::Girasole;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Coro;
use Data::MessagePack;
use Fcntl qw();
use Guard;
use Girasole::Constants qw(:CATEGORY :LEVEL :MSG);
use GMS::API::Return;
use GMS::Common::Logger;
use Mojo::IOLoop;
use Sys::Hostname::FQDN qw(short);
use Try::Tiny;
use ZMQ::FFI qw(ZMQ_DEALER);

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Static Variables
#---------------------------------------------------------------------------
has 'interval' => (
    is      => 'rw',
    isa     => 'Int',
    default => 3,
);

has 'pidfile' => (
    is      => 'rw',
    isa     => 'Str',
    default => '/var/run/girasole/girasole-publisher.pid'
);

has 'publisher_pid' => (
    is  => 'rw',
    isa => 'Int | Undef',
);

has 'addr' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ipc:///var/run/girasole/publisher.ipc',
);

has 'packer' => (
    is      => 'ro',
    isa     => 'Data::MessagePack',
    default => sub { Data::MessagePack->new()->utf8->prefer_integer; },
);

has 'zcontext' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { ZMQ::FFI->new(); },
);

has 'zsock' => (
    is  => 'rw',
    isa => 'Object | Undef',
);

has 'zid' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { sprintf('%s-gms-%d', short(), $$); },
);

has 'queue' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { []; },
);

has 'logfile' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { '/var/log/gms/event.log'; },
);

#---------------------------------------------------------------------------
#   Functions
#---------------------------------------------------------------------------
sub register
{
    my ($self, $app, $conf) = @_;

    $self->interval($conf->{interval}) if (defined($conf->{interval}));

    Mojo::IOLoop->recurring(
        $self->interval => sub
        {
            async
            {
                $Coro::current->{desc} = 'event-worker';

                catch_sig_warn(%{$app->log_settings});

                (my $endpoint = $self->addr) =~ s/^ipc:\/\///g;

                if (!-S $endpoint)
                {
                    warn "[DEBUG] Endpoint does not exist: $endpoint";
                    return;
                }

                if (!defined($self->zsock))
                {
                    my $zsock = $self->zcontext->socket(ZMQ_DEALER);

                    $zsock->set_linger(100);
                    $zsock->set_identity($self->zid);
                    $zsock->connect($self->addr);

                    warn sprintf('[INFO] Connected to girasole-publisher: %s',
                        $self->addr,);

                    $self->zsock($zsock);
                }

                my $dbg_fh;

                scope_guard { close($dbg_fh) if (defined($dbg_fh)); };

                return if (scalar(@{$self->queue}) == 0);

                #my $debug = $app->etcd->get_key(key => '/ClusterMeta/debug/Event');
                my $debug = 1;

                if ($debug)
                {
                    # 1. 읽기/쓰기 모드로 파일 열기
                    if (
                        !open(
                            $dbg_fh, (-f $self->logfile ? '+<' : '>'),
                            $self->logfile
                        )
                        )
                    {
                        warn sprintf('[ERR] Failed to open file: %s: %s',
                            $self->logfile, $!,);

                        return;
                    }

                    # 2. 베타적 잠금
                    if (!flock($dbg_fh, Fcntl::LOCK_EX))
                    {
                        warn sprintf('[ERR] Failed to lock file: %s: %s',
                            $self->logfile, $!,);

                        return;
                    }

                    # 3. 기존 로그 파일의 끝에서부터 이벤트 메시지 정보를 기록
                    seek($dbg_fh, 0, Fcntl::SEEK_END);
                }

                warn "[DEBUG] Queue(before): ${\$app->dumper($self->queue)}";

                while (my $msg = shift(@{$self->queue}))
                {
                    warn "[DEBUG] Dequeue: ${\$app->dumper($msg)}";

                    $self->send_to_pub($msg->{msgid}, $msg->{data});

                    next if (!defined($dbg_fh));

                    if ($msg->{msgid} == MSG_NEW_EVENT)
                    {
                        printf($dbg_fh "%s|%s|%s\n",
                            $msg->{data}->{time},
                            $msg->{data}->{scope},
                            $msg->{data}->{code},
                        );
                    }
                }

                warn "[DEBUG] Queue(after): ${\$app->dumper($self->queue)}";
            };
        }
    );

    $app->helper(
        gms_new_event => sub
        {
            my $c     = shift;
            my %args  = @_;
            my $event = undef;

            try
            {
                if ($self->check_publisher())
                {
                    warn '[WARN] girasole-publisher is not running';
                }

                $event = get_api_status($args{locale});

                if (ref($event) ne 'HASH')
                {
                    warn '[ERR] Invalid API status';
                    return -1;
                }

                $event->{level} = grs_numlevel($event->{level});

                if (!defined($event))
                {
                    warn "[ERR] gms_new_event: Unknown event";
                    return -1;
                }

                delete($event->{msgargs});

                warn "[DEBUG] Event: ${\$app->dumper($event)}";

                push(
                    @{$self->queue},
                    {msgid => MSG_NEW_EVENT, data => $event}
                );

                return 0;
            }
            catch
            {
                warn "[ERR] Failed to publish new event: @_";
                return -1;
            };
        }
    );

    $app->helper(
        run_checkers => sub
        {
            my $c      = shift;
            my $target = shift;

            try
            {
                if ($self->check_publisher())
                {
                    warn '[WARN] girasole-publisher is not running';
                }

                my $new_item = {msgid => MSG_RUN_CHECKERS, data => 0};

                $new_item->{data} = $target if (defined($target));

                push(@{$self->queue}, $new_item);

                return 0;
            }
            catch
            {
                warn "[ERR] Failed to trigger RUN_CHECKERS command: @_";
                return -1;
            }
        }
    );

    warn "[INFO] ${\__PACKAGE__} plugin is registered";

    return;
}

sub check_publisher
{
    my $self = shift;

    if (!defined($self->publisher_pid) && -f $self->pidfile)
    {
        my $pid = undef;

        if (open(my $pidfile, '<', $self->pidfile))
        {
            $pid = <$pidfile>;
            close($pidfile);
        }

        if (!defined($pid) || $pid !~ m/^\d+$/)
        {
            warn '[ERR] Could not find the PID of girasole-publisher';
            return -1;
        }

        $self->publisher_pid($pid);
    }

    return -1 if (!defined($self->publisher_pid));

    if (!kill(0, $self->publisher_pid))
    {
        warn '[WARN] girasole-publisher is not running';
        $self->publisher_pid(undef);
        return -1;
    }

    return 0;
}

sub send_to_pub
{
    my ($self, $msgid, $data) = @_;

    my $packed = try
    {
        return $self->packer->pack([$msgid, $data]);
    }
    catch
    {
        warn "[ERR] Unexpected error: @_";
        return;
    };

    if (!defined($packed))
    {
        warn sprintf('[ERR] Failed to send new event: %s',
            $self->app->dumper($packed));

        return -1;
    }

    return try
    {
        warn '[DEBUG] Sending message to girasole-publisher';
        $self->zsock->send_multipart(['', $packed]);
        warn '[DEBUG] New event request is sent';
        return 0;
    }
    catch
    {
        warn "[ERR] Failed to send new event: @_";
        return -1;
    };
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Plugin::Girasole - Girasole plugin for GMS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONTRIBUTORS

Ji-Hyeon Gim <potatogim@gluesys.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
