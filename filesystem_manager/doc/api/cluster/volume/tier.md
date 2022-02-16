# Cluster Volume API: Tiering

## API 개요

* **클러스터 볼륨에 대한 Tiering 설정 및 제어할 수 있는 API**

### 1. [/cluster/volume/tier/attach](#1-tier-attach)
### 2. [/cluster/volume/tier/list](#2-tier-list)
### 3. [/cluster/volume/tier/detach](#3-tier-detach)
### 4. [/cluster/volume/tier/reconfig](#4-tier-reconfiguration)
### 5. [/cluster/volume/tier/opts](#5-tier-options-configuration)

## API 설명

### 1. tier attach

* 클러스터 볼륨에 Hot tier를 설정하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:       "...",
>         Volume_Name:   "...",
>         Pool_Name:     "...",
>         Capacity:      "...",
>         Replica_Count: "...",
>         Node_List:     [ ... ]
>     }
> }
> ```
> Argument        | Description                       | Type   | Required |
> --------        | -----------                       | ----   | -------- |
> **FS_Type**     | 'glusterfs' or 'ceph' or 'maha'   | String | Y        |
> **Volume_Name** | Hot tier가 설정될 볼륨 명         | String | Y        |
> **Pool_Name**   | Hot tier용 LV를 생성할 볼륨 풀 명 | String | Y        |
> **Capacity**    | Hot tier의 크기                   | String | Y        |
> **Replica_Count** | Hot tier의 복제 수                | String | Y        |
> **Node_List**   | Hot tier가 설정될 노드 호스트 명  | Array  | Y        |

***

> #### 응답 결과 값
> ```
> {
>     return: "...",
>     code:   "...",
>     msg:    "...",
>     entity: "..."
> }
> ```
> Argument   | Description                                       | Type            |
> --------   | -----------                                       | ----            |
> **return** | 'true' or 'false'                                 | String          |
> **code**   | ...                                               | String          |
> **msg**    | ...                                               | String          |
> **entity** | Hot tier가 생성된 볼륨 명 또는 생성 실패 시 Undef | String or Undef |

***

### 2. tier list

* 현재 설정된 Hot tier 정보에 대한 목록을 반환하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:     "...",
>         Volume_Name: "..."
>     }
> }
> ```
> Argument        | Description                      | Type   | Required |
> --------        | -----------                      | ----   | -------- |
> **FS_Type**     | 'glusterfs' or 'ceph' or 'maha'  | String | Y        |
> **Volume_Name** | Hot tier의 정보를 가져올 볼륨 명 | String | N        |

***




> #### 응답 결과 값
> ```
> {
>     return: "...",
>     code:   "...",
>     msg:    "...",
>     entity: [ { 
>            Volume_Name:        "...",
>            Distributed_Count:  "...",
>            Replica_Count:      "...",
>            Tier_Type:          "...",
>            Size_Bytes:         "...",
>            Size:               "...",
>            Node_Info: [ {
>                    Status:     "...",
>                    Status_Msg: "...",
>                    Hostname:   "...",
>                    LV_Type:    "...",
>                    LV_Name:    "...",
>                    LV_Size:    "...",
>                    LV_Size_Bytes: "...",
>                    LV_Mount:   "...",
>                    LV_Used:    "...",
>                    Pool_Name:  "...",
>                } 
>            ]
> }
> ```  
> Argument          | Description                                         | Type           |
> --------          | -----------                                         | ----           |
> **return**        | 'true' or 'false'                                   | String         |
> **code**          | ...                                                 | String         |
> **msg**           | ...                                                 | String         |
> **entity**        | Hot tier 상태 값에 대한 Array                       | Array          |
> **Volume_Name**   | Hot tier가 생성된 볼륨 명                           | String         |
> **Distributed_Count** | Hot tier 분산 수                                | String         |
> **Replica_Count** | Hot tier 복제 수                                    | String         |
> **Tier_Type**     | Hot tier 타입 (thin or thick)                       | String         |
> **Size**          | Hot tier의 총 크기                                  | String         |
> **Size_Bytes**    | Hot tier의 총 크기 Byte 단위                        | String         |
> **Node_Info**     | Node 별 Hot tier 상세 정보                          | Array          |
> **Status**        | 상태 코드('OK' or 'ERR' or 'WARN')                  | String         |
> **Status_Msg**    | 상태 메시지                                         | String         |
> **Hostname**      | 노드 명                                             | String         |
> **LV_Type**       | Hot tier brick의 LV 타입 (thin or thick)            | String         |
> **LV_Name**       | Hot tier brick의 LV 이름                            | String         |
> **LV_Size**       | Hot tier brick의 LV 크기                            | String         |
> **LV_Size_Bytes** | Hot tier brick의 LV 크기 Byte 단위                  | String         |
> **LV_Mount**      | Hot tier brick LV 마운트 경로                       | String         |
> **LV_Used**       | Hot tier brick LV 현재 사용량(%)                    | String         |
> **Pool_Name**     | Hot tier brick LV가 속한 VG 명 또는 Thin Pool LV 명 | String         |

