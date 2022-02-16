# Library: ClusterGlobal

## 인덱스

### 공통 함수

#### 1. [distribute_call](#1-distribute_call-1)
#### 2. [get_host_from_ip](#2-get_host_from_ip-1)
#### 3. [get_host_from_ips](#3-get_host_from_ips-1)
#### 4. [procedure_log](#4-procedure_log-1)
#### 5. [master](#5-master-1)
#### 6. [whoami](#6-whoami-1)
#### 7. [is_init](#7-is_init-1)

### 상태 관련 함수

#### 1. [set_component_status](#1-set_component_status-1)
#### 2. [get_component_status](#2-get_component_status-1)

### Stage 관련 함수

#### 1. [get_stage](#1-get_stage-1)
#### 2. [set_stage](#2-set_stage-1)
#### 3. [get_represent_stage](#3-get_represent_stage-1)
#### 4. [list_stage](#4-list_stage-1)
#### 5. [get_policy_from_stage](#5-get_policy_from_stage-1)
#### 6. [get_available_stage](#6-get_available_stage-1)
#### 7. [get_api_type](#7-get_api_type-1)
#### 8. [init_proc](#8-init_proc-1)
#### 9. [update_proc](#9-update_proc-1)
#### 10. [rollback_proc](#10-rollback_proc-1)
#### 11. [get_proc](#11-get_proc-1)
#### 12. [clear_proc](#12-clear_proc-1)

### Lock 관련 함수

#### 1. [gms_lock_info](#1-gms_lock_info-1)
#### 2. [gms_lock](#2-gms_lock-1)
#### 3. [gms_unlock](#3-gms_unlock-1)

## 개요

* GMS/GSM 전역에서 사용하는 클러스터 라이브러리 

## 공통 함수 목록

### 1. distribute_call 

* 원하는 노드에 API를 순차적으로 호출하는 함수

> #### 인자값
> Argument  | Description                   | Type   | Required   | Default|
> --------  | -----------                   | :----: | :--------: | :-------: | 
> **uri**   | 요청하고자 하는 API의 uri     | String | Y          | - |
> **parms** | API에 전달하고자 하는 인자값  | Hash | Y          |  - |
> **skip** | API를 처리할 수 없는 노드가 있을 경우 이를 skip하고 처리한 후 성공처리함  | Integer | N          |  0 |
> **precheck** | API를 수행하기 전에 처리할 수 없는 노드 유무를 확인하고 있을 경우 API를 수행안함  | Integer| N          |  0 |
> **targets**  | 요청하고자 하는 노드 리스트| Array | N          |  모든 노드 |
> **except_mds**  | MDS를 제외하고 보내는 용도의 플래그 | 0 or 1 | N |  0 |
> **except_ds**  | DS를 제외하고 보내는 용도의 플래그 | 0 or 1 | N  |  0 |
> **except_me**  | 본인을 제외하고 보내는 용도의 플래그 | 0 or 1 | N  |  0 |
> 
> * * *
> 
> #### 결과값: HashRef
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **return**   | 실패한 노드 수, 즉 0이면 성공  | Integer|
> **entity**   | 각 노드들의 API 호출 결과를 담는 해시 | HashRef |
> **entity/{node}**  | 각 노드들의 API 호출 결과 | HashRef |
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
> my $result = $cg->distribute_call(
>     uri     => '/cluster/volume/list',
>     parms   => {
>         entity => \%entity,
>     },
>     targets => \@targets
> );
>
> # Fail! 
> if($result->{return}){}
> # Success!
> else {}
>
> ```


* * *

### 2. get_host_from_ip

* IP를 입력받아 해당 IP의 호스트명을 가져오는 함수
* 관리 IP와 스토리지 IP에 대해 수행할 수 있음

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **ip**   | IP 주소 | String | Y          | - |
> 
> * * *
> 
> #### 결과값: String
> **호스트명**  or **undef**
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
> my $host = $cg->get_host_from_ip(
>     ip => '192.168.3.65'
> );
>
> ```

