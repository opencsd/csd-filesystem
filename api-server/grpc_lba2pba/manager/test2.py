import lba2pba_pb2
import lba2pba_pb2_grpc

import grpc

import manager_kube

ip = '172.16.219.75'
fileList = ['ab/test3','ftree_chk.py']

pvList = {}

pvcName = manager_kube.GetPVC(ip)

if pvcName in pvList.keys():
	print(lba2pba_pb2.GetFMResponse(FileMap=pvList[pvcName]['FileMap']))
else:
	pvList[pvcName] = dict()
	pvList[pvcName]['FileMap'] = lba2pba_pb2.FileMap()

subDir, volName = manager_kube.GetSubDir(pvcName)
pvList[pvcName]['volName'] = volName
pvList[pvcName]['subDir'] = subDir

for f in fileList:
	fileName = f'{subDir}/{f}'
	with grpc.insecure_channel("trace:23830") as channel:
		stub = lba2pba_pb2_grpc.TraceStub(channel)
		res = stub.Get(lba2pba_pb2.TGetPbaRequest(FileName=fileName,VolName=volName))

		print(f'File : {f}')
		print(res)
