# 5 노드 관리

본 기능을 사용하여 클러스터에 참여한 개별 노드들의 상태를 모니터링할 수 있습니다.

개별 노드의 리소스 상태 점검 시 주로 활용합니다.

<div class="notices yellow element normal">

<strong>노드 관리 유의사항</strong>

<ul>
    <li>각 노드의 H/W 및 S/W 리소스는 클러스터 관리자에 의해 관리되므로 개별 노드의 리소스 제어는 권고하지 않습니다.</li>
</ul>
</div>

## 5.1 노드 관리 소개

| 구분 | 설명 |
| :--: | :--- |
| **노드별 현황**   | 클러스터에 속한 특정 노드의 시스템 정보를 취합하고 요약하여 해당 노드의 상태와 정보를 보여주는 기능입니다. |
| **디스크 설정**   | 디스크 설정 기능은 노드 별 논리 디스크(LVM 볼륨 그룹)을 관리하는 기능입니다. |
| **볼륨 설정**     | 노드 별 LVM 논리 볼륨을 관리하는 기능입니다. |
| **프로세스**      | 노드에서 실행중인 프로세스를 나타냅니다. |
| **RAID 정보**     | RAID 구성 정보 및 상태를 확인할 수 있습니다. |
| **네트워크 본딩** | 네트워크 본딩 상태를 출력하고 네트워크 본딩의 생성/수정/삭제를 수행할 수 있습니다. |
| **네트워크 장치** | 네트워크 장치 상태를 출력하고 유저가 특정 네트워크 장치 상태를 변경할 수 있습니다. |
| **네트워크 주소** | 네트워크 주소 할당 현황을 출력하고 네트워크 주소의 생성/수정/삭제를 수행할 수 있습니다. |
| **전원**          | 노드의 전원을 종료 및 재시작 합니다. |
| **S.M.A.R.T.**    | 디스크의 S.M.A.R.T. 상태 정보와 테스트 결과를 확인할 수 있습니다. |