* * *

### 3. get_host_from_ips

* 여러 IP의 호스트명을 가져오는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **ips**   | IP를 담는 리스트   | ArrayRef | Y | - |
> 
> * * *
> 
> #### 결과값: ArrayRef
> **호스트명 리스트** 
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
> my $host_list = $cg->get_host_from_ips(
>     ips => ['192.168.3.65', '192.168.3.66']
> );
>
> ```


* * *

### 4. procedure_log

* /var/log/gms/procedure.log 에 로그를 남겨주는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |  
> **첫번째 인자값** | 로그 메시지 | String | Y | - |
> 
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
> my $cg = Cluster::ClusterGlobal->new();
> $cg->procedure_log('[WARN] warning message!');
>
> ```

* * *

### 5. master

* master node의 hostname을 반환하는 함수

> #### 인자값
> **없음**
> 
> * * *
> 
> #### 결과값: String
> **master의 hostname**
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
> my $master = $cg->master();
>
> ```

* * *

### 6. whoami

* 자신이 어떤 노드(mds/ds/master)인지 알려주는 함수 

> #### 인자값
> **없음**
> 
> * * *
> 
> #### 결과값: String
> **mds** or **ds** or **master**
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
> my $node_type = $cg->whoami();
>
> ```

* * *

### 7. is_init

* 자신이 초기화 되었는지 안되었는지 알려주는 함수

> #### 인자값
> **없음**
> 
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
> my $cg = Cluster::ClusterGlobal->new();
>
> # 초기화 됨 
> if($cg->is_init()){}
> # 초기화 안됨 
> else {}
>
> ```

* * *

##  상태 관련 함수 목록

### 1. set_component_status

* 컴포넌트 상태를 저장하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |
> **component**   | 컴포넌트의 이름 | String| Y | - |
> **status**   | 컴포넌트의 상태| String| Y | - |
> **reason**   | 컴포넌트의 상태변경 이유| String| N | Unknown |
> **code**   | 컴포넌트의 상태코드| String| N | ${component}_Unknown |
> 
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
> my $cg = Cluster::ClusterGlobal->new();
>
> $cg->set_component_status(
>     component => 'ctdb',
>     status    => 'ok',
>     reason    => 'ok',
>     code      => 'CTDB_OK'
> );
> ```

* * *

### 2. get_component_status

* 컴포넌트 상태를 가져오는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |
> --------    | -----------                   | :----: | :--------: |
> **첫 인자값**   | 컴포넌트의 이름 | String| N |
> 
> * * *
> 
> #### 결과값: HashRef 
> Argument    | Description                   | Type   |
> --------    | -----------                   | :----: |
> **component**   | 컴포넌트의 이름 | String| 
> **status**   | 컴포넌트의 상태| String| 
> **reason**   | 컴포넌트의 상태변경 이유| String| 
> **code**   | 컴포넌트의 상태코드| String|
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my $all_comp_status = $cg->get_component_status();
> print $all_comp_status->{ctdb}{status};
>
> my $nfs_status = $cg->get_component_status('nfs');
> print $nfs_status->{status};
> ```

* * *

## Stage 관련 함수 목록

### 1. set_stage

* 스테이지를 저장하는 함수

> #### 인자값
> ##### 인자값 1
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |
> **첫 인자값**   | 스테이지 이름 | String| Y | - |
> **두 인자값**   | 스테이지 영역 (cluster, node, local, both)| String| N | node |
> **세 인자값**   | 스테이지가 필요한 데이터값 | String| N | '' |
>
> ##### 인자값 2
> Argument    | Description                   | Type   | Required   | Default|
> --------    | -----------                   | :----: | :--------: | :-------: |
> **첫 인자값**   | 스테이지 정보를 담는 해시 | HashRef | Y | - |
> **첫 인자값/stage**   | 스테이지 이름| String| N | node |
> **첫 인자값/scope**   | 스테이지 영역 (cluster, node, local)| String| N | node |
> **첫 인자값/data**   | 스테이지가 필요한 데이터값| String| N | ''|
> 
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
> my $cg = Cluster::ClusterGlobal->new();
>
> # cluster, node 모두 설정
> $cg->set_stage('running', 'both');
>
> # cluster 설정
> $cg->set_stage('support', 'cluster');
>
> # Hash 를 이용한 설정
> $cg->set_stage({
>     stage => 'running',
>     scope => 'node',
>     data  => 'data'
> });
> ```

