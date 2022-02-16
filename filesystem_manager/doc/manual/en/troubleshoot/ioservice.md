# Diagnosing Service I/O

> When a failure is detected while using the CIFS and NFS service, follow the instructions below.

+ **Recommendations**
 
 Check on the general troubleshoots on whether the status of the network configuration or the device is normal.
 If the same symptom is not seen in other nodes, the problem might be dependent on the client environment.

## NFS: Input/Output error occurs when accessing specific files or directories

| Analysis     | Description   |
| ------        | -----  |
| Version     | All  |
| Symptom     | A message "Input/Output error" appears and unable to access when accessing to a specific file/directory from the volume mounted through NFS. |
| Cause     | The file might be affected by the split-brain status.<br> Split-brain is a status which causes an error on the system auto-recovery by metadata discord of the files between replicated nodes. |
| Solution     | Fix the split-brain issue using the mtime (modified time of a file) or source recovery referred in the guide below. |

1. Verify the issue
```
$ ls /mnt/nfs/test_file
ls: reading directory .: Input/output error
```
2. Access SSH or console of AnyStor-E device and proceed the following command to check the volume status. 

```
$ gluster volume heal {volume_name} info split-brain
Brick 10.10.59.65:/volume/{volume_name}
Status: Connected
Number of entries in split-brain: 0

Brick 10.10.59.66:/volume/{volume_name}
Status: Connected
Number of entries in split-brain: 0
```

3. Select a file at mtime and recover

```
$ gluster volume heal {volume_name} split-brain latest-mtime {file_path}
* {file_path} is a lower path of a mount path.
* For instance, if a mount path is set as '/mnt/volume/', to recover '/mnt/volume/a.file' you should enter '/a.file'.
```

4. Select a source file and recover

```
* When it is unable to recover at mtime, you can designate a node which has the original file for the recovery.
* To designate a node for the recovery, you must know the IP({storage_ip}) of each node.
* {storage_ip} is an IP address which designates each node in the cluster file system and can be confirmed using a command.
* You can use the hostname as a {storage_ip} from the example of a command below.

$ gluster pool list
UUID                                    Hostname        State
2856591b-a6e7-4479-9a68-77ba6d4ce497    10.10.59.67     Connected
71ceb5ec-a3cf-49d6-b1c6-be6a0aaf76e9    10.10.59.68     Connected
036d30f8-c6f3-481e-bddf-e284c270b3ab    10.10.59.66     Connected
2d4bf849-9da3-4b05-8dfc-4e22dabec37b    localhost       Connected

>+ **This recovery method will recover the file to the previous state.**
>+ &nbsp;&nbsp;&nbsp;&nbsp; As the file is recovered using the designated node, it is possible that the file might not be the one you are expecting.

* You can recover the file through designated node using the information such as {storage_ip}, {volume_name}, and {file_path} which were verified by the commands earlier.

$ gluster volume heal {volume_name} split-brain source-brick {storage_ip}:/volume/{volume_name} {file_path}
```

