# Network API: Device

## API 인덱스

#### 1. [/network/device/list](#1-networkdevicelist-1)
#### 2. [/network/device/info](#2-networkdeviceinfo-1)
#### 3. [/network/device/update](#3-networkdeviceupdate-1)

## 개요

* 노드 API로 각 노드의 네트워크 장치 정보를 조회하고 갱신하는 API

## API 목록

### 1. /network/device/list

* 노드의 네트워크 장치 목록을 scope에 맞게 조회하는 API
* 각 scope의 의미

> ALL: 모든 NIC 장치 목록
> 
> NO_BOND: BOND를 제외한 NIC 장치 목록
> 
> NO_SLAVE: BOND의 SLAVE로 지정된 NIC 장치를 제외한 NIC 장치 목록
> 
> NO_LOOPBACK: loopback 장치를 제외한 NIC 장치 목록
> 
> NO_INTANGIBLE: 물리적인 NIC 장치 목록 (VLAN Tag 가 붙어 있지 않은)
> 

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : { },
>     entity : {
>         scope, ex) "NO_SLAVE|NO_INTANGIBLE"
>     }
> }
> ```
> Argument  | Description                                                          | Type   | Required |
> --------  | -----------                                                          | :----: | :------: | 
> --        | --                                                                   | --     | --       |
>
> Entity    | Description                                                                                | Type   | Required |
> --------  | -----------                                                                                | :----: | :------: | 
> **scope** | 조회할 network device의 범위를 정하는 변수[ALL/NO_BOND/NO_SLAVE/NO_LOOPBACK/NO_INTANGIBLE] | String | N        |
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
>             IPasign, #STATIC, DHCP or NONE
>             DevDesc, #ex) 'Intel Corporation 82545EM Gigabit Ethernet Controller (Copper) (rev 01)'
>             IPaddrInfo => [
>                 {
>                     Netmask,   #ex) 255.255.252.0
>                     IPaddr,
>                     Gateway,
>                     PrintMask, #ex) '255.255.252.0 [22]',
>                     Maskbits,  #ex) 22
>                 },
>             ],
>             Slave, #'on' or 'off'
>             Master,
>             MTU,
>             HwAddr, #MAC address ex) '00:0C:29:27:4E:C3'
>             LinkStatus, #'up' or 'down'
>             LinkSpeed,
>             Active, #'on' or 'off'
>             LastUpdated,
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
> **entity**   | 데이터를 담은 변수                          | Array  |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 2. /network/device/info

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
> Argument    | Description                              | Type   | Required |
> --------    | -----------                              | :----: | :------: | 
> **devname** | 조회 대상 network device를 지정하는 변수 | String | Y        | 
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
>             IPasign, #STATIC, DHCP or NONE
>             DevDesc, #ex) 'Intel Corporation 82545EM Gigabit Ethernet Controller (Copper) (rev 01)'
>             IPaddrInfo => [
>                 {
>                     Netmask,  #ex) 255.255.252.0
>                     IPaddr,
>                     Gateway,
>                     PrintMask #ex) '255.255.252.0 [22]',
>                     Maskbits  #ex) 22
>                 },
>             ],
>             Slave, #'on' or 'off'
>             Master,
>             MTU,
>             HwAddr, #MAC address ex) '00:0C:29:27:4E:C3'
>             LinkStatus, #'up' or 'down',
>             LinkSpeed,
>             RxInfo => {
>                 dropped,
>                 bytes,
>                 errors,
>                 packets
>             },
>             TxInfo => {
>                 bytes,
>                 dropped,
>                 errors,
>                 packets
>             },
>             Active, #'on' or 'off
>             TrafficUpdatedTime,
>             LastUpdated
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
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **msg**      | 결과에 대한 설명을 담은 메시지              | String |
> **entity**   | 데이터를 담은 변수                          | Array  |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String |

* * *

### 3. /network/device/update

* 노드의 Network Device 정보를 갱신하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         devname,
>     },
>     entity : {
>         MTU,
>         Active,
>         IPasign,
>         VLAN_Tags, ex) [ 100, 200, 300 ]
>     }
> }
> ```
> Argument    | Description                                | Type   | Required |
> --------    | -----------                                | :----: | :------: | 
> **devname** | 변경 대상 Netmask Device를 전달하는 변수   | String | Y        | 
>
> Entity        | Description                                                         | Type   | Required |
> --------      | -----------                                                         | :----: | :------: | 
> **MTU**       | 설정할 MTU                                                          | String | N        |
> **Active**    | 활성화 여부를 결정하는 변수                                         | String | M        | 
> **IPasign**   | 네트워크 주소의 할당 형태를 결정하는 변수                           | String | N        | 
> **VLAN_Tags** | 대상 장치에 붙일 VLAN 태그의 목록(VLAN_Tag가 붙지 않은 장치만 가능) | Array  | N        | 
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity : {
>         MTU,
>         Active,
>         IPasign,
>         VLAN_Tags,
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
> **entity**   | 데이터를 담은 변수                          | Array  |
> **stage_info**   | stage 정보를 담는  변수              | Hash |
> **stage_info/stage**   | Stage 값을 나타내는 변수               | String |
> **stage_info/data**   | Stage에 필요한 추가 정보를 담는 변수  | String |
> **statuses** | 내부에서 호출된 모든 API의 결과를 담은 변수 | String |
> **return**   | API의 성공 여부를 담는 변수                 | String | 

* * *