* * *

### 2. get_stage

* 스테이지를 가져오는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **첫 인자값**   | 스테이지 영역 (cluster, node, local) | String| N | node |
> 
> * * *
> 
> #### 결과값: HashRef 
> Argument    | Description                   | Type   |
> --------    | -----------                   | :----: |
> **stage**   | 스테이지 이름 | String|
> **data**   | 스테이지가 필요한 데이터값| String|
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my $cluster_stage = $cg->get_stage('cluster');
> print $cluster_stage->{stage};
> print $cluster_stage->{data};
> ```

* * *

### 3. get_represent_stage

* 대표 스테이지를 반환하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **첫 인자값**   | node 호스트명 | String| N | 자신|
> 
> * * *
> 
> #### 결과값: Array
> Argument    | Description                   | Type   |
> --------    | -----------                   | :----: |
> **첫번째 값**   | 스테이지 이름 | String|
> **두번째 값 **   | 스테이지 영역| String|
> **세번째 값 **   | 스테이지 Data 값| String|
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my ($stage, $scope, $data) = $cg->get_represent_stage();
> ```
* * *

### 4. list_stage

* 스테이지 목록을 가져오는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **첫 인자값**   | 스테이지 영역 (cluster, node, local) | String| N | node |
> 
> * * *
> 
> #### 결과값: ArrayRef 
> **스테이지 리스트**
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my $stage_list = $cg->list_stage('cluster');
> ```

* * *

### 5. get_policy_from_stage

* 스테이지에 따라 API가 SET 가능인지 아닌지 여부를 알려주는 함수 

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **stage**   | 스테이지 이름 | String| Y | - |
> **scope**   | 스테이지 영역 (cluster, node, local) | String| N | node |
> **data**   | 현재 스테이지가 가진 data값  | String| Y | - |
> **uri**   | 요청된 URI  | String| Y | - |
> 
> * * *
> 
> #### 결과값: String 
> **rw**(SET/GET 가능) or **ro**(GET 가능) or **no**(API 불가능)
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my $policy = $cg->get_policy_from_stage(
>     stage => 'support',
>     scope => 'node',
>     data  => '',
>     uri   => '/cluster/volume/list'
> );
>
> if($policy eq 'rw') {}
> elsif($policy eq 'ro') {}
> else {}
> ```

* * *

### 6. get_available_stage

* 변경가능한 스테이지 목록을 가져오는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **scope**   | 스테이지를 변경할 동작의 Scope | String (node or cluster)| N | node |
> **node**   | 노드 스테이지 | String| N (scope == 'cluster' 일 때 미사용) | - |
> **cluster**   | 클러스터 스테이지 | String| Y | - |
> 
> * * *
> 
> #### 결과값: ArrayRef
> **변경가능한 스테이지 목록**
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my @stage_list = @{$cg->get_available_stage(scope => 'cluster', cluster => 'running')};
>
> # @stage_list = ('support'); 데이터가 들어있음
> ```

* * *

### 7. get_api_type 

* API의 type을 가져오는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **첫번째 값**   | URI | String | Y | - |
> 
> * * *
> 
> #### 결과값: 0(SET) or 1(GET) or -1(failed)
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my $type = $cg->get_api_type('/cluster/volume/create');
> ```

* * *

### 8. init_proc

