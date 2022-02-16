package Test::AnyStor::Base;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Crypt::OpenSSL::RSA;
use Data::Dumper;
use DateTime::Format::Strptime;
use Devel::NYTProf;
use Etcd;
use Env;
use Encode qw/encode_utf8/;
use GMS::Common::Useful;
use HTTP::Tiny;
use JSON qw/decode_json/;
use List::MoreUtils qw/uniq/;
use Mojo::Util qw/url_unescape b64_decode b64_encode/;
use Net::Ping;
use POSIX qw/strftime/;
use Test::Most;
use Test::Mojo;
use Term::ANSIColor;
use XML::Smart;

use base 'Exporter';

our @EXPORT = qw/
    call_system ping
    p_printf p_e_printf p_w_printf p_warn
    paint_reset paint_info paint_err paint_warn
    paint_info_l paint_warn_l paint_err_l
    nodes_archive profile_archive
    /;

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'no_login' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'no_logout' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'no_complete' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 't' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { Test::Mojo->new(); },
    lazy    => 1,
    handles => {
        success => 'success',
    }
);

has 'x' => (
    is      => 'ro',
    isa     => 'Object',
    default => sub { Test::Mojo->new(); },
    lazy    => 1,
);

has 'cluster' => (
    is      => 'rw',
    isa     => 'Str | Undef',
    default => undef,
);

has 'nodes' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { []; },
);

has 'addr' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { $ENV{GMS_TEST_ADDR} // '127.0.0.1:80'; },
);

has 'api_token' => (
    is      => 'rw',
    isa     => 'Str | Undef',
    default => undef,
);

has 'public_key' => (
    is  => 'rw',
    isa => 'Str',
);

has 'junit_data' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { []; },
);

has 'junit_result' => (
    is      => 'rw',
    isa     => 'Str',
    default => '/usr/gms/result.xml',
);

has 'junit_duration' => (
    is      => 'rw',
    isa     => 'Num',
    default => '0',
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub login
{
    my $self = shift;
    my %args = @_;

    my $failure = $args{failure} // 0;

    my $signing_key;
    my $res = $self->t->get_ok("http://${\$self->addr}");

    foreach my $c (@{$res->tx->res->cookies})
    {
        if ($c->name eq 'signing_key')
        {
            $signing_key = b64_decode(url_unescape($c->value));
            last;
        }
    }

    if (!ok(defined($signing_key), 'Signing key is defined'))
    {
        return -1;
    }

    $args{password} = $self->encrypt(
        key  => $signing_key,
        data => $args{password} // 'admin'
    );

    $res = $self->request(
        uri    => '/manager/sign_in',
        params => {
            ID       => $args{id} // 'admin',
            Password => $args{password},
        },
        expected_return => $failure ? 'false' : 'true'
    );

    return if ($failure);

    if (!isa_ok($res, 'HASH', 'response is a HASH'))
    {
        return -1;
    }

    if (!isa_ok($res->{entity}, 'HASH', 'response->entity is a HASH'))
    {
        return -1;
    }

    if (!ok($res->{entity}->{token}, 'response->entity->token exists'))
    {
        return -1;
    }

    $self->api_token($res->{entity}->{token});

    if (!ok(
        $res->{entity}->{public_key},
        'response->entity->public_key exists'
    ))
    {
        return -1;
    }

    $self->public_key($res->{entity}->{public_key});

    return 0;
}

sub encrypt
{
    my $self = shift;
    my %args = @_;

    my $key = $args{key} // $self->public_key;
    my $rsa = Crypt::OpenSSL::RSA->new_public_key($key);

    $rsa->use_pkcs1_padding();

    return b64_encode($rsa->encrypt($args{data}));
}

sub get_nodes
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri => '/cluster/general/nodelist',
        %args,
    );

    if (defined($args{http_status}))
    {
        cmp_ok(ref($res->{entity}), 'eq', 'ARRAY', 'entity isa ARRAY');
    }

    if (ref($res->{entity}) eq 'ARRAY')
    {
        foreach my $node (@{$res->{entity}})
        {
#       TODO : Skip ERR checking by hgichon 2016/11/01
#        map {
#            unlike($node->{$_}, qr/err/i
#                , "Node $node->{Mgmt_Hostname} $_: $node->{$_}");
#        } qw/SW_Status HW_Status/;
#
            push(@{$self->nodes}, $node);
        }
    }

    return 0;
}

