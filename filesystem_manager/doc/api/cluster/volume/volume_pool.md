# Cluster Volume API: Volume Pool

## API 개요

### 1. [/cluster/volume/pool/create](#1-volume-pool-create)
### 2. [/cluster/volume/pool/list](#2-volume-pool-list)
### 3. [/cluster/volume/pool/remove](#2-volume-pool-remove)
### 4. [/cluster/volume/pool/extend](#2-volume-pool-extend)

## API 설명

* 볼륨 풀을 생성/삭제/조회 하는 API

### 1. volume pool create

* 볼륨 풀을 생성하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:   "...",
>         Pool_Type: "...",
>         Pool_Desc: "...",
>         Capacity:  "...",
>         Base_Pool: "...",
>         Node_Info: [ {
>                 Hostname: "...",
>                 PVs:      [ { Name : "..." } ]
>             } ],
>        External_IP: "...", 
>        External_Type: "...", 
>     }
> }
> ```
> Argument        | Description                                         | Type   | Required | Boundary                    |
> --------        | -----------                                         | ----   | -------- | --------                    |
> **FS_Type**     | 'Gluster' or 'ceph' or 'maha' or 'External'         | String | Y        |                             |
> **Pool_Type**   | 생성할 볼륨 풀 타입                                 | String | Y        | 'thick' or 'thin'           |
> **Pool_Desc**   | 생성할 볼륨 풀 사용의 예                            | String | Y        | 'for_data' or 'for_tiering' |
> **Capacity**    | thin type 일 경우, 생성할 볼륨 풀의 용량            | String | N        | MB, GB, TB 단위             |
> **Base_Pool**   | thin type 일 경우, thick 볼품 명(VG)                | String | N        |                             |
> **Node_Info**   | 노드 정보                                           | Hash   | N        |                             |
> **Hostname**    | 노드 Hostname                                       | String | N        |                             |
> **PVs**         | 생성할 볼륨 풀(thick)의 멤버 block device 배열      | Array  | N        |                             |
> **PVs{Name}**   | 생성할 볼륨 풀(thick)의 멤버 block device 명        | String | N        | /dev/sdb, /dev/sdc, ...     |
> **External_IP   | 외부 볼륨풀을 제공하는 서버의 IP                    | String | N        | 192.000.000.000             |
> **External_Type | 외부 볼륨풀을 제공하는 볼륨풀 유형('NFS' or 'SNFS') | String | N        | 'NFS' or 'SNFS'             | 

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
> Argument   | Description       | Type            |
> --------   | -----------       | ----            |
> **return** | 'true' or 'false' | String          |
> **code**   | ...               | String          |
> **msg**    | ...               | String          |
> **entity** | 생성된 볼륨 풀 명 | String or Undef |

***

### 2. volume pool list

* 생성된 볼륨 풀의 목록을 반환하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:   "...",
>         Pool_Name: "...",
>     }
> }
> ```
> Argument      | Description                                   | Type   | Required |
> --------      | -----------                                   | ----   | -------- |
> **FS_Type**   | 'Gluster' or 'ceph' or 'maha'                 | String | Y        |
> **Pool_Name** | 조회할 볼륨 풀 명, 없을 경우 모든 목록을 반환 | String | N        |

***

> #### 응답 결과 값
> ```
> {
>     return: "...",
>     code:   "...",
>     msg:    "...",
>     entity: [ {
>            Pool_Name : "...",
>            Pool_Type : "...",
>            Pool_Size : "...",
>            Pool_Size_Bytes : "...",
>            Pool_Free_Size : "...",
>            Pool_Free_Size_Bytes : "...",
>            Pool_Used : "...",
>            Pool_Status : "...",
>            Pool_Status_Msg : "...",
>            Pool_Status_Detail : [ "..." ],
>            Volume_Count : "...",
>            Base_Pool : "...",
>            Node_List : [ "..." ],
>            Node_Info : [ {
>                    Hostname : "...",
>                    Used : "...", 
>                    PVs  : [ { Name : "...", In_Use : "..." } ] 
>               } ],
>        }, ]
> }
> ```
> Argument                    | Description                                                           | Type           |
> --------                    | -----------                                                           | ----           |
> **return**                  | 'true' or 'false'                                                     | String         |
> **code**                    | ...                                                                   | String         |
> **msg**                     | ...                                                                   | String         |
> **entity**                  | 생성된 볼륨 풀 목록                                                   | Array          |
> **Pool_Name**               | 볼륨 풀 명                                                            | String         |
> **Pool_Type**               | 볼륨 풀 타입(thin, thick)                                             | String         |
> **Pool_Size**               | 볼륨 풀 최대 가용량(GB, TB)                                           | String         |
> **Pool_Size_Bytes**         | 볼륨 풀 최대 가용량(Bytes)                                            | String         |
> **Pool_Free_Size**          | 볼륨 풀 현재 가용량(GB, TB)                                           | String         |
> **Pool_Free_Size_Bytes**    | 볼륨 풀 현재 가용량(Bytes)                                            | String         |
> **Pool_Used**               | 볼륨 풀 사용률(%)                                                     | String         |
> **Pool_Status**             | 볼륨 풀 상태 값(OK, WARN, ERROR)                                      | String         |
> **Pool_Status_Msg**         | 볼륨 풀 대표 상태 메시지                                              | String         |
> **Pool_Status_Detail**      | 볼륨 풀 상태 상세 메시지                                              | Array          |
> **Volume_Count**            | 볼륨 풀내 생성된 볼륨들의 개수                                        | String         |
> **Base_Pool**               | thin 볼륨 풀인 경우 베이스가 되는 thick 볼륨 풀 명                    | String         |
> **Node_List**               | 볼륨 풀을 구성하는 멤버 노드 목록                                     | Array          | 
> **Node_Info**               | 볼륨 풀을 구성하는 멤버 노드에 대한 상세 정보                         | Hash           |
> **$hostname{Used}**         | 노드의 볼륨 풀 리소스(thin pool LV, VG)의 가용률(%)                   | String         |
> **$hostname{PVs}**          | thick 볼륨 풀인 경우, 노드의 볼륨 풀 리소스를 구성하는 PV 목록        | Array          | 
> **$hostname{PVs}#{Name}**   | thick 볼륨 풀인 경우, 노드의 볼륨 풀 리소스를 구성하는 PV 명          | String         | 
> **$hostname{PVs}#{In_Use}** | thick 볼륨 풀인 경우, 노드의 볼륨 풀 리소스를 구성하는 PV의 사용 여부 | String         | 

