# Library: MDSAdapter 

## 인덱스

### 공통 함수

#### 1. [rebuild_module](#1-rebuild_module-1)
#### 2. [update_target](#2-update_target-1)
#### 3. [get_target](#3-get_target-1)

### ETCD 관련 함수

#### 1. [set_key](#1-set_key-1)
#### 2. [get_key](#2-get_key-1)
#### 3. [compare_and_swap_key](#3-compare_and_swap_key-1)
#### 4. [set_conf](#4-set_conf-1)
#### 5. [get_conf](#5-get_conf-1)
#### 6. [compare_and_swap_conf](#6-compare_and_swap_conf-1)
#### 7. [dump_conf](#7-dump_conf-1)
#### 8. [restore_conf](#8-restore_conf-1)

### DB 관련 함수

#### 1. [execute_query](#1-execute_query-1)
#### 2. [execute_dbi](#2-execute_dbi-1)
#### 3. [get_dbhandler](#3-get_dbhandler-1)
#### 4. [build_db](#4-build_db-1)

### GSM 관련 함수
#### 1. [reset_gsm_target](#1-reset_gsm_target-1)
#### 2. [get_gsm_master](#2-get_gsm_master-1)
#### 3. [get_mds_addrs](#3-get_mds_addrs-1)
#### 4. [get_gsm_conf_currtime](#4-get_gsm_conf_currtime-1)

## 개요

* MDSAdapter 에서 사용하는 라이브러리 목록 정의

## 공통 함수 목록

### 1. rebuild_module

* 각 모듈이 가진 객체를 재생성하는 함수
* 인자값을 넣지 않을 경우 모든 모듈의 객체를 재생성함

> #### 인자값
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: |
> **1 인자값** | 모듈명 | 'db' or 'gsm' or 'conf' | N | - |
> 
> * * *
> 
> #### 결과값
> **없음**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> $adpt->rebuild_module('db');
>
> # All of modules are reloaded 
> $adpt->rebuild_module();
> ```

* * *

### 2. update_target 

* 각 모듈의 대상을 재검색하여 할당하는 함수

> #### 인자값
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: |
> **1 인자값** | 모듈명 | 'db' or 'gsm' or 'conf' | N | - |
> 
> * * *
> 
> #### 결과값
> **없음**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> $adpt->update_target('db');
>
> # Target for all of modules is reassigned
> $adpt->update_target();
> ```

* * *

### 3. get_target 

* 각 모듈의 대상을 가져오는 함수 

> #### 인자값
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: |
> **1 인자값** | 모듈명 | 'db' or 'gsm' or 'conf' | Y | - |
> 
> * * *
> 
> #### 결과값: String
> **대상 IP**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $db_target = $adpt->get_target('db');
> ```

* * *

## Etcd 관련 함수 목록

### 1. set_key

* Etcd 에 Key/Value 형태로 데이터를 넣을 때 사용하는 함수
* Etcd에 다음과 같은 키로 데이터가 추가됨
* (key의 첫 '/'은 생략됨)

  * 노드를 명시한 경우: /{node}/{db}/{key}
  * 노드를 명시하지 않은 경우: /{db}/{key}

> #### 인자값
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: |
> **1 인자값** | DB 이름 | String | Y | - |
> **2 인자값** | Key 이름  | String | Y | '/' |
> **3 인자값** | Node 명 | 'node' or 'cluster' or {hostname} | N  | 'cluster' |
> 
> * * *
> 
> #### 결과값: Integer
> **수정된 시간(Index)** or **0**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $hostname = short();
> my $result = $adpt->set_key('ClusterMeta', '/master', $hostname);
>
> # Fail! 
> if(!$result){}
> # Success!
> else {}
>
> ```

* * *

### 2. get_key

