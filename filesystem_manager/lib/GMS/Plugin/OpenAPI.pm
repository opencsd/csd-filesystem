package GMS::Plugin::OpenAPI;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use File::Basename;
use File::Find;
use File::Temp qw(tempfile);
use YAML qw(LoadFile Dump);

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Plugin';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'spec' => (
    is     => 'ro',
    isa    => 'HashRef',
    writer => 'set_spec',
);

has 'app' => (
    is     => 'ro',
    isa    => 'Object',
    writer => 'set_app',
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub register
{
    my ($self, $app, $args) = @_;

    $self->set_app($app);

    $app->helper(gen_tags => sub { shift; $self->gen_tags(shift); });
    $app->helper(
        gen_components => sub { shift; $self->gen_components(shift); });
    $app->helper(gen_paths  => sub { shift; $self->gen_paths(shift); });
    $app->helper(write_spec => sub { shift; $self->write_spec(); });

    my $spec_dir = $args->{spec_dir};

    if (!defined($spec_dir))
    {
        $spec_dir = sprintf('%s/public/api', $app->home);
    }

    $self->set_spec(LoadFile("$spec_dir/openapi.yaml"));
    $self->gen_tags("$spec_dir/tags");
    $self->gen_components("$spec_dir/components");
    $self->gen_paths("$spec_dir/paths");

    return;
}

sub gen_tags
{
    my $self = shift;
    my $path = shift;

    if (!-d $path)
    {
        die "Failed to access: $path: $!";
    }

    find(
        {
            wanted => sub
            {
                return if ($File::Find::name !~ m/.yaml$/);

                (my $name = basename($File::Find::name)) =~ s/\..+$//;

                return if ($name =~ m/^[\._]/);

                warn "[DEBUG] Trying to loading $File::Find::name...";

                my $yaml = LoadFile($File::Find::name);

                push(@{$self->spec->{tags}}, $yaml);
            },
            no_chdir => 1,
        },
        $path
    );
}

sub gen_components
{
    my $self = shift;
    my $path = shift;

    if (!-d $path)
    {
        die "Failed to access: $path: $!";
    }

    foreach my $comp_name (qw(schemas parameters requestBody responses))
    {
        next if (!-d "$path/$comp_name");

        find(
            {
                wanted => sub
                {
                    return if ($File::Find::name !~ m/.yaml$/);

                    (my $name = basename($File::Find::name)) =~ s/\..+$//;

                    return if ($name =~ m/^[\._]/);

                    warn "[DEBUG] Trying to loading $File::Find::name...";

                    my $yaml = LoadFile($File::Find::name);

                    $self->spec->{components}->{$comp_name}->{$name} = $yaml;
                },
                no_chdir => 1,
            },
            "$path/$comp_name"
        );
    }
}

sub gen_paths
{
    my $self = shift;
    my $path = shift;

    if (!-d $path)
    {
        die "Failed to access: $path: $!";
    }

    find(
        {
            wanted => sub
            {
                return if ($File::Find::name !~ m/.yaml$/);

                (my $name = basename($File::Find::name)) =~ s/\..+$//;

                return if ($name =~ m/^[\._]/);

                warn "[DEBUG] Trying to loading $File::Find::name...";

                my $yaml = LoadFile($File::Find::name);

                (my $uri = $File::Find::name) =~ s|^/.+/api/paths/||g;
                $uri =~ s/\..+$//;

                $self->spec->{paths}->{"/$uri"} = $yaml;
            },
            no_chdir => 1,
        },
        $path
    );
}

sub write_spec
{
    my $self = shift;

    local $YAML::SortKeys
        = ['openapi', 'info', 'servers', 'components', 'security', 'paths',];

    # tricky
    (my $spec = Dump($self->spec)) =~ s/"(\$ref:\s*.+)"/$1/g;
    $spec =~ s/version:\s*([0-9\.]+)/version: '$1'/g;

    my ($fh, $filename) = tempfile(
        'gms-openapi_XXXXX',
        TMPDIR => 1,
        SUFFIX => '.spec',
    );

    print $fh $spec;

    close($fh);

    $self->app->routes->any(
        '/api/v3' => sub { shift->render(json => $self->spec); });

    return $filename;
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Plugin::OpenAPI - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

