import os
import subprocess


def fTree(dic):
	ftree = {}
	for curDir, dirs, files in os.walk(dic):
		for d in dirs:
			fTree(d)
		for f in files:
			if not ".swp" in f:
				p = os.path.join(curDir,f)
				mtime = os.path.getmtime(p)

				p = p.split(dic)[1][1:]

				ftree[p] = mtime

	return ftree

def diffTree(tree, rootDic):
	curTree = fTree(rootDic)
	
	fList = tree.keys()
	cfList = curTree.keys()

	result = list()
	
	if tree != curTree:
		for f in cfList:
			if f in fList:
				if curTree[f] != tree[f]:
					result.append(f)
			else:
				result.append(f)	
			
		return True, result

	return False, result
