package Test::AnyStor::Filing;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Try::Tiny;
use Test::Most;
use Scalar::Util qw/looks_like_number/;
use Number::Bytes::Human;
use Data::Dumper;

use Test::AnyStor::Util;
use GMS::Common::Command qw/:all/;

extends 'Test::AnyStor::Base';

has 'mounted' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { []; },
);

has 'writed' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { []; },
);

has 'remote' => (
    is      => 'rw',
    isa     => 'Str | Undef',
    default => undef,
);

has 'max_mount_tries' => (
    is      => 'ro',
    isa     => 'Int',
    default => 5,
);

has 'quiet' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'memtotal' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub
    {
        local @ARGV = ('/proc/meminfo');

        my $memtotal = 0;

        while (<>)
        {
            if ($_ =~ m/^MemTotal:\s*(?<memtotal>\d+)/)
            {
                $memtotal = $+{memtotal};
                last;
            }
        }

        return $memtotal;
    },
    lazy => 1,
);

# do not call umount(), when the obj demolished.
has 'not_umount' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

sub is_mountable
{
    my $self = shift;
    my %args = @_;

    my $cmd = undef;

    # 1. mount a specified gluster volume to the temporary mount point.

    $cmd
        = $args{timeo}
        ? "timeout $args{timeo} mount"
        : "mount";

    $cmd .= " -t $args{type}"                     if ($args{type});
    $cmd .= ' -o ' . join(',', @{$args{options}}) if ($args{options});

    if (!defined($args{device}))
    {
        fail("device '$args{device}' doesn't exists");
        return -1;
    }

    $cmd .= " $args{device}";

    my $point;

    if (defined($args{point}))
    {
        $point = $args{point};
    }
    elsif ($args{device} =~ m/([^\/]+)$/)
    {
        $point = "/mnt/$1";
        mkdir $point if (!-d $point);
    }

    $cmd .= " $point";

    if (defined($self->remote))
    {
        $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
    }

    $cmd .= " &> /dev/null" if ($self->quiet);

    my $try    = 0;
    my $result = -1;

    do
    {
        if ($try > 0) { sleep 1; }
        my $mount_res = system($cmd );
        $result = $?;
        $try++;

        # FIXME: makeshift.
        # Remove this after solve "permission denied" issue of cifs mount
        # related redmine issue: http://redmine.gluesys.com/redmine/issues/4960
        if (!defined($args{skip_smb_restrt})
            && $args{type} eq 'cifs'
            && $mount_res == 8192)
        {
            $self->_restart_server_smb($args{device});
        }
    } while ($result != 0 && $try < $self->max_mount_tries);

    my $return;

    if ($result == 0)
    {
        $cmd = "umount $point &> /dev/null";

        if (defined($self->remote))
        {
            $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
        }

        # unmount sometime failed silently
        my $status = system($cmd);
        ok($status >> 8 == 0, "[" . get_time() . "] Un-mount $point");

        ok(1, 'It is mountable');
        $return = 1;
    }
    else
    {
        ok(1, "It isn\'t mountable");
        $return = 0;
    }

    return $return;
}

sub show_mount
{
    my $self = shift;
    my %args = @_;
    my $res;
    my $cmd_res;
    my $cmd    = undef;
    my $try    = 0;
    my $result = -1;
    my $time;

    # 1. ping test
    do
    {
        if ($try > 0)
        {
            # VMware eth2 interface error workaround by hgichon 2018/01/29
            # http://redmine.gluesys.com/redmine/projects/anycloud/wiki/Jenkins_및_테스트_Error_List#mergefiling-test-도중-ping-실패
            my $devname;

            my $version
                = `lsb_release -r | sed -e "s/\\s\\+//g;" | cut -d ":" -f 2`;

            if ($version =~ m/^7/)
            {
                $devname = 'ens224';
            }
            else
            {
                $devname = 'eth2';
            }

            diag("[builder] reload $devname interface");
            $cmd = "ifconfig $devname down && ifconfig $devname up";
            system($cmd);
            sleep 1;
        }

        $cmd     = "ping -w 3 -q -c 1 $args{ip} >/dev/null 2>&1";
        $cmd_res = system($cmd);
        $res     = $?;

        $try++;

        $time = get_time();

        diag("[$time][$try] $cmd : $cmd_res");
    } while ($res >> 8 != 0 && $try < $self->max_mount_tries);

    is($res >> 8, 0, "ping $args{ip} ok");

    # 2. show mount

    if ($args{type} eq 'nfs')
    {
        $cmd = "showmount -e $args{ip}";
    }
    elsif ($args{type} eq 'cifs')
    {
        $cmd = "smbclient -L //$args{ip} -U $args{user}%$args{pass}";
    }

    $try = 0;

    do
    {
        if ($try > 0)
        {
            sleep 5;
        }

        $cmd_res = system("$cmd >/dev/null 2>&1");
        $res     = $?;

        $try++;
        $time = get_time();

        diag("[$time][$try] $cmd : $cmd_res");
    } while ($res >> 8 != 0 && $try < $self->max_mount_tries);

    is($res >> 8, 0, "$args{type} : showmount ok");
}

