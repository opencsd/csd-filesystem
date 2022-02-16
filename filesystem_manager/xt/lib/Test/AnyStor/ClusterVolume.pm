package Test::AnyStor::ClusterVolume;

use v5.14;

use strict;
use warnings;
use utf8;

our $AUTHORITY = 'cpan:gluesys';

use Mouse;
use namespace::clean -except => 'meta';

use Test::Most;
use Mojo::UserAgent;
use JSON qw/from_json decode_json/;

extends 'Test::AnyStor::Base';

#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_list
#        BRIEF: Distribute 클러스터 볼륨 생성
#   PARAMETERS: {
#                   volname   => 'volume_name',  # option
#               }
#      RETURNS: {
#                   key => value,
#               }
#
#=============================================================================
sub volume_list
{
    my $self = shift;
    my %args = @_;

    my %payload = (
        Pool_Type   => 'Gluster',
        Volume_Name => $args{volname} // undef
    );

    if (defined($args{pooltype}))
    {
        $payload{Pool_Type} = $args{pooltype};
    }

    $self->request(
        uri    => '/cluster/volume/list',
        params => {
            argument => \%payload,
        }
    );

    my $res = $self->t->tx->res->json;

    if ($res->{stage_info}->{stage} ne 'running')
    {
        diag(explain($res));
    }

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: brick_list
#        BRIEF:
#   PARAMETERS: {
#                   volname   => 'volume_name',  # option
#               }
#      RETURNS:
#
#=============================================================================
sub brick_list
{
    my $self = shift;
    my %args = @_;

    $self->request(
        uri    => '/cluster/volume/brick/list',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $args{volname} // undef,
            }
        }
    );

    my $res = $self->t->tx->res->json;

    if ($res->{stage_info}->{stage} ne 'running')
    {
        diag(explain($res));
    }

    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_create_distribute