sub ping
{
    my $self = @_ % 2 ? shift : undef;
    my %args = @_;

    if (!defined($args{host}))
    {
        warn '[ERR] Invalid parameter: host';
        return -1;
    }

    my $p = Net::Ping->new('tcp', $args{timeout} // 2);

    $p->port_number(scalar(getservbyname('http', 'tcp')));

    my $tout  = $args{timeout} // 300;
    my $start = time;

    while (!$p->ping($args{host}))
    {
        warn "[INFO] $args{host}:${\$p->port_number} seems down...";

        sleep($args{interval} // 1);

        if (time - $start >= int($tout))
        {
            warn "[ERR] ping timed out in $tout seconds";
            return -1;
        }
    }

    warn "[INFO] $args{host} seems up!";

    $p->close();

    return 0;
}

sub is_code_exist_in_recent_events
{
    my $self        = shift;
    my $target_code = shift;
    my $from        = shift;
    my $to          = shift;

    return $self->is_matched_exist_in_recent_events(
        code => $target_code,
        from => $from,
        to   => $to
    );
}

sub is_message_exist_in_recent_events
{
    my $self       = shift;
    my $target_msg = shift;
    my $from       = shift;
    my $to         = shift;

    return $self->is_matched_exist_in_recent_events(
        message => $target_msg,
        from    => $from,
        to      => $to
    );
}

sub is_matched_exist_in_recent_events
{
    my $self = shift;
    my %args = @_;

    my %cond;
    my @valid_fields = (qw(Scope Type Message Code Category));

    foreach my $key (keys(%args))
    {
        next if (grep { $_ eq $key } ('from', 'to'));

        my $field = ucfirst(lc($key));

        if (scalar(grep { $_ eq $field } @valid_fields) == 0)
        {
            return 0;
        }

        $cond{$field} = $args{$key};
    }

    for (my $try = 0; $try < 10; $try++)
    {
        my @events = $self->get_events(from => $args{from}, to => $args{to});

        foreach my $event (@events)
        {
            my $is_matched = 1;

            foreach my $key (keys(%cond))
            {
                if ($event->{$key} !~ m/$cond{$key}/)
                {
                    $is_matched = 0;
                    last;
                }
            }

            if ($is_matched)
            {
                ok(1, "Found matched event!\n${\Dumper($event)}");
                return 1;
            }
        }

        sleep 5;
    }

    return 0;
}

sub check_api_code_in_recent_events
{
    my $self = shift;
    my %args = @_;

    diag('check event args');
    diag(Dumper(\%args));

    my $prefix = uc($args{prefix});

    my @event_cds = ();

    # XXX: optional args
    my $status    = $args{status};
    my $ok        = $args{ok}      // [];
    my $failure   = $args{failure} // [];
    my $category  = $args{category} ? uc($args{category}) : undef;
    my $message   = $args{msg};
    my $level     = $args{level} ? uc($args{level}) : undef;
    my $from      = $args{from};
    my $to        = $args{to};
    my $max_retry = $args{max_retry} // 2;
    my $skip_fail = $args{skip_fail} // 'true';

    $status = lc($status) if (defined($status));

    if (defined($status) && $status)
    {
        foreach my $code (@{$ok})
        {
            $code = $prefix . $code;
            push(@event_cds, $code);
        }
    }
    elsif (defined($status) && !$status)
    {
        foreach my $code (@{$failure})
        {
            $code = $prefix . $code;
            push(@event_cds, $code);
        }
    }
    elsif ($prefix !~ /^\s*$/)
    {
        push(@event_cds, $prefix);
    }

    # arg check
    if (!@event_cds)
    {
        fail('Invalid argument, empty event codes');
        return -1;
    }

    @event_cds = uniq(@event_cds);

    my $retry = $max_retry;

    for (my $i = 1; $i <= $retry; $i++)
    {
        my %tmp = ();

        $tmp{category} = $category if (defined($category));
        $tmp{from}     = $from     if (defined($from));
        $tmp{to}       = $to       if (defined($to));

        my $events = $self->test_events(%tmp);

        my @found = grep { $_->{Code} ~~ \@event_cds } @{$events};

        if (@found > 0)
        {
            if (defined($message) && !($message =~ /^\s*$/))
            {
                @found = grep { $_->{Message} =~ $message } @found;
            }

            if (defined($level) && !($level =~ /^\s*$/))
            {
                @found = grep { $_->{Level} =~ $level } @found;
            }

            if (@found > 0)
            {
                ok(1, "check event (@event_cds)");
                diag(Dumper(\@found));
                return 0;
            }
        }

        ok(1, "wait @event_cds event ($i/$retry)");

        sleep(5);
    }

    if ($skip_fail ne 'true')
    {
        fail("check event (@event_cds)");
    }

    p_e_printf("not ok - check event (@event_cds)");

    return 1;
}

sub test_events
{
    my $self = shift;
    my %args = @_;

    my @event_list = $self->get_events(@_);

    for (my $i = 0; $i < @event_list; $i++)
    {
        map {
            $self->t->json_like(
                "/entity/$i/$_",
                qr/$args{pattern}/i,
                "event match: $_"
            );
        } @{$args{fields}};
    }

    return wantarray ? @event_list : \@event_list;
}

sub gen_event_api_payload
{
    my $self = shift;
    my %args = @_;

    my %payload = (
        NumOfRecords => $args{numofrecords} // 50,
        PageNum      => $args{pagenum}      // 1,
    );

    if (exists($args{from}))
    {
        $payload{From} = $args{from};
    }

    if (exists($args{to}))
    {
        $payload{To} = $args{to};
    }

    if (exists($args{category}))
    {
        $payload{Category} = $args{category};
    }

    if (exists($args{level}))
    {
        $payload{Level} = $args{level};
    }

    if (!exists($payload{To}))
    {
        $payload{To} = $self->get_ts_from_server();
    }

    if (!exists($payload{From}))
    {
        $payload{From} = $payload{To} - 60;
    }

    $payload{To} += 60;

    return \%payload;
}

sub get_events
{
    my $self = shift;
    my %args = @_;

    my $payload = $self->gen_event_api_payload(%args);

    my $res = $self->request(
        uri    => '/cluster/event/list',
        params => $payload,
    );

    cmp_ok(ref($res->{entity}), 'eq', 'ARRAY', 'entity isa ARRAY');

    diag(
        sprintf(
            'Events: %s(%d) - %s(%d): %d events',
            strftime('%F %T', localtime($payload->{From})),
            $payload->{From},
            strftime('%F %T', localtime($payload->{To})),
            $payload->{To},
            scalar(@{$res->{entity}}),
        )
    );

    return wantarray ? @{$res->{entity}} : $res->{entity};
}

sub get_event_count
{
    my $self = shift;
    my %args = @_;

    my $payload = $self->gen_event_api_payload(%args);

    my $res = $self->request(
        uri    => '/cluster/event/count',
        params => $payload,
    );

    diag(
        sprintf(
            'Events: %s(%d) - %s(%d): %s',
            strftime('%F %T', localtime($payload->{From})),
            $payload->{From},
            strftime('%F %T', localtime($payload->{To})),
            $payload->{To},
            Dumper($res->{entity}),
        )
    );

    return $res->{entity};
}

sub gen_task_api_payload
{
    my $self = shift;
    my %args = @_;

    my %payload = (
        NumOfRecords => $args{numofrecords} // 50,
        PageNum      => $args{pagenum}      // 1,
    );

    if (exists($args{from}))
    {
        $payload{From} = $args{from};
    }

    if (exists($args{to}))
    {
        $payload{To} = $args{to};
    }

    if (exists($args{category}))
    {
        $payload{Category} = $args{category};
    }

    if (exists($args{level}))
    {
        $payload{Level} = $args{level};
    }

    if (!exists($payload{To}))
    {
        $payload{To} = $self->get_ts_from_server();
    }

    if (!exists($payload{From}))
    {
        $payload{From} = $payload{To} - 60;
    }

    $payload{To} += 60;

    return \%payload;
}

sub get_tasks
{
    my $self = shift;
    my %args = @_;

    my $payload = $self->gen_event_api_payload(%args);

    my $res = $self->request(
        uri    => '/cluster/task/list',
        params => $payload,
    );

    cmp_ok(ref($res->{entity}), 'eq', 'ARRAY', 'entity isa ARRAY');

    diag(
        sprintf(
            'Tasks: %s(%d) - %s(%d): %d tasks',
            strftime('%F %T', localtime($payload->{From})),
            $payload->{From},
            strftime('%F %T', localtime($payload->{To})),
            $payload->{To},
            scalar(@{$res->{entity}}),
        )
    );

    return wantarray ? @{$res->{entity}} : $res->{entity};
}

sub get_task_count
{
    my $self = shift;
    my %args = @_;

    my $payload = $self->gen_event_api_payload(%args);

    my $res = $self->request(
        uri    => '/cluster/task/count',
        params => $payload,
    );

    diag(
        sprintf(
            'Tasks: %s(%d) - %s(%d): %s',
            strftime('%F %T', localtime($payload->{From})),
            $payload->{From},
            strftime('%F %T', localtime($payload->{To})),
            $payload->{To},
            Dumper($res->{entity}),
        )
    );

    return $res->{entity};
}

sub test_return
{
    my $self = shift;
    my %args = @_;

    my $expect = $args{expect} // 1;

    if ($expect =~ m/^(?:true|yes|1)$/i)
    {
        $expect = 1;
    }
    else
    {
        $expect = 0;
    }

    $self->t->json_is('/success ' => $expect, 'return validation')
        ->or(sub { diag(Dumper($self->t->tx->res->json)); });

    return !$self->t->success();
}

sub logout
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/manager/sign_out');

    return 0;
}

sub gethostnm
{
    my $self    = shift;
    my (%args)  = @_;
    my @hostnms = ();

    foreach my $key (qw/start_node cnt/)
    {
        if (!exists($args{$key}) || !defined($args{$key}))
        {
            warn "[ERR] Invalid parameter: $key";
            return @hostnms;
        }
    }

    my $start    = $args{start_node};
    my $cnt      = $args{cnt};
    my $mgmtip_k = 'Mgmt_Hostname';
    my $node_cnt = scalar @{$self->nodes};

    if ($start < 0
        || $start + $cnt > $node_cnt
        || $cnt < 1
        || $cnt > $node_cnt)
    {
        warn
            "[ERR] Invalid parameter: start($start), cnt($cnt), node_cnt($node_cnt)";
        return @hostnms;
    }

    my @tmp = ();

    foreach my $node (@{$self->nodes})
    {
        push(@tmp, $node->{$mgmtip_k});
    }

    my $sorter = sub
    {
        my ($anum) = shift =~ /(\d+)$/;
        my ($bnum) = shift =~ /(\d+)$/;

        ($anum || 0) <=> ($bnum || 0);
    };

    @hostnms = sort { $sorter->($a, $b); } @tmp;

    return @hostnms[$start .. ($start + $cnt) - 1];
}

sub hostnm2stgip
{
    my $self   = shift;
    my (%args) = @_;
    my @ip     = ();

    if (!exists($args{hostnms})
        || !defined($args{hostnms} || ref $args{hostnms} ne 'ARRAY'))
    {
        warn "[ERR] Invalid parameter: hostnms";
        return @ip;
    }

    my $hostnms  = $args{hostnms};
    my $hostnm_k = 'Mgmt_Hostname';
    my $stgip_k  = 'Storage_IP';

    my $node_cnt = scalar(@{$self->nodes});

    foreach my $hostnm (@{$hostnms})
    {
        foreach my $info (@{$self->nodes})
        {
            if ($hostnm eq $info->{$hostnm_k})
            {
                push(@ip, $info->{$stgip_k});
                last;
            }
        }
    }

    return @ip;
}

sub hostnm2mgmtip
{
    my $self   = shift;
    my (%args) = @_;
    my @ip     = ();

    if (!exists($args{hostnms})
        || !defined($args{hostnms} || ref($args{hostnms}) ne 'ARRAY'))
    {
        warn "[ERR] Invalid parameter: hostnms";
        return @ip;
    }

    my $hostnms  = $args{hostnms};
    my $hostnm_k = 'Mgmt_Hostname';
    my $mgmtip_k = 'Mgmt_IP';

    my $node_cnt = scalar(@{$self->nodes});

    foreach my $hostnm (@{$hostnms})
    {
        foreach my $info (@{$self->nodes})
        {
            if ($hostnm eq $info->{$hostnm_k})
            {
                push(@ip, $info->{$mgmtip_k}->{ip});
                last;
            }
        }
    }

    return @ip;
}

sub get_master
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/cluster/general/master');

    $self->t->status_is(200)->json_has('/entity/0/Hostname')
        ->json_has('/entity/0/Mgmt_IP')->json_has('/entity/0/Storage_IP');

    return $res->{entity};
}

