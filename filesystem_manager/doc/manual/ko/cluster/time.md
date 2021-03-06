## 1.7 시간 설정

클러스터 참여한 모든 노드의 시간을 동기화 합니다.

네트워크 시간 서버(NTP) 및 수동 설정으로 시간을 변경할 수 있습니다.

NTP 서버를 통해 국가 표준시로 클러스터 시간을 동기화할 수 있습니다.

<div class="notices blue element normal">

<strong>클러스터와 시간 동기화</strong>

<ul>
    <li>클러스터는 각 노드의 상태를 진단하기 위한 모니터링과 클러스터 정보 동기화를 위해 노드간 정보를 주고 받으며, 이러한 동기화 과정에는 시스템의 시간을 참조하는 경우가 많습니다.</li>
    <li>따라서 AnyStor-E는 자체적으로 구동되는 NTP 서버를 통해 전체 시간을 동기화합니다.</li>
</ul>
</div>

<div class="notices red element normal">

<strong>주의사항</strong>

<ul>
    <li>수동으로 시간을 변경할 경우, 모니터링 동작이 잠시 중단될 수 있습니다.</li>
    <li>시간이 변경 되는 경우 성능 통계 데이터가 잠시 갱신이 되지 않을 수 있습니다.</li>
</ul>
</div>

### 1.7.1 시간 설정 기능

| 구분             | 설명 |
| ----             | ---- |
| 시스템 현재 시간 | 시스템 현재 시간은 클러스터의 현재 시간을 나타냅니다. |
| 표준 시간대      | 지역에 따른 표준 시간대를 설정할 수 있습니다. |
| 수동 설정        | 수동 설정으로 원하는 날짜와 시간을 선택할 수 있습니다. |
| 시간 동기화      | NTP 서버를 지정하여 시간을 동기화할 수 있습니다. |

* **시간 동기화**
  * 상단 첫 번째 설정된 NTP 서버와 시간을 동기화 합니다.
  * NTP 서버와 연결할 수 없다면, 추가로 설정한 NTP 서버와 동기화 합니다.
  * NTP 서버는 최대 5개까지 지정할 수 있습니다.