* Etcd로부터 Key/Value 형태의 데이터를 가져올 때 사용하는 함수
* Etcd에 다음과 같은 키로 데이터가 추가됨
* (key의 첫 '/'은 생략됨)

  * 노드를 명시한 경우: /{node}/{db}/{key}
  * 노드를 명시하지 않은 경우: /{db}/{key}

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: | 
> **1 인자값** | DB 이름 | String | Y | - |
> **2 인자값** | Key 이름  | String | Y | - |
> **3 인자값** | Node 명 | 'node' or 'cluster' or {hostname} | N  | 'cluster' |
> **4 인자값** | Index를 저장할 레퍼런스 변수 | Reference | N  | - |
> 
> * * *
> 
> #### 결과값: String
> **Value** or **''**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $timestamp;
> my $master = $adpt->get_key('ClusterMeta', '/master', \$timestamp);
>
> ```

* * *

### 3. compare_and_swap_key

* Etcd로부터 Key/Value 형태의 데이터를 수정할 때 기존값을 전달하여 기존값이 동일할 때만 수정함
* Etcd에 다음과 같은 키로 데이터가 추가됨
* (key의 첫 '/'은 생략됨)

  * 노드를 명시한 경우: /{node}/{db}/{key}
  * 노드를 명시하지 않은 경우: /{db}/{key}

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: | 
> **1 인자값** | DB 이름 | String | Y | - |
> **2 인자값** | Key 이름  | String | Y | - |
> **3 인자값** | 기존 Value 값 | String | Y  | - |
> **4 인자값** | 갱신할 Value 값 | String | N  | - |
> **5 인자값** | Node 명 | 'node' or 'cluster' or {hostname} | N  | 'cluster' |
> 
> * * *
> 
> #### 결과값: Integer 
> **0**(Failed) or **1**(Success) or **101**(Not match old one)
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $result = $adpt->compare_and_swap_key('ClusterMeta', '/master', 'alghost-1', 'alghost-2')
>
> # Not match ! 
> if($result == 101){}
> # Failed !
> elsif(!$result){}
> # Success!
> else {}
> ```

* * *

### 4. set_conf

* Etcd에 JSON 형식으로 된 DB 데이터를 저장

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: | 
> **1 인자값** | DB 이름 | String | Y | - |
> **2 인자값** | DB 데이터 | HashRef | Y  | - |
> **3 인자값** | Node 명 | 'node' or 'cluster' or {hostname} | N  | 'cluster' |
> 
> * * *
> 
> #### 결과값: String
> **수정된 시간(Index)** or **0**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $sample_data = {
>     data => 'sample',
>     key  => 'sample_key'
> };
> my $result = $adpt->set_conf('ClusterInfo', $sample_data); 
>
> # Fail! 
> if(!$result){}
> # Success!
> else {}
> ```

* * *

### 5. get_conf

* Etcd로 부터 JSON 형식으로 저장된 DB 데이터를 가져옴

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: | 
> **1 인자값** | DB 이름 | String | Y | - |
> **2 인자값** | Node 명 | 'node' or 'cluster' or {hostname} | N  | 'cluster' |
> 
> * * *
> 
> #### 결과값: HashRef
> **DB 데이터**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $cluster_info = $adpt->get_conf('ClusterInfo');
>
> ```

* * *

### 6. compare_and_swap_conf

* Etcd에 JSON 형식으로 된 DB 데이터를 저장할 때 기존값을 입력하여 기존값과 동일할 때만 수정되도록 하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: | 
> **1 인자값** | DB 이름 | String | Y | - |
> **2 인자값** | 기존 DB 데이터 | HashRef | Y  | - |
> **3 인자값** | 갱신할 DB 데이터 | HashRef | Y  | - |
> **4 인자값** | Node 명 | 'node' or 'cluster' or {hostname} | N  | 'cluster' |
> 
> * * *
> 
> #### 결과값: Integer 
> **0**(초기화 안됨) or **1**(초기화 됨)
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $old_status = $adpt->get_conf('Status');
> my $new_status = {
>     status => 'not ok',
>     msg    => 'wrong sample'
> };
> my $result = $adpt->compare_and_swap_conf('Status', $old_status, $new_status);
>
> # Not match ! 
> if($result == 101){}
> # Failed !
> elsif(!$result){}
> # Success!
> else {}
> ```

* * *

### 7. dump_conf

* Etcd에 있는 정보를 로컬에 dump하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: | 
> 
> * * *
> 
> #### 결과값: undef
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
>
> $adpt->dump_conf();
> ```

* * *

### 8. restore_conf

