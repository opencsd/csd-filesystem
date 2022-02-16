#!/bin/sh

# RoCE v2 enable code by hgichon  2016. 03. 31. (목) 01:59:38 KST

base=/sys/kernel/config/rdma_cm
ib=/sys/class/infiniband

if [ ! -e $ib ]; then
        exit 1
fi

case "$1" in
  start)
    mount -t configfs none /sys/kernel/config

    for dev in $ib/*;
    do
        mlnx=$(basename $dev)
        mkdir -p $base/$mlnx
        echo RoCE V2 > $base/$mlnx/default_roce_mode
        rmdir $base/$mlnx
    done
    umount /sys/kernel/config
    ;;
  restart)
    umount /sys/kernel/config
    mount -t configfs none /sys/kernel/config

    for dev in $ib/*;
    do
        mlnx=$(basename $dev)
        mkdir $base/$mlnx
        echo RoCE V2 > $base/$mlnx/default_roce_mode
        rmdir $base/$mlnx
    done
    ;;
  stop)
    umount /sys/kernel/config
    ;;
  status)
    echo -n "mlx4_core param : v"
    cat /sys/module/mlx4_core/parameters/roce_mode
    mount -t configfs none /sys/kernel/config

    for dev in $ib/*;
    do
        mlnx=$(basename $dev)
        echo -n "$mlnx: "
        mkdir -p $base/$mlnx
        cat $base/$mlnx/default_roce_mode
        rmdir $base/$mlnx
    done
    umount /sys/kernel/config
    ;;
  *)
    echo "Usage: /etc/init.d/roce.sh {start|stop|restart}"
    exit 2
    ;;
esac


exit 0
