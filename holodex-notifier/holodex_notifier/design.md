# Holodex Notifier Implementation Plan

## I. Core Architecture (Flutter/Dart)

*   **UI Layer (Flutter):** Builds the user interface using Flutter widgets for settings and relies on system notifications managed by the Notification Manager.
*   **Application Layer (Dart):**
    *   **State Management (`flutter_riverpod`):** Manages UI state, user settings, and communication between UI and services.
    *   **Application Controller:** Central logic unit connecting Poller, Cache, User Settings, and Notification scheduling/dispatch.
*   **Domain Layer (Dart):** Contains core business logic, data models (`freezed` classes), and interfaces for services.
*   **Infrastructure Layer (Dart):**
    *   **API Interface Service (Background Poller):** Handles Holodex API communication via `dio`. Runs periodically using `flutter_background_service`.
    *   **Cache Service:** Persistent local storage using `drift` (high-level non-ORM wrapper for `sqflite`).
    *   **Settings Service:** Manages simple settings using `shared_preferences`.
    *   **Secure Storage Service:** Stores API key using `flutter_secure_storage`.
    *   **Notification Manager:** Manages scheduling, displaying, and cancelling system notifications using `flutter_local_notifications`.
    *   **Connectivity Service:** Checks network status using `connectivity_plus`.
    *   **Logging Service:** Uses `logger` for structured logging.

## II. User Interface (Settings Page - Android/Windows)

1.  **Framework:** Flutter SDK with Dart.
2.  **State Management:** Persistently store Poll Frequency, Grouping toggle, Delay toggle, API Key (securely), the state of the Global Switches (for new card defaults), and the list of added channels with their individual toggle states. Use `flutter_riverpod` for managing UI state, settings, and channel lists.

3.  **Layout:**
    *   Build the UI using standard Flutter widgets (`Scaffold`, `ListView`, `Card`, `Switch`, `Slider`, `TextField`, `DropdownButton`, etc.).
    *   **App Behavior Settings:** Widgets bound to Riverpod providers for Poll Frequency, Grouping, API Key visibility/input, Delay New Media.
        *   Poll Frequency Slider/Input (5min - 12hr, Default: 10 min).
        *   Notification Grouping Toggle (Default ON).
        *   API Key Input (hidden by default, revealed by button, with info text). Use secure storage (Android Keystore, Windows DPAPI). Store encrypted key in persistent settings (SharedPreferences/Settings).
        *   Delay New Media Until Scheduled Toggle (Default OFF).
    *   **Channel Management:**
        *   **Global Switches:** Four toggles (New Media, Mentions, Live, Update). These bulk-apply settings to all *currently added* channel cards AND set the default state for these toggles on *newly added* channel cards.
            * `Switch` widgets updating defaults in the Settings Service and iterating through existing channel settings via the Controller/Riverpod.
        *   **Channel Search:** Text input bar. Uses `/channels` endpoint. Implement throttling (e.g., ≥ 4 chars, 1-sec debounce after typing stops). Display results (avatar, name) in a dropdown/suggestion list.
            * `TextField` with debounce (`flutter_hooks` or `rxdart`) triggering API calls via Riverpod provider. Display results in an overlay/dropdown (`OverlayPortal` or similar).
        *   **Add Button:** Confirms selection from search results.
        *   **Channel Cards Area:** Displays added channels as cards.
            *   **Card Content:** Avatar (`photo`), Name (`name`), four toggles (New Media, Mentions, Live, Update - initialized from Global Switch defaults).
            *   **Interactions:** Drag-and-drop reordering, Remove button.
            * Use `flutter_reorderable_list` or similar for draggable cards. Each card displays channel info (`CachedNetworkImage` for avatar) and `Switch` widgets bound to specific channel settings via Riverpod.
    *   **Scheduled Notifications UI:**
        *   Displays upcoming scheduled live notifications in a scrollable list (`ListView`).
        *   Each entry shows channel avatar, name, stream title (`video.title`), scheduled start time (`start_scheduled` formatted as local time). 
        *   Includes a cancel button for each entry that triggers `NotificationManager.cancelScheduledNotification()` and updates the cache (`scheduled_live_notification_id = null`).
        *   Automatic updates via Riverpod provider that monitors CacheService changes (watches `CachedVideo` entries with `scheduled_live_notification_id != null`).
    *   **Background Process Status Panel**: 
        *   Status indicator badge (running/stopped) using `Chip` or custom widget bound to `flutter_background_service` state via Riverpod.
        *   Timeline displays: Last successful poll time (from `last_poll_time`), Next scheduled poll (calculated from Poll Frequency + last poll time).
        *   Manual poll button (`ElevatedButton`) that triggers immediate background service execution.
        *   Error display area (`Alert` or colored text) showing last error message from poller (stored in Riverpod state). 
        *   Auto-refresh mechanism using `Timer.periodic` or Riverpod `StreamProvider` to update status every 30 seconds.