sub mount
{
    my $self = shift;
    my %args = @_;

    my $cmd = undef;

    # 1. mount a specified gluster volume to the temporary mount point.
    $cmd = "mount";

    $cmd .= " -t$args{type}" if ($args{type});
    $cmd .= ' -o' . join(',', @{$args{options}})
        if (defined($args{options}) && @{$args{options}});

    if (!defined($args{device}))
    {
        fail("device '$args{device}' doesn't exists");
        return -1;
    }

    $cmd .= " $args{device}";

    my $point;

    if (defined($args{point}))
    {
        $point = $args{point};
    }
    elsif ($args{device} =~ m/([^\/]+)$/)
    {
        $point = "/mnt/$1";
    }

    mkdir $point if (!-d $point);

    $cmd .= " $point";

    if (defined($self->remote))
    {
        $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
    }

    $cmd .= " &> /dev/null" if ($self->quiet);

    my $try    = 0;
    my $result = -1;
    my $time;

    do
    {
        sleep 1 if ($try > 0);

        my $mount_res = system($cmd);

        $result = $?;

        $try++;

        $time = get_time();

        diag("[$time][$try] $cmd : $mount_res");

        # FIXME: makeshift.
        # Remove this after solve "permission denied" issue of cifs mount
        # related redmine issue: http://redmine.gluesys.com/redmine/issues/4960
        $self->_restart_server_smb($args{device})
            if ($args{type} eq 'cifs' && $mount_res == 8192);
    } while ($result != 0 && $try < $self->max_mount_tries);

    if (!is($result >> 8, 0, "mount $args{device} to $point: $cmd"))
    {
        return -1;
    }

    push(@{$self->mounted}, $point);

    return $result;
}

sub _restart_server_smb
{
    my $self             = shift;
    my $smb_restart_addr = shift;

    $smb_restart_addr =~ s/^\/\///g;
    $smb_restart_addr =~ s/\/.*$//g;
    $smb_restart_addr .= ":80";

    $self->t->post_ok(
        "http://$smb_restart_addr/api/share/smb/control",
        {
            Authorization => $self->api_token,
        },
        json => {
            Action => 'restart',
        }
    );
}

sub cd
{
    my $self = shift;
    my %args = @_;

    # access the mount point with change directory.
    my $failure = 0;

    foreach my $point (@{$self->mounted})
    {
        my $cmd = "sh -c \"cd $point\"";

        if (defined($self->remote))
        {
            $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
        }

        system($cmd);

        is($? >> 8, 0, "change directory with $point");
    }

    return $failure;
}

sub is_readable
{
    my $self = shift;
    my %args = @_;

    my $point;

    if (defined($args{point}))
    {
        $point = $args{point};
    }
    elsif ($args{device} =~ m/([^\/]+)$/)
    {
        $point = "/mnt/$1";
        mkdir $point if (!-d $point);
    }

    my $chk_file;

    if (defined($args{file}))
    {
        $chk_file = $point . '/' . $args{file};
    }
    else
    {
        $chk_file = $point . '/gms_test';
    }

    my $cmd = "cat $chk_file";

    if (defined($self->remote))
    {
        $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
    }

    $cmd .= " &> /dev/null" if ($self->quiet);

    my $return;

    if (!system($cmd))
    {
        ok(1, "It is readable");
        $return = 1;
    }
    else
    {
        ok(1, "It isn\'t readable");
        $return = 0;
    }

    return $return;
}

