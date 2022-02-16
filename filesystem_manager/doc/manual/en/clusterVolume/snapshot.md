## 2.4 Snapshot Management
### 2.4.1 About Snapshot Management
> Can create manual snapshot or set snapshot scheduling in dynamically allocated cluster volume.

**Snapshot**  
> Snapshot is a technique for storing a volume's image at a specific point of time. This function allows you to acccess files in the past due to data deletion or alternation.  
> Snapshot scheduler makes snaption creation and rotation easier.  

+ **Note**

    Snapshot feature is enabled only for dynamically allocated cluster volumes.     
    You can create ***255*** snapshots per volume.
    The snapshot creation may be canceled due to system condition such as excessive I/O.   
    Snapshot creation fails during cluster volume rebalancing.  

### 2.4.2 Snapshot Scheduling List
> Snapshot scheduling list and manually created snapshot list are available for each cluster volume.

|Category|Description|
|----|----|
|Volume Name|The name of the cluster volume that will create snapshot.|
|Schedule Name|Name of the configured scheduling. Manually created snapshots will appear as **Manual Snapshot**.|
|Repeat Interval|View the interval of snapshot creation. Please refer to [2.4.3 Creating Snapshot Schedule](#clusterVolume.xhtml#2.4.3 Creating Snapshot Schedule).|
|Next Run Time|View the date and time when it will proceed the next schedule for the snapshot.|
|Last Executed Time|View the date and time of the most recently executed schedule.|
|Last Executed Status|View whether the most recently executed schedule has created a snapshot.  <br>&nbsp;&nbsp;&nbsp;&nbsp; **OK** - Snapshot created successfully<br>&nbsp;&nbsp;&nbsp;&nbsp; **ERROR** - Snapshot failed to create|
|Start Date|View the date when it will start creating the snapshot.|
|End Date|View the date when it will end creating the snapshot.|
|Activation|View whether the scheduling is working. When deactivated, the snapshot will not be created.  <br>&nbsp;&nbsp;&nbsp;&nbsp; **Enable** - Enable scheduling   <br>&nbsp;&nbsp;&nbsp;&nbsp; **Disable** - Disable scheduling|
|No. of Snapshot|The total number of snapshot created through the scheduling.|
|Action|Can perform additional task in scheduling.  <br>&nbsp;&nbsp;&nbsp;&nbsp; **SNAPSHOT** - Can manage cluster volume's snapshot.  <br>&nbsp;&nbsp;&nbsp;&nbsp; **CHANGE** - Can change scheduling settings.  <br>&nbsp;&nbsp;&nbsp;&nbsp; **DELETE** - Can delete scheduling.|

**Action**
> NAPSHOT, CHANGE, and DELETE button will be available for snapshot scheduling list
> only SNAPSHOT button will be available for manual snapshot list.

#### 2.4.2.1 Snapshot management
> You can manage cluster volume wise snapshots created manually or as per schedule by pressing **SNAPSHOT** button from **Action** menu.

| Category 		| Description |
|-----	    	|------|
|Snapshot Name	| Snapshot name format will be "Name_Greenwich mean time". <br>Snapshots which are created by scheduler, the term **auto** will be included with its name.|
|Node   		| Name of the nodes which were included in the cluster volume during snapshot creation.|
|Status	    	| Will show snapshot status.|
|Create Date	| Snapshot sreation time according to web browser based time zone.|
|Enable		    | Will show snapshot activate/deactivate status. Please refer to [2.4.2.1.1 Snapshot Activate Deactivate](#clusterVolume.xhtml#2.4.2.1.1 Snapshot Activate Deactivate) for more details.|
|Action		    | You can perform additional operations on the snapshot.   <br>&nbsp;&nbsp;&nbsp;&nbsp; **DELETE** - Selected snapshot will be deleted.  <br>&nbsp;&nbsp;&nbsp;&nbsp; **ACTIVATE/DEACTIVATE** - Can activate/deactivate snapshot.|

##### 2.4.2.1.1 Snapshot Activate Deactivate
> [2.4.2.1 Snapshot management](#clusterVolume.xhtml#2.4.2.1 Snapshot management) Click Activate/Deactivate from **Action** manu to use the snapshot.  
> Clients can access snapshot data if the snapshot is activated.  

##### 2.4.2.1.2 Delete Snapshot
> [2.4.2.1 Snapshot management](#clusterVolume.xhtml#2.4.2.1 Snapshot management) Click **Delete** from **Action** manu to delete the snapshot.

> * **Snapshot access path for clinets**
>   * *<MOUNT\_DIR\>/.snaps/<ACTIVATED\_SNAPSHOT\_NAME\>*

#### 2.4.2.2 Modify Snapshot Schedule
> Click **CHANGE** from **Action** manu to modify snapshot schedule.
> Settinge are same as described in [2.4.3 Creating Snapshot Schedule](#clusterVolume.xhtml#2.4.3 Creating Snapshot Schedule) section.  

+ **Volume Name**, **Schedule Name** can't be modified.
 While setting value is changed, **next schedule execution time** will recalculated based on modified settings value. 

#### 2.4.2.3 Delete Snapshot Schedule
> Click **DELETE** from **Action** manu to delete the snapshot. 

+ Snapshot created due to scheduling will not be deleted while deleting snapshot schedule.  

### 2.4.3 Creating Snapshot Schedule
> You can configuresnapshot schedule by clicking **Create Snapshot Schedule** located at the left-top corner of the page.   
> You can set various scheduling times using repeat cycle settings located at the left of **Create Snapshot Scheduling popup window**.
> The interval for the schedule can be set as hourly, daily, weekly, and monthly.

**General Settings**

|Category|Description|
|----|----|
|Schedule Name|The name of a schedule. <br>Enter the name in alphanumeric between 4 to 20 characters. Allowed special characters are "-" and "_". |
|Volume Name|The name of a cluster volume where the snapshot will be created.|
|Start Date|Set the date of the schedule on when it will start creating snapshots. The default setting will be the current date.|
|End Date|Set the date of the schedule on when it will stop creating snapshots.|
|No. of Snapshot|Set the maximum number of snapshot which the schedule will create.<br>If a snapshot is created over the limit, the oldest snapshots will be deleted. <br>The sum of all snapshots of every schedule in a single cluster volume cannot exceed 255.|
|Enable Scheduling|Configure the activation of a schedule. When deactivated, the snapshot will not be created.|
|Enable Snapshot|The snapshot will be activated when it is created. Please refer to [2.4.2.1.1 Snapshot Activating Deactivating](#clusterVolume.xhtml#2.4.2.1.1 Snapshot Activate Deactivate).|


##### 2.4.3.1 Hourly Snapshot Scheduling
> Set a schedule which will create a snapshot at the specific time every day.
> Please refer to the General Settings of [2.4.3 Creating Snapshot Schedule](#clusterVolume.xhtml#2.4.3 Creating Snapshot Schedule). 

|Category|Description|
|----|----|
|Time|Set the time between 00:00~23:00 to create a snapshot at the exact hour.|

##### 2.4.3.2 Daily Snapshot Scheduling
> Set a schedule which will create a snapshot of the selected day.
> The snapshot will be created at the scheduled time and day.  
> Please refer to the General Settings of [2.4.3 Creating Snapshot Schedule](#clusterVolume.xhtml#2.4.3 Creating Snapshot Schedule).

|Category|Description|
|----|----|
|Interval|Set how many daily intervals the schedule will be executed.|
|Time|Set the time between 00:00~23:00 to create a snapshot at the exact hour.|

##### 2.4.3.3 Weekly Snapshot Scheduling
> Set a schedule which will create a snapshot of the selected week.  
> The snapshot will be created at the scheduled time, day, and week.
> Please refer to the General Settings of [2.4.3 Creating Snapshot Schedule](#clusterVolume.xhtml#2.4.3 Creating Snapshot Schedule).

|Category|Description|
|----|----|
|Interval|Set how many weekly intervals the schedule will be executed.|
|Day|Set the day of when the schedule will be executed in the selected week.|
|Time|Set the time between 00:00~23:00 to create a snapshot at the exact hour.|

##### 2.4.3.4 Monthly Snapshot Scheduling
> Set a schedule which will create a snapshot of the selected month.  
> The snapshot will be created within the scheduled time, day, week, and month.
> Please refer to the General Settings of [2.4.3 Creating Snapshot Schedule](#clusterVolume.xhtml#2.4.3 Creating Snapshot Schedule).

|Category|Description|
|----|----|
|Interval|Set how many monthly intervals the schedule will be executed.|
|Week|Set the week of when the schedule will be executed in the selected month.|
|Day|Set the day of when the schedule will be executed in the selected week.|
|Time|Set the time between 00:00~23:00 to create a snapshot at the exact hour.|

### 2.3.4 Create Manual Snapshot
> You can create cluster volume's snapshot by clicking **Create Manual Snapshot** button located at the top-left of the page.

| Category 		| Description |
|-----			|------|
|Volume Name |Select cluster volume to create snapshot.|
|Snapshot Name		|Enter snapshot name which you want to create.|
|Max. no. of manual snapshot creatable	|Max **255** snapshots can be created per volume.|
