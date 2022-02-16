## 3.3 Group

### 3.3.1 About Group Management

> You can manage the group of a user which accesses the cluster volume through CIFS protocol.  
> The group permissions are compatible with the standard Unix tool such as chgrp.
> You can create, modify, and delete the group information.  

* **Category**

    | Category     		| Description      |
    | :---:    		| :---     |
    | **Group Name** 	|  View the name of a group. |
    | **Description** 	|  View the description which is entered while creating the group. |
    | **User Information** 	|  View the information on the user. |

+ **Tip**
    
    In Windows environment, it will be convenient to allow the access to a CIFS share for the group.   
    A group name must be at least 5 alphanumeric characters and symbols. However, it should not be starting with numbers.   
    You can use the search option on the top right of the list to browse the group by its ID and description.   

### 3.3.1 Creating Group
> Go to Account >> Group page and click **Create** button on the top left corner to execute the group creation wizard.
> Enter the details on the group, select the user, and press **OK** to complete the creation.  
> The created group will be affiliated to the local authentication domain and will be able to use the share through group access control when accessing through CIFS.  

* **Entering Group Information**
    
    | Category     	| Description      |
    | :---:    	| :---     |
    | **Group Name** | The name of a group. |
    | **Description** | The description of a group. |

* **Selecting User**
> Select one or more users by the checkbox on the left.

### 3.3.2 Deleting Group

> Select one or more group by the check box on the left to activate the **Delete** button.  
> Click **Delete** button to delete the selected group.  

+ **Note**
    
    When deleting the group, CIFS users will maintain the connection until it is disconnected.    
    The deleted group's file will preserve the information on the GID, in case if the new group is appointed to have the same GID to obtain the permission on the ownership of the file.

### 3.3.3 Modifying Group

> Select the checkbox on the left from the group list to activate **Modify** button for the group modification.  
> You can modify the group description and the user.

* **Contents**
    
    | Category     | Description      |
    | :---:    | :---     |
    | **Group Name** | Once the group ID is registered, it cannot be modified.  |
    | **Description** | The description of the group can be modified.  |

* **Modifying User Selection**
 
>  Select one or more user by the checkbox on the left of the user list to register.

+ **Note**
    
    Even after the modification, the old information will still be displayed until the CIFS user ends the connection.