sub is_writable
{
    my $self = shift;
    my %args = @_;

    my $point;

    if (defined($args{point}))
    {
        $point = $args{point};
    }
    elsif ($args{device} =~ m/([^\/]+)$/)
    {
        $point = "/mnt/$1";
        mkdir $point if (!-d $point);
    }

    my $chk_file = $point . '/writable_test';

    my $cmd = "touch $chk_file";

    if (defined($self->remote))
    {
        $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
    }

    $cmd .= " &> /dev/null" if ($self->quiet);

    my $return;

    if (!system($cmd))
    {
        $cmd = "rm -rf $chk_file";

        if (defined($self->remote))
        {
            $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
        }

        $cmd .= " &> /dev/null" if ($self->quiet);

        system($cmd);

        ok(1, "It is writable");
        $return = 1;
    }
    else
    {
        ok(1, "It isn\'t writable");
        $return = 0;
    }

    return $return;
}

sub write_file
{
    my $self = shift;
    my %args = @_;

    my $point;

    if (defined($args{point}))
    {
        $point = $args{point};
    }
    elsif ($args{device} =~ m/([^\/]+)$/)
    {
        $point = "/mnt/$1";
        mkdir $point if (!-d $point);
    }

    my $file;

    if (defined($args{file}))
    {
        $file = $point . '/' . $args{file};
    }
    else
    {
        $file = $point . '/gms_test';
    }

    my $contents;

    if (defined($args{contents}))
    {
        $contents = $args{contents};
    }
    else
    {
        $contents = "The contents of gms_test";
    }

    my $cmd = "echo -e \"$contents\" \> $file";

    if (defined($self->remote))
    {
        $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
    }

    $cmd .= " &> /dev/null" if ($self->quiet);

    my $result = system($cmd);

    is($result, 0, "file write executed: $cmd");

    if ($result == 0)
    {
        push(@{$self->writed}, $file);
    }

    return $result;
}

sub make_directory
{
    my $self = shift;
    my %args = @_;

    my $cmd = "mkdir";
    my $dir;

    if (defined($args{options}))
    {
        $cmd .= ' ' . join(' ', @{$args{options}});
    }

    if (defined($args{dir}))
    {
        $dir = $args{dir};
    }
    elsif ($args{device} =~ m/([^\/]+)$/)
    {
        $dir = "/mnt/$args{device}";
    }

    if (!defined $dir)
    {
        fail('Unknow mount path');
        return -1;
    }

    $cmd .= " $dir";

    if (defined($self->remote))
    {
        $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
    }

    $cmd .= " &> /dev/null" if ($self->quiet);

    my $result;
    my $mkdir_cnt = 5;

MKDIR_RETRY:
    return 0 if (-d $dir);

    $result = system($cmd);

    if ($result != 0 && $mkdir_cnt-- > 0)
    {
        sleep(1);
        goto MKDIR_RETRY;
    }

    is($result, 0, "directory make executed: $cmd");

    if ($result == 0)
    {
        push(@{$self->writed}, $dir);
    }

    return $result;
}

sub io_archive
{
    my $self    = shift;
    my %args    = @_;
    my $srcpath = $args{srcpath};
    my $dstip   = $args{destip};
    my $dstpath = $args{destpath};
    my $tool    = $args{tool}  // undef;
    my $print   = $args{print} // 0;

    # print I/O test result
    if ($tool && $print)
    {
        if ($tool eq 'bonnie++')
        {
            try
            {
                opendir(my $dh, $srcpath);

                my @files = readdir($dh);

                my $sorter = sub
                {
                    my ($anum) = shift =~ /^.+\.(\d+)$/;
                    my ($bnum) = shift =~ /^.+\.(\d+)$/;

                    ($anum || 0) <=> ($bnum || 0);
                };

                @files = grep { !/^(\.|\.\.)$/ }
                    sort { $sorter->($a, $b); } @files;

                foreach my $file (@files)
                {
                    next if ($file eq '.' || $file eq '..');

                    warn "\n$file\n";

                    my $cmd = "cat $srcpath/$file | bon_csv2txt";

                    if (defined($self->remote))
                    {
                        $cmd = sprintf('ssh %s "%s"', $self->remote, $cmd);
                    }

                    system($cmd);
                }
            }
            catch
            {
                warn "Fail to print I/O result files\n";
            };
        }
    }

    my $cmd = "scp -r $srcpath root\@$dstip:$dstpath > /dev/null";

    if (defined($self->remote))
    {
        $cmd = sprintf('ssh %s "%s"', $self->remote, $cmd);
    }

    my $ret = system($cmd);

    ok($ret == 0, "Archive the result of I/O test: $cmd");

    return if ($ret);

    return $self->rm(dir => $srcpath);
}

