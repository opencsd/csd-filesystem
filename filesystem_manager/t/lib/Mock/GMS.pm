package Mock::GMS;

use v5.14;

use strict;
use warnings;
use utf8;

our $ETCD_MOCK;
our $ETCD_DATA;
our $ETCD_HANDLE;
our $ETCD;

BEGIN
{
    use Test::MockModule;
    use Module::Load;
    use Env;

    my $etcd = 'GMS::Cluster::Etcd';

    if (!$ENV{MOCK_ETCD})
    {
        try
        {
            load($etcd);

            $ETCD_HANDLE = $etcd->new(host => '127.0.0.1');

            $ETCD_HANDLE->watch() if (eval { $ETCD_HANDLE->can('watch') });
        }
        catch
        {
            warn "Failed to load $etcd: @_";
            warn 'Test will be performed with fallback';

            $ENV{MOCK_ETCD} = 1;
        };
    }

    if ($ENV{MOCK_ETCD})
    {
        $ETCD_MOCK = Test::MockModule->new($etcd);

        $ETCD_MOCK->mock('key_exists' => \&mock_key_exists);
        $ETCD_MOCK->mock('set_key'    => \&mock_set_key);
        $ETCD_MOCK->mock('get_key'    => \&mock_get_key);
        $ETCD_MOCK->mock('del_key'    => \&mock_del_key);
        $ETCD_MOCK->mock('ls'         => \&mock_ls);
        $ETCD_MOCK->mock('watch'      => \&mock_watch);
        $ETCD_MOCK->mock('lock'       => \&mock_lock);
        $ETCD_MOCK->mock('unlock'     => \&mock_unlock);
    }
}

our $AUTHORITY = 'cpan:gluesys';

use Mojo::Base qw/Mojolicious/;

use GMS;

use File::Basename qw/dirname/;
use File::Spec::Functions qw/rel2abs/;
use Module::Load;
use Module::Loaded;
use POSIX qw/strftime/;
use Test::Most;
use Try::Tiny;

use GMS::API::Return;
use GMS::Common::Logger;
use Data::Dumper;

use Exporter 'import';

our @EXPORT = (
    qw/&mock_key_exists &mock_set_key &mock_get_key &mock_del_key &mock_ls
        &mock_watch &mock_data &unmock_data/
);

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'rootdir' => sub
{
    (my $ROOTDIR = dirname(rel2abs(__FILE__))) =~ s/\/(gms|GMS)\/.+$/\/$1/;

    return $ROOTDIR;
};

#---------------------------------------------------------------------------
#   Constructor
#---------------------------------------------------------------------------
sub new
{
    my $self = shift->SUPER::new(@_);

    $self->controller_class('GMS::Controller');

    $self->setup_static();
    $self->setup_logger();

    GMS::setup_helpers($self);
    GMS::setup_hooks($self);

    $self->helper(gms_lock   => sub { });
    $self->helper(gms_unlock => sub { });

    $self->helper(
        gms_new_event => sub
        {
            my $c    = shift;
            my %args = @_;

            my $event = get_api_status($args{locale});

            note("Event: ${\$c->dumper($event)}");
        }
    );

    $self->helper(
        etcd => sub
        {
            load('GMS::Cluster::Etcd')
                if (!is_loaded('GMS::Cluster::Etcd'));

            return GMS::Cluster::Etcd->new();
        }
    );

    push(@{$self->routes->namespaces}, 'GMS::Controller');

    # Coro
    $self->plugin('GMS::Plugin::Coro');

    # PRS
    $self->plugin('GMS::Plugin::PRS');

    # OpenAPI
    $self->plugin(
        'GMS::Plugin::OpenAPI',
        {
            spec_dir => "$ENV{GMSROOT}/public/api"
        }
    );

    # Config
    #$self->plugin('Config', {file => "${\$self->rootdir}/config/gms.conf"});

    # OpenAPI
    my $spec = $self->write_spec();

    $self->plugin(
        'OpenAPI',
        {
            spec                   => $spec,
            schema                 => 'v3',
            add_preflighted_routes => 1
        }
    );

    $self->inactivity_timeout(600);

    return $self;
}

