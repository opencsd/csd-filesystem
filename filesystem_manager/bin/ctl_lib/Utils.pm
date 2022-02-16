#-----------------------------------------------------------------------------
#   logging library for plugdisk cli
#-----------------------------------------------------------------------------

sub __call_rest_api
{
    my ($uri, $input, $timeout, $noprint) = @_;

    $noprint = $noprint // 0;

    my $res = run_gms_ua_post(GMS_API_SERVER, $uri, $input, $timeout);

    if ($res->{return} ne 'true')
    {
        if (defined $res->{msg})
        {
            print_log(LOG_ERR, "[$uri]failed: $res->{msg}\n");
        }
        elsif (defined $res->{res}->{error}->{message})
        {
            print_log(LOG_ERR,
                "[$uri]failed: $res->{res}->{error}->{message}\n");
        }
        else
        {
            print_log(LOG_ERR, "[$uri]failed:\n" . Dumper($res));
        }

        return;
    }
    else
    {
        print_log(LOG_INFO, "[$uri] success:$res->{msg}\n", $noprint);
    }

    return $res;
}

sub setup_log
{
    my $LOGFH;

    # :TODO 2018년 03월 29일 00시 30분 09초: by P.G.
    #
    # We need to make base directory of $OPTS{LOGFILE}
    if (!open($LOGFH, '>>', $OPTS{LOGFILE}))
    {
        print STDERR "Failed to open log file: $OPTS{LOGFILE}: $!\n";
        exit 255;
    }

    catch_sig_warn(
        datetime => 1,
        procname => 1,
        pid      => 1,
        level    => 1,
        filename => 0,
        linenum  => 0,
        stdout   => [$LOGFH],
        stderr   => [$LOGFH],
    );

    logmask(LOG_INFO);

    if ($OPTS{DEBUG})
    {
        catch_sig_warn(
            mask     => LOG_DEBUG,
            filename => 1,
            linenum  => 1,
        );

        print_log(LOG_DEBUG, "Debug mode is enabled\n");
    }
}

sub print_log
{
    my ($level, $msg, $noterm);

    if (@_ == 1)
    {
        $level = LOG_INFO;
        $msg   = shift;
    }
    else
    {
        ($level, $msg, $noterm) = @_;
    }

    $noterm //= 0;

    $|++;

    if ($level <= LOG_ERR)
    {
        $level = LOG_ERR;

        print STDERR "[ERR] $msg" if (!$noterm);
    }
    elsif ($level == LOG_WARNING)
    {
        $level = LOG_WARNING;

        print STDOUT "[WARN] $msg" if (!$noterm);
    }
    elsif ($level == LOG_INFO)
    {
        $level = LOG_INFO;

        print STDOUT "[INFO] $msg" if (!$noterm);
    }
    else
    {
        $level = LOG_DEBUG;

        print STDERR "[DEBUG] $msg" if (!$noterm && $OPTS{DEBUG});
    }

    my ($file, $line, $category);

    if (1)
    {
        my @caller = caller(0);

        if (@caller && defined($caller[1]))
        {
            ($file, $line) = @caller[1 .. 2];

            foreach my $inc (@INC)
            {
                next unless ($file =~ m/^$inc\/(.+)$/);

                $file = $1;

                next unless ($file =~ m/^([^\/]+)/);

                $category = $1;

                last;
            }
        }
    }

    foreach my $m (split(/\n+/, $msg))
    {
        logging($level, undef, 1, $m, 1 ? $file : undef, 1 ? $line : undef);
    }

    return;
}

1;
