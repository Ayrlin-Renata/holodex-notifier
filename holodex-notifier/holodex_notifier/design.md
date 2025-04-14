# Holodex Notifier Implementation Plan (v2 - Reflecting Current State & New UI)

## I. Core Architecture (Flutter/Dart)

*   **UI Layer (Flutter):** Builds the user interface using Flutter widgets. State is managed reactively using `flutter_riverpod`. Key components include screens for different sections and reusable card widgets.
*   **Application Layer (Dart):**
    *   **State Management (`flutter_riverpod` / `hooks_riverpod`):** Manages UI state, application settings, channel data, background status, and communication between UI and services using various providers (`StateProvider`, `FutureProvider`, `StateNotifierProvider`, `StreamProvider`).
    *   **Application Controller (`AppController`):** Central logic unit connecting UI actions (button presses, switch toggles) to service operations. Orchestrates tasks like adding/removing channels, applying global settings, and updating individual channel settings, including related notification cleanup/scheduling logic.
*   **Domain Layer (Dart):** Contains core business logic definitions, data models (using `freezed` for immutability and serialization), and abstract interfaces (`IApiService`, `ICacheService`, etc.) defining contracts for infrastructure services.
*   **Infrastructure Layer (Dart):** Provides concrete implementations of domain interfaces:
    *   **API Service (`HolodexApiService`):** Handles Holodex API communication via `dio`, including interceptors for API key injection and logging. Implements logic for fetching videos and searching channels (using `/search/autocomplete`).
    *   **Cache Service (`DriftCacheService`):** Persistent local storage for video data using `drift` (on top of `sqflite`). Manages `CachedVideo` entities.
    *   **Settings Service (`SharedPrefsSettingsService`):** Manages application settings and channel subscription list using `shared_preferences`. Delegates API key storage to Secure Storage. Handles JSON serialization for complex settings.
    *   **Secure Storage Service (`FlutterSecureStorageService`):** Securely stores sensitive data like the API key using platform-specific mechanisms (`flutter_secure_storage`).
    *   **Notification Service (`LocalNotificationService`):** Manages scheduling, displaying, and cancelling system notifications using `flutter_local_notifications`. Handles platform setup (channels, permissions), image caching (`flutter_cache_manager`), and notification tap events.
    *   **Background Polling Service (`BackgroundPollerService`):** Manages the background polling process using `flutter_background_service`. Handles initialization, starting/stopping, and configuration for foreground service behavior on Android. The core polling logic runs within this service's separate isolate.
    *   **Connectivity Service (`ConnectivityPlusService`):** Checks network status using `connectivity_plus`.
    *   **Logging Service (`LoggerService`):** Uses the `logger` package for structured logging across the application, including the background isolate.
    *   **Database (`AppDatabase`):** The `drift` database definition, including table schemas (`CachedVideos`), type converters, migrations, and DAOs/query methods.

*   **Isolate Communication:** The background service (`BackgroundPollerService`) runs in a separate isolate. It uses `flutter_background_service`'s `invoke` mechanism for simple commands (stop, trigger poll) and potentially for receiving settings updates. It utilizes a dedicated `ProviderContainer` initialized with necessary service providers (overriding `isolateContextProvider` to `background`). A readiness flag (`main_services_ready` in `SettingsService`) ensures the background isolate waits for critical main isolate services (like `NotificationService`) to be initialized before proceeding.

## II. User Interface (Multi-Page Layout - Android/Windows)

1.  **Framework:** Flutter SDK with Dart.
2.  **State Management:** Riverpod manages UI state, settings, channel lists, search results, scheduled notifications, and background status. Data is persisted via infrastructure services.
3.  **Navigation:** A `BottomNavigationBar` provides access to three main pages:
    *   **Page 1: Scheduled (Default):** Displays upcoming scheduled notifications.
    *   **Page 2: Channels:** Allows searching, adding, and managing subscribed channels and their notification settings.
    *   **Page 3: Settings:** Contains application behavior settings and background process status.