sub setup_logger
{
    my $self = shift;

    catch_sig_warn(%{$self->log_settings});

    my $ts = strftime('%Y%m%d-%H%M%S', localtime());

    $self->log->path("unit.log");

    if ($ENV{TEST_VERBOSE})
    {
        logmask(LOG_DEBUG);
        $self->log->level('debug');
    }
    else
    {
        logmask(LOG_INFO);
        $self->log->level('info');
    }
}

sub setup_static
{
    my $self = shift;

    (my $static = $self->static->paths->[0]) =~ s/\/t\//\//g;

    $self->static->paths([$static]);
}

sub log_settings
{
    my $self = shift;

    return {
        mojo     => $self,
        level    => 0,
        depth    => 1,
        category => 0,
        stdout   => undef,
        stderr   => undef,
    };
}

#---------------------------------------------------------------------------
#   Mock Methods
#---------------------------------------------------------------------------
sub mock_key_exists
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    my $retval;

    if ($ENV{MOCK_ETCD})
    {
        if (defined($args{db}))
        {
            $args{key} = "/$args{db}/$args{key}";
        }

        $args{key} =~ s/\/+/\//g;
        $args{key} =~ s/\/+$//g;

        $retval = exists($ETCD_DATA->{$args{key}});
    }
    else
    {
        $retval = $ETCD_HANDLE->key_exists(@_);
    }

    return $retval;
}

sub mock_set_key
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

#    note("mock_set_key(ARGS): ${\Dumper(\%args)}");
    warn "[DEBUG] mock_set_key(ARGS): ${\Dumper(\%args)}";

    my $retval = -1;

    if ($ENV{MOCK_ETCD})
    {
        if (defined($args{db}))
        {
            $args{key} = "/$args{db}/$args{key}";
        }

        $args{key} =~ s/\/+/\//g;
        $args{key} =~ s/\/+$//g;

        #warn "[DEBUG] KEY: $args{key}";

        $ETCD_DATA->{$args{key}} = $args{value};

        $retval = 0;
    }
    else
    {
        $retval = $ETCD_HANDLE->set_key(@_);
    }

#    note("mock_set_key: ${\Dumper(\%args)}: $retval");
    warn "[DEBUG] mock_set_key(ETCD_DATA): ${\Dumper($ETCD_DATA)}";

    return $retval;
}

sub mock_get_key
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

#    note("mock_get_key(ARGS): ${\Dumper(\%args)}: ${\Dumper($ETCD_DATA)}");

    my $value;

    if ($ENV{MOCK_ETCD})
    {
        $value = $ETCD_DATA->{$args{key}};

        if (!defined($value) && ref($args{options}) eq 'HASH')
        {
            if (lc($args{options}->{recursive}) =~ m/^(1|true|yes)/i)
            {
                $value = mock_get_key_recur(key => $args{key});
            }
        }
    }
    else
    {
        $value = $ETCD_HANDLE->get_key(@_);
    }

#    note("mock_get_key: $args{key}: ${\Dumper($value)}");
#    warn "[DEBUG] mock_get_key(ETCD_DATA): ${\Dumper($ETCD_DATA)}";

    return $value;
}

sub mock_get_key_recur
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    my $value = undef;

