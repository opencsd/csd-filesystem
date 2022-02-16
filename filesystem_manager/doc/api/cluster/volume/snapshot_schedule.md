# Cluster Volume Snapshot Scheduling API

## API 개요

### 1. [/cluster/volume/schedule/snapshot/list](#1-schedule-snapshot-list)
### 2. [/cluster/volume/schedule/snapshot/create](#2-schedule-snapshot-create)
### 2. [/cluster/volume/schedule/snapshot/change](#2-schedule-snapshot-change)

## API 설명

* 클러스터 볼륨 스냅샷 생성/삭제 및 관리하는 API

### 1. snapshot list

* 클러스터 볼륨의 스냅샷 스케줄링 목록을 반환하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: <KEY>,
>     argument: {
>         FS_Type:     ...,
>         Volume_Name: ... 
>     }
> }
> ```
> Argument        | Description                                            | Type   | Required |
> --------        | -----------                                            | ----   | -------- |
> **FS_Type**     | 'glusterfs' or 'ceph' or 'maha'                        | String | Y        |
> **Volume_Name** | 클러스터 볼륨 명 지정, 없을 경우 모든 볼륨 정보를 반환 | String | N        |

***

> #### 응답 결과 값
> ```
> {
>     return: ...,
>     code:   ...,
>     msg:    ...,
>     entity: [ 
>         {
>             Snapshot_Name: ...,
>             Snapshot_Desc: ...,
>             Volume_Name: ...,
>             Activated: ...,
>             Status: ...,
>             Status_Msg: ...,
>             Created: ...,
>             Created_By: ...,
>         }, ...
>     ]
> }

> ```
> Argument              | Description                                                   | Type   |
> --------              | -----------                                                   | ----   |
> **return**            | 'true' or 'false'                                             | String |
> **code**              | ...                                                           | String |
> **msg**               | ...                                                           | String |
> **entity**            | 요청된 스냅샷 정보                                            | Array  |
> **Snapshot_Name**     | 클러스터 볼륨 스냅샷 명                                       | String |
> **Snapshot_Desc**     | 스냅샷 설명 (스케줄링 설명과 동일)                            | String |
> **Volume_Name**       | 클러스터 볼륨명                                               | String |
> **Activated**         | 스냅샷 활성화 여부                                            | String |
> **Status     **       | 상태 정보                                                     | String |
> **Status_Msg**        | 상태 정보 상세 메세지                                         | String |
> **Created**           | 생성된 시각 (timestamp)                                       | String |
> **Created_By**        | 수동 생성 : '', 스케줄링에 의한 생성시, 스케줄링 ID           | String |

***

### 2. snapshot avail

* 해당 클러스터 볼륨의 생성 가능한 스냅샷 수를 반환하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: <KEY>,
>     argument: {
>         FS_Type:     ...,
>         Volume_Name: ... 
>     }
> }
> ```
> Argument        | Description                                            | Type   | Required |
> --------        | -----------                                            | ----   | -------- |
> **FS_Type**     | 'glusterfs' or 'ceph' or 'maha'                        | String | Y        |
> **Volume_Name** | 클러스터 볼륨 명                                       | String | Y        |

***

> #### 응답 결과 값
> ```
> {
>     return: ...,
>     code:   ...,
>     msg:    ...,
>     entity: ...,
> }

> ```
> Argument              | Description                                                   | Type   |
> --------              | -----------                                                   | ----   |
> **return**            | 'true' or 'false'                                             | String |
> **code**              | ...                                                           | String |
> **msg**               | ...                                                           | String |
> **entity**            | 생성 가능한 스냅샷 수 (-N ~ 0 ~ N)                            | String |

***