sub set_debug
{
    my $self = shift;
    my %args = @_;

    $self->request(
        uri    => '/cluster/debug/set',
        params => {
            scope => $args{scope},
            value => $args{value},
        }
    );

    return 0;
}

sub get_debug
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(uri => '/cluster/debug/get');

    if (!isa_ok($res, 'HASH'))
    {
        return;
    }

    if (!isa_ok($res->{entity}, 'HASH'))
    {
        return;
    }

    return $res->{entity};
}

sub etcd_get
{
    my $self = ref($_[0]) ? shift : undef;

    my %args = @_;

    my $ip   = $args{ip};
    my $port = $args{port} // '2379';
    my $key  = $args{key};

    if (!defined($key) || !defined($ip) || !defined($port))
    {
        p_e_printf("[ERR] Invalid arguement, empty key or addr or port\n");
        return;
    }

    $key =~ s/\/+/\//g;
    $key =~ s/\/$//g;

    $key = '/' . $key if ($key =~ /^[^\/]/);

    my %opts  = $args{opts}  // ();
    my $timeo = $args{timeo} // 10;

    my $using_kv_db = 0;

    if ($key =~ /^\/ClusterMeta/)
    {
        $using_kv_db = 1;
        $opts{recursive} = 'true';
    }

    my $etcd = Etcd->new(
        host => $ip,
        port => $port,
        http => HTTP::Tiny->new(timeout => $timeo),
    );

    my $ret = try
    {
        my $val = $etcd->get($key, %opts);

        # for string type json K/V DB
        if (!$using_kv_db)
        {
            if (!exists($val->{node}->{value})
                || !defined($val->{node}->{value}))
            {
                die Dumper($val);
            }

            return decode_json($val->node->value, {utf8 => 1});
        }

        # for ClusterMeta DB
        if (exists($val->{node}) && defined($val->{node}))
        {
            my $tmp = {};
            _response_to_flat_hashref($val->{node}, $tmp);
            return $tmp;
        }

        die Dumper($val);
    }
    catch
    {
        p_e_printf("[ERR] Unknown exception: $_");
        return;
    };

    return $ret;
}

sub _response_to_flat_hashref
{
    my $data   = shift;
    my $result = shift;

    # leaf Etcd::Node
    if (!exists($data->{dir})
        && exists($data->{key})
        && exists($data->{value}))
    {
        $result->{$data->{key}} = $data->{value};
    }

    # dir Etcd::Node
    if (exists($data->{nodes})
        && defined($data->{nodes})
        && ref($data->{nodes}) eq 'ARRAY')
    {
        _response_to_flat_hashref($_, $result) for (@{$data->{nodes}});
    }
}

sub ssh
{
    my $self = (ref($_[0]) ? shift : undef);
    my %args = @_;

    return GMS::Common::Useful::ssh(%args);
}

sub ssh_cmd
{
    my $self = (ref($_[0]) ? shift : undef);
    my %args = @_;

    my @retval = GMS::Common::Useful::ssh_cmd(%args);

    diag("SSH Command [$args{addr}] : $args{cmd}");

    if (defined($retval[0]))
    {
        diag("STDOUT      : $retval[0]");
        diag("STDERR      : $retval[1]");
    }

    return @retval;
}

sub scp_get_r
{
    my $self = (ref($_[0]) ? shift : undef);
    my %args = @_;

    return GMS::Common::Useful::scp_get_r(%args);
}

sub scp_put_r
{
    my $self = (ref($_[0]) ? shift : undef);
    my %args = @_;

    return GMS::Common::Useful::scp_put_r(%args);
}

