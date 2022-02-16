# Cluster API: Init

## API 인덱스

#### 1. [/cluster/init/config](#1-clusterinitconfig-1)
#### 2. [/cluster/init/create](#2-clusterinitcreate-1)
#### 3. [/cluster/init/join](#3-clusterinitjoin-1)
#### 4. [/cluster/init/register(내부용)](#3-clusterinitregister%EB%82%B4%EB%B6%80%EC%9A%A9)
#### 5. [/cluster/init/expand](#5-clusterinitexpand-1)
#### 6. [/cluster/init/activate(내부용)](#6-clusterinitactivate%EB%82%B4%EB%B6%80%EC%9A%A9-1)

## 개요

* 클러스터 API로 각 노드의 기반 시스템 설정과 클러스터 초기화/확장을 수행하는 API

## API 목록

### 1. /cluster/init/config

* 노드의 기반 시스템(network, volume group)을 설정하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Network : {
>             Service : {
>                 Slaves,
>                 Mode,
>             },
>             Storage : {
>                 Slaves,
>                 Mode,
>                 Ipaddr,
>                 Netmask,
>                 Gateway,
>             },
>             Management : {
>                 Interface,
>                 Ipaddr,
>                 Netmask,
>             },
>         },
>         Volume : {
>             Base_Pvs,
>             Tier_Pvs,
>         },
>     }
> }
> ```
> Argument                         | Description                                                         | Type   | Required      |
> --------                         | -----------                                                         | :----: | :------:      | 
> **Network**                      | Network에 대한 정보를 전달하는 변수                                 | Hash   | Y             | 
> **Network/Service**              | Service network에 사용할 정보를 전달하는 변수                       | Hash   | Y             | 
> **Network/Service/Slaves**       | Service Bond에 포함할 네트워크 장치 목록                            | Array  | Y             | 
> **Network/Service/Mode**         | Service Bond에 적용할 본딩 모드 정보 (default: 0)                   | Int    | N             | 
> **Network/Storage**              | Storage network에 사용할 정보를 전달하는 변수                       | Hash   | Y             | 
> **Network/Storage/Slaves**       | Storage Bond에 포함할 네트워크 장치 목록                            | Array  | Y             | 
> **Network/Storage/Mode**         | Storage Bond에 적용할 본딩 모드 정보 (default: 0)                   | Int    | N             | 
> **Network/Storage/Ipaddr**       | Storage Bond에 할당할 IP address의 주소                             | String | Y             | 
> **Network/Storage/Netmask**      | Storage Bond에 할당할 IP address의 netmask ex)255.255.255.0         | String | Y             | 
> **Network/Storage/Gateway**      | Storage Bond에 할당할 IP address의 gateway                          | String | N             | 
> **Network/Management**           | Management network에 사용할 정보를 전달하는 변수                    | Hash   | Y             | 
> **Network/Management/Interface** | Management network의 인터페이스로 사용할 네트워크 장치(서비스 네트워크와 같이 쓸 경우 'service'를 값으로 입력) | String | Y        | 
> **Network/Management/Ipaddr**    | Management network에서 사용할 IP address의 주소                     | String | Y(conditional)| 
> **Network/Management/Netmask**   | Management network에서 사용할 IP address의 netmask ex)255.255.255.0 | String | Y(conditional)| 
> **Volume**                       | Volume에 대한 정보를 전달하는 변수                                  | Hash   | Y             | 
> **Volume/Base_Pvs**              | 추후 cluster Base volume을 구성하는 volume group에 포함할 장치 목록 | Array  | Y             |
> **Volume/Tier_Pvs**              | 추후 cluster Tier volume을 구성하는 volume group에 포함할 장치 목록 | Array  | N             | 
> 
> Network/Management의 Ipaddr과 Netmask는 Network/Management/Interface가 'service'인 경우에만 필수
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

### 2. /cluster/init/create

* Cluster를 초기화 하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Service_IP : {
>             Start,
>             End,
>             Netmask,
>         },
>         Cluster_Name,
>     }
> }
> ```
> Argument               | Description                                                    | Type   | Required |
> --------               | -----------                                                    | :----: | :------: | 
> **Service_IP**         | Cluster가 Client에 서비스를 제공할 주소의 범위를 전달하는 변수 | Hash   | Y        | 
> **Service_IP/Start**   | Cluster가 Client에 서비스를 제공할 주소의 시작                 | String | Y        | 
> **Service_IP/End**     | Cluster가 Client에 서비스를 제공할 주소의 끝                   | String | Y        | 
> **Service_IP/Netmask** | Cluster가 Client에 서비스를 제공할 주소들의 Netmask            | String | Y        | 
> **Cluster_Name**       | Cluster의 이름을 전달하는 변수                                 | String | Y        | 
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