* 로컬에 있는 정보를 Etcd에 복구하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: | 
> 
> * * *
> 
> #### 결과값: undef
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
>
> $adpt->restore_conf();
> ```

* * *

## DB 관련 함수 목록

### 1. execute_query

* Query 를 입력받아 해당 Query를 실행하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |
> **query**   | 실행하고자 하는 SQL Query | String| Y | - |
> 
> * * *
> 
> #### 결과값 
> **Statement**(select 일경우) or **0**(Failed) or **1**(Success)
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
>
> my $result = $adpt->execute_query(
>     query => 'insert into gms_lock_log(\'lk_name\') values(\'test\');'
> );
>
> # Success
> if($result){}
> # Failed 
> else {}
> ```

* * *

### 2. exeucte_dbi

* 컴포넌트 상태를 가져오는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |
> **db_name** | DB의 Table 명 | String| Y |
> **rs_func** | ResultSet에서 호출할 함수명 | String| N | 'search' |
> **rs_cond** | rs_func 호출시 사용되는 조건값 (search일 경우 사용)| HashRef | N | {} |
> **rs_attr** | rs_func 호출시 사용되는 속성값 (search일 경우 사용)| HashRef | N | {} |
> **rs_data** | rs_func 호출시 사용되는 데이터값 (search가 아닐 경우 사용) | HashRef | N | - |
> **func** | rs_func 결과로부터 호출할 함수 | String| N | - |
> **args** | func 호출시 사용되는 인자값| HashRef | N | - |
> 
> * * *
> 
> #### 결과값
> **Statement**(select 일경우) or **0**(Failed) or **1**(Success)
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
>
> my $result = $adpt->execute_dbi(
>     db_name => 'Events',
>     rs_func => 'search',
>     rs_cond => {
>         -and => [
>             level          => { '!=', GSM_LV_REPAIR },
>             quiet          => 0,
>             beep_count     => 0,
>             rsyslog_count  => 0,
>             smtp_count     => 0,
>             snmptrap_count => 0,
>         ],
>     },
>     func    => 'all'
> );
>
> # Success
> if($result){}
> # Failed 
> else {}
> ```

* * *

### 3. get_dbhandler

* 최근에 사용한 DBI 객체를 반환하는 함수

> #### 인자값
> **없음**
> 
> * * *
> 
> #### 결과값 
> **DBI**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $dbhandler = $adpt->get_dbhandler();
>
> ```

* * *

### 4. build_db

* 초기 DB 테이블을 구축하는 함수

> #### 인자값
> **없음**
>  
> * * *
> 
> #### 결과값
> **없음**
> 
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::MDSAdapter->new();
> $adpt->build_db();
> 
> ```

* * *

## GSM 관련 함수 목록

### 1. reset_gsm_target 

* 정상적으로 연결이 가능한 Collector의 IP를 반환하는 함수

> #### 인자값
> **없음**
> 
> * * *
> 
> #### 결과값
> **IP주소** or **호스트명**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $target = $adpt->reset_gsm_target();
> ```

* * *

### 2. get_gsm_master

* 단일 장비에서만 수행해야되는 Agent를 위해 관리되는 master 주소를 반환하는 함수

> #### 인자값
> **없음**
> 
> * * *
> 
> #### 결과값
> **IP주소** or **호스트명**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $target = $adpt->get_gsm_master();
> ```

* * *

### 3. get_mds_addrs

* MDS 주소 리스트를 반환하는 함수

> #### 인자값
> **없음**
> 
> * * *
> 
> #### 결과값: ArrayRef
> **MDS 주소리스트**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $mds_list = $adpt->get_mds_addrs();
> ```

* * *

### 4. get_gsm_conf_currtime

* GSM 설정정보가 갱신된 timestamp를 가져옴
* 사용되는 timestamp값은 Etcd의 Modifed index 값임

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **1 인자값** | GSM 컴포넌트| 'Publisher' or 'Collector' or 'Notifier' | Y | - |
> 
> * * *
> 
> #### 결과값: Interger
> **timestamp**
>
> * * *
>
> #### 예제
> ```perl
> my $adpt = Cluster::MDSAdapter->new();
> my $pub_tstamp = $adpt->get_gsm_conf_currtime('Publisher');
> ```