4.  **Data Persistence:** Settings and channel configurations managed by Riverpod providers interacting with `shared_preferences` and the `drift` database via respective services. API key managed via `flutter_secure_storage`.

## III. API Interface Service (Background Poller)

1.  **Background Execution:** Use `flutter_background_service` configured for both Android (foreground service) and Windows (background task). Ensure singleton execution logic within the service setup.
2.  **Polling Trigger:** Schedule based on periodic execution via `flutter_background_service` "Poll Frequency" setting.
3.  **API Client:** Use `dio` for requests.
    *   **Interceptors:** Add interceptors for:
        *   Injecting the API Key (`X-APIKEY` header) from Secure Storage Service or fallback developer key.
        *   Logging requests/responses.
        *   Handling errors (see Error Handling section).
4.  **Polling Logic (per cycle):**
    *   Check connectivity using `connectivity_plus`. If offline, log and skip cycle.
    *   Get `last_poll_time` (timestamp of *start* of last successful poll) from persistent storage.
    *   Get `current_poll_time` (timestamp of *start* of current poll).
    *   Identify unique `subscribed_ids` (channels followed for New/Live/Update) from User Settings.
    *   Identify unique `mention_ids` (channels followed for Mentions) from User Settings.
    *   Combine unique IDs needed (`all_ids = subscribed_ids U mention_ids`).
    *   Fetch video data iteratively using `/videos` endpoint via `dio`, requesting `live_info` and `mentions`. Use `freezed` models for parsing responses.
        *   For each `id` in `all_ids`:
            *   Determine if this `id` is needed for subscriptions (`is_subscribed = id in subscribed_ids`) or mentions (`is_mentioned = id in mention_ids`).
            *   If `is_subscribed`: Call `/videos?channel_id={id}&include=live_info,mentions&from={last_poll_time}&limit=50&type=stream,clip,placeholder`. Add results to `results`.
            *   If `is_mentioned` AND *not* `is_subscribed` (to avoid duplicate calls): Call `/videos?mentioned_channel_id={id}&include=live_info,mentions&from={last_poll_time}&limit=50&type=stream,clip,placeholder`. Add results to `results`.
    *   Pass unique `results` list (deduplicated by `video.id`) to Application Controller.
    *   If processing succeeds (no exceptions thrown by Controller), store `current_poll_time` as the new `last_poll_time` in persistent storage.
5.  **Error Handling:** See Section IX. Transient network/server errors should be retried by `dio` interceptor (`dio_smart_retry` or custom). Persistent errors should be logged and potentially surfaced to the UI via Riverpod state.

## IV. Cache Service (`drift` / `sqflite`)

1.  **Storage:** Setup `drift` database for storing video cache.
2.  **Schema (`CachedVideo` Table):**
    *   `video_id` (TEXT, PRIMARY KEY)
    *   `status` (TEXT)
    *   `start_scheduled` (TEXT - ISO8601, nullable)
    *   `start_actual` (TEXT - ISO8601, nullable)
    *   `available_at` (TEXT - ISO8601) - Needed for pruning and New Media check.
    *   `certainty` (TEXT, nullable) - Possible values: 'certain', 'likely'. Assume 'certain' if null/missing.
    *   `mentioned_channel_ids` (TEXT - Store as JSON array string or in a separate relation table)
    *   `is_pending_new_media_notification` (BOOLEAN, Default: false)
    *   `last_seen_timestamp` (INTEGER - Unix timestamp)
    *   `scheduled_live_notification_id` (INTEGER, nullable) - ID for the scheduled platform notification.
    *   `last_live_notification_sent_time` (INTEGER - Unix timestamp, nullable) - To prevent rapid duplicate "Live".
3.  **Pruning:** Implement a daily background task (triggered via `flutter_background_service`) to delete stale entries based on `status` and `available_at`.
    *   Delete entries where `status == 'past'`.
    *   Delete entries where `available_at` is older than 4 days from the current time.

## V. Application Controller

