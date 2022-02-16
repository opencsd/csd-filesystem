# Cluster Volume API: Volume

## API 개요

### 1. [/cluster/volume/list](#1-volume-list)
### 2. [/cluster/volume/create](#2-volume-create)
### 3. [/cluster/volume/extend](#3-volume-extend)

## API 설명

* 클러스터 볼륨 생성/삭제 및 관리하는 API

### 1. volume list

* 생성된 클러스터 볼륨의 목록을 반환하는 API

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
> **FS_Type**     | 'Gluster' or 'External' or 'ALL'                       | String | Y        | 
> **Volume_Name** | 클러스터 볼륨 명 지정, 없을 경우 모든 볼륨 정보를 반환 | String | Y        |

***

> #### 응답 결과 값
> ```
> {
>     return: ...,
>     code:   ...,
>     msg:    ...,
>     entity: [ 
>         {
>         
>             Options: { ... },
>             Volume_Name: ...,
>             Volume_Type:  ...,
>             Volume_Used:  ...,
>             Volume_Mount: ...,
>             Volume_Policy: ...,
>             Policy: ...,
>             Pool_Name: ...,
>             Transport_Type: ...,
>             Size: ...,
>             Hot_Tier: ...,
>             Chaining: ...,
>             Distributed_Count: ...,
>             Replica_Count: ...,
>             Disperse_Count: ...,
>             Arbiter: ..,
>             Arbiter_Count: ..,
>             Shard: ...,
>             Shard_Block_Size: ...,
>             Code_Count: ...,
>             Node_List: [ ... ],
>             Node_Info: [
>                 {
>                   SW_Status: ...,
>                   Mgmt_Hostname: ...,
>                   HW_Status: ...,
>                   Node_Used: ...,
>                   Storage_Hostname: ...,
>                 }, ...
>             ],
>             Oper_Stage: ...,
>             Status_Code: ...,
>             Status_Msg: ...,
>         }, ...
>     ]
> }

> ```
> Argument                       | Description                                                   | Type   |
> --------                       | -----------                                                   | ----   |
> **return**                     | 'true' or 'false'                                             | String |
> **code**                       | ...                                                           | String |
> **msg**                        | ...                                                           | String |
> **entity**                     | 요청된 볼륨 정보 목록                                         | Array  |
> **Options**                    | 볼륨에 적용된 옵션값 (key, value)                             | Hash   |
> **Volume_Name**                | 클러스터 볼륨명                                               | String |
> **Volume_Type**                | 볼륨 유형 (thick, thin)                                       | String |
> **Volume_Used**                | 볼륨의 사용량 (%)                                             | String |
> **Volume_Mount**               | 클러스터 볼륨이 마운트된 경로                                 | String |
> **Policy**                     | 분산 정책 (NetworkRAID, Distributed, Shard 등)                | String |
> **Pool_Name**                  | 소속된 볼륨 풀의 이름                                         | String |
> **Transport_Type**             | 전송 유형 ('tcp', 'tcp,rdma', 'rdma')                         | String |
> **Size**                       | 클러스터 볼륨의 크기                                          | String |
> **Hot_Tier**                   | Hot tier 설정 여부 ('true' or 'false')                        | String |
> **Chaining**                   | 체인 볼륨 ('not_chained' or 'optimal' or 'partially')         | String |
> **Distributed_Count**          | 분산 노드 수                                                  | String |
> **Replica_Count**              | 복제 수                                                       | String |
> **Disperse_Count**             | NetworkRAID 노드 수(최초 생성된 노드수)                       | String |
> **Arbiter**                    | true|false|na (활성화됨|활성화할 수 있음|활성화할 수 없음)    | String |
> **Arbiter_Count**              | 복제 그룹당 Arbiter 수                                        | String |
> **Code_Count**                 | Network RAID easure code 수                                   | String |
> **Node_List**                  | 노드의 호스트명 리스트                                        | Array  |
> **Node_Info**                  | 노드의 상태 정보                                              | Array  |
> **Node_Info/Mgmt_Hostname**    | 노드의 호스트명                                               | String |
> **Node_Info/Storage_Hostname** | 노드의 호스트명                                               | String |
> **Node_Info/HW_Status**        | 장비 상태 (OK, WARN, ERROR)                                   | String |
> **Node_Info/SW_Status**        | 서비스 상태 (OK, WARN, ERROR)                                 | String |
> **Node_Info/Node_Used**        | 저장공간 사용량 (%)                                           | String |
> **Oper_Stage**                 | 작업 수행 메세지 (Extend, Delete, ...)                        | String |
> **Status_Msg**                 | 상태 정보 메세지 (Healing, Started 등)                        | String |
> **Status_Code**                | 상태 정보 (OK, WARN, ERROR)                                   | String |
> **Shard**                      | 샤딩적용 유무'true' or 'false')                               | String |
> **Shard_Block_Size**           | 샤딩 블록 사이즈          ('512MB' or '1GB' or '2GB' or '4GB')| String |

