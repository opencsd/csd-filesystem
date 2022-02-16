## 5.9 Network Address

### 5.9.1 About Network Address Menu
> You can check the list of network address status of the cluster node along with creation, modification, and deletion options.

- **Limitations on storage network address modification and deletion**
    
    You cannot modify or delete the storage network address.

---

- **Limitations on modification and deletion of addresses in service address pool**
    
    The network addresses included in the service address pool are configured internally in the cluster management software     
    and are automatically allocated to each node. Although it can be browsed by users, it cannot be modified or deleted.    
    For more information on the service address pool, please refer to "[1.5.1 Service IP Settings](#cluster.xhtml#1.5.1 Service IP Settings)".  


### 5.9.2 Contents of Network Address Menu

* The page is located all across the screen.
* Displays the list of network addresses and their details.
* The details are IP address, subnet mask, gateway, IP address allocation method, device name, activation, and connection status.
* Network address list reflects the system's status.


### 5.9.3 Network Address Information Page

#### 5.9.3.1 Contents of Network Address Information Page

|  Category  |  Description  |
|  :---:  |  :---  |
| **IP Address** | View the network address allocated to the cluster node. |
| **Subnet Mask** | View the subnet mask of the network address.<br>A subnet mask indicates which part is the network identifier and which part is host identifier. |
| **Gateway** | View the gateway of the network address.<br>If the gateway is not configured, the content will be empty. |
| **Allocation Method** | View whether the allocation method of IP address is through DHCP or STATIC. |
| **Device** | View the network device where the network address is allocated. |
| **Active** | View whether the network device is enabled or disabled. |
| **Connection Status** | View the connection status of the network device. |

#### 5.9.3.2 Creating Network Address
> Press **Create** button from **Network Address Information** page to create a new network address.

##### 5.9.3.2.1 Entering Network Address Information
* **[Device Name]**
  * Select a network device from the drop-down list to allocate network address.
  * It will only display the device with no assigned address or composed as a network bond.
* **[Enable]**
  * Activates the network device.
  * If the option is enabled, the network device will be activated.
  * If the option is disabled, the network device will be deactivated.
* **[IP Address]**
  * Fill in a new IP address to allocate.
* **[Subnet Mask]**
  * Fill in a new subnet mask of the address to allocate.
  * A subnet mask will be in a form of "xx.xx.xx.xx", and each subset will be a number between 0 to 255.
* **[Gateway]**
  * Fill in a new gateway address to allocate.
  * If the value is not entered, it will not configure a gateway for this address.

#### 5.9.3.3 Modifying Network Address
> Select an address from the list and press **Modify** button to modify the information in the network address.

##### 5.9.3.3.1 Changing Network Address Information
* **[Device Name]**
  * The name of the network device where the network address is allocated.
  * The device cannot be modified.
* **[Enable]**
  * Activates the network device.
  * If the option is enabled, the network device will be activated.
  * If the option is disabled, the network device will be deactivated.
* **[IP Address]**
  * Fill in the IP address to allocate if need to be changed.
* **[Subnet Mask]**
  * Fill in the subnet mask of the address to allocate if need to be changed.
  * A subnet mask will be in a form of "xx.xx.xx.xx", and each subset will be a number between 0 to 255.
* **[Gateway]**
  * Fill in the gateway address to allocate if need to be changed.
  * If the value is not entered, it will not configure a gateway for this address.

#### 5.9.3.4 Deleting Network Address
> Select one or more address from **Network Address Information** page, and press **Delete** button to delete the network address.
