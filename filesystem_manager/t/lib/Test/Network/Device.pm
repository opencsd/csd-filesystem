package Test::Network::Device;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use File::Path qw/make_path remove_tree/;
use Sys::Hostname::FQDN qw/short/;

has 'namespace' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Mock::Controller',
);

has 'cntlr' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Network',
);

has 'uri' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub
    {
        {
            list   => '/api/network/device/list',
            info   => '/api/network/device/info',
            update => '/api/network/device/update',
        };
    },
);

has 'scope' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
);

has 'hostname' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { short(); },
);

has 'script_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/etc/sysconfig/network-scripts',
);

has 'sysfs_dir' => (
    is      => 'ro',
    isa     => 'Str',
    default => '/tmp/sys/class/net',
);

sub test_startup
{
    my $self = shift;

    $self->next::method(@_);

    my $t = $self->t;

    foreach my $k (keys(%{$self->uri}))
    {
        $t->app->routes->post($self->uri->{$k})->to(
            namespace  => $self->namespace,
            controller => $self->cntlr,
            action     => "device_$k",
        );
    }
}

sub test_setup
{
    my $self = shift;

    $self->next::method(@_);

    $self->mock_config_file(
        DEVICE => 'ens32',
        IPADDR => '192.168.0.10',
    );

    $self->mock_config_file(
        DEVICE  => 'ens34',
        IPADDR  => '10.10.0.10',
        NETMASK => '255.255.255.0',
    );

    map { $self->mock_config_file(DEVICE => "ens$_"); } (qw/192 193 194 195/);
}

sub test_teardown
{
    my $self = shift;

    $self->next::method(@_);

    $self->unmock_data();
    $self->mock_cleanup_config();
}

sub mock_config_file
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    my %data = (
        DEVICE    => 'ens32',
        TYPE      => 'Ethernet',
        BOOTPROTO => 'static',
        ONBOOT    => 'yes',
        IPADDR    => '192.168.0.10',
        NETMASK   => '255.255.252.0',
        GATEWAY   => '192.168.0.1',
    );

    map {
        if (!exists($args{$_}))
        {
            $args{$_} = $data{$_};
        }
    } keys(%data);

    my $dev = $args{DEVICE};

    map {
        my $dir = $_;

        if (-e $dir && !-d $dir)
        {
            die "path exists but not a directory: $dir";
        }

        if (!-d $dir && make_path($dir, {error => \my $err}) == 0)
        {
            my ($path, $msg) = %{$err->[0]};

            if ($path eq '')
            {
                die "Generic error: $msg";
            }
            else
            {
                die "Failed to make directory: $path: $msg";
            }
        }
    } (
        "${\$self->sysfs_dir}/$dev", "${\$self->sysfs_dir}/$dev/statistics",
        $self->script_dir,
    );

    my $file = sprintf('%s/ifcfg-%s', $self->script_dir, $dev);

    my $mock = '';

    map {
        $mock .= sprintf("%s=%s\n",
            uc($_), exists($args{$_}) ? $args{$_} : $data{$_});
    } keys(%data);

    open(my $fh, '>', $file)
        || die "Failed to open file: $file: $!";

    print $fh $mock;

    close($fh);

    $self->mock_write_sysfs(%args);
}

sub mock_write_nic_config
{
    my $self = shift;
    my $data = shift;

    my $dir = $self->script_dir;

    if (-e $dir && !-d $dir)
    {
        die "path exists but not a directory: $dir";
    }

    if (!-d $dir && make_path($dir, {error => \my $err}) == 0)
    {
        my ($path, $msg) = %{$err->[0]};

        if ($path eq '')
        {
            die "Generic error: $msg";
        }
        else
        {
            die "Failed to make directory: $path: $msg";
        }
    }

    my $file = sprintf('%s/ifcfg-%s', $dir, $data->{DEVICE});
    my $mock = '';

    map { $mock .= sprintf("%s=\"%s\"\n", uc($_), $data->{$_}); }
        keys(%{$data});

    open(my $fh, '>', $file)
        || die "Failed to open file: $file: $!";

    print $fh $mock;

    close($fh);

    $self->mock_write_sysfs(%{$data});
}

