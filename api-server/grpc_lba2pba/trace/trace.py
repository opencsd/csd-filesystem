from concurrent import futures
import logging

import grpc

import os
import lba2pba_pb2
import lba2pba_pb2_grpc

import shard

def getGlusterHost():
	cmd = 'gluster peer status | grep Hostname'
	err, res = subprocess.getstatusoutput(cmd)

	hosts = ['localhost']
	if res:
		for line in res.split('\n'):
			hosts.append(line.split(": ")[1])

		return hosts

def getFM(volume,fName):
	shardList = shard.getShardList()
	
#	re = {}

	for t in shardList.keys():
		if not volume in shardList[t].keys():
			continue
		
		for f in shardList[t][volume].keys():
			if fName in f:
				fName = f
	
		#if not volume in re.keys():
		#	re[volume] = {}

		#if not fList:
		#	flist = shardList[t][volume].keys()

		if t == 'replica':
		#	for fName in flist:
			FM = {'FileName':fName,'Type':t,'rPba':[]}
			for host in shardList[t][volume][fName].keys():
				rPba = {}
				pba = []
				for f in shardList[t][volume][fName][host]:
					with grpc.insecure_channel(f'{host}:23829') as channel:
						stub = lba2pba_pb2_grpc.WorkerStub(channel)
						res = stub.Get(lba2pba_pb2.WGetPbaRequest(FileName=f))

						for p in res.Pba:
							tdict = {
								'Disk': res.Disk,
								'Host': host,
								'Offset': p.Offset,
								'Length': p.Length,
							}

							pba.append(tdict)

				rPba['Pba'] = pba
				rPba['Node'] = host

				FM['rPba'].append(rPba)

			#re[volume][fName]=FM
			return FM

		elif t == 'distribute':
			#for fName in flist:
			FM = {'FileName':fName, 'Type':t, 'Pba':[]}

			for fInfo in shardList[t][volume][fName]:
				host, f = fInfo.split(' ')

				with grpc.insecure_channel(f'{host}:23829') as channel:
					stub = lba2pba_pb2_grpc.WorkerStub(channel)
					res = stub.Get(lba2pba_pb2.WGetPbaRequest(FileName=f))

					pba = []
					for p in res.Pba:
						tdict = {
							'Disk': res.Disk,
							'Host': host,
							'Offset': p.Offset,
							'Length': p.Length,
							'Major': p.Major,
							'Minor': p.Minor
						}

						FM['Pba'].append(tdict)

			return FM

	return 

class Trace(lba2pba_pb2_grpc.TraceServicer): 	
	def Get(self,request,context):

		fName = request.FileName
		volume = request.VolName
		
		data = getFM(volume,fName)

		if data['Type'] == 'distribute':
			return lba2pba_pb2.TGetPbaResponse(Pba=data['Pba'])
		elif data['Type'] == 'replica':
			return lba2pba_pb2.TGetPbaResponse(RPba=data['rPba'])



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


	