***

### 3. tier detach

* 클러스터 볼륨에 Hot tier를 제거하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:     "...",
>         Volume_Name: "..."
>     }
> }
> ```
> Argument        | Description                      | Type   | Required |
> --------        | -----------                      | ----   | -------- |
> **FS_Type**     | 'glusterfs' or 'ceph' or 'maha'  | String | Y        |
> **Volume_Name** | Hot tier가 제거될 볼륨 명        | String | Y        |

***

> #### 응답 결과 값
> ```
> {
>     return: "...",
>     code:   "...",
>     msg:    "...",
>     entity: "...",
> }
> ```
> Argument   | Description                                 | Type            |
> --------   | -----------                                 | ----            |
> **return** | 'true' or 'false'                           | String          |
> **code**   | ...                                         | String          |
> **msg**    | ...                                         | String          |
> **entity** | Hot tier가 제거된 볼륨 명 또는 실패시 Undef | String or Undef |

***

### 4. tier reconfiguration

* 티어링된 클러스터 볼륨의 Hot tier를 재 설정(확장/축소)하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:       "...",
>         Volume_Name:   "...",
>         Capacity:      "...",
>         Replica_Count: "...",
>         Node_List:     [ ... ]
>     }
> }
> ```
> Argument          | Description                      | Type   | Required |
> --------          | -----------                      | ----   | -------- |
> **FS_Type**       | 'glusterfs' or 'ceph' or 'maha'  | String | Y        |
> **Volume_Name**   | Hot tier가 설정될 볼륨 명        | String | Y        |
> **Capacity**      | Hot tier의 크기                  | String | Y        |
> **Replica_Count** | Hot tier의 복제 수               | String | Y        |
> **Node_List**     | Hot tier가 설정될 노드 호스트 명 | Array  | Y        |

***

> #### 응답 결과 값
> ```
> {
>     return: "...",
>     code:   "...",
>     msg:    "...",
>     entity: "..."
> }
> ```
> Argument   | Description                                       | Type            |
> --------   | -----------                                       | ----            |
> **return** | 'true' or 'false'                                 | String          |
> **code**   | ...                                               | String          |
> **msg**    | ...                                               | String          |
> **entity** | Hot tier가 재 설정된 볼륨 명 또는 요청 실패 시 Undef | String or Undef |

***

### 5. tier options configuration

