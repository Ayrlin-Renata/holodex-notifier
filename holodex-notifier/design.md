# Holodex Notifier Implementation Plan

## I. Core Architecture

*   **UI:** Platform-specific front-end for settings and displaying notifications (indirectly via system).
*   **API Interface Service (Background Poller):** Handles all communication with the Holodex API, runs periodically in the background.
*   **Cache:** Persistent local storage for video state comparison.
*   **Application Controller:** Central logic unit connecting the Poller, Cache, User Settings, and Notification dispatch.
*   **Notification Manager:** Platform-specific handler for creating and displaying system notifications.

## II. User Interface (Settings Page - Android/Windows)

1.  **Frameworks:** Utilize native or cross-platform frameworks suitable for Android (Jetpack Compose recommended) and Windows (WinUI 3/MAUI recommended).
2.  **Layout:**
    *   **App Behavior Settings:**
        *   Poll Frequency Slider/Input (5min - 12hr, Default: 10 min).
        *   Notification Grouping Toggle (Default ON).
        *   API Key Input (hidden by default, revealed by button, with info text). Use secure storage (Android Keystore, Windows DPAPI). Store encrypted key in persistent settings (SharedPreferences/Settings).
        *   Delay New Media Until Scheduled Toggle (Default OFF).
    *   **Channel Management:**
        *   **Global Switches:** Four toggles (New Media, Mentions, Live, Update). These bulk-apply settings to all *currently added* channel cards AND set the default state for these toggles on *newly added* channel cards.
        *   **Channel Search:** Text input bar. Uses `/channels` endpoint. Implement throttling (e.g., ≥ 4 chars, 1-sec debounce after typing stops). Display results (avatar, name) in a dropdown/suggestion list.
        *   **Add Button:** Confirms selection from search results.
        *   **Channel Cards Area:** Displays added channels as cards.
            *   **Card Content:** Avatar (`photo`), Name (`name`), four toggles (New Media, Mentions, Live, Update - initialized from Global Switch defaults).
            *   **Interactions:** Drag-and-drop reordering, Remove button.
3.  **State Management:** Persistently store Poll Frequency, Grouping toggle, Delay toggle, API Key (securely), the state of the Global Switches (for new card defaults), and the list of added channels with their individual toggle states (e.g., using Room DB/SQLite or platform settings).

## III. API Interface Service (Background Poller)

1.  **Background Execution:**
    *   **Android:** Use `WorkManager` for reliable, battery-conscious background execution, ensuring only one worker instance runs.
    *   **Windows:** Use a Background Task or potentially a Windows Service for persistent operation. Ensure singleton execution.
2.  **Polling Trigger:** Schedule based on "Poll Frequency" setting.
3.  **API Key:** Use user-provided key if present and valid, otherwise fall back to the embedded developer key. Include `X-APIKEY` header in all API requests.
4.  **Polling Logic (per cycle):**
    *   Get `last_poll_time` (timestamp of *start* of last successful poll) from persistent storage.
    *   Get `current_poll_time` (timestamp of *start* of current poll).
    *   Identify unique `subscribed_ids` (channels followed for New/Live/Update) from User Settings.
    *   Identify unique `mention_ids` (channels followed for Mentions) from User Settings.
    *   Combine unique IDs needed (`all_ids = subscribed_ids U mention_ids`).
    *   `results = []`
    *   For each `id` in `all_ids`:
        *   Determine if this `id` is needed for subscriptions (`is_subscribed = id in subscribed_ids`) or mentions (`is_mentioned = id in mention_ids`).
        *   If `is_subscribed`: Call `/videos?channel_id={id}&include=live_info,mentions&from={last_poll_time}&limit=50&type=stream,clip,placeholder`. Add results to `results`.
        *   If `is_mentioned` AND *not* `is_subscribed` (to avoid duplicate calls): Call `/videos?mentioned_channel_id={id}&include=live_info,mentions&from={last_poll_time}&limit=50&type=stream,clip,placeholder`. Add results to `results`.
    *   Pass unique `results` list (deduplicated by `video.id`) to Application Controller.
    *   If processing succeeds (acknowledged by Controller), store `current_poll_time` as the new `last_poll_time` in persistent storage.
5.  **Network & Error Handling:**
    *   Check network connectivity before initiating calls. If offline, gracefully halt polling and reschedule/wait for connectivity restoration without generating user-facing errors.
    *   Handle HTTP errors (e.g., 4xx, 5xx). Implement retry logic with exponential backoff specifically for rate limits (429) and transient server errors (5xx).
    *   Catch JSON parsing errors or unexpected API response formats.
    *   If non-transient errors persist after retries (e.g., 401 Unauthorized, 403 Forbidden, persistent 404s, malformed data), log the error and signal the Application Controller to notify the user via the UI (e.g., a non-intrusive, persistent error indicator in the settings).

## IV. Cache

1.  **Storage:** Use a local database (Android Room, SQLite wrapper for Windows).
2.  **Schema:** A table `CachedVideos` with columns:
    *   `video_id` (TEXT, PRIMARY KEY)
    *   `status` (TEXT)
    *   `start_scheduled` (TEXT - ISO8601, nullable)
    *   `start_actual` (TEXT - ISO8601, nullable)
    *   `available_at` (TEXT - ISO8601) - Needed for pruning and New Media check.
    *   `certainty` (TEXT, nullable) - Possible values: 'certain', 'likely'. Assume 'certain' if null/missing.
    *   `mentioned_channel_ids` (TEXT - Store as JSON array string or in a separate relation table)
    *   `is_pending_new_media_notification` (BOOLEAN, Default: false)
    *   `last_seen_timestamp` (INTEGER - Unix timestamp)
