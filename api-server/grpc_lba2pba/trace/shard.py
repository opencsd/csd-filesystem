import os
import subprocess
import json
import re

import grpc

import lba2pba_pb2
import lba2pba_pb2_grpc

def getGlusterHosts():
	cmd = 'gluster peer status | grep Hostname'
	err, res = subprocess.getstatusoutput(cmd)

	cmd = 'hostname'
	err, host = subprocess.getstatusoutput(cmd)
	
	hosts = [host]
	if res:
		for line in res.split('\n'):
			hosts.append(line.split(": ")[1])

		return hosts

def getShardList():
	hosts = getGlusterHosts()

	shardList = {'replica':{},'distribute':{}}

	shardType = {}
	
	dSList = {}

	resData = {}
	for host in hosts:
		with grpc.insecure_channel(f'{host}:23829') as channel:
			stub = lba2pba_pb2_grpc.WorkerStub(channel)
			res = stub.GetShardList(lba2pba_pb2.WGetShardRequest())
			
			resData[host] = res

			for volume in res.vShardList:
				isReplica = True
				volName = volume.VolName

				for vshard in volume.ShardList:
					if 'Shard' == vshard.FileName:
						isReplica = False

				if isReplica:
					if not volName in shardList['replica'].keys():
						shardList['replica'][volName] = {}

					for vshard in volume.ShardList:
						fName = vshard.FileName
						if not fname in shardList['replica'][volName].keys():
							shardList['replica'][volName][fName] = {}

						if not host in shardList['replica'][volName][fname].keys():
							shardList['replica'][volName][fName][host] = [fName]

						if vshard.shardList:
							shardList['replica'][volName][fName][host]+=list(vshard.shardList)
						
				else:
					if not volName in shardList['distribute'].keys():
						shardList['distribute'][volName] = {}

					for vshard in volume.ShardList:
						fName = vshard.FileName
						shard = vshard.shardList[0]
						if not fName == 'Shard':
							if not fName in shardList['distribute'][volName].keys():
								shardList['distribute'][volName][fName] = [f'{host} {fName}']

							
							if not shard in dSList.keys():
								dSList[shard] = fName

	for host in hosts:
		for data in resData[host].vShardList:
			volName = data.VolName
			
			if volName in shardList['distribute'].keys():
				for vshard in data.ShardList:
					if vshard.FileName == 'Shard':
						for sName in list(vshard.shardList):
							s = sName.rsplit('/',1)[1].split('.')[0]
							if s in dSList.keys():
								fName = dSList[s]
								shardList['distribute'][volName][fName].append(f'{host} {sName}')

			
				for fName in shardList['distribute'][volName].keys():
					tsl = ['' for i in range(len(shardList['distribute'][volName][fName]))]
					
					chk=0 
					for shard in shardList['distribute'][volName][fName]:
						if chk != 0:
							num = shard.split(' ')[-1].rsplit('.')[-1]
							tsl[int(num)] = shard
						else:
							tsl[0] = shard	
							

						chk += 1
						
					shardList['distribute'][volName][fName] = tsl
			elif volName in shardList['replica'].keys():
				for fName in shardList['replica'][volName].keys():
					tsl = ['' for i in range(len(shardList['replica'][volName][fName][host]))]

					chk = 0 
					for shard in shardList['replica'][volName][fName][host]:
						if chk != 0:
							num = shard.split(' ')[-1].rsplit('.')[-1]
							tsl[int(num)] = shard
						else:
							tsl[0] = shard

						chk += 1

					shardList['replica'][volName][fName][host] = tsl
					
	return shardList
			
    


def getPba(path, host):
    try:
        with grpc.insecure_channel('%s:23829'%host) as channel:
            stub = lba2pba_pb2_grpc.WorkerStub(channel)
            res = stub.Get(lba2pba_pb2.WGetPbaRequest(FileName=path))

            disk = res.Disk
            
            pba_list = list()

            for pba in res.Pba:
                data = lba2pba_pb2.PBA(Disk=disk,Host=host,Major=pba.Major,Minor=pba.Minor,Offset=pba.Offset)

                pba_list.append(data)

        return pba_list

    except Exception as e:
        print(e)
