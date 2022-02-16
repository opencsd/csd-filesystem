#!/usr/bin/perl -I/user/gms/t/lib

use strict;
use warnings;

BEGIN
{
    use File::Basename qw/dirname/;
    use File::Spec;
    use File::Spec::Functions qw/rel2abs/;

    my $ROOTDIR = dirname(rel2abs(__FILE__));
    $ROOTDIR =~ s/gms\/.+$/gms/;

    unshift(@INC,
        "$ROOTDIR/perl5/lib/perl5",
        "$ROOTDIR/lib",
        "$ROOTDIR/libgms",
        "$ROOTDIR/t/lib");
}

use Env;
use Data::Dumper;
use Test::Most;
use Test::AnyStor::Base;
use GMS::Cluster::MDSAdapter;

$ENV{GMS_TEST_ADDR} = shift(@ARGV) if @ARGV;

# 검사 준비
printf("Preparing Function-test for %s...\n\n", $ENV{GMS_TEST_ADDR});

subtest 'Preparing' => sub
{
    ok(1, 'Ready');
};

printf("\nTest for account events will be performed...\n\n");

subtest 'Basic' => sub
{
    my @id       = ('admin', 'gluesys');
    my @password = ('admin', 'gluesys');
    my $failure;    #SIGN_IN, NOT_AUTH, WRONG_PSWD

    login_event($id[0], $password[0], $failure = 'SIGNED_IN');
    login_event($id[1], $password[0], $failure = 'NOT_LOGGED_IN');
    login_event($id[0], $password[1], $failure = 'PASSWD_NOT_MATCH');
};

done_testing();

#---------------------------------------------------------------------------
#   Functions
#---------------------------------------------------------------------------
sub login_event
{
    my $t = Test::AnyStor::Base->new(
        addr        => $ENV{GMS_TEST_ADDR},
        no_complete => 1
    );
    my $mds = GMS::Cluster::MDSAdapter->new();

    my $code     = '';
    my $id       = $_[0];
    my $password = $_[1];
    my $failure  = $_[2];

    $t->login(id => $id, password => $password, failure => $failure);
    my $login_time = int($t->hires_timestamp());
    sleep(5);

    my $result = $mds->execute_dbi(
        db      => 'girasole',
        table   => 'Events',
        rs_func => 'search',
        rs_cond => {
            time     => $login_time,
            category => 'DEFAULT',
            type     => 'COMMAND',
            code     => $failure
        },
        rs_attr => {
            order_by     => {-desc => 'time'},
            limit        => 1,
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        },
        func => 'first'
    );

    if ($result->{'message'} =~ /authorized/i)
    {
        ok(1, "Not Authorized Test");
    }
    elsif ($result->{'message'} =~ /password/i)
    {
        ok(1, "Password not matched Test");
    }
    elsif ($result->{'message'} =~ /signed in/i)
    {
        ok(1, "Sign in Test");
    }
    else
    {
        return 1;
    }

    return 0;
}
