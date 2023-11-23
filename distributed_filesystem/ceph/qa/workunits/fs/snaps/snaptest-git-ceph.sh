#!/bin/sh -x

set -e

# try it again if the clone is slow and the second time
retried=false
trap -- 'retry' EXIT
retry() {
    rm -rf ceph
    # double the timeout value
    timeout 3600 git clone git://git.ceph.com/ceph.git
}
rm -rf ceph
timeout 1800 git clone git://git.ceph.com/ceph.git
trap - EXIT
cd ceph

versions=`seq 1 21`

for v in $versions
do
    ver="v0.$v"
    echo $ver
    git reset --hard $ver
    mkdir .snap/$ver
done

for v in $versions
do
    ver="v0.$v"
    echo checking $ver
    cd .snap/$ver
    git diff --exit-code
    cd ../..
done

for v in $versions
do
    ver="v0.$v"
    rmdir .snap/$ver
done

echo OK
