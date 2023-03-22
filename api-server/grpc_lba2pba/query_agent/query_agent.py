from concurrent import futures
import logging
import subprocess

import grpc

import lba2pba_pb2
import lba2pba_pb2_grpc

import ftree_chk

FM = lba2pba_pb2.FileMap()
FMTree = {}
Root = ""
Ip = ""

def UpdatePush(RootDic):
	pass


def getIP():
	cmd = "hostname -i"
	err , ip = subprocess.getstatusoutput(cmd)

	return ip

def getRoot():
	cmd = "df -Th | grep gluster"
	err ,res = subprocess.getstatusoutput(cmd)

	root = res.split()[-1]

	return root

def initFM():
	global FMTree
	global Root
	global Ip
	global FM

	Root = getRoot()
	Ip = getIP()

	FMTree = ftree_chk.fTree(Root)
	fList = list(FMTree.keys())

	with grpc.insecure_channel("lba2pba_manager:23831") as channel:
		stub = lba2pba_pb2_grpc.ManagerStub(channel)
		res = stub.GetFM(lba2pba_pb2.GetFMRequest(Ip=Ip,FileList=fList))

		FM = res

def getPba(file_name, start_offset, length):
	global FM

	result_pba = []
	for file_pba in FM.FileMap.FilePba:
		if file_name == file_pba.FileName.split("/")[-1]:
			start = start_offset
			left_len = length
			
			start_chk = False
			end_chk = False

			for pba in file_pba.Pba:
				tmp_pba = lba2pba_pb2.PBA()
				s = pba.Offset
				e = s + pba.Length

				if not start_chk:
					if start <= pba.Length :
						tmp_pba.Disk = pba.Disk
						tmp_pba.Host = pba.Host
						tmp_pba.Offset = s + start

						if tmp_pba.Offset + left_len <= e:
							tmp_pba.Length = left_len
							end_chk = True
						else:
							tmp_pba.Length = e-(s+start)
							left_len -= tmp_pba.Length

						result_pba.append(tmp_pba)
						start_chk = True
				else:
					if not end_chk:
						tmp_pba.Disk = pba.Disk
						tmp_pba.Host = pba.Host
						tmp_pba.Offset = pba.Offset

						if tmp_pba.Offset + left_len < e:
							tmp_pba.Length = left_len
							end_chk = True
						else:
							tmp_pba.Length = pba.Length

						result_pba.append(tmp_pba)

	return {"Pba":result_pba,"FileName":file_name}
					

				
			

class QueryAgent:
	def GetPba(self,request,context):
		global FM
		print(FM)
		result = []		
		
		for re in request.Requests:
			file_name = re.FileName
			start_offset = re.Offset
			length = re.Length
			
			print("%s %s %s"%(file_name,start_offset,length))
		
			result.append(getPba(file_name, start_offset, length))


		return lba2pba_pb2.QGetPbaResponse(FilePba=result)


def serve():
	server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
	lba2pba_pb2_grpc.add_QueryAgentServicer_to_server(QueryAgent(),server)
	server.add_insecure_port('[::]:23832')
	print("Query Agent Start!!\nPort : 23832")
	server.start()
	server.wait_for_termination()

if __name__ == "__main__":
	initFM()
	logging.basicConfig()
	serve()
	

