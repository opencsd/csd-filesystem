#!/usr/bin/env perl

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use open qw/:encoding(utf8)/;

our $GMSROOT;

BEGIN
{
    use Cwd qw/abs_path/;

    ($GMSROOT = abs_path($0)) =~ s/\/xt\/[^\/]*$//;

    unshift(@INC,
        "$GMSROOT/xt/lib",
        "$GMSROOT/libgms",
        "$GMSROOT/lib",
        "/usr/girasole/lib");
}

use Data::Dumper;
use Env;
use File::Find;
use List::MoreUtils qw/uniq/;
use POSIX qw/strftime/;
use TAP::Parser;
use TAP::Parser::Aggregator qw/all/;
use Test::AnyStor::Base;
use Test::Most;

# UTF encoding trick for Data::Dumper
no warnings 'redefine';
*Data::Dumper::qquote   = sub { qq["${\(shift)}"] };
$Data::Dumper::Useperl  = 1;
$Data::Dumper::Sortkeys = 1;
use warnings 'redefine';

#---------------------------------------------------------------------------
#   Main
#---------------------------------------------------------------------------
select(STDERR);
$| = 1;
select(STDOUT);
$| = 1;

my $sub_module = "";

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

if (!defined($ENV{FUNC_SUB_MOD}) || $ENV{FUNC_SUB_MOD} eq '/')
{
    $sub_module = "";
}
else
{
    $sub_module = $ENV{FUNC_SUB_MOD};
}

my $ignored_tests = undef;

if (defined($ENV{IGNORED_TESTS}))
{
    $ignored_tests = [uniq(split(',', $ENV{IGNORED_TESTS}))];
}

# 검사 준비
paint_info();

diag(
    sprintf(
        "\nPreparing Function-test(%s) for %s bail_on_fail mode %s...",
        ($sub_module eq '') ? 'all' : $sub_module,
        $ENV{GMS_TEST_ADDR},
        defined($ENV{BAIL_ON_FAIL}) ? 'set' : 'unset'
    )
);

if (defined($ignored_tests))
{
    diag(sprintf("\nIngnored tests like below " . Dumper $ignored_tests));
}

paint_reset();

#subtest 'Preparing Bail out MODE' => sub {
#    set_failure_handler(
#        sub {
#            my $builder = shift;
#
#            if (defined($ENV{BAIL_ON_FAIL}))
#            {
#                BAIL_OUT("function_test.t is bailed out");
#                done_testing();
#            }
#
#            if (!defined($ENV{GOGO_ON_FAIL}))
#            {
#                BAIL_OUT("function_test.t is bailed out");
#                done_testing();
#            }
#
#            paint_err();
#            daig("Failure detected but GOGOGO");
#            paint_reset();
#        }
#    );
#
#    ok(1, 'Ready');
#};

# t/function 아래의 모든 검사 스크립트 수행
my $aggregate     = TAP::Parser::Aggregator->new;
my $start_at      = time;
my $failure       = 0;
my @err_test_list = ();

require GMS::Cluster::MDSAdapter;

#my $mds_adapter  = GMS::Cluster::MDSAdapter->new();
#my $configurator = $mds_adapter->{conf};

my $target_ip = $ENV{GMS_TEST_ADDR};
$target_ip =~ s/:\d+$//;

my $configurator = GMS::Cluster::MDSAdapter->new(target => $target_ip);

diag("/debug/Cluster on\n");

$configurator->set_key('ClusterMeta', '/debug/Cluster', 1, 'cluster');

if ($sub_module ne '')
{
    my $debug_key = ucfirst($sub_module);

    diag("/debug/$debug_key on\n");

    $configurator->set_key('ClusterMeta', "/debug/$debug_key", 1, 'cluster');
}

if ($sub_module eq 'guitar')
{
    paint_info();
    ok(1, "Build Done for GUITAR Test");
    paint_reset();
}
else
{
    find(
        {
            wanted   => \&wanted,
            no_chdir => 0
        },
        "$GMSROOT/xt/function/$sub_module"
    );
}

diag("/debug/Cluster off\n");

$configurator->set_key('ClusterMeta', '/debug/Cluster', 0, 'cluster');

if ($sub_module ne '')
{
    my $debug_key = ucfirst($sub_module);

    diag("/debug/$debug_key off\n");

    $configurator->set_key('ClusterMeta', "/debug/$debug_key", 0, 'cluster');
}

# 검사 리포트 생성
#paint_info();
#diag(sprintf("\nGenerating test report for this test...\n\n"));
#paint_reset();

#subtest 'Report Generating' => sub {
#    my $srcip = $ENV{GMS_TEST_ADDR};
#    ok(1);
#};

if ($failure > 0)
{
    p_e_printf("Total Failed Scirpt %d\n", $failure);

    foreach my $err_t (@err_test_list)
    {
        p_e_printf("   - %s\n", $err_t);
    }
}

# 검사 종료
done_testing();

#---------------------------------------------------------------------------
#   Functions
#---------------------------------------------------------------------------
sub wanted
{
    my $file = $File::Find::name;
    my $pwd  = $File::Find::dir;
    my $t    = $_;

    return unless (-f $file && $file =~ m/\.t$/);

    if (defined($ignored_tests)
        && ref($ignored_tests) eq 'ARRAY'
        && scalar(grep { $file =~ /$_/; } @{$ignored_tests}))
    {
        return;
    }

    paint_info();
    diag("\n\n<<< Sub-test Category '$t' >>>\n");
    paint_reset();

    my $local_fail = 0;

    my $parser = TAP::Parser->new(
        {
            source => $file,
            merge  => 1,
        }
    );

    while (my $result = $parser->next)
    {
        diag(sprintf("%s\n", $result->as_string));
    }

    if (scalar($parser->failed) > 0 || $parser->exit != 0)
    {
        paint_err();
        push(@err_test_list, $t);
        $failure++;
        $local_fail = 1;
        fail('failed');
    }
    else
    {
        paint_info();
        pass('success');
    }

    diag("\nTest Summary\n\n");
    diag(
        sprintf(
            "- Test: %s\n- Exit Code: %d\n- Passed: %s\n- Failed: %s\n- Start: %s\n- End: %s\n",
            $t,
            $parser->exit,
            scalar($parser->passed),
            scalar($parser->failed),
            strftime('%Y-%m-%d %T', localtime($parser->start_time)),
            strftime('%Y-%m-%d %T', localtime($parser->end_time)),
        )
    );

    paint_reset();

    $aggregate->add($file, $parser);

    if ($local_fail > 0)
    {
        if (defined($ENV{BAIL_ON_FAIL}))
        {
            paint_err();
            BAIL_OUT("Function test is bailed out");
            paint_reset();
            done_testing();
        }

        if (!defined($ENV{GOGO_ON_FAIL}))
        {
            paint_err();
            BAIL_OUT("Function test is bailed out");
            paint_reset();
            done_testing();
        }

        paint_err();
        diag("Failure detected but GOGOGO");
        paint_reset();
    }

    return;
}