#        BRIEF: Distribute 클러스터 볼륨 생성
#   PARAMETERS: {
#                   volname    => 'volume_name',  # option
#                   node_count => 1,
#                   replica    => 1,
#                   capacity   => '1G'
#                   node_list  => [ $stgip1 ] # option
#                   voltype    => 'thin' or 'thick'
#               }
#      RETURNS: 'volume_name'
#
#=============================================================================
sub volume_create_distribute
{
    my $self = shift;
    my %args = @_;

    my $capacity         = $args{capacity}   // '1G';
    my $node_count       = $args{node_count} // 1;
    my $replica          = $args{replica}    // 1;
    my $volname          = $args{volname}    // 'ac2_dist';
    my $node_list        = $args{node_list}  // [];
    my $pool_name        = $args{pool_name}  // 'vg_cluster';
    my $chaining         = $args{chaining}   // 'false';
    my $shard            = $args{shard}      // 'false';
    my $shard_block_size = $args{shard_block_size};
    my $provision        = $args{provision} // 'thick';
    my $expected         = $args{expected}  // {success => 1};

    if (!scalar(@{$node_list}))
    {
        foreach my $idx (1 .. $node_count)
        {
            push(@{$node_list}, $self->nodes->[$idx - 1]->{Storage_IP}->{ip});
        }
    }

    my $res = $self->request(
        uri    => '/cluster/volume/create',
        params => {
            argument => {
                Pool_Name        => $pool_name,
                Pool_Type        => 'Gluster',
                Volume_Name      => $volname,
                Volume_Policy    => {Distributed => 'true'},
                Replica          => $replica,
                Node_List        => $node_list,
                Transport_Type   => 'tcp',
                Capacity         => $capacity,
                Chaining         => $chaining,
                Shard            => $shard,
                Shard_Block_Size => $shard_block_size,
                Provision        => $provision,
            }
        },
        expected => $expected->{success},
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME',
        prefix   => 'CLST_VOLUME_CREATE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $volname;

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_create_stripe
#        BRIEF: Stripe 클러스터 볼륨 생성
#   PARAMETERS: {
#                   voltype   => 'thin' or 'thick'
#                   node_count => 1,
#                   replica    => 1
#               }
#      RETURNS: 'volume_name' or undef
#
#=============================================================================
sub volume_create_stripe
{
    my $self = shift;
    my %args = @_;

    my $capacity   = $args{capacity}   // '1G';
    my $replica    = $args{replica}    // 1;
    my $node_count = $args{node_count} // 2;
    my $stripe     = int($args{node_count} / $args{replica});
    my $volname    = $args{volname}   // "ac2_dist_${node_count}_${replica}";
    my $node_list  = $args{node_list} // [];
    my $pool_name  = $args{pool_name} // 'vg_cluster';
    my $provision  = $args{provision} // 'thick';
    my $expected   = $args{expected}  // {success => 1};

    if ($stripe < 2)
    {
        diag('You need more nodes to create stripe volume');
        return;
    }

    if (!scalar(@{$node_list}))
    {
        foreach my $idx (1 .. $node_count * $replica)
        {
            push(@{$node_list}, $self->nodes->[$idx - 1]->{Storage_IP}->{ip});
        }
    }

    my $res = $self->request(
        uri    => '/cluster/volume/create',
        params => {
            argument => {
                Pool_Type      => 'Gluster',
                Volume_Name    => $volname,
                Pool_Name      => $pool_name,
                Volume_Policy  => {Striped => 'true'},
                Replica        => $replica,
                Node_List      => $node_list,
                Transport_Type => 'tcp',
                Capacity       => $capacity,
                Provision      => $provision,
            }
        },
        expected => $expected->{success},
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME',
        prefix   => 'CLST_VOLUME_CREATE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $volname;

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_create_networkraid
#        BRIEF: Network Raid 클러스터 볼륨 생성
#   PARAMETERS: {
#                   voltype   => 'thin' or 'thick'
#                   node_count => 1,
#                   code_count => 1
#               }
#      RETURNS: 'volume_name' or undef
#
#=============================================================================
sub volume_create_networkraid
{
    my $self = shift;
    my %args = @_;

    my $capacity   = $args{capacity}   // '1G';
    my $node_count = $args{node_count} // 3;
    my $code_count = $args{code_count} // 1;
    my $volname    = $args{volname} // "ac2_dist_${node_count}_${code_count}";
    my $node_list  = $args{node_list} // [];
    my $pool_name  = $args{pool_name} // 'vg_cluster';
    my $provision  = $args{provision} // 'thick';
    my $expected   = $args{expected}  // {success => 1};

    if ($node_count < 3)
    {
        diag('Network raid volume need more nodes to be created');
        return;
    }

    if (!scalar(@{$node_list}))
    {
        foreach my $idx (1 .. $node_count)
        {
            push(@{$node_list}, $self->nodes->[$idx - 1]->{Storage_IP}->{ip});
        }
    }

    my $res = $self->request(
        uri    => '/cluster/volume/create',
        params => {
            argument => {
                Pool_Type      => 'Gluster',
                Volume_Name    => $volname,
                Pool_Name      => $pool_name,
                Volume_Policy  => {NetworkRAID => $code_count},
                Replica        => 1,
                Node_List      => $node_list,
                Transport_Type => 'tcp',
                Capacity       => $capacity,
                Provision      => $provision,
            }
        },
        expected => $expected->{success},
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME',
        prefix   => 'CLST_VOLUME_CREATE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $volname;

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_delete
#        BRIEF: 클러스터 볼륨을 삭제
#   PARAMETERS: {
#                   volname => 'volume_name',
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_delete
{
    my $self = shift;
    my %args = @_;

    my $pool_name = $args{pool_name} // 'vg_cluster';
    my $volname   = $args{volname};
    my $expected  = $args{expected} // {dryrun => 1, success => 1};

    my $res = $self->request(
        uri    => '/cluster/volume/delete',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Pool_Name   => $pool_name,
                Volume_Name => $volname,
                Reason      => 'To test functionality',
                Password    => $args{password} // 'admin',
                Dry         => 'true'
            }
        },
        expected => $expected->{dryrun},
    );

    if ($res->{success} != $expected->{dryrun})
    {
        diag(
            sprintf(
                'API return is not "%s" or stage is not "running": %s/%s',
                $expected->{dryrun},
                $res->{success},
                $res->{stage_info}->{stage}
            )
        );

        diag(explain($res));

        return -1;
    }

    if ($res->{entity}->[0]->{is_possible} eq 'false')
    {
        diag(explain($res));

        diag("$volname cannot be deleted: $res->{entity}->[0]->{msg}");

        return -1;
    }

    $res = $self->request(
        uri    => '/cluster/volume/delete',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Pool_Name   => $pool_name,
                Volume_Name => $volname,
                Reason      => 'To test functionality',
                Password    => $args{password} // 'admin',
            },
        },
        expected => $expected->{success},
    );

    if ($res->{success} != $expected->{success}
        || $res->{stage_info}->{stage} ne 'running')
    {
        diag(
            sprintf(
                'API return is not "%s" or stage is not "running": %s/%s',
                $expected->{success},
                $res->{success},
                $res->{stage_info}->{stage}
            )
        );

        diag(explain($res));

        return -1;
    }

    $self->check_api_code_in_recent_events(
        category => 'VOLUME',
        prefix   => 'CLST_VOLUME_DELETE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return 0;
}

sub is_bad_res
{
    my $self = shift;
    my %args = @_;

    return (!$self->t->success
            || $args{res}->{return} ne 'true'
            || $args{res}->{stage_info}->{stage} ne 'running');
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_set_config
#        BRIEF: 클러스터 볼륨에 옵션 적용
#   PARAMETERS: {
#                   volname   => 'volume_name',
#                   option    => 'option',
#                   parameter => 'value'
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_set_config
{
    my $self = shift;
    my %args = @_;

    my $volname   = $args{volname};
    my $option    = $args{option};
    my $parameter = $args{parameter};

    my $res = $self->request(
        uri    => '/cluster/volume/ctlopt',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $volname,
                Option      => $option,
                Parameter   => $parameter,
            }
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    my $opts = $self->volume_get_config(volname => $volname);

    goto ERROR if (!isa_ok($opts, 'HASH'));

    is($opts->{$option}, $parameter, 'Verify option');

    return 0;

ERROR:
    diag(explain($res));
    return -1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_get_config
#        BRIEF: 클러스터 볼륨에 옵션 적용
#   PARAMETERS: {
#                   volname   => 'volume_name'
#                   option    => string | undef
#               }
#      RETURNS: {
#                   'key' => 'value',
#                   'key' => 'value'
#               }
#=============================================================================
sub volume_get_config
{
    my $self = shift;
    my %args = @_;

    my $volname = $args{volname};
    my $option  = $args{option};

    my %payload = (
        Pool_Type   => 'Gluster',
        Volume_Name => $volname,
    );

    $payload{Option} = $option
        if (defined($option) && $option ne '');

    my $res = $self->request(
        uri    => '/cluster/volume/ctlopt',
        params => {
            argument => \%payload,
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_expand
#        BRIEF: 클러스터 볼륨을 확장 (scale-out)
#   PARAMETERS: {
#                   volname   => 'volume_name',
#                   add_count => 2
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_expand
{
    my $self = shift;
    my %args = @_;

    my $volname   = $args{volname};
    my $add_count = $args{add_count};
    my $node_list = $args{node_list} // [];
    my $expected  = $args{expected}  // {dryrun => 1, success => 1};

    my $res = $self->volume_list(volname => $volname);

    if (ref($res) ne 'ARRAY' || scalar(@{$res}) == 0)
    {
        fail('Failed to get the volume infomation');
        return -1;
    }

    my $prev_cnt = scalar(@{$res->[0]->{Node_List}});

    if (!scalar(@{$node_list}))
    {
        for (my $i = 1; $i <= $args{add_cnt}; $i++)
        {
            my $tmp = $prev_cnt + $i;

            push(@{$node_list}, "test-$tmp");
        }
    }

    $res = $self->request(
        uri    => '/cluster/volume/expand',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $volname,
                Dry         => 'true'
            }
        },
        expected => $expected->{dryrun},
    );

    if ($res->{success} != $expected->{dryrun}
        || $res->{stage_info}->{stage} ne 'running')
    {
        diag(
            sprintf(
                'API return is not "%s" or stage is not "running": %s/%s',
                $expected->{dryrun},
                $res->{success},
                $res->{stage_info}->{stage}
            )
        );

        diag(explain($res));

        return -1;
    }

    if ($res->{entity}->[0]->{is_possible} eq 'false')
    {
        diag("$volname cannot be expanded: $res->{entity}->[0]->{msg}");

        diag(explain($res));

        return -1;
    }

    $res = $self->request(
        uri    => '/cluster/volume/expand',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $volname,
                Node_List   => $node_list
            },
        },
        expected => $expected->{success},
    );

    if ($res->{success} != $expected->{success}
        || $res->{stage_info}->{stage} ne 'running')
    {
        diag(
            sprintf(
                'API return is not "%s" or stage is not "running": %s/%s',
                $expected->{success},
                $res->{success},
                $res->{stage_info}->{stage}
            )
        );

        diag(explain($res));

        return -1;
    }

    $self->check_api_code_in_recent_events(
        category => 'VOLUME',
        prefix   => 'CLST_VOLUME_EXPAND_',
        from     => $$res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return 0;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_extend
#        BRIEF: 클러스터 볼륨을 확장 (scale-in)
#   PARAMETERS: {
#                   volname   => 'volume_name',
#                   extendsize => 2G
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_extend
{
    my $self = shift;
    my %args = @_;

    my $expected = $args{expected} // {dryrun => 1, success => 1};

    my $res = $self->request(
        uri    => '/cluster/volume/extend',
        params => {
            argument => {
                Pool_Name   => $args{pool_name} // 'vg_cluster',
                Volume_Name => $args{volname},
                Extend_Size => $args{extendsize},
                Dry         => 'true'
            }
        },
        expected => $expected->{dryrun},
    );

    if ($res->{success} != $expected->{dryrun}
        || $res->{stage_info}->{stage} ne 'running')
    {
        diag(
            sprintf(
                'API return is not "%s" or stage is not "running": %s/%s',
                $expected->{dryrun},
                $res->{success},
                $res->{stage_info}->{stage}
            )
        );
        return -1;
    }

    if ($res->{entity}->[0]->{is_possible} eq 'false')
    {
        diag("$args{volname} cannot be extended: $res->{entity}->[0]->{msg}");
        return -1;
    }

    $res = $self->request(
        uri    => '/cluster/volume/extend',
        params => {
            argument => {
                Pool_Name   => $args{pool_name} // 'vg_cluster',
                Volume_Name => $args{volname},
                Extend_Size => $args{extendsize},
            }
        },
        expected => $expected->{success},
    );

    if ($res->{success} != $expected->{success}
        || $res->{stage_info}->{stage} ne 'running')
    {
        diag(
            sprintf(
                'API return is not "%s" or stage is not "running": %s/%s',
                $expected->{success},
                $res->{success},
                $res->{stage_info}->{stage}
            )
        );
        return -1;
    }

    $self->check_api_code_in_recent_events(
        category => 'VOLUME',
        prefix   => 'CLST_VOLUME_EXTEND_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return 0;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_rebalance
#        BRIEF: 클러스터 볼륨을 rebalance함
#   PARAMETERS: {
#                   volname => 'volume_name',
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_rebalance
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/rebalance',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $args{volname},
                Dry         => 'true'
            }
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    if ($res->{entity}->[0]->{is_possible} eq 'false')
    {
        diag("$args{volname} cannot be rebalanced: $res->{entity}->[0]->{msg}"
        );
        goto ERROR;
    }

    $res = $self->request(
        uri    => '/cluster/volume/rebalance',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $args{volname},
            }
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return 0;

ERROR:
    diag(explain($res));
    return -1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_heal
#        BRIEF: 클러스터 볼륨을 heal(복구)함
#   PARAMETERS: {
#                   volname => 'volume_name',
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_heal
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/heal',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $args{volname},
                Dry         => 'true'
            },
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    if ($res->{entity}->[0]->{is_possible} eq 'false')
    {
        diag("$args{volname} cannot be healed: $res->{entity}->[0]->{msg}");
        return 1;
    }

    $res = $self->request(
        uri    => '/cluster/volume/heal',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $args{volname},
            },
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return 0;

ERROR:
    diag(explain($res));
    return -1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_snapshot_create
#        BRIEF: 클러스터 볼륨의 스냅샷을 생성
#   PARAMETERS: {
#                   volname => 'volume_name',
#                   snapname => 'snapshot_name'
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_snapshot_create
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/snapshot/create',
        params => {
            argument => {
                Pool_Type     => 'Gluster',
                Volume_Name   => $args{volname}  // '',
                Snapshot_Name => $args{snapname} // '',
            }
        }
    );

    diag('Waiting 10 seconds...');
    sleep 10;

    $self->check_api_code_in_recent_events(
        category => 'SNAPSHOT',
        prefix   => 'CLST_SNAPSHOT_CREATE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_snapshot_avail
#        BRIEF: 클러스터 볼륨의 스냅샷 가용수를 출력
#   PARAMETERS: {
#                   volname => 'volume_name'
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_snapshot_avail
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/snapshot/avail',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $args{volname} // '',
            }
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return $res->{entity};

ERROR:
    diag(explain($res));
    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_snapshot_list
#        BRIEF: 클러스터 볼륨의 스냅샷을 반환
#   PARAMETERS: {
#                   volname => 'volume_name', # optional
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_snapshot_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/snapshot/list',
        params => {
            argument => {
                Pool_Type   => 'Gluster',
                Volume_Name => $args{volname} // '',
            },
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return $res->{entity};

ERROR:
    explain(diag($res->{entity}));
    return $res->{entity};
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_snapshot_restore
#        BRIEF: 클러스터 볼륨의 데이터를 스냅샷으로 복구
#   PARAMETERS: {
#                   volname => 'volume_name',
#                   snapname => 'snap_name'
#      RETURNS: {
#               }
#=============================================================================
sub volume_snapshot_restore
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/snapshot/restore',
        params => {
            argument => {
                Pool_Type     => 'Gluster',
                Volume_Name   => $args{volname}  // '',
                Snapshot_Name => $args{snapname} // '',
            },
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return 0;

ERROR:
    diag(explain($res));
    return -1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_snapshot_delete
#        BRIEF: 클러스터 볼륨의 스냅샷을 삭제
#   PARAMETERS: {
#                   volname => 'volume_name',
#                   snapname => 'snap_name'
#      RETURNS: {
#               }
#=============================================================================
sub volume_snapshot_delete
{
    my $self = shift;
    my %args = @_;

    my $volname  = $args{volname}  // '';
    my $snapname = $args{snapname} // '';

    my %payload = (
        Pool_Type   => 'Gluster',
        Volume_Name => $volname,
    );

    $payload{Snapshot_Name} = $snapname if ($snapname ne '');

    my $res = $self->request(
        uri    => '/cluster/volume/snapshot/delete',
        params => {
            argument => \%payload,
        },
    );

    diag('Waiting 10 seconds...');
    sleep 10;

    $self->check_api_code_in_recent_events(
        category => 'SNAPSHOT',
        prefix   => 'CLST_SNAPSHOT_DELETE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return 0;

ERROR:
    diag(explain($res));
    return -1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_snapshot_activate
#        BRIEF: 클러스터 볼륨의 스냅샷을 활성화/비활성화
#   PARAMETERS: {
#                   volname => 'volume_name',
#                   snapname => 'snap_name'
#                   activated = > 'true or false'
#      RETURNS: {
#               }
#=============================================================================
sub volume_snapshot_activate
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/snapshot/activate',
        params => {
            argument => {
                Pool_Type     => 'Gluster',
                Volume_Name   => $args{volname}   // '',
                Snapshot_Name => $args{snapname}  // '',
                Activated     => $args{activated} // 'true',
            },
        }
    );

    diag('Waiting 10 seconds...');
    sleep 10;

    if ($args{activated} eq 'true')
    {
        $self->check_api_code_in_recent_events(
            category => 'SNAPSHOT',
            prefix   => 'CLST_SNAPSHOT_ACTIVE_',
            from     => $res->{prof}->{from},
            to       => $res->{prof}->{to},
            status   => $res->{success},
            ok       => ['OK'],
            failure  => ['FAILURE'],
        );
    }
    else
    {
        $self->check_api_code_in_recent_events(
            category => 'SNAPSHOT',
            prefix   => 'CLST_SNAPSHOT_DEACTIVE_',
            from     => $res->{prof}->{from},
            to       => $res->{prof}->{to},
            status   => $res->{success},
            ok       => ['OK'],
            failure  => ['FAILURE'],
        );
    }

    return 0;

ERROR:
    diag(explain($res));
    return -1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_snapshot_clone
#        BRIEF: 클러스터 볼륨의 스냅샷으로 새로운 클러스터 볼륨을 생성
#   PARAMETERS: {
#                   origin_volname => 'original_volume_name',
#                   snapname      => 'snap_name',
#                   volname       => 'new_volume_name'
#      RETURNS: {
#               }
#=============================================================================
sub volume_snapshot_clone
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/snapshot/clone',
        params => {
            argument => {
                Pool_Type          => 'Gluster',
                Origin_Volume_Name => $args{origin_volname} // '',
                Snapshot_Name      => $args{snapname}       // '',
                Volume_Name        => $args{volname}        // '',
            },
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return 0;

ERROR:
    diag(explain($res));
    return -1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_tier_list
#        BRIEF: Hot tier의 정보 목록을 반환
#   PARAMETERS: {
#                   volname => volume name (없을 경우 모든 Hot tier list)
#               }
#      RETURNS: [
#                   {
#                       'Volume_Name'   => $volname,
#                       'Node_List'     => [ 'test-1' ],
#                       'Replica_Count' => 1,
#                       'Nodes'     => [
#                           {
#                               'Node_Name'     => $volname,
#                               'Status_Msg'    => '',
#                               'Status_Code'   => 'OK',
#                               'Hot_Tiers'     => [
#                                   {
#                                       'LV_Name'   => $volname,
#                                       'LV_Mount'  => "/tier/$volname",
#                                       'LV_Usage'  => '50',
#                                       'Pool_Name' => 'vg_tier',
#                                   },
#                               ],
#                           },
#                       ],
#                   }
#               ]
#=============================================================================
sub volume_tier_list
{
    my $self = shift;
    my %args = @_;

    my $volname = $args{volname};
    my %payload = (Pool_Type => 'Gluster');

    $payload{Volume_Name} = $volname if (defined($volname));

    my $res = $self->request(
        uri    => '/cluster/volume/tier/list',
        params => {
            argument => \%payload,
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_tier_attach
#        BRIEF: 클러스터 볼륨에 Hot tier를 설정
#   PARAMETERS: {
#                   pool_name   => name of volume pool
#                   volname     => volume name
#                   capacity    => total hot tier's capa of all nodes
#                   replica_cnt => hot tier replication count
#                   node_list   => node hostnames
#               }
#      RETURNS: volume name or undef
#=============================================================================
sub volume_tier_attach
{
    my $self = shift;
    my %args = @_;

    my $volname = $args{volname};

    my $res = $self->request(
        uri    => '/cluster/volume/tier/attach',
        params => {
            argument => {
                Pool_Name     => $args{pool_name} // 'vg_cluster',
                Pool_Type     => 'Gluster',
                Volume_Name   => $args{volname},
                Capacity      => $args{capacity},
                Replica_Count => $args{replica_cnt},
                Node_List     => $args{node_list},
            }
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    diag('Waiting 3 seconds...');
    sleep 3;

    $self->check_api_code_in_recent_events(
        category => 'TIERING',
        prefix   => 'CLST_TIER_ATTACH_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_tier_detach
#        BRIEF: 클러스터 볼륨에 Hot tier를 제거
#   PARAMETERS: {
#                   volname => volume name
#               }
#      RETURNS: volume name or undef
#=============================================================================
sub volume_tier_detach
{
    my $self = shift;
    my %args = @_;

    my $volname = $args{volname};
    my %payload = (Pool_Type => 'Gluster');

    $payload{Volume_Name} = $volname if (defined($volname));

    my $res = $self->request(
        uri    => '/cluster/volume/tier/detach',
        params => {
            argument => \%payload,
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    diag('Waiting 3 seconds...');
    sleep 3;

    $self->check_api_code_in_recent_events(
        category => 'TIERING',
        prefix   => 'CLST_TIER_DETACH_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_tier_reconfig
#        BRIEF: 클러스터 볼륨에 Hot tier를 재설정(확장/축소)
#   PARAMETERS: {
#                   volname     => volume name
#                   capacity    => total hot tier's capa of all nodes
#                   replica_cnt => hot tier replication count
#                   node_list   => node hostnames
#               }
#      RETURNS: volume name or undef
#=============================================================================
sub volume_tier_reconfig
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/tier/reconfig',
        params => {
            argument => {
                Pool_Type     => 'Gluster',
                Volume_Name   => $args{volname},
                Capacity      => $args{capacity},
                Replica_Count => $args{replica_cnt},
                Node_List     => $args{node_list},
            }
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_tier_opts
#        BRIEF: Tireing된 클러스터 볼륨의 옵션 조회/변경
#   PARAMETERS: {
#                   volname     => volume name
#                   action_type => get/set
#                   tier_opts   => { # tiering configs when set
#                       Tier_Pause     => on/off,
#                       Tier_Mode      => cache/test,
#                       Tier_Max_MB    => 4000MB,
#                       Tier_Max_Files => 10000,
#                       Watermark      => { High => 90, Low => 75 },
#                       IO_Threshold   => { Read_Freq => 0, Write_Freq => 0 },
#                       Migration_Freq => { Promote => 120, Demote => 3600 },
#                   }
#               }
#      RETURNS: {
#                   volname     => volume name
#                   action_type => get/set
#                   tier_opts   => { # tiering configs when set
#                       Tier_Pause     => on/off,
#                       Tier_Mode      => cache/test,
#                       Tier_Max_MB    => 4000MB,
#                       Tier_Max_Files => 10000,
#                       Watermark      => { High => 90, Low => 75 },
#                       IO_Threshold   => { Read_Freq => 0, Write_Freq => 0 },
#                       Migration_Freq => { Promote => 120, Demote => 3600 },
#                   }
#               }
#=============================================================================
sub volume_tier_opts
{
    my $self = shift;
    my %args = @_;

    my $volname = $args{volname};
    my $action  = $args{action_type};
    my $opts    = $args{tier_opts};

    my %payload = (Pool_Type => 'Gluster');

    $payload{Volume_Name} = $volname if (defined($volname));
    $payload{Action_Type} = $action  if (defined($action));
    $payload{Tier_Opts}   = $opts    if (defined($opts));

    my $res = $self->request(
        uri    => '/cluster/volume/tier/opts',
        params => {
            argument => \%payload,
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    diag('Waiting 3 seconds...');
    sleep 3;

    if ($action eq 'get')
    {
        $self->check_api_code_in_recent_events(
            category => 'TIERING',
            prefix   => 'CLST_TIER_GET_OPTS_',
            from     => $res->{prof}->{from},
            to       => $res->{prof}->{to},
            status   => $res->{success},
            ok       => ['OK'],
            failure  => ['FAILURE'],
        );
    }
    else
    {
        $self->check_api_code_in_recent_events(
            category => 'TIERING',
            prefix   => 'CLST_TIER_SET_OPTS_',
            from     => $res->{prof}->{from},
            to       => $res->{prof}->{to},
            status   => $res->{success},
            ok       => ['OK'],
            failure  => ['FAILURE'],
        );
    }

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_pool_list
#        BRIEF: 클러스터 볼륨 풀 정보를 반환
#   PARAMETERS: {
#                   pool_name => 'volume pool name' # optional
#      RETURNS: {
#               }
#=============================================================================
sub volume_pool_list
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/pool/list',
        params => {
            argument => {
                Pool_Name => $args{pool_name},
                Pool_Type => 'Gluster',
            }
        },
        ignore => $args{ignore_return} // 0
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_pool_create
#        BRIEF: 클러스터 Thin 볼륨 풀을 생성
#   PARAMETERS: {
#                   pool_name => 'name for volume pool'
#                   Provision => 'thick' or 'thin'
#                   capacity  => 'capacity for create thin volume pool' # 1G
#                   basepool  => 'vg name for create thin volume pool'
#                   nodes     => 'node infos to create volume pool'
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_pool_create
{
    my $self = shift;
    my %args = @_;

    my %payload = (Pool_Type => 'Gluster');

    $args{pool_name} = 'vg_cluster' if (!defined($args{pool_name}));
    $args{provision} = 'thick'      if (!defined($args{provision}));
    $args{purpose}   = 'for_data'   if (!defined($args{purpose}));

    if (!defined($ENV{GMS_BUILD_CONFIG}))
    {
        chomp(my $hostname = `hostname`);

        $hostname = uc($hostname);

        $ENV{GMS_BUILD_CONFIG}
            = "/usr/jenkins/jenkins_build_info/$hostname.config";
    }

    local @ARGV = $ENV{GMS_BUILD_CONFIG};
    local $/    = undef;

    my $lines     = <>;
    my $config_db = from_json($lines, {utf8 => 1});

    if (!defined($args{nodes}))
    {
        my @vpool_pvs;

        foreach my $pv (@{$config_db->{pvs}})
        {
            $pv =~ s/^[\/dev]*\/{0,1}//;

            push(@vpool_pvs, {Name => "/dev/$pv"});
        }

        my @nodeinfo
            = map { {Hostname => $_->{Mgmt_Hostname}, PVs => \@vpool_pvs,}; }
            @{$self->nodes};

        $args{nodes} = \@nodeinfo;
    }

    $payload{Pool_Type}     = $args{pooltype}  if (exists($args{pooltype}));
    $payload{Capacity}      = $args{capacity}  if (exists($args{capacity}));
    $payload{Base_Pool}     = $args{basepool}  if (exists($args{basepool}));
    $payload{Pool_Name}     = $args{pool_name} if (exists($args{pool_name}));
    $payload{External_IP}   = $args{ip}        if (exists($args{ip}));
    $payload{External_Type} = $args{externaltype}
        if (exists($args{externaltype}));
    $payload{External_Path} = $args{externalpath}
        if (exists($args{externalpath}));
    $payload{Provision}    = $args{provision} if (exists($args{provision}));
    $payload{Pool_Purpose} = $args{purpose}   if (exists($args{purpose}));
    $payload{Nodes}        = $args{nodes}     if (exists($args{nodes}));

    my $res = $self->request(
        uri    => '/cluster/volume/pool/create',
        params => {
            argument => \%payload,
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME_POOL',
        prefix   => 'CLST_VPOOL_CREATE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_pool_reconfig
#        BRIEF: 클러스터 Thin 볼륨 풀을 생성
#   PARAMETERS: {
#                   pool_name => 'name for volume pool'
#                   capacity  => 'capacity for reconfig thin volume pool' # 1G
#                   basepool  => 'vg name for reconfig thin volume pool'
#                   nodes     => 'node infos to reconfig volume pool'
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_pool_reconfig
{
    my $self = shift;
    my %args = @_;

    my %payload = (Pool_Type => 'Gluster');

    $payload{Pool_Name} = $args{pool_name} if (exists($args{pool_name}));
    $payload{Base_Pool} = $args{basepool}  if (exists($args{basepool}));
    $payload{Capacity}  = $args{capacity}  if (exists($args{capacity}));
    $payload{Nodes}     = $args{nodes}     if (exists($args{nodes}));

    my $res = $self->request(
        uri    => '/cluster/volume/pool/reconfig',
        params => {
            argumetns => \%payload,
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME_POOL',
        prefix   => 'CLST_VPOOL_RECONFIG_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_pool_reconfig_external
#        BRIEF: 클러스터 Thin 볼륨 풀을 생성
#   PARAMETERS: {
#                   pool_name => 'name for volume pool'
#                   capacity  => 'capacity for reconfig thin volume pool' # 1G
#                   basepool  => 'vg name for reconfig thin volume pool'
#                   nodes     => 'node infos to reconfig volume pool'
#               }
#      RETURNS: {
#               }
#=============================================================================
sub volume_pool_reconfig_external
{
    my $self = shift;
    my %args = @_;

    my %payload = (Pool_Type => 'External');

    $payload{Pool_Name}   = $args{pool_name} if (exists($args{pool_name}));
    $payload{Nodes}       = $args{nodes}     if (exists($args{nodes}));
    $payload{External_IP} = $args{external_ip}
        if (exists($args{external_ip}));

    my $res = $self->request(
        uri    => '/cluster/volume/pool/reconfig',
        params => {
            argument => \%payload,
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME_POOL',
        prefix   => 'CLST_VPOOL_RECONFIG_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_pool_remove
#        BRIEF: 클러스터 볼륨 풀 제거
#   PARAMETERS: {
#                   pool_name => 'volume pool name'
#      RETURNS: {
#               }
#=============================================================================
sub volume_pool_remove
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/pool/remove',
        params => {
            argument => {
                Pool_Type => $args{pooltype}  // 'Gluster',
                Pool_Name => $args{pool_name} // 'vg_cluster',
            }
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME_POOL',
        prefix   => 'CLST_VPOOL_REMOVE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_create
#        BRIEF: 클러스터 볼륨 생성 랩핑 함수
#   PARAMETERS: {
#                   volpolicy  => 'Distributed' or 'Disperse' or 'Stripe',
#                   voltype    => 'thin' or 'thick', # option
#                   capacity   => '1.0G',
#                   replica    => 2 or if voltype eq Disperse, useless
#                   start_node => 0,
#                   node_count => 2,
#                   code_count => 1 or if voltype ne Disperse, useless
#               }
#      RETURNS: {
#                   success
#                       return $volume_name
#                   failed
#                       return
#               }
#=============================================================================
sub volume_create
{
    my $self = shift;
    my (%args) = @_;

    foreach my $key (qw/volpolicy capacity start_node node_count/)
    {
        if (!exists($args{$key}) || !defined($args{$key}))
        {
            warn "[ERR] Invalid parameter: $key ($args{$key})";
            return;
        }
    }

    if (!exists($args{volname}))
    {
        $args{volname} = $self->generate_volname(%args);
    }

    my @node_list_hostnm = $self->gethostnm(
        start_node => $args{start_node},
        cnt        => $args{node_count}
    );

    my @node_list_stgip = $self->hostnm2stgip(hostnms => \@node_list_hostnm);

    my @node_list_mgmtip
        = $self->hostnm2mgmtip(hostnms => \@node_list_hostnm);

    is(scalar(@node_list_hostnm),
        $args{node_count}, 'Verify the node hostnames count');
    is(scalar(@node_list_stgip),
        $args{node_count}, 'Verify the node stgips count');

    return
        if (scalar(@node_list_hostnm) != $args{node_count}
        || scalar(@node_list_stgip) != $args{node_count});

    # try vol create
    my $ret = undef;

    if ($args{volpolicy} eq 'Distributed')
    {
        $ret = $self->volume_create_distribute(%args,
            node_list => \@node_list_stgip);
    }
    elsif ($args{volpolicy} eq 'Disperse')
    {
        $ret = $self->volume_create_networkraid(%args,
            node_list => \@node_list_stgip);
    }
    elsif ($args{volpolicy} eq 'Striped')
    {
        $ret = $self->volume_create_stripe(%args,
            node_list => \@node_list_stgip);
    }
    else
    {
        fail('Unknown cluster volume type');
    }

    return $ret;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_create_external_
#        BRIEF: 클러스터 볼륨 생성 랩핑 함수
#   PARAMETERS: {
#                   volname   => 'VOLNAME'
#                   pooltype  => 'external'
#                   pool_name => 'POOLNAME'
#                   nodes     => 2,
#               }
#      RETURNS: {
#                   success
#                       return $volume_name
#                   failed
#                       return
#               }
#=============================================================================
sub volume_create_external
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/create',
        params => {
            argument => {
                Pool_Type        => 'External',
                Volume_Name      => $args{volname},
                Pool_Name        => $args{pool_name},
                External_Target  => $args{externaltarget},
                External_Options => $args{externaloptions},
                Nodes            => $args{nodes},
            }
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME',
        prefix   => 'CLST_VOLUME_CREATE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: volume_delete_external
#        BRIEF: 클러스터 볼륨 생성 랩핑 함수
#   PARAMETERS: {
#                   volname  => 'VOLNAME'
#               }
#      RETURNS: {
#                   success
#                       return $volume_name
#                   failed
#                       return
#               }
#=============================================================================
sub volume_delete_external
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/delete',
        params => {
            argument => {
                Pool_Type   => 'External',
                Pool_Name   => $args{pool_name},
                Volume_Name => $args{volname},
                Reason      => 'To test functionality',
                Password    => $args{password} // 'admin',
            },
        },
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    $self->check_api_code_in_recent_events(
        category => 'VOLUME',
        prefix   => 'CLST_VOLUME_DELETE_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{entity};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: verify_volstatus
#        BRIEF: 전체 노드 상의 클러스터 볼륨 상태 조회
#   PARAMETERS: {
#                   volname => 'volume_name',
#                   exists  => 'expected value',
#               }
#      RETURNS: {
#                   return failed node ip or undef
#               }
#=============================================================================
sub verify_volstatus
{
    my $self = shift;
    my %args = @_;

    foreach my $key (qw/volname exists/)
    {
        if (!exists($args{$key}) || !defined($args{$key}))
        {
            warn "[ERR] Invalid parameter: $key";
            return;
        }
    }

    $args{thin}      //= 0;
    $args{pool_name} //= 'vg_cluster';

    my @allhostnm = $self->gethostnm(
        start_node => 0,
        cnt        => scalar(@{$self->nodes})
    );

    my @allmgmtip = $self->hostnm2mgmtip(hostnms => \@allhostnm);

    foreach my $ip (@allmgmtip)
    {
        my $res = 0;

        if ($args{exists})
        {
            my $vol = $self->volume_list(volname => $args{volname});

            is(scalar(@{$vol}), 1, 'Verify the getting a volume list');

            next if (scalar(@{$vol}) != 1);

            my $lvchk = 0;
            my @member_mgmtip
                = $self->hostnm2mgmtip(hostnms => $vol->[0]->{Node_List});

            $lvchk = 1 if (grep { $ip eq $_; } @member_mgmtip);

            $res = $self->__verify_volbyssh(
                addr      => $ip,
                pool_name => $args{pool_name},
                volname   => $args{volname},
                exists    => $args{exists},
                lvchk     => $lvchk,
                thin      => $args{thin},
            );

            is($res, 0, "Verify the $args{volname} exists in $ip");

        }
        else
        {
            $res = $self->__verify_volbyssh(
                addr      => $ip,
                pool_name => $args{pool_name},
                volname   => $args{volname},
                exists    => $args{exists},
                lvchk     => 1,
                thin      => $args{thin},
            );

            is($res, 0, "Verify the $args{volname} is not exists in $ip");
        }

        return $ip if ($res != $args{exists});
    }

    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: __verify_volbyssh
#        BRIEF: 클러스터 볼륨 상태 조회
#   PARAMETERS: {
#                   addr    => 'management ip',
#                   volname => 'volume_name',
#                   exists  => 'expected value',
#                   lvchk   => 'only lv checking',
#               }
#      RETURNS: {
#                   cmd result stdout's line count
#               }
#=============================================================================
sub __verify_volbyssh
{
    my $self = shift;
    my (%args) = @_;

    foreach my $key (qw/addr volname exists lvchk/)
    {
        if (!exists($args{$key}) || !defined($args{$key}))
        {
            warn "[ERR] Invalid parameter: $key";
            return -1;
        }
    }

    $args{thin}      //= 0;
    $args{pool_name} //= 'vg_cluster';

    my @ssh_cmds = (
        "df -h | egrep '/export/$args{volname}\$' | wc -l",
        "ls /var/lib/glusterd/vols | egrep '$args{volname}\$' | wc -l",
    );

    my @verify_msgs = (
        'gluster volume df -h',
        'gluster volume file in /var/lib/glusterd/vols',
    );

    if ($args{lvchk})
    {
        (my $thin_name = $args{pool_name}) =~ s/^vg_/tp_/g;

        push(
            @ssh_cmds,
            sprintf(
                "cat /etc/fstab | egrep '%s' | wc -l",
                $args{thin}
                ? sprintf(
                    "/volume/%s[0-9]+/%s/%s_[0-9]+\\s+",
                    $args{pool_name},
                    $thin_name,
                    $args{volname}
                    )
                : sprintf(
                    "/volume/%s[0-9]+/%s_[0-9]+\\s+",
                    $args{pool_name}, $args{volname}
                )
            )
        );

        push(
            @ssh_cmds,
            sprintf(
                "df -h | egrep '%s' | wc -l",
                $args{thin}
                ? sprintf(
                    "/volume/%s[0-9]+/%s/%s_[0-9]+\$",
                    $args{pool_name},
                    $thin_name,
                    $args{volname}
                    )
                : sprintf(
                    "/volume/%s[0-9]+/%s_[0-9]+\$",
                    $args{pool_name}, $args{volname}
                )
            )
        );

        push(@ssh_cmds,
            sprintf("lvs | egrep '%s' | wc -l", "$args{volname}_[0-9]+\\s+"));

        push(@verify_msgs, 'LV mount entry existance in /etc/fstab');
        push(@verify_msgs, 'LV with "df -h"');
        push(@verify_msgs, 'LV with "lvs"');
    }

    my @df_result = $self->ssh_cmd(addr => $args{addr}, cmd => 'df -h');

    diag('SSH Command : df -h');
    diag("STDOUT      : $df_result[0]");

    foreach my $idx (0 .. $#ssh_cmds)
    {
        my ($ret, undef)
            = $self->ssh_cmd(addr => $args{addr}, cmd => $ssh_cmds[$idx]);

        diag("SSH Command    : $ssh_cmds[$idx]");
        diag("Command result : $ret");

        if (!defined($args{exists}) || $args{exists} == 0)
        {
            is($ret, 0, "Verify the $verify_msgs[$idx] on $args{addr}");

            return -1 if ($ret != 0);
        }
        elsif (defined($args{exists}) && $args{exists})
        {
            if (int($ret) >= int($args{exists}))
            {
                ok(1, "Verify the $verify_msgs[$idx] on $args{addr}");
            }
            else
            {
                fail("Verify the $verify_msgs[$idx] on $args{addr}");
                return -1;
            }
        }
    }

    return 0;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: file_write
#        BRIEF: 클러스터 볼륨 I/O 테스트
#   PARAMETERS: {
#                   volname => 'volume_name',
#                   path => 'path to write the file
#                   file => 'file name'
#                   node_list => 'hostnames to write file'
#               }
#      RETURNS: {
#                   0 or -1
#               }
#=============================================================================
sub file_write
{
    my $self = shift;
    my %args = @_;

    my $tot       = $args{tot}       // 1;
    my $node_list = $args{node_list} // [];
    my $bs        = $args{bs}        // 1024;
    my $count     = $args{count}     // 1024;

    foreach my $key (qw/volname path file/)
    {
        if (!exists($args{$key}) || !defined($args{$key}))
        {
            fail("arg $key missing");
            return -1;
        }
    }

    my $vol = $self->volume_list(volname => $args{volname});

    is(scalar(@{$vol}), 1, 'Getting the volume information');

    return -1 if (!defined($vol) || !scalar(@{$vol}));

    if (!exists($vol->[0]->{Node_List})
        || ref($vol->[0]->{Node_List}) ne 'ARRAY'
        || !scalar(@{$vol->[0]->{Node_List}}))
    {
        fail("Failed to get volume information's node list");
        return -1;
    }

    my @node_list_mgmtip = $self->hostnm2mgmtip(
        hostnms => scalar(@{$node_list}) == 0
        ? $vol->[0]->{Node_List}
        : $node_list
    );

    foreach my $ip (@node_list_mgmtip)
    {
        for (my $i = 1; $i <= $tot; $i++)
        {
            my $res = $self->ssh(
                addr => $ip,
                cmd  =>
                    "dd if=/dev/zero of=$args{path}/$args{file}.$i bs=$bs count=$count"
            );

            is($res, 0, "Verify the file I/O $ip:$args{path}/$args{file}.$i");

            return -1 if ($res);

            ($res, undef) = $self->ssh_cmd(
                addr => $ip,
                cmd  => "ls $args{path}/$args{file}.$i | wc -l"
            );

            is($res, 1, "$ip:$args{path}/$args{file}.$i exists checking");

            return -1 if (!$res);
        }
    }

    return 0;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: file_remove
#        BRIEF: 클러스터 노드의 지정된 파일을 삭제한다
#   PARAMETERS: {
#                   volname => 'volume_name',
#                   path => 'path to remove the file
#                   file => 'file name'
#                   node_list => 'hostnames to remove file'
#               }
#      RETURNS: {
#                   0 or -1
#               }
#=============================================================================
sub file_remove
{
    my $self = shift;
    my %args = @_;

    my $node_list = $args{node_list} // [];

    foreach my $key (qw/volname path file/)
    {
        if (!exists($args{$key}) || !defined($args{$key}))
        {
            fail("arg $key missing");
            return -1;
        }
    }

    my $rm     = "rm -rf $args{path}/$args{file}";
    my $ls_all = "ls $args{path} | wc -l";
    my $ls     = "ls $args{path} | grep $args{file} | wc -l";

    my $vol = $self->volume_list(volname => $args{volname});

    is(scalar(@{$vol}), 1, 'Getting the volume information');

    return -1 if (!defined($vol) || !scalar(@{$vol}));

    if (!exists($vol->[0]->{Node_List})
        || ref($vol->[0]->{Node_List}) ne 'ARRAY'
        || !scalar(@{$vol->[0]->{Node_List}}))
    {
        fail("Failed to get volume information's node list");
        return -1;
    }

    my @node_list_mgmtip = $self->hostnm2mgmtip(
        hostnms => scalar(@{$node_list}) == 0
        ? $vol->[0]->{Node_List}
        : $node_list
    );

    foreach my $ip (@node_list_mgmtip)
    {
        my $cmd = $rm;

        my $res = $self->ssh(
            addr => $ip,
            cmd  => $cmd,
        );

        is($res, 0, "file remove on $ip:$args{path}/$args{file}");

        return -1 if ($res);

        $cmd = $ls;
        $cmd = $ls_all if ($args{file} eq '*');

        ($res, undef) = $self->ssh_cmd(
            addr => $ip,
            cmd  => $cmd
        );

        is($res, 0, "$ip:$args{path}/$args{file} file is removed");

        return -1 if ($res);
    }

    return 0;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: verify_volheal
#        BRIEF: cluster volume의 heal을 검증
#   PARAMETERS: {
#                   volname   => volume name
#                   node      => node mgmt ip
#                   totfile   => file exists checking count
#               }
#      RETURNS: 0 or -1
#=============================================================================
sub verify_volheal
{
    my $self = shift;
    my %args = @_;

    foreach my $key (qw/volname node totfile/)
    {
        if (!exists($args{$key}) || !defined($args{$key}))
        {
            fail("arg $key missing");
            return -1;
        }
    }

    my $ls_all = "ls /volume/$args{volname} | wc -l";
    my $retry  = 120;
    my $res    = undef;

    for (my $i = 1; $i <= $retry; $i++)
    {
        sleep 1;

        ($res, undef) = $self->ssh_cmd(addr => $args{node}, cmd => $ls_all);

        if (!defined($res) || (!($res ^ $res) && $res == -1))
        {
            fail("Getting file count on $args{node}:/volume/$args{volname}");
            next;
        }

        if ($res < $args{totfile})
        {
            ok(
                1,
                "wait to heal, volume files ($res), expected ($args{totfile}) ($i/120)"
            );
            next;
        }

        last;
    }

    is($res, $args{totfile}, 'Verify the file recover by heal');

    return $res == $args{totfile} ? 0 : -1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: verify_volrebalance
#        BRIEF: cluster volume의 rebalancing을 검증
#   PARAMETERS: {
#                   volname    => volume name
#                   node       => check node
#                   totfiles   => total file count on all nodes
#               }
#      RETURNS: 0 or -1
#=============================================================================
sub verify_volrebalance
{
    my $self = shift;
    my %args = @_;

    # /var/lib/glusterd/vols/$volname/node_status.info
    # check rebalance_status=1, status=3, rebalance_op=19
    my $GD_DEFRAG_CMD_START       = '1';
    my $GD_DEFRAG_STATUS_STOPPED  = '3';
    my $GD_DEFRAG_STATUS_COMPLETE = '4';
    my $GD_OP_REBALANCE           = '19';

    foreach my $key (qw/volname node totfiles/)
    {
        if (!exists($args{$key}) || !defined($args{$key}))
        {
            fail("arg $key missing");
            return -1;
        }
    }

    my ($res, undef) = $self->ssh_cmd(
        addr => $args{node},
        cmd  => "ls /volume/$args{volname} | wc -l"
    );

    if (!$res || $res == -1)
    {
        fail("ssh_cmd failed, to verify rebalance.");
        return -1;
    }

    if ($res == $args{totfiles})
    {
        my $retry = 10;

        for (my $i = 1; $i <= $retry; $i++)
        {
            ($res, undef) = $self->ssh_cmd(
                addr => $args{node},
                cmd  =>
                    "cat /var/lib/glusterd/vols/$args{volname}/node_state.info"
            );

            next if (!defined($res));

            if ($i < $retry)
            {
                fail("ssh_cmd failed, retry again ... ($i/$retry)");
                sleep 1;
                next;
            }

            fail("ssh_cmd failed, to verify rebalance.");

            return -1;
        }

        my $gluster_op_code = 0;
        my $op_started      = 0;
        my $op_status       = 0;

        my @tmp = split('\n', $res);

        foreach my $line (@tmp)
        {
            chomp($line);

            $gluster_op_code = 1
                if ($line =~ /^rebalance_op=$GD_OP_REBALANCE$/);

            $op_started = 1
                if ($line =~ /^rebalance_status=$GD_DEFRAG_CMD_START$/);

            $op_status = 1
                if ($line =~ /^status=$GD_DEFRAG_STATUS_STOPPED$/
                || $line =~ /^status=$GD_DEFRAG_STATUS_COMPLETE$/);
        }

        goto ERROR if (!$gluster_op_code || !$op_started || !$op_status);
    }
    elsif ($res > $args{totfiles})
    {
        goto ERROR;
    }

    ok(1, "Verify the $args{volname} rebalance");

    return 0;

ERROR:
    fail("$args{volname} rebalance is failed");
    return 1;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: generate_volname
#        BRIEF: 클러스터 볼륨 작명 함수
#   PARAMETERS: {
#                   volpolicy    => 'Distributed' or 'Disperse' or 'Stripe'
#                   capacity   => '1.0G',
#                   replica    => 2,
#                   start_node => 0,
#                   node_count => 2,
#                   code_count => 1 or undef,
#                   postfix    => 'test' or undef
#               }
#      RETURNS: {
#                   $volume_name
#               }
#=============================================================================
sub generate_volname
{
    my $self = shift;
    my %args = @_;

    my $volname = '';

    $volname .= substr($args{volpolicy}, 0, 4)
        if (exists($args{volpolicy}));

    $volname .= '_cd' . $args{code_count}
        if (exists($args{code_count}));

    $volname .= '_rep' . $args{replica}
        if (exists($args{replica}));

    $volname .= '_' . $args{postfix}
        if (exists($args{postfix}));

    if (!exists($args{postfix}))
    {
        my ($S, $M, $H, $d, $m, $Y) = localtime(time());

        $m += 1;
        $Y += 1900;

        $volname .= sprintf('_%02d_%02d', $M, $S);
    }

    return lc($volname);
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: v
#        BRIEF: 클러스터 볼륨 생성 랩핑 함수
#   PARAMETERS: {
#                   volpolicy  => 'Distributed' or 'Disperse' or 'Stripe',
#                   voltype    => 'thin' or 'thick', # option
#                   capacity   => '1.0G',
#                   replica    => 2 or if voltype eq Disperse, useless
#                   start_node => 0,
#                   node_count => 2,
#                   code_count => 1 or if voltype ne Disperse, useless
#               }
#      RETURNS: {
#                   success
#                       return $volume_name
#                   failed
#                       return
#               }
#=============================================================================
sub attach_arbiter
{
    my $self = shift;
    my %args = @_;

    my $res = $self->request(
        uri    => '/cluster/volume/arbiter/attach',
        params => {
            argument => {
                Pool_Type        => 'Gluster',
                Volume_Name      => $args{volume_name},
                Shard            => $args{shard},
                Shard_Block_Size => $args{shard_block_size},
            }
        }
    );

    goto ERROR if ($self->is_bad_res(res => $res));

    diag('Waiting 10 seconds...');
    sleep 10;

    $self->check_api_code_in_recent_events(
        category => 'ARBITER',
        prefix   => 'CLST_ARBITER_ATTACH_',
        from     => $res->{prof}->{from},
        to       => $res->{prof}->{to},
        status   => $res->{success},
        ok       => ['OK'],
        failure  => ['FAILURE'],
    );

    return $res->{success};

ERROR:
    diag(explain($res));
    return;
}

#===  CLASS METHOD  ==========================================================
#        CLASS: ClusterVolume
#       METHOD: verify_arbiter
#        BRIEF: cluster volume의 arbiter 검증
#   PARAMETERS: {
#                   volname   => volume name
#                   node      => node mgmt ip
#                   totfile   => file exists checking count
#               }
#      RETURNS: 0 or -1
#=============================================================================
sub verify_arbiter
{
    my $self = shift;
    my %args = @_;

    my $chaining    = $args{chaining};
    my $volume_name = $args{volume_name};
    my $master_ip   = $args{master_ip};

    my $vol      = $self->volume_list(volname => $volume_name);
    my $node_cnt = @{$vol->[0]->{Node_List}};

    my $check_cnt = undef;

    if ($chaining eq 'Optimal')
    {
        $check_cnt = $node_cnt;
    }
    elsif ($chaining eq 'Not_Chained')
    {
        $check_cnt = int($node_cnt / 2);
    }
    else
    {
        fail('Not defined mode in verifiing the arbiter');
    }

    my $res = undef;

    for my $i (0 .. 2)
    {
        ($res, undef) = $self->ssh_cmd(
            addr => $master_ip,
            cmd  => "gluster v info $volume_name | grep arbiter | wc -l",
        );

        last if (defined($res));
    }

    if (!defined($res) || $res != $check_cnt)
    {
        return -1;
    }

    return 0;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=encoding utf8

=head1 NAME

ClusterVolume - 클러스터 볼륨의 기능 테스트에 대한 함수를 제공하는 라이브러리

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021. Gluesys Co., Ltd. All rights reserved.

=head1 SEE ALSO

=cut


