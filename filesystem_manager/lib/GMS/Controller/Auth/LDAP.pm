package GMS::Controller::Auth::LDAP;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return qw/:AUTH api_status/;
use GMS::Auth::LDAP;
use GMS::System::Service qw/enable_service disable_service service_status
    control_service/;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'ldap' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Auth::LDAP->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $rv = $self->ldap->info();

    if (ref($rv) ne 'HASH')
    {
        $self->throw_error('Failed to get LDAP authentication info');
    }

    $self->stash(openapi => $rv);
}

sub enable
{
    my $self   = shift;
    my $params = $self->req->json;

    state $rule = {
        URI => {
            isa => 'NotEmptyStr',
        },
        BindDN => {
            isa => 'NotEmptyStr',
        },
        BindPw => {
            isa => 'NotEmptyStr',
        },
        BaseDN => {
            isa => 'NotEmptyStr',
        },
        PasswdDN => {
            isa => 'NotEmptyStr',
        },
        ShadowDN => {
            isa => 'NotEmptyStr',
        },
        GroupDN => {
            isa => 'NotEmptyStr',
        },
        SSL => {
            isa => 'NotEmptyStr',
        }
    };

    my $args = $self->validate($rule, $params);

    # 1. this method includes below actions
    # - update /etc/nslcd.conf
    # - update /etc/nsswitch.conf via authconfig
    # - update /etc/pam.d/{password-auth-ac,system-auth-ac} via authconfig
    # - update /etc/{smb.conf,afp.conf,proftpd.conf}
    my $rv = $self->ldap->enable(
        uri      => $args->{URI},
        binddn   => $args->{BindDN},
        bindpw   => $args->{BindPw},
        basedn   => $args->{BaseDN},
        passwddn => $args->{PasswdDN},
        shadowdn => $args->{ShadowDN},
        groupdn  => $args->{GroupDN},
        ssl      => $args->{SSL},
    );

    if ($rv)
    {
        $self->throw_error('Faield to enable LDAP authentication');
    }

    # 2. restart related services
    foreach my $svc (qw/nscd nslcd smb netatalk proftpd/)
    {
        if ($svc =~ m/^(nscd|nslcd)$/)
        {
            enable_service(service => $svc);

            my $oper = service_status(service => $svc) ? 'start' : 'restart';

            if (control_service(service => $svc, action => $oper))
            {
                $self->throw_error("Failed to $oper $svc");
            }
        }
        else
        {
            if (!service_status(service => $svc)
                && control_service(service => $svc, action => 'restart'))
            {
                $self->throw_error("Failed to restart $svc");
            }
        }
    }

    return $self->stash(
        openapi => 'OK',
        status  => 204,
    );
}

sub disable
{
    my $self   = shift;
    my $params = $self->req->json;

    # 1. this method includes below actions
    # - update /etc/nslcd.conf
    # - update /etc/nsswitch.conf via authconfig
    # - update /etc/pam.d/{password-auth-ac,system-auth-ac} via authconfig
    # - update /etc/{smb.conf,afp.conf,proftpd.conf}
    if ($self->ldap->disable())
    {
        $self->throw_error('Failed to disable LDAP authentication');
    }

    # 2. stop/restart related services
    foreach my $svc (qw/nscd nslcd smb netatalk proftpd/)
    {
        if ($svc =~ m/^(nscd|nslcd)$/
            && !service_status(service => $svc))
        {
            disable_service(service => $svc);

            if (control_service(service => $svc, action => 'stop'))
            {
                $self->throw_error("Failed to stop $svc");
            }
        }
        else
        {
            if (!service_status(service => $svc)
                && control_service(service => $svc, action => 'restart'))
            {
                $self->throw_error("Failed to restart $svc");
            }
        }
    }

    return $self->stash(
        openapi => 'OK',
        status  => 204,
    );
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

GMS::Controller::Auth::LDAP - 

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

