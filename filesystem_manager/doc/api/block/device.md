# Block API: Device

## API 인덱스

#### 1. [/block/device/list](#1-blockdevicelist-1)
#### 2. [/block/device/info](#2-blockdeviceinfo-1)

## 개요

* 노드 API로 각 노드의 블록 장치 정보를 조회하고 갱신하는 API

## API 목록

### 1. /block/device/list

* 노드의 네트워크 장치 목록을 scope에 맞게 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { },
>     entity : { scope }
> }
> ```
> Argument  | Description                                                 | Type   | Required |
> --------  | -----------                                                 | :----: | :------: | 
> --        | --                                                          | --     | --       |
>
> Entity    | Description                                                 | default | Type   | Required |
> --------  | -----------                                                 | :-----: | :----: | :------: | 
> **scope** | 조회할 block device의 범위를 정하는 변수[NO_OSDISK/NO_PART] | 'ALL'   | --     | N        |
> 
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [
>         {
>             DevName,
>             Media_Type,
>             Total_Size,
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
> Argument                | Description                                 | Type   |
> --------                | -----------                                 | :----: |
> **msg**                 | 결과에 대한 설명을 담은 메시지              | String |
> **entity**              | 데이터를 담은 변수                          | Array  |
> **entity/#/DevName**    | Block device의 이름                         | String |
> **entity/#/Media_Type** | Block device의 디스크 타입(hdd/ssd)         | String |
> **entity/#/Total_Size** | Block device의 크기(Byte)                   | String |
> **stage_info**          | stage 정보를 담는  변수                     | Hash   |
> **stage_info/stage**    | Stage 값을 나타내는 변수                    | String |
> **stage_info/data**     | Stage에 필요한 추가 정보를 담는 변수        | String |
> **statuses**            | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**              | API의 성공 여부를 담는 변수                 | String |

* * *

### 2. /block/device/info

* 노드의 특정 Network Device의 상세 정보를 조회하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         devname,
>     },
>     entity : { }
> }
> ```
> Argument    | Description                            | Type   | Required |
> --------    | -----------                            | :----: | :------: | 
> **devname** | 조회 대상 block device를 지정하는 변수 | String | Y        | 
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : [
>         {
>             DevName,
>             Media_Type,
>             Total_Size,
>             is_os_disk,
>             is_in_use,
>         }
>     ],
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument                | Description                                 | Type   |
> --------                | -----------                                 | :----: |
> **msg**                 | 결과에 대한 설명을 담은 메시지              | String |
> **entity**              | 데이터를 담은 변수                          | Array  |
> **entity/0/DevName**    | Block device의 이름                         | String |
> **entity/0/Media_Type** | Block device의 디스크 타입(hdd/ssd)         | String |
> **entity/0/Total_Size** | Block device의 크기(Byte)                   | String |
> **entity/0/is_os_disk** | Block device가 os disk인지 아닌지를 나타냄  | String |
> **entity/0/is_in_use**  | Block device가 사용중인지 아닌지를 나타냄   | String |
> **stage_info**          | stage 정보를 담는  변수                     | Hash   |
> **stage_info/stage**    | Stage 값을 나타내는 변수                    | String |
> **stage_info/data**     | Stage에 필요한 추가 정보를 담는 변수        | String |
> **statuses**            | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**              | API의 성공 여부를 담는 변수                 | String |

* * *

