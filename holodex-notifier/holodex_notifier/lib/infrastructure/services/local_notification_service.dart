// ignore_for_file: unused_import

import 'dart:async';
import 'dart:io'; // For Platform check

import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart'; // Import SettingsService interface
import 'package:holodex_notifier/domain/models/notification_format_config.dart'; // Import format config model
import 'package:holodex_notifier/domain/models/notification_instruction.dart'; // Need NotificationInstruction for switch
import 'package:intl/intl.dart'; // Import intl for formatting
import 'package:synchronized/synchronized.dart';
import 'package:timeago/timeago.dart' as timeago; // Import timeago package
import 'package:url_launcher/url_launcher.dart'; // {{ Add for launching URLs }}


import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// --- Notification Tap/Action Handling ---

// Renamed top-level function for background isolate execution
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // IMPORTANT: This runs in a separate isolate. Minimal logic here.
  // We can try to reconstruct URLs directly if needed, or use a simpler payload.
  print('Background Notification Tapped: ID=${notificationResponse.id}, ActionID=${notificationResponse.actionId}, Payload=${notificationResponse.payload}');
  // Directly call _handleTap with background context
  _handleTap(
    payload: notificationResponse.payload,
    actionId: notificationResponse.actionId,
    isBackground: true,
  );
}

// Common handler function (TOP-LEVEL) for launching URLs or app actions
// Needs to be top-level to be callable from background isolate.
Future<void> _handleTap({required String? payload, required String? actionId, required bool isBackground}) async {
  print("Handling Tap: Payload=$payload, ActionID=$actionId, Background=$isBackground");
  if (payload == null || payload.isEmpty) {
    print("Tap Handler: No payload (videoId expected), ignoring.");
    return;
  }

  final String videoId = payload; // Payload is the videoId
  String? urlToLaunch;
  bool openApp = false;

  // Determine action based on actionId
  if (actionId == LocalNotificationService.actionOpenYoutube) {
    urlToLaunch = 'https://www.youtube.com/watch?v=$videoId';
  } else if (actionId == LocalNotificationService.actionOpenHolodex) {
    urlToLaunch = 'https://holodex.net/watch/$videoId';
  } else if (actionId == LocalNotificationService.actionOpenSource) {
     // << IMPORTANT LIMITATION >>
     // In the background isolate, we ONLY have the videoId (payload).
     // We CANNOT easily get the specific videoSourceLink here.
     // Fallback: Open the Holodex page for the video ID.
     urlToLaunch = 'https://holodex.net/watch/$videoId';
     print("Tap Handler WARNING: action_open_source tapped. Source link UNKNOWN in this context. Falling back to opening Holodex page for video ID: $videoId");
     // A more complex solution would involve storing the source link temporarily
     // (e.g., SharedPreferences) keyed by videoId when the notification is created,
     // or using a structured payload (if plugin allowed larger/complex payloads reliably).
  } else if (actionId == LocalNotificationService.actionOpenApp) {
    openApp = true;
    print("Tap Handler: App open action requested for video $videoId.");
    // Actual app opening/navigation needs to be handled by the main isolate listener
  } else {
    // No action ID, assume main notification tap -> Default action (e.g., Holodex)
    print("Tap Handler: Main notification tap. Defaulting to Holodex.");
    urlToLaunch = 'https://holodex.net/watch/$videoId';
  }

  // Launch URL if determined
  if (urlToLaunch != null) {
    final uri = Uri.tryParse(urlToLaunch);
    if (uri != null) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print("Launched URL: $uri");
        } else {
          print('Could not launch URI: $uri');
        }
      } catch (e) {
        print('Error launching URL $uri: $e');
      }
    } else {
      print('Failed to parse URI: $urlToLaunch');
    }
  }
  // App opening signal is handled by the foreground callback listener
}
// --- End Notification Tap/Action Handling ---


class LocalNotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // Use DefaultCacheManager or configure a custom one
  final BaseCacheManager _cacheManager = DefaultCacheManager();
  final String _appName = 'Holodex Notifier'; // {{ App name for actions }}

  // Stream controller for tap events (to signal ಮುಖ್ಯ app)
  final StreamController<String?> _notificationTapController = StreamController<String?>.broadcast();

  static const String _androidIconReference = '@mipmap/ic_launcher';

  // Dependencies
  final ILoggingService _logger;
  final ISettingsService _settingsService; // Inject ISettingsService

  static bool _isInitialized = false;
  static final _initLock = Lock(); // Basic lock object

  // --- Channel Definitions ---
  static const String defaultChannelId = 'holodex_notifier_default';
  static const String defaultChannelName = 'Holodex Notifications';
  static const String defaultChannelDesc = 'General notifications from Holodex Notifier';

  static const String scheduledChannelId = 'holodex_notifier_scheduled';
  static const String scheduledChannelName = 'Scheduled Live Streams';
  static const String scheduledChannelDesc = 'Notifications for when streams are about to go live';

  static const String reminderChannelId = 'holodex_notifier_reminders';
  static const String reminderChannelName = 'Upcoming Stream Reminders';
  static const String reminderChannelDesc = 'Reminders for streams that are due soon';

  // --- Action ID Constants ---
  static const String actionOpenYoutube = 'action_open_youtube';
  static const String actionOpenHolodex = 'action_open_holodex';
  static const String actionOpenSource = 'action_open_source'; // ID for source link (if available)
  static const String actionOpenApp = 'action_open_app';

  // --- Constructor ---
  LocalNotificationService(this._logger, this._settingsService); // Update constructor

  @override
  Stream<String?> get notificationTapStream => _notificationTapController.stream;

  // State
  NotificationFormatConfig? _formatConfigInternal; // Change to nullable
  bool _configLoadAttempted = false; // Flag to prevent multiple loads

 // Getter for external use (returns loaded config or throws error if not yet loaded properly)
  NotificationFormatConfig get _formatConfig {
    if (_formatConfigInternal == null) {
      // This shouldn't happen if loadFormatConfig is called correctly, but acts as a safeguard.
      _logger.fatal("_formatConfig accessed before successful load! Ensure loadFormatConfig() or _ensureConfigLoaded() is called first.");
      // Optionally return default or throw, but fatal better indicates logic error
      throw StateError("Notification Format Config not loaded!");
    }
    return _formatConfigInternal!;
  }

  // Public method to load config, safe to call multiple times
  Future<void> loadFormatConfig() async {
    if (_configLoadAttempted) {
       _logger.trace("Notification Format Config load already attempted/completed.");
      return; // Avoid redundant loads
    }
    _configLoadAttempted = true; // Set flag immediately
    try {
      _logger.debug("Loading Notification Format Config...");
      _formatConfigInternal = await _settingsService.getNotificationFormatConfig(); // Assign to nullable field
      _logger.debug("Notification Format Config loaded (Version: ${_formatConfigInternal?.version}).");
    } catch (e, s) {
      _logger.error("Failed to load Notification Format Config. Using defaults.", e, s);
      _formatConfigInternal = NotificationFormatConfig.defaultConfig(); // Assign default to nullable field
      // Consider if retry is appropriate on error. Keeping `_configLoadAttempted = true` prevents retries on subsequent calls.
    }
  }

  // Helper to ensure config is loaded before use in show/schedule methods
  Future<void> _ensureConfigLoaded() async {
    if (_formatConfigInternal == null) {
      _logger.debug("_ensureConfigLoaded: Config not yet loaded, calling loadFormatConfig().");
      await loadFormatConfig();
    }
  }

  @override
  Future<void> initialize() async {
    // Use the lock to prevent concurrent initialization
    bool shouldInitialize = false;
    await _initLock.synchronized(() {
      if (!_isInitialized) {
        shouldInitialize = true;
        _isInitialized = true;
      }
    });

    if (!shouldInitialize) {
      _logger.debug("LocalNotificationService already initialized or initialization in progress. Skipping.");
      return;
    }

    _logger.info("Initializing LocalNotificationService...");
    try {
      // --- Load Format Config FIRST ---
      await loadFormatConfig(); // {{ Ensure config is loaded before use }}

      // --- Timezone Setup ---
      _logger.debug("Initializing timezones...");
      tz.initializeTimeZones();
      _logger.debug("Timezones initialized.");

      // --- Platform Settings ---
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(_androidIconReference);
      final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          _logger.info("[iOS Legacy] Notification Received (id=$id, payload=$payload)");
          // Handle legacy tap like a main tap
          _handleTap(payload: payload, actionId: null, isBackground: false); // Assume foreground for legacy
          _notificationTapController.add(payload); // Signal controller with videoId
        },
      );
      const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open');

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
      );

      // --- Initialize Plugin ---
      _logger.debug("Calling _flutterLocalNotificationsPlugin.initialize()...");
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // --- Updated Foreground Callback ---
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          final payload = notificationResponse.payload ?? '<null>';
          final actionId = notificationResponse.actionId;
          _logger.info("Foreground Notification Tapped: ActionID=$actionId, Payload=$payload");

          // Call the common handler (which is now top-level)
          await _handleTap(payload: payload, actionId: actionId, isBackground: false);

          // Signal the main application stream controller IF it was a main tap or specific app open action
          if ((actionId == null || actionId.isEmpty || actionId == actionOpenApp) && payload != '<null>') {
              _logger.debug("Signaling TapController from foreground callback for payload: $payload");
             _notificationTapController.add(payload); // Payload is videoId
          }
        },
        // --- End Updated Foreground Callback ---
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground, // Keep background handler
      );
      _logger.debug("_flutterLocalNotificationsPlugin.initialize() COMPLETED.");

      // --- Request Permissions & Create Channels ---
      if (Platform.isAndroid) {
        await _requestAndroidPermissions();
        await _createAndroidChannels();
      }

      _logger.info("LocalNotificationService initialized successfully.");
    } catch (e, s) {
      // Reset init flag on failure
      await _initLock.synchronized(() {
        _isInitialized = false;
      });
      _logger.fatal("LocalNotificationService Initialization FAILED.", e, s);
      rethrow;
    }
  }


  Future<void> _requestAndroidPermissions() async {
    final plugin = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (plugin != null) {
      try {
        _logger.debug("Requesting Android notification permissions...");
        final notificationsGranted = await plugin.requestNotificationsPermission();
        _logger.debug("Android Notification Permission Granted: $notificationsGranted");

        _logger.debug("Requesting Android exact alarm permissions...");
        final exactAlarmsGranted = await plugin.requestExactAlarmsPermission();
        _logger.debug("Android Exact Alarm Permission Granted: $exactAlarmsGranted");
      } catch (e, s) {
        _logger.error("Error requesting Android permissions", e, s);
      }
    }
  }

  Future<void> _createAndroidChannels() async {
    // Default channel (Immediate: Live, New, Update, Mention)
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      defaultChannelId,
      defaultChannelName,
      description: defaultChannelDesc,
      importance: Importance.max,
      playSound: true,
    );
    // Scheduled channel (Scheduled: Live)
    const AndroidNotificationChannel scheduledChannel = AndroidNotificationChannel(
      scheduledChannelId,
      scheduledChannelName,
      description: scheduledChannelDesc,
      importance: Importance.high,
      playSound: true,
    );
    // Reminder channel (Scheduled: Reminder)
     const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      reminderChannelId,
      reminderChannelName,
      description: reminderChannelDesc,
      importance: Importance.high, // << INCREASED from defaultImportance
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('notification_sound'), // Optional
    );

    // ... (rest of the method) ...
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    try {
        await androidImplementation?.createNotificationChannel(defaultChannel);
        await androidImplementation?.createNotificationChannel(scheduledChannel);
        await androidImplementation?.createNotificationChannel(reminderChannel);
        _logger.info("Android Notification Channels Created/Ensured.");
    } catch (e,s) {
      _logger.error("Failed to create Android notification channels", e, s);
    }
  }


  @override
  Future<void> showNotification(NotificationInstruction instruction) async {
    _logger.debug("[ShowNotification] Start instruction: ${instruction.eventType}, videoId: ${instruction.videoId}");
    // ... (beginning of method, config loading, formatting, asset fetching) ...
    try {
        // --- Ensure Config is Loaded ---
        await _ensureConfigLoaded();
        // Use the getter, which now ensures non-null or throws
        final config = _formatConfig;

        // --- 1. Format Title & Body ---
        final formatted = _formatNotification(instruction, config);
        if (formatted == null) {
            _logger.warning("[ShowNotification] Could not format notification for event type ${instruction.eventType}. Aborting show.");
            return;
        }
        final title = formatted.title;
        final body = formatted.body;
        // << CHANGE: Payload is now just the videoId >>
        final payload = instruction.videoId;

        _logger.debug("[ShowNotification] Formatted: Title='$title', Body='$body', Payload='$payload'");

        // --- Assets ---
        // --- 2. Get Assets (Avatar & Big Picture) ---
        AndroidBitmap<Object>? largeIconBitmap;
        String? largeIconPath; // Keep track for Darwin fallback if needed
        StyleInformation? styleInformation;
        List<DarwinNotificationAttachment>? darwinAttachments;

        // Fetch avatar (becomes largeIcon on Android)
         if (instruction.channelAvatarUrl != null && instruction.channelAvatarUrl!.isNotEmpty) {
            try {
              _logger.trace("[ShowNotification] Fetching avatar: ${instruction.channelAvatarUrl}");
              final avatarFile = await _cacheManager.getSingleFile(instruction.channelAvatarUrl!);
              largeIconPath = avatarFile.path; // Save path for later use
              largeIconBitmap = FilePathAndroidBitmap(avatarFile.path);
              _logger.debug("[ShowNotification] Avatar fetched for largeIcon: $largeIconPath");
            } catch (e) {
                _logger.error("[ShowNotification] Failed fetch avatar",e);
                // Continue without avatar
            }
         }
         // Fetch thumbnail (becomes BigPictureStyle on Android, attachment on Darwin)
         if (instruction.videoThumbnailUrl != null && instruction.videoThumbnailUrl!.isNotEmpty) {
            try {
               _logger.trace("[ShowNotification] Fetching thumbnail: ${instruction.videoThumbnailUrl}");
              final thumbnailFile = await _cacheManager.getSingleFile(instruction.videoThumbnailUrl!);
              styleInformation = BigPictureStyleInformation(
                  FilePathAndroidBitmap(thumbnailFile.path),
                  largeIcon: largeIconBitmap, // Show channel avatar in corner if available
                  hideExpandedLargeIcon: false, // Keep avatar visible when expanded
              );
              _logger.debug("[ShowNotification] Thumbnail fetched for BigPicture: ${thumbnailFile.path}");
              // Use thumbnail as Darwin attachment
              darwinAttachments = [DarwinNotificationAttachment(thumbnailFile.path)];
            } catch (e) {
               _logger.error("[ShowNotification] Failed fetch thumbnail",e);
               // Fallback: If thumbnail failed but avatar exists, use avatar for Darwin
               if (largeIconPath != null) {
                 darwinAttachments = [DarwinNotificationAttachment(largeIconPath)];
                 _logger.debug("[ShowNotification] Using avatar as Darwin attachment due to thumbnail error.");
               }
            }
         } else if (largeIconPath != null) {
             // No thumbnail URL provided, but avatar exists, use avatar for Darwin
             darwinAttachments = [DarwinNotificationAttachment(largeIconPath)];
             _logger.debug("[ShowNotification] Using avatar as Darwin attachment (no thumbnail URL).");
         }
        // --- End Assets ---

        // --- Channel Details ---
        // --- 3. Determine Channel and Details ---
        final String channelId = _getChannelIdForInstruction(instruction);
        final String channelName = _getChannelNameFromId(channelId);
        final String channelDesc = _getChannelDescFromId(channelId);
        final Importance importance = _getImportanceFromId(channelId);
        final Priority priority = _getPriorityFromId(channelId);
        _logger.debug("[ShowNotification] Using channel: $channelId");

        // --- Actions ---
        // --- 4. Define Actions (Conditional Logic) ---
        final List<AndroidNotificationAction> androidActions = _buildAndroidActions(instruction); // Use helper

        // --- Build Details ---
        // --- 5. Build Notification Details --
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            channelId, channelName,
            channelDescription: channelDesc,
            importance: importance, priority: priority,
            largeIcon: largeIconBitmap, // fetched avatar or null
            styleInformation: styleInformation, // fetched thumbnail or null
            actions: androidActions, // actions built by helper
            ticker: title,
        );
         final DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true,
            attachments: darwinAttachments, // fetched thumbnail or avatar or null
         );
        final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

        // --- Generate ID and Show ---
        // --- 6. Generate ID and Show ---
        final int notificationId = _generateImmediateNotificationId(instruction.videoId, instruction.eventType);

        // {{ Log the actions LIST right before showing }}
        _logger.debug("[ShowNotification] FINAL Actions being passed for ID $notificationId: ${androidActions.map((a) => a.id).join(', ')}");

        _logger.debug("[ShowNotification] Showing notification ID: $notificationId");
        // << Pass videoId as payload >>
        await _flutterLocalNotificationsPlugin.show(notificationId, title, body, notificationDetails, payload: payload);
        _logger.info("[ShowNotification] Notification shown successfully. ID: $notificationId Type: ${instruction.eventType}");

    } catch (e, s) {
        _logger.error("[ShowNotification] Error for ${instruction.videoId}", e, s);
        /* Rethrow or handle */
    }
  }

  @override
  Future<int?> scheduleNotification({
    required NotificationInstruction instruction,
    required DateTime scheduledTime,
  }) async {
      _logger.debug("[ScheduleNotification] Start instruction: ${instruction.eventType}, videoId: ${instruction.videoId}, time: $scheduledTime");
     // ... (beginning of method, config loading, formatting) ...
     try {
        // --- Ensure Config is Loaded ---
        await _ensureConfigLoaded();
        final config = _formatConfig; // Use getter

        // --- 1. Format Title & Body ---
        final formatted = _formatNotification(instruction, config, scheduledTime: scheduledTime);
        if (formatted == null) {
             _logger.warning("[ScheduleNotification] Could not format scheduled notification for event type ${instruction.eventType}. Aborting schedule.");
             return null;
        }
        final title = formatted.title;
        final body = formatted.body;
        // << CHANGE: Payload is now just the videoId >>
        final payload = instruction.videoId;
        _logger.debug("[ScheduleNotification] Formatted: Title='$title', Body='$body', Payload='$payload'");

        // ... Channel Details ...
        // --- 2. Determine Channel and Details ---
        final String channelId = _getChannelIdForScheduleInstruction(instruction);
        final String channelName = _getChannelNameFromId(channelId);
        final String channelDesc = _getChannelDescFromId(channelId);
        final Importance importance = _getImportanceFromId(channelId);
        final Priority priority = _getPriorityFromId(channelId);
         _logger.debug("[ScheduleNotification] Using channel: $channelId");

        // ... Actions ...
        // --- 3. Define Actions (Conditional) ---
        final List<AndroidNotificationAction> androidActions = _buildAndroidActions(instruction); // Use helper

        // ... Assets ...
        // --- 4. Get Assets (Avatar only for scheduled) ---
        AndroidBitmap<Object>? largeIconBitmap;
        if (instruction.channelAvatarUrl != null && instruction.channelAvatarUrl!.isNotEmpty) {
          try {
               _logger.trace("[ScheduleNotification] Fetching avatar for scheduled: ${instruction.channelAvatarUrl}");
              final file = await _cacheManager.getSingleFile(instruction.channelAvatarUrl!);
              largeIconBitmap = FilePathAndroidBitmap(file.path);
               _logger.debug("[ScheduleNotification] Avatar fetched for scheduled notification largeIcon: ${file.path}");
          } catch (e) {
             _logger.warning("[ScheduleNotification] Failed fetch scheduled avatar", e);
              /* Log warning, continue without icon */
          }
        }

        // --- Build Details ---
        // --- 5. Build Notification Details ---
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            channelId, channelName,
            channelDescription: channelDesc,
            importance: importance, priority: priority,
            largeIcon: largeIconBitmap, // Avatar is passed (or null if failed/not present)
            actions: androidActions, // Pass built actions
            ticker: title,
            // No styleInfo (thumbnail) for scheduled
        );
          const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
            presentAlert: true, presentBadge: true, presentSound: true,
            // No attachments for scheduled
          );
         final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

        // --- Schedule ---
        // --- 6. Convert time and Schedule ---
        final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(scheduledTime, tz.local);
        // Generate ID based on type (Reminder vs Scheduled Live)
        final int notificationId = instruction.eventType == NotificationEventType.reminder
                ? _generateReminderNotificationId(instruction.videoId)
                : _generateScheduledNotificationId(instruction.videoId); // Live uses this

        await _flutterLocalNotificationsPlugin.cancel(notificationId);
         _logger.debug("[ScheduleNotification] Pre-cancelled existing notification ID $notificationId before scheduling.");

        // {{ Log the actions LIST right before scheduling }}
        _logger.debug("[ScheduleNotification] FINAL Actions being passed for ID $notificationId: ${androidActions.map((a) => a.id).join(', ')}");

         _logger.debug("[ScheduleNotification] Scheduling notification ID: $notificationId for time: $scheduledTZTime");
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId, title, body, scheduledTZTime, notificationDetails,
          // << Pass videoId as payload >>
          payload: payload,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Needs permission
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Or match full date/time if needed
        );

         _logger.info("[ScheduleNotification] Notification scheduled successfully. ID: $notificationId for $scheduledTZTime Type: ${instruction.eventType}");
        return notificationId;
    } catch (e, s) {
        _logger.error("[ScheduleNotification] Failed for ${instruction.videoId}", e, s);
        return null;
    }
  }

