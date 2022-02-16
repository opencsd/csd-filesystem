package Test::Network::Address;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Test::Class::Moose extends => 'Test::GMS';

use JSON qw/to_json/;

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
        {update => '/api/cluster/network/address/update',};
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
            action     => "address_$k",
        );
    }
}

sub test_setup
{
    my $self = shift;

    $self->next::method(@_);

    $self->mock_config_file(
        DEVICE  => 'ens32',
        IPADDR  => '192.168.0.10',
        NETMASK => '255.255.252.0',
    );

    $self->mock_config_file(
        DEVICE  => 'ens34',
        IPADDR  => '10.10.0.10',
        NETMASK => '255.255.255.0',
    );

    map { $self->mock_config_file(DEVICE => "ens$_"); } (qw/192 193 194 195/);

    $self->mock_etcd_clusterinfo();
    $self->mock_etcd_hosts();
}

sub test_teardown
{
    my $self = shift;

    $self->next::method(@_);

    $self->unmock_data();
    $self->mock_cleanup_config();
}

sub mock_etcd_clusterinfo
{
    my $self = shift;

    my $cinfo = {
        cluster => {
            cluster_name => $self->hostname,
            active       => 4,
            total        => 4,
        },
        config => {
            mds        => [map { "${\$self->hostname}-$_"; } (1 .. 3)],
            cluster_fs => ["gluster"],
            native_fs  => "xfs",
        },
        node_infos => {
            "${\$self->hostname}-1" => {
                activated => 1,
                mgmt_ip   => {
                    interface => "ens32",
                    ip        => "192.168.0.10",
                    netmask   => "255.255.252.0",
                },
                service_ip => ["192.168.3.16"],
                storage_ip => {
                    interface => "bond0",
                    ip        => "10.10.1.10",
                    netmask   => "255.255.255.0",
                },
            },
            "${\$self->hostname}-2" => {
                activated => 1,
                mgmt_ip   => {
                    interface => "ens32",
                    ip        => "192.168.0.11",
                    netmask   => "255.255.252.0",
                },
                service_ip => ["192.168.3.15"],
                storage_ip => {
                    interface => "bond0",
                    ip        => "10.10.1.11",
                    netmask   => "255.255.255.0",
                },
            },
            "${\$self->hostname}-3" => {
                activated => 1,
                mgmt_ip   => {
                    interface => "ens32",
                    ip        => "192.168.0.12",
                    netmask   => "255.255.252.0",
                },
                service_ip => [],
                storage_ip => {
                    interface => "bond0",
                    ip        => "10.10.1.12",
                    netmask   => "255.255.255.0",
                },
            },
            "${\$self->hostname}-4" => {
                activated => 1,
                mgmt_ip   => {
                    interface => "ens32",
                    ip        => "192.168.0.13",
                    netmask   => "255.255.252.0",
                },
                service_ip => [],
                storage_ip => {
                    interface => "bond0",
                    ip        => "10.10.1.13",
                    netmask   => "255.255.255.0",
                },
            },
        },
    };

    $self->mock_data(
        data => {
            '/ClusterInfo' => to_json($cinfo, {utf8 => 1}),
        }
    );
}

sub mock_etcd_hosts
{
    my $self = shift;

    $self->mock_data(
        data => {
            '/Cluster/Network/Hosts/192.168.0.10/0' =>
                "${\$self->hostname}-1",
            '/Cluster/Network/Hosts/192.168.0.11/0' =>
                "${\$self->hostname}-2",
            '/Cluster/Network/Hosts/192.168.0.12/0' =>
                "${\$self->hostname}-3",
            '/Cluster/Network/Hosts/192.168.0.13/0' =>
                "${\$self->hostname}-4",
        }
    );
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

# 매개변수를 입력하지 않을 경우 -> 실패
sub test_address_update_no_params : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok('/api/cluster/network/address/update');

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Missing parameter/)
        ->json_is('/statuses/0/code' => 'MISSING_PARAM');
}

# 특정 파라미터 개수를 3개 이상 입력할 경우 -> 실패
sub test_address_update_over_num_of_params
{
    my $self = shift;

    # Gateway 파라미터 개수를 3개 이상 입력할 경우 -> 실패
#    my $t = $self->t->post_ok(
#        '/api/cluster/network/address/update',
#        json => {
#            Device  => 'ens32',
#            IPAddr  => ['192.168.0.10', '192.168.0.15'],
#            Netmask => ['255.255.252.0', '255.255.252.0'],
#            Gateway => [undef, undef, '192.168.0.1'],
#        }
#    );
#
#    $t->status_is(422)
#        ->json_is('/success'         => 0)
#        ->json_is('/statuses/0/code' => 'INVALID_VALUE');

    # Netmask 파라미터 개수를 3개 이상 입력할 경우 -> 실패
    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => 'ens32',
            IPAddr  => ['192.168.0.10',  '192.168.0.15'],
            Netmask => ['255.255.252.0', '255.255.252.0', '255.255.255.0'],
            Gateway => [undef,           undef],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');

    # IPAddr 파라미터 개수를 3개 이상 입력할 경우 -> 실패
    $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => 'ens32',
            IPAddr  => ['192.168.0.10',  '192.168.0.15', '192.168.0.11'],
            Netmask => ['255.255.252.0', '255.255.252.0'],
            Gateway => [undef,           undef],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');
}

