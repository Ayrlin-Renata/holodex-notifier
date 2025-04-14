# holodex-notifier

Holodex Notifier is an app available for mobile and desktop platforms which notifies the user about Holodex API events.

## User Interface
Holodex Notifier has a clean and simple modern user interface which allows the user to customize which events cause notifications. The UI features a single settings page, and the system notifications.

### App Behavior Settings
*  Poll Frequency: How often the app checks the holodex API for changes. 
    * Default: 10 minutes.
    * Minimum: 5 minutes.
    * Maximum: 12 hours.  
* Notification Grouping: Whether or not to group notifications caused by a single change to media.
    * Default: ON.
* API Key: The API Key to use for polling.
    * Default: Blank (Developer provided, not revealed to UI).
    * There is a button that expands a section with instructions on how to obtain an API Key.
* Delay New Media Until Scheduled: A switch
    * Allows the user to choose whether or not to delay New Media notifications for media which has an unknown start time until the start time is known. 

### Channel Notification Management
Users can search for and manage channel-specific notification preferences through an integrated search interface and interactive channel cards.

#### Global Switch Management
A panel of four switches allows the user to bulk edit all switches in the Channel Notification Cards for each notification type. They also set defaults for new channel cards that are created.

#### Channel Search & Selection
A universal search bar allows users to find Holodex channels. As they type, real-time suggestions appear in a drop-down list. Upon selecting a channel and confirming (via "Add" button or Enter key), the channel is added as a persistent card to the notification settings panel. Users may add multiple channels through repeated searches.

#### Channel Notification Cards
Each added channel appears as a visual card containing:
* Channel avatar/logo
* Channel name
* Four toggle switches for notification types:
    * New Media
        * Enable to notify when new content (streams, clips, etc.) is published to this channel
    * Channel Mentions
        * Enable to notify when this channel is mentioned in content from other channels
    * Live Alerts
        * Enable to notify when this channel starts broadcasting live
    * Schedule Updates
        * Enable to notify when this channel changes scheduled content start times

Users can:
* Reorder cards via drag-and-drop
* Remove cards using a delete icon

### Notifications
Notifications display the type of notification (New Media, Channel Mention, Live, or Update), the associated channel name and image (if possible on the platform), and the type, time, and title of the new media. This is arranged in the following manner for each type: 

**New Media Notification**
> Image: "[Channel Image]"  
> Title: "New [Media Type] - [Media Time] - [Channel Name]"  
> Content: "[Media Title]"

**Channel Mention Notification**
> Image: "[Channel Image]"  
> Title: "Mentioned in [Media Type] - [Media Time] - [Channel Name]"  
> Content: "[Media Title]"

**Live Notification**
> Image: "[Channel Image]"  
> Title: "🔴 [Media Type (all caps)] LIVE NOW - [Media Time] - [Channel Name]"  
> Content: "[Media Title]"

**Update Notification**
> Image: "[Channel Image]"  
> Title: "⚠️ Update for [Media Type] - [Media Time] - [Channel Name]"  
> Content: "[Media Title]"

#### Notification Grouping
If Notification Grouping is enabled, in order to reduce notification spam, some circumstances can result in notifications being grouped:
* The notifications are about media which involves channels that in a Collaboration at the time.
    * A Collaboration is determined based on several factors: 
        * If a media includes channel mentions of channels, those channels are considered to be in a collaboration at the start time of the media.
        * If other media mentions channels which are in a collaboration, and the start time is within an hour, and there is an at least 50% overlap in involved channels, those channels are in the same collaboration.
        * Multiple, seperate collaborations with different groups of channels can happen at the same time. 

**Notification Appearance**
Typically this means the channel name will appear like [Channel Name] +N where N is the number of other notifications grouped into the same notification, and the Content of the notification will additionally have a list of the other channel names.

## Architecture
### API Interface Service
Responsible for checking the API for information. Uses the Poll Rate setting to determine when to check. Must always run in the background on the device, making sure that there is only one instance. Queries the API about information regarding channels and events required for notifications by user settings.

The API key will be the developer's key by default, but will use the api key from the user settings if present. 

### Application Controller
Responsible for determining which notifications to send. Recieves information from the API Interface Service and compares it to the Cache while considering the user settings, to determine what Notification Events need to be assembled, and how to greet them. 

New Media is detected based on media not in the cache since the last successful poll. 

If media has a start time in the past, it will not cause a notification other than Live or Updated, and if it has finished airing it will not cause a Live notification. 

If the user has opted to delay unknown start time New Media notifications using the Delay New Media Until Scheduled switch, these Update Notifications are not sent for the time change when the media changes from unknown start time to known start time, so as to not duplicate notifications.

Live notifications will be scheduled based on the anticipated start time of the media, and updated based on the information retrieved during polling. If a live notification is incorrectly sent at an anticipated time, and a later update reveals a change that means it starts later, a new live notification will be sent based on the new anticipated time.

### Cache
Stores information about the known state of the API information, for comparison against new information. Only stores information necessary to make the determinations. 

