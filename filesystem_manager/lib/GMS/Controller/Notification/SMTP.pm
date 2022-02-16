package GMS::Controller::Notification::SMTP;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use GMS::API::Return;
use Girasole::Constants qw/:LEVEL/;
use Girasole::Event;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub info
{
    my $self   = shift;
    my $params = $self->req->json;

    eval {
        require Girasole::Notifier::Configurator;
        Girasole::Notifier::Configurator->import();

        return 1;
    } or do
    {
        $self->throw_error(message => "Failed to load Girasole configurator");
    };

    # 여기에서는 notifier의 환경 설정 파일을 읽어오는 작업만 수행한다.
    my $cfgtor = Girasole::Notifier::Configurator->new(source => 'etcd');

    $cfgtor->load_config(key => 'Notifier');

    my $cfg  = $cfgtor->get_config(key => 'SMTP');
    my $from = $cfg->{from};
    my $to   = $cfg->{to};

    if ($from)
    {
        utf8::decode($from) if (!utf8::is_utf8($from));
        $from =~ s/"//g;
    }

    if ($to)
    {
        utf8::decode($to) if (!utf8::is_utf8($to));
        $to =~ s/"//g     if ($to);
    }

    api_status(
        level => 'INFO',
        code  => SMTP_INFO_OK,
    );

    my %rv = (
        Enabled  => ($cfg->{enabled} =~ m/(yes|true|1)/i ? 'true' : 'false'),
        Server   => $cfg->{server},
        Port     => $cfg->{port},
        Auth     => $cfg->{auth} =~ m/(NO|NONE)/i ? 'false' : 'true',
        Security => $cfg->{security},
        ID       => $cfg->{username},
        Sender   => $from,
        Receiver => $to,

        # :WARNING 04/25/2016 02:01:04 PM: tricky!
        Alert_Level => grs_numlevel($cfg->{alert_level}) - 2,
    );

RETURN:

    $self->render(json => \%rv);
}

sub config
{
    my $self   = shift;
    my $params = $self->req->json;

    eval {
        require Girasole::Notifier::Configurator;
        Girasole::Notifier::Configurator->import();

        return 1;
    } or do
    {
        $self->throw_error(message => 'Failed to load Girasole configurator');
    };

    # 여기에서는 notifier의 환경 설정 파일을 쓰는 작업만 수행한다.
    my $cfgtor = Girasole::Notifier::Configurator->new(source => 'etcd');

    $cfgtor->load_config(key => 'Notifier');

    my $config = $cfgtor->get_config(key => 'SMTP');

    foreach my $key (keys(%{$params}))
    {
        next if (!length($params->{$key}));

        given ($key)
        {
            when ('Enabled')
            {
                $config->{enabled} = $params->{$key};
            }
            when ('Server')
            {
                $config->{server} = $params->{$key};
            }
            when ('Port')
            {
                $config->{port} = $params->{$key};
            }
            when ('Security')
            {
                $config->{security} = $params->{$key};
            }
            when ('Auth')
            {
                $config->{auth}
                    = $params->{$key} eq 'true'
                    ? 'LOGIN PLAIN DIGEST-MD5 CRAM-MD5'
                    : 'NONE';
            }
            when ('ID')
            {
                $config->{username} = $params->{$key};
            }
            when ('Pass')
            {
                $config->{password} = $params->{$key};
            }
            when ('Sender')
            {
                if ($params->{$key} =~ m/^(?<name>.+) (?<email>\<.+\>)$/)
                {
                    $params->{$key} = "\"$+{name}\" $+{email}";
                }

                $config->{from} = $params->{$key};
            }
            when ('Receiver')
            {
                if ($params->{$key} =~ m/^(?<name>.+) (?<email>\<.+\>)$/)
                {
                    $params->{$key} = "\"$+{name}\" $+{email}";
                }

                $config->{to} = $params->{$key};
            }
            when ('Alert_Level')
            {
                $config->{alert_level} = grs_strlevel($params->{$key} + 2);
            }
        }
    }

    if ($cfgtor->save_config(key => 'Notifier'))
    {
        $self->throw_error(message => 'Failed to set SMTP setting');
    }

    api_status(
        level => 'INFO',
        code  => SMTP_CONFIG_OK,
    );

    $self->render(status => 204, json => undef);
}

sub test
{
    my $self   = shift;
    my $params = $self->req->json;

    my $server   = $params->{Server};
    my $port     = $params->{Port};
    my $security = $params->{Security};
    my $auth     = $params->{Auth};
    my $user     = $params->{ID};
    my $pass     = $self->rsa_decrypt(data => $params->{Pass});
    my $from     = $params->{Sender};
    my $to       = $params->{Receiver};

    if ($security =~ m/(NO|NONE)/i)
    {
        $security = 'NONE';
    }

    if ($auth =~ m/^(true|yes|1)$/i)
    {
        $auth = 1;
    }
    elsif ($auth =~ m/^(false|no|0)/i)
    {
        $auth = 0;
    }

    eval {
        require Girasole::Notifier;

        return 1;
    } or do
    {
        $self->throw_error(message => 'Failed to load Girasole configurator');
    };

    my $mailer = Girasole::Notifier->new();

    if (!defined($mailer))
    {
        $self->throw_error(message => 'Failed to get SMTP handler');
    }

    my $rv = $mailer->_send_mail(
        server   => $server,
        port     => $port,
        username => $user,
        password => $pass,
        security => $security,
        auth     => $auth,
        from     => $from,
        to       => $to,
        cc       => undef,
        format   => 'html',
        test     => 'true',
        debug    => 0,
    );

    if ($rv->{res} == -1)
    {
        $rv->{msg} =~ s/[\r\n]+/\\n/g;

        chomp($rv->{msg});

        $self->throw_error(message => "Failed to send e-mail: $rv->{msg}");
    }

    api_status(
        level => 'INFO',
        code  => SMTP_TEST_OK,
    );

    $self->render(status => 204, json => undef);
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Notification::SMTP - GMS API Controller for SMTP notification

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

