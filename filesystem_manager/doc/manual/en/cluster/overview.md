## 1.2 Overview

> Overview page shows the overall status of the cluster through collecting and summarizing every information from the entire node.  
> In this section, it features the list of node status, usage and available space of cluster volume, client access status, and the list of the recent event.  

| Category              | Location        | Description              |
| :---                | ----        | :------           |
| Cluster Status       | Top left   | Shows the status of the entire cluster. |
| Node Status         | Top left   | Summarizes the status of each node, resource usage, and the performance. |
| Client Connection Status | Middle left   | Shows the number of clients of each node and I/O status graph. |
| Recent Events         | Bottom left   | Displays recently occurred events. |
| Cluster Usage     | Top Right | Displays the usage and available space of each cluster volume in a bar graph. |
| Performance Statistics           | Bottom Right | Shows a graph on CPU, network, and disk I/O usage of a cluster. |

+ **Tip**

    Check the status light of **Cluster Status**. If it is not green, look for its cause from the event page or the task page.   
    Check **Cluster Usage**. If the volume usage exceeds 95%, performance might fall.     
    Check **Cluster CPU**. If it exceeds 75%, the resource needs to be checked.    


### 1.2.1 Node Status Table

 *  About Node Status Table
  * The information on the node will be described in a single row.
  * There is a status bar showing a status light and a status message on the top of the table.
  * A single row shows the node status, network speed, storage speed, and disk status of a node.
  * The bottom row of the table shows the sum of network and storage speed and disk usage of all node.

 * Cluster Status
  * The status light and status message on the cluster will be displayed.
  * **The status light will display the color red, yellow, and green which indicates the status Error, Warning, and OK of the cluster.**
   * When an error occurs among the nodes, the cluster status will show the word Error. When there is a node in a Warning status and no error, the cluster status will show as Warning.
   * When neither of the nodes has Error or Warning status, the cluster status will show as OK.
  * The status message will display the cause of Error or Warning status.

 * Node Status
  * From this menu, it will display the node's status, ID, management IP, and service IP.

    | Category           |  Description  |
    | :---:          |  :---  |
    | **Status**       |  Displays a node's condition<br>The menu will be composed of status light and stage value of a node.<br> The status light will display the color red, yellow, and green which indicates the status Error, Warning, and OK of the cluster.<br>Stage value is a value marking the current node for the user's convenience. For more information, refer to [1.3.5.2 Node Stage](#cluster.xhtml#1.3.5.2 Node Stage).  |
    | **ID**         |  Unique ID of a node  |
    | **Management IP**    | IP for the management which will be statically allocated to the node.  |
    | **Service IP**  |  Allocated IP for the service<br>Service IP is allocated from one of the IPs from service IP pool on the **Service IP Settings** tab located on the Cluster Management > Network Settings page<br>and will be dynamically distributed depending on the node's condition.<br>Therefore, if the client is connected through service IP, it automatically connects to another available node in the cluster when the system failure occurs.<br>Service IP may exist more than one per node or none.  |

 *  Network Speed
  * Network speed is displayed in input speed and output speed.
  * Network speed refers to the amount of network data processed by the node per second.

    |  Category  |  Description  |
    |  :---:  |  :---  |
    |  **Input Speed**  |  The speed of data entering the cluster node's network.  |
    |  **Output Speed**  |  The speed of data going out from the cluster node's network.  |

 * Storage Speed
  * Storage speed is displayed in input speed and output speed.
  * Storage speed refers to the amount of data going in and out of the storage device per second.
  * A sub volume, which consists the cluster volume, will be a target to measure data I/O speed.

    |  Category  |  Description  |
    |  :---:  |  :---  |
    |  **Input Speed**  |  The speed of data entering the cluster node's storage device.  |
    |  **Output Speed**  |  The speed of data going out from the cluster node's storage device.  |

 * Disk
  * This part displays disk pool usage, overall space, and the usage in a percentage from each node.

    |  Category  |  Description  |
    |  :---:  |  :---  |
    |  **Usage**  |  Amount of space allocated to compose the cluster volume from the disk pool of a node  |
    |  **Usage (%)**  |  Percentage of space allocated to compose the cluster volume from the disk pool of a node  |
    |  **Total Space**  |  Overall space of disk pool of a node  |

### 1.2.2 Client Connection Status Graph

 * About Client Connection Status Graph
  * Displays a graph (blue) showing the number of clients connected to the node and another graph (orange) showing the service performance.

 * Client
  * Shows the number of a client connected to each node in a blue bar graph.
  * The criterion of the graph will be displayed on the left.
  * The client connection will imply that the cluster volume has been mounted through NFS or CIFS network file system service.
  * NFS and CIFS are shown as an identical connection.
  * When the cluster volume is mounted from an external node, the value of a node operated with NFS or CIFS server used by the client will increase.

 * Performance Graph
  * Shows the service performance of each node in an orange bar graph.
  * The criterion of the graph will be displayed on the right.
  * The service performance will be measured by consolidating the sum of I/O per criteria between client and server of each node.

### 1.2.3 Recent Events

 * About Recent Events
  * Generates recently occurred events.
  * Information on each event will be shown in a single row.
  * Each row shows the status, occurred time, description, device name, and type of the event.

    |  Category  |  Description  |
    |  :---:  |  :---  |
    |  **Status**  |  One of the three event level, Error, Warning, and Info will appear<br>and each level is shown as red, yellow, and green light.  |
    |  **Time**  |  Shows when the event occurred. Displayed as "yyyy/mm/dd  hh : mm : ss".  |
    |  **Contents**  |  Describes the details of the event.  |
    |  **Device**  |  Shows the name of the device where the event occurred. If it occurs in a specific node, it shows the node ID, and if it is from the entire node of the cluster, it shows the text 'cluster'.  |
    |  **Type**  |  Indicates which function the event is from and if the cause is not specified, it will show the text 'DEFAULT'.  |

 * Sorting Events
  * The default setting is to display in order by setting the recent event on the top (in reverse chronological order) but also can be modified by its needs.
  * If you click the header at the top that lists column names, the data below will be sorted in alphabetical or chronological order depending on its content.

 * Event Details
  * Each event will show its details as you select.
  * The details will be displayed in a form of a dictionary of key-value.
  * Categories are ID, Scope, Level, Category, Message, Details, Time, and Quiet.

    |  Category  |  Description  |
    |  :---:  |  :---  |
    |  **ID**  |  The identifier of the event.  |
    |  **Scope**  |  View the location where the event occurred. When it happened in a node, it will show the node ID and if it is the cluster, it will show the text, "cluster".  |
    |  **Level**  |  Shows one of the three event level: Error, Warning, and Info.  |
    |  **Category**  |  Indicates which function the event is from and if the cause is not specified, it will show the text 'DEFAULT'.  |
    |  **Message**  |  The text describing the content of the event.  |
    |  **Details**  |  Displays more information on the event than Message. It is shown in a form of a dictionary of key-value.  |
    |  **Time**  |  Shows when the event occurred. Displayed as "yyyy/mm/dd  hh : mm : ss".  |
    |  **Quiet**  |  If the value is not 0, it will be displayed as an event but will not be informed by email.  |

### 1.2.4 Cluster Usage Graph
* Displays the usage and available space of each cluster volume in a bar graph.
* Each bar graph indicates each existing cluster volume.
* When there is no cluster volume to show, it will display a message "There is no data for the cluster usage.".

### 1.2.5 Performance Statistics

 * About Performance Statistics
  * Generates the progress of CPU usage, volume, and network I/O of the entire cluster in a line graph.
  * The chronological range can be selected between 1 Hour, 1 Day, 1 Week, 1 Month, 6 Months, and 1 Year.
  * In case of 1 Hour and 1 Day, the statistics will be refreshed every 10 seconds.
  * There are three graphs, Cluster CPU, Cluster Disk I/O, and Cluster Service Network I/O.

 * Cluster CPU Graph
  * Displays the CPU usage of the nodes in the cluster.
  * Each CPU statistics will display its graph in different colors.
  * Types of CPU statistics are the system, user, iowait, irq, softirq, and nice.

    |  Name  |  Description  |
    |  :---:  |  :---  |
    |  **system(Green)**  |  CPU spent running the kernel  |
    |  **user(Yellow)**  |  CPU spent running user processes that have been un-niced  |
    |  **iowait(Light blue)**  |  CPU spent while the process is waiting for the data I/O to finish  |
    |  **irq(Orange)**  |  CPU spent processing the interrupt request from the hardware  |
    |  **softirq(Red)**  |  CPU spent processing the interrupt request from the software  |
    |  **nice(Blue)**  |  CPU spent running user processes that have been niced  |

 * Cluster Disk I/O Graph
  * Displays the sum of all data I/O of every cluster volume existing in the cluster.
  * The graph will display read (green) and write (yellow) of the disks.

 * Cluster Service Network I/O Graph
  * **Displays the sum of network data going through service network interface of every node from the cluster.**
   * Service network interface is a network that can mount storages through NFS/CIFS protocols.
  * The graph will display send (yellow) and receive (green) of a network.
