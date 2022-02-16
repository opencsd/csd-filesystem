# 4 서비스 프로토콜

AnyStor-E는 표준 파일 및 블록 서비스 프로토콜을 지원하며 클러스터 전용 접속 방식을 지원합니다.

파일 서비스는 **NFS v3 및 CIFS/SMB v2 및 v3**를 지원합니다.

블록 서비스는 **LIO 기반의  iSCSI 및 iSER**를 지원하며 향후 FC 및 FCoE 등을 확장할 수 있습니다.

전용 접속 방식은 GlusterFS를 사용하는 경우, **FUSE 및 gfapi 지원**이 가능합니다.

| **AnyStor-E 적용 서비스 및 운영체제 지원 개요** |
| :------: |
| ![prococol_overview](./images/ase-protocol.png) |

<div class="notices yellow element normal">

<strong>웹 관리자 설정 제약</strong>

<ul>
    <li>AnyStor-E 웹 관리자는 <strong>NFS/SMB</strong> 설정만 가능하며, 나머지 기능은 콘솔을 통해 수동으로 설정이 가능합니다.</li>
    <li>본 매뉴얼은 웹 관리자 설정 기능만 기술하였으며, 기타 수동 설정은 기술 문의를 부탁드립니다.</li>
</ul>
</div>

* 지원하는 기능은 다음과 같습니다.

| 구분 | 설명 |
| :------------: | :---------------- |
| **프로토콜 설정** | 공유 프로토콜을 On/Off 및 기본설정 하는 기능입니다. |
| **공유 설정** | 볼륨 별 공유 설정을 할 수 있습니다. ACL 및 세부 기능 설정이 가능합니다. |