***

### 2. volume create

* 클러스터 볼륨 생성 API

> #### 요청 인자 값
> ```
> {
>     secure-key: <KEY>,
>     argument: {
>         FS_Type:     ...,
>         Volume_Name: ...
>         Pool_Name: ...,
>         Volume_Policy: {
>               Distributed: ...,
>               NetworkRAID: ...,
>               Striped: ..., 
>         }
>         Replica: ...,
>         Node_List: [ ... ],
>         Transport_Type: ...,
>         Capacity: ...,
>         Chaining: ...,
>         Shard: ...,
>         Shard_Block_Size: ...,
>         External_Target: ...,
>         External_Options: ...,
>     },
> }
> ```
> Argument                      | Description                                                           | Type   | 
> --------                      | -----------                                                           | ----   | 
> **FS_Type**                   | 'Gluster' or 'External'                                               | String | 
> **Volume_Name**               | 생성할 볼륨 이름                                                      | String | 
> **Pool_Name**                 | 소속될 볼륨 풀 이름                                                   | String | 
> **Volume_Policy**             | 볼륨 분산 정책                                                        | Hash   |
> **Volume_Policy/Distributed** | '' or 'true'                                                          | String |
> **Volume_Policy/NetworkRAID** | '' or '1' ~ 'N'                                                       | String |
> **Volume_Policy/Striped**     | '' or 'true'                                                          | String |
> **Replica**                   | Distributed, Striped 인 경우 복제수, NetworkRAID 인 경우 erasure code | String |
> **Node_List**                 | 브릭을 생성할 노드의 호스트 명                                        | Array  |
> **Transport_Type**            | 전송 유형 ('tcp', 'tcp,rdma', 'rdma')                                 | String |
> **Capacity**                  | 생성할 볼륨의 총 용량                                                 | String |
> **Chaining**                  | 체인 볼륨 타입 여부('true' or 'false')                                | String |
> **Shard**                     | 샤딩적용 유무'true' or 'false')                                       | String |
> **Shard_Block_Size**          | 샤딩 블록 사이즈 결정 ('512MB' or '1GB' or '2GB' or '4GB')            | String |
> **External_Target**           | 공유자원의 절대경로 (/Shard/NFS/OR/SNFS/PATH)                         | String |
> **External_Oprions**          | 공유자원의 공유 방식에 따른 옵션을 지정 할 수 있음                    | String |

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
> Argument   | Description       | Type   |
> --------   | -----------       | ----   |
> **return** | 'true' or 'false' | String |
> **code**   | ...               | String |
> **msg**    | ...               | String |
> **entity** | 0 or -1           | Int    |

***

### 3. volume extend

* 클러스터 볼륨 scale-in 확장 API

> #### 요청 인자 값
> ```
> {
>     secure-key: <KEY>,
>     argument: {
>         FS_Type:     ...,
>         Volume_Name: ...,
>         Extend_Size: ...,
>         Dry: ...,
>     },
> }
> ```
> Argument        | Description                       | Type   | 
> --------        | -----------                       | ----   | 
> **FS_Type**     | 'Gluster'                         | String | 
> **Volume_Name** | 확장할 볼륨 이름                  | String | 
> **Extend_Size** | 확장 완료 후의 볼륨 크기 (4.0G)   | String |
> **Dry**         | 확장 가능 여부 질의 (true, false) | String |

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
> Argument   | Description       | Type         |
> --------   | -----------       | ----         |
> **return** | 'true' or 'false' | String       |
> **code**   | ...               | String       |
> **msg**    | ...               | String       |
> **entity** | 볼륨 명 or undef  | String|Undef |

***
