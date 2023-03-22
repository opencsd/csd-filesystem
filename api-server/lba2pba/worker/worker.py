from concurrent import futures
import logging

import grpc

import lba2pba_pb2
import lba2pba_pb2_grpc

import os
import errno
import struct
import array
import fcntl
import json
import subprocess

_PBASCAN_FORMAT = "=QQLLLL"
_PBASCAN_SIZE = struct.calcsize(_PBASCAN_FORMAT)
_PBASCAN_EXTENT_FORMAT = "=QQQQQLLLL"
_PBASCAN_EXTENT_SIZE = struct.calcsize(_PBASCAN_EXTENT_FORMAT)
_PBASCAN_IOCTL = 0xC020660B
_PBASCAN_FLAG_SYNC = 0x00000001
_PBASCAN_BUFFER_SIZE = 256 * 1024

class Worker(lba2pba_pb2_grpc.WorkerServicer):
	def Get(self, request, context):
		query_data = {}
		query_data = request.FileName

		cmd = "df %s"%query_data
		err, res = subprocess.getstatusoutput(cmd)
		res = res.split("\n")[1]		

		disk = res.split()[0]

		print ("DEBUG: file name : %s" % query_data)

		pba_buf_size = _PBASCAN_BUFFER_SIZE - _PBASCAN_SIZE
		_fiemap_extent_cnt = pba_buf_size // _PBASCAN_EXTENT_SIZE
		pba_buf_size = _fiemap_extent_cnt * _PBASCAN_EXTENT_SIZE
		pba_buf_size += _PBASCAN_SIZE

		pba_buf = array.array('B', [0] * pba_buf_size)

		db_fd = open ("%s" % query_data, "r")
		db_info = os.stat(query_data)
		disk_major = os.major(db_info.st_dev)
		disk_minor = os.minor(db_info.st_dev)

		print ("DEBUG: file size: %d, device %d/%d" % (db_info.st_size, disk_minor, disk_minor))

		struct.pack_into(_PBASCAN_FORMAT, pba_buf, 0, 0, db_info.st_size,_PBASCAN_FLAG_SYNC, 0, _fiemap_extent_cnt, 0)

		try:
			fcntl.ioctl(db_fd, _PBASCAN_IOCTL, pba_buf, 1)

		except IOError as err:
			if err.errno == errno.EOPNOTSUPP:
				print ("FIEMAP ioctl is not supported by filesystem (%d)" % err)
				pass
			if err.errno == errno.ENOTTY:
				print ("FIEMAP ioctl is not supported by kernel (%d)" % err)
				pass
			raise Error ("the FIEMAP ioctl failed for '%s': %s" % (query_data, err))

		pba_map = struct.unpack(_PBASCAN_FORMAT, pba_buf[:_PBASCAN_SIZE])
		print ("DEBUG: extent counts : " , pba_map[3])

				
		chunk_list = list()

		for i in range(0, pba_map[3]):

			dist = _PBASCAN_SIZE + _PBASCAN_EXTENT_SIZE * i
			pba_extent = struct.unpack(_PBASCAN_EXTENT_FORMAT, pba_buf[dist:dist+_PBASCAN_EXTENT_SIZE])
			print ("DEBUG: extent(%d) phy_addr(%d) count(%d)" % (i,  pba_extent[1], pba_extent[2]))
			chunk_obj = dict()
			chunk_obj['Major'] = disk_major
			chunk_obj['Minor'] = disk_minor
			chunk_obj['Offset'] = pba_extent[1]
			chunk_obj['Length'] = pba_extent[2]
			chunk_list.append (chunk_obj)
		
		data_dict = dict()

		return lba2pba_pb2.WGetPbaResponse(Pba=chunk_list,Disk=disk,FileName=query_data)

def serve():
	server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
	lba2pba_pb2_grpc.add_WorkerServicer_to_server(Worker(),server)
	server.add_insecure_port('[::]:23829')
	print("PBA Worker Start!!")
	server.start()
	server.wait_for_termination()

if __name__ == "__main__":
	logging.basicConfig()
	serve()