#    note("mock_get_key_recur(ARGS): $args{key}");

    my @keys = grep { $_ =~ m/^$args{key}\//; } keys(%{$ETCD_DATA});

    foreach my $key (@keys)
    {
        $key =~ s/^$args{key}\///;

        my @path = split(/\//, $key);
        my $tmp  = \$value;

        foreach my $subkey (@path)
        {
            if ($subkey =~ m/^\d+$/)
            {
                $tmp = \$$tmp->[$subkey];
            }
            else
            {
                $tmp = \$$tmp->{$subkey};
            }
        }

        $$tmp = $ETCD_DATA->{"$args{key}/$key"};
    }

#    warn "[DEBUG] mock_get_key_recur(ETCD_DATA): ${\Dumper($ETCD_DATA)}";

    return $value;
}

sub mock_del_key
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

#    note("mock_del_key(ARGS): ${\Dumper(\%args)}");

    if ($ENV{MOCK_ETCD})
    {
        if (ref($args{options}) eq 'HASH'
            && lc($args{options}->{recursive}) eq 'true')
        {
            foreach my $key (keys(%{$ETCD_DATA}))
            {
                delete($ETCD_DATA->{$key}) if ($key =~ m/^$args{key}\//);
            }
        }
        elsif (!exists($ETCD_DATA->{$args{key}}))
        {
            return -1;
        }

        delete($ETCD_DATA->{$args{key}});
    }
    else
    {
        return $ETCD_HANDLE->del_key(@_);
    }

#    warn "[DEBUG] mock_del_key(ETCD_DATA): ${\Dumper($ETCD_DATA)}";

    return 0;
}

sub mock_ls
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

#    note("mock_ls(ARGS): ${\Dumper(\%args)}");
#    warn "[DEBUG] mock_ls(ARGS): ${\Dumper(\%args)}";

    if ($ENV{MOCK_ETCD})
    {
        my %dirs = ();

        foreach (keys(%{$ETCD_DATA}))
        {
            next if ($_ !~ m/^$args{key}\//);

            $_ =~ m/^$args{key}\/(?<dir>[^\/]+)/;

            $dirs{$+{dir}} = 1;
        }

        return wantarray ? keys(%dirs) : [keys(%dirs)];
    }
    else
    {
        return $ETCD_HANDLE->ls(@_);
    }
}

sub mock_watch
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    # :TODO 04/23/2019 12:44:26 AM: by P.G.
    # Not implemented yet.
    if ($ENV{MOCK_ETCD})
    {

    }
    else
    {
        $ETCD_HANDLE->watch(@_) if (eval { $ETCD_HANDLE->can('watch'); });
    }

    return;
}

sub mock_lock
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

#    note("mock_lock(ARGS): ${\Dumper(\%args)}");

    # :TODO 04/23/2019 12:44:26 AM: by P.G.
    # Not implemented yet.
    if ($ENV{MOCK_ETCD})
    {

    }
    else
    {

    }

    return;
}

sub mock_unlock
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

#    note("mock_unlock(ARGS): ${\Dumper(\%args)}");

    # :TODO 04/23/2019 12:44:26 AM: by P.G.
    # Not implemented yet.
    if ($ENV{MOCK_ETCD})
    {

    }
    else
    {

    }

    return;
}

sub mock_data
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    if (!keys(%args))
    {
        if ($ENV{MOCK_ETCD})
        {
            return $ETCD_DATA;
        }
        else
        {
            return mock_get_key(key => '/', options => {recursive => 'true'});
        }
    }

    foreach my $key (keys(%{$args{data}}))
    {
        (my $purified = $key) =~ s/\/+/\//g;

        if ($ENV{MOCK_ETCD})
        {
            $ETCD_DATA->{$purified} = $args{data}->{$key};
        }
        else
        {
            mock_set_key(key => $purified, value => $args{data}->{$key});
        }
    }

    return;
}

sub unmock_data
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    if ($ENV{MOCK_ETCD})
    {
        $ETCD_DATA = {};
    }
    else
    {
        foreach my $key ($ETCD_HANDLE->ls(key => '/'))
        {
            mock_del_key(key => "/$key", options => {recursive => 'true'});
        }
    }
}

1;

=encoding utf8

=head1 NAME

Mock::GMS - Mockup application for GMS unit-testing

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

