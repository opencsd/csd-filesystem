#!/bin/sh
# Simple Peer Reset script 
# http://gluster-documentations.readthedocs.io/en/master/Administrator%20Guide/Resolving%20Peer%20Rejected/
#   Changlog : 2017. 10. 18. (수) 11:06:09 KST by hgichon
#--------------------------------------------------------------------------------
#    Stop glusterd
#    In /var/lib/glusterd, delete everything except glusterd.info (the UUID file)
#    Start glusterd
#    Probe one of the good peers
#    Restart glusterd, check 'gluster peer status'
#    You may need to restart glusterd another time or two, keep checking peer status.
#--------------------------------------------------------------------------------

GOOD_PEER=

service glusterd stop
cp /var/lib/glusterd/glusterd.info /tmp/
rm -rf /var/lib/glusterd/*
service glusterd start
gluster peer probe $GOOD_PEER
gluster peer status
service glusterd restart
gluster peer status
