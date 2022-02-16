## 5.4 Configuring Volumes

### 5.4.1 About Volume Settings Menu

The **Volume Settings** menu provides LVM logical volume management for each nodes.

You can see three grids which manage LVM components like below that

1. [Physical Volume List](#node.xhtml#5.4.3.1 Physical Volume List) that can manage LVM physical volumes.
1. [Volume Group List](#node.xhtml#5.4.3.2 Volume Group List) that can manage LVM volume groups.
1. [Logical Volume List](#node.xhtml#5.4.3.3 Logical Volume List) that can manage LVM logical volumes.

### 5.4.2 Technical Factors

#### 5.4.2.1 LVM(Logical Volume Manager)

The volume configuration of the node internally uses LVM.

Please refer to [2.1.1 About LVM](#clusterVolume.xhtml#2.1.1 About LVM))

#### 5.4.3 Description and Configuration

#### 5.4.3.1 Physical Volume List

Presents the list of physical volumes which are located in the selected node and their details.

<div class="notices yellow element normal">
    <ul>
        <li>Some information that is dependent on the hardware or does not exist in our hardware database may cause not shown properly.</li>
    </ul>
</div>

| **Category** | **Description** |
| :---: | :--- |
| **Name** | The name of a physical volume. |
| **SCSI ID** | The SCSI identifier for a physical volume.<br/>This ID is assigned by a system automatically. |
| **Vendor** | The manufacturer of a physical volume.<br/>It depends on underlying block device. |
| **Product** | The product name of a physical volume.<br/>It depends on underlying block device. |
| **Size** | The size of a physical volume. |
| **Volume Group Name** | The volume group name which using a physical volume. |

##### 5.4.3.1.1 Creating Physical Volume

Press **Create** button from [5.4.3.1 Physical Volume List](#node.xhtml#5.4.3.1 Physical Volume List) to create a physical volume.

##### 5.4.3.1.2 Deleting Physical Volume

Press **Delete** button from [5.4.3.1 Physical Volume List](#node.xhtml#5.4.3.1 Physical Volume List) to delete the selected physical volume.

#### 5.4.3.2 Volume Group List

Presents the list of volume groups which are located in the selected node and their details.

| **Category** | **Description** |
| :---: | :--- |
| **Name** | The name of a volume group. |
| **Size** | The size of a volume group. |
| **Usage** | The current usage of a volume group. |
| **Usage(%)** | The current usage of a volume group in percentage. |

#### 5.4.3.2.1 Creating Volume Group

Press **Create** button from [5.4.3.2 Volume Group List](#node.xhtml#5.4.3.2 Volume Group List) to create a volume group.

<div class="notices blue element normal">
    <ul>
        <li>Unused physical volumes are needed to create a volume group. You can create a physical volume with reference to "<a href="node.xhtml#5.4.3.1.1 Creating Physical Volume">5.4.3.1.1 Creating Physical Volume</a>"</li>
    </ul>
</div>

| **Category**| **Description** |
| :---: | :--- |
| **Name** | Enter a new logical volume name. Enter 4 ~ 20 alphanumeric letters starting with an alphabet.<br/>As for symbols, only `"-"` and `"_"` are allowed. |
| **Physical volume list** | The physical volumes can be used to create a volume group.<br/><ul><li>**Name** - The name of a physical volume.</li><li>**Size** - The size of a physical volume.</li></ul> |

#### 5.4.3.2.2 Extending Volume Group

Press **Extend** button from [5.4.3.2 Volume Group List](#node.xhtml#5.4.3.2 Volume Group List) to extend selected volume group.

<div class="notices blue element normal">
    <ul>
        <li>Unused physical volumes are needed to extend a volume group. You can create a physical volume with reference to "<a href="node.xhtml#5.4.3.1.1 Creating Physical Volume">5.4.3.1.1 Creating Physical Volume</a>"</li>
    </ul>
</div>

| **Category** | **Description** |
| :---: | :--- |
| **Name** | The name of a volume group to extend. |
| **Physical volume list** | The physical volumes can be used to extend selected volume group.<br/><ul><li>**Name** - The name of a physical volume.</li><li>**Size** - The size of a physical volume.</li></ul> |

#### 5.4.3.2.3 Reducing Volume Group

Press **Reduce** button from [5.4.3.2 Volume Group List](#node.xhtml#5.4.3.2 Volume Group List) to reduce selected volume group.

<div class="notices blue element normal">
    <ul>
        <li>Physical volumes not allocated for logical volumes can only be reduced.</li>
    </ul>
</div>

| **Category** | **Description** |
| :---: | :--- |
| **Name** | The name of a volume group to reduce. |
| **Physical volume list** | The physical volumes being used for a volume group.<br/><ul><li>**Name** - The name of a physical volume.</li><li>**Size** - The size of a physical volume.</li></ul> |

#### 5.4.3.2.4 Deleting Volume Group

Press **Delete** button from [5.4.3.2 Volume Group List](#node.xhtml#5.4.3.2 Volume Group List) to delete the selected volume group.

#### 5.4.3.3 Logical Volume List

Select a volume group from [5.4.3.2 Volume Group List](#node.xhtml#5.4.3.2 Volume Group List) to list the assigned logical volumes from [5.4.3.3 Logical Volume List](#node.xhtml#5.4.3.3 Logical Volume List).
You can create, modify, delete, mount, and format logical volumes.

| **Category** | **Description** |
| ---- | ---- |
| **Name**  | The name of a logical volume. |
| **Mount** | The path where the logical volume is mounted. |
| **Size**  | The total size of a logical volume. |
| **Usage(%)**  | The usage of the logical volume in percentage. |

#### 5.4.3.3.1 Creating Logical Volume

Press **Create** button from [5.4.3.3 Logical Volume List](#node.xhtml#5.4.3.3 Logical Volume List) to create a logical volume.

| **Category** | **Description** |
| ---- | ---- |
| **Volume Group Name** | Select a volume group from the drop-down list. |
| **Volume Name** | Enter a new logical volume name. Enter 4 ~ 20 alphanumeric letters starting with an alphabet.<br/>As for symbols, only `"-"` and `"_"` are allowed. |
| **Volume Type** | Select the allocation type for the new volume group.<br/><ul><li>**Static Allocation** - Creates a default logical volume.</li><li>**Dynamic Allocation** - Creates a thin provisioned logical volume (ThinLV). You can select this option only when the volume group has dynamic allocation configured.</li></ul> |
| **Available Space** | The available space of the selected volume group.<br/>It shows only when the volume type is configured as static allocation. |
| **Volume Size** | Set the size of the new logical volume.<br/>The number can be set up to two decimal places. |

#### 5.4.3.3.2 Modifying Logical Volume

Press **Modify** button from [5.4.3.3 Logical Volume List](#node.xhtml#5.4.3.3 Logical Volume List) to configure the size of the selected logical volume.

<div class="notices blue element normal">
    <ul>
        <li>Only the mounted logical volume can be modified.</li>
    </ul>
</div>

| **Category** | **Description** |
| :---: | :--- |
| **Volume Group Name** | The name of a volume group where the logical volume is at. |
| **Volume Name** | The name of a logical volume. |
| **Volume Type** | Whether it is a default logical volume (LV) or thin provisioned logical volume(ThinLV). |
| **Volume Size** | Configure the size of the logical volume. |

#### 5.4.3.3.3 Formatting Logical Volume

Press **Format** button from [5.4.3.3 Logical Volume List](#node.xhtml#5.4.3.3 Logical Volume List) to format the selected logical volume.

<div class="notices blue element normal">
    <ul>
        <li>Cannot format logical volumes that are mounted.</li>
    </ul>
</div>

#### 5.4.3.3.4 Mounting Logical Volume

Press **Mount** button from [5.4.3.3 Logical Volume List](#node.xhtml#5.4.3.3 Logical Volume List) to mount the selected logical volume.

<div class="notices blue element normal">
    <ul>
        <li>Cannot mount logical volumes that are already mounted.</li>
    </ul>
</div>

#### 5.4.3.3.5 Unmounting Logical Volume

Press **Unmount** button from [5.4.3.3 Logical Volume List](#node.xhtml#5.4.3.3 Logical Volume List) to unmount the selected logical volume.

<div class="notices blue element normal">
    <ul>
        <li>Cannot unmount logical volumes that are not mounted.</li>
    </ul>
</div>

#### 5.4.3.3.6 Deleting Logical Volume

Press **Delete** button from [5.4.3.3 Logical Volume List](#node.xhtml#5.4.3.3 Logical Volume List) to delete the selected logical volume.

<div class="notices blue element normal">
    <ul>
        <li>Cannot delete logical volumes that are mounted.</li>
    </ul>
</div>
