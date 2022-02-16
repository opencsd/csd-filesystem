## 5.3 디스크 설정

### 5.3.1 개요

디스크 설정 기능은 노드별 블록 장치(디스크)를 관리하는 기능입니다.

### 5.3.2 기술 요소

#### 5.3.2.1 블록 장치

#### 5.3.2.2 NVMe

#### 5.3.2.3 멀티패스

### 5.3.3 상세 설명 및 설정

#### 5.3.3.1 블록 장치 목록

해당 노드의 블록 장치 정보를 보여줍니다.

<div class="notices yellow element normal">
    <ul>
        <li>하드웨어 데이터베이스에 없는 장치는 하드웨어에 의존하는 일부 정보들(일련번호, 제조사 및 제품 이름 등)이 올바르게 보이지 않을 수도 있습니다.</li>
    </ul>
</div>

| 구분 | 설명 |
| :---: | :--- |
| **이름** | 블록 장치의 이름입니다. |
| **일련번호** | 블록 장치의 일련번호로써, 제조사가 할당합니다. |
| **제조사** | 블록 장치의 제조사입니다. |
| **제품 이름** | 블록 장치의 제품명입니다. |
| **유형** | 블록 장치의 유형을 나타냅니다. <ul><li>**hdd**: 일반 하드디스크</li><li>**ssd**: 솔리드 스테이트 드라이브</li><li>**nvme**: NVMe 인터페이스 장치</li><li>**multipath**: 멀티패스 장치</li></ul> |
| **인터페이스** | 블록 장치가 시스템과 연결된 인터페이스 방식입니다. <ul><li>**ATA/SATA**</li><li>**SAS**</li><li>**FC/FCoE**</li><li>**NVMe**</li></ul> |
| **크기** | 블록 장치의 크기입니다. |
| **OS 디스크** | 운영 체제를 위해 할당되었거나, LVM 논리 볼륨이 이러한 목적으로 해당 블록 장치를 사용하고 있다면 `OS`로 표기됩니다. |
| **사용 상태** | 마운트가 되어 있거나, LVM 물리 볼륨으로 사용 중이라면 `사용`으로, 그렇지 않다면 `미사용`으로 표기됩니다. |
| **마운트** | 블록 장치와 연관된 모든 마운트 경로를 보여줍니다. |