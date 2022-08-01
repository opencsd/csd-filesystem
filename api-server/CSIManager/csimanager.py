from flask import Flask, request
import os
import yaml
import subprocess

app = Flask(__name__)

_DIS = "kadalu.gluster-vol"
_REP1 = ""
_REP2 = ""
_REP3 = ""

def applyPVC(name):
	cmd = "kubectl create -f yaml/%s"%name
	err, msg = subprocess.getstatusoutput(cmd)

def createPVC(pvcName,pvcType,scName,limit):
	pass
	template = ""
	yamlName = "%s_pvc.yaml"%(pvcName)
	with open('template_pvc.yaml','r') as f:
		template = yaml.load(f,Loader=yaml.FullLoader)
	
		template["metadata"]["name"] = pvcName
		template["spec"]["storageClassName"] = scName
		template["spec"]["resources"]["requests"]["storage"] = limit

	with open("yaml/%s"%yamlName,'w') as f:
		yaml.dump(template,f,default_flow_style=False)
	
	applyPVC(yamlName)
	
@app.route("/getSubdir",methods=["GET","POST"])
def getSubdir():
	if request:
		ip = str(request.form["ip"])

		podCMD = '''kubectl get pod -o json | jq '.items[] | select(.status.podIP=="%s") | .metadata.name' '''%ip
		err, podName = subprocess.getstatusoutput(podCMD)

		pvcCMD = '''kubectl get pod/%s -o json | jq -r ".spec.volumes[0].persistentVolumeClaim.claimName" '''%podName
		err, pvcName = subprocess.getstatusoutput(pvcCMD)

		pvCMD = '''kubectl get pvc/%s -o json | jq -r ".spec.volumeName" '''%pvcName
		err, pvName = subprocess.getstatusoutput(pvCMD)

		subdirCMD = '''kubectl get pv/%s -o json | jq -r ".spec.csi.volumeAttributes.path" '''%pvName
		err, subDir = subprocess.getstatusoutput(subdirCMD)

		scCMD = '''kubectl get pvc/%s -o json | jq -r ".spec.storageClassName" '''%pvcName
		err, scName = subprocess.getstatusoutput(scCMD)

		glsCMD = '''kubectl get sc/%s -o json | jq -r ".parameters.gluster_volname" '''%scName
		err, volName = subprocess.getstatusoutput(glsCMD)

		subDir = subDir.replace("\n","")
		volName = volName.replace("\n","")
		
		return {"data" : [subDir,volName]}

@app.route("/create",methods=["GET","POST"])
def create():
	if request:
		pvcName = str(request.form["pvcName"])
		pvcType = str(request.form["pvcType"])
		dupliType = str(request.form["dupliType"])
		limit = str(request.form["limit"])
		
		scName = ""

		if dupliType == "distribute":
			scName = _DIS
		elif dupliType == "replica1":
			scName = _REP1
		elif dupliType == "replica2":
			scName = _REP2
		elif dupliType == "replica3":
			scName = _REP3

		createPVC(pvcName,pvcType,scName,limit)
		
		return pvcName

@app.route("/delete",methods=["GET","POST"])
def delete():
	if request:
		pvcName = str(request.form["pvcName"])

		cmd = "kubectl delete pvc/%s && rm -f yaml/%s_pvc.yaml"%(pvcName,pvcName)
		err, msg = subprocess.getstatusoutput(cmd)

		return msg

@app.route("/get",methods=["GET","POST"])
def get():
	if request:
		result = []

		cmd = "kubectl get pvc"
		err, res = subprocess.getstatusoutput(cmd)
		res = res.split("\n")[1:]
		
		for r in res:
			pvc = {}
			r = r.split()

			pvc["name"] = r[0]
			if "kadalu" in r[5]:
				pvc["pvcType"] = "Gluster"
				if "vol1" in r[5]:
					pvc["dupliType"] = "Replica 1"
				elif "vol2" in r[5]:
					pvc["dupliType"] = "Replica 2"
				elif "vol3" in r[5]:
					pvc["dupliType"] = "Replica 3"
				else:
					pvc["dupliType"] = "Distribute"

				cmd = '''kubectl get pv/%s -o json | jq -r ".spec.csi.volumeAttributes.path" '''%r[2]
				err, subdir = subprocess.getstatusoutput(cmd)
				pvc["subdir"] = subdir
			else:
				pvc["pvcType"] = "NVMeOF"
			result.append(pvc)
					
		return {"result":result}

if __name__ == "__main__":
	app.run(host="0.0.0.0",port=1113)