// Helper to Build Actions CONDITIONALLLY
  List<AndroidNotificationAction> _buildAndroidActions(NotificationInstruction instruction) {
    final List<AndroidNotificationAction> actions = [];
    final String? sourceLink = instruction.videoSourceLink;

    _logger.trace("[BuildActions] Building actions for Video: ${instruction.videoId}, Type: ${instruction.videoType ?? 'N/A'}, SourceLink: '${sourceLink ?? 'null'}'");

    if (sourceLink != null && sourceLink.isNotEmpty) {
      // Placeholder -> Only show 'Open Source' 
      _logger.debug("[BuildActions] Adding 'Open Source' action for placeholder video ${instruction.videoId}.");
      actions.add(AndroidNotificationAction(
        actionOpenSource,
        'Open Source',
        showsUserInterface: false, // Use false as we handle launch via _handleTap
      ));
    } else {
      // Regular video -> Show 'Open YouTube', 'Open Holodex', 
      _logger.debug("[BuildActions] Adding 'Open YouTube' & 'Open Holodex' actions for regular video ${instruction.videoId}.");
      actions.add(AndroidNotificationAction(
        actionOpenYoutube,
        'Open YouTube',
        showsUserInterface: false, // Use false as we handle launch via _handleTap
      ));
      actions.add(AndroidNotificationAction(
        actionOpenHolodex,
        'Open Holodex',
        showsUserInterface: false, // Use false as we handle launch via _handleTap
      ));
    }

    return actions;
  }
