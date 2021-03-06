## 5.8 네트워크 장치

클러스터 노드의 네트워크 장치 상태를 출력하고 특정 네트워크 장치 상태를 변경할 수 있습니다.

<div class="notices yellow element normal">
<strong>서비스/스토리지 네트워크 장치 활성/비활성화 제한</strong>

<ul>
    <li>서비스와 스토리지 네트워크 장치는 비활성화 할 수 없습니다.</li>
</ul>

<br/>

<strong>본딩에 소속한 네트워크 장치 상태 변경 제한</strong>

<ul>
    <li>본딩에 속한 네트워크 장치는 상태를 단독으로 바꿀 수 없습니다.</li>
    <li>본딩의 상태를 변경하면 그 본딩이 포함하는 네트워크 장치들도 모두 변경됩니다.</li>
</ul>
</div>

### 5.8.1 네트워크 장치 정보 조회

* 네트워크 장치의 정보를 출력합니다.
* 네트워크 장치 정보는 장치, 장치 설명, MAC 주소, 연결 속도, MTU, 활성화 상태, 연결 상태, IP 주소 할당 방식, 본딩 정보를 포함합니다.
* 네트워크 목록은 시스템을 반영하여 보여줍니다.

|  구분  |  내용  |
|  :---:  |  :---  |
| **장치** | 네트워크 장치 이름을 표시합니다. |
| **장치 설명** | 네트워크 장치의 모델명을 표기합니다.<br>본딩 장치는 가상의 하드웨어이므로 'Unknown'으로 표기합니다. |
| **MAC 주소** | 네트워크 장치의 식별자인 MAC 주소를 표기합니다. |
| **연결 속도** | 네트워크 장치의 연결 속도를 표기합니다.<br>네트워크 장치가 활성화 되지 않으면 연결 속도는 표기하지 않습니다. |
| **MTU** | 네트워크 장치의 MTU를 표기합니다.<br>MTU는 네트워크 장치가 한번에 보낼 수 있는 데이터의 최대 크기를 의미합니다. |
| **활성화 상태** | 사용자가 설정한 네트워크의 up/down 상태입니다.<br>활성화 상태와 연결 상태가 다르면 이벤트 페이지에 문제 상황을 나타내는 작업이 발생합니다. |
| **연결 상태** | 네트워크 장치의 링크 상태를 나타냅니다. |
| **주소 할당** | 네트워크 장치에 IP를 동적 혹은 정적으로 할당했는지를 나타냅니다. |
| **주 장치** | 네트워크 장치가 속한 본딩을 나타냅니다.<br>네트워크 장치가 본딩에 속하지 않으면 본딩 정보를 표시하지 않습니다. |

#### 5.8.1.1 상세 정보

* 각각의 네트워크 장치를 선택하고 상세 정보 버튼을 누르면 상세 정보가 나타납니다.
* 네트워크 상세 정보에서는 네트워크 장치 정보/주소와 네트워크 송/수신 정보를 보여줍니다.

<table>
<caption>네트워크 장치 정보표</caption>
<thead>
    <tr>
        <th>구분</th>
        <th>내용</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td><strong>장치</strong></td>
        <td>네트워크 장치 이름을 표시합니다.</td>
    </tr>
    <tr>
        <td><strong>MAC 주소</strong></td>
        <td>네트워크 장치의 식별자인 MAC 주소를 표기합니다.</td>
    </tr>
    <tr>
        <td><strong>연결 속도</strong></td>
        <td>네트워크 장치의 연결 속도를 표기합니다.<br>네트워크 장치가 활성화 되지 않으면 연결 속도는 표기하지 않습니다.</td>
    </tr>
    <tr>
        <td><strong>MTU</strong></td>
        <td>네트워크 장치의 MTU를 표기합니다.<br>MTU는 네트워크 장치가 한번에 보낼 수 있는 데이터의 최대 크기를 의미합니다.</td>
    </tr>
    <tr>
        <td><strong>활성화 상태</strong></td>
        <td>사용자가 설정한 네트워크의 up/down 상태입니다.<br>활성화 상태와 연결 상태가 다르면 이벤트 페이지에 문제 상황을 나타내는 작업이 발생합니다.</td>
    </tr>
    <tr>
        <td><strong>연결 상태</strong></td>
        <td>네트워크 장치의 링크 상태를 나타냅니다.</td>
    </tr>