### 3. /cluster/init/join

* 대상 노드에 register 명령을 내리는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Cluster_IP,
>         Manual_Active,
>     }
> }
> ```
> Argument          | Description                                                                      | Type   | Required |
> --------          | -----------                                                                      | :----: | :------: | 
> **Cluster_IP**    | register 명령을 내릴 대상 Node의 IP를 전달하는 변수                              | String | Y        | 
> **Manual_Active** | 자동으로 대상 노드를 expand 할 것인지를 표시, 해당 값이 'Y'이면 수동으로 expand  | String | N        | 
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

### 3. /cluster/init/register(내부용)

* 새 노드를 클러스터에 등록하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Storage_IP,
>         Storage_Iface,
>         Mgmt_IP,
>     }
> }
> ```
> Argument          | Description                                          | Type   | Required |
> --------          | -----------                                          | :----: | :------: | 
> **Storage_IP**    | 새로 등록할 Node의 storage ip를 전달하는 변수        | String | Y        | 
> **Storage_Iface** | 새로 등록할 Node의 storage interface를 전달하는 변수 | String | Y        | 
> **Mgmt_IP**       | 새로 등록할 Node의 management ip를 전달하는 변수     | String | Y        | 
> 
> * * *
> 
> #### 응답 결과값 
> ```
> {
>     msg,
>     entity{
>         new_nodename,
>     },
>     stage_info : {
>         stage,
>         data
>     },
>     statuses,
>     return
> }
> ```
> Argument                | Description                                  | Type   |
> --------                | -----------                                  | :----: |
> **msg**                 | 결과에 대한 설명을 담은 메시지               | String |
> **entity**              | 데이터를 담은 변수                           | Array  |
> **entity/new_nodename** | 새로 추가한 노드의 이름(hostname)            | Array  |
> **stage_info**          | stage 정보를 담는  변수                      | Hash   |
> **stage_info/stage**    | Stage 값을 나타내는 변수                     | String |
> **stage_info/data**     | Stage에 필요한 추가 정보를 담는 변수         | String |
> **statuses**            | 내부에서 호출된 모든 API의 결과를 담은 변수  | String |
> **return**              | API의 성공 여부를 담는 변수                  | String | 


* * *

### 5. /cluster/init/expand

* 대상 노드에 activate 명령을 내리는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Manage_IP
>     }
> }
> ```
> Argument      | Description                                         | Type   | Required |
> --------      | -----------                                         | :----: | :------: | 
> **Manage_IP** | activate 명령을 내릴 대상 Node의 IP를 전달하는 변수 | String | Y        | 
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

### 6. /cluster/init/activate(내부용)

* 대상 노드를 초기화하여 가용할 수 있도록 하는 API

> #### 요청 인자값
> ```
> {
>     secure-key : <KEY>,
>     argument : {
>         Node_Name,
>         Master_storage,
>         Version,
>         Master_Candidates,
>         Local_Time, #`date +'%Y-%-m-%d %T`
>     }
> }
> ```
> Argument              | Description                                          | Type   | Required |
> --------              | -----------                                          | :----: | :------: | 
> **Node_Name**         | 대상 Node가 사용할 이름을 전달하는 변수              | String | Y        | 
> **Master_storage**    | 대상 Node가 참조할 노드의 IP를 전달하는 변수         | String | Y        | 
> **Version**           | 대상 Node가 포함될 Cluster의 Version을 전달하는 변수 | String | Y        | 
> **Master_Candidates** | 대상 Node가 참조할 Master 후보를 전달하는 변수       | Array  | Y        |
> **Local_Time**        | 대상 Node가 동기화 할 Local Time을 전달하는 변수     | Array  | Y        | 

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


