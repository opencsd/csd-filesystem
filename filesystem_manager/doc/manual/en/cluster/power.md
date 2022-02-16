## 1.8 Power Management

> This feature provides power management on every node in the cluster.

+ **Recommended Boot Order**

    When turning on the cluster, starting off from the first node will make it faster to change the stage to RUNNING.   
    It will be considered as normal when **Cluster Status** from "[1.2 Overview](#cluster.xhtml#1.2 Overview)" is set as RUNNING.    
    However, the service will not start when the cluster quorum is not fulfilled.     

### 1.8.1 Power Management
> It manages cluster's power.  
> Every node in the cluster will be involved when you use system shut-down or system restart option.  
> System shut-down and restart will proceed in an order designated by the system.  

* **System Shut-down**
 * Shuts down all node in the cluster.

* **System Restart**
 * Restarts all node in the cluster.


---
