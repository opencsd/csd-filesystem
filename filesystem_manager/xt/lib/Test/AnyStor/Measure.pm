package Test::AnyStor::Measure;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Exporter;

our @EXPORT = qw/Asyncctl Asyncjob/;

# Async task manage with fork() & select()
package Asyncctl;

use strict;
use warnings;
use utf8;

use Mouse;
use namespace::clean -except => 'meta';

use JSON;
use Try::Tiny;
use IO::Pipe;
use IO::Select;
use POSIX qw/sys_wait_h signal_h/;
use Proc::Exists qw/pexists/;
use Time::HiRes qw/usleep/;

use Data::Dumper;

has 'trigger_term' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'pipe' => (
    is      => 'rw',
    isa     => 'Object|Undef',
    default => undef,
);

has 'child' => (
    is      => 'rw',
    isa     => 'Str|Undef',
    default => undef,
);

has 'result' => (
    is      => 'rw',
    isa     => 'ArrayRef|Undef',
    default => undef,
);

has 'read_set' => (
    is      => 'rw',
    isa     => 'Object',
    default => sub { IO::Select->new() },
);

has 'jobs' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub DESTROY
{
    my $self = shift;
    $self->clear();
}

sub done
{
    my $self = shift;

    $self->_read();

    return ref($self->result) eq 'ARRAY'
        ? @{$self->result}
        : undef;
}

sub clear
{
    my $self = shift;

    foreach my $job (@{$self->jobs})
    {
        $job->clear();
    }

    if ($self->child && pexists($self->child))
    {
        kill(SIGUSR1, $self->child);

        waitpid($self->child, 0);

        undef($self->{child});
    }

    $self->{jobs}     = [];
    $self->{read_set} = IO::Select->new();
    $self->{result}   = undef;

    if ($self->pipe && ref($self->pipe) eq 'IO::Pipe::End')
    {
        $self->pipe->close();
        undef($self->{pipe});
    }

    $self->{pipe} = IO::Pipe->new();
}

sub add
{
    my $self = shift;
    my $job  = shift;

    if (ref($job) ne 'Asyncjob')
    {
        return -1;
    }

    $job->{id} = @{$self->{jobs}} + 1;
    push @{$self->{jobs}}, $job;

    return 0;
}

sub run
{
    my $self = shift;

    local $SIG{USR1} = $self->_sigusr1();

    $self->{pipe} = IO::Pipe->new();

    my $pid = fork();

    if ($pid < 0)
    {
        return -1;
    }

    # child (select)
    if ($pid == 0)
    {
        $self->pipe->writer();

        my $done_job   = 0;
        my $nowait_job = 0;
        my $job_count  = 0;

        foreach my $job (@{$self->jobs})
        {
            $job_count++;

            my $res = $job->run();

            $self->read_set->add($job->pipe);

            $nowait_job++ if ($job->nowait);

            last if ($job_count == scalar(@{$self->jobs}));

            sleep $self->trigger_term if ($self->trigger_term);
        }

        while (1)
        {
            usleep(100);

            goto LOOP_OUT if (@{$self->jobs} <= $done_job + $nowait_job);

            my ($rh_set)
                = IO::Select->select($self->read_set, undef, undef, 0);

            foreach my $rh (@{$rh_set})
            {
                foreach my $job (@{$self->jobs})
                {
                    if ($job->pipe == $rh && $job->read())
                    {
                        $self->read_set->remove($rh);
                        $done_job++ if (!$job->nowait);
                        last;
                    }
                }
            }
        }

    LOOP_OUT:

        # send result to parent
        print {$self->{pipe}} to_json($self->_result());
        $self->clear();
        exit 0;
    }

    # parent
    local $SIG{USR1} = 'DEFAULT';

    $self->pipe->reader();
    $self->{child} = $pid;

    return 0;
}

sub _result
{
    my $self    = shift;
    my @results = ();

    for my $job (@{$self->jobs})
    {
        $job->clear();
        push(@results, $job->result);
    }

    $self->{result} = \@results if (@results);

    return {result => \@results};
}

sub _read
{
    my $self = shift;
    my $ret  = undef;

    if ($self->pipe && ref($self->pipe) eq 'IO::Pipe::End')
    {
        my $reader = $self->pipe;
        $ret = <$reader>;

        if ($ret)
        {
            $ret = decode_json($ret);
            $self->{$_} = $ret->{$_} foreach (keys(%{$ret}));
            $self->_result_to_job();
        }
    }

    return $ret;
}

sub _result_to_job
{
    my $self = shift;

    return if (!$self->result);

    foreach my $res (@{$self->result})
    {
        foreach my $job (@{$self->jobs})
        {
            if ($res->{id} eq $job->{id})
            {
                $job->{$_} = $res->{$_} foreach (keys(%{$res}));
                $job->{result} = $res;
            }
        }
    }

    return;
}

