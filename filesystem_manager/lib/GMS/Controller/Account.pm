package GMS::Controller::Account;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use File::Path qw/make_path/;
use Guard;
use JSON qw/decode_json/;

use GMS::Account::AccountCtl;
use GMS::Auth::PAM::PWQuality;

#---------------------------------------------------------------------------
#   Inheritances
#---------------------------------------------------------------------------
extends 'GMS::Controller';

#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'ctl' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Account::AccountCtl->new(); },
);

has 'pwquality' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub { GMS::Auth::PAM::PWQuality->new(); },
);

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub conv_post_parm
{
    my $self = shift;
    my %args = @_;

    my $post = $self->req->params->to_hash;

    return if (ref($post) ne 'HASH');

    my $filter;

    foreach my $key (keys(%{$post}))
    {
        given ($key)
        {
            when ('page')
            {
                ${$args{params}}->{argument}->{PageNumber} = $post->{$key};
            }
            when ('limit')
            {
                ${$args{params}}->{argument}->{NumOfRecords} = $post->{$key};
            }
            when ('sort')
            {
                my $sorters = decode_json($post->{$key});

                foreach my $s (@{$sorters})
                {
                    ${$args{params}}->{argument}->{SortType}
                        = $s->{direction};
                    ${$args{params}}->{argument}->{SortField}
                        = $s->{property};
                }
            }
            when ('LocationType')
            {
                ${$args{params}}->{argument}->{Location} = $post->{$key};
            }
            when ('FilterName')
            {
                $filter->{FilterName} = $post->{$key};
            }
            when ('FilterArgs')
            {
                $filter->{FilterArgs} = $post->{$key};
            }
            when ('MatchType')
            {
                $filter->{MatchType} = $post->{$key};
            }
            default
            {
                warn "[WARN] Unknown parameter: $key: $post->{$key}";
            }
        }
    }

    if (exists($filter->{FilterName}) && exists($filter->{FilterArgs}))
    {
        push(@{${$args{params}}->{argument}->{Filters}}, $filter);
    }

    if (exists($post->{TempName}) && $filter->{FilterName} ne 'MemberOf')
    {
        push(
            @{${$args{params}}->{argument}->{Filters}},
            {
                FilterName => 'MemberOf',
                FilterArgs => $post->{TempName},
                MatchType  => $filter->{MatchType},
            }
        );
    }

    return;
}

sub user_count
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->conv_post_parm(params => \$params);

    my $result = $self->ctl->user_count(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub user_list
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->conv_post_parm(params => \$params);

    my $result = $self->ctl->user_list(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result, count => int(scalar(@{$result})));
}

sub user_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->user_info(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub user_create
{
    my $self   = shift;
    my $params = $self->req->json;

    if (defined($params->{entity}->{User_Password})
        && $params->{entity}->{User_Password} ne '')
    {
        $params->{entity}->{User_Password}
            = $self->rsa_decrypt(data => $params->{entity}->{User_Password});

        if ($self->pwquality->is_valid_passwd(
            passwd => $params->{entity}->{User_Password}
        ))
        {
            $self->throw_error(
                'Password is not satisified with pwquality policy');
        }
    }

    $self->gms_lock(scope => '/Account/User');

    scope_guard { $self->gms_unlock(scope => '/Account/User'); };

    my $result = $self->ctl->user_create(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->publish_event();

    $self->stash(json => $result);

    return $result;
}

sub user_update
{
    my $self   = shift;
    my $params = $self->req->json;

    if (defined($params->{entity}->{User_Password})
        && $params->{entity}->{User_Password} ne '')
    {
        $params->{entity}->{User_Password}
            = $self->rsa_decrypt(data => $params->{entity}->{User_Password});

        if ($self->pwquality->is_valid_passwd(
            passwd => $params->{entity}->{User_Password}
        ))
        {
            $self->throw_error(
                'Password is not satisified with pwquality policy');
        }
    }

    $self->gms_lock(scope => '/Account/User');

    scope_guard { $self->gms_unlock(scope => '/Account/User'); };

    my $result = $self->ctl->user_update(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->publish_event();

    $self->stash(json => $result);

    return $result;
}

sub user_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    # :TODO Wed Apr 14 02:27:07 PM KST 2021
    # we should prohibit the deletion of manager account ASAP.

    $self->gms_lock(scope => '/Account/User');

    scope_guard { $self->gms_unlock(scope => '/Account/User'); };

    my $result = $self->ctl->user_delete(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->publish_event();

    $self->stash(json => $result);

    return $result;
}

sub group_count
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->conv_post_parm(params => \$params);

    my $result = $self->ctl->group_count(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub group_list
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->conv_post_parm(params => \$params);

    my $count = $self->ctl->group_count(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    my $result = $self->ctl->group_list(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result, count => $count->{NumOfGroups} // 0);
}

sub group_info
{
    my $self   = shift;
    my $params = $self->req->json;

    my $result = $self->ctl->group_info(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->render(json => $result);
}

sub group_create
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => '/Account/Group');

    scope_guard { $self->gms_unlock(scope => '/Account/Group'); };

    my $result = $self->ctl->group_create(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->publish_event();

    $self->stash(json => $result);

    return $result;
}

sub group_update
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => '/Account/Group');

    scope_guard { $self->gms_unlock(scope => '/Account/Group'); };

    my $result = $self->ctl->group_update(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->publish_event();

    $self->stash(json => $result);

    return $result;
}

sub group_delete
{
    my $self   = shift;
    my $params = $self->req->json;

    $self->gms_lock(scope => '/Account/Group');

    scope_guard { $self->gms_unlock(scope => '/Account/Group'); };

    my $result = $self->ctl->group_delete(
        argument => $params->{argument},
        entity   => $params->{entity}
    );

    $self->publish_event();

    $self->stash(json => $result);

    return $result;
}

__PACKAGE__->meta->make_immutable();
1;

=encoding utf8

=head1 NAME

GMS::Controller::Account - Account management API controller for GMS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut

