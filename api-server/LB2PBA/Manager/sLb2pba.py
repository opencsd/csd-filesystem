import os 
import subprocess
import json
import requests as re
from flask import Flask, request


app = Flask(__name__)

def getVolumeHost(volume):
	pass
	cmd = "gluster volume info %s | grep Brick"%(volume)
	err, res = subprocess.getstatusoutput(cmd)
	
	hosts = {}
	if err != 0:
		return 1, res
	else:
		res = res.split("\n")[2:]
		
		for r in res:
			host = r.split(":")[1][1:]
			birck = r.split(":")[2]

			hosts[host] = birck

		
		return 0, hosts
	

	

def getGfid(firstFile):
	pass
	path = firstFile["path"]
	host = firstFile["host"]

	gfid = ""

	cmd = "ssh %s 'getfattr -d -m. -e hex %s'"%(host,path)
	err, res = subprocess.getstatusoutput(cmd)

	if err == 0:
		gfid = res.split("gfid=0x")[1].split("\n")[0]

		return 0, gfid

	return 1, res

def getShardList(path,volume):
	pass
	err, hosts = getVolumeHost(volume)
	if err != 0:
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
			shardPath = brick+"/.shard/"

			cmd = "ssh %s 'ls %s'"%(host, shardPath)
			err ,res = subprocess.getstatusoutput(cmd)
		
			if err == 0:
				shards = res.split("\n")

				for shard in shards:
					if gfid in shard.replace("-",""):
						shardList.append({"path": shardPath+shard, "host": host})

	shardList = sorted(shardList, key=(lambda x: x["path"]))
	shardList.insert(0,firstFile)

	return shardList

def file2PBA(host,fName):
	pass
	data = {"fName":fName}
	url = "http://%s:9999/query/block/simple"%host
	
	res = json.loads(re.post(url,data=data).json())["RES"]

	result = []
	
	for file_dict in res["LIST"]:
		
		for chunk in file_dict["CHUNKS"]:
			pba = {}

			pba["OFFSET"] = chunk["OFFSET"]
			pba["LENGTH"] = chunk["LENGTH"]
			pba["HOST"] = host
			pba["DISK"] = file_dict["DISK"]

			result.append(pba)
	
	print("file2PBA : ",result)

	return result

	


@app.route("/getPBA",methods=['GET','POST'])
def getPBA():
	pass

	if request:
		path = str(request.form['path'])
		volume = str(request.form["volume"])
		
		fPath,fName = os.path.split(path)
		

		result = {"name":fName,"fpath":fPath}

		shardList = getShardList(path,volume)

		data = []

		print(shardList)

		for shard in shardList:
			host = shard["host"]
			path = shard["path"]

			data.extend(file2PBA(host,path))
		
		ran = 0
		for i in range(len(data)):
			start = ran
			end = ran + data[i]["LENGTH"]

			data[i]["RANGE"] = [ran, end]

			ran = end

		result["data"] = data

		return json.dumps(result)

if __name__ == "__main__":
    app.run(host="0.0.0.0",port=1111)