3.  **Pruning:** Implement a daily background task (e.g., via WorkManager/Scheduled Task):
    *   Delete entries where `status == 'past'`.
    *   Delete entries where `available_at` is older than 4 days from the current time.

## V. Application Controller

1.  **Inputs:** List of `VideoFull` objects from Poller, current User Settings, access to Cache.
2.  **Processing:**
    *   Initialize `notifications_to_send = []`.
    *   Get `current_system_time`.
    *   For each `video` in the list from Poller:
        *   `cached_video = Cache.get(video.id)`
        *   `event_type = null`
        *   `relevant_channel_id = video.channel.id` // Default for New/Live/Update
        *   `is_certain = (video.certainty === 'certain' || video.certainty == null)`
        *   `was_certain = (cached_video != null && (cached_video.certainty === 'certain' || cached_video.certainty == null))` // Check previous certainty
        *   `is_delayed_new = UserSettings.delay_new_media_until_scheduled`

        *   **Detect Event:**
            *   **New Media:** If `cached_video` is null:
                *   // Check if video is too old/already finished
                *   If `video.status === 'past'` OR `current_system_time > (parse(video.available_at) + 16 hours)`:
                    *   Skip; update cache only.
                *   // Handle delay for uncertain start time
                *   Else if `!is_certain` AND `is_delayed_new`:
                    *   Do not set `event_type` yet; update cache with `is_pending_new_media_notification = true`.
                *   Else:
                    *   Set `event_type = 'New Media'`.
            *   **Pending New Media Trigger:** If `cached_video` exists AND `cached_video.is_pending_new_media_notification` was true AND `is_certain`:
                *   Set `event_type = 'New Media'`. Clear pending flag in cache update.
            *   **Live:** If `cached_video` exists AND `cached_video.status !== 'live'` AND `video.status === 'live'`:
                *   Set `event_type = 'Live'`.
            *   **Update:** If `cached_video` exists AND `video.start_scheduled !== cached_video.start_scheduled`:
                *   // Suppress update notification if it's just the uncertainty changing *and* user delays new media
                *   If `is_delayed_new` AND `!was_certain` AND `is_certain`:
                     *   Skip event; this change triggers the "Pending New Media" notification instead.
                *   Else:
                    *   Set `event_type = 'Update'`.
            *   **Mention:** If `cached_video` exists:
                *   Extract `new_mention_ids` by comparing `video.mentions` list's IDs with `cached_video.mentioned_channel_ids`.
                *   For each `m_id` in `new_mention_ids`:
                    *   If `UserSettings.isMentionEnabledFor(m_id)`:
                        *   Add `{ video_data: video, event_type: 'Mention', target_channel_id: m_id }` to `notifications_to_send`. (Handled separately from the single `event_type` logic).

        *   **Check User Settings (for New/Live/Update):** If `event_type` is set (`New Media`, `Live`, `Update`):
            *   If `UserSettings.isNotificationEnabledFor(relevant_channel_id, event_type)`:
                *   Add `{ video_data: video, event_type: event_type, target_channel_id: relevant_channel_id }` to `notifications_to_send`.

        *   **Update Cache:** Store/Update `video` data (relevant fields from Schema) in the Cache, setting `is_pending_new_media_notification` as determined above and updating `last_seen_timestamp`.

3.  **Grouping (Simple V1):**
    *   `// TODO: Implement advanced collaboration-based grouping per readme.md V2`
    *   If `UserSettings.notification_grouping` is ON:
        *   Group entries in `notifications_to_send` by `video_data.id`.
        *   For each group, format for grouped display (pass grouped data containing list of events/targets to Notification Manager).
    *   Else (Grouping OFF):
        *   Pass each entry in `notifications_to_send` individually to Notification Manager.

4.  **Error Signaling:** If Poller signals a persistent API error state, update a state variable (e.g., LiveData/StateFlow) observed by the UI to display the error indicator.

## VI. Notification Manager

1.  **Platform Implementation:**
    *   **Android:** Use `NotificationManagerCompat`, handle Notification Channels, icons, PendingIntents for opening the app/video, large icons.
    *   **Windows:** Use `ToastNotificationManager`, construct XML payloads for toast notifications, handle activation.
2.  **Input:** Formatted notification data (individual or grouped) from Controller. Contains `video_data`, `event_type`, and `target_channel_id` (or a list of event/target pairs if grouped).
3.  **Tasks:**
    *   Asynchronously fetch the relevant channel photo (`video.channel.photo` or `mention.photo` depending on `target_channel_id`). Implement local image caching.
    *   Construct notification title and content based on `event_type` and `video_data` as specified in `readme.md`. Use `target_channel_id` to determine which channel's name/image is primarily displayed (especially for Mentions).
    *   If grouped, adjust title (e.g., `[Primary Channel Name] +N`) and format content to summarize the multiple events/targets for that single video ID.
    *   Display the notification using platform APIs.

## VII. Initial Target Platforms

*   Android
*   Windows