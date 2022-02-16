<span style="color:#0000BB">Configuration</span>
====

### Setting administrator

##### Add user

    /usr/gms/script/gms useradd -n <USER> -p <PASSWORD>

##### Delegate account as web administrator

    /usr/gms/script/gms admin -n <USER>

### Node configuration

**Node configuration is the step of setting basic information for each node**

1.  IP setting  
     **vim /etc/sysconfig/network-scripts/ifcfg-<Interface>** (you can use another IP setting command)  
    ![](./images/10.PNG)
2.  Access <IP Address> on the web  
3.  System Setting Wizard, Click **Next**  
    ![](./images/eng1.png)
3.  Select Storage Network Device  
    ![](./images/eng2.png)
4.  Select bonding mode, Usually select 'Active Backup'  
    ![](./images/eng3.png)
5.  Input the storage Network address  
    ![](./images/eng4.png)
6.  Select Service Network Device  
    (If you want to use service network and management network as one, check the 'Use it as both service network device and management network device')  
    ![](./images/eng5.png)
7.  Select bonding mode, Usually select 'Round-Robin'  
    ![](./images/eng6.png)
8.  Select Management Network Device  
    ![](./images/eng7.png)
9.  Check configuration information and click 'Apply'  
    ![](./images/eng8.png)

### Cluster Setup

**Cluster initialization is performed on the first node in the cluster**

-   After completing the node configuration, Select **Create Cluster** on the wizard page  
    -   Click 'OK' after input clustername, service IP range, netmask  
    -   you can check the initialization process by checking the **`/var/log/gms/procedure_gms.log`**  

![](./images/eng9.png)

### Cluster Expand

**It is executed by accessing the node to be included in the clsuter**

-   After completing the node configuration, Select **Add Node to Cluster** on the wizard page  
    -   Input Management IP of the Cluster Node(First Node) and Click 'OK'  
    -   When pop-up the **"Would you like to expand after adding the node?"**  
        Click **"Expand"**  
    -   you can check the initialization process by checking the **`/var/log/gms/procedure_gms.log`**  

![](./images/eng10.png)

### Configuring the Cluster

![](./images/eng11.png)

**Caution** <br/> 

-   Problems occur when adding clusters at the same time  
-   If you click 'OK' multiple times during the initializtion, the API is called multiple times, which may cause problems.  

