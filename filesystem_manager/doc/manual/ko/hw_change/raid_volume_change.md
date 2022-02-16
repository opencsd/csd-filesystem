# RAID 볼륨 교체

> 클러스터 볼륨 풀 (vg_cluster, vg_tier 등) 및 클러스터 볼륨을 구성하는 RAID 볼륨에 문제가 발생한 경우 아래 가이드에 따라 조치를 취할 수 있습니다.

> 클러스터 볼륨 구성 방식에 따라 데이터 복구가 불가능할 수 있습니다.

> RAID 볼륨을 다시 구성한 후 데이터를 복구 할 복제 세트가 있는 경우에만 데이터 복구가 가능합니다.

#### 1. RAID 볼륨 재구성

> 기존 구성과 동일하게 RAID 볼륨을 재구성 합니다.

> RAID 구성 방식은 사용하고계신 RAID 컨트롤러의 가이드를 참조해 주세요.

#### 2. 클러스터 볼륨 상태 확인

```
$ gluster volume info test

Volume Name: test
Type: Replicate
Volume ID: 0095adee-8e80-4b34-8866-ed2ed13d11ab
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 4 = 4
Transport-type: tcp
Bricks:
Brick1: 10.10.1.220:/volume/test_0
Brick2: 10.10.1.221:/volume/test_0
Brick3: 10.10.1.222:/volume/test_0
Brick4: 10.10.1.223:/volume/test_0
Options Reconfigured:
diagnostics.client-sys-log-level: WARNING
diagnostics.brick-sys-log-level: WARNING
network.ping-timeout: 30
transport.address-family: inet
nfs.disable: on
```

```
$ gluster volume status test
Status of volume: test
Gluster process                             TCP Port  RDMA Port  Online  Pid
------------------------------------------------------------------------------
Brick 10.10.1.220:/volume/test_0            49153     0          Y       23176
Brick 10.10.1.221:/volume/test_0            49153     0          Y       20293
Brick 10.10.1.222:/volume/test_0            49154     0          Y       19798
Self-heal Daemon on localhost               N/A       N/A        Y       23212
Self-heal Daemon on AC2PERF-2               N/A       N/A        Y       20363
Self-heal Daemon on AC2PERF-3               N/A       N/A        Y       19961

Task Status of Volume test
------------------------------------------------------------------------------
There are no active volume tasks
```

> 정상 노드에서 클러스터 볼륨의 상태를 확인합니다.

> 예시에서 사용한 클러스터 노드, 볼륨의 정보는 다음과 같습니다.

> - 클러스터 노드의 스토리지 IP : 10.10.1.220 ~ 223
> - 클러스터 볼륨 명 : test
> - 클러스터 볼륨 구성 : 4 노드 복제 구성
> - Brick Size : 5.00 Tib
> - RAID 볼륨 교체가 진행된 노드의 스토리지 IP : 10.10.1.223

> 볼륨 정보 (gluster volume info)에는 4개의 Brick이 확인 되지만, 볼륨 상태 (gluster volume status)에는 문제가 발생한 Brick (10.10.1.223:/volume/test_0)이 확인되지 않습니다.

#### 3. PV (Physical Volume) 생성

```
$ pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created
```

> 새로 구성한 RAID 볼륨을 사용하여 PV를 생성합니다.

> 노드의 볼륨 구성에 따라 블록 디바이스 경로는 예시와 다를 수 있습니다. (/dev/sdX)

#### 4. VG (Volume Groups) 생성

```
$ vgcreate vg_cluster /dev/sdb
  Volume group "vg_cluster" successfully created
```

> 클러스터 볼륨 풀에서 사용하는 VG를 생성합니다. (vg_cluster, vg_tier 등)

> 클러스터의 볼륨 구성에 따라 VG 명은 예시와 다를 수 있습니다.

> 노드의 볼륨 구성에 따라 블록 디바이스 경로는 예시와 다를 수 있습니다. (/dev/sdX)

#### 5. 정상 노드에서 LV (Logical Volume) 정보 확인

```
$ lvdisplay
  --- Logical volume ---
  LV Path                /dev/vg_cluster/test_0
  LV Name                test_0
  VG Name                vg_cluster
  LV UUID                qqHOmi-BzYl-zTh1-xCXS-pAqc-7KWV-Kf1y97
  LV Write Access        read/write
  LV Creation host, time AC2PERF-1, 2018-03-26 11:24:46 +0900
  LV Status              available
  # open                 1
  LV Size                5.00 TiB
  Current LE             1310720
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0
```

> LV 명은 test_0, LV 크기는 5.00 Tib 입니다.

#### 6. LV (Logical Volume) 생성

```
$ lvcreate -L 5.00Tib -n test_0 vg_cluster
  Logical volume "test_0" created.
```

> 기존 LV와 동일한 구성으로 LV를 생성합니다.

#### 7. LV 파일시스템 포맷

```
$ mkfs.xfs -i size=512,maxpct=0 -l lazy-count=1 -f /dev/vg_cluster/test_0
meta-data=/dev/vg_cluster/test_0 isize=512    agcount=32, agsize=41943040 blks
         =                       sectsz=4096  attr=2, projid32bit=0
data     =                       bsize=4096   blocks=1342177280, imaxpct=0
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0
log      =internal log           bsize=4096   blocks=521728, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```

#### 8. LV 마운트

```
$ mount -t xfs -o defaults /dev/vg_cluster/test_0 /volume/test_0
```

> 기존 Brick과 동일한 위치에 LV를 마운트 합니다.

#### 9. 클러스터 볼륨 재구성 (정상 노드에서 진행)

```
$ gluster volume reset-brick test 10.10.1.223:/volume/test_0 start
volume reset-brick: success: reset-brick start operation successful
$ gluster volume reset-brick test 10.10.1.223:/volume/test_0 10.10.1.223:/volume/test_0 commit force
```

> 정상 노드에서 볼륨 재구성을 진행합니다.

> 두 번째 명령어 이후 데이터 마이그레이션 작업이 진행됩니다. (데이터 양에 따라 시간이 소요될 수 있습니다.)

#### 10. 클러스터 볼륨 상태 확인

```
$ gluster volume status test
Status of volume: test
Gluster process                             TCP Port  RDMA Port  Online  Pid
------------------------------------------------------------------------------
Brick 10.10.1.220:/volume/test_0            49153     0          Y       40616
Brick 10.10.1.221:/volume/test_0            49153     0          Y       32654
Brick 10.10.1.222:/volume/test_0            49153     0          Y       28084
Brick 10.10.1.223:/volume/test_0            49152     0          Y       5375
Self-heal Daemon on localhost               N/A       N/A        Y       5005
Self-heal Daemon on 10.10.1.223             N/A       N/A        Y       5383
Self-heal Daemon on 10.10.1.222             N/A       N/A        Y       17270
Self-heal Daemon on 10.10.1.221             N/A       N/A        Y       7469

Task Status of Volume test
------------------------------------------------------------------------------
There are no active volume tasks
```

> 클러스터 볼륨 상태에 복구한 Brick (10.10.1.223:/volume/test_0)이 확인 됩니다.
