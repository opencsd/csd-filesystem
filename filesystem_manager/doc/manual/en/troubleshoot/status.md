#  Troubleshooting via Status and Stage 

* Follow the instructions according to the status of a cluster, stage, and node.
* You may fix the issue according to each status and stage by following the instructions in "[Troubleshooting via Event]".

## If a cluster status is 'Manage: UNHEALTHY' 

### System Environment

|Item            | Description    |
| ------         | -----  |
| **AnyStor-E Version** | 2.0.6.3 or above |
| **OS** | CentOS 6.9 or above |
| **GlusterFS Version** | 3.10.7 or above |

#### Cause of Issue

* It occurs when some of the components for the cluster management are in abnormal status.

#### Verify the Issue

* Check "[1.2.2.1 Node Status Table](#cluster.xhtml#1.2.1 Node Status Table)" to verify the node with the issue.
* Go to Node Management page and check the component status of the node which was mentioned in "[5.2.2.1 About Node Information List](#node.xhtml#5.2.2.1 About Node Information List)".
* The status of a component will be displayed as 'Status (xxxx)'. If the status is not shown as 'OK', go to **Event** page mentioned at "[1.4 Event](#cluster.xhtml#1.4 Events)" whether there is an event related to the component.

#### Solution

* Please refer to "[Troubleshooting via Event]".

## If the cluster status is 'Service: DEGRADED'

### System Environment

|Item            | Description    |
| ------         | -----  |
| **AnyStor-E Version** | 2.0.6.3 or above |
| **OS** | CentOS 6.9 or above |
| **GlusterFS Version** | 3.10.7 or above |

### Cause of Issue

* It occurs when the component for I/O service is in abnormal status in some nodes.

### Verify the Issue

* Check "[1.2.2.1 Node Status Table](#cluster.xhtml#1.2.1 Node Status Table)" to verify the node with the issue.
* Go to Node Management page and check the component status of the node which was mentioned in "[5.2.2.1 About Node Information List](#node.xhtml#5.2.2.1 About Node Information List)".

### Solution

* 