sub io
{
    my $self     = shift;
    my %args     = @_;
    my $tool     = $args{tool}    // 'bonnie++';
    my $point    = $args{point}   // undef;
    my $io_size  = $args{io_size} // undef;
    my $dd_bs    = $args{dd_bs};
    my $dd_count = $args{dd_count};

    if (!$point)
    {
        $point = $self->mounted;
    }
    else
    {
        $point = [$point];
    }

    if ($io_size)
    {
        if (!looks_like_number($io_size) || $io_size <= 0)
        {
            fail("Invalid I/O size($io_size)");
            return -1;
        }
        elsif ($io_size =~ /^(?<val>\d+)\s*(B|Ki*B|Mi*B|Gi*B|Ti*B)\s*$/)
        {
            if (int($+{val}) <= 0)
            {
                fail("Invalid I/O size($io_size)");
                return -1;
            }

            my $human = Number::Bytes::Human->new(bs => 1024, si => 1);
            $io_size = $human->parse($io_size);
        }
    }

    if ($tool eq 'bonnie++')
    {
        if ($io_size)
        {
            $args{memtotal} = int($self->memtotal / 1024);
            $args{dir_num}  = 100;
            $args{rand_min} = 4096;
            $args{rand_max} = (1024 * 1024);
            $args{rand_num}
                = int($io_size / $args{dir_num} / $args{rand_max});
            $args{seq_max}   = int($io_size / $args{rand_max});
            $args{seq_chunk} = 4096;
            $args{uid}       = 0;
            $args{gid}       = 0;
            $args{count}     = 1;
        }

        return $self->io_bonnie(points => $point, %args);
    }
    elsif ($tool eq 'dd')
    {
        my $points = join(' ', @{$point});

        $args{bs}    = $dd_bs;
        $args{count} = $dd_count;

        return $self->io_dd(points => $points, %args);
    }

    return -1;
}

sub io_bonnie
{
    my $self     = shift;
    my %args     = @_;
    my $points   = $args{points};
    my $savepath = $args{save_path}   // undef;
    my $prefix   = $args{save_prefix} // undef;

    # 1. access the mount point with change directory.
    # 2. perform read/write operation some shell commands or POSIX API.
    my $failure = 0;

    my %opts = (
        memtotal => $args{memtotal} // int($self->memtotal / 1024),
        uid      => $args{uid}      // 0,
        gid      => $args{gid}      // 0,
        count    => $args{count}    // 1,
    );

    for my $key (qw/seq_max seq_chunk rand_num rand_max rand_min dir_num/)
    {
        $opts{$key} = $args{$key}
            if (exists $args{$key} && defined $args{$key});
    }

    foreach my $point (@{$points})
    {
        # bonnie++를 통해 IO 스트레스 테스트
        my $cmd = "bonnie++ -d $point";

        $cmd .= sprintf(" -r %s", $opts{memtotal});

        if (exists $opts{seq_max} && defined $opts{seq_max})
        {
            $cmd .= " -s $opts{seq_max}";

            if (exists $opts{seq_chunk} && defined $opts{seq_chunk})
            {
                $cmd .= ":$opts{seq_chunk}";
            }
        }
        else
        {
            $cmd .= " -s 0";
        }

        if (exists $opts{rand_num} && defined $opts{rand_num})
        {
            $cmd .= " -n $opts{rand_num}";

            if (exists $opts{rand_max} && defined $opts{rand_max})
            {
                $cmd .= ":$opts{rand_max}";

                if (exists $opts{rand_min} && defined $opts{rand_min})
                {
                    $cmd .= ":$opts{rand_min}";

                    if (exists $opts{dir_num} && defined $opts{dir_num})
                    {
                        $cmd .= ":$opts{dir_num}";
                    }
                }
            }
        }
        else
        {
            $cmd .= " -n 0";
        }

        $cmd .= sprintf(" -m '%s'",  $point);
        $cmd .= sprintf(" -u %s:%s", $opts{uid}, $opts{gid});
        $cmd .= " -x $opts{count}";

        if ($savepath)
        {
            if (!$prefix)
            {
                $prefix = $point;
                $prefix =~ s/\//_/;
            }

            $cmd .= " > $savepath/bonnie_$prefix." . time();
        }

        diag("Performing I/O-test: $cmd");

        if (defined($self->remote))
        {
            $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
        }

        my $return = system($cmd);

        ok($return == 0, "I/O-test for '$point': $cmd");

        $failure++ if ($return);
    }

    return $failure;
}

