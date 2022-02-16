# 서비스 입출력 점검 사항

NFS/SMB 서비스 사용 시, 장애가 발생한 경우 아래 가이드에 따라 조치를 취할 수 있습니다.

<div class="notices info element normal">

<strong>서비스 입출력 점검 시 권장 사항</strong>

<ul>
    <li>기본 점검 사항을 먼저 확인해서 네트워크 구성 및 장비 상태가 정상인지 확인하세요.</li>
    <li>다른 노드에서도 동일한 현상이 보이지 않는다면 클라이언트 환경과 관련된 문제일 수 있습니다.</li>
</ul>

</div>

## NFS: 특정 파일,디렉터리 접근 시 <code>Input/Output error</code> 발생

| 점검 대상 | 내용 |
| :-------: | :--- |
| 관련 버전 | 버전 무관 |
| 장애 증상 | NFS로 마운트한 볼륨에서 특정 파일/디렉터리에 접근 시 <code>Input/Output error</code>가 출력되며 접근이 불가능합니다. |
| 발생 원인 | 해당 파일이 스플릿-브레인(Split-brain) 상태일 수도 있습니다.<br>스플릿-브레인(Split-brain)이란 복제 구성된 볼륨의 파일에 대해 메타데이터 불일치가 발생하여, 시스템이 자동으로 복구할 수 없는 상태입니다.<br>주로 복제 구성에 있는 두 노드가 비정상적인 재시작/종료 등이 반복된 경우에 발생할 수 있습니다. |
| 해결 방안 | 아래 가이드에 따라 mtime 또는 원본 선택 복구를 통해 스플릿-브레인(Split-brain)을 해결합니다. |

##### 1. 문제 확인

```
$ ls /mnt/nfs/test_file
ls: reading directory .: Input/output error
```

##### 2. AnyStor-E 장비에 SSH 또는 콘솔에 접근 후, 다음 명령어를 수행하여 볼륨 상태를 점검 합니다.

```
$ gluster volume heal {volume_name} info split-brain
Brick 10.10.59.65:/volume/{volume_name}
Status: Connected
Number of entries in split-brain: 0

Brick 10.10.59.66:/volume/{volume_name}
Status: Connected
Number of entries in split-brain: 0
```

##### 3. mtime 기존 파일 선택 및 복구

```
$ gluster volume heal {volume_name} split-brain latest-mtime {file_path}
* {file_path}는 마운트 경로가 아닌 마운트 경로의 하위 경로를 의미합니다.
* 예를 들어, 마운트 경로가 /mnt/volume/ 이라고 가정할 때 /mnt/volume/a.file을 복구하기 위해서는 /a.file을 입력해야 합니다.
```

##### 4. souce 파일 선택 및 복구

mtime(파일의 수정된 시간)으로 복구를 할 수 없는 경우, 복구에 사용할 원본 파일이 있는 노드를 지정할 수 있습니다.</br>

특정 노드를 지정하여 복구하기 위해서는 내부에서 노드 간에 가리키기 위한 IP({storage_ip})를 확인해야 합니다.</br>

{storage_ip}는 클러스터 파일시스템에서 각 노드를 가리키기 위한 IP로 별도의 명령어로 확인이 가능합니다.</br>

아래 명령어에 대한 결과에서 나오는 호스트 이름(Hostname)을 {storage_ip}로 사용합니다.</br>

```
$ gluster pool list
UUID                                    Hostname        State
2856591b-a6e7-4479-9a68-77ba6d4ce497    10.10.59.67     Connected
71ceb5ec-a3cf-49d6-b1c6-be6a0aaf76e9    10.10.59.68     Connected
036d30f8-c6f3-481e-bddf-e284c270b3ab    10.10.59.66     Connected
2d4bf849-9da3-4b05-8dfc-4e22dabec37b    localhost       Connected
```

<div class="notices yellow element normal">

<strong>이 복구 방법은 파일이 이전 상태로 복구될 수 있습니다.</strong>

<ul>
    <li>지정한 노드의 파일로 덮어쓰기 때문에 원치 않은 파일 일 수
    있습니다.</li>
</ul>

</div>

------

* 이전 명령어로 확인한 {storage_ip}와 {volume_name}, {file_path}를 사용하여 특정 노드의 파일로 복구할 수 있습니다.

```
$ gluster volume heal {volume_name} split-brain source-brick {storage_ip}:/volume/{volume_name} {file_path}
```
