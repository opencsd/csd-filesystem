from concurrent import futures
import logging

import grpc

import os
import lba2pba_pb2
import lba2pba_pb2_grpc

import shard

class Trace(lba2pba_pb2_grpc.TraceServicer):
	def Get(self,request,context):
		path = request.FileName
		volume = request.VolName

		shardList = shard.getShardList(path,volume)

		pba_list = list()
		

		for shardlist in shardList:
			path = shardlist['path']
			host = shardlist['host']

			with grpc.insecure_channel("%s:23829"%host) as channel:
				stub = lba2pba_pb2_grpc.WorkerStub(channel)
				res = stub.Get(lba2pba_pb2.WGetPbaRequest(FileName=path))
				

				disk = res.Disk
				
				for pba in res.Pba:
					data = dict()
					data["Disk"] = disk
					data["Host"] = host
					data["Major"] = pba.Major
					data["Minor"] = pba.Minor
					data["Offset"] = pba.Offset
					data["Length"] = pba.Length

					pba_list.append(data)

		print(pba_list)

		return lba2pba_pb2.TGetPbaResponse(Pba=pba_list)


def serve():
	server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
	lba2pba_pb2_grpc.add_TraceServicer_to_server(Trace(),server)
	server.add_insecure_port('[::]:23830')
	print("LBA2PBA Trace Start !!")
	server.start()
	server.wait_for_termination()

if __name__ == "__main__":
	logging.basicConfig()
	serve()


	
