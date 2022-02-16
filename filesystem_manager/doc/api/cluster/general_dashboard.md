 Cluster API: General & Dashboard

## API 인덱스

#### 1. [/cluster/general/nodelist](#1-clustergeneralnodelist-1)
#### 2. [/cluster/general/master](#2-clustergeneralmaster-1)
#### 3. [/cluster/general/setdebug](#3-clustergeneralsetdebug-1)
#### 4. [/cluster/general/getdebug](#4-clustergeneralgetdebug-1)
#### 5. [/cluster/status](#5-clusterstatus-1)
#### 6. [/cluster/nodes](#6-clusternodes-1)
#### 7. [/cluster/dashboard/clientgraph](#7-clusterdashboardclientgraph-1)
#### 8. [/cluster/dashboard/procusage](#8-clusterdashboardprocusage-1)
#### 9. [/cluster/dashboard/netstats](#9-clusterdashboardnetstats-1)
#### 10. [/cluster/dashboard/fsstats](#10-clusterdashboardfsstats-1)
#### 11. [/cluster/dashboard/fsusage](#11-clusterdashboardfsusage-1)
#### 12. [/cluster/event/count](#12-clustereventcount-1)
#### 13. [/cluster/event/list](#13-clustereventlist-1)
#### 14. [/cluster/task/count](#14-clustertaskcount-1)
#### 15. [/cluster/task/list](#15-clustertasklist-1)
#### 16. [/cluster/power/shutdown](#16-clusterpowershutdown-1)
#### 17. [/cluster/power/reboot](#17-clusterpowerreboot-1)
#### 18. [/general/nodedesc](#18-generalnodedesc-1)

## 개요

* 클러스터 Scope에서 필요한 일반적인 API와 대시보드에 사용되는 API

## API 목록

### 1. /cluster/general/nodelist