***

### 3. volume pool remove

* 생성된 볼륨 풀을 삭제하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:   "...",
>         Pool_Name: "...",
>     }
> }
> ```
> Argument      | Description                   | Type   | Required |
> --------      | -----------                   | ----   | -------- |
> **FS_Type**   | 'Gluster' or 'ceph' or 'maha' | String | Y        |
> **Pool_Name** | 삭제할 볼륨 풀 명             | String | Y        |

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
> Argument   | Description       | Type            |
> --------   | -----------       | ----            |
> **return** | 'true' or 'false' | String          |
> **code**   | ...               | String          |
> **msg**    | ...               | String          |
> **entity** | 삭제된 볼륨 풀 명 | String or Undef |

***

### 4. volume pool reconfig

* 기 생성된 볼륨 풀을 재설정하는 API (확장/축소)
    
    * Node_Info의 입력 값에 따라 확장 및 축소를 실행

      * External 볼륨 또한 Node_Info 아래 내용을 따름 

    * 확장/축소 타입

      * 노드 확장/축소

        * thick 볼륨 풀

            * 확장 : 지정된 노드 별 새로운 볼륨 풀(VG)을 생성
            * 축소 : 미 지정된 노드의 해당 볼륨 풀(VG)이 있을 경우, 볼륨 풀(VG)을 제거

                * 축소시, 해당 볼륨 풀(VG)에 LV가 있을 경우, 실패 처리

        * thin 볼륨 풀

            * 확장 : 지정된 노드 별 새로운 볼륨 풀(Thin Pool LV)을 생성
            * 축소 : 지정된 노드 별 볼륨 풀(Thin Pool LV)을 제거

                * 축소시, 해당 볼륨 풀(Thin Pool LV)와 연관된 LV가 있을 경우, 실패 처리

      * Block device 크기 확장/축소

        * thick 볼륨 풀

            * 확장 : 지정된 노드 별 볼륨 풀(VG)에서 지정된 Block device(PV)를 추가
            * 축소 : 지정된 노드 별 볼륨 풀(VG)에서 지정된 Block device(PV)를 제거
                
                * 축소시, PV에 LV가 설정되어 있는 경우 실패 처리

        * thin 볼륨 풀
        
            * 확장 : 지정된 노드 별 볼륨 풀(Thin Pool LV)의 크기를 확장

                * Thin Pool LV가 속한 VG의 가용량이 부족한 경우 실패 처리

            * 축소 : thin 볼륨 풀은 크기 축소 불가 
            
                * 사유 : Thin Pool LV에 대한 LVM CLI는 미 지원

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_Type:   "...",
>         Pool_Name: "...",
>         Capacity:  "...",
>         Node_Info: [ {
>                 Hostname: "...",
>                 PVs:      [ { Name: "..." } ]
>             } ],
>     }
> }
> ```
> Argument      | Description                                       | Type   | Required | Boundary                 |
> --------      | -----------                                       | ----   | -------- | --------                 |
> **FS_Type**   | 'Gluster' or 'ceph' or 'maha' or 'External        | String | Y        |                          |
> **Pool_Name** | 재 설정할 볼륨 풀 명                              | String | Y        |                          |
> **Capacity**  | thin type 일 경우, 변경할 볼륨 풀의 용량          | String | N        | MB, GB, TB 단위          |
> **Node_Info** | 노드 정보                                         | Hash   | N        |                          |
> **Hostname**  | 노드 Hostname                                     | String | N        |                          |
> **PVs**       | 재 설정할 볼륨 풀(thick)의 멤버 block device 배열 | Array  | N        |                          |
> **PVs{Name}** | 재 설정할 볼륨 풀(thick)의 멤버 block device 배열 | String | N        | /dev/sdb, /dev/sdc, ...  |

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
> Argument   | Description         | Type            |
> --------   | -----------         | ----            |
> **return** | 'true' or 'false'   | String          |
> **code**   | ...                 | String          |
> **msg**    | ...                 | String          |
> **entity** | 재설정된 볼륨 풀 명 | String or Undef |

***
