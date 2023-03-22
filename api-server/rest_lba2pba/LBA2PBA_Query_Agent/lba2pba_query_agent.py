import os
import subprocess
import json
import time
import requests as re
import threading
from flask import Flask, request

app = Flask(__name__)

FMState = {}
FM = {}

Subvol = ""
Volume = ""

def fileState(dic):
	state = {}
	for curDir, dirs, files in os.walk(dic):
		for d in dirs:
			fileState(d)
		for f in files:
			if not ".swp" in f:
				p = os.path.join(curDir,f)
				mtime = os.path.getmtime(p)
			
				state[p]=mtime
	
	return state

def checkFM(FMState, RootDic):
	curFMState = fileState(RootDic)
	if FMState != curFMState:
		return True

	return False

def UpdatePush(RootDic):
	global FMState
	global FM
	while True:
		if checkFM(FMState,RootDic):
			FMState = fileState(RootDic)
			
			
			print(FMState)

		time.sleep(5)

def LB2PBA(path,sector,length):
	pass
	global FM

	result = []
	for i in range(len(FM.keys())):
		f = list(FM.keys())[i]
		print("path %s : , FM path : %s"%(path,f))
		if path != f:
			continue
		
		sector = int(sector)
		length = int(length)		

		start = sector
		end  = sector+length
		

		schk = False
		echk = False
		
		
		for fpba in FM[f]["data"]:
			pba={}
			s = fpba["RANGE"][0]
			e = fpba["RANGE"][1]
			if not schk:
				
				print("FM Start : %d, Start : %d"%(s, start))
				if s <= start and start < e:
					pba["HOST"] = fpba["HOST"]
					pba["DISK"] = fpba["DISK"]
					pba["OFFSET"] = fpba["OFFSET"]+(start-s)

					

					if end < e:
						pba["LENGTH"] = end-start
						echk = True
					else:
						pba["LENGTH"] = e - start
						

					result.append(pba)
					schk = True
					
			else:
				if not echk:
					pba["HOST"] = fpba["HOST"]
					pba["DISK"] = fpba["DISK"]
					pba["OFFSET"] = fpba["OFFSET"]
					
					print("FM End : %d, End : %d"%(e, end))
					if s <= e and end < e:
						pba["LENGTH"] = end - s
						echk = True
					else:
						pba["LENGTH"] = fpba["LENGTH"]
					
					print(pba)

					result.append(pba)
	
	
	return result
					
				

def file2PBA(fName,RootDic):
	pass
	global Volume
	global Subvol
	name = fName.split(RootDic)[1]
	
	path = Subvol+name
	data = {"path":path,"volume":Volume}	
	
	
	pba = re.post("http://192.168.10.91:1111/getPBA",data=data).json()


	return pba

@app.route("/getPBA",methods=["GET","POST"])
def getPBA():
	pass
	if request:
		fpath = str(request.form["fpath"])
		offsets = json.loads(request.form["offsets"].replace("'",'''"'''))

		print(offsets)
		
		result = {"name" : fpath, "data" : {}}

		for index in offsets:
			offset = offsets[index][0]
			length = offsets[index][1]

			data = LB2PBA(fpath,offset,length)
		
			result["data"][index] = data

		return result



@app.route("/initFM",methods=["GET","POST"])
def initFM():
	global Subvol
	global Volume
	global FM
	global FMState

	cmd = "mount | grep gluster"
	err, res = subprocess.getstatusoutput(cmd)
	
	if err == 0:
		RootDic = res.split()[2]
		
		FMState = fileState(RootDic)

		cmd = "ifconfig | grep inet"
		err, res = subprocess.getstatusoutput(cmd)

		print(RootDic)
		
		if err == 0:
			ip = {"ip":res.split()[1]}
			data = re.post("http://csimanager:1113/getSubdir",data=ip).json()["data"]

			#Subvol, Volume = re.post("http://csiManager:5000/getPodInfo",data)

			Subvol = data[0]
			Volume = data[1]
			
			for fName in FMState.keys():
				FM[fName] = file2PBA(fName,RootDic)
		
		t = threading.Thread(target=UpdatePush,args=(RootDic,))
		t.start()

		
		return FM


if __name__ == "__main__":
	app.run(host="0.0.0.0",port=1111)
