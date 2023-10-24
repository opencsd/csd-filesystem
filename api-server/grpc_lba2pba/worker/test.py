import grpc

import lba2pba_pb2
import lba2pba_pb2_grpc

with grpc.insecure_channel("worker1:23829") as channel:
	stub = lba2pba_pb2_grpc.WorkerStub(channel)
	res = stub.GetShardList(lba2pba_pb2.WGetShardRequest(VolName='replica3_1'))

	print(res)