* 기 생성된 클러스터 볼륨의 옵션을 조회/변경하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:     "...",
>         Volume_Name: "...",
>         Action_Type: "...",
>         Tier_Opts: { 
>             Tier_Pause:     "...",
>             Tier_Mode:      "...",
>             Tier_Max_MB:    "...",
>             Tier_Max_Files: "...",
>             Watermark:      { High:      "...", Low : "..." },
>             IO_Threshold:   { Read_Freq: "...", Write_Freq : "..." },
>             Migration_Freq: { Promote:   "...", Demote : "..." }
>         }  
>     }
> }
> ```
> Argument            | Description                                                            | Type     | Required           | Default | Boundary          |
> --------            | -----------                                                            | ----     | --------           | ------- | -----------       |
> **FS_Type**         | 'glusterfs' or 'ceph' or 'maha'                                        | String   | Y                  |         |                   |
> **Volume_Name**     | Hot tier가 설정될 볼륨 명                                              | String   | Y                  |         |                   |
> **Action_Type**     | 옵션 API 요청 타입('get' or 'set')                                     | String   | Y                  |         |                   |
> **Tier_Opts**       | 요청이 set일 경우, 추가될 옵션 값들                                    | Hash     | N ('Set'일 경우 Y) |         |                   |
> **Tier_Pause**      | Tier 동작 상태                                                         | String   | N ('Set'일 경우 Y) | 'on'    | 'on' or 'off'     |
> **Tier_Mode**       | Tier 동작 모드                                                         | String   | N ('Set'일 경우 Y) | 'cache' | 'cache' or 'test' |
> **Tier_Max_MB**     | File migration 시 최대 데이터 양(1회 시)                               | String   | N ('Set'일 경우 Y) | '4000'  | 1 ~ 100000        | 
> **Tier_Max_Files**  | File migration 시 최대 파일 수(1회 시)                                 | String   | N ('Set'일 경우 Y) | '10000' | 1 ~ 100000        |
> **Watermark**       | cache 모드일 경우, migration 동작 정책                                 | Hash     | N ('Set'일 경우 Y) |         |                   |      
> **High**            | cache 모드일 경우, promote 동작 방지 및 demote 발생 값(Hot tier Usage) | String   | N ('Set'일 경우 Y) | '90'    | 1 ~ 99            |
> **Low**             | cache 모드일 경우, demote 동작 방지 및 promote 가능 값(Hot tier Usage) | String   | N ('Set'일 경우 Y) | '75'    | 1 ~ 99            |
> **IO_Threshold**    | test 모드일경우, migration 동작 정책                                   | String   | N ('Set'일 경우 Y) |         |                   |
> **Read_Freq**       | 해당 회수 보다 Read 회수가 많은 경우, promote. 아닌경우 demote         | String   | N ('Set'일 경우 Y) | '0'     | 0 ~ 20            |
> **Write_Freq**      | 해당 회수 보다 Write 회수가 많은 경우, promote. 아닌경우 demote        | String   | N ('Set'일 경우 Y) | '0'     | 0 ~ 20            |
> **Migration_Freq**  | Tier간 migraition 시도 주기                                            | String   | N ('Set'일 경우 Y) |         |                   |
> **Promote**         | Cold -> Hot tier로 migration 시도 주기                                 | String   | N ('Set'일 경우 Y) | '120'   | 1 ~ 172800        |
> **Promote**         | Hot -> Cold tier로 migration 시도 주기                                 | String   | N ('Set'일 경우 Y) | '3600'  | 1 ~ 172800        |

***

> #### 응답 결과 값
> ```
> {
>     return: "...",
>     code:   "...",
>     msg:    "...",
>     entity: {
>         Volume_Name: "...",
>         Action_Type: "...",
>         Tier_Opts: { 
>             Tier_Pause:     "...",
>             Tier_Mode:      "...",
>             Tier_Max_MB:    "...",
>             Tier_Max_Files: "...",
>             Watermark:      { High:      "...", Low : "..." },
>             IO_Threshold:   { Read_Freq: "...", Write_Freq : "..." },
>             Migration_Freq: { Promote:   "...", Demote : "..." }
>         }  
>     }
> }
> ```
> Argument   | Description                                                    | Type          |
> --------   | -----------                                                    | ----          |
> **return** | 'true' or 'false'                                              | String        |
> **code**   | ...                                                            | String        |
> **msg**    | ...                                                            | String        |
> **entity** | API 요청 반환 값(내부 값 설명은 상단 요청 값 설명 참조)        | Hash or Undef |

***