sub io_dd
{
    my $self = shift;
    my %args = @_;

    my $points   = $args{points}   // undef;
    my $bs       = $args{bs}       // undef;
    my $count    = $args{count}    // undef;
    my $filename = $args{filename} // 'dummy.txt';

    if (!defined($bs) || !defined($count) || !defined($points))
    {
        ok(
            0,
            'Failed to I/O test with dd command no defined bs, count, points'
        );
        return -1;
    }

    my $cmd
        = "dd if=/dev/zero of=$points/$filename bs=$bs count=$count oflag=direct";

    diag("Performing I/O-test: $cmd");

    if (defined($self->remote))
    {
        $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
    }

    my $ret = system($cmd);

    ok($ret == 0, "I/O-test for '$points':$cmd");

    return $ret;
}

sub exists
{
    my $self = shift;
    my %args = @_;

    my $cmd = "[ -e $args{target} ]";

    if (defined($self->remote))
    {
        $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
    }

    return system($cmd);
}

sub rm
{
    my $self = shift;
    my %args = @_;

    my $failure = 0;

    if (defined($args{target}))
    {
        my $cmd = "rm -f " . $args{target};

        if (defined($self->remote))
        {
            $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
        }

        my $result = system($cmd);

        is($result, 0, "rm file executed: $cmd");

        if ($result != 0) { $failure = -1; }
    }
    elsif (defined($args{point}))
    {
        my $cmd = "rm -f " . $args{point} . '/gms_test';

        if (defined($self->remote))
        {
            $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
        }

        my $result = system($cmd);

        is($result, 0, "rm file executed: $cmd");

        if ($result != 0) { $failure = -1; }
    }
    elsif (defined($args{dir}))
    {
        my $cmd = "rm -rf " . $args{dir};

        if (defined($self->remote))
        {
            $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
        }

        my $result = system($cmd);

        is($result, 0, "rm directory executed: $cmd");

        if ($result != 0) { $failure = -1; }
    }
    else
    {
        foreach my $file (@{$self->writed})
        {
            my $cmd = "rm -rf $file";

            if (defined($self->remote))
            {
                $cmd = sprintf("ssh %s \"%s\"", $self->remote, $cmd);
            }

            my $result = system($cmd);

            is($result, 0, "rm files executed: $cmd");

            if ($result != 0)
            {
                $failure = -1;
            }
        }
    }

    return $failure;
}

sub umount
{
    my $self = shift;
    my %args = @_;

    diag("Current mount dirs: ${\Dumper($self->mounted)}");

    my $failure = 0;

    my @umount_fail = ();

    foreach my $point (@{$self->mounted})
    {
        my $cmd = "umount $point";

        $cmd = sprintf('ssh %s "%s"', $self->remote, $cmd)
            if (defined($self->remote));

        # unmount sometime failed silently
        #my $result = run_forked($cmd, { 'timeout' => 10 });
        #$result = $result->{exit_code};
        my $time = get_time();

        diag("[$time] $cmd");

        my $result = system($cmd);

        $time = get_time();

        is($result >> 8, 0, "[$time] Un-mount $point");

        if ($result >> 8)
        {
            push(@umount_fail, $point);
            $failure++;
        }
    }

    $self->{mounted} = \@umount_fail;

    return $failure;
}

sub DEMOLISH
{
    my $self     = shift;
    my $isglobal = shift;

    ok(1, "call Test::AnyStor::Filing::DEMOLISH");
    ok(1, "\$self->not_umount: ${\$self->not_umount}");

    if (!$self->not_umount)
    {
        ok(1, "Try to unmount all of mount dirs");
        $self->umount();
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8

=head1 NAME

Test::AnyStor::Filing - Test package for the filing protocol access.

=head1 SYNOPSIS

This package is that for the access test with some filing protocols like NFS/CIFS.

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

