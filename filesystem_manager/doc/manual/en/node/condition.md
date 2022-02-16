## 5.2 Node Status

### 5.2.1 About Node Status Menu

> AnyStor-E collects and abstracts system information of a selected node and displays the status and performance through **Node Status** menu.  
> **Node Status** menu presents the overall status of a selected node: the basic information of the node, the list of recent events that occurred in the node, the list of clients that are connected to the node, the usage and available capacity in a bar graph, and the performance statistics.  
> The node can be selected from the drop-down list on the top left corner of the **Node Status** page.  

### 5.2.2 Contents of Node Status Menu

#### 5.2.2.1 About Node Information List
* Located on the top left side of the page.
* Displays the hardware information, version of the cluster management software, and the composition status of the node.

#### 5.2.2.2 About Recent Event List
* Located on the top right side of the page.
* The events will be displayed in order by setting the most recent event on the top (in reverse chronological order).

#### 5.2.2.3 About Client Connection Status List
* Located on the middle center side of the page.
* Shows the list of clients connected to the node.

#### 5.2.2.4 About Node Usage Graph
* Located on the middle right side of the page.
* Shows the usage and available capacity of the node's cluster volume in a bar graph.

#### 5.2.2.5 About Performance Statistics
* Located on the bottom of the page.
* Shows the change of CPU usage, volume I/O, and service network I/O over time in a line graph.
* The time scale of the graph can be configured through the drop-down list located on the top right corner of the section.

### 5.2.3 Node Information List

#### 5.2.3.1 Contents of Node Information List
* The information is displayed in the manner of "{Key}:{Value}".
* **The information on the hardware includes the following items:**
  * A name, manufacturer, and model of the main board
  * A name, manufacturer, model, and performance of the CPU
  * The size of memory
* **The cluster management software version includes the following items:**
  * The released/committed version
  * The branch
  * The packaged date
* The list of compositions of the node includes the status of daemons and hardware which are needed for the node's management.

### 5.2.4 Recent Event List

#### 5.2.4.1 Contents of Event List
* Lists the event that recently occurred.
* The information on each event will be listed in each row.
* A single row includes the event's status, occurred time, description, range, and type.

|  Category  |  Description  |
|  :---:  |  :---  |
|  **Status**  |  Shows one of the three event level: Error, Warning, and Info.<br>The color of each level are shown as red, yellow, and green.  |
|  **Time**  |  Shows the time when the event occurred. Displayed as "yyyy/mm/dd  hh : mm : ss".  |
|  **Contents**  |  Describes the details of the event.  |
|  **Range**  |  View the location where the event occurred. It will show the ID(Hostname) of the node.  |
|  **Type**  |  Indicates which function the event is from and if the cause is not specified, it will show the text 'DEFAULT'.  |

#### 5.2.4.2 Sorting Events
* The default setting is to display in order by setting the recent event on the top (in reverse chronological order) but also can be modified by its needs.
* If you click the header at the top that lists column names, the data below will be sorted in alphabetical or chronological order depending on its content.

#### 5.2.4.3 Event Details
* Each event will show its details as you double-click.
* The details will be displayed in a form of a dictionary of key-value.
* Categories are ID, Scope, Level, Category, Message, Details, Time, and Quiet.

|  Category  |  Description  |
|  :---:  |  :---  |
|  **ID**  |  The identifier of the event. |
|  **Scope**  |  View the location where the event occurred. It will show the ID(Hostname) of the node. |
|  **Level**  |  Shows one of the three event level: Error, Warning, and Info.  |
|  **Category**  |  Indicates which function the event is from and if the cause is not specified, it will show the text 'DEFAULT'.  |
|  **Message**  |  The text describing the content of the event.  |
|  **Details**  |  Displays more information on the event than Message. It is shown in a form of a dictionary of key-value.  |
|  **Time**  |  Shows when the event occurred. Displayed as "yyyy/mm/dd hh : mm : ss".  |
|  **Quiet**  |  If the value is not 0, it will be displayed as an event but will not be informed by email.  |


### 5.2.5 Client Connection Status List

#### 5.2.5.1 Contents of Client Connection Status List
* View the list of clients connected to the node.
* The information on each client will be displayed in each row.
* It will relate the client's network(IP) address with the client's type.
* The client's type will show which protocol (NFS or CIFS) the client is approaching with.

### 5.2.6 Cluster Usage Graph
* Displays the usage and available space of each cluster volume in a bar graph.
* Each bar graph indicates each existing cluster volume.
* When there is no cluster volume to show, it will display a message "There is no data for the cluster usage.".

### 5.2.7 Performance Statistics

#### 5.2.7.1 Contents of Performance Statistics
* Generates the progress of CPU usage, volume, and network I/O of the entire node in a line graph.
* The chronological range can be selected between 1 Hour, 1 Day, 1 Week, 1 Month, 6 Months, and 1 Year.
* In case of 1 Hour and 1 Day, the statistics will be refreshed every 10 seconds.
* There are three graphs, Node CPU, Node Disk I/O, and Node Service Network I/O.

#### 5.2.7.2 Node CPU Graph
* Displays the overall CPU usage of the node.
* Each CPU statistics will display its graph in different colors.
* Type of CPU statistics are the system, user, iowait, irq, softirq, and nice.

|  Name  |  Description  |
|  :---:  |  :---  |
|  **system(Green)**  |  CPU spent running the kernel  |
|  **user(Yellow)**  |  CPU spent running user processes that have been un-niced  |
|  **iowait(Light blue)**  |  CPU spent while the process is waiting for the data I/O to finish  |
|  **irq(Orange)**  |  CPU spent processing the interrupt request from the hardware  |
|  **softirq(Red)**  |  CPU spent processing the interrupt request from the software  |
|  **nice(Blue)**  |  CPU spent running user processes that have been niced  |

#### 5.2.7.3 Node Disk I/O Graph
* Displays the sum of all data I/O of every cluster sub-volume existing in the node.
* The graph will display read (green) and write (yellow) of the disks.

#### 5.2.7.4 Node Service Network I/O Graph
* **Displays the sum of network data going through service network interface of the node.**
  * Service network interface: An interface to proceed NFS/CIFS service.
* The graph will display send (yellow) and receive (green) of a network.
