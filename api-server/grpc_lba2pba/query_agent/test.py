import grpc

import lba2pba_pb2
import lba2pba_pb2_grpc



def run():
	with grpc.insecure_channel("master:23831") as channel:
		stub = lba2pba_pb2_grpc.ManagerStub(channel)
		fileList = ["ftree_chk.py",'ab/test3']
		res = stub.GetFM(lba2pba_pb2.GetFMRequest(Ip="172.16.219.75",FileList=fileList))

		print(res)


if __name__ == "__main__":
	run()