sub mock_write_sysfs
{
    my $self = shift;
    my %args = @_;

    my $dev = $args{DEVICE};
    my $dir = "${\$self->sysfs_dir}/$dev";

    foreach ($dir, "$dir/statistics", "$dir/bonding")
    {
        next if ($_ =~ m/bonding/ && $dev !~ m/^bond/);

        if (!-d $_ && make_path($_, {error => \my $err}) == 0)
        {
            my ($path, $msg) = %{$err->[0]};

            if ($path eq '')
            {
                die "Generic error: $msg";
            }
            else
            {
                die "Failed to make directory: $path: $msg";
            }
        }
    }

    my %sysfs = (
        "$dir/duplex"       => 'full',
        "$dir/speed"        => 1000,
        "$dir/mtu"          => 1500,
        "$dir/address"      => 'aa:bb:cc:dd:ee:ff',
        "$dir/tx_queue_len" => 1000,
        "$dir/operstate"    => 'up',
        "$dir/ifalias"      => '',
    );

    my @stats_keys = (
        qw/
            collisions
            multicast
            rx_bytes
            rx_compressed
            rx_crc_errors
            rx_dropped
            rx_errors
            rx_fifo_errors
            rx_frame_errors
            rx_length_errors
            rx_missed_errors
            rx_nohandler
            rx_over_errors
            rx_packets
            tx_aborted_errors
            tx_bytes
            tx_carrier_errors
            tx_compressed
            tx_dropped
            tx_errors
            tx_fifo_errors
            tx_heartbeat_errors
            tx_packets
            tx_window_errors
            /
    );

    map { $sysfs{"$dir/statistics/$_"} = int(rand(10)); } @stats_keys;

    if ($dev =~ m/^bond/)
    {
        my $mode    = ($args{BONDING_OPTS} =~ m/mode=([^\s]+)/)[0];
        my $primary = ($args{BONDING_OPTS} =~ m/primary=([^\s]+)/)[0];

        my %bonding = (
            mode             => $mode    // 0,
            primary          => $primary // '',
            primary_reselect => '',
            active_slave     => '',
            slaves           => '',
            xmit_hash_policy => '',
            fail_over_mac    => '',
            lacp_rate        => '',
            ad_select        => '',
        );

        map { $sysfs{"$dir/bonding/$_"} = $bonding{$_}; } keys(%bonding);
    }
    elsif ($args{MASTER} && $args{SLAVE} eq 'yes')
    {
        my $slaves = "${\$self->sysfs_dir}/$args{MASTER}/bonding/slaves";

        open(my $fh, -f $slaves ? '+<' : '>', $slaves)
            || die "Failed to open file: $slaves: $!";

        local $/;

        my $line = <$fh>;

        $line .= " $args{DEVICE}";
        $line =~ s/(^\s+|\s+$|\n)//g;

        seek($fh, 0, 0)
            || die "Failed to seek file: $slaves: $!";

        print $fh $line;

        truncate($fh, tell($fh))
            || die "Failed to truncate file: $slaves: $!";

        close($fh);
    }

    foreach my $key (keys(%sysfs))
    {
        open(my $fh, '>', $key)
            || die "Failed to open file: $sysfs{$key}: $_";

        printf $fh $sysfs{$key};

        close($fh);
    }
}

sub mock_cleanup_config
{
    my $self = shift;

    map {
        my $dir = $_;

        if (-d $dir && remove_tree($dir, {error => \my $err}) == 0)
        {
            my ($path, $msg) = %{$err->[0]};

            if ($path eq '')
            {
                die "Generic error: $msg";
            }
            else
            {
                die "Failed to remove: $path: $msg";
            }
        }
    } ($self->script_dir, $self->sysfs_dir);

    return;
}

