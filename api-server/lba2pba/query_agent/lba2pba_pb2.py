# -*- coding: utf-8 -*-
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: lba2pba.proto
"""Generated protocol buffer code."""
from google.protobuf import descriptor as _descriptor
from google.protobuf import descriptor_pool as _descriptor_pool
from google.protobuf import message as _message
from google.protobuf import reflection as _reflection
from google.protobuf import symbol_database as _symbol_database
# @@protoc_insertion_point(imports)

_sym_db = _symbol_database.Default()




DESCRIPTOR = _descriptor_pool.Default().AddSerializedFile(b'\n\rlba2pba.proto\x12\x07lba2pba\"_\n\x03PBA\x12\x0c\n\x04\x44isk\x18\x01 \x01(\t\x12\x0c\n\x04Host\x18\x02 \x01(\t\x12\x0e\n\x06Offset\x18\x03 \x01(\x03\x12\x0e\n\x06Length\x18\x04 \x01(\x03\x12\r\n\x05Major\x18\x05 \x01(\x03\x12\r\n\x05Minor\x18\x06 \x01(\x03\"6\n\x07\x46ilePBA\x12\x19\n\x03Pba\x18\x01 \x03(\x0b\x32\x0c.lba2pba.PBA\x12\x10\n\x08\x46ileName\x18\x02 \x01(\t\",\n\x07\x46ileMap\x12!\n\x07\x46ilePba\x18\x01 \x03(\x0b\x32\x10.lba2pba.FilePBA\"\"\n\x0eWGetPbaRequest\x12\x10\n\x08\x46ileName\x18\x01 \x01(\t\"\xa3\x01\n\x0fWGetPbaResponse\x12*\n\x03Pba\x18\x01 \x03(\x0b\x32\x1d.lba2pba.WGetPbaResponse.Data\x12\x0c\n\x04\x44isk\x18\x02 \x01(\t\x12\x10\n\x08\x46ileName\x18\x03 \x01(\t\x1a\x44\n\x04\x44\x61ta\x12\r\n\x05Major\x18\x01 \x01(\x03\x12\r\n\x05Minor\x18\x02 \x01(\x03\x12\x0e\n\x06Offset\x18\x03 \x01(\x03\x12\x0e\n\x06Length\x18\x04 \x01(\x03\"3\n\x0eTGetPbaRequest\x12\x10\n\x08\x46ileName\x18\x01 \x01(\t\x12\x0f\n\x07VolName\x18\x02 \x01(\t\",\n\x0fTGetPbaResponse\x12\x19\n\x03Pba\x18\x01 \x03(\x0b\x32\x0c.lba2pba.PBA\"G\n\x10\x43reatePvcRequest\x12\x0f\n\x07PvcName\x18\x01 \x01(\t\x12\x0f\n\x07PvcType\x18\x02 \x01(\t\x12\x11\n\tDupliType\x18\x03 \x01(\t\"1\n\x11\x43reatePvcResponse\x12\x0b\n\x03Msg\x18\x01 \x01(\t\x12\x0f\n\x07PvcName\x18\x02 \x01(\t\"#\n\x10\x44\x65letePvcRequest\x12\x0f\n\x07PvcName\x18\x01 \x01(\t\"1\n\x11\x44\x65letePvcResponse\x12\x0b\n\x03Msg\x18\x01 \x01(\t\x12\x0f\n\x07PvcName\x18\x02 \x01(\t\",\n\x0cGetFMRequest\x12\n\n\x02Ip\x18\x01 \x01(\t\x12\x10\n\x08\x46ileList\x18\x02 \x03(\t\"2\n\rGetFMResponse\x12!\n\x07\x46ileMap\x18\x01 \x01(\x0b\x32\x10.lba2pba.FileMap\"/\n\x0fUpdateFMRequest\x12\n\n\x02Ip\x18\x01 \x01(\t\x12\x10\n\x08\x46ileList\x18\x02 \x03(\t\"5\n\x10UpdateFMResponse\x12!\n\x07\x46ileMap\x18\x01 \x01(\x0b\x32\x10.lba2pba.FileMap\"\x80\x01\n\x0eQGetPbaRequest\x12\x31\n\x08Requests\x18\x01 \x03(\x0b\x32\x1f.lba2pba.QGetPbaRequest.Request\x1a;\n\x07Request\x12\x10\n\x08\x46ileName\x18\x01 \x01(\t\x12\x0e\n\x06Offset\x18\x02 \x01(\x03\x12\x0e\n\x06Length\x18\x03 \x01(\x03\"4\n\x0fQGetPbaResponse\x12!\n\x07\x46ilePba\x18\x01 \x03(\x0b\x32\x10.lba2pba.FilePBA2I\n\nQueryAgent\x12;\n\x06GetPba\x12\x17.lba2pba.QGetPbaRequest\x1a\x18.lba2pba.QGetPbaResponse2\x8a\x02\n\x07Manager\x12\x42\n\tCreatePvc\x12\x19.lba2pba.CreatePvcRequest\x1a\x1a.lba2pba.CreatePvcResponse\x12\x42\n\tDeletePvc\x12\x19.lba2pba.DeletePvcRequest\x1a\x1a.lba2pba.DeletePvcResponse\x12\x36\n\x05GetFM\x12\x15.lba2pba.GetFMRequest\x1a\x16.lba2pba.GetFMResponse\x12?\n\x08UpdateFM\x12\x18.lba2pba.UpdateFMRequest\x1a\x19.lba2pba.UpdateFMResponse2A\n\x05Trace\x12\x38\n\x03Get\x12\x17.lba2pba.TGetPbaRequest\x1a\x18.lba2pba.TGetPbaResponse2B\n\x06Worker\x12\x38\n\x03Get\x12\x17.lba2pba.WGetPbaRequest\x1a\x18.lba2pba.WGetPbaResponseb\x06proto3')