sub _sigusr1
{
    my $self = shift;

    return sub
    {
        if ($self->pipe && ref($self->pipe) eq 'IO::Pipe::End')
        {
            print {$self->{pipe}} to_json($self->_result());
        }

        $self->clear();

        exit 0;
    }
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

Asyncctl

=head1 SYNOPSIS

use Some::Obj;
use Data::Dumper;

use Test::AnyStor::Measure;

my $someobj = Some::Obj->new();

my $ctl  = Asyncctl->new(trigger_term => 2);
my $job1 = Asyncjob->new(func => \&sum, args => [ 1, 2 ], timeout => 1);
my $job2 = Asyncjob->new(obj => $someobj, func => \&Some::Obj::do, args => [ 1, 2 ], nowait => 1);

if ($ctl->add($job1))
{
    warn "Error job add failed\n";
    return -1;
}

if ($ctl->add($job2))
{
    warn "Error job add failed\n";
    return -1;
}

if ($ctl->run())
{
    warn "Error ctl run failed\n";
    return -1;
}

# wait all job done
while ($ctl->done())
{
    # do something ...
}

print Dumper $ctl->result;
print Dumper $job1;
print Dumper $job2;

$ctl->clear();

=head1 DESCRIPTION

작업 멀티플렉서

Asyncjob 객체로 전달 받은 작업들에 대한 수행 및 결과 값을 처리하는 클래스

 * 생성자 인자 값

   * trigger_term : add된 Asyncjob을 실행 간의 초단위 지연 시간 지정 
                    (default : 0)

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

# Job with fork()
package Asyncjob;

use strict;
use warnings;
use utf8;

use Mouse;
use namespace::clean -except => 'meta';

use JSON;
use IO::Pipe;
use Config qw/%Config/;
use Try::Tiny;
use B qw/svref_2object/;
use Time::HiRes qw/time/;
use POSIX qw/sys_wait_h signal_h/;
use Proc::Exists qw/pexists/;

use Data::Dumper;

has 'id' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'stdout_discard' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'stderr_discard' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'nowait' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'timeout' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'obj' => (
    is      => 'rw',
    isa     => 'Object|Undef',
    default => undef,
    trigger => sub
    {
        my $self = shift;
        my $argv = shift;

        $self->{objname} = ref($argv);
    }
);

has 'func' => (
    is      => 'rw',
    isa     => 'CodeRef',
    trigger => sub
    {
        my $self = shift;
        my $argv = shift;
        my $name = '';

        try
        {
            $name = svref_2object($argv)->GV->NAME;
        }
        catch
        {
            $name = 'unknown';
        };

        $self->{funcname} = $name;
    }
);

has 'args' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'result' => (
    is      => 'rw',
    isa     => 'HashRef|Undef',
    default => undef,
);

has 'error' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has 'objname' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'main',
);

has 'funcname' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'unknown',
);

has 'child' => (
    is      => 'rw',
    isa     => 'Str|Undef',
    default => undef,
);

has 'pipe' => (
    is      => 'rw',
    isa     => 'Object|Undef',
    default => undef,
);

has 'start' => (
    is      => 'rw',
    default => undef
);

has 'end' => (
    is      => 'rw',
    default => undef
);

has 'retval' => (
    is      => 'rw',
    default => undef
);

has 'retcode' => (
    is      => 'rw',
    default => undef
);

has 'signo' => (
    is      => 'rw',
    default => undef
);

has 'core' => (
    is      => 'rw',
    default => undef
);

has 'is_timeout' => (
    is      => 'rw',
    default => 0,
);

sub DESTROY
{
    my $self = shift;
    $self->clear();
}

sub run
{
    my $self = shift;

    $self->{pipe} = IO::Pipe->new();

    my $pid = fork();

    if ($pid < 0)
    {
        $self->{error} = "Failed to fork: ${\Dumper($self)}";

        return -1;
    }

    # child
    if ($pid == 0)
    {
        # set up sighandler for child
        local $SIG{USR1} = $self->_sigusr1();
        local $SIG{ALRM} = $self->_sigalrm() if ($self->timeout);

        $self->pipe->writer();

        # run given func
        if ($self->obj)
        {
            try
            {
                if (!$self->obj->can($self->{funcname}))
                {
                    die
                        "Cannot found method($self->{funcname}) from Object($self->{objname})";
                }
            }
            catch
            {
                chomp($_);
                $self->{error} = $_;
                $self->_sigusr1()->();
            };

            unshift(@{$self->args}, $self->obj);
        }

        # TODO: discard 옵션 정상 동작하는지 확인
        close(STDIN);
        close(STDOUT) if ($self->stdout_discard);
        close(STDERR) if ($self->stderr_discard);

        alarm($self->timeout) if ($self->timeout);

        $self->{start}  = time();
        $self->{retval} = $self->func->(@{$self->args});
        $self->{end}    = time();

        # send result to parent
        print {$self->{pipe}} to_json($self->_result());
        $self->clear();

        exit 0;
    }

    # parent
    # set up sighandler to default
    $self->pipe->reader();

    $self->{child} = $pid;

    return 0;
}