1.  **Inputs:** `List<VideoFull>` from Poller, User Settings (via Riverpod/SettingsService), CacheService access, NotificationManager access.
2.  **Processing:**
    *   Initialize `notifications_to_dispatch = []`, `scheduled_tasks_to_update = []`.
    *   Get `current_system_time`.
    *   For each `video` in the list from Poller:
        *   Get `cached_video` from CacheService.
        *   Determine `is_certain`, `was_certain`, `is_delayed_new`.
            *   `is_certain = (video.certainty === 'certain' || video.certainty == null)`
            *   `was_certain = (cached_video != null && (cached_video.certainty === 'certain' || cached_video.certainty == null))` // Check previous certainty
            *   `is_delayed_new = UserSettings.delay_new_media_until_scheduled`
        *   `has_live_notification_scheduled = cached_video?.scheduled_live_notification_id != null`.
        *   **Detect Events & Schedule/Cancel Live Notifications:**
            *   **Live Scheduling Logic:**
                *   If user wants 'Live' notifications for `video.channel.id` AND `video.status === 'upcoming'` AND `video.start_scheduled != null`:
                    *   If `!has_live_notification_scheduled` OR `video.start_scheduled != cached_video.start_scheduled`:
                        *   If `has_live_notification_scheduled`, add cancellation for `cached_video.scheduled_live_notification_id` to `scheduled_tasks_to_update`.
                        *   Schedule a new timed notification via NotificationManager for `video.start_scheduled`. Get the `new_notification_id`. Update cache entry with `scheduled_live_notification_id = new_notification_id`.
                        *   *Note:* The NotificationManager handles the actual platform scheduling.
                *   Else if `has_live_notification_scheduled` AND (`video.status !== 'upcoming'` OR `video.start_scheduled == null`):
                    *   Add cancellation for `cached_video.scheduled_live_notification_id` to `scheduled_tasks_to_update`. Update cache entry `scheduled_live_notification_id = null`.
            *   **New Media Event:** Determine if a 'New Media' event occurred (as per previous logic: check cache null, age, delay setting, certainty). If yes, add to `notifications_to_dispatch`. Cancel any scheduled live notification for this video (it's now considered "known").
            *   **Pending New Media Trigger:** As before. If triggered, add to `notifications_to_dispatch`.
            *   **Live Event (Poll-Detected):** If (`cached_video == null` OR `cached_video.status !== 'live'`) AND `video.status === 'live'`:
                *   Check `last_live_notification_sent_time` to prevent duplicates within a short window (e.g., 2 mins).
                *   If okay to send, add 'Live' event to `notifications_to_dispatch`. Update `last_live_notification_sent_time` in cache.
                *   Cancel any potentially pending scheduled live notification via `scheduled_tasks_to_update`. Update cache entry `scheduled_live_notification_id = null`.
            *   **Update Event:** As before (check `start_scheduled` change, suppress if only certainty changes with delay enabled). If yes, add to `notifications_to_dispatch`. *Note: Live notification scheduling logic above handles schedule changes proactively.*
            *   **Mention Event:** As before (check new mentions, check user settings per mentioned channel). If yes, add specific 'Mention' event(s) to `notifications_to_dispatch`.

        *   **Update Cache:** Update the `CachedVideo` entry with latest data from `video`, including any changes to `is_pending_new_media_notification`, `scheduled_live_notification_id`, `last_live_notification_sent_time`, and `last_seen_timestamp`.
3.  **Dispatch Scheduled Task Updates:** Call NotificationManager methods to cancel/update any tasks listed in `scheduled_tasks_to_update`.
4.  **Grouping:** Apply grouping logic to `notifications_to_dispatch` based on user setting.
    *   `// TODO: Implement advanced collaboration-based grouping per readme.md V2`
    *   If `UserSettings.notification_grouping` is ON:
        *   Group entries in `notifications_to_send` by `video_data.id`.
        *   For each group, format for grouped display (pass grouped data containing list of events/targets to Notification Manager).
    *   Else (Grouping OFF):
        *   Pass each entry in `notifications_to_send` individually to Notification Manager.
5.  **Dispatch Notifications:** Pass the final (potentially grouped) list to NotificationManager for immediate display.
6.  **Error Signaling:** Catch exceptions during processing. Log errors. If critical, update UI state via Riverpod.

## VI. Notification Manager

1.  **Initialization:** Configure the plugin for Android and Windows (channels, permissions).
2.  **Methods:**
    *   `displayNotification(data)`: Takes processed notification data (single/grouped), fetches images (`flutter_cache_manager`), formats, and displays using `flutter_local_notifications`.
    *   `scheduleLiveNotification(videoId, channelId, scheduledTime)`: Generates a unique notification ID, creates a pending notification payload with verification data (video ID, expected time), and schedules it using the plugin's zoned schedule feature. Returns the notification ID.
    *   `cancelScheduledNotification(notificationId)`: Cancels a previously scheduled notification.
    *   `handleScheduledNotificationCallback(payload)`: (Called by the platform when a scheduled notification fires).
        *   Parse `payload` to get `videoId` and `expectedTime`.
        *   **Verification Step:** Quickly check CacheService (or potentially a very quick targeted API call if allowed in background):
            *   Is the video's *current* status 'live'?
            *   Did `start_actual` or `start_scheduled` occur close to `expectedTime` (within tolerance)?
            *   Was a 'Live' notification already sent recently (`last_live_notification_sent_time`)?
        *   If verification passes:
            *   Fetch latest video data from cache.
            *   Format and display the "Live" notification via `displayNotification`.
            *   Update `last_live_notification_sent_time` in cache.
        *   Log the outcome (sent, skipped-already-live, skipped-cancelled, skipped-failed-verification).
        *   Update `scheduled_live_notification_id = null` in cache for this video.
3.  **Image Caching:** Use `flutter_cache_manager` to download and cache channel/mention avatars efficiently.

## VII. Initial Target Platforms

*   Android
*   Windows

## VIII. Technology Stack Summary

*   **Language:** Dart
*   **Framework:** Flutter
*   **State Management:** `flutter_riverpod`
*   **HTTP Client:** `dio` (with `dio_smart_retry`)
*   **Background Execution:** `flutter_background_service`
*   **Database (Cache):** `drift` (over `sqflite`)
*   **Simple Settings:** `shared_preferences`
*   **Secure Storage:** `flutter_secure_storage`
*   **Notifications:** `flutter_local_notifications`
*   **Connectivity:** `connectivity_plus`
*   **Data Modeling:** `freezed`, `json_serializable`
*   **Image Caching:** `flutter_cache_manager`
*   **Logging:** `logger`
*   **Testing:** `flutter_test`, `integration_test`, `mockito` (or `mocktail`), `riverpod_test`

## IX. Error Handling, Debugging & Testing Strategy

1.  **Error Handling:**
    *   **Graceful Degradation:** Aim for resilience. API errors or background task failures should not crash the app. The UI should remain responsive.
    *   **API/Network Errors:** Use `dio` interceptors and `try-catch` blocks. Log detailed errors (HTTP status, URL, body snippet if possible, timestamp). Use retry mechanisms for transient errors (429, 5xx, network timeout).
    *   **Parsing/Data Errors:** Use `try-catch` around `freezed` model deserialization. Log the problematic data snippet if possible.
    *   **Background Service Errors:** Wrap main background logic in `try-catch`. Log exceptions using the `logger` service. Ensure the service reschedules itself even after failure.
    *   **Database/Storage Errors:** Catch exceptions during DB/preference operations. Log errors.
    *   **User-Facing Errors:**
        *   Use Riverpod state to reflect persistent error conditions (e.g., "API Unreachable", "Invalid API Key") in the UI settings page via non-modal indicators (e.g., `SnackBar`, banner).
        *   Provide clear error messages understandable to the user where possible.
        *   Include a unique error code/ID and timestamp in logged errors.
        *   Consider an "About" or "Debug" section with an option to view/copy/export logs for bug reporting.
2.  **Debugging:**
    *   Utilize Flutter DevTools for UI inspection, performance monitoring, and debugging.
    *   Implement comprehensive logging using the `logger` package, with different levels (debug, info, warning, error). Log key events, state changes, API calls, background task execution, errors.
    *   Conditional logging based on build mode (verbose logs in debug, essential logs in release).
3.  **Testing:**
    *   **Unit Tests (`flutter_test`):** Test individual functions, controller logic, data transformations, parsing logic. Mock dependencies (API client, cache, settings, notifications) using `mockito` or `mocktail`.
    *   **Widget Tests (`flutter_test`):** Test individual UI widgets and simple screen flows in isolation. Provide mock data via Riverpod overrides.
    *   **State Management Tests (`riverpod_test`):** Test Riverpod providers and state transitions.
    *   **Integration Tests (`integration_test`):** Test key end-to-end flows:
        *   Adding/removing a channel and verifying settings persistence.
        *   Simulating API poll responses and verifying cache updates and notification scheduling/dispatch (mock the NotificationManager display/scheduling).
        *   Testing background task initialization and execution cycle (mocking API/time).
    *   **Code Coverage:** Aim for high test coverage, especially for core logic (Controller, Services).