4.  **Page Content & Functionality:**
    *   **Page 1: Scheduled (`ScheduledNotificationsCard` content)**
        *   Displays upcoming scheduled live stream notifications fetched from `CacheService` via `scheduledNotificationsProvider` (`StateNotifierProvider` wrapping `AsyncValue<List<CachedVideo>>`).
        *   Each entry shows channel avatar (`channelAvatarUrl`), name (`channelName`), stream title (`videoTitle`), and scheduled start time (`start_scheduled` formatted). Uses `CachedNetworkImage`.
        *   Includes a cancel button per entry, triggering cancellation via `NotificationService` and cache update via `CacheService`, handled by `AppController` or directly in the widget via providers.
        *   Updates automatically based on cache changes (or manual refresh).
        *   **Refresh:** Pull-to-refresh triggers `ref.read(scheduledNotificationsProvider.notifier).fetchScheduledNotifications(isRefreshing: true)`.
    *   **Page 2: Channels (`ChannelManagementCard` content)**
        *   **Global Defaults:** Four `FilterChip` widgets (New, Mentions, Live, Update) bound to simple `StateProvider`s (`global...DefaultProvider`). An "Apply Defaults" button triggers `AppController.applyGlobalDefaultsToAllChannels`.
        *   **Channel Search:** `TextField` bound to `channelSearchQueryProvider`. Uses `debouncedChannelSearchProvider` (`FutureProvider`) with a debounce mechanism to call `ApiService.searchChannels` (currently using autocomplete endpoint). Displays results (`Channel`) considering loading/error states (`asyncSearchResults.when`). Handles `ApiKeyRequiredException`. Shows an "Add" button per result if not already added, triggering `AppController.addChannel`.
        *   **Added Channel List:** Displays added channels (`channelListProvider`) using `ChannelSettingsTile` widgets within a `ReorderableListView`. Provides drag-and-drop reordering via `ChannelListNotifier.reorderChannels`.
            *   `ChannelSettingsTile`: Shows channel avatar, name, individual notification `FilterChip` toggles (bound to `ChannelListNotifier`), and a "Remove" button (with confirmation dialog) triggering `AppController.removeChannel`.
        *   **Refresh:** Pull-to-refresh triggers `ref.read(channelListProvider.notifier).reloadState()`.
    *   **Page 3: Settings (`AppBehaviorSettingsCard` + `BackgroundStatusCard` content)**
        *   **App Behavior:** (`AppBehaviorSettingsCard`)
            *   Notification Grouping Toggle (`SwitchListTile` bound to `notificationGroupingProvider` and `SettingsService`).
            *   Delay New Media Toggle (`SwitchListTile` bound to `delayNewMediaProvider` and `SettingsService`).
            *   Poll Frequency Slider (`Slider` bound to `pollFrequencyProvider` and `SettingsService`, range 5min-12hr, default 10min). Persists `onChangeEnd`.
            *   API Key Input (`TextField` within `ListTile`, using local `useState` for visibility/editing state, bound to `apiKeyProvider` and `SettingsService` via `SecureStorageService`).
        *   **Background Status:** (`BackgroundStatusCard`)
            *   Displays service status (Running/Stopped `Chip`), last successful poll time, next calculated poll time, and last error message using `backgroundServiceStatusStreamProvider` (`StreamProvider` updating periodically and watching `backgroundLastErrorProvider`).
            *   "Poll Now" button invokes `'triggerPoll'` on the background service.
            *   Includes a "Clear Error" button.
        *   **Refresh:** No pull-to-refresh. Status card updates periodically.
5.  **Data Persistence:** Settings and channel configurations managed by Riverpod providers interacting with `SharedPrefsSettingsService` (which uses `shared_preferences` and `SecureStorageService`). Video cache managed by `DriftCacheService`.

## III. API Interface Service (Background Poller)

1.  **Background Execution:** Uses `flutter_background_service`. Configured as an Android foreground service (`dataSync` type) with a low-importance notification channel (`holodex_notifier_background_service`). Enabled for `autoStartOnBoot`.
2.  **Isolate Setup:**
    *   Runs in a dedicated isolate via `onStart` entry point.
    *   Initializes `DartPluginRegistrant`.
    *   Creates a `ProviderContainer` with overrides (setting `IsolateContext.background`).
    *   Initializes `LoggingService`.
    *   Sets up listeners for `invoke` calls (`stopService`, `triggerPoll`, `updateSetting`).
    *   **Readiness Check:** Enters a loop waiting for `SettingsService.getMainServicesReady()` to return true, ensuring main isolate services (esp. `NotificationService`) are ready before proceeding.
