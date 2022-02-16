## 4.3 Share Settings

### 4.3.1 About Share Settings Menu

> This menu is for managing and configuring shared objects provided by the cluster volume.
>
> You can configure the CIFS and NFS shares.

+ **It is recommended to set one NFS share per one cluster volume**

    If the share is in the same cluster volume, it will mean that it also shares the same NFS configuration.

### 4.3.2 Contents of Share Settings Menu

#### 4.3.2.1 About Share Settings Tab
* Provides the list and the configuration menu for all shares.
* A shared object is an aggregate of information including basic information on the share such as the share path or the cluster volume of the share.
* A shared object will be displayed on the list of CIFS Share tab or NFS Share tab depending on its service protocol configuration.

#### 4.3.2.2 About CIFS Share Tab
* Provides the list and the configuration menu for CIFS shared objects.
* Only shows the shared object that has selected the CIFS service protocol.

#### 4.3.2.3 About NFS Share Tab
* Provides the list and the configuration menu for NFS shared objects.
* Only shows the shared object that has selected the NFS service protocol.

### 4.3.3 Share Settings Tab

#### 4.3.3.1 Contents of Share Settings Tab
* The list displays the details on each shared object.
* The information includes a share's name, description, status, path, volume, modified date, and service protocol.

|  Category  |  Description  |
|  :---:  |  :---  |
| **Share Name** | View the name for identification of a shared object. |
| **Description** | View the description of the shared object. |
| **Status** | View the status of a shared object. It will display **'Normal'** of the status is normal. |
| **Path** | View the path of a file system inside the volume provided to the client by the shared object. |
| **Volume** | View the cluster volume provided to the client by the shared object. |
| **Modified Date** | The time of creation/modification of the shared object. |
| **Service Protocol** | View the service protocol provided by the shared object.<br>You can select either or both CIFS and NFS. |

#### 4.3.3.2 Creating Shared Object
> Select **Share Settings** tab from **Share Settings** menu and click **Create** button to create a new shared object.

##### 4.3.3.2.1 Contents of the Shared Object
* **[Share Name]**
  * A name of the shared object to be created.
  * 4~20 alphanumeric characters.
* **[Volume]**
  * A volume that will be shared by the shared object.
  * Select a cluster volume created from "[2.3 Volume Management](#clusterVolume.xhtml#2.3 Volume Management)".
* **[Share Description]**
  * Enter the description of the shared object.
* **[Service]**
  * Select whether the shared object will be providing the shared space to the clients using which protocol.
  * You can select either or both CIFS and NFS.
  * If CIFS is selected, the created shared object will appear on the CIFS share tab.
  * If NFS is selected, the created shared object will appear on the NFS share tab.
* **[Share Path]**
  * If you do not select a share path, it will be set to the path of the volume. (It will show volume path's permission as POSIX, ACL's permission.)
  * You can select a path from the list to set it as share path. (It will show selected path's permission as POSIX, ACL's permission.)
  * If you click "Create share directory" button, you will be able to create share path as sub directory of current volume path.
* **[POSIX Permission Setting]**
  * Displays the POSIX permissions of the selected share path.
  * Can view and change the permissions of User, Group, and Other.
  * By clicking "Change Permission" button, popup window will show you users and groups list and you will be able to change their permission by clicking "Apply" button after updating permission.
* **[ACL Permission Setting]**
  * Displays the ACL permissions of the selected share path.
  * Can view and change the permissions of User, Group, and Other.
  * By clicking "Change Permission" button, popup window will show you users and groups list and you will be able to change their permission by clicking "Apply" button after updating permission.
  * Delete button will be activated when you select any user or group. CLick "Delete" button to delete selected user or group.


#### 4.3.3.3 Modifying Shared Object
> Navigate to **Share Settings** tab from **Share Settings** menu and click **Modify** button to modify the selected shared object.

##### 4.3.3.3.1 Contents of the Shared Object
* **[Share Setting Information]**
  * You can modify share's basic settings.
  * Volume name, Share name can also be modified.
  * "Description" allows to enter share description.
  * **[Service]**
    * Select whether the shared object will be providing the shared space to the clients using which protocol.
    * You can select either or both CIFS and NFS.
    * If CIFS is selected, the created shared object will appear on the CIFS share tab.
    * If NFS is selected, the created shared object will appear on the NFS share tab.
