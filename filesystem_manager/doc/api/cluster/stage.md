# Cluster API: Stage

## API 인덱스

#### 1. [/cluster/stage/set](#1-clusterstageset-1)
#### 2. [/cluster/stage/get](#2-clusterstageget-1)
#### 3. [/cluster/stage/list](#3-clusterstagelist-1)
#### 4. [/cluster/stage/info](#4-clusterstageinfo-1)

## 개요

* 클러스터 API로 각 노드와 클러스터의 Stage 값을 설정/조회 할 수 있는 API

## API 목록

### 1. /cluster/stage/set

* Stage 를 설정하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Stage,
>         Scope,
>         Data
>     }
> }
> ```
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: |    
> **Stage** | 설정하고자 하는 Stage 값      | String | Y          | - |
> **Scope** | Stage의 범위: cluster, node   | String | N          | node |
> **Data**  | 해당 Stage에 필요한 데이터    | String | N          | - |
> 
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity,
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

### 2. /cluster/stage/get

* 현재 Stage 를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Scope
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |    
> **Scope**   | Stage의 범위: cluster, node   | String | Y          | - |
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [{
>         stage,
>         data
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
> **entity/0**   | 데이터를 담은 해쉬                         | Hash |
> **entity/0/stage**   | Stage 값을 나타내는 변수               | String |
> **entity/0/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
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

### 3. /cluster/stage/list

* set 가능한 Stage의 리스트를 반환하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Scope
>     }
> }
> ```
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |    
> **Scope**   | Stage의 범위: cluster, node   | String | Y          | - | 
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [
>         'running', 'support', ...
>     ]
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
> **entity**   | 데이터를 담은 변수: stage 종류를 반환       | Array  |
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

### 4. /cluster/stage/info

* 클러스터 노드 관리 페이지에서 클러스터의 스테이지 정보를 조회하는 API

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
>         Name,
>         Stage,
>         Status_Msg,
>         Total_Capacity,
>         Usage_Capacity,
>         Management: [
>             'support'
>         ]
>     }]
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
> **entity**   | 데이터를 담은 변수      | Array  |
> **entity/0**   | 데이터를 담은 해쉬        | Hash  |
> **entity/0/Name**   | 클러스터 명   | String |
> **entity/0/Stage**   | 클러스터 스테이지     | String |
> **entity/0/Status_Msg**   | 클러스터 상태 메시지        | String |
> **entity/0/Total_Capacity**   | 클러스터 전체 용량       | String (ex: '100T')  |
> **entity/0/Usage_Capacity**   | 클러스터 사용중인 용량    | String (ex: '10T') |
> **entity/0/Management**   | 사용가능한 스테이지 액션| Array|
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