3.  **Polling Trigger:**
    *   Periodically via `Timer.periodic` based on resolved `currentPollFrequency` from `SettingsService`.
    *   Manually via `'triggerPoll'` invoke from UI.
    *   A simple lock (`isPolling`) prevents concurrent poll cycles.
4.  **API Client:** Uses `dio` instance obtained via the background `ProviderContainer`. `ApiKeyInterceptor` handles API key retrieval from `SettingsService`.
5.  **Polling Logic (`_executePollCycle`):**
    *   Resolves necessary services (`Logging`, `Settings`, `Connectivity`, `API`, `Cache`, `Notification`) from the background `ProviderContainer`.
    *   Checks connectivity (`ConnectivityService`). Skips if offline.
    *   Gets `lastPollTime` from `SettingsService` (or defaults to lookback).
    *   Gets current subscribed channels (`ChannelSubscriptionSetting`) from `SettingsService`. Skips API call if none.
    *   Prepares `subscribedIds` and `mentionIds` sets.
    *   Fetches video data using `ApiService.fetchVideos` (which handles iterative calls per channel/mention ID) with `from=lastPollTime`, including `live_info` and `mentions`.
    *   Processes fetched `VideoFull` results:
        *   For each `video`, calls `_processVideoUpdate`.
        *   `_processVideoUpdate`:
            *   Gets cached state (`CacheService.getVideo`).
            *   Resolves needed services from container (logger, cache, notification, settings).
            *   Determines event conditions based on fetched vs cached state (`_ProcessingState` helper class: `isNew`, `isCertain`, `statusChanged`, `scheduleChanged`, `becameCertain`, `mentionsChanged`, `wasPendingNewMedia`).
            *   Calls event-specific helpers (`_handleLiveScheduling`, `_handleNewMediaEvent`, etc.).
            *   These helpers determine actions based on user settings and state changes, adding `NotificationInstruction`s to dispatch list and notification IDs to cancel list. Crucially, they interact with the *resolved* `NotificationService` instance for scheduling/cancellation calls *if* necessary within the helper logic (e.g., `_handleLiveScheduling`).
            *   Passively updates channel avatar URL in `SettingsService`.
            *   Returns a `VideoProcessingResult` containing the `CachedVideosCompanion` to upsert, notifications to dispatch, and cancellations needed.
        *   Accumulates `VideoProcessingResult`s from all videos.
    *   Performs **batch database upsert** (`db.batch`) for all collected `CachedVideosCompanion`s *after* processing all videos.
    *   Dispatches accumulated notification cancellations (`_dispatchCancellations`) and immediate notifications (`_dispatchNotifications`) via `NotificationService` *after* the database batch write succeeds.
    *   Updates `backgroundLastErrorProvider` state for UI feedback.
    *   If cycle succeeds, updates `lastPollTime` in `SettingsService`.
6.  **Error Handling:** Catches errors during the poll cycle, logs them, updates `backgroundLastErrorProvider`. Retry logic for transient errors is handled by `dio` interceptors (if configured). Uses `ILoggingService` within the background isolate. Unhandled initialization errors stop the service.
7.  **Settings Update:** Listens for `'updateSetting'` invoke (currently only handles `pollFrequency`) to update the `Timer.periodic` interval.

## IV. Cache Service (`drift` / `sqflite`)

1.  **Storage:** `drift` database (`AppDatabase`) initialized in `main.dart` (or background isolate entry point) via `openConnection()`. Uses `holodex_notifier_db.sqlite` in app documents directory.
2.  **Schema (`CachedVideos` Table - v1):**
    *   `video_id` (TEXT, PRIMARY KEY)
    *   `channel_id` (TEXT, Default: 'Unknown')
    *   `status` (TEXT) - 'new', 'upcoming', 'live', 'past', 'missing'
    *   `start_scheduled` (TEXT - ISO8601, nullable)
    *   `start_actual` (TEXT - ISO8601, nullable)
    *   `available_at` (TEXT - ISO8601)
    *   `certainty` (TEXT, nullable) - 'certain', 'likely'
    *   `mentioned_channel_ids` (TEXT, Default: '[]', `StringListConverter`)
    *   `video_title` (TEXT, Default: 'Unknown Title')
    *   `channel_name` (TEXT, Default: 'Unknown Channel')
    *   `channel_avatar_url` (TEXT, nullable)
    *   `is_pending_new_media_notification` (BOOLEAN, Default: false)
    *   `last_seen_timestamp` (INTEGER - Unix ms)
    *   `scheduled_live_notification_id` (INTEGER, nullable) - Platform notification ID.
    *   `last_live_notification_sent_time` (INTEGER - Unix ms, nullable) - Debounce for immediate live.
