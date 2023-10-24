import lba2pba_pb2
import lba2pba_pb2_grpc
import grpc

with grpc.insecure_channel('worker1:23830') as channel:
    path = 'ab/test3'

    stub = lba2pba_pb2_grpc.TraceStub(channel)
    res = stub.Get(lba2pba_pb2.TGetPbaRequest(FileName=path,VolName='replica3_1'))

    print(res)
