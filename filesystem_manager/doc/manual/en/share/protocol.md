## 4.1 About Service Protocol

+ **Multi-Protocol Support**

    AnyStor-E has multi-protocol access.    
    However, lock and ACL policies are not shared between protocols.    

> Every node of AnyStor-E will have **/export/(Volume Name)** folder created and will have access to the identical file system image.  
> The folder can be shared through NFS and CIFS/SMB protocols along with the export option.   
> AnyStor-E Manager only supports tested and tuned configuration. Further configuration can be done through the technical support.  

### 4.1.1 Technical Description on the Protocol
> This chapter shows the basic technical description on NFS/CIFS service protocols.

#### 4.1.1.1 CIFS / SMB (Common Internet File System)
> AnyStor-E supports SMB 1.0, 2.0, and 3.0. The details are as follows.

| SMB version | Supported Operating System    |
| :-------:   |                               |
| 1           | Windows 2000 or later <br> Windows XP or later <br> Mac OS X 10.5 or later |
| 2           | Windows Vista or later <br> Windows Server 2008 or later       |
| 2.1         | Windows 7 or later <br> Windows Server 2008 R2 or later         |
| 3           | Windows 8 or later <br> Windows Server 2012 or later <br> Mac OS X 10.11 or later  |

* **About CIFS/SMB Protocol**

 * CIFS/SMB is a protocol that allows accessing files or data of remote computer through the network.
 * Through CIFS/SMB protocol, it can control the access by users, domains, and IP ranges.
 * AnyStor-E supports Windows and Linux along with MacOS environment.

* **NetBIOS Name**

 * NetBIOS(Network Base Input/Output System): A communication protocol used when the software communicates with the remote computer through the network.
 * NetBIOS Name is a standard character string of fewer than 16 letters for defining a software which becomes the subject for the communication by the NetBIOS protocol.

* **WINS (Windows Internet Naming Service)**
 * WINS is a service used in Windows client.
 * It associates the NetBIOS name and the IP address which will notify the appropriate network address for the NetBIOS name provided by the Windows client when needed.

* **CIFS Security Mode**
 * CIFS protocol supports all types of access controls on the file system and these types are known as the **security mode**.

    | Security Mode | Description      |
    | :-------:       | :-------             |
    | **user**      | This will be the default setting if the user does not designate any security mode.<br> It will allow or deny the request by checking the user's name and password of the client who is making the request. |
    | **ads**       | The authentication module of CIFS protocol which uses Microsoft ADS(Active Directory Service).<br> For more information on ADS, please refer to **[3.4 External Authentication](#account.xhtml#3.4 External Authentication)**. |
    | **domain**   | The option to read and write the user or group using CIFS protocol concentrating into a single shared space.<br> A single server inside the domain (a workgroup), which is known as the **domain controller**, will proceed the authentication of all clients. The server will be designated by its user or automatically by the domain's own internal decision. |

#### 4.1.1.2 NFS (Network File System)

* **About NFS Protocol**
 * NFS is a protocol mostly used in Unix/Linux environment.
 * NFS protocol provides access control on the share by the IP range.

* **Protocol Comparison**

    | Feature  |  NFS                   | CIFS             | FUSE        |
    | :---:  |              :-------          |           :-------       |                     :-------        |
    | Performance   | Capable in both small and large files  | Better in large files      | Better in large files and parallel reading   |
    | Stability | Reconnects the session when it is disconnected    | Interrupts I/O of file service when failover/failback occurs | Good |
    | Compatibility | Unix, Linux, VMware    | Windows, MacOS   | Linux                  |

+ **NFS Compatibility**

    **NFS v3 protocol** based on TCP is fundamentally built-in to AnyStor-E.    
    The access to the share will not be seamless if there is a problem on **MTU configuration** or **network environment**.


## 4.2 Configuring Service Protocols

> To share the cluster volume to the client, you have to configure the storage sharing server (Daemon) from **Protocol Settings** page.  
> Supported protocol services are CIFS and NFS.  
> The configuration will be applied to all shares using the protocol.  


### 4.2.1 CIFS Settings
> Go to **Protocols >> Protocol Settings** page from the menu list and click **CIFS Settings** tab for its configuration.  
> You can enable, disable, and restart the CIFS service.  
> While restarting CIFS, the file that was in transfer will not redo after the reset.  

* **[Enable Service]**
  * Select the check box to enable the CIFS server to all nodes in the cluster.
* **[Service Status]**
  * Shows on/off status of the CIFS server.
* **[Restart Service]**
  * Click the button to restart the CIFS server.
  **[NetBIOS Name]**
  * Shows the NetBIOS name allocated to all CIFS server in the entire cluster.
  * The cluster management software will automatically designate hostname from one of the cluster nodes.
* **[Mode]**
  * Shows the security mode that is currently used by the CIFS protocol.
  * Go to "[3.4 External Authentication](#account.xhtml#3.4 External Authentication)" for the configuration.
* **[Workgroup]**
  * Set the workgroup for the CIFS server of the cluster.
* **[WINS Server]**
  * Set the WINS server for the CIFS servers of the cluster.


### 4.2.2 NFS Settings
> Go to **Protocols >> Protocol Settings** page from the menu list and click **NFS Settings** tab for its configuration.  
> You can enable, disable, and restart the NFS service.    

+ **Note**  

    The default configuration for NFS service is **On**.   
    When restarting the service, the client might experience a slight latency on the connection.   

-----

* **[Enable Service]**
  * Select the check box to enable the NFS server to all nodes in the cluster.
* **[Service Status]**
  * Shows on/off status of the NFS server.
* **[Restart Service]**
  * Click the button to restart the NFS server.
* **[Common Options]**
  * Set the option that is applied to all NFS server.