3.  **Methods (`DriftCacheService` wrapping `AppDatabase`):** Provides standard CRUD (`getVideo`, `upsertVideo`, `deleteVideo`), status-based retrieval (`getVideosByStatus`), state updates (`updateVideoStatus`, `updateScheduledNotificationId`, etc.), and specific queries for UI (`getScheduledVideos`, `watchScheduledVideos`).
4.  **Pruning:** `pruneOldVideos` method implemented in `DriftCacheService`. Called potentially by background poller or a separate timer. Deletes entries where `status == 'past'` OR `available_at` is older than a defined `maxAge`.

## V. Application Controller (`AppController`)

1.  **Dependencies:** Riverpod `Ref`, `ISettingsService`, `ILoggingService`, `ICacheService`, `INotificationService`.
2.  **Responsibilities:**
    *   `addChannel`: Creates `ChannelSubscriptionSetting` from `Channel` data (using global defaults from providers), adds to `channelListProvider`, triggers save.
    *   `removeChannel`:
        *   Fetches scheduled videos for the channel from `CacheService`.
        *   Iterates and cancels corresponding platform notifications via `NotificationService`.
        *   Updates cache entries to clear `scheduledLiveNotificationId`.
        *   Removes channel from `channelListProvider`, triggers save.
        *   Refreshes `scheduledNotificationsProvider`.
    *   `updateChannelNotificationSetting`: Updates a specific toggle (new, mention, live, update) for a channel in `channelListProvider`, triggers save.
        *   If disabling 'Live', calls helper (`_cancelScheduledLiveNotificationsForChannel`) to cancel existing scheduled notifications for that channel via `NotificationService` and update cache.
        *   If enabling 'Live', calls helper (`_scheduleMissingLiveNotificationsForChannel`) to find upcoming videos in cache and schedule notifications via `NotificationService` if not already scheduled/past.
        *   Refreshes `scheduledNotificationsProvider`.
    *   `updateGlobalSetting`: Updates simple settings (grouping, delay, poll frequency, API key) via `StateProvider`s and persists using `SettingsService`. Notifies background service ('updateSetting' invoke) if `pollFrequency` changes.
    *   `applyGlobalDefaultsToAllChannels`: Updates all entries in `channelListProvider` with current global defaults (`global...DefaultProvider`), triggers save.

## VI. Notification Service (`LocalNotificationService`)

1.  **Technology:** Uses `flutter_local_notifications`.
2.  **Initialization (`initialize`):**
    *   Called only by the **main isolate**.
    *   Handles timezone setup (`timezone` package).
    *   Sets up platform-specific initialization settings (Android, iOS, Linux).
    *   Initializes the plugin, setting `onDidReceiveNotificationResponse` (foreground tap) and `onDidReceiveBackgroundNotificationResponse` (background tap). Tap events push the payload (videoId) to `_notificationTapController`.
    *   Requests permissions on Android (Notifications, Exact Alarms).
    *   Creates Android Notification Channels (`holodex_notifier_default`, `holodex_notifier_scheduled`).
    *   Uses a lock (`_initLock`) to prevent concurrent initialization.
3.  **Methods:**
    *   `showNotification(NotificationInstruction)`:
        *   Formats title/body based on `eventType`.
        *   Fetches channel avatar using `flutter_cache_manager` (`_cacheManager`).
        *   Builds `NotificationDetails` for platforms (includes `largeIcon` for Android).
        *   Generates a consistent notification ID based on `videoId` and `eventType` (`_generateImmediateNotificationId`).
        *   Displays the notification using `_flutterLocalNotificationsPlugin.show()`.
    *   `scheduleNotification({videoId, scheduledTime, ...})`:
        *   Formats title/body.
        *   Builds `NotificationDetails` using the `scheduledChannelId`.
        *   Converts `scheduledTime` to `TZDateTime`.
        *   Generates a consistent notification ID based on `videoId` (`_generateScheduledNotificationId`).
        *   Schedules using `_flutterLocalNotificationsPlugin.zonedSchedule()` with `AndroidScheduleMode.exactAllowWhileIdle`.
        *   Returns the generated notification ID or null on error.
    *   `cancelScheduledNotification(notificationId)`: Cancels using `_flutterLocalNotificationsPlugin.cancel()`.
    *   `cancelAllNotifications()`: Cancels all using `_flutterLocalNotificationsPlugin.cancelAll()`.
    *   `notificationTapStream (get)`: Exposes the stream of payloads from tapped notifications.