# 모든 파라미터 개수를 1개만 입력할 경우 -> 실패
sub test_address_update_one_param
{
    my $self = shift;

    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => 'ens32',
            IPAddr  => ['192.168.0.10'],
            Netmask => ['255.255.252.0'],
            Gateway => [undef],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');
}

# 모든 파라미터 개수를 3개 이상 입력할 경우 -> 실패
sub test_address_update_over_num_of_param_all
{
    my $self = shift;

    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => 'ens32',
            IPAddr  => ['192.168.0.10',  '192.168.0.15',  '192.168.0.11'],
            Netmask => ['255.255.252.0', '255.255.252.0', '255.255.255.0'],
            Gateway => [undef,           undef,           undef],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');
}

# NIC 파라미터를 2개 이상 입력할 경우 -> 실패
sub test_address_update_multiple_device_name
{
    my $self = shift;

    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => ['ens32',         'ens192'],
            IPAddr  => ['192.168.0.10',  '192.168.0.15'],
            Netmask => ['255.255.252.0', '255.255.252.0'],
            Gateway => [undef,           undef],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');
}

# NIC 파라미터를 입력하지 않을 경우 -> 실패
sub test_address_update_no_input_device
{
    my $self = shift;

    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => undef,
            IPAddr  => ['192.168.0.10',  '192.168.0.15'],
            Netmask => ['255.255.252.0', '255.255.252.0'],
            Gateway => [undef,           undef],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Validation failed/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');
}

# NIC 파라미터를 빈 공간으로 입력할 경우 -> 실패
sub test_address_update_input_device_space
{
    my $self = shift;

    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => '',
            IPAddr  => ['192.168.0.10',  '192.168.0.15'],
            Netmask => ['255.255.252.0', '255.255.252.0'],
            Gateway => [undef,           undef],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');
}

# 유효하지 않는 대역의 IP를 입력할 경우 -> 실패
sub test_address_update_invalid_network
{
    my $self = shift;

    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => undef,
            IPAddr  => ['192.168.0.10',  '192.168.0.999'],
            Netmask => ['255.255.252.0', '255.255.555.0'],
            Gateway => [undef,           undef],
        }
    );

    $t->status_is(422)->json_is('/success' => 0)
        ->json_like('/msg' => qr/Validation failed/)
        ->json_is('/statuses/0/code' => 'INVALID_VALUE');
}

# netmask만 고칠 경우 -> 정상
sub test_address_update_same_ip_diff_netmask : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => 'ens32',
            IPAddr  => ['192.168.0.10',  '192.168.0.10'],
            Netmask => ['255.255.252.0', '255.255.255.0'],
            Gateway => [undef,           undef],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network address is updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_ADDR_UPDATE_OK');

#    explain($t->tx->res->json);

    my $data = $self->mock_get_key(
        key     => "/${\$self->hostname}/Network/Device/ens32",
        options => {recursive => 'true'}
    );

    cmp_ok($data->{IPADDR}->[0],
        'eq', '192.168.0.10', 'ipaddr[0]: 192.168.0.10');

    cmp_ok($data->{NETMASK}->[0],
        'eq', '255.255.255.0', 'netmask[0]: 255.255.255.0');

    is($data->{GATEWAY}->[0], undef, 'gateway[0]: undef');
}

# 정상값을 입력하는 경우 -> 정상
sub test_address_update_default : Test(no_plan)
{
    my $self = shift;

    my $t = $self->t->post_ok(
        '/api/cluster/network/address/update',
        json => {
            Device  => 'ens32',
            IPAddr  => ['192.168.0.10',  '192.168.0.15'],
            Netmask => ['255.255.252.0', '255.255.252.0'],
            Gateway => [undef,           '192.168.0.1'],
        }
    );

    $t->status_is(200)->json_is('/success' => 1)
        ->json_like('/msg' => qr/Network address is updated/)
        ->json_is('/statuses/0/code' => 'NETWORK_ADDR_UPDATE_OK');

#    explain($t->tx->res->json);

    my $data = $self->mock_get_key(
        key     => "/${\$self->hostname}/Network/Device/ens32",
        options => {recursive => 'true'}
    );

    cmp_ok($data->{IPADDR}->[0],
        'eq', '192.168.0.15', 'ipaddr[0]: 192.168.0.15');

    cmp_ok($data->{NETMASK}->[0],
        'eq', '255.255.252.0', 'netmask[0]: 255.255.252.0');

    # TODO: #7281-54
    # etcd v3에서 빈 값('')에 대한 처리 방법이 정해지면, 그때 게이트웨이
    # 설정을 다시 시작함. modified by thkim
    # Gateway 값은 받지만, 실제로 아무 작업을 하지 않는다.
    is($data->{GATEWAY}->[0], undef, 'gateway[0]: undef, not changed');
}

1;

=encoding utf8

=head1 NAME

Test::Network::Address - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

