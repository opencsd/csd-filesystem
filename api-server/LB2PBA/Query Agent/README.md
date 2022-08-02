## LB2PBA Query Agent API 

### 기능

* 파일의 논리 OFFSET을 파일이 저장된 장치의 물리 OFFSET을 반환

* 타겟 디렉토리의 전체 파일맵(파일트리)가 변경될 시 변경된 파일맵(파일트리)를 PUSH

### URL

  HTTP
  
  POST http://{LB2PBAQueryAgent}:1113/getPBA
  
  - Parameter
	
	|Name|Required|Type|Description|
	|:---:|:---:|:---:|:---|
	|`fpath`|True|String|`File Path`|
	|`offsets`|True|Dictionary|`Offset Dictionary`|
	|`LB2PBAQueryAgent`|True|Int|`Kubernetes POD IP`|
  
	*offsets = {Index1:[OFFSET,LENGTH],Index2:[OFFSET,LENGTH]}
  
  - Return
	
	|Result|Type|Value|
	|:---:|:---:|:---|
	|`Success`|JSON|{<br>&nbsp;&nbsp;"name":"a.txt"<br>&nbsp;&nbsp;"data":{<br>&nbsp;&nbsp;&nbsp;&nbsp;Index1:[<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"DISK" : "/dev/sdb",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"HOST" : "gluster-1",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"OFFSET" : 12314,<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"LENGTH" : 1324<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;},<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;]<br>&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;}|
	|`Fail`|String|Error Message|