* Stage에 대한 진행률 표기를 위해 자료구조를 초기화하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **첫번째 값**   | 해당 Stage에서 진행할 함수의 수 (진행률 표기에 활용됨) | Integer | Y | - |
> 
> * * *
> 
> #### 결과값: undef
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> $cg->init_proc(50);
> ```

* * *

### 9. update_proc

* Stage에 대한 진행률 정보를 갱신하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **node**   | 노드명 (호스트명) | String | Y | - |
> **proc**   | 진행중인 단계 이름 혹은 설명| String | Y | - |
> **rate**   | 진행률| Integer| Y | - |
> 
> * * *
> 
> #### 결과값: undef
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> $cg->update_proc(
>     node => 'alghost-1',
>     proc => 'Add storage IP',
>     rate => 90
> );
> ```

* * *

### 10. rollback_proc

* 진행도중에 동자게 실패하여 rollback을 하게 될때 총 동작해야하는 함수 갯수를 갱신하기 위한 함수 

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **첫번째 값**   | 해당 Stage에서 진행할 함수의 수 (진행률 표기에 활용됨) | Integer | Y | - |
> 
> * * *
> 
> #### 결과값: undef
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> $cg->rollback_proc(100);
> ```

* * *

### 11. get_proc

* proc 정보를 가져오는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> 
> * * *
> 
> #### 결과값: HashRef 
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
> **total_rate**   | 전체 진행률  | Float |
> **nodes**   | 각 노드들의 진행 정보를 담는 배열 | ArrayRef |
> **nodes/0~n**  | 진행 정보를 담는 해시 | HashRef |
> **nodes/0~n/name**  | 노드명 | String |
> **nodes/0~n/curr_proc**  | 현재 진행 중인 단계의 이름 혹은 설명| String |
> **nodes/0~n/proc_rate**  | 현재 진행 중인 단계의 진행률| Float |
> **nodes/0~n/completed**  | 완료된 단계들의 이름을 담은 Array| ArrayRef|
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my $proc = $cg->get_proc();
> ```

* * *

### 12. clear_proc

* proc 정보를 삭제하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> 
> * * *
> 
> #### 결과값: undef 
> Argument     | Description                                 | Type   |
> --------     | -----------                                 | :----: |
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> $cg->clear_proc();
> ```

* * *

## Lock 관련 함수 목록

### 1. gms_lock_info

* 현재 락이 잡혀있는지 아닌지 확인하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **scope**   | 락의 영역(카테고리) | String| Y | - |
> 
> * * *
> 
> #### 결과값: Interger
> **0**(Unlocked) or **1**(Locked) or **-1**(Failed)
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> my $is_locked = $cg->gms_lock_info('cluster/glusterfs');
>
> if(!$is_locked) {
>     # Do somethings
> }
> ```


* * *

### 2. gms_lock

* 락을 얻는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **scope**   | 락의 영역(카테고리) | String| Y | - |
> **timeout** | 락의 유지시간 | Integer | N | 10 |
> **nb**   | non-block 모드를 위한 플래그| 0 or 1 | N | 0 |
> 
> * * *
> 
> #### 결과값: Interger
> **0**(Lock) or **1**(Lock exists) or **-1**(Failed)
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> $cg->gms_lock(scope => 'cluster/glusterfs');
>
> $cg->gms_lock(
>     scope   => 'cluster/glusterfs',
>     timeout =>  30
> );
>
> $cg->gms_lock(
>     scope   => 'cluster/glusterfs',
>     timeout => 60,
>     nb      => 1
> );
> ```

* * *

### 3. gms_unlock

* 락을 획득하는 함수

> #### 인자값
> Argument    | Description                   | Type   | Required   |Default|
> --------    | -----------                   | :----: | :--------: |:-------: |
> **scope**   | 락의 영역(카테고리) | String| Y | - |
> 
> * * *
> 
> #### 결과값: Interger
> **0**(Unlock) or **-1**(Failed)
>
> * * *
>
> #### 예제
> ```perl
> my $cg = Cluster::ClusterGlobal->new();
>
> $cg->gms_unlock(scope => 'cluster/glusterfs');
>
> ```
