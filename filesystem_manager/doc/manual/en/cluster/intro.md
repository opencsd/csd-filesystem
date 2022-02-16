# 1 Cluster Management

## 1.1 Preface

> **AnyStor Enterprise** provides cluster and node management features through GUI.
>
> Through this, it can verify and respond on **various events and performance data** that takes place across the entire cluster.
>
> You can control the client's access and easily configure several distributed nodes through time settings and power management.
>

 **About Cluster Management Section**

| Category                   | Description                                                               |
| :------------:         | :----------------                                                  |
| **Overview**             | A dashboard presenting the summary of system informations of all nodes of the cluster. |
| **Cluster Node Management** | View the information and status of all active or standby physical nodes. Used for shifting them as active or maintenance mode. |
| **Event**             | Audits all events and tasks occurred in the entire node along with the adjustment in hardwares and softwares.  |
| **Network Settings**      | Manages the overall network configuration on service IP pool, DNS, routing, and security zone. |
| **Email Settings**        | Manages email settings to receive notification on events and tasks occurred in the system. |
| **Time Settings**          | Manages time synchronization of all nodes through NTP or manual time settings. |
| **Power Management**          | Manages the power of all nodes in the cluster. |
| **Log Backup**          | Provides download options on the system log.  |
| **License Management**      | Provides license search, license registration, and product code verification of your cluster.  |


- **Caution**

    Some actions can be restricted if a node is down while managing the cluster.    
    However, the configurations will be automatically synchronized with the cluster information through reloading the configuration information when the node is recovered.
