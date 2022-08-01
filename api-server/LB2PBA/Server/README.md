## LB2PBA Server API 

### 기능

* 파일명을 받아서 파일의 Shard 파일 리스트를 얻고 파일의 디바이스,물리 OFFSET,길이를 반환

### URL

  HTTP
  
  POST http://{LB2PBAServer}:1113/getPBA
  
  - Parameter
	
	|Name|Required|Type|Description|
	|:---:|:---:|:---:|:---|
	|`fpath`|True|String|`File Path`|
	|`volume`|True|String|`Gluster Storage Volume`|
	|`LB2PBAServer`|True|Int|`LB2PBAServer IP(Storage #1)`|
  
  
  - Return
	
	|Result|Type|Value|
	|:---:|:---:|:---|
	|`Success`|JSON|{<br>&nbsp;&nbsp;"name":"a.txt"<br>&nbsp;&nbsp;"fpath":"/subvol/ae/3d/1a"<br>&nbsp;&nbsp;"data":{<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"DISK" : "/dev/sdb",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"HOST" : "gluster-1",<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"OFFSET" : 12314,<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"LENGTH" : 1324<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;},<br>&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;}|
	|`Fail`|String|Error Message|