package Test::AnyStor::License;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Data::Dumper;
use Test::Most;
use JSON qw/decode_json/;

use MIME::Base64;

use GMS::System::License;
use GMS::Common::registry;
use GMS::Cluster::ClusterGlobal;

extends 'Test::AnyStor::Base';

my $event_check = 1;

my $license_obj = GMS::System::License->new();

sub system_license_uniq_key
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $return_expect = 0;
    }

    my $res = $self->call_rest_api("system/license/uniq_key", {}, {},
        {expected_return => $return_expect});

    return $res->{entity}->[0]->{Unique_Key};
}

sub system_license_list
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $return_expect = 0;
    }

    my $res = $self->call_rest_api("system/license/list", {}, {},
        {expected_return => $return_expect});

    return $res->{entity};
}

sub system_license_summary
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $return_expect = 0;
    }

    my $res = $self->call_rest_api("system/license/summary", {}, {},
        {expected_return => $return_expect});

    return $res->{entity}->[0];
}

sub system_license_check
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $return_expect = 0;
    }

    my $res
        = $self->call_rest_api("system/license/check",
        {Target => $args{target}},
        {}, {expected_return => $return_expect});

    return $res->{entity}->[0]->{Check_Info};
}

sub system_license_register
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $return_expect = 0;
    }

    my $res = $self->call_rest_api(
        "system/license/register", {},
        {LicenseKey      => $args{license_key}},
        {expected_return => $return_expect}
    );

    if ($event_check && $return_expect eq 'true')
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'LICENSE_REGISTER_OK', $res->{prof}{from}
            ),
            "'LICENSE_REGISTER_OK' event check"
        );
    }

    return $res->{success} == $return_expect;
}

sub system_license_test
{
    my $self = shift;
    my %args = @_;

    my $return_expect = 1;

    if (defined($args{return_false}) && $args{return_false} != 0)
    {
        $return_expect = 0;
    }

    my $res = $self->call_rest_api("system/license/test", {}, {},
        {expected_return => $return_expect});

    if ($event_check && $return_expect eq 'false')
    {
        ok(
            $self->is_code_exist_in_recent_events(
                'LICENSE_DENIED', $res->{prof}{from}
            ),
            "'LICENSE_DENIED' event check"
        );
    }

    return $res->{success} == $return_expect;
}

my $license_shared_db = $license_obj->{config}{shared_db_file};
my $license_local_db  = $license_obj->{config}{db_file};

sub backup_license_list
{
    my $self = shift;

    if (!_is_file_exist($self, $license_shared_db)
        || _is_file_exist($self, $license_shared_db . '.back'))
    {
        return 1;
    }

    (my $ipaddr) = split(/:/, $self->addr);

    return $self->ssh(
        addr => $ipaddr,
        cmd  => "cp $license_shared_db $license_shared_db.back",
    ) == 0;
}

sub rollback_license_list
{
    my $self = shift;

    if (!_is_file_exist($self, $license_shared_db . ".back"))
    {
        return 1;
    }

    (my $ipaddr) = split(/:/, $self->addr);

    my $status = $self->ssh(
        addr => $ipaddr,
        cmd  => "mv -f $license_shared_db.back $license_shared_db",
    );

    return ($status == 0 && $self->cluster_license_reload);
}

sub init_license_list
{
    my $self   = shift;
    my $result = 1;

    if (_is_file_exist($self, $license_shared_db))
    {
        (my $ipaddr) = split(/:/, $self->addr);

        $result &&= (
            $self->ssh(
                addr => $ipaddr,
                cmd  => "rm -f $license_shared_db",
            ) == 0
        );
    }

    foreach (@{$self->nodes})
    {
        next
            if (
            !_is_file_exist($self, $license_local_db, $_->{Mgmt_IP}->{ip}));

        $result &&= (
            $self->ssh(
                addr => $_->{Mgmt_IP}->{ip},
                cmd  => "rm -f $license_local_db",
            ) == 0
        );
    }

    return $result;
}

my $demo_license = $license_obj->{config}{shared_demo_file};
my $demo_date    = $license_obj->{config}{demo_date};

sub backup_demo_license
{
    my $self = shift;

    if (!_is_file_exist($self, $demo_license)
        || _is_file_exist($self, $demo_license . '.back'))
    {
        return 1;
    }

    (my $ipaddr) = split(/:/, $self->addr);

    return (
        $self->ssh(
            addr => $ipaddr,
            cmd  => "cp -f $demo_license $demo_license.back",
        ) == 0
    );
}

sub rollback_demo_license
{
    my $self = shift;

    if (!_is_file_exist($self, $demo_license . ".back"))
    {
        return 1;
    }

    (my $ipaddr) = split(/:/, $self->addr);

    return (
        $self->ssh(
            addr => $ipaddr,
            cmd  => "mv -f $demo_license.back $demo_license",
        ) == 0
    );
}

sub make_demo_license_expired
{
    my $self = shift;

    my @timestamp = localtime($self->get_ts_from_server);

    $timestamp[3] -= ($demo_date + 1);

    (my $ipaddr) = split(/:/, $self->addr);

    my $expired_demo_license
        = encode_base64(
        join(' ', @timestamp, $demo_date, $self->get_uniq_seed));

    return $self->ssh(
        addr => $ipaddr,
        cmd  => "echo \"$expired_demo_license\" > $demo_license",
    ) == 0;
}

sub _is_file_exist
{
    my $self   = shift;
    my $target = shift;
    my $ipaddr = shift;

    ($ipaddr) = split(/:/, $self->addr) if (!defined($ipaddr));

    (my $status) = $self->ssh_cmd(
        addr => $ipaddr,
        cmd  => "ls $target | wc -l"
    );

    return $status != 0;
}

sub cluster_license_reload
{
    my $self = shift;

    my $global_obj = GMS::Cluster::ClusterGlobal->new();

    my $reload_result = $global_obj->distribute_call(
        uri   => "/system/license/reload",
        parms => {
            argument => {},
            entity   => {}
        },
    );

    return $reload_result->{success} == 0;
}

sub get_uniq_seed
{
    my $self = shift;

    # TBD: change method getting uniq_seed
    #      uniq_seed must be got from only uniq_key
    (my $ipaddr) = split(/:/, $self->addr);

    (my $status) = $self->ssh_cmd(
        addr => $ipaddr,
        cmd  => "/usr/gms/bin/get_unique_seed"
    );

    return $status;
}

sub issue_license
{
    my $self      = shift;
    my $uniq_seed = shift;
    my $license   = shift;

    my $issue_server = shift;
    $issue_server = '127.0.0.1' if (!defined($issue_server));

    if ($license eq 'Test')
    {
        return '191501000102';
    }

    # TBD: add license issuing step(Test license)
    `/usr/gms/bin/lmgr license $uniq_seed $license` =~ /.+=(?<retval>.+)\n/;

    return $+{retval};
}

sub trigger_license_noty_girasole_plugin
{
    my $self = shift;

    sleep(200);

    return 1;
}

sub is_uniq_key_valid
{
    my $target = shift;
    $target = shift if (ref($target) eq __PACKAGE__);

    return ($target =~ /[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}/);
}

1;

__END__

=encoding utf8

=head1 NAME

Test::AnyStor::License - 

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