4.  **Scheduled Notification Handling:** The background polling service (`_processVideoUpdate`) detects when a stream actually goes live and dispatches an *immediate* 'Live' notification. It also cancels the previously scheduled notification at that point. The scheduled notification itself, if it fires before being cancelled, simply displays the "Scheduled to go live" message. There is no complex verification logic within the `onDidReceive...` callbacks for scheduled notifications in this version.

## VII. Initial Target Platforms

*   Android
*   Windows

## VIII. Technology Stack Summary

*   **Language:** Dart 3.x
*   **Framework:** Flutter 3.x
*   **State Management:** `flutter_riverpod`, `hooks_riverpod`, `flutter_hooks`
*   **HTTP Client:** `dio`
*   **Background Execution:** `flutter_background_service`
*   **Database (Cache):** `drift`, `sqlite3_flutter_libs`, `path_provider`, `path`
*   **Simple Settings:** `shared_preferences`
*   **Secure Storage:** `flutter_secure_storage`
*   **Notifications:** `flutter_local_notifications`
*   **Connectivity:** `connectivity_plus`
*   **Data Modeling:** `freezed`, `json_serializable`, `freezed_annotation`, `json_annotation`
*   **Image Caching:** `cached_network_image`, `flutter_cache_manager`
*   **Logging:** `logger`
*   **Asynchronous:** `synchronized`, `stream_transform`
*   **Utilities:** `intl`, `collection`, `timezone`
*   **Build/Codegen:** `build_runner`, `drift_dev`
*   **Linting:** `flutter_lints`

## IX. Error Handling, Debugging & Testing Strategy

1.  **Error Handling:**
    *   **Network/API:** `dio` interceptors for logging/retries. `try-catch` around API calls in `HolodexApiService`. `ApiKeyRequiredException` handled in `ChannelManagementCard`.
    *   **Background Service:** Main logic wrapped in `try-catch`. Errors logged via `LoggerService`. `backgroundLastErrorProvider` updated to show errors in UI. Readiness check prevents early execution. Initialization errors stop the service.
    *   **Database/Storage:** `try-catch` around critical operations (e.g., JSON parsing in `SharedPrefsSettingsService`). Drift handles many DB errors internally.
    *   **Notifications:** `try-catch` around scheduling/showing/cancelling in `LocalNotificationService` and relevant controller/poller logic.
    *   **Initialization:** `main.dart` has a top-level `try-catch`. Fatal errors launch a minimal `ErrorApp` and attempt to reset the readiness flag.
    *   **UI:** `AsyncValue.when` used extensively for handling loading/error states from providers (`ScheduledNotificationsCard`, `ChannelManagementCard`, `BackgroundStatusCard`). `ScaffoldMessenger` shows transient errors/success messages.
2.  **Debugging:**
    *   `LoggerService` provides structured logs with timestamps and levels, functional in both main and background isolates.
    *   Flutter DevTools.
    *   `kDebugMode` used for conditional logging/behavior (e.g., Dio logging).
    *   `drift`'s `logStatements: true` enabled for debug builds.
3.  **Testing (Strategy):**
    *   **Unit Tests:** Test services (mocking dependencies like Dio, SharedPreferences, Drift), `AppController` logic (mocking services), `freezed` models, utility functions. Use `mocktail` or `mockito`.
    *   **Widget Tests:** Test individual cards and tiles, providing mock data via Riverpod overrides. Test UI interactions (button taps, switch toggles).
    *   **Riverpod Tests:** Test `StateNotifier` logic (`ChannelListNotifier`, `ScheduledNotificationsNotifier`), provider state transitions.
    *   **Integration Tests:** Test key flows:
        *   Adding channel -> Verifying list update and persistence.
        *   Changing setting -> Verifying persistence and potential background notification.
        *   Simulating poll -> Verifying cache update & notification scheduling/dispatch (mock `flutter_local_notifications`).
        *   Background service lifecycle and readiness flag interaction.