sub test_device_list : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/device/list');

    diag($t->tx->res->json);

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network device list is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_DEV_LIST_OK')
        ->json_like('/entity/0/Device' => qr/^ens(?:32|34|192|193|194|195)$/)
        ->json_like('/entity/1/Device' => qr/^ens(?:32|34|192|193|194|195)$/)
        ->json_like('/entity/2/Device' => qr/^ens(?:32|34|192|193|194|195)$/)
        ->json_like('/entity/3/Device' => qr/^ens(?:32|34|192|193|194|195)$/)
        ->json_like('/entity/4/Device' => qr/^ens(?:32|34|192|193|194|195)$/)
        ->json_like('/entity/5/Device' => qr/^ens(?:32|34|192|193|194|195)$/);

    my $data = $self->mock_get_key(
        key     => "/${\$self->hostname}/Network/Device",
        options => {recursive => 'true'}
    );

    ok(exists($data->{ens32}),  'ens32 appeared in etcd database');
    ok(exists($data->{ens34}),  'ens34 appeared in etcd database');
    ok(exists($data->{ens192}), 'ens192 appeared in etcd database');
    ok(exists($data->{ens193}), 'ens193 appeared in etcd database');
    ok(exists($data->{ens194}), 'ens194 appeared in etcd database');
    ok(exists($data->{ens195}), 'ens195 appeared in etcd database');
}

sub test_device_info : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/device/info');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Device/);

    $t = $self->t->post_ok(
        '/api/network/device/info',
        json => {
            Device => 'unknown',
        }
    );

    $t->status_is(404)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Network device not found: unknown/)
        ->json_is('/statuses/0/code' => 'NOT_FOUND')
        ->json_like(
        '/statuses/0/message' => qr/Network device not found: unknown/);

    $t = $self->t->post_ok(
        '/api/network/device/info',
        json => {
            Device => 'ens32',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network device is retrieved/)
        ->json_is('/statuses/0/code' => 'NETWORK_DEV_INFO_OK');

#    explain($t->tx->res->json);
}

sub test_device_update : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/network/device/update');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM')
        ->json_like('/statuses/0/message' => qr/Missing parameter: Device/);

    $t = $self->t->post_ok(
        '/api/network/device/update',
        json => {
            Device  => 'ens32',
            IPAddr  => ['192.168.0.10',  '192.168.0.11'],
            Netmask => ['255.255.255.0', '255.255.252.0'],
            Gateway => ['192.168.0.1',   '192.168.3.254'],
            OnBoot  => 'no',
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network device is updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_DEV_UPDATE_OK');

#    explain($t->tx->res->json);

    my $data = $self->mock_get_key(
        key     => "/${\$self->hostname}/Network/Device/ens32",
        options => {recursive => 'true'}
    );

    explain($data);

    cmp_ok($data->{device},    'eq', 'ens32',    'device: ens32');
    cmp_ok($data->{BOOTPROTO}, 'eq', 'static',   'bootproto: static');
    cmp_ok($data->{ONBOOT},    'eq', 'no',       'onboot: no');
    cmp_ok($data->{TYPE},      'eq', 'Ethernet', 'type: Ethernet');
    cmp_ok($data->{IPADDR}->[0],
        'eq', '192.168.0.10', 'ipaddr[0]: 192.168.0.10');
    cmp_ok($data->{IPADDR}->[1],
        'eq', '192.168.0.11', 'ipaddr[1]: 192.168.0.11');
    cmp_ok($data->{NETMASK}->[0],
        'eq', '255.255.255.0', 'netmask[0]: 255.255.255.0');
    cmp_ok($data->{NETMASK}->[1],
        'eq', '255.255.252.0', 'netmask[1]: 255.255.252.0');
    cmp_ok($data->{GATEWAY}->[0],
        'eq', '192.168.0.1', 'gateway[0]: 192.168.0.1');
    cmp_ok($data->{GATEWAY}->[1],
        'eq', '192.168.3.254', 'gateway[1]: 192.168.3.254');
}

1;

=encoding utf8

=head1 NAME

Test::Network::Device - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

