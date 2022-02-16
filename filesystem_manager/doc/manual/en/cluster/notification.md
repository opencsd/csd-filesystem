## 1.6 Email Settings
+ **Tip**

    You can receive the information on the events and tasks that occurred in the cluster by email.    
    If you set the Alert Level as ERROR or WARN, you can only be notified of the important information.    
    If the DNS or gateway settings were inappropriate, you will not be able to receive any emails.    
    Use **Send Test Mail** button to check whether you can receive the email.  

---

* **Checklist for the Email Configuration**  

    | Category        | Description                                  |
    | :----       | ------                                |
    | SMTP Server   | SMTP configuration on the email service you are currently using |
    | Authentication   | Authentication support such as SSL, TLS, and StartTLS       |
    | Alert Level   | Notification by email according to the alert level<br>Error/Warning/Info |
    | Notification   | The notification will only be sent once when the event or task occurred from the system |
    | Email Address | Email must follow RFC821 address format.<br> Name, <Email Address>  (e.g. AnyStore <admin@gluesys.com> ) |

### 1.6.1 **Email Settings**
* Check **Enable Email** on the top to activate email notification.
* Enter the following information on the activated page.

    | Category                   | Description  |
    | :---:                  | :--- |
    | **Admin Email Address** | Enter the email address where you will receive information on events and tasks occurred in the cluster. |
    | **Sender Email Address** | Enter the email address to reply. |
    | **SMTP Address**          | Enter the domain address of SMTP server. |
    | **SMTP Port**          | Enter SMTP port number of SMTP server. |
    | **Alert Level**          | Select the alert level you wish to receive by email. |
    | **SSL Authentication**           | Select security authentication method for the email. |
    | **SMTP Authentication**           | **SMTP ID** - Enter SMTP ID.<br> **SMTP Password** - Enter the password.<br> **Confirm SMTP Password** - Enter the same password to check once more. |

* Send Test Mail
 * If you click the button, a simple test mail will be sent to the registered administrator's email.
 * It is recommended to verify whether the email notification works properly.

* Save Email Settings
 * After the configuration, click **Save** button at the bottom.
 * The configuration will be saved to the cluster. Therefore, every event or task happened in any node will be notified by email.


--------
