## 1.4 Events


> Event page provides users the integrated information on events and alerts that happened in the cluster and the tasks done by cluster management software.  
> The page shows a list of event logs and the list of ongoing tasks.  
> You can sort only the parts that need confirmation, or can see more results on one page by selecting the number of events that will be displayed on the list.  
>

 **Contents**

| Category          | Location      |  Description        |
| :---            | ---       | ---          |
| Event History | Top      | Able to browse event logs that occurred from cluster and node |
| Task       | Bottom      | Lists ongoing tasks and its status |

### 1.4.1 Event History

 *   About Event History
  * Event History list gathers information on the occurred event and displays each events in a single row.
  * You can set the search conditions using the search tool from the top of the list.
  * You can browse the page by number by using the page control button from the bottom of the list.
  * The column names on the header row are Status, Range, Type, Category, Time, and Contents.

    | Category            | Description |
    | :---:           | :--- |
    | **Status** | Shows one of the three event level: Error, Warning, and Info.<br>The color of each level are shown as red, yellow, and green. |
    | **Range** | View the range where the event occurred. If it was occurred in the node, it will show the node's ID. If it is the cluster, it will show the text, "cluster". |
    | **Type** | View whether the event happened from the monitoring component or the management component. |
    | **Category** | View which functions the event is related and if the event does not have any type, it will show the text "DEFAULT".  |
    | **Time** | Shows the time when the event occurred. Displayed as "yyyy/mm/dd  hh : mm : ss". |
    | **Contents** | Describes the details of the event. |

 * Sorting Events
  * The default option is to sort the events in reverse chronological order but can be modified.
  * If you click one of the categories from the header row, the data below will be sorted in alphabetical or chronological order depending on its content.

 * Event Details
  * Each event will show its details as you select.
  * The details will be displayed in a form of a dictionary of key-value.
  * Categories are ID, Scope, Level, Category, Message, Details, Time, and Quiet.

    | Category            | Description |
    | :---:           | :--- |
    | **ID** | The identifier of the event. |
    | **Scope** | View the location where the event occurred. When it happened in a node, it will show the node ID and if it is the cluster, it will show the text, "cluster". |
    | **Level** | Shows one of the three event level: Error, Warning, and Info. |
    | **Type** | View whether the event happened from the monitoring component or the management component. |
    | **Category** |  View which functions the event is related and if the event does not have any type, it will show the text "DEFAULT".  |
    | **Message** | The text describing the content of the event. |
    | **Details** | Displays more information on the event than Message. It is shown in a form of a dictionary of key-value. |
    | **Time** | Shows when the event occurred. Displayed as "yyyy/mm/dd  hh : mm : ss". |
    | **Quiet** | If the value is not 0, it will be displayed as an event but will not be informed by email. |


### 1.4.2 Task Status

 * About Task Status
  * Located on the Event History page.
  * View the progress and unsolved issues on the task operated by the cluster management software.
  * The contents of the header row are Status, Start Time, End Time, Contents, Range, Type, and Progress.
  * You can browse the page by number by using the page control button from the bottom of the list.

    | Category            | Description |
    | :---:           | :--- |
    | **Status** | Shows one of the three task level: Error, Warning, and Info.<br>The color of each level are shown as red, yellow, and green. |
    | **Start Time** | Shows the start time of a task or the issue.<br>Displayed as "yyyy/mm/dd  hh : mm : ss". |
    | **End Time** | Shows the end time of a task.<br>As for the issues, the section itself will disappear not having the end time when the issue is solved.<br>Displayed as "yyyy/mm/dd  hh : mm : ss". |
    | **Contents** | View the content of a task.<br>Displays the contents of the process in the background by the cluster management software<br>or the issues remaining in the cluster. |
    | **Range** | View the location where the task or the issue happened.<br>When it happened in a node, it will show the node ID and if it is the cluster, it will show the text, "cluster". |
    | **Type** | View which functions the task is related and if the task does not have any type, it will show the text "DEFAULT". |
    | **Progress** | View the progress of a task in percentage.<br>When it is an issue, it will be displayed as 0%. |


 * Sorting Tasks
  * The default option is to sort the events in alphabetical order but can be modified.
  * If you click one of the categories from the header row, the data below will be sorted in alphabetical or chronological order depending on its content.

 * Task Details
  * Each task will show its details as you select.
  * The details will be displayed in a form of a dictionary of key-value.
  * Categories are Scope, Level, Category, Message, Details, Time, and Quiet.

    | Category            | Content |
    | :---:           | :--- |
    | **Scope** | View the location where the task has been processed. When it happened in a node, it will show the node ID and if it is the cluster, it will show the text, "cluster". |
    | **Level** | Shows one of the three task level: Error, Warning, and Info. |
    | **Category** | View which functions the task is related and if the task does not have any type, it will show the text "DEFAULT". |
    | **Message** | The text describing the content of the task. |
    | **Details** | Displays more information on the task than Message. It is shown in a form of a dictionary of key-value. |
    | **Start** | Shows when the task has started. Displayed as "yyyy/mm/dd  hh : mm : ss". |
    | **Finish** | Shows when the task has ended. Displayed as "yyyy/mm/dd  hh : mm : ss".<br>When the task has not yet finished, the value will be "null". |
    | **Quiet** | If the value is not 0, it will be displayed as an event but will not be informed by email. |
