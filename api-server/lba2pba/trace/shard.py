import os
import subprocess
import json


def getVolumeHost(volume):
	cmd = "gluster volume info %s | grep Brick"%(volume)
	err ,res = subprocess.getstatusoutput(cmd)

	hosts = {}
	if err != 0:
		return 1, res

	else:
		res = res.split("\n")[2:]
		
		for r in res:
			host = r.split(":")[1][1:]
			brick = r.split(":")[2]

			hosts[host] = brick

		return 0, hosts

def getGfid(firstFile):
	path = firstFile["path"]
	host = firstFile["host"]

	gfid = ""
	
	cmd = "ssh %s 'getfattr -d -m. -e hex %s'"%(host,path)
	err, res = subprocess.getstatusoutput(cmd)

	if err == 0:
		gfid = res.split("gfid=0x")[1].split("\n")[0]

		return 0, gfid

	return 1, res

def getShardList(path, volume):
	err, hosts = getVolumeHost(volume)
	if err !=0:
		return err, hosts

	shardList = list()

	firstFile = {}

	for host in hosts.keys():
		brick = hosts[host]
		fullPath = brick + "/" + path

		cmd = "ssh %s 'ls %s'"%(host,fullPath)
		err, res = subprocess.getstatusoutput(cmd)
		
		if err == 0:
			firstFile["path"] = fullPath
			firstFile["host"] = host

	err, gfid = getGfid(firstFile)
	if err == 0:
		for host in hosts.keys():
			brick = hosts[host]
			shardPath = brick + "/.shard/"
			
			cmd = "ssh %s 'ls %s'"%(host, shardPath)	
			err, res = subprocess.getstatusoutput(cmd)

			if err == 0:
				shards = res.split("\n")

				for shard in shards:
					if gfid in shard.replace("-",""):
						shardList.append({"path": shardPath+shard, "host": host})

	shardList = sorted(shardList, key=(lambda x: x["path"]))
	shardList.insert(0,firstFile)

	return shardList

	
