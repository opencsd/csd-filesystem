#!/usr/bin/perl

use v5.14;

use strict;
use warnings;
use utf8;

INIT
{
    use Env;
    use Cwd qw/abs_path/;

    if (!$ENV{GMSROOT})
    {
        ($ENV{GMSROOT} = abs_path($0)) =~ s/\/t\/[^\/]*$//;
    }

    unshift(@INC,
        "$ENV{GMSROOT}/t/lib",
        "$ENV{GMSROOT}/libgms",
        "$ENV{GMSROOT}/lib");

    # UTF encoding trick for Data::Dumper
    use Data::Dumper;

    no warnings;
    *Data::Dumper::qquote  = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;

    use strict;
    use warnings;
    use utf8;
    use open qw/:encoding(utf8)/;
}

BEGIN
{
    use Env;

    $ENV{ETCD_PID} = undef;

    if (!$ENV{MOCK_ETCD})
    {
        system('killall etcd &>/dev/null');
        system('rm -rf /tmp/etcd_data');

        if (!-x '/tmp/etcd')
        {
            my $url
                = 'https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz';

            system(
                "wget $url -O - | tar -xpz --strip-components=1 -C /tmp -f - etcd-v3.3.13-linux-amd64/etcd"
            );

            if ($? >> 8)
            {
                die 'Failed to download etcd';
            }
        }

        $ENV{ETCD_PID} = fork();

        if ($ENV{ETCD_PID} == 0)
        {
            exec('/tmp/etcd --data-dir /tmp/etcd_data &>/tmp/etcd.log')
                || die "Failed to run etcd normally: $$: $!";
        }

        $SIG{INT} = sub
        {
            if ($ENV{ETCD_PID})
            {
                system('killall etcd &>/dev/null');
                waitpid($ENV{ETCD_PID}, 0);
            }

            exit 255;
        };

        sleep 5;
    }
}

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose::CLI;

-f './unit.log' && system('rm -f unit.log');

Test::Class::Moose::CLI->new_with_options->run;

END
{
    if (!$ENV{MOCK_ETCD} && $ENV{ETCD_PID})
    {
        system('killall etcd &>/dev/null');
        waitpid($ENV{ETCD_PID}, 0);
    }
}