* **[Service Protocol]**
  * The protocol for share will be activated and  each protocol settings can be updated by clicking respective button.
* **[Share Permission]**
  * Share path can't be changed.
  * It will show sub-directory information of the share path.
  * If share path is not senected, it will show POSIX, ACL information of the shared director.
  * You can set POSIX, ACL permission by selecting sub-directory of the share. 
  * POSIX, ACL settings are same as share creation.


#### 4.3.3.4 Deleting Shared Object
> Navigate to **Share Settings** tab from **Share Settings** menu and click **Delete** button to delete the selected shared object.
>
> Select one or more shared object from the list and press **Delete** to delete multiple shared object at once.

### 4.3.4 CIFS Share

#### 4.3.4.1 Contents of CIFS Share Tab
* CIFS share list displays the details of each shared object that uses CIFS.
* The information includes a share's name, description, path, permission, guests, hide status, and activation.

|  Category  |  Description  |
|  :---:  |  :---  |
| **Share Name** | View the name for identification of a CIFS shared object. |
| **Description** | View the description of the CIFS shared object. |
| **Path** | View the path of a file system inside the volume provided to the client by the CIFS shared object. |
| **Permission** | View the access permission on the CIFS share. |
| **Guests** | View the status of whether the CIFS shared object allows 'guest' accounts. |
| **Hide** | View the status of whether the share is configured to be hidden from Windows clients. |
| **Enable** | View on whether the CIFS shared object is available.<br>If the status is 'on', it means that the share is enabled. |

#### 4.3.4.2 Modifying CIFS Shared Object
> Go to **CIFS Share** tab from **Share Settings** menu and click **Modify** button to modify the selected shared object.

##### 4.3.4.2.1 Contents of the CIFS Shared Object
* **[Access Permission]**
  * Configure the access permission on the CIFS shared object.
  * Select either 'read' or 'read/write'.
* **[Share Administrator]**
  * Enter the name of the administrator who will manage the CIFS shared object.
* **[Enable]**
  * Select whether the CIFS share should be enabled.
  * If **Enable** is selected, the CIFS share will be activated.
* **[Guests]**
  * Select whether the CIFS share should use 'guest' accounts.
  * If **Guests** is selected, it will allow the 'guest' accounts.
  * If the 'guest' accounts are allowed, an individual can access the CIFS share by just entering the user ID as 'guest'.
  * The 'guest' accounts will follow the configured **access permission** of the CIFS share.
* **[Hide]**
  * Select whether the CIFS share should be hidden from the Windows client.
  * If **Hide** is selected, the Windows client will be unable to search the CIFS share.
  * However, even if the share is hidden from Windows client, it can be accessed if its address is entered.

##### 4.3.4.2.2 Users Accessing CIFS Share
* **[User Name/Description]**
  * The name and description of the user account registered in the cluster.
  * To create/modify/delete the user, go to "[3.2 User](#account.xhtml#3.2 User)" or "[3.4 External Authentication](#account.xhtml#3.4 External Authentication)" to proceed the task.
* **[Authentication]**
  * The authentication method of the user.
  * The methods are used either local authentication or ADS.
* **[Permission]**
  * Configure access permission of CIFS share for each user.
  * The access permission on the user can be selected among 'allow', 'disallow', 'read-only', 'read/write', and 'deny'.

    |  Permission   |  Description  |
    |  :---:  |  :---  |
    | **allow** | Allows the users from accessing the CIFS share.<br>The read/write permission of the user follows the **permission** configured in "[4.3.4.2.1 Contents of the CIFS Shared Object](#share.xhtml#4.3.4.2.1 Contents of the CIFS Shared Object)". |
    | **disallow** | Limits the users from accessing the CIFS share.<br>If the user belongs to a group, the user will follow the **permission** configured in "[4.3.4.2.3 Groups Accessing CIFS Share](#share.xhtml#4.3.4.2.3 Groups Accessing CIFS Share)". |
    | **read-only** | Allows the users from accessing the CIFS share.<br>The user will only have read permission. |
    | **read/write** | Allows the users from accessing the CIFS share.<br>The user will have both read and write permission. |
    | **deny** | Forbids all users from accessing the CIFS share. |

##### 4.3.4.2.3 Groups Accessing CIFS Share
* **[Group Name/Description]**
  * The name and description of a group in the cluster.
  * To create/modify/delete the group, go to "[3.3 Group](#account.xhtml#3.3 Group)" or "[3.4 External Authentication](#account.xhtml#3.4 External Authentication)" to proceed the task.