</tbody>
</table>

* 네트워크 장치의 기본 정보를 출력합니다.
* 네트워크 장치 정보는 장치, MAC 주소, 연결 속도, MTU, 활성화 상태, 연결 상태가 있습니다.

<table>
<caption>네트워크 장치 주소 정보표</caption>
<thead>
    <tr>
        <th>구분</th>
        <th>내용</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td><strong>IP 주소</strong></td>
        <td>장치에 할당된 IP 주소를 표시합니다.</td>
    </tr>
    <tr>
        <td><strong>서브넷 마스크</strong></td>
        <td>장치에 할당된 IP의 서브넷 마스크를 표시합니다.<br><code>"xx.xx.xx.xx [xx]"</code>의 형태로 표기합니다.</td>
    </tr>
    <tr>
        <td><strong>게이트웨이</strong></td>
        <td>장치에 할당된 IP의 게이트웨이를 표시합니다.<br>게이트웨이가 설정되지 않으면 내용이 비어 있을 수 있습니다.</td>
    </tr>
    <tr>
        <td><strong>연결 상태</strong></td>
        <td>네트워크 장치의 링크 상태를 나타냅니다.</td>
    </tr>
</tbody>
</table>

* 장치에 할당된 IP 주소를 출력합니다.
* 장치에 할당한 IP 주소가 없으면 표 내용이 비어 있을 수 있습니다.
* 네트워크 장치 주소 정보는 IP 주소, 서브넷 마스크, 게이트웨이, 연결 상태가 있습니다.

<table>
<caption>네트워크 수신 정보표</caption>
<thead>
    <tr>
        <th>구분</th>
        <th>내용</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td><strong>bytes</strong></td>
        <td>장치에 들어오는 데이터의 총용량을 나타냅니다.</td>
    </tr>
    <tr>
        <td><strong>packets</strong></td>
        <td>장치에 들어온 패킷의 총 갯수를 나타냅니다.</td>
    </tr>
    <tr>
        <td><strong>dropped</strong></td>
        <td>장치에 들어온 패킷 중에 처리하지 못한 패킷의 갯수를 나타냅니다.</td>
    </tr>
    <tr>
        <td><strong>errors</strong></td>
        <td>장치에 들어온 패킷 중에 처리 도중 오류가 발생한 패킷의 갯수를 나타냅니다.</td>
    </tr>
</tbody>
</table>

* 장치에 들어오는 데이터에 대한 통계 정보를 출력합니다.
* 네트워크 수신 정보는 bytes, packets, dropped, errors가 있습니다.

<table>
<caption>네트워크 송신 정보표</caption>
<thead>
    <tr>
        <th>구분</th>
        <th>내용</th>
    </tr>
</thead>
<tbody>
    <tr>
        <td><strong>bytes</strong></td>
        <td>장치에서 나가는 데이터의 총 바이트 수를 나타냅니다.</td>
    </tr>
    <tr>
        <td><strong>packets</strong></td>
        <td>장치에서 나가는 패킷의 총 갯수를 나타냅니다.</td>
    </tr>
    <tr>
        <td><strong>dropped</strong></td>
        <td>장치에서 나가는 패킷 중에 처리하지 못한 패킷의 갯수를 나타냅니다.</td>
    </tr>
    <tr>
        <td><strong>errors</strong></td>
        <td>장치에서 나가는 패킷 중에 처리 도중 오류가 발생한 패킷의 갯수를 나타냅니다.</td>
    </tr>
</tbody>
</table>

* 장치에서 나가는 데이터에 대한 통계 정보를 출력합니다.
* 네트워크 송신 정보는 bytes, packets, dropped, errors가 있습니다.

#### 5.8.2 네트워크 장치 수정

네트워크 장치의 활성화 상태와 MTU(Maximum Transmission Unit)를 변경할 수 있습니다.

* **[네트워크 장치 이름]**
  * 수정할 네트워크 장치 명입니다.
  * 네트워크 장치 이름은 변경이 불가합니다.

* **[활성화]**
  * 네트워크 장치의 활성화 상태입니다.
  * 해당 항목이 선택된 하면 네트워크 장치를 켭니다.
  * 해당 항목이 선택되지 않으면 네트워크 장치를 끕니다.

* **[MTU]**
  * 네트워크 장치의 MTU 입니다.
  * 입력한 값으로 네트워크 장치의 MTU가 설정됩니다.
