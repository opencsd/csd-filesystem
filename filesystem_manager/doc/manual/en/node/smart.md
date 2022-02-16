## 5.11 SMART

### 5.11.1 SMART overview
> Can check disk's SMART details and test result.
> Disk's electrical and machanicla faults can be detected by reviewing details information and test result.

[S.M.A.R.T. - Wikipedia](https://en.wikipedia.org/wiki/S.M.A.R.T.)

+ **SMART information is updated in every hour.** 

- **SMART restrictions**

    Depending on the disk type and vendor, themeaning of SMART attributes may be different.
    H/W RAID controller only supports megaraid.

  
### 5.11.2 SMART Components

#### 5.11.2.1 Disk Informaiton
> Will show Disk Model, Temperature, Usage time etc.

| Category              | Description |
|-----------------------|-------------|
| **Status**            | Will show disk status.<br>&nbsp;&nbsp;&nbsp;&nbsp;**Normal**(![ICONNORMAL](./images/icon-status-normal2.png)) - Normal state.<br>&nbsp;&nbsp;&nbsp;&nbsp;**Warning**(![ICONWARN](./images/icon-status-warning2.png)) - One or more SMART attribute is suspected to be defective.<br>&nbsp;&nbsp;&nbsp;&nbsp;**Error**(![ICONERR](./images/icon-status-error2.png)) - Will show when Disk's **Healthy** value is **FAILED**.|
| **Block Device Name** | The name of the block device mapped to disk.|
| **Serial No.**        | The serial number of the disk.|
| **Model**             | The model name of the disk.|
| **Temperature**       | Internal temperature of the disk.|
| **Size**              | The total size of the disk.|
| **Device Type**       | The type of disk.<br>&nbsp;&nbsp;&nbsp;&nbsp;**HDD**: Hard disk drive<br>&nbsp;&nbsp;&nbsp;&nbsp;**SSD**: Solid state drive|
| **Healty**            | SMART diagnostic result. <br>&nbsp;&nbsp;&nbsp;&nbsp;**PASSED**: No issue<br>&nbsp;&nbsp;&nbsp;&nbsp;**FAILED**: Defective<br>&nbsp;&nbsp;&nbsp;&nbsp;**UNKNOWN**:SMART not supported by the disk|
| **SMART Support**     | A disk device that supports SMART diagnostics|
| **OS Disk**           | Will show if OS is installed on the disk.|
| **Power-On Hours**    | Refers to the length of time, in hours, that electrical power is applied to a device.|

#### 5.11.2.2 Disk Properties
> Will show information to diagnose disk's electrical and mechanical faults.

+ **Please refer to [S.M.A.R.T. - Wikipedia](https://en.wikipedia.org/wiki/S.M.A.R.T.) for each attribute value.**


| Category           | Description |
|--------------------|-------------|
| **Status**         | Shows the status of SMART attributes.<br>&nbsp;&nbsp;&nbsp;&nbsp;**Normal**(![ICONNORMAL](./images/icon-status-normal2.png)) - Status in normal.<br>&nbsp;&nbsp;&nbsp;&nbsp;**Warning**(![ICONWARN](./images/icon-status-warning2.png)) - Current value is less or equal to the threshold value. |
| **ID**             | SMART attribute wise ID.|
| **Attribute Name** | SMART attribute name.|
| **Current Value**  | This is a generalized raw value. Depending on the vendor and model this value may be 100, 250 or 255.|
| **Worst Value**   | During the total disk usage time, the current value is closest to the threshold value.|
| **Threshold**      | Vendor-specified threshold. The closer the current value is to the threshold, the higher the fault rate.|
| **Raw Value**      | Raw values, such as temperature, recovery, etc., depending on the SMART attribute. |
| **Attribuye Type** | If the current value is below the threshold value, it can be classified as follows according to the attribute type.<br>&nbsp;&nbsp;&nbsp;&nbsp;**Old-age**: Mechanical wear, aged disk<br>&nbsp;&nbsp;&nbsp;&nbsp;**Pre-fail**: Disk operation fault|

#### 5.11.2.3 SMART Test Result
> Will show information and results of recent SMART tests.

- **If you are experiencing an LBA error during SMART testing, please contact technical support.** 

| Category             | Description |
|----------------------|-------------|
| **No.**              |The test execution number. The lower number refers to  more recently performed tests.|
| **Progress Status**  |Test progress status.|
| **Error on LBA**     |Logical block address where the read test failure occured.|
| **Power-On Hours**   |Refers to the length of time, in hours, that electrical power is applied to a device.|
| **Test Type**        |Shows test type performed.<br>&nbsp;&nbsp;&nbsp;&nbsp;**short offline**: Used for quick defect detection of discs. Performs electrical tests on the disk controller, mechanical testing of the headers, servomotors test, read and validation of specific areas.<br>&nbsp;&nbsp;&nbsp;&nbsp;**extended offline**: This is a test designed to be the final test for disc production. It is the same as the short test, but does not have a time limit and performs read and validation on all areas.|
| **Test Result**      |Shows test result and errors (if any).|