sub redmine_issue_report
{
    my $self = shift;
    my %args = @_;

    return if ($ENV{JOB_NAME} !~ /AC2-GMS*/);

    my $res = $self->t->post_ok(
        "http://redmine.gluesys.com/issues.json",
        json => {
            issue => {
                project_id   => "ac2",
                subject      => "$ENV{JOB_NAME}/$ENV{BUILD_NUMBER}",
                proiority_id => 4,
                description  =>
                    "http://jenkins.gluesys.com/job/$ENV{JOB_NAME}/$ENV{BUILD_NUMBER}",
            },
        }
    )->tx->res->json;

#    $self->t->status_is(200)
#        ->json_is('/success' => 1);
#
#    ok(ref($res->{entity}) eq 'ARRAY', 'entity validation');

    return 0;
}

sub profile_archive
{
    my ($path, $job_name, $build_number) = @_;

    $job_name     //= $ENV{JOB_NAME};
    $build_number //= $ENV{BUILD_NUMBER};

    do_archive(
        destip   => $ENV{ARCHIVE_IP},
        destpath => "$ENV{ARCHIVE_ROOT}/$job_name/$build_number/$path",
        target   => 'profile',
    );

    note(
        sprintf(
            "Profile: http://%s/jenkins_log/%s/%s\n",
            $ENV{ARCHIVE_IP}, $job_name, $build_number
        )
    );
}

sub nodes_archive
{
    my ($path, $nodes, $job_name, $build_number) = @_;

    $job_name     //= $ENV{JOB_NAME};
    $build_number //= $ENV{BUILD_NUMBER};

    note("===== Time comparison between target and test node =====\n");

    foreach my $node (@{$nodes})
    {
        my ($out, $err) = ssh_cmd(
            addr  => $node,
            cmd   => 'date',
            timeo => 30,
        );

        chomp(my $date = `date`);

        note("$node [$out] : tester [$date]\n");
    }

    ssh_cmd(
        addr => $nodes->[0],
        cmd  => "mysqldump --single-transaction --skip-opt --routines"
            . " --databases girasole -u root -p\'gluesys!!\'"
            . " > /var/lib/gms/mysqldump.sql",
        timeo => 30,
    );

    diag("[$nodes->[0]] mysqldump: $nodes->[0]:/var/lib/gms/");

    foreach my $node (@{$nodes})
    {
        ssh_cmd(
            addr  => $node,
            cmd   => 'ctdb ip > /tmp/ctdb.status',
            timeo => 30,
        );

        ssh_cmd(
            addr  => $node,
            cmd   => 'ctdb status >> /tmp/ctdb.status',
            timeo => 30,
        );

        diag("[$node] CTDB IP/Status: /tmp/ctdb.status");

        ssh_cmd(
            addr  => $node,
            cmd   => 'gluster volume status > /tmp/gluster.status',
            timeo => 30,
        );

        diag("[$node] gluster volume status > /tmp/gluster.status");

        ssh_cmd(
            addr  => $node,
            cmd   => 'ps -aux > /tmp/ps.aux',
            timeo => 30,
        );

        diag("[$node] ps aux > /tmp/ps.aux");

        my @journal_targets = (

            #'gms',
            #'girasole-hub',
            #'girasole-publisher',
            #'girasole-notifier',
        );

        foreach my $target (@journal_targets)
        {
            ssh_cmd(
                addr  => $node,
                cmd   => "journalctl -u $target > /tmp/$target.log",
                timeo => 30,
            );

            diag("[$node] journalctl -u $target > /tmp/$target.log");
        }
    }

    foreach my $node (@{$nodes})
    {
        do_archive(
            srcip    => $node,
            destip   => $ENV{ARCHIVE_IP},
            destpath => "$ENV{ARCHIVE_ROOT}/$job_name/$build_number/$path",
            target   => 'node',
        );
    }

    note(
        sprintf(
            "Log: http://%s/jenkins_log/%s/%s\n\n",
            $ENV{ARCHIVE_IP}, $job_name, $build_number
        )
    );
}