sub read
{
    my $self = shift;
    my $ret  = undef;

    if ($self->pipe && ref($self->pipe) eq 'IO::Pipe::End')
    {
        my $reader = $self->pipe;
        $ret = <$reader>;

        if ($ret)
        {
            $ret = decode_json($ret);

            $self->{$_} = $ret->{$_} foreach (keys(%{$ret}));
            $self->{result} = $ret;
        }
    }

    return $ret;
}

sub clear
{
    my $self = shift;
    my $ret  = undef;

    if ($self->child)
    {
        if ($self->nowait && pexists($self->child))
        {
            kill(SIGUSR1, $self->child);
        }

        waitpid($self->child, 0);

        my ($rc, $sig, $core) = ($? >> 8, $? & 127, $? & 128);

        $self->{result} = {} if (!$self->result);

        $self->{result}->{retcode} = $rc;
        $self->{result}->{signo}   = $sig;
        $self->{result}->{core}    = $core;

        my $tmp = $self->{result};

        foreach my $key (qw/error retval retcode signo core is_timeout/)
        {
            $self->{$key} = $tmp->{$key} if (exists($tmp->{$key}));
        }

        undef($self->{child});
    }

    if ($self->pipe && ref($self->pipe) eq 'IO::Pipe::End')
    {
        $self->pipe->close();

        undef($self->{pipe});
    }
}

sub _result
{
    my $self   = shift;
    my $result = {};

    $result->{$_} = $self->$_
        for (
        grep {
            !/^(objname|obj|funcname|func|args|nowait|timeout|pipe|child
                    |retcode|signo|core|result|std.+_discard)$/x
        } keys(%{$self})
        );

    return $result;
}

sub _sigusr1
{
    my $self = shift;

    return sub
    {
        if ($self->pipe && ref($self->pipe) eq 'IO::Pipe::End')
        {
            print {$self->{pipe}} to_json($self->_result());
        }

        # TODO: kill (-9) all of child procs.
        # Asyncjob으로 ssh $IP bonnie 실행 중, 해당 잡 clear() 이후
        # 실제 I/O 출력하는 bonnie 프로세스들은 살아 있음
        # Asyncjob 문제인지 OpenSSH의 문제인지,

        $self->clear();
        exit 0;
    }
}

sub _sigalrm
{
    my $self = shift;

    return sub
    {
        alarm(0);
        $self->{is_timeout} = 1;
    }
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

Asyncjob

=head1 SYNOPSIS

use Data::Dumper;

use Test::AnyStor::Measure;

my $job = Asyncjob->new(func => \&sum, args => [ 1, 2 ], timeout => 1);

if ($job->run())
{
    warn "$job->error\n";
    return -1;
}

while (!$job->read()) { sleep 1; }

# get child process return infos
$job->clear();

print Dumper $job->result;

if ($job->retval)
{
    # print result
    print "$job->objname::$job->funcname" . Dumper $job->args;
    print "job result: " . Dumper $job->retval;
    print "job start timestamp : $job->start\n";
    print "job end timestamp : $job->end\n";
    print "job reached timeout : $job->is_timeout\n";
}
else
{
    print "job error: $job->error\n";
    print "job proc return code : $job->retcode\n";
    print "job proc recieved signal : $job->signo\n";
    print "job proc core dumped  : $job->core\n";
}

=head1 DESCRIPTION

수행할 작업을 obj, func, args를 인자 값으로 받아서, 프로세스 포킹 이후
child에서 작업을 수행하고 pipe로 write 후 종료, parent는 pipe를 read
하여 Asyncjob 객체에 해당 작업 결과를 저장하는 클래스

 * 생성자 인자 값

   * timeout : 0 or N, child 프로세스의 작업 실행이 해당 timeout 초를 초과하였는지 검사
               (default : 0, 검사 안함)
   * nowait  : 0 or 1, clear 함수 호출 시 child 프로세스가 작업 중 일 경우, kill을 수행
               (default : 0, child 작업 완료 시 까지 대기)
   * func    : 필수 값, child가 수행할 작업 (func ref)
   * obj     : func이 객체의 메서드일 경우, 작업 수행을 위해 전달되어야 하는 객체
               (default : undef)
   * args    : func 수행 시 전달할 arguments, array 참조 값
   * stdout_discard : stdout 출력 금지 옵션 (default : 0, 출력)
   * stderr_discard : stderr 출력 금지 옵션 (default : 0, 출력)

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