* **[Authentication]**
  * The authentication method of the group.
  * The methods are used either local authentication or ADS.
* **[Permission]**
  * Configure access permission of CIFS share for each group.
  * The access permission on the zone can be selected among 'allow', 'disallow', 'read-only', 'read/write', and 'deny'.

    |  Permission   |  Description  |
    |  :---:  |  :---  |
    | **allow** | Allows the users in the group from accessing the CIFS share.<br>The read/write permission of the user follows the **permission** configured in "[4.3.4.2.1 Contents of the CIFS Shared Object](#share.xhtml#4.3.4.2.1 Contents of the CIFS Shared Object)". |
    | **disallow** | Limits the users in the group from accessing the CIFS share. |
    | **read-only** | Allows the users in the group from accessing the CIFS share.<br>The user will only have the permission to read. |
    | **read/write** | Allows the users in the group from accessing the CIFS share.<br>The user will have both read and write permission. |
    | **deny** | Forbids the users in the group from accessing the CIFS share. |


##### 4.3.4.2.4 Configuring CIFS Security Zone
* **[Zone Name/Allowed Address]**
  * The name of a security zone and its address.
  * To create and delete the security zone, go to "[1.5.4 Security Settings](#cluster.xhtml#1.5.4 Security Settings)" tab to proceed the task.
* **[Permission]**
  * Configure access permission of CIFS share for each zone.
  * The access permission on the zone can be selected among 'allow', 'disallow', and 'deny'.

    |  Permission   |  Description  |
    |  :---:  |  :---  |
    | **allow** | Allows the clients in the security zone from accessing the CIFS share. |
    | **disallow** | Limits the clients in the security zone from accessing the CIFS share. |
    | **deny** | Forbids the clients in the security zone from accessing the CIFS share. |

*  For instance, if the permission is set as "deny" on the security zone having the IP of "1.2.3.4", the server will block all requests coming from the IP "1.2.3.4".


### 4.3.5 NFS Share

#### 4.3.5.1 Contents of NFS Share Tab
* NFS share list displays the details of each shared object that uses NFS.
* The information includes a share's name, description, path, and activation.

|  Category  |  Description  |
|  :---:  |  :---  |
| **Share Name** | View the name for identification of an NFS shared object. |
| **Description** | View the description of the NFS shared object. |
| **Path** | View the path of a file system inside the volume provided to the client by the NFS shared object. |
| **Enable** | View on whether the NFS shared object is available.<br>If the status is 'on', it means that the share is enabled. |

#### 4.3.5.2 Modifying NFS Shared Object
> Go to **NFS Share** tab from **Share Settings** menu and click **Modify** button to modify the selected shared object.

##### 4.3.5.2.1 Contents of the NFS Shared Object
* **[Enable]**
  * Select whether the NFS share should be enabled.
  * If **Enable** is selected, the NFS share will be activated.

##### 4.3.5.2.2 Configuring NFS Security Zone
* **[Zone Name/Allowed Address]**
  * The name of a security zone and its address.
  * To create and delete the security zone, go to "[1.5.4 Security Settings](#cluster.xhtml#1.5.4 Security Settings)" tab to proceed the task.
* **[Permission]**
  * Configure access permission of CIFS share for each zone.
  * The access permission on the zone can be selected among 'disallow', 'read-only', and 'read/write'.
  
    |  Permission   |  Description  |
    |  :---:  |  :---  |
    | **disallow** | Limits the clients in the security zone from accessing the NFS share. |
    | **read-only** | Allows the clients in the security zone from accessing the NFS share.<br>The clients will only have read permission. |
    | **read/write** | Allows the clients in the security zone from accessing the NFS share.<br>The clients will have both read and write permission. |

*  For instance, if the permission is set as "deny" on the security zone having the IP of "1.2.3.4", the server will block all requests coming from the IP "1.2.3.4".
* **[NoRootSquashing]**
  * Decides whether the permission of the client root should be considered as the same with the NFS server root.
  * If [NoRootSquashing] is 'on', the client root will have the root permission in the shared space provided by the NFS share.
* **[Insecure]**
  * Decides whether it will allow the Internet port(~1024).
  * If [Insecure] is 'on', it will allow the Internet port(~1024).
