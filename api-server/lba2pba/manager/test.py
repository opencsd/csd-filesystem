import grpc

import lba2pba_pb2
import lba2pba_pb2_grpc



def run():
	with grpc.insecure_channel("192.168.10.20:23831") as channel:
		stub = lba2pba_pb2_grpc.ManagerStub(channel)
		fileList = ["test.txt"]
		res = stub.GetFM(lba2pba_pb2.GetFMRequest(Ip="10.44.0.4",FileList=fileList))

		print(res)


if __name__ == "__main__":
	run()
