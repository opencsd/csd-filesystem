## DB2PBA API 

### 기능

* 파일명을 받아서 파일의 다바이스, 물리 OFFSET, OFFSET 길이를 반환

### URL

  HTTP
  
  POST http://{DB2PBA}:9999/query/block/simple
  
  - Parameter
	
	|Name|Required|Type|Description|
	|:---:|:---:|:---:|:---|
	|`fName`|True|String|`File Name(Full Path)`|
	|`DB2PBA`|True|Int|`Gluster Storage IP(# N)`|
  
  
  - Return
	
	|Result|Type|Value|
	|:---:|:---:|:---|
	|`Success`|JSON|{<br>&nbsp;&nbsp;"List":{<br>&nbsp;&nbsp;&nbsp;&nbsp;"DISK" : "/dev/sda"<br>&nbsp;&nbsp;&nbsp;&nbsp;"CHUNKS" : [<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"OFFSET" : 123412,<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"LENGTH" : 123412<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}<br>&nbsp;&nbsp;&nbsp;&nbsp;]<br>&nbsp;&nbsp;}<br>}|
	|`Fail`|String|Error Message|