sub do_archive
{
    my $self = (ref($_[0]) ? shift : undef);
    my %args = @_;

    my $target = $args{target};
    $target = 'all' if (!defined($target));

    if ($target !~ /all|node|profile/)
    {
        warn "[ERR] Invalid target: $target";
        return -1;
    }

    foreach my $key (qw/destip destpath/)
    {
        if (!defined($args{$key}))
        {
            warn "[ERR] Invalid parameter: $key";
            return -1;
        }
    }

    my $retval  = 0;
    my $tmpdir  = "/tmp/$ENV{JOB_NAME}-$ENV{BUILD_NUMBER}";
    my $nodedir = "$tmpdir/$args{srcip}";

    # 기존의 아티팩트가 있다면 삭제
    if (-e $tmpdir)
    {
        my $cmd = "rm -rf $tmpdir";

        if (system($cmd))
        {
            warn "[ERR] Failed to delete '$tmpdir': $cmd";
            return -1;
        }
    }

    my @tmp_targets = (

        #'ctdb.status',
        #'gluster.status',
        #'ps.aux',
        #'gms.log',
        #'girasole-hub.log',
        #'girasole-publisher.log',
        #'girasole-notifier.log',
    );

    if ($target =~ /^(?:all|node)$/)
    {
        if (!defined($args{srcip}))
        {
            warn "[ERR] Not passed require parameter: srcip";
            return -1;
        }

        # /tmp 아래의 아티팩트들을 복사
        foreach my $t (@tmp_targets)
        {
            $retval = scp_get_r(
                srcip    => $args{srcip},
                srcpath  => "/tmp/$t",
                destpath => "$tmpdir/$args{srcip}",
            );
        }

        # /var/lib/gms 복사
        $retval = scp_get_r(
            srcip    => $args{srcip},
            srcpath  => '/var/lib/gms',
            destpath => "$tmpdir/$args{srcip}",
        );

        if ($retval)
        {
            warn "[ERR] Failed to get '/var/lib/gms'";
        }

        # /var/lib/gms 복사
        $retval = scp_get_r(
            srcip    => $args{srcip},
            srcpath  => '/var/lib/gms',
            destpath => "$tmpdir/$args{srcip}",
        );

        if ($retval)
        {
            warn "[ERR] Failed to get '/var/lib/gms'";
        }

        # /var/lib/gms 복사
        $retval = scp_get_r(
            srcip    => $args{srcip},
            srcpath  => '/var/lib/gms',
            destpath => "$tmpdir/$args{srcip}",
        );

        if ($retval)
        {
            warn "[ERR] Failed to get '/var/lib/gms'";
        }

        # /var/lib/glusterd 복사
        $retval = scp_get_r(
            srcip    => $args{srcip},
            srcpath  => '/var/lib/glusterd',
            destpath => "$tmpdir/$args{srcip}",
        );

        if ($retval)
        {
            warn "[ERR] Failed to get '/var/lib/gms'";
        }

        # /var/log 복사
        $retval = scp_get_r(
            srcip    => $args{srcip},
            srcpath  => '/var/log',
            destpath => "$tmpdir/$args{srcip}",
        );

        if ($retval)
        {
            warn "[ERR] Failed to get '/var/log'";
        }

        # /mnt/private 복사
        $retval = scp_get_r(
            srcip    => $args{srcip},
            srcpath  => '/mnt/private',
            destpath => "$tmpdir/$args{srcip}",
        );

        if ($retval)
        {
            warn "[ERR] Failed to get '/mnt/private'";
        }

        $retval = `cp -af "$tmpdir/$args{srcip}" "$args{destpath}"`;

        if ($?)
        {
            warn "[ERR] Failed to copy node artifacts"
                . ": $tmpdir/$args{srcip} => $args{destpath}: $!: $retval";

            return -1;
        }
    }

    if ($target =~ /^(?:all|profile)$/)
    {
        $retval = scp_get_r(
            srcip    => '127.0.0.1',
            srcpath  => '/tmp/profile',
            destpath => $tmpdir,
        );

        if ($retval)
        {
            warn "[ERR] Failed to get '/tmp/profile'";
        }

        $retval = `cp -af "$tmpdir/profile" "$args{destpath}"`;

        if ($?)
        {
            warn "[ERR] Failed to put profile artifacts"
                . ": $tmpdir => $args{destpath}: $!: $retval";

            return -1;
        }
    }

    $retval = `chmod -R 755 "$args{destpath}"`;

    if ($?)
    {
        warn "[ERR] Failed to chmod: $args{destpath}: $!: $retval";
    }

    # 임시 디렉토리 삭제
    if (-e $tmpdir)
    {
        my $cmd = "rm -rf $tmpdir";

        if (system($cmd))
        {
            warn "[ERR] Failed to delete '$tmpdir': $cmd";
        }
    }

    return 0;
}

# add log painter driver by hgichon 2016/07/08

sub paint_info_l
{
    print color('blue');
    print STDERR color('blue');
}

sub paint_info
{
    print color('bold blue');
    print STDERR color('bold blue');
}

sub paint_warn_l
{
    print color('yellow');
    print STDERR color('yellow');
}

sub paint_warn
{
    print color('bold yellow');
    print STDERR color('bold yellow');
}

sub paint_err_l
{
    print color('red');
    print STDERR color('red');
}

sub paint_err
{
    print color('bold red');
    print STDERR color('bold red');
}

sub paint_reset
{
    print color('reset');
}

sub p_printf
{
    paint_info;
    printf(@_);
    paint_reset;
}

sub p_e_printf
{
    paint_err;
    printf(STDERR @_);
    paint_reset;
}

sub p_w_printf
{
    paint_warn;
    printf(STDERR @_);
    paint_reset;
}

sub p_warn
{
    paint_err;
    warn(sprintf(@_));
    paint_reset;
}

sub info_diag
{
    my $self = shift;

    paint_info;
    diag(@_);
    paint_reset;
}

sub err_diag
{
    my $self = shift;

    paint_err;
    diag(@_);
    paint_reset;
}

sub warn_diag
{
    my $self = shift;

    paint_warn;
    diag(@_);
    paint_reset;
}

sub call_system
{
    my ($str) = @_;

    my $output = `$str`;

    if ($? == -1)
    {
        paint_err;
        warn sprintf("Failed to execute: %s: %s", $str, $output);
        paint_reset;
        return -1;
    }
    elsif ($? >> 8)
    {
        paint_err;
        warn sprintf(
            "Command %s exited with the status '%d': %s",
            $str,
            $? >> 8,
            $output
        );
        paint_reset;
        return -1;
    }

    return 0;
}

sub get_ts_from_server
{
    my $self = shift;

    $self->x->get_ok("http://${\$self->addr}");

    return get_ts_from_tx($self->x->tx);
}

sub hires_timestamp
{
    my $self = shift;

#    my @tmp = split /:/, $self->addr;
#    my $ipaddr = $tmp[0];
#    my ($time, undef) = ssh_cmd(addr => $ipaddr, cmd => 'date +%s');
#    return $time;
    return Time::HiRes::time;
}

sub hostname
{
    my $self = shift;

    my ($hostname, undef) = ssh_cmd(
        addr => (split(/:/, $self->addr))[0],
        cmd  => 'hostname'
    );

    return $hostname;
}

