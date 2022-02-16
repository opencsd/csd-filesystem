# Cluster Volume API: Arbiter

## API 개요

* **클러스터 볼륨에 대한 Tiering 설정 및 제어할 수 있는 API**

### 1. [/cluster/volume/arbiter/attach]

## API 설명

### 1. arbiter attach

* 클러스터 볼륨에 arbiter 를 설정하는 API

> #### 요청 인자 값
> ```
> {
>     secure-key: "<KEY>",
>     argument: {
>         FS_TYPE:    "...",
>         Volume_Name:   "...",
>     }
> }
> ```
***Argument            | Description                        | Type   | Required |
> --------             | -----------                        | ----   | -------- |
> **FS_Type**          | 'glusterfs' or 'ceph' or 'maha'    | String | Y        |
> **Volume_Name**      | Arbiter가 설정될 볼륨 명           | String | Y        |
> **Shard**            | 'true' or 'false'                  | String | Y        |
> **Shard_Block_Size** | '512MB' or '1GB' or '2GB' or '4GB' | String | Y        |

> #### 응답 결과 값
> ```
> {
>     return: "...",
>     code:   "...",
>     msg:    "...",
>     entity: "..."
> }
> ```
> Argument   | Description                                       | Type   |
> --------   | -----------                                       | ------ |
> **return** | 'true' or 'false'                                 | String |
> **code**   | ...                                               | String |
> **msg**    | ...                                               | String |
> **entity** | Arbiter가 설정된 볼륨 명                          | String |

***
