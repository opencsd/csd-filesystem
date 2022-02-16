## 1.7 Time Settings

> Synchronizes the time setting of every node in the cluster.  
> You can set the time using the external time server (such as NTP) or by manual.  
> By using the NTP server, it can synchronize the cluster's time settings to the standard time.  

+ **Synchronizing Time with the Cluster**

    From heartbeat, which diagnoses the node error and downtime, to journaling file system, which updates the newest changes,
    cluster shares information between nodes by miscellaneous software components.   
    In other words, the cluster might malfunction if there is a time mismatch between nodes.    
    AnyStor-E provides cluster-wide time synchronization through its embedded NTP master.   

 ---
- **Caution**

    When the time is changed manually, it may cause issues in the monitoring system.    
    It can also cause an error in the performance statistics.

### 1.7.1 Contents

|Category            |Description|
|----            |----|
|Current System Time|View the current time of the cluster.|
|Universal Time     |Able to set the standard time zone for the local region.|
|Manual Setting       |Able to set the date and time manually.|
|Time Synchronization     |Able to synchronize the time by designating the external time server.|

* **Time Synchronization**

 * Synchronizes the time with the uppermost NTP server.
 * If the connection with the main NTP server is invalid, it will be synchronized with the other NTP server you have configured previously.
 * It can be added up to 5 servers.
