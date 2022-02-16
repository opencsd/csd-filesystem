# Node API: License

## API 인덱스

#### 1. [/system/license/uniq_key](#1-systemlicenseuniq_key-1)
#### 2. [/system/license/list](#2-systemlicenselist-1)
#### 3. [/system/license/summary](#3-systemlicensesummary-1)
#### 4. [/system/license/check](#4-systemlicensecheck-1)
#### 5. [/system/license/register](#5-systemlicenseregister-1)
#### 6. [/system/license/reload](#6-systemlicensereload-1)
#### 7. [/system/license/test](#7-systemlicensetest-1)

## 개요

* License 를 등록하고 조회하는 API

## API 목록

### 1. /system/license/uniq_key

* License 를 발급 받기 위해 필요한 클러스터 고유의 키를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { },
>     entity : { },
> }
> ```
> Argument  | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
> 
> Entity    | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
>
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [{
>         Unique_Key
>     }],
>     stage_info : {
>         stage,
>         data,
>         proc : {
>            total_rate,
>            nodes : [
>                {
>                    name,
>                    proc_rate,
>                    curr_proc,
>                    completed : [ 'Test 1', 'Test 2', 'Test 3', ...]
>                },
>            ] 
>         }
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array  |
> **entity/0** | 데이터를 담은 해쉬                          | Hash   |
> **entity/0/Unique_Key** | Unique_Key 값을 나타내는 변수    | String |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **stage_info/proc**   | 진행률 표기가 필요한 Stage 일 때 진행률 정보를 포함하는 해쉬 | Hash or undef |
> **stage_info/proc/total_rate**   | 전체 진행률을 나타내는 값| Integer (%)|
> **stage_info/proc/nodes**   | 모든 노드의 진행률 정보를 가진 변수  | Array |
> **stage_info/proc/nodes/0~n**   | 각 노드들의 진행률 정보를 가진 해쉬 | Hash |
> **stage_info/proc/nodes/0~n/name**   | 노드의 이름 | String |
> **stage_info/proc/nodes/0~n/proc_rate**   | 현재 진행중인 단계의 진행률 | Integer (%)|
> **stage_info/proc/nodes/0~n/curr_proc**   | 현재 진행중인 단계 | String |
> **stage_info/proc/nodes/0~n/completed**   | 완료된 단계를 담은 변수 | Array |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 2. /system/license/list

* 현재 등록된 license의 목록을 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { },
>     entity : { },
> }
> ```
> Argument  | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
> 
> Entity    | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [
>         {
>             Name,
>             Activation,
>             Expiration,
>             Licensed,
>             Status,
>             RegDate,   
>         },
>         ...
>     ],
>     stage_info : {
>         stage,
>         data,
>         proc : {
>            total_rate,
>            nodes : [
>                {
>                    name,
>                    proc_rate,
>                    curr_proc,
>                    completed : [ 'Test 1', 'Test 2', 'Test 3', ...]
>                },
>            ] 
>         }
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                              | Type   |
> --------     | -----------                              | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지           | String |
> **entity**   | 데이터를 담은 변수                       | Array  |
> **entity/0~n/Name**       | License 이름(종류)          | String |
> **entity/0~n/Activation** | License 활성화 날짜         | String |
> **entity/0~n/Expiration** | License 만료 날짜           | String |
> **entity/0~n/Licensed**   | 허가된 권한                 | String |
> **entity/0~n/Status**     | License 상태                | String |
> **entity/0~n/RegDate**    | License 등록 날짜           | String |
> **stage_info**   | stage 정보를 담는  변수              | Hash   |
> **stage_info/stage**   | Stage 값을 나타내는 변수       | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **stage_info/proc**   | 진행률 표기가 필요한 Stage 일 때 진행률 정보를 포함하는 해쉬 | Hash or undef |
> **stage_info/proc/total_rate**   | 전체 진행률을 나타내는 값| Integer (%)|
> **stage_info/proc/nodes**   | 모든 노드의 진행률 정보를 가진 변수  | Array |
> **stage_info/proc/nodes/0~n**   | 각 노드들의 진행률 정보를 가진 해쉬 | Hash |
> **stage_info/proc/nodes/0~n/name**   | 노드의 이름 | String |
> **stage_info/proc/nodes/0~n/proc_rate**   | 현재 진행중인 단계의 진행률 | Integer (%)|
> **stage_info/proc/nodes/0~n/curr_proc**   | 현재 진행중인 단계 | String |
> **stage_info/proc/nodes/0~n/completed**   | 완료된 단계를 담은 변수 | Array |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 3. /system/license/summary

* 등록된 License에 의해 활성화 된 기능/정보를 표시하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { },
>     entity : { },
> }
> ```
> Argument  | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
> 
> Entity    | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [
>         {
>             CIFS,
>             NFS,
>             ISCSI,
>             OS,
>             Demo,
>             ADS,
>             Support,
>             VolumeSize,
>             Nodes,
>         },
>         ...
>     ],
>     stage_info : {
>         stage,
>         data,
>         proc : {
>            total_rate,
>            nodes : [
>                {
>                    name,
>                    proc_rate,
>                    curr_proc,
>                    completed : [ 'Test 1', 'Test 2', 'Test 3', ...]
>                },
>            ] 
>         }
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                               | Type   |
> --------     | -----------                                               | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지                            | String |
> **entity**   | 데이터를 담은 변수                                        | Array  |
> **entity/0~n/CIFS**       | CIFS 사용 가능 여부                          | String |
> **entity/0~n/NFS**        | NFS 사용 가능 여부                           | String |
> **entity/0~n/ISCSI**      | ISCSI 사용 가능 여부                         | String |
> **entity/0~n/OS**         | GMS, GWM, GSM 사용 가능 여부                 | String |
> **entity/0~n/Demo**       | Demo License 여부                            | String |
> **entity/0~n/ADS**        | ADS 사용 가능 여부                           | String |
> **entity/0~n/Support**    | 기술 지원 유지보수 가능 여부(기간 만료 있음) | String |
> **entity/0~n/VolumeSize** | 생성 가능한 모든 클러스터 볼륨 크기의 합     | String |
> **entity/0~n/Nodes**      | 클러스터에 포함될 수 있는 최대 노드 수       | String |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **stage_info/proc**   | 진행률 표기가 필요한 Stage 일 때 진행률 정보를 포함하는 해쉬 | Hash or undef |
> **stage_info/proc/total_rate**   | 전체 진행률을 나타내는 값| Integer (%)|
> **stage_info/proc/nodes**   | 모든 노드의 진행률 정보를 가진 변수  | Array |
> **stage_info/proc/nodes/0~n**   | 각 노드들의 진행률 정보를 가진 해쉬 | Hash |
> **stage_info/proc/nodes/0~n/name**   | 노드의 이름 | String |
> **stage_info/proc/nodes/0~n/proc_rate**   | 현재 진행중인 단계의 진행률 | Integer (%)|
> **stage_info/proc/nodes/0~n/curr_proc**   | 현재 진행중인 단계 | String |
> **stage_info/proc/nodes/0~n/completed**   | 완료된 단계를 담은 변수 | Array |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

### 4. /system/license/check

* License를 사용하여 특정 기능이 사용 가능한지를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { Target },
>     entity : { },
> }
> ```
> Argument  | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> Target    | 확인 하려는 기능              | String | yes        | --        |
> 
> Entity    | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [{ Check_Info }],
>     stage_info : {
>         stage,
>         data,
>         proc : {
>            total_rate,
>            nodes : [
>                {
>                    name,
>                    proc_rate,
>                    curr_proc,
>                    completed : [ 'Test 1', 'Test 2', 'Test 3', ...]
>                },
>            ] 
>         }
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array  |
> **entity/0** | 데이터를 담은 해쉬                          | Hash   |
> **entity/0/Check_Info** | Check 결과를 나타내는 변수 ['yes' or 'no' or {Capablity}] | String |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **stage_info/proc**   | 진행률 표기가 필요한 Stage 일 때 진행률 정보를 포함하는 해쉬 | Hash or undef |
> **stage_info/proc/total_rate**   | 전체 진행률을 나타내는 값| Integer (%)|
> **stage_info/proc/nodes**   | 모든 노드의 진행률 정보를 가진 변수  | Array |
> **stage_info/proc/nodes/0~n**   | 각 노드들의 진행률 정보를 가진 해쉬 | Hash |
> **stage_info/proc/nodes/0~n/name**   | 노드의 이름 | String |
> **stage_info/proc/nodes/0~n/proc_rate**   | 현재 진행중인 단계의 진행률 | Integer (%)|
> **stage_info/proc/nodes/0~n/curr_proc**   | 현재 진행중인 단계 | String |
> **stage_info/proc/nodes/0~n/completed**   | 완료된 단계를 담은 변수 | Array |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 


### 5. /system/license/register

* 새로운 License 를 등록하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { },
>     entity : { LicenseKey },
> }
> ```
> Argument    | Description                                         | Type   | Required   | Default   |
> --------    | -----------                                         | :----: | :--------: | :-------: |    
> --          | --                                                  | --     | --         | --        |
> 
> Entity     | Description                                         | Type   | Required   | Default   |
> --------   | -----------                                         | :----: | :--------: | :-------: |    
> LicenseKey | 등록하려는 license key (license 서버에서 발급 받음) | String | --         | --        |
>
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [{
>         LicenseKey
>     }],
>     stage_info : {
>         stage,
>         data,
>         proc : {
>            total_rate,
>            nodes : [
>                {
>                    name,
>                    proc_rate,
>                    curr_proc,
>                    completed : [ 'Test 1', 'Test 2', 'Test 3', ...]
>                },
>            ] 
>         }
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array  |
> **entity/0** | 데이터를 담은 해쉬                          | Hash   |
> **entity/0/LicenseKey** | 등록 완료한 license key         | string |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **stage_info/proc**   | 진행률 표기가 필요한 Stage 일 때 진행률 정보를 포함하는 해쉬 | Hash or undef |
> **stage_info/proc/total_rate**   | 전체 진행률을 나타내는 값| Integer (%)|
> **stage_info/proc/nodes**   | 모든 노드의 진행률 정보를 가진 변수  | Array |
> **stage_info/proc/nodes/0~n**   | 각 노드들의 진행률 정보를 가진 해쉬 | Hash |
> **stage_info/proc/nodes/0~n/name**   | 노드의 이름 | String |
> **stage_info/proc/nodes/0~n/proc_rate**   | 현재 진행중인 단계의 진행률 | Integer (%)|
> **stage_info/proc/nodes/0~n/curr_proc**   | 현재 진행중인 단계 | String |
> **stage_info/proc/nodes/0~n/completed**   | 완료된 단계를 담은 변수 | Array |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 6. /system/license/reload

* License 를 새로 업데이트 하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { },
>     entity : { },
> }
> ```
> Argument  | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
> 
> Entity    | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
>
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [ ],
>     stage_info : {
>         stage,
>         data,
>         proc : {
>            total_rate,
>            nodes : [
>                {
>                    name,
>                    proc_rate,
>                    curr_proc,
>                    completed : [ 'Test 1', 'Test 2', 'Test 3', ...]
>                },
>            ] 
>         }
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array  |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **stage_info/proc**   | 진행률 표기가 필요한 Stage 일 때 진행률 정보를 포함하는 해쉬 | Hash or undef |
> **stage_info/proc/total_rate**   | 전체 진행률을 나타내는 값| Integer (%)|
> **stage_info/proc/nodes**   | 모든 노드의 진행률 정보를 가진 변수  | Array |
> **stage_info/proc/nodes/0~n**   | 각 노드들의 진행률 정보를 가진 해쉬 | Hash |
> **stage_info/proc/nodes/0~n/name**   | 노드의 이름 | String |
> **stage_info/proc/nodes/0~n/proc_rate**   | 현재 진행중인 단계의 진행률 | Integer (%)|
> **stage_info/proc/nodes/0~n/curr_proc**   | 현재 진행중인 단계 | String |
> **stage_info/proc/nodes/0~n/completed**   | 완료된 단계를 담은 변수 | Array |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 7. /system/license/test

* License에 의한 API 컨트롤을 확인 하기 위한 테스트용 API
* 'Test' license가 있으면 접근 허용
* 'Test' license가 없으면 접근 거부

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { },
>     entity : { }
> }
> ```
> Argument  | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
> 
> Entity    | Description                   | Type   | Required   | Default   |
> --------  | -----------                   | :----: | :--------: | :-------: |    
> --        | --                            | --     | --         | --        |
>
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [ ],
>     stage_info : {
>         stage,
>         data,
>         proc : {
>            total_rate,
>            nodes : [
>                {
>                    name,
>                    proc_rate,
>                    curr_proc,
>                    completed : [ 'Test 1', 'Test 2', 'Test 3', ...]
>                },
>            ] 
>         }
>     },
>     statuses,
>     return
> }
> ```
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array  |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **stage_info/proc**   | 진행률 표기가 필요한 Stage 일 때 진행률 정보를 포함하는 해쉬 | Hash or undef |
> **stage_info/proc/total_rate**   | 전체 진행률을 나타내는 값| Integer (%)|
> **stage_info/proc/nodes**   | 모든 노드의 진행률 정보를 가진 변수  | Array |
> **stage_info/proc/nodes/0~n**   | 각 노드들의 진행률 정보를 가진 해쉬 | Hash |
> **stage_info/proc/nodes/0~n/name**   | 노드의 이름 | String |
> **stage_info/proc/nodes/0~n/proc_rate**   | 현재 진행중인 단계의 진행률 | Integer (%)|
> **stage_info/proc/nodes/0~n/curr_proc**   | 현재 진행중인 단계 | String |
> **stage_info/proc/nodes/0~n/completed**   | 완료된 단계를 담은 변수 | Array |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

