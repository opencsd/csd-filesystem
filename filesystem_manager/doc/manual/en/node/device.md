## 5.8 Network Device

### 5.8.1 About Network Device Menu

> The menu presents the status of network devices of the cluster node, along with the option of modifying their status.

+ **Limitations on the activation and deactivation of service and storage network device**

    Service and storage network device cannot be deactivated.

---

+ **Limitations on the modification of network device status**

    The network device that is used in bonding cannot be modified individually.    
    If the status of the bonding is modified, all the network devices that are in the bond will also be modified.   


### 5.8.2 Contents of Network Device Menu

#### 5.8.2.1 About Network Device Page
* The page is located all across the screen.
* Generates a list of network devices.
* Each network device from the list includes information such as its name, description, MAC address, connection speed, MTU, activation, connection status, IP address allocation method, and the information on network bonding.
* Network device list reflects the system's status.

### 5.8.3 Network Device Page

#### 5.8.3.1 Contents of Network Device Page

|  Category  |  Description  |
|  :---:  |  :---  |
| **Name** | View the name of a network device. |
| **Description** | View the model name of a network device.<br>As bonding device is a virtual hardware, it will be displayed as "Unknown". |
| **MAC Address** | View the MAC address of a network device. |
| **Connection Speed** | View the connection speed of a network device.<br>If the network device is not enabled, it will not be displayed on the list. |
| **MTU** | View the MTU (Maximum Transmission Unit) of a network device.<br>MTU is the maximum size of data that can be sent by a network device. |
| **Active** | View whether the network device is enabled or disabled.<br>If there is a difference in activation and connection status, the task on the issue will be triggered on the **Event** page. |
| **Connection Status** | View the connection status of the network device. |
| **Allocation Method** | View whether the allocation method of IP address is through DHCP or STATIC. |
| **Bonding Information** | View the network bonding name which the network device belongs to.<br>If the device belongs to nowhere, it will be displaying a blank. |


#### 5.8.3.2 Details on Network Devices

* Select a network device and press **Show Details** button to check the detailed information on the device.
* The pop-up screen will show several charts on the network device.
* It includes the chart on the basic information on the network device, network device address, and received and transmitted data on the network device.

##### 5.8.3.2.1 Network Device Chart
* Shows the basic information on the network device.
* It shows the device's name, traffic update time, last update time, MAC address, connection speed, MTU, activation, and connection status.

|  Category  |  Description  |
|  :---:  |  :---  |
| **Device** | View the name of a network device. |
| **MAC Address** | View the MAC address of a network device.  |
| **Speed** | View the connection speed of a network device.<br>If the network device is not enabled, it will not be displayed on the list. |
| **MTU** | View the MTU (Maximum Transmission Unit) of a network device.<br>MTU is the maximum size of data that can be sent by a network device. |
| **Active** | View whether the network device is enabled or disabled.<br>If there is a difference in activation and connection status, the task on the issue will be triggered on the **Event** page. |
| **Status** | View the connection status of the network device. |

##### 5.8.3.2.2 Network Device Address Chart
* Shows the IP address allocated to the device.
* If the device has no IP address allocated, it will show a blank.
* It shows the device's IP address, subnet mask, gateway, and connection status.

|  Category  |  Description  |
|  :---:  |  :---  |
| **IP Address** | View the IP address allocated to the device. |
| **Subnet Mask** | View the IP's subnet mask.<br>It will be displayed in the form of "xx.xx.xx.xx [xx]". |
| **Gateway** | View the IP's gateway.<br>If the gateway is not configured, the content will be empty. |
| **Connection Status** | View the connection status of the network device. |

##### 5.8.3.2.3 Network Receive (Rx) Chart
* Shows the statistics on the data being received by the device.
* Displayed information are bytes, packets, dropped, and errors.

|  Category  |  Description  |
|  :---:  |  :---  |
| **bytes** | View the total size of data received by the device. |
| **packets** |  View the total number of packets received by the device. |
| **dropped** | View the number of packets that were failed to reach the device. |
| **errors** | View the number of packets that had errors during the process after receiving them. |

##### 5.8.3.2.4 Network Transmit (Tx) Chart
* Shows the statistics on the data being transmitted from the device.
* Displayed information are bytes, packets, dropped, and errors.

|  Category  |  Description  |
|  :---:  |  :---  |
| **bytes** | View the total size of data transmitted from the device. |
| **packets** | View the total number of packets transmitted from the device. |
| **dropped** | View the number of packets that were failed to transmit from the device. |
| **errors** | View the number of packets that had errors during the process when transmitting them. |


#### 5.8.3.3 Modifying Network Device
> You will be able to change its active status and MTU (Maximum Transmission Unit).  

* **[Network Device Name]**
  * The name of the network device you have selected.
  * The device name cannot be changed.
* **[Enable]**
  * Activates the network device.
  * If the option is enabled, the network device will be activated.
  * If the option is disabled, the network device will be deactivated.
* **[MTU]**
  * Changes the MTU of the network device.
  * You can enter the number to change the MTU.
