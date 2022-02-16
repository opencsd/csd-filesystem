## General Troubleshooting Tips 

> These are the common checklists when there is a problem with NFS/CIFS service or cluster management.  
> Most of the hardware failures can be detected and notified by AnyStor-E management software. If it is not detected, please refer to **Checking your Hardware Configuration** below.

## 1. Checking your Network Configuration
> There are various possible causes of access issues on AnyStor-E cluster manager or the malfunction of I/O on the client.  
> This section goes through the basic configurations on AnyStor-E network environment.

* Network Status Checklist

| Item            | Method (CLI)              |  Description          |
| :----------:        | :----------:           | :----------:    |
| Cluster ping  | 'ping {IP address}'            | Do a ping test on the cluster management IP or service IP from the client you are currently using.   |
| Cluster port  | 'nmap {IP address}' or 'telnet (IP address)'  | Verify whether the cluster port (management:80, NFS:2049,111,38465, CIFS:139,445) is available in firewall. |


## 2. Checking your Software Configuration
> To check your cluster's status, you can verify it from "[1.2 Overview](#cluster.xhtml#1.2 Overview)", and for the details on each node, please check "[5.2.3 Node Information List](#node.xhtml#5.2.3 Node Information List)".

* Status Checklist through Cluster Manager

| Item           | Method                           |  Description          |
| :----------:       | :----------:                        | :----------:    |
| Cluster overview | Cluster Management >> Overview >> Node Status  | If there is a warning or error on the hardware and software of the entire cluster or a node, the status field value will be changed. For the related issue, check **Dashboard Monitoring** section of this manual. |
| Cluster node status | Node Management >> Node Status             | Verify the type and status of the resources you wish to monitor. |
| Task     | Cluster Management >> Event >> Task    | Check the tasks that require notification or problem solving on the hardware and software resources of the cluster. |

## 3. Checking your Hardware Configuration
> There are several ways to check your hardware depending on its manufacturer or model and this manual presents its basic description. For more information, refer to the manual of the **hardware manufacturer**.  
> It may help to check the system event which is unidentified from the status check by the cluster manager.

* Hardware Notification Check (LED and alarm)

| Item        | Method                      |  Description          |
| :----------:    | :----------:                   | :----------:    |
| NIC LED    | Check NIC LED             | If the LED is turned off or denied by the switch, you should suspect an error on the card or the switch port. |
| Disk LED        | Check disk LED            | If the LED turns red, it means that there is a possible disk failure. In case there is no RAID composed, it will fail to access its file system. |
| RAID Controller | Check beep sound or the message when the system starts | RAID Controller will make a beep sound when an error occurs. |
| System LED      | Check LED on the front system panel | When the status of the hardware, such as CPU, mainboard, voltage, and fan are not normal, the LED will turn red which indicates the system failure. |

* Internal System Check (SSH/Console)

| Item        | Method (CLI)                      |  Description          |
| :----------:    | :----------:                   | :----------:    |
| IPMI sensor data| ipmitool                  | Check the hardware status using the IPMI command line to find the hardware error. |
| MCE log          | mcelog                         | Check the MCEs (Machine Check Event) reported by x86 CPU to investigate the system error. You may be able to find the cause of an instant system restart or shutdown. |
| RAID Controller | Check beep sound or the message when the system starts | RAID Controller will make a beep sound when an error occurs. |
| System LED      | Check LED on the front system panel | When the status of the hardware, such as CPU, mainboard, voltage, and fan are not normal, the LED will turn red which indicates the system failure. |