# Function : call_rest_api
# Input
#     uri      : string  : ex) cluster/volume/list
#     api_args : HASH    : arguments
#     entity   : HASH    : entity
#     ext_args : HASH    : debug/skip trigger
#     params   : HASH    : parameter for v3 API which alternative arguments,
#                          entity.
#
sub call_rest_api
{
    my $self = shift;
    my @args = @_;

    my ($uri, $api_args, $entity, $ext_args, $params) = @args;

    my $target = $ext_args->{target}        // $self->addr;
    my $ignore = $ext_args->{ignore_return} // 0;
    my $expected
        = (exists($ext_args->{expected_return}))
        ? $ext_args->{expected_return}
        : 1;
    my $http_status
        = (exists($ext_args->{http_status}))
        ? $ext_args->{http_status}
        : 200;

    $uri =~ s/^\///;

    my $start = $self->get_ts_from_server();

    my %headers;

    $headers{Authorization} = "Bearer ${\$self->api_token}"
        if (defined($self->api_token));

    my $body;

    if ($params)
    {
        $body = $params;
    }
    else
    {
        $body->{arguments} = $api_args if ($api_args);
        $body->{entity}    = $entity   if ($entity);
    }

    $self->t->post_ok("http://$target/api/$uri", \%headers, json => $body);

    my $tx  = $self->t->tx;
    my $res = $tx->res->json;

    my $end = $self->get_ts_from_server();

    # 'undef' used for don't care flag
    if (defined($http_status))
    {
        cmp_ok($tx->res->code, '==', $http_status,
            sprintf('HTTP status is %s', $tx->res->code // 'undef'));
    }

    # profiling start
    my $class_name = '';

    for (my $i = 0; $i < 10; $i++)
    {
        my $caller = (caller($i))[1];

        next
            if (!defined($caller)
            || ($caller !~ /\.t$/ && $caller !~ /gms-tester/));

        $class_name = File::Basename::basename($caller);
        $class_name .= '/';
        $class_name .= File::Basename::basename((caller($i - 1))[1]);

        last;
    }

    my %j_data = (
        name      => $uri,
        classname => $class_name,
        time      => $end - $start,
    );

    $start = int($start);
    $end   = int($end);

    $res->{prof}->{from} = $start;
    $res->{prof}->{to}   = $end;

    # profiling end

    my $t_duration = $self->junit_duration + $j_data{time};

    $self->junit_duration($t_duration);

    my $logfile = sprintf(
        "Log: http://192.168.3.4/jenkins_log/%s/%s\n",
        $ENV{JOB_NAME}     // 'undef',
        $ENV{BUILD_NUMBER} // 'undef'
    );

    goto RETURN if ($ignore =~ m/^(1|true|yes)$/i);

    if (defined($http_status)
        && ($http_status != 200 || !defined($res->{success})))
    {
        diag("HTTP error: ${\Dumper($tx->res->error)}");

        $j_data{error}->{message} = 'HTTP Error';
        $j_data{error}->{type}    = 'ERROR';
    }
    elsif (defined($expected) && $res->{success} != $expected)
    {
        diag("Response error: ${\Dumper($res)}");

        $j_data{error}->{message} = $res->{msg};
        $j_data{error}->{type}    = 'ERROR';
    }

    if (exists($j_data{error}))
    {
        $j_data{error}->{CONTENT} = $logfile;
        $j_data{error}->{CONTENT}
            .= sprintf("argument :\n%s", Dumper($api_args));
        $j_data{error}->{CONTENT}
            .= sprintf("entity :\n%s", Dumper($entity));
        $j_data{error}->{CONTENT}
            .= sprintf("ext_arg :\n%s", Dumper($ext_args));
        $j_data{error}->{CONTENT}
            .= sprintf("return :\n%s", Dumper($res));
    }

RETURN:
    push(@{$self->junit_data}, \%j_data);

    return $res;
}

sub request
{
    my $self = shift;
    my %args = @_;

    my $uri     = $args{uri};
    my $headers = $args{headers};
    my $params  = $args{params};

    if (!exists($args{http_status}))
    {
        $args{http_status} = 200;
    }

    my $ext_args = {
        target          => $args{target},
        ignore_return   => $args{ignore},
        expected_return => $args{expected},
        http_status     => $args{http_status},
    };

    return $self->call_rest_api($uri, undef, undef, $ext_args, $params);
}

sub get_ts_from_tx
{
    my $tx = shift;

    my $date    = $tx->res->headers->{headers}->{date}->[0];
    my $pattern = '%a, %d %b %Y %T %Z';
    my $parser  = DateTime::Format::Strptime->new(pattern => $pattern);

    return $parser->parse_datetime($date)->epoch;
}

#---------------------------------------------------------------------------
#   Lifecycle
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->t->ua->request_timeout(600);
    $self->t->ua->connect_timeout(600);
    $self->t->ua->inactivity_timeout(600);
    $self->t->ua->max_connections(100);

    $self->login() if (!$self->no_login);

    $self->get_nodes(
        http_status     => undef,
        expected_return => undef,
    );

    return;
}

sub DEMOLISH
{
    my $self     = shift;
    my $isglobal = shift;
    my $XML;

    # Initializing Junit report
    #
    if (!-e $self->junit_result)
    {
        $XML = XML::Smart->new();
        $XML->{testsuite} = {
            failures => '0',
            name     => 'CI',
            package  => 'Jenkins',
            tests    => '0',
            time     => $self->junit_duration,
        };
    }
    else
    {
        $XML = XML::Smart->new($self->junit_result);
        $XML->{testsuite}->{time} += $self->junit_duration;
    }

    foreach my $junit (@{$self->junit_data})
    {
        push(@{$XML->{testsuite}->{testcase}}, $junit);
        $XML->{testsuite}->{tests}++;
    }

    $XML->save($self->junit_result);

    return if ($self->no_login || $self->no_logout);

    $self->logout();

    return if ($self->no_complete);

    done_testing();

    return;
}

1;

=encoding utf8

=head1 NAME

Test::AnyStor::Base - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

