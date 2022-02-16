## 5.7 Network Bonding

### 5.7.1 About Network Bonding Menu
> You can verify the network bonding status of the cluster node along with creation, modification, and deletion options.

- **Limitations on the activation and deactivation of service and storage network device**

    Service and storage network device cannot be deactivated.

---

- **Limitations on the modification of network device status**

    The network device that is used in bonding cannot be modified individually.    
    If the status of the bond is modified, all the network devices that are in the bond will also be modified.    


### 5.7.2 Contents of Network Bonding Menu

* Generates a list of network bonding.
* Network bonding list reflects the operating system's status of the storage.


### 5.7.3 Bonding Information Page

#### 5.7.3.1 Contents of Bonding Information Page

|  Category  |  Description  |
|  :---:  |  :---  |
| **Name** | View the name of a bond. |
| **MAC Address** | View the MAC address of a bond. |
| **Physical Device** | View the slave network device of a bond. |
| **PrimarySlave** | View the primary slave network device of a bond.<br>If the primary slave is not present, it will show a blank.<br>The slave network device, which is designated as the primary slave, has a high possibility of being utilized as a network device which the bond uses as the main communication device. |
| **ActiveSlave** | View the slave network device in active slave state.<br>If the active slave is not present, it will show a blank. |
| **Active** | View whether the network bonding is enabled or disabled.<br>If there is a difference in activation and connection status, the task on the issue will be triggered on the **Event** page. |
| **Connection Status** | View the connection status of the network device. |

#### 5.7.3.2 Details on Physical Devices
* Select a network bonding from the list and press **Device Details** button to verify the details on the physical device that is used on the bond.
* The pop-up screen will inform the name of the of the device and its MAC address.

#### 5.7.3.3 Creating Network Bonding
> Go to **Bonding Information** page and press **Create** button to create a network bonding.

##### 5.7.3.3.1 Choosing Bonding Mode
* **[Round-Robin]**
  * Sequentially sends the data to the network device. Provides load balancing and fault tolerance.
  * Mode number: 0
* **[Active Backup]**
  * Activates only one device. Other devices will be activated when the issue occurs on the currently activated device.
  * Mode number: 1
* **[Balance-XOR]**
  * Selects a device which transmit packets using XOR operation.
  * Mode number: 2
* **[IEEE 802.3ad]**
  * A bond supporting EtherChannel or LACP(Link Aggregation Control Protocol). Requires a network device (switch) for the support.
  * Mode number: 4
* **[Balance-tlb]**
  * The load balancing is configured only in the transmitted packets. Received packets will only be sent to the activated devices.
  * Mode number: 5
* **[Balance-alb]**
  * The load balancing is configured in both transmitted and received packets. It is sent to the bonding device that has less traffic.
  * Mode number: 6

##### 5.7.3.3.2 Selecting Network Device for Bonding
* **[Enable]**
  * Activates the network bonding.
  * If the option is enabled, the network bonding and the slave device will be activated.
  * If the option is disabled, the network bonding and the slave device will be deactivated.
* **[Primary Slave]**
  * Select a device from one of the slave network devices which will be used as a primary slave from the drop-down list.
* **[Available Network Device(s)]**
  * View the list of network devices that can be composed of a network bonding.
  * Only shows the network devices that are not currently used as a network bonding.
  * The selected network device will be designated as a slave.

#### 5.7.3.4 Modifying Network Bonding
> Select a bond from **Bonding Information** page and press **Modify** button to modify the network bonding.

##### 5.7.3.4.1 Choosing Bonding Mode
* **[Round-Robin]**
  * Sequentially sends the data to the network device. Provides load balancing and fault tolerance.
  * Mode number: 0
* **[Active Backup]**
  * Activates only one device. Other devices will be activated when the issue occurs on the currently activated device.
  * Mode number: 1
* **[Balance-XOR]**
  * Selects a device which transmit packets using XOR operation.
  * Mode number: 2
* **[IEEE 802.3ad]**
  * A bond supporting EtherChannel or LACP(Link Aggregation Control Protocol). Requires a network device (switch) for the support.
  * Mode number: 4
* **[Balance-tlb]**
  * The load balancing is configured only in the transmitted packets. Received packets will only be sent to the activated devices.
  * Mode number: 5
* **[Balance-alb]**
  * The load balancing is configured in both transmitted and received packets. It is sent to the bonding device that has less traffic.
  * Mode number: 6

##### 5.7.3.4.2 Selecting Network Device for Bonding
* **[Enable]**
  * Activates the network bonding.
  * If the option is enabled, the network bonding and the slave device will be activated.
  * If the option is disabled, the network bonding and the slave device will be deactivated.
* **[Primary Slave]**
  * Select a device from one of the slave network devices which will be used as a primary slave from the drop-down list.
* **[Available Network Device(s)]**
  * View the list of network devices that can be composed of a network bonding.
  * Only shows the network devices that are not currently used as a network bonding.
  * The selected network device will be designated as a slave.


#### 5.7.3.5 Deleting Network Bonding
> Select one or more bond from **Bonding Information** page, and press **Delete** button to delete the network bonding.