// ... (rest of the class, including _formatNotification which remains unchanged) ...

  // --- Formatting Helper ---
  ({String title, String body})? _formatNotification(
    NotificationInstruction instruction,
    NotificationFormatConfig config, {
    DateTime? scheduledTime, // Null for immediate, used for {relativeTime} in REMINDERS
  }) {
    // Determine format based on event type
    final format = config.formats[instruction.eventType];
    if (format == null) {
      _logger.warning("No format found for event type ${instruction.eventType}. Using basic fallback.");
      // Basic fallback using channel/title
      return (title: instruction.channelName, body: instruction.videoTitle);
    }

    // Base time for formatting is the actual stream event time
    DateTime baseTime = instruction.availableAt;
    final localBaseTime = baseTime.toLocal(); // Convert to local time for formatting

    // Calculate relative time ONLY if it's a reminder AND a scheduled time is provided
    // This represents "in X minutes/hours" for the *upcoming* reminder notification.
    String relativeTime = '';
    if (instruction.eventType == NotificationEventType.reminder && scheduledTime != null) {
      try {
        // Calculate how far away the notification *will* fire from the time this format call happens.
        // Or use timeago.format(baseTime) to show time relative to actual start?
        // Let's use timeago.format(baseTime) to say "Starting X ago/in X"
        // relativeTime = timeago.format(scheduledTime, locale: 'en_short', allowFromNow: true);
        relativeTime = timeago.format(localBaseTime, locale: 'en_short', allowFromNow: true);
      } catch (e) {
        _logger.error("Error formatting relative time using baseTime: $localBaseTime", e);
        relativeTime = "soon"; // fallback
      }
    } else if (scheduledTime == null) { // For immediate notifications
        try {
            // How long ago did it start/become available?
            relativeTime = timeago.format(localBaseTime, locale: 'en_short', allowFromNow: true);
        } catch (e) {
             _logger.error("Error formatting relative time for immediate notification using baseTime: $localBaseTime", e);
            relativeTime = "just now"; // fallback
        }
    }

    // Prepare other placeholders
    final String mediaTime = DateFormat.jm().format(localBaseTime); // 1:30 PM
    String mediaType = instruction.videoType ?? 'Media'; 
    if (mediaType.isEmpty || mediaType == 'placeholder') mediaType = 'Media';
    String mediaTypeCaps = mediaType.toUpperCase(); // STREAM

    // Date formats based on the actual event time (local)
    String dateYMD = DateFormat('yyyy-MM-dd').format(localBaseTime);
    String dateDMY = DateFormat('dd-MM-yyyy').format(localBaseTime);
    String dateMDY = DateFormat('MM-dd-yyyy').format(localBaseTime);
    String dateMD = DateFormat('MM-dd').format(localBaseTime);
    String dateDM = DateFormat('dd-MM').format(localBaseTime);
    String dateAsia = '${DateFormat('yyyy').format(localBaseTime)}年${DateFormat('MM').format(localBaseTime)}月${DateFormat('dd').format(localBaseTime)}日';

    // Build replacement map
    Map<String, String> replacements = {
      '{channelName}': instruction.channelName,
      '{mediaTitle}': instruction.videoTitle,
      '{mediaTime}': mediaTime,        // Event time, e.g., 1:30 PM
      '{relativeTime}': relativeTime,  // Event relative time, e.g., "5 minutes ago" or "in 10 minutes"
      '{mediaType}': mediaType,        // Stream, Premiere, Clip etc.
      '{mediaTypeCaps}': mediaTypeCaps, // STREAM, PREMIERE, CLIP etc.
      '{newLine}': '\n',
      '{mediaDateYMD}': dateYMD,      // 2023-10-27
      '{mediaDateDMY}': dateDMY,      // 27-10-2023
      '{mediaDateMDY}': dateMDY,      // 10-27-2023
      '{mediaDateMD}': dateMD,        // 10-27
      '{mediaDateDM}': dateDM,        // 27-10
      '{mediaDateAsia}': dateAsia,     // 2023年10月27日
    };

    // Apply replacements
    String title = format.titleTemplate;
    String body = format.bodyTemplate;

    replacements.forEach((key, value) {
      title = title.replaceAll(key, value);
      body = body.replaceAll(key, value);
    });

    return (title: title, body: body);
  }


    // --- Channel Info Helpers ---

   // Helper to determine channel for IMMEDIATE notifications
  String _getChannelIdForInstruction(NotificationInstruction instruction) {
    switch (instruction.eventType) {
      // Immediate notifications (Live just started, new video, update, mention) use the default channel
      case NotificationEventType.live:
      case NotificationEventType.newMedia:
      case NotificationEventType.update:
      case NotificationEventType.mention:
         _logger.trace("_getChannelIdForInstruction: Event ${instruction.eventType} -> defaultChannelId");
         return defaultChannelId;
      // Reminders should always be scheduled, triggering this would be unexpected.
      case NotificationEventType.reminder:
         _logger.warning("_getChannelIdForInstruction: Unexpected immediate REMINDER event -> defaultChannelId (fallback)");
         return defaultChannelId; // Fallback, though should not happen
      // ignore: unreachable_switch_default
      default: // Should not happen
        _logger.warning("Unknown event type in _getChannelIdForInstruction: ${instruction.eventType} -> defaultChannelId (fallback)");
        return defaultChannelId;
    }
  }

  // Separate helper to determine channel for SCHEDULED notifications
  String _getChannelIdForScheduleInstruction(NotificationInstruction instruction) {
      switch (instruction.eventType) {
          // Scheduled Live stream notifications use the scheduled channel
          case NotificationEventType.live:
            _logger.trace("_getChannelIdForScheduleInstruction: Event ${instruction.eventType} -> scheduledChannelId");
            return scheduledChannelId;
          // Scheduled Reminder notifications use the reminder channel
          case NotificationEventType.reminder:
            _logger.trace("_getChannelIdForScheduleInstruction: Event ${instruction.eventType} -> reminderChannelId");
            return reminderChannelId;
          // Other types (New, Update, Mention) are typically NOT scheduled. If they are, use default as fallback.
          case NotificationEventType.newMedia:
          case NotificationEventType.update:
          case NotificationEventType.mention:
          // ignore: unreachable_switch_default
          default:
              _logger.warning("Attempting to SCHEDULE unexpected notification type: ${instruction.eventType}. Using default channel.");
              return defaultChannelId; // Fallback
      }
  }


  // Add helpers to get name/desc/importance/priority from ID
  String _getChannelNameFromId(String id) {
    if (id == scheduledChannelId) return scheduledChannelName;
    if (id == reminderChannelId) return reminderChannelName;
    return defaultChannelName; // Default
  }

  String _getChannelDescFromId(String id) {
    if (id == scheduledChannelId) return scheduledChannelDesc;
    if (id == reminderChannelId) return reminderChannelDesc;
    return defaultChannelDesc; // Default
  }

  Importance _getImportanceFromId(String id) {
    if (id == scheduledChannelId) return Importance.high;       // Scheduled Live
    if (id == reminderChannelId) return Importance.high; // Reminders (INCREASED)
    return Importance.max; // Default (Immediate Live, New, etc.)
  }

  Priority _getPriorityFromId(String id) {
    if (id == scheduledChannelId) return Priority.high;        // Scheduled Live
    if (id == reminderChannelId) return Priority.high; // Reminders (INCREASED to match Importance.high)
    return Priority.high; // Default (Immediate Live, New, etc.) - Changed from Max to High for consistency with Importance.Max
  }

  // Generates a stable 31-bit integer ID from a string.
  // Needed because Android notification IDs are 32-bit signed integers.
  int _generateConsistentId(String uniqueString) {
    // Simple hash: sum of character codes modulo max 31-bit int
    const maxInt = 0x7FFFFFFF; // Max positive 32-bit signed int
    var hash = 0;
    for (var i = 0; i < uniqueString.length; i++) {
      hash = (31 * hash + uniqueString.codeUnitAt(i)) & maxInt;
    }
    // print("Generated ID for '$uniqueString': $hash"); // Debug logging if needed
    return hash;
  }

  // Generate distinct IDs for immediate notifications based on video and type.
  int _generateImmediateNotificationId(String videoId, NotificationEventType type) {
    // Prefix differentiates from scheduled/reminder IDs for the same videoId.
    // Including type helps if we ever need to show e.g., an immediate 'live' AND an immediate 'mention' for the same video (unlikely but possible).
    return _generateConsistentId("immediate_${videoId}_${type.name}");
  }

  // Generate distinct ID for a SCHEDULED 'live' notification.
  int _generateScheduledNotificationId(String videoId) {
    // Different prefix from immediate and reminder. Only one scheduled 'live' per video expected.
    return _generateConsistentId("scheduled_live_$videoId");
  }

  // Generate distinct ID for a SCHEDULED 'reminder' notification.
  int _generateReminderNotificationId(String videoId) {
     // Different prefix from immediate and scheduled live. Only one reminder per video expected.
    return _generateConsistentId("scheduled_reminder_$videoId");
  }

  // --- Other Methods (cancel, cancelAll) ---
  @override
  Future<void> cancelScheduledNotification(int notificationId) async {
    _logger.info("Cancelling notification/schedule with ID: $notificationId");
    try {
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
    } catch (e, s) {
      _logger.error("Failed to cancel notification $notificationId", e, s);
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    _logger.info("Cancelling ALL notifications");
     try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e, s) {
      _logger.error("Failed to cancel all notifications", e, s);
    }
  }

  // Helper to cancel notification based on Video ID (for scheduled live start time)
  Future<void> cancelScheduledLiveNotification(String videoId) async {
      final id = _generateScheduledNotificationId(videoId);
      await cancelScheduledNotification(id);
  }

  // Helper to cancel notification based on Video ID (for reminder)
  Future<void> cancelScheduledReminderNotification(String videoId) async {
       final id = _generateReminderNotificationId(videoId);
      await cancelScheduledNotification(id);
  }

} // End of class