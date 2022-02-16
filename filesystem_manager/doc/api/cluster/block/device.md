# Block API: Device

## API 인덱스

#### 1. [/cluster/block/device/list](#1-clusterblockdevicelist-1)

## 개요

* 클러스터 API로 각 노드에 대한 블럭 디바이스의 정보를 조회/제어하는 API

## API 목록

### 1. /cluster/block/device/list

* 모든 노드의 블럭 디바이스의 정보를 scope에 맞게 조회하는 API

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
> **scope** | 조회할 block device의 범위를 정하는 변수[NO_OSDISK/NO_PART/NO_INUSE] | 'ALL'   | --     | N        |
> 
> * * *
> 
> #### 응답 결과값
> ```
> {
>     msg,
>     entity : [
>         {
>             Hostname,
>             Devices : [
>                 {
>                     DevName,
>                     Media_Type,
>                     Total_Size,
>                 }, ...
>             ],
>         },
>     ],
>     return
> }
> ```
> Argument                          | Description                                 | Type   |
> --------                          | -----------                                 | :----: |
> **msg**                           | 결과에 대한 설명을 담은 메시지              | String |
> **entity**                        | 데이터를 담은 변수                          | Array  |
> **entity/#/Hostname**             | 노드 명                                     | String |
> **entity/#/Devices**              | Block device들의 정보를 담은 변수           | Array  |
> **entity/#/Devices/#/DevName**    | Block device의 이름                         | String |
> **entity/#/Devices/#/Media_Type** | Block device의 디스크 타입(hdd/ssd)         | String |
> **entity/#/Devices/#/Total_Size** | Block device의 크기(Byte)                   | String |
> **return**                        | API의 성공 여부를 담는 변수                 | String |

* * *

