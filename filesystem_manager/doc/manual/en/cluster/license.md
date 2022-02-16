## 1.10 License Management

> This menu offers you to manage the license for the cluster management function.
> This menu will help you to register new license and browse the list of registered licenses.

+ **Demo License Policy**
    
    After the cluster is created, the demo license will be enabled and will last for a period of time.
    While the demo license is enabled, every feature of AnyStor-E will be available.
    When the demo license is expired, all the features, except for License Management, will be unavailable.
    To use the features of AnyStor-E after the expiration of demo license, please make an inquiry to Gluesys.

-----

- **Restriction of Features by License**

    Some features which requires a license will be restricted to use when it is not registered.

-----

* **Contents**
    
    | Name                 | Location                |  Description                                        |
    | :---                 | ---                     | ---                                                 |
    | License List         | License Management page | Able to browse the registered license from the list |
    | License Registration | License Management page | Able to register a new license                      |

### 1.10.1 Type of License

* Licenses are classified as system, restriction, and activation.
* System license
  * A license which has the system type such as AnyStor-E, Support, or Demo.
  * A system license cannot be used after the expiration.
  * AnyStor-E: A license to use AnyStor-E. The name may vary due to the type of the software.
  * Support: A warranty license of the technical support on AnyStor-E.
  * Demo: A demo version license of AnyStor-E. It will be enabled immediately after the cluster is built and can use every features for a period of time. When the demo license is expired, all features will be restricted to use.

* Restriction license
  * A license for the restrictions such as the number of nodes or volume sizes.
  * The resources related with the license will be displayed from the permission section.
  * A restriction license key may expire if it is not registered in a certain period of time.
  * Nodes: Shows the number of maximum nodes which can be attached to the cluster.
  * VolumeSize: The maximum size of cluster volume which can be created.

* Activation license
  * A license which determines whether to enable CIFS, NFS, and ADS.
  * An activation license key may expire if it is not registered in a certain period of time.
  * CIFS: A license which enables CIFS.
  * NFS: A license which enables NFS.
  * ADS: A license which enables ADS.

### 1.10.2 License Configuration

* Contents
  * The information on the license will be listed in each row.
  * A single row includes license name, status, enabled date, expiration date, permission, and registered date.

    |  Category  |  Description  |
    |  :---:  |  :---  |
    | **License Name** | View the name of a license. |
    | **Status** | View the status of a license.<br> It will show either "Active", "Inactive", or "Expired". |
    | **Enabled Date** | View the date on when the license is enabled. |
    | **Expiry Date** | View the date on when the license will expire. |
    | **Permission** | View the permission on which the license allows.  |
    | **Registered Date** | View the date on when the license is registered. |

#### 1.10.2.1 License Registration
> Go to **License Management** and press **Register** button to register a new license.

* **[Product Key]**
  * An automatically generated key for cluster depending on the system's status.
  * The key consists of four random uppercase alphabets connected with four hyphens. ex) ASNC-VJCV-RGYE-GHCU
  * The product key will be used for validation of the license when the license key is issued.
  * To acquire the license, you must send the product key to Gluesys.

* **[License Key]**
  * Able to enter the license key issued by Gluesys.
  * When the entered license key is found valid, the registered license will be added to the license list and will be allowed to use every features related with the registered license.

