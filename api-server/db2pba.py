# LBA2PBA API Server
# Gluesys

# ChangeLog
#   2021. 11. 04. (목) 13:52:24 KST : simple prototype


from flask import Flask, request
from flask_restx import Api, Resource

import os
import errno
import struct
import array
import fcntl
import json

app = Flask(__name__)
api = Api(app)

# Simple File name to PBA query Interface
# Query : { "db_name" : "/dev/ssd/sss" }

_PBASCAN_FORMAT = "=QQLLLL"
_PBASCAN_SIZE = struct.calcsize(_PBASCAN_FORMAT)
_PBASCAN_EXTENT_FORMAT = "=QQQQQLLLL"
_PBASCAN_EXTENT_SIZE = struct.calcsize(_PBASCAN_EXTENT_FORMAT)
_PBASCAN_IOCTL = 0xC020660B
_PBASCAN_FLAG_SYNC = 0x00000001
_PBASCAN_BUFFER_SIZE = 256 * 1024

class Error(Exception):
    """A class for all the other exceptions raised by this module."""
    pass

@api.route('/query/block/simple')
class block_query(Resource):
    def post(self):
        query_data = {}
        query_data = request.json.get('db_name')

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

        print ("DEBUG: file size: %d, device %d/%d" % (db_info.st_size, 
                disk_minor, disk_minor))

        struct.pack_into(_PBASCAN_FORMAT, pba_buf, 0, 0, db_info.st_size, 
                _PBASCAN_FLAG_SYNC, 0, _fiemap_extent_cnt, 0)

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

        res_dict = dict()
        data_dict = dict()
        file_list = list()

        file_dict = dict()
        chunk_list = list()

        for i in range(0, pba_map[3]):
            dist = _PBASCAN_SIZE + _PBASCAN_EXTENT_SIZE * i
            pba_extent = struct.unpack(_PBASCAN_EXTENT_FORMAT, pba_buf[dist:dist+_PBASCAN_EXTENT_SIZE])
            print ("DEBUG: extent(%d) phy_addr(%d) count(%d)" % (i,  pba_extent[1], pba_extent[2]))
            chunk_obj = dict()
            chunk_obj['SEQID'] = i
            chunk_obj['MAJOR'] = disk_major
            chunk_obj['MINOR'] = disk_minor
            chunk_obj['OFFSET'] = pba_extent[1]
            chunk_obj['LENGTH'] = pba_extent[2]
            chunk_list.append (chunk_obj)

        file_dict['FILENAME'] = query_data
        file_dict['CHUNKS'] = chunk_list
        file_list.append(file_dict)

        data_dict['ORDER'] = "Chunk"
        data_dict['LIST'] = file_list

        res_dict['RES'] = data_dict

        print(res_dict)

        return json.dumps(res_dict)

@api.route('/query/object/<string:name>')
class object_query(Resource):
    def get(self, name):
        return {"object_name":"Request Object PBA : %s!" % name}

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=9999)