_PBA = DESCRIPTOR.message_types_by_name['PBA']
_FILEPBA = DESCRIPTOR.message_types_by_name['FilePBA']
_FILEMAP = DESCRIPTOR.message_types_by_name['FileMap']
_WGETPBAREQUEST = DESCRIPTOR.message_types_by_name['WGetPbaRequest']
_WGETPBARESPONSE = DESCRIPTOR.message_types_by_name['WGetPbaResponse']
_WGETPBARESPONSE_DATA = _WGETPBARESPONSE.nested_types_by_name['Data']
_TGETPBAREQUEST = DESCRIPTOR.message_types_by_name['TGetPbaRequest']
_TGETPBARESPONSE = DESCRIPTOR.message_types_by_name['TGetPbaResponse']
_CREATEPVCREQUEST = DESCRIPTOR.message_types_by_name['CreatePvcRequest']
_CREATEPVCRESPONSE = DESCRIPTOR.message_types_by_name['CreatePvcResponse']
_DELETEPVCREQUEST = DESCRIPTOR.message_types_by_name['DeletePvcRequest']
_DELETEPVCRESPONSE = DESCRIPTOR.message_types_by_name['DeletePvcResponse']
_GETFMREQUEST = DESCRIPTOR.message_types_by_name['GetFMRequest']
_GETFMRESPONSE = DESCRIPTOR.message_types_by_name['GetFMResponse']
_UPDATEFMREQUEST = DESCRIPTOR.message_types_by_name['UpdateFMRequest']
_UPDATEFMRESPONSE = DESCRIPTOR.message_types_by_name['UpdateFMResponse']
_QGETPBAREQUEST = DESCRIPTOR.message_types_by_name['QGetPbaRequest']
_QGETPBAREQUEST_REQUEST = _QGETPBAREQUEST.nested_types_by_name['Request']
_QGETPBARESPONSE = DESCRIPTOR.message_types_by_name['QGetPbaResponse']
PBA = _reflection.GeneratedProtocolMessageType('PBA', (_message.Message,), {
  'DESCRIPTOR' : _PBA,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.PBA)
  })
_sym_db.RegisterMessage(PBA)

FilePBA = _reflection.GeneratedProtocolMessageType('FilePBA', (_message.Message,), {
  'DESCRIPTOR' : _FILEPBA,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.FilePBA)
  })
_sym_db.RegisterMessage(FilePBA)

FileMap = _reflection.GeneratedProtocolMessageType('FileMap', (_message.Message,), {
  'DESCRIPTOR' : _FILEMAP,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.FileMap)
  })
_sym_db.RegisterMessage(FileMap)

WGetPbaRequest = _reflection.GeneratedProtocolMessageType('WGetPbaRequest', (_message.Message,), {
  'DESCRIPTOR' : _WGETPBAREQUEST,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.WGetPbaRequest)
  })
_sym_db.RegisterMessage(WGetPbaRequest)

WGetPbaResponse = _reflection.GeneratedProtocolMessageType('WGetPbaResponse', (_message.Message,), {

  'Data' : _reflection.GeneratedProtocolMessageType('Data', (_message.Message,), {
    'DESCRIPTOR' : _WGETPBARESPONSE_DATA,
    '__module__' : 'lba2pba_pb2'
    # @@protoc_insertion_point(class_scope:lba2pba.WGetPbaResponse.Data)
    })
  ,
  'DESCRIPTOR' : _WGETPBARESPONSE,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.WGetPbaResponse)
  })
_sym_db.RegisterMessage(WGetPbaResponse)
_sym_db.RegisterMessage(WGetPbaResponse.Data)

TGetPbaRequest = _reflection.GeneratedProtocolMessageType('TGetPbaRequest', (_message.Message,), {
  'DESCRIPTOR' : _TGETPBAREQUEST,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.TGetPbaRequest)
  })
_sym_db.RegisterMessage(TGetPbaRequest)

TGetPbaResponse = _reflection.GeneratedProtocolMessageType('TGetPbaResponse', (_message.Message,), {
  'DESCRIPTOR' : _TGETPBARESPONSE,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.TGetPbaResponse)
  })
_sym_db.RegisterMessage(TGetPbaResponse)

CreatePvcRequest = _reflection.GeneratedProtocolMessageType('CreatePvcRequest', (_message.Message,), {
  'DESCRIPTOR' : _CREATEPVCREQUEST,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.CreatePvcRequest)
  })
_sym_db.RegisterMessage(CreatePvcRequest)

CreatePvcResponse = _reflection.GeneratedProtocolMessageType('CreatePvcResponse', (_message.Message,), {
  'DESCRIPTOR' : _CREATEPVCRESPONSE,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.CreatePvcResponse)
  })
_sym_db.RegisterMessage(CreatePvcResponse)

DeletePvcRequest = _reflection.GeneratedProtocolMessageType('DeletePvcRequest', (_message.Message,), {
  'DESCRIPTOR' : _DELETEPVCREQUEST,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.DeletePvcRequest)
  })
_sym_db.RegisterMessage(DeletePvcRequest)

DeletePvcResponse = _reflection.GeneratedProtocolMessageType('DeletePvcResponse', (_message.Message,), {
  'DESCRIPTOR' : _DELETEPVCRESPONSE,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.DeletePvcResponse)
  })
_sym_db.RegisterMessage(DeletePvcResponse)

GetFMRequest = _reflection.GeneratedProtocolMessageType('GetFMRequest', (_message.Message,), {
  'DESCRIPTOR' : _GETFMREQUEST,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.GetFMRequest)
  })
_sym_db.RegisterMessage(GetFMRequest)

GetFMResponse = _reflection.GeneratedProtocolMessageType('GetFMResponse', (_message.Message,), {
  'DESCRIPTOR' : _GETFMRESPONSE,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.GetFMResponse)
  })
_sym_db.RegisterMessage(GetFMResponse)

UpdateFMRequest = _reflection.GeneratedProtocolMessageType('UpdateFMRequest', (_message.Message,), {
  'DESCRIPTOR' : _UPDATEFMREQUEST,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.UpdateFMRequest)
  })
_sym_db.RegisterMessage(UpdateFMRequest)

UpdateFMResponse = _reflection.GeneratedProtocolMessageType('UpdateFMResponse', (_message.Message,), {
  'DESCRIPTOR' : _UPDATEFMRESPONSE,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.UpdateFMResponse)
  })
