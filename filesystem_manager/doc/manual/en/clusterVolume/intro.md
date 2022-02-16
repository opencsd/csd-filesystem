# 2 Cluster Volume Management

**AnyStor-E Volume Architecture**
> To configure the performance and stability of storage services, AnyStor-E embedded Linux Logical Volume Manager and RedHat **GlusterFS** file system.     
> Volume pool is used by managing the local LVM space of the cluster node through the cluster and volumes will be managed by virtual cluster volumes using GlusterFS volumes.    
>     
> You can configure **thin provisioned and tiered volume including the snapshot**, and **network RAID volumes** to increase the storage utilization when performing a backup or archiving.   

| Menu                      | Description                                                               |
| ------------              | ----------------                                                   |
| **Volume Pool**          | For the management on physical volume, volume group, and logical volume of LVM across nodes.<br>It should be created and configured before using **Volume** menu.|
| **Volume**             | For creating, deleting, and expanding the cluster volume using the logical volume from volume pool of each node.<br>It has additional features such as snapshot and tiering.|                                                                
| **Snapshot Scheduling**  | For setting and deleting schedules which periodically creates snapshots of the cluster volume.                                                                     |
