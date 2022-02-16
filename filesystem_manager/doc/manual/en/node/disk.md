## 5.3 Configuring Disks

### 5.3.1 About Disk Settings Menu

Disk Settings menu provides the management on the block device(disk) of each node.

### 5.3.2 Technical Factors

#### 5.3.2.1 Block device

#### 5.3.2.2 NVMe

#### 5.3.2.3 Multipath

### 5.3.3 Description and Configuration

#### 5.3.3.1 Block Device List

Shows the list of block devices and their details.

<div class="notices yellow element normal">
    <ul>
        <li>Some information that is dependent on the hardware or does not exist in our hardware database may cause not shown properly.</li>
    </ul>
</div>

| **Category** | **Description** |
| :---: | :--- |
| **Name** | The name of the block device. |
| **Serial** | The serial number of the block device that is assigned by the manufacturer. |
| **Vendor** | The manufacturer of the block device. |
| **Product** | The model name of the block device. |
| **Type** | The type of the block device. <ul><li>**hdd**: General Hard disk drive</li><li>**ssd**: Solid state drive</li><li>**nvme**: NVMe drive</li><li>**multipath**: Multipath drive</li></ul> |
| **Interface** | The interface type of the block device connected with this system. <ul><li>**ATA/SATA**</li><li>**SAS**</li><li>**FC/FCoE**</li><li>**NVMe**</li></ul> |
| **Size** | The size of the block device. |
| **Preserved** | If the block device is using for system internal purpose or it has a LVM logical volume for that, this field shows `OS` |
| **Status** | This field shows `In use` if the block divice is mounted or it is being used as a LVM physical volume, `Not in use` otherwise. |
| **Mount** | All mount points associated with the block device. |

