import shard
import grpc

import lba2pba_pb2
import lba2pba_pb2_grpc

shardList = shard.getShardList()

re = []

for t in shardList.keys():
	for volName in shardList[t].keys():
		if t == 'replica':
			for fName in shardList[t][volName].keys():
				FM = {'FileName':'','Type':'','rPba':[]}
				for host in shardList[t][volName][fName].keys():
					rPba = {}
					pba = []
					for f in shardList[t][volName][fName][host]:
						with grpc.insecure_channel(f'{host}:23829') as channel:
							stub = lba2pba_pb2_grpc.WorkerStub(channel)
							res = stub.Get(lba2pba_pb2.WGetPbaRequest(FileName=f))
							
							for p in res.Pba:
								tdict = {
									'Disk': res.Disk,
									'Host': host,
									'Offset': p.Offset,
									'Length': p.Length,
									'Major': p.Major,
									'Minor': p.Minor
								}
								
								pba.append(tdict)

						rPba['pba'] = pba
						rPba['Node'] = host

					FM['FileName'] = fName
					FM['Type'] = t
					FM['rPba'].append(rPba)
				
				re.append(FM)			
		elif t == 'distribute':
			for fName in shardList[t][volName].keys():
				FM = {'FileName':fName,'Type':t,'Pba':[]}

				for fInfo in shardList[t][volName][fName]:	
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

				re.append(FM)

print(re)
