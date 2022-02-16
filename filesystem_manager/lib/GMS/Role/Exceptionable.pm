package GMS::Role::Exceptionable;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse::Role;
use namespace::clean -except => 'meta';

use Devel::StackTrace;
use GMS::API::Return qw/api_status get_gms_message/;
use GMS::Exception::UnknownException;
use Module::Load;
use Scalar::Util qw/blessed/;
use Sys::Hostname::FQDN qw/short/;
use Try::Tiny;

sub throw_exception
{
    my $self  = shift;
    my $class = sprintf('GMS::Exception::%s', shift);
    my %args  = @_;

    my $except = try
    {
        load($class);
        return $class->new(%args);
    }
    catch
    {
        warn @_;
        return GMS::Exception::UnknownException->new(class => $class);
    };

    if (blessed($except) && $except->can('throw_hook'))
    {
        $except->throw_hook(%args);
    }
    else
    {
        $self->api_status(
            scope    => $except->scope,
            level    => $except->level,
            category => $except->category,
            code     => $except->code,
            msgargs  => $except->msgargs,
        );
    }

    die $except;
}

# :TODO Wed Apr 14 02:03:49 PM KST 2021
# We should detach the GMS status handling from this code.
# ex) implement throw_status as other new method
sub throw_error
{
    my $self = shift;
    my %args = @_ % 2 ? (message => shift, @_) : @_;

    $self->api_status(
        scope    => $args{scope}    // short(),
        level    => $args{level}    // 'ERROR',
        category => $args{category} // 'GMS',
        code     => $args{code}     // 'UNEXPECTED_ERROR',
        msgargs  => $args{msgargs}  // [details => $args{message}],
    );

    $args{status} //= 500;

    if (!defined($args{message}) && defined($args{code}))
    {
        $args{message}
            = $self->get_gms_message($args{code}, undef, @{$args{msgargs}});
    }

    if (exists($args{trace}) && $args{trace} == 0)
    {
        die "$args{status}: $args{message}";
    }

    my $trace     = Devel::StackTrace->new();
    my $trace_str = '';

    while (my $frame = $trace->next_frame)
    {
        $trace_str .= "${\$frame->as_string}\n";
    }

    die sprintf("%s: %s\n%s",
        $args{status}  // 'undef',
        $args{message} // 'undef',
        $trace_str     // 'undef');
}

no Mouse::Role;
1;

=encoding utf8

=head1 NAME

GMS::Role::Exceptionable - Provides GMS exception handling with Mouse::Role

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut
