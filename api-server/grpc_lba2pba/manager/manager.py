import os
import yaml
import subprocess

from concurrent import futures
import logging

import grpc

import lba2pba_pb2
import lba2pba_pb2_grpc

import manager_kube

pvList = {}

class Manager(lba2pba_pb2_grpc.ManagerServicer):
	global pvList

	def CreatePvc(self, request, context):
		pass

	def DeletePvc(self, request, context):
		pass

	def GetFM(self, request, context):
		ip = request.Ip
		fileList = request.FileList

		pvcName = manager_kube.GetPVC(ip)

		print(f'IP : {ip}\nFiles : {fileList}\nPVC : {pvcName}')

		if pvcName in pvList.keys():
			return lba2pba_pb2.GetFMResponse(FileMap=pvList[pvcName]["FileMap"])
		else:
			pvList[pvcName] = dict()
			pvList[pvcName]["FileMap"] = lba2pba_pb2.FileMap()
		
		
		subDir, volName = manager_kube.GetSubDir(pvcName)
		pvList[pvcName]["volName"] = volName
		pvList[pvcName]["subDir"] = subDir
		
		for f in fileList:
			fileName = "%s/%s"%(subDir,f)
			print(f'fileName : {fileName}\nvolName:{volName}')
			with grpc.insecure_channel("trace:23830") as channel:
				stub = lba2pba_pb2_grpc.TraceStub(channel)
				res = stub.Get(lba2pba_pb2.TGetPbaRequest(FileName=fileName,VolName=volName))

				FilePba = lba2pba_pb2.FilePBA()
				if res.Pba:
					FilePba.Pba.extend(res.Pba)
					FilePba.Type = 'distribute'
				elif res.RPba:
					FilePba.rPba.extend(res.RPba)
					FilePba.Type = 'replica'
					
				FilePba.FileName = f

				pvList[pvcName]["FileMap"].FilePba.append(FilePba)
		

		return lba2pba_pb2.GetFMResponse(FileMap=pvList[pvcName]["FileMap"])
			
		
			

	def UpdateFM(self, request, context):
		ip = request.Ip
		fileList = request.FileList

		pvcName = manager_kube.GetPVC(ip)

		volName = pvList[pvcName]["volName"]

		for f in fileList:
			fileName = "%s/%s"%(pvList[pvcName]["subDir"],f)
			with grpc.insecure_channel("trace:23830") as channel:
				stub = lba2pba_pb2_grpc.TraceStub(channel)
				res = stub.Get(lba2pba_pb2.TGetPbaRequest(FileName=fileName,VolName=volName))

				for i in range(len(pvList[pvcName]["FileMap"].FilePba)):
					t = pvList[pvcName]["FileMap"].FilePba[0].Type

					if pvList[pvcName]["FileMap"].FilePba[i].FileName == f:
						
						if t == 'distribute':
							pvList[pvcName]["FileMap"].FilePba[i].ClearField("Pba")
							pvList[pvcName]["FileMap"].FilePba[i].Pba = res
						elif t == 'replica':
							pvList[pvcName]["FileMap"].FilePba[i].clearField("rPba")
							pvList[pvcName]["FIleMap"].FilePba[i].rPba = res

						print(pvList[pvcName]["FileMap"])
			

		return lba2pba_pb2.UpdateFMResponse(FileMap=pvList[pvcName]["FileMap"])
def serve():
	server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
	lba2pba_pb2_grpc.add_ManagerServicer_to_server(Manager(),server)
	server.add_insecure_port('[::]:23831')
	print("LBA2PBA Manager Start !!\nPort : 23831")
	server.start()
	server.wait_for_termination()

if __name__ == "__main__":
	logging.basicConfig()
	serve()
