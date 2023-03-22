LBA2PBA는 쿠버네티스에서 동작하는 파드가 사용중인 PV(Persistent Volume)에 저장된 파일들의 물리 주소를 찾아주는 소프트웨어입니다.

LBA2PBA는 gRPC를 사용하며, 4개의 서비스(QueryAgent, Manager, Trace, Worker)가 있습니다.


QueryAgent
---
QueryAgent는 파드에 저장된 파일들의 논리 주소를 받으면 대응되는 물리 주소로 반환해주는 서비스입니다.

```
# LBA2PBA.proto Code
service QueryAgent{
  rpc GetPba (QGetPbaRequest) returns (QGetPbaResponse);
  rpc UpdatePba (UpdatePbaRequest) returns (UpdatePbaResponse);
}

message PBA{
  string Disk = 1;
  string Host = 2;
  int64 Offset = 3;
  int64 Length = 4;
  int64 Major = 5;
  int64 Minor = 6;
}

message FilePBA{
  repeated PBA Pba = 1;
  string File_Name = 2;
}

message FileMap{
  repeated FilePBA File_Pba = 1;
}

message QGetPbaRequest{
  message Request{
    string File_Name = 1;
    int64 Offset = 2;
    int64 Length = 3;
  }
  
  repeated Request Requests = 1;
}

message QGetPbaResponse{
  repeated FilePBA File_Pba = 1;
}

message UpdatePbaRequest{
  string Ip = 1;
  repeated string Modi_List = 2;
  repeated string Add_list = 3;
  repeated string Del_list = 4;
}

message UpdatePbaResponse{
  FileMap File_Map = 1;
}
```

Manager
---
Manager는 QueryAgent로부터 PV에 저장된 파일 리스트 전달받아 전체 FileMap을 관리하고, PVC 생성 및 삭제 기능을 하는 서비스입니다.

```
service Manager{
  rpc CreatePvc (CreatePvcRequest) returns (CreatePvcResponse);
  rpc DeletePvc (DeletePvcRequest) returns (DeletePvcResponse);
  rpc GetFM (GetFMRequest) returns (GetFMResponse);
  rpc UpdateFM (UpdateFMRequest) returns (UpdateFMResponse);
}

message CreatePvcRequest{
  string Pvc_Name = 1;
  string Pvc_Type = 2;
  string Dupli_Type = 3;
}

message CreatePvcResponse{
  string Msg = 1;
  string Pvc_Name = 2;
}

message DeletePvcRequest{
  string Pvc_Name = 1;
}

message DeletePvcResponse{
  string Msg = 1;
  string Pvc_Name = 2;
}

message GetFMRequest{
  string Ip = 1;
  repeated string File_List = 2;
}

message GetFMResponse{
  FileMap File_Map = 1;
}

message UpdateFMRequest{
  string Ip = 1;
  repeated string Modi_List = 2;
  repeated string Add_List = 3;
  repeated string Del_List = 4;
}

message UpdateFMResponse{
  FileMap File_Map = 1;
}
```

Trace
---
Trace는 Gluster 볼륨에 저장된 파일명을 받으면 해당 파일의 Sharding 된 파일명들을 찾아 파일의 물리 주소를 순서대로 정렬하여 반환하는 서비스입니다.

```
service Trace{
  rpc Get (TGetPbaRequest) returns (TGetPbaResponse);
}

message PBA{
  string Disk = 1;
  string Host = 2;
  int64 Offset = 3;
  int64 Length = 4;
  int64 Major = 5;
  int64 Minor = 6;
}

message TGetPbaRequest{
  string File_Name = 1;
  string Vol_Name = 2;
}

message TGetPbaResponse{
  repeated PBA Pba = 1;
}
```

Worker
---
Worker는 파일명을 받으면 해당 파일명의 물리 주소와 길이를 반환해주는 서비스입니다.

```
service Worker{
  rpc Get (WGetPbaRequest) returns (WGetPbaResponse);
}

message WGetPbaRequest{
  string File_Name = 1;
}

message WGetPbaRequest{
  message Data{
    int64 Major = 1;
    int64 Minor = 2;
    int64 Offset = 3;
    int64 Length = 4;
  }
  
  repeated Data Pba = 1;
  string Disk = 2;
  string File_Name = 3;
}
```
