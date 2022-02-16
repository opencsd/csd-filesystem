# RAID 디스크 교체

> RAID를 구성하는 디스크에 문제가 발생한 경우 아래 가이드에 따라 조치를 취할 수 있습니다.

> RAID 레벨에 따라 교체 가능한 디스크 수가 다르고, 데이터 유실이 발생할 수 있습니다.

#### 0. 사전 확인

> 본 가이드는 storcli를 활용 가능 한 LSI MegaRAID 컨트롤러를 기준으로 사용 가능합니다.

> 그 이외의 RAID 컨트롤러는 각 컨트롤러에서 제공하는 디스크 교체 매뉴얼을 참조하여 주시기 바랍니다.

> 다음의 명령어로 RAID 컨트롤러의 제조사 및 모델 확인이 가능합니다.

```
$ lspci  | grep RAID
82:00.0 RAID bus controller: LSI Logic / Symbios Logic MegaRAID SAS-3 3108 [Invader] (rev 02)
```

#### 1. 문제 확인

```
$ storcli /c0 show all
...
-------------------------------------------------------------------------
EID:Slt DID State DG     Size Intf Med SED PI SeSz Model              Sp
-------------------------------------------------------------------------
252:0     8 Onln   0 931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
252:1     9 Onln   0 931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
252:2    10 Onln   0 931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
252:3    11 Onln   0 931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
252:4    12 UBad   - 931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
252:5    15 Onln   0 931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
252:6    13 Onln   0 931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
252:7    14 Onln   0 931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
-------------------------------------------------------------------------
...
```
> 디스크에 문제가 발생 할 경우, 'State'가 Offln, UBad 등으로 표시가 됩니다.

> 다수의 RAID 컨트롤러를 사용 할 경우 컨트롤러 번호가 0번이 아닐 수 있습니다. 이 경우 /cX 의 형태로 옵션이 변경됩니다.

> 위 예시에서는 State가 'UBad'인 4번 디스크에 문제가 있습니다.

> 예시해서 사용중인 RAID 컨트롤러 ID, RAID 볼륨 ID, 장애 디스크 ID는 다음과 같습니다.

> - RAID 컨트롤러 ID : 0 (/c0)
> - RAID 볼륨 ID : 252 (/e252)
> - 장애 디스크 ID : 4 (/s4)

#### 2. 문제가 발생한 디스크 교체

> 문제가 발생한 디스크를 교체합니다.

> 기존 디스크와 동일 모델의 제품을 권장합니다.

#### 3. 교체 디스크 State 변경

```
$ storcli /c0 /e252 /s4 set good
Controller = 0
Status = Success
Description = Set Drive Good Succeeded.

$ storcli /c0 /e252 /s4 show

-------------------------------------------------------------------------
EID:Slt DID State DG     Size Intf Med SED PI SeSz Model              Sp
-------------------------------------------------------------------------
252:4    12 UGood F  931.0 GB SATA HDD N   N  512B TOSHIBA DT01ACA100 U
-------------------------------------------------------------------------
```

> 디스크 교체 후 교체 디스크의 State는 'UBad (Unconfigured Bad)' 입니다.

> 교체 디스크의 State를 UGood으로 변경합니다.

#### 4. Foriegn Config 확인

```
$ storcli /c0 -/fall show
-Controller = 0
Status = Success
Description = Operation on foreign configuration Succeeded

FOREIGN CONFIGURATION :
=====================

---------------------------------------
DG EID:Slot Type  State     Size NoVDs
---------------------------------------
 0 -        RAID5 Frgn  6.364 TB     1
 ---------------------------------------

 NoVDs - Number of VDs in disk group|DG - Diskgroup
 Total foreign drive groups = 1
```

#### 5. Foriegn Config Clearing (Rebuild 시작)

```
$ storcli /c0 /fall import
Controller = 0
Status = Success
Description = Successfully imported foreign configuration
```

#### 6. 디스크 Rebuild 상태 확인

```
$ storcli /c0 /e252 /s4 show rebuild
Controller = 0
Status = Success
Description = Show Drive Rebuild Status Succeeded.

------------------------------------------------------
Drive-ID    Progress% Status      Estimated Time Left
------------------------------------------------------
/c0/e252/s4         8 In progress 6 Hours 25 Minutes
------------------------------------------------------
```

> Progress% 는 현재 진행률을 나타냅니다.

> Estimated Time Left는 잔여 시간을 나타냅니다.

> 디스크 크기, 데이터 양에 따라 시간은 변동될 수 있습니다.