_sym_db.RegisterMessage(UpdateFMResponse)

QGetPbaRequest = _reflection.GeneratedProtocolMessageType('QGetPbaRequest', (_message.Message,), {

  'Request' : _reflection.GeneratedProtocolMessageType('Request', (_message.Message,), {
    'DESCRIPTOR' : _QGETPBAREQUEST_REQUEST,
    '__module__' : 'lba2pba_pb2'
    # @@protoc_insertion_point(class_scope:lba2pba.QGetPbaRequest.Request)
    })
  ,
  'DESCRIPTOR' : _QGETPBAREQUEST,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.QGetPbaRequest)
  })
_sym_db.RegisterMessage(QGetPbaRequest)
_sym_db.RegisterMessage(QGetPbaRequest.Request)

QGetPbaResponse = _reflection.GeneratedProtocolMessageType('QGetPbaResponse', (_message.Message,), {
  'DESCRIPTOR' : _QGETPBARESPONSE,
  '__module__' : 'lba2pba_pb2'
  # @@protoc_insertion_point(class_scope:lba2pba.QGetPbaResponse)
  })
_sym_db.RegisterMessage(QGetPbaResponse)

_QUERYAGENT = DESCRIPTOR.services_by_name['QueryAgent']
_MANAGER = DESCRIPTOR.services_by_name['Manager']
_TRACE = DESCRIPTOR.services_by_name['Trace']
_WORKER = DESCRIPTOR.services_by_name['Worker']
if _descriptor._USE_C_DESCRIPTORS == False:

  DESCRIPTOR._options = None
  _PBA._serialized_start=26
  _PBA._serialized_end=121
  _FILEPBA._serialized_start=123
  _FILEPBA._serialized_end=177
  _FILEMAP._serialized_start=179
  _FILEMAP._serialized_end=223
  _WGETPBAREQUEST._serialized_start=225
  _WGETPBAREQUEST._serialized_end=259
  _WGETPBARESPONSE._serialized_start=262
  _WGETPBARESPONSE._serialized_end=425
  _WGETPBARESPONSE_DATA._serialized_start=357
  _WGETPBARESPONSE_DATA._serialized_end=425
  _TGETPBAREQUEST._serialized_start=427
  _TGETPBAREQUEST._serialized_end=478
  _TGETPBARESPONSE._serialized_start=480
  _TGETPBARESPONSE._serialized_end=524
  _CREATEPVCREQUEST._serialized_start=526
  _CREATEPVCREQUEST._serialized_end=597
  _CREATEPVCRESPONSE._serialized_start=599
  _CREATEPVCRESPONSE._serialized_end=648
  _DELETEPVCREQUEST._serialized_start=650
  _DELETEPVCREQUEST._serialized_end=685
  _DELETEPVCRESPONSE._serialized_start=687
  _DELETEPVCRESPONSE._serialized_end=736
  _GETFMREQUEST._serialized_start=738
  _GETFMREQUEST._serialized_end=782
  _GETFMRESPONSE._serialized_start=784
  _GETFMRESPONSE._serialized_end=834
  _UPDATEFMREQUEST._serialized_start=836
  _UPDATEFMREQUEST._serialized_end=883
  _UPDATEFMRESPONSE._serialized_start=885
  _UPDATEFMRESPONSE._serialized_end=938
  _QGETPBAREQUEST._serialized_start=941
  _QGETPBAREQUEST._serialized_end=1069
  _QGETPBAREQUEST_REQUEST._serialized_start=1010
  _QGETPBAREQUEST_REQUEST._serialized_end=1069
  _QGETPBARESPONSE._serialized_start=1071
  _QGETPBARESPONSE._serialized_end=1123
  _QUERYAGENT._serialized_start=1125
  _QUERYAGENT._serialized_end=1198
  _MANAGER._serialized_start=1201
  _MANAGER._serialized_end=1467
  _TRACE._serialized_start=1469
  _TRACE._serialized_end=1534
  _WORKER._serialized_start=1536
  _WORKER._serialized_end=1602
# @@protoc_insertion_point(module_scope)