* 클러스터 노드목록을 요청하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: | 
> 
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [{
>           Storage_Hostname,
>           Storage_IP,
>           Mgmt_Hostname,
>           Mgmt_IP,
>           Physical_Block_Size,
>           CPU,
>           Memory,
>           HW_Status,
>           SW_Status,
>           Stage,
>           Node_Used,
>           Node_Free_Size,
>           Node_Free_Size_Byte,
>           Tp_List : [{
>               Pool_Name,
>               Pool_Used,
>               Pool_Free_Size
>           }], 
>           Service_IP : [
>               IP1, IP2, IP3, ...
>           ],
>           Management: [
>               'expand', 'support', ...
>           ],
>           Version
>     }],
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array |
> **entity/0~n**   | 데이터를 담은 해쉬                          | Hash|
> **entity/0~n/Storage_Hostname**   | 노드의 스토리지 네트워크 호스트명| String |
> **entity/0~n/Storage_IP**   | 노드의 스토리지 네트워크 IP| String |
> **entity/0~n/Mgmt_Hostname**   | 노드의 관리 네트워크 호스트명| String |
> **entity/0~n/Mgmt_IP**   | 노드의 관리 네트워크 IP| String |
> **entity/0~n/Physical_Block_Size**   | 노드의 물리 디스크 전체 용량 합산치 | String |
> **entity/0~n/CPU**   | 노드의 CPU 모델명, 성능 | String |
> **entity/0~n/Memory**   | 노드의 총 Memory 크기 | String |
> **entity/0~n/HW_Status**   | 장비 상태 | String (ex: OK,  WARN,  ERR )|
> **entity/0~n/SW_Status**   | 서비스 상태 | String (ex: OK, WARN, ERR )|
> **entity/0~n/Stage**   | 스테이지 정보 | String |
> **entity/0~n/Node_Used**   | 저장공간 사용량 | Integer (%) |
> **entity/0~n/Node_Free_Size**   | 남은 저장용량| String (ex: '10T' )|
> **entity/0~n/Node_Free_Size_Byte**   | 남은 저장용량을 Byte로 표기| Integer|
> **entity/0~n/Tp_List**   | Thin 볼륨 풀을 가진 리스트 | Array |
> **entity/0~n/Tp_Lis/0~n/**   | Thin 볼륨 풀 정볼르 가진 해쉬 | Hash |
> **entity/0~n/Tp_Lis/0~n/Pool_Name**   | Thin 볼륨 풀의 이름| String |
> **entity/0~n/Tp_Lis/0~n/Pool_Used**   | Thin 볼륨 풀 사용량| Interger (%)|
> **entity/0~n/Tp_Lis/0~n/Pool_Free_Size**   | Thin 볼륨 풀의 남은 저장용량 | String (ex: '1T' )|
> **entity/0~n/Service_IP**   | 서비스 IP 목록| Array|
> **entity/0~n/Management**   | 요청가능한 Stage 목록| Array|
> **entity/0~n/Version**   | 노드에 설치된 버전 | String|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 2. /cluster/general/master

* 클러스터의 마스터정보를 요청하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: | 
> 
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : {
>         Hostname,
>         Mgmt_ip,
>         Storage_ip,
>         Service_ip,
>     },
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity/Hostname**   | 마스터의 호스트명| String |
> **entity/Mgmt_ip**   | 마스터의 관리 IP| String |
> **entity/Storage_ip**   | 마스터의 스토리지 네트워크 IP | String |
> **entity/Service_ip**   | 마스터의 서비스   네트워크 IP | Array  |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 3. /cluster/general/setdebug

* 디버그 모드를 변경하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         scope,
>         value
>     }
> }
> ```
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: | 
> **scope**      | 디버그 모드를 활성화 할 모듈의 Scope| String| N | all |
> **value**      | 활성화/비활성화 여부| Integer| Y | enable/disable |
> 
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [{
>     }],
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 4. /cluster/general/getdebug

* 디버그 모드를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: | 
> **scope**      | 디버그 모드를 조회할 모듈의 Scope| String| N | all |
> 
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [{
>         'scope1' : '0|1',
>         'scope2' : '0|1',
>         'scope3' : '0|1',
>     }],
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array |
> **entity/0**   | 데이터를 담은 해쉬                          | Array  |
> **entity/0/scope1,2,3,...**   | 모듈명을 키로 enable,disable 여부를 가짐| String |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *


### 5. /cluster/status

* 대시보드에서 클러스터 상태를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [{,
>         Cluster_Name,
>         Version,
>         Status,
>         Reason,
>         Msg,
>     }],
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array  |
> **entity/0**   | 데이터를 담은 해쉬                          | Array  |
> **entity/0/Cluster_Name**   | 클러스터명 | String |
> **entity/0/Version**   | 클러스터 버전| String |
> **entity/0/Status**   | 클러스터 상태| String (ex: OK, WARN, ERR) |
> **entity/0/Reason**   | 상태 정보| String (ex: healthy, etc.) |
> **entity/0/Msg**   | 클러스터 상태에 대한 메시지| String |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 6. /cluster/nodes

* 대시보드에서 노드 상태를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [{
>         Status,
>         Status_Details : {
>             'component1' : 'ERR',
>             'component2' : WARN'
>         }
>         Mgmt_Hostname,
>         Mgmt_IP,
>         Service_IP : [
>             IP1, IP2, IP3, ... 
>         ],
>         Netw_In_Byte_Sec,
>         Netw_Out_Byte_Sec,
>         Strg_In_Byte_Sec,
>         Strg_Out_Byte_Sec,
>         Node_Used_Size,
>         Node_All_Size,
>         Node_Usage,
>         Stage,
>     }],
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Array  |
> **entity/0~n**   | 데이터를 담은 해쉬   | Hash|
> **entity/0~n/Status**   | 노드 상태| String (ex: OK, WARN, ERR) |
> **entity/0~n/Status_Details**   | 노드 상태가 WARN이나 ERR일때 상세 정보| Hash |
> **entity/0~n/Mgmt_Hostname**   | 관리 네트워크의 호스트명| String |
> **entity/0~n/Mgmt_IP**   | 관리 네트워크의 IP| String |
> **entity/0~n/Service_IP**   | 서비스 IP 리스트| Array |
> **entity/0~n/Netw_In_Byte_Sec**   | 네트워크 In 성능| Interger |
> **entity/0~n/Netw_Out_Byte_Sec**   | 네트워크 Out 성능| Interger |
> **entity/0~n/Strg_In_Byte_Sec**   | 스토리지 In 성능| Interger |
> **entity/0~n/Strg_Out_Byte_Sec**   | 스토리지 Out 성능| Interger |
> **entity/0~n/Node_Used_Size**   | 디스크 사용량| Interger |
> **entity/0~n/Node_All_Size**   | 디스크 전체 크기| Interger |
> **entity/0~n/Node_Usage**   | 디스크 사용률 | Interger (%) |
> **entity/0~n/Stage**   | 스테이지 정보 | String |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 7. /cluster/dashboard/clientgraph

* 클러스터 대시보드에서 클라이언트 현황 그래프 정보를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [{
>         key,
>         Client,
>         Performance,
>     }],
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Array  |
> **entity/0~n**   | 데이터를 담은 해쉬        | Hash  |
> **entity/0~n/key**   | 노드명 (x축 라벨)  | String|
> **entity/0~n/Client**   | 클라이언트 수     | Integer |
> **entity/0~n/Performance**   | 성능 값 (서비스 네트워크 인터페이스의 성능)      | Integer |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 8. /cluster/dashboard/procusage

* 클러스터 대시보드에서 CPU 그래프 정보를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Limit,
>         Interval
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **Limit**      | 최대 자료 개수 | Integer | N | 10 |
> **Interval**   | 자료 간 간격 (초단위)      | Integer | N | 60 |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         is_available,
>         data : [{
>             key,
>             User,
>             System,
>             IOWait
>         }],
>     },
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Hash |
> **entity/is_avasilable**   | 성능 데이터에 접근 가능한지 여부 | String (ex: 'true' or 'false')|
> **entity/data**   | 성능 데이터를 담은 변수   | Array|
> **entity/data/0~n**   | 성능 데이터를 담은 해쉬   | Hash |
> **entity/data/0~n/key**   | 레이블  | String|
> **entity/data/0~n/User**   | 사용자 영역의 프로세서 점유율 | Integer|
> **entity/data/0~n/System**   | 시스템 영역의 프로세서 점유율 | Integer|
> **entity/data/0~n/IOWait**   | 입출력에 소요된 프로세서 점유율| Integer|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 9. /cluster/dashboard/netstats

* 클러스터 대시보드에서 네트워크 그래프 정보를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Limit,
>         Interval
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **Limit**      | 최대 자료 개수 | Integer | N | 10 |
> **Interval**   | 자료 간 간격 (초단위)      | Integer | N | 60 |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         is_available,
>         data : [{
>             key,
>             Send,
>             Recv
>         }],
>     },
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Hash |
> **entity/is_avasilable**   | 성능 데이터에 접근 가능한지 여부 | String (ex: 'true' or 'false')|
> **entity/data**   | 성능 데이터를 담은 변수   | Array|
> **entity/data/0~n**   | 성능 데이터를 담은 해쉬   | Hash |
> **entity/data/0~n/key**   | 레이블  | String|
> **entity/data/0~n/Send**   | 보낸 데이터량| Integer|
> **entity/data/0~n/Recv**   | 받은 데이터량 | Integer|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 10. /cluster/dashboard/fsstats

* 클러스터 대시보드에서 클러스터 성능 그래프 정보를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Limit,
>         Interval
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **Limit**      | 최대 자료 개수 | Integer | N | 10 |
> **Interval**   | 자료 간 간격 (초단위)      | Integer | N | 60 |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         is_available,
>         data : [{
>             key,
>             Read,
>             Write 
>         }],
>     },
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Hash |
> **entity/is_avasilable**   | 성능 데이터에 접근 가능한지 여부 | String (ex: 'true' or 'false')|
> **entity/data**   | 성능 데이터를 담은 변수   | Array|
> **entity/data/0~n**   | 성능 데이터를 담은 해쉬   | Hash |
> **entity/data/0~n/key**   | 레이블  | String|
> **entity/data/0~n/Read**   | 읽기 데이터량| Integer|
> **entity/data/0~n/Write**   | 쓴 데이터량 | Integer|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 11. /cluster/dashboard/fsusage

* 클러스터 대시보드에서 클러스터 사용량 그래프 정보를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         is_available,
>         data : [{
>             key,
>             Using,
>             Free
>         }],
>     },
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Hash |
> **entity/is_avasilable**   | 성능 데이터에 접근 가능한지 여부 | String (ex: 'true' or 'false')|
> **entity/data**   | 성능 데이터를 담은 변수   | Array|
> **entity/data/0~n**   | 성능 데이터를 담은 해쉬   | Hash |
> **entity/data/0~n/key**   | 식별자 | String|
> **entity/data/0~n/Using**   | 사용률| Integer|
> **entity/data/0~n/Free**   | 가용률 | Integer|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 12. /cluster/event/count

* 이벤트 갯수를 반환하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         From,
>         To,
>         Type,
>         Category,
>         Scope,
>         Message
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **From**      | 시작 시간 (초 단위)| Integer| N | - |
> **To**      | 종료 시간 (초 단위)| Integer| N | - |
> **Type**      | 사건 유형| String (ex: COMMAND, MONITOR, ...)| N |  - |
> **Category**      | 사건 범주 | String (ex: ACCOUNT, NETWORK, ...)| N |  - |
> **Scope**      | 범위| String (ex: 노드명, cluster)| N |  - |
> **Message**      | 내용 | String | N |  - |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         info,
>         warn,
>         err 
>     },
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Hash |
> **entity/info**   | info 수준의 이벤트 개수 | Integer|
> **entity/warn**   | warn 수준의 이벤트 개수 | Integer|
> **entity/err**   | err 수준의 이벤트 개수| Integer|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 13. /cluster/event/list

* 이벤트 목록을 반환하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         NumOfRecords,
>         PageNum,
>         From,
>         To,
>         Type,
>         Category,
>         Level,
>         Scope,
>         Message 
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **NumOfRecords**      | 레코드 개수| Integer| N | - |
> **PageNujm**      | 페이지 번호| Integer| N | - |
> **From**      | 시작 시간 (초 단위)| Integer| N | - |
> **To**      | 종료 시간 (초 단위)| Integer| N | - |
> **Type**      | 사건 유형| String (ex: COMMAND, MONITOR, ...) | N |  - |
> **Category**      | 사건 범주 | String (ex: ACCOUNT, NETWORK, ...) | N |  - |
> **Level**      | 사건 수준 | String (ex: INFO, WARN, ERR)| N |  - |
> **Scope**      | 범위| String (ex: 노드명, cluster)| N |  - |
> **Message**      | 내용 | String | N |  - |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         total,
>         events : [{
>             ID,
>             Scope,
>             Level,
>             Type,
>             Category,
>             Message,
>             Details : {
>                 'key' : 'value', 
>             },
>             Time,
>             Quiet,
>         }]
>     },
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Hash |
> **entity/total**   | 전체 레코드 수 | Integer|
> **entity/events**   | 전체 이벤트 목록을 담은 변수| Array|
> **entity/events/0~n**   | 이벤트 정보를 담은 해쉬| Hash|
> **entity/events/0~n/ID**   |식별자| String|
> **entity/events/0~n/Scope**   | 범위| String|
> **entity/events/0~n/Level**   | 수준| String|
> **entity/events/0~n/Type**   | 유형| String|
> **entity/events/0~n/Category**   | 구분| String|
> **entity/events/0~n/Message**   | 내용| String|
> **entity/events/0~n/Details**   | 상세 내용| Hash|
> **entity/events/0~n/Time**   | 시간| String|
> **entity/events/0~n/Quiet**   | 조용히| String|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 14. /cluster/task/count

* 태스크 갯수를 반환하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         From,
>         To,
>         Type,
>         Category,
>         Scope,
>         Message 
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **From**      | 시작 시간 (초 단위)| Integer| N | - |
> **To**      | 종료 시간 (초 단위)| Integer| N | - |
> **Type**      | 작업 유형| String (ex: COMMAND, MONITOR, ...)| N |  - |
> **Category**      | 작업 범주 | String (ex: ACCOUNT, NETWORK, ...)| N |  - |
> **Scope**      | 범위| String (ex: 노드명, cluster)| N |  - |
> **Message**      | 내용 | String | N |  - |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         info,
>         warn,
>         err
>     },
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Hash |
> **entity/info**   | info 수준의 태스크 개수 | Integer|
> **entity/warn**   | warn 수준의 태스크 개수 | Integer|
> **entity/err**   | err 수준의 태스크 개수| Integer|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 15. /cluster/task/list

* 태스크 목록을 반환하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         NumOfRecords,
>         PageNum,
>         From,
>         To,
>         Type,
>         Category,
>         Level,
>         Scope,
>         Message 
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **NumOfRecords**      | 레코드 개수| Integer| N | - |
> **PageNujm**      | 페이지 번호| Integer| N | - |
> **From**      | 시작 시간 (초 단위)| Integer| N | - |
> **To**      | 종료 시간 (초 단위)| Integer| N | - |
> **Type**      | 작업 유형| String (ex: COMMAND, MONITOR, ...)| N |  - |
> **Category**      | 작업 범주 | String (ex: ACCOUNT, NETWORK, ...)| N |  - |
> **Level**      | 작업 수준 | String (ex: INFO, WARN, ERR)| N |  - |
> **Scope**      | 범위| String (ex: 노드명, cluster)| N |  - |
> **Message**      | 내용 | String | N |  - |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         total,
>         tasks : [{
>             ID,
>             Scope,
>             Level,
>             Type,
>             Category,
>             Message,
>             Details : {
>                 'key' : 'value', 
>             },
>             Time,
>             Quiet,
>         }]
>     },
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Hash |
> **entity/total**   | 전체 레코드 수 | Integer|
> **entity/tasks**   | 전체 태스크 목록을 담은 변수| Array|
> **entity/tasks/0~n**   | 태스크 정보를 담은 해쉬| Hash|
> **entity/tasks/0~n/ID**   |식별자| String|
> **entity/tasks/0~n/Scope**   | 범위| String|
> **entity/tasks/0~n/Level**   | 수준| String|
> **entity/tasks/0~n/Type**   | 유형| String|
> **entity/tasks/0~n/Category**   | 구분| String|
> **entity/tasks/0~n/Message**   | 내용| String|
> **entity/tasks/0~n/Details**   | 상세 내용| Hash|
> **entity/tasks/0~n/Time**   | 시간| String|
> **entity/tasks/0~n/Quiet**   | 조용히| String|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 16. /cluster/power/shutdown

* 클러스터 전원을 종료하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity,
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Array|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 17. /cluster/power/reboot

* 클러스터를 재시작하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity,
>     stage_info : {
>         stage
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수      | Array|
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

### 18. /general/nodedesc

* 클러스터 노드목록을 요청하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>     }
> }
> ```
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: | 
> 
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [
>         { 'Hostname' },
>         { 'Product Name' },
>         { Manufacturer },
>         { Hardware Status },
>         { Software Status },
>         { CPU },
>         { Memory },
>         { Board },
>         { GMS Version },
>         { AnyCloud Version },
>         { GSM Version },
>         { GMS_commit Version },
>         { GSM_commit Version },
>         { Date Version },
>         {
>             Resource,
>             Category,
>             Code,
>             Status
>         }, ...
>     ],
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array |
> **entity/0~n**   | 데이터를 담은 해쉬                          | Hash|
> **entity/0~n/Hostname**   | 대상 노드의 호스트명| String |
> **entity/0~n/Product Name**   | 대상 노드의 하드웨어 이름 (ex: OK, WARN, ERR )| String |
> **entity/0~n/Manufacturer**   | 대상 노드의 하드웨어의 제작사 (ex: OK, WARN, ERR )| String | 
> **entity/0~n/Hardware Status**  | 대상 노드의 장비 상태| String |
> **entity/0~n/Software Status**  | 대상 노드의 서비스 상태| String |
> **entity/0~n/CPU**   | 대상 노드의 CPU 모델명, 성능 | String |
> **entity/0~n/Memory**   | 대상 노드의 총 Memory 크기 | String |
> **entity/0~n/Board**   | 대상 노드의 Matherboard 이름 | String |
> **entity/0~n/GMS Version**  | 대상 노드 GMS의 버전 | String |
> **entity/0~n/GSM Version**  | 대상 노드 GSM의 버전 | String |
> **entity/0~n/AnyCloud Version**   | 대상 노드 AnyCloud 버전 | String |
> **entity/0~n/GMS_commit Version** | 대상 노드의 GMS 마지막 commit 번호 | String |
> **entity/0~n/GSM_commit Version** | 대상 노드의 GSM 마지막 commit 번호 | String |
> **entity/0~n/Date Version** | 대상 노드의 소프트웨어가 패키징 된 날짜 | String |
> **entity/0~n/Resource_item** | 대상 노드를 구성하는 자원의 상태 (Resource, Category, Code, Status 를 포함하는 item) | Hash |
> **entity/0~n/Resource_item(Resource)** | 상태를 나타낼 대상 자원 | String |
> **entity/0~n/Resource_item(Category)** | 대상 자원의 분류 | String(ex: HW, service) |
> **entity/0~n/Resource_item(Code)** | 대상 자원의 상태를 나타내는 code | String |
> **entity/0~n/Resource_item(Status)** | 대상 자원의 상태(ex: OK, WARN, ERR ) | String |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *
