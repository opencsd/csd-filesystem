# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: lba2pba.proto
"""Generated protocol buffer code."""
from google.protobuf import descriptor as _descriptor
from google.protobuf import descriptor_pool as _descriptor_pool
from google.protobuf import symbol_database as _symbol_database
from google.protobuf.internal import builder as _builder
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor_pool.Default().AddSerializedFile(b'\n\rlba2pba.proto\x12\x07lba2pba\"_\n\x03PBA\x12\x0c\n\x04\x44isk\x18\x01 \x01(\t\x12\x0c\n\x04Host\x18\x02 \x01(\t\x12\x0e\n\x06Offset\x18\x03 \x01(\x03\x12\x0e\n\x06Length\x18\x04 \x01(\x03\x12\r\n\x05Major\x18\x05 \x01(\x03\x12\r\n\x05Minor\x18\x06 \x01(\x03\"5\n\nReplicaPba\x12\x19\n\x03Pba\x18\x01 \x03(\x0b\x32\x0c.lba2pba.PBA\x12\x0c\n\x04Node\x18\x02 \x01(\t\"g\n\x07\x46ilePBA\x12\x19\n\x03Pba\x18\x01 \x03(\x0b\x32\x0c.lba2pba.PBA\x12!\n\x04rPba\x18\x02 \x03(\x0b\x32\x13.lba2pba.ReplicaPba\x12\x10\n\x08\x46ileName\x18\x03 \x01(\t\x12\x0c\n\x04Type\x18\x04 \x01(\t\",\n\x07\x46ileMap\x12!\n\x07\x46ilePba\x18\x01 \x03(\x0b\x32\x10.lba2pba.FilePBA\"s\n\x06VShard\x12\x0f\n\x07VolName\x18\x01 \x01(\t\x12)\n\tShardList\x18\x02 \x03(\x0b\x32\x16.lba2pba.VShard.FShard\x1a-\n\x06\x46Shard\x12\x10\n\x08\x46ileName\x18\x01 \x01(\t\x12\x11\n\tshardList\x18\x02 \x03(\t\"#\n\x10WGetShardRequest\x12\x0f\n\x07VolName\x18\x01 \x01(\t\"8\n\x11WGetShardResponse\x12#\n\nvShardList\x18\x01 \x03(\x0b\x32\x0f.lba2pba.VShard\"\"\n\x0eWGetPbaRequest\x12\x10\n\x08\x46ileName\x18\x01 \x01(\t\"\xa3\x01\n\x0fWGetPbaResponse\x12*\n\x03Pba\x18\x01 \x03(\x0b\x32\x1d.lba2pba.WGetPbaResponse.Data\x12\x0c\n\x04\x44isk\x18\x02 \x01(\t\x12\x10\n\x08\x46ileName\x18\x03 \x01(\t\x1a\x44\n\x04\x44\x61ta\x12\r\n\x05Major\x18\x01 \x01(\x03\x12\r\n\x05Minor\x18\x02 \x01(\x03\x12\x0e\n\x06Offset\x18\x03 \x01(\x03\x12\x0e\n\x06Length\x18\x04 \x01(\x03\"3\n\x0eTGetPbaRequest\x12\x10\n\x08\x46ileName\x18\x01 \x01(\t\x12\x0f\n\x07VolName\x18\x02 \x01(\t\"O\n\x0fTGetPbaResponse\x12\x19\n\x03Pba\x18\x01 \x03(\x0b\x32\x0c.lba2pba.PBA\x12!\n\x04RPba\x18\x02 \x03(\x0b\x32\x13.lba2pba.ReplicaPba\"G\n\x10\x43reatePvcRequest\x12\x0f\n\x07PvcName\x18\x01 \x01(\t\x12\x0f\n\x07PvcType\x18\x02 \x01(\t\x12\x11\n\tDupliType\x18\x03 \x01(\t\"1\n\x11\x43reatePvcResponse\x12\x0b\n\x03Msg\x18\x01 \x01(\t\x12\x0f\n\x07PvcName\x18\x02 \x01(\t\"#\n\x10\x44\x65letePvcRequest\x12\x0f\n\x07PvcName\x18\x01 \x01(\t\"1\n\x11\x44\x65letePvcResponse\x12\x0b\n\x03Msg\x18\x01 \x01(\t\x12\x0f\n\x07PvcName\x18\x02 \x01(\t\",\n\x0cGetFMRequest\x12\n\n\x02Ip\x18\x01 \x01(\t\x12\x10\n\x08\x46ileList\x18\x02 \x03(\t\"2\n\rGetFMResponse\x12!\n\x07\x46ileMap\x18\x01 \x01(\x0b\x32\x10.lba2pba.FileMap\"/\n\x0fUpdateFMRequest\x12\n\n\x02Ip\x18\x01 \x01(\t\x12\x10\n\x08\x46ileList\x18\x02 \x03(\t\"5\n\x10UpdateFMResponse\x12!\n\x07\x46ileMap\x18\x01 \x01(\x0b\x32\x10.lba2pba.FileMap\"\x80\x01\n\x0eQGetPbaRequest\x12\x31\n\x08Requests\x18\x01 \x03(\x0b\x32\x1f.lba2pba.QGetPbaRequest.Request\x1a;\n\x07Request\x12\x10\n\x08\x46ileName\x18\x01 \x01(\t\x12\x0e\n\x06Offset\x18\x02 \x01(\x03\x12\x0e\n\x06Length\x18\x03 \x01(\x03\"4\n\x0fQGetPbaResponse\x12!\n\x07\x46ilePba\x18\x01 \x03(\x0b\x32\x10.lba2pba.FilePBA2I\n\nQueryAgent\x12;\n\x06GetPba\x12\x17.lba2pba.QGetPbaRequest\x1a\x18.lba2pba.QGetPbaResponse2\x8a\x02\n\x07Manager\x12\x42\n\tCreatePvc\x12\x19.lba2pba.CreatePvcRequest\x1a\x1a.lba2pba.CreatePvcResponse\x12\x42\n\tDeletePvc\x12\x19.lba2pba.DeletePvcRequest\x1a\x1a.lba2pba.DeletePvcResponse\x12\x36\n\x05GetFM\x12\x15.lba2pba.GetFMRequest\x1a\x16.lba2pba.GetFMResponse\x12?\n\x08UpdateFM\x12\x18.lba2pba.UpdateFMRequest\x1a\x19.lba2pba.UpdateFMResponse2A\n\x05Trace\x12\x38\n\x03Get\x12\x17.lba2pba.TGetPbaRequest\x1a\x18.lba2pba.TGetPbaResponse2\x89\x01\n\x06Worker\x12\x38\n\x03Get\x12\x17.lba2pba.WGetPbaRequest\x1a\x18.lba2pba.WGetPbaResponse\x12\x45\n\x0cGetShardList\x12\x19.lba2pba.WGetShardRequest\x1a\x1a.lba2pba.WGetShardResponseb\x06proto3')

_globals = globals()
_builder.BuildMessageAndEnumDescriptors(DESCRIPTOR, _globals)
_builder.BuildTopDescriptorsAndMessages(DESCRIPTOR, 'lba2pba_pb2', _globals)
if _descriptor._USE_C_DESCRIPTORS == False:

  DESCRIPTOR._options = None
  _globals['_PBA']._serialized_start=26
  _globals['_PBA']._serialized_end=121
  _globals['_REPLICAPBA']._serialized_start=123
  _globals['_REPLICAPBA']._serialized_end=176
  _globals['_FILEPBA']._serialized_start=178
  _globals['_FILEPBA']._serialized_end=281
  _globals['_FILEMAP']._serialized_start=283
  _globals['_FILEMAP']._serialized_end=327
  _globals['_VSHARD']._serialized_start=329
  _globals['_VSHARD']._serialized_end=444
  _globals['_VSHARD_FSHARD']._serialized_start=399
  _globals['_VSHARD_FSHARD']._serialized_end=444
  _globals['_WGETSHARDREQUEST']._serialized_start=446
  _globals['_WGETSHARDREQUEST']._serialized_end=481
  _globals['_WGETSHARDRESPONSE']._serialized_start=483
  _globals['_WGETSHARDRESPONSE']._serialized_end=539
  _globals['_WGETPBAREQUEST']._serialized_start=541
  _globals['_WGETPBAREQUEST']._serialized_end=575
  _globals['_WGETPBARESPONSE']._serialized_start=578
  _globals['_WGETPBARESPONSE']._serialized_end=741
  _globals['_WGETPBARESPONSE_DATA']._serialized_start=673
  _globals['_WGETPBARESPONSE_DATA']._serialized_end=741
  _globals['_TGETPBAREQUEST']._serialized_start=743
  _globals['_TGETPBAREQUEST']._serialized_end=794
  _globals['_TGETPBARESPONSE']._serialized_start=796
  _globals['_TGETPBARESPONSE']._serialized_end=875
  _globals['_CREATEPVCREQUEST']._serialized_start=877
  _globals['_CREATEPVCREQUEST']._serialized_end=948
  _globals['_CREATEPVCRESPONSE']._serialized_start=950
  _globals['_CREATEPVCRESPONSE']._serialized_end=999
  _globals['_DELETEPVCREQUEST']._serialized_start=1001
  _globals['_DELETEPVCREQUEST']._serialized_end=1036
  _globals['_DELETEPVCRESPONSE']._serialized_start=1038
  _globals['_DELETEPVCRESPONSE']._serialized_end=1087
  _globals['_GETFMREQUEST']._serialized_start=1089
  _globals['_GETFMREQUEST']._serialized_end=1133
  _globals['_GETFMRESPONSE']._serialized_start=1135
  _globals['_GETFMRESPONSE']._serialized_end=1185
  _globals['_UPDATEFMREQUEST']._serialized_start=1187
  _globals['_UPDATEFMREQUEST']._serialized_end=1234
  _globals['_UPDATEFMRESPONSE']._serialized_start=1236
  _globals['_UPDATEFMRESPONSE']._serialized_end=1289
  _globals['_QGETPBAREQUEST']._serialized_start=1292
  _globals['_QGETPBAREQUEST']._serialized_end=1420
  _globals['_QGETPBAREQUEST_REQUEST']._serialized_start=1361
  _globals['_QGETPBAREQUEST_REQUEST']._serialized_end=1420
  _globals['_QGETPBARESPONSE']._serialized_start=1422
  _globals['_QGETPBARESPONSE']._serialized_end=1474
  _globals['_QUERYAGENT']._serialized_start=1476
  _globals['_QUERYAGENT']._serialized_end=1549
  _globals['_MANAGER']._serialized_start=1552
  _globals['_MANAGER']._serialized_end=1818
  _globals['_TRACE']._serialized_start=1820
  _globals['_TRACE']._serialized_end=1885
  _globals['_WORKER']._serialized_start=1888
  _globals['_WORKER']._serialized_end=2025
# @@protoc_insertion_point(module_scope)
