## CSI Manager API 

### 기능

* PVC 생성, PVC 삭제, PVC 조회, Gluster Subdir 조회

### URL

#### PVC 생성

  HTTP
  
  POST http://{CSIManager}:1113/create
  
  - Parameter
	
	|Name|Required|Type|Description|
	|:---:|:---:|:---:|:---|
	|`pvcName`|True|String|`PVC name`|
	|`pvcType`|True|String|`NVMeOF / Gluster`|
	|`dupliType`|True|String|`Replica [1,2,3] / Distribute`|
	|`CSIManger`|True|Int|`Kubernetes Master IP`|
  
  
  - Return
	
	|Result|Type|Value|
	|:---:|:---:|:---|
	|`Success`|JSON|{<br>&nbsp;&nbsp;"pvName":[PV Name]<br>}|
	|`Fail`|String|Error Message|
	
#### PVC 삭제

  HTTP
	
  POST http://{CSIManager}:1113/delete
	
  - Parameter
	
	|Name|Required|Type|Description|
	|:---:|:---:|:---:|:---|
	|`pvcName`|True|String|`PVC name`|
	|`CSIManger`|True|Int|`Kubernetes Master IP`|
  
  
  - Return
	
	|Result|Type|Value|
	|:---:|:---:|:---|
	|`Success`|String|Success Message|
	|`Fail`|String|Error Message|
	
#### PVC 조회

  HTTP
	
  POST http://{CSIManager}:1113/get
	
  - Parameter
	
	|Name|Required|Type|Description|
	|:---:|:---:|:---:|:---|
	|`CSIManger`|True|Int|`Kubernetes Master IP`|
  
  
  - Return
	
	|Result|Type|Value|
	|:---:|:---:|:---|
	|`Success`|JSON|[<br>&nbsp;&nbsp;{<br>&nbsp;&nbsp;&nbsp;&nbsp;"pvcName" : [PVC Name],<br>&nbsp;&nbsp;&nbsp;&nbsp;"pvcType" : [NVMeOF/Gluster],<br>&nbsp;&nbsp;&nbsp;&nbsp;"dupliType" : [Replica{1,2,3} / Distribute],<br>&nbsp;&nbsp;&nbsp;&nbsp;"subdir" : "subvol/ce/3d/"<br>&nbsp;&nbsp;},<br>] |
	|`Fail`|String|Error Message|

#### subdir 조회

  HTTP
	
  POST http://{CSIManager}:1113/getSubdir
	
  - Parameter
	
	|Name|Required|Type|Description|
	|:---:|:---:|:---:|:---|
	|`ip`|True|String|`POD IP`|
	|`CSIManger`|True|Int|`Kubernetes Master IP`|
  
  
  - Return
	
	|Result|Type|Value|
	|:---:|:---:|:---|
	|`Success`|JSON|{<br>&nbsp;&nbsp;"data" : [Subdir , VolumeName] <br>}|
	|`Fail`|String|Error Message|