## 3.2 User

### 3.2.1 About User Menu
> Use CIFS service to manage the user information which can access the cluster volume.  
> If the service is based on Windows, administrators can manage the service using the local or active directory authentication.  
> The user function is based on **local authentication**.

* **Contents**
    
    | Category            	| Description  |
    | :---:           	| :--- |
    | **User ID**		| View the registered account name on the cluster. |
    | **Description** 	| View the description which is entered while creating the user. |
    | **Home Directory** 	| View the path of the user's home directory. |
    | **Email** 		| View the registered email. |
    | **Group Information** 		| View the information on the group where the user belongs to.<br> &nbsp;&nbsp;&nbsp;&nbsp; **Group Name** - View the group name which is entered while creating the group.<br> &nbsp;&nbsp;&nbsp;&nbsp; **Group Description** - View the description which is entered while creating the group.<br> &nbsp;&nbsp;&nbsp;&nbsp; **Authentication** - View the authentication which is registered while creating the group. |

+ **Tip**
    
    If it is hard to find each local users from the list, use the search option from **User Information** list to browse the user by user ID, email, and the description.

 ---

- **NFS and Local User Permission**
    
    When connecting to NFS, the file permission will be created due to the permission of the **accessed host's user ID and group ID**.   
    In this case, it can be mixed with the user ID and group ID appointed by AnyStor-E's local authentication.    
    To avoid the crash, it is not recommended to use the same volume as CIFS/NFS in case of the service that needs permission control.  
 
### 3.2.2 Creating User
> Go to Account >> User page and click **Create** button in the top left corner to execute the user creation wizard.  
> Enter the details on the user, select the group, and press **OK** to complete the creation.  
> The created user will be affiliated to the local authentication domain and will be able to use the share through user access control when accessing through CIFS.

+ **Tips**
    
    IDs contain at least 5 characters and cannot start with numbers.    
    You must enter the email address of a user and must use the standard form (e.g. example@example.com).   
    Passwords contain at least 5 alphanumeric characters.
    Group session can be skipped.  

---

* **Entering User Information**
    
    | Category            	| Description  |
    | :---:           	| :--- |
    | **User ID** 	| An account name must contain at least 5 alphanumeric characters. |
    | **Description** 	| Enter the description of the user. This part can be skipped. |
    | **Email** 		| Enter the email address of a user. |
    | **Password** 		| The password for a user's account contains at least 4 alphanumeric characters. |
    | **Confirm Password** 	| Enter the same password to check once more. |

* **Selecting Group**
    
    | Category            	| Description  |
    | :---:           	| :--- |
    | **Group Name** 	| View the name of the group. |
    | **Description** 	| View the description of the group. |
    | **Authentication** 		| View the information on the authentication of the group.    |

+ **Tips**
    
    A user can be in multiple groups.    
    You can browse the group you are looking for from the search panel on the top of the list.    
    If there is a crash between users and groups with the CIFS share access permission, the restriction on the access permission will be prioritized, therefore it is recommended to separate groups and users in this matter.

### 3.2.3 Deleting User

> Select the checkbox on the left from the user list to activate the **Delete** button.  
> You can delete multiple users by selecting more than one checkbox on the left.   

+ **Note**
    
    When deleting the user, CIFS users will maintain the connection until it is disconnected.    
    The deleted user's file will preserve the information on the UID, in case if the new user is appointed to have the same UID to obtain the permission on the ownership of the file.

### 3.2.4 Modifying User

> Select the checkbox on the left from the user list to activate **Modify** button for the user modification.    
> You can modify its description, email address, password, and the group.
 
* **Contents**
    
    | Category            	| Description  	|
    | :---:           	| :--- 		|
    | **User ID** 	|Once the user ID is registered, it cannot be modified. |
    | **Description** 	|The description of the user can be modified.  |
    | **Email** 		|The email address of the user can be modified. |
    | **Password** 		|The password on the user can be modified. If not entered, it will use the previous password.  |
    | **Confirm Password** 	|Enter the same password to check once more. |

* **Modifying Group Selection**

> Select one or more group by the checkbox on the left of the group list to reorganize where the user will belong to.

+ **Note**
    
    Even after the modification, the old information will still be displayed until the CIFS user ends the connection.

  
