# Cluster Volume API: Volume

## API 개요

### 1. [/cluster/volume/brick/list](#1-brick-list)

## API 설명

* 클러스터 볼륨의 브릭에 관련된 API

### 1. brick list

* 생성된 클러스터 볼륨의 브릭 목록을 반환하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: <KEY>,
>     argument: {
>         FS_Type:     ...,
>         Volume_Name: ...,
>         Without_Arbiter: ...,
>     }
> }
> ```
> Argument        | Description                                            | Type   | Required |
> --------        | -----------                                            | ----   | -------- |
> **FS_Type**     | 'glusterfs' or 'ceph' or 'maha'                        | String | Y        |
> **Volume_Name** | 클러스터 볼륨 명 지정, 없을 경우 모든 볼륨의 브릭 정보를 반환 | String | Y        |
> **With_Arbiter** | 0 : Arbiter 브릭 미포함, 1 : Arbiter 브릭 포함 (default : 0)  | String | Y        |

***

> #### 응답 결과 값
> ```
> {
>     return: ...,
>     code:   ...,
>     msg:    ...,
>     entity: [ 
>         {
>             Hostname: test-node-1,
>             Brick_Used: 0%,
>             Brick_Number: 6,
>             Volume_Name: test,
>             Capacity: 37.0GiB,
>             Backend_Type: lvm,
>             Brick_Type: cold_tier,
>             Backend_Pool: tp_cluster,
>             Mount_Path: /volume/test_0,
>             Backend_FS: xfs,
>             Backend_Base_Pool: vg_cluster,
>             Capacity_bytes: 39728447488,
>             Storage_IP: 10.10.63.96,
>             Backend_Subtype: thin,
>             Arbiter: false
>         }, ...
>     ]
> }

> ```
> Argument              | Description                                                   | Type   |
> --------              | -----------                                                   | ----   |
> **return**            | 'true' or 'false'                                             | String |
> **code**              | ...                                                           | String |
> **msg**               | ...                                                           | String |
> **entity**            | 요청된 볼륨 정보 목록                                         | String |
> **Hostname**          | 노드 명                                                       | String |
> **Storage_IP**        | 노드의 스토리지 IP                                            | String |
> **Volume_Name**       | 클러스터 볼륨명                                               | String |
> **Brick_Number**      | Gluster CLI의 브릭 넘버링                                     | String |
> **Brick_Type**        | 브릭 종류 (cold_tier, hot_tier)                               | String |
> **Capacity**          | 브릭 크기                                                     | String |
> **Capacity_bytes**    | 브릭 크기 (byte 단위)                                         | String |
> **Brick_Used**        | 브릭 사용률                                                   | String |
> **Mount_Path**        | 브릭 마운트 경로                                              | String | 
> **Backend_FS**        | 브릭 백엔드 파일 시스템 (xfs)                                 | String |
> **Backend_Type**      | 브릭 백엔드 타입 (lvm)                                        | String |
> **Backend_Subtype**   | 브릭 LV의 타입 (thin, thick)                                  | String |
> **Backend_Pool**      | 브릭이 생성된 볼륨 풀 명                                      | String |
> **Backend_Base_Pool** | 브릭 LV가 포함된 VG 명                                        | String |
> **Arbiter**           | Arbiter 브릭 여부                                             | String |

***

