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
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:intl/intl.dart'; // Import intl for formatting
import 'package:synchronized/synchronized.dart';
import 'package:timeago/timeago.dart' as timeago; // Import timeago package

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// --- Notification Payload Handling ---
// Needs to be a top-level function or static method for background isolate
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handle action occurring when notification is tapped in the background.
  // IMPORTANT: This runs in a separate isolate. Accessing app state directly is complex.
  // Logging or potentially using shared preferences/background messaging are options.
  print('Background Notification Tapped: Payload=${notificationResponse.payload}');
  // You might store the payload to be processed when the app launches next.
}

class LocalNotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // Use DefaultCacheManager or configure a custom one
  final BaseCacheManager _cacheManager = DefaultCacheManager();

  // Stream controller for tap events
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

  // --- Constructor ---
  LocalNotificationService(this._logger, this._settingsService); // Update constructor

  @override
  Stream<String?> get notificationTapStream => _notificationTapController.stream;

  // State
  NotificationFormatConfig? _formatConfigInternal; // Change to nullable
  bool _configLoadAttempted = false; // Flag to prevent multiple loads

  // Getter for external use (optional, but good practice)
  NotificationFormatConfig get _formatConfig {
    if (_formatConfigInternal == null) {
      // This shouldn't happen if loadFormatConfig is called correctly, but acts as a safeguard.
      _logger.fatal("_formatConfig accessed before successful load!");
      // Optionally return default or throw, but fatal better indicates logic error
      throw StateError("Notification Format Config not loaded!");
    }
    return _formatConfigInternal!;
  }

  // Public method to load config, safe to call multiple times
  Future<void> loadFormatConfig() async {
    if (_configLoadAttempted) {
      // _logger.debug("Notification Format Config load already attempted/completed.");
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
      _configLoadAttempted = false; // Allow retry on error? Maybe not. Keep true.
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
      await _loadFormatConfig(); // Load config before plugin init

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
          _logger.info("iOS Legacy Notification Received (id=$id, payload=$payload)");
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
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          final payload = notificationResponse.payload ?? '<null>';
          _logger.info("Foreground Notification Tapped: Payload=$payload");
          _notificationTapController.add(notificationResponse.payload);
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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

  /// Loads the format config from settings or uses defaults.
  Future<void> _loadFormatConfig() async {
    try {
      _logger.debug("Loading Notification Format Config...");
      _formatConfigInternal = await _settingsService.getNotificationFormatConfig();
      _logger.debug("Notification Format Config loaded (Version: ${_formatConfig.version}).");
      // Optionally, save defaults if version mismatch or first time
      // await _settingsService.setNotificationFormatConfig(_formatConfig);
    } catch (e, s) {
      _logger.error("Failed to load Notification Format Config. Using defaults.", e, s);
      _formatConfigInternal = NotificationFormatConfig.defaultConfig();
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
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      defaultChannelId,
      defaultChannelName,
      description: defaultChannelDesc,
      importance: Importance.max, // Adjust importance as needed
      playSound: true,
      // sound: RawResourceAndroidNotificationSound('notification_sound'), // Optional custom sound
    );
    const AndroidNotificationChannel scheduledChannel = AndroidNotificationChannel(
      scheduledChannelId,
      scheduledChannelName,
      description: scheduledChannelDesc,
      importance: Importance.high, // Might be lower than immediate alerts
      playSound: true,
    );
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      reminderChannelId,
      reminderChannelName,
      description: reminderChannelDesc,
      importance: Importance.defaultImportance, // Reminders might be less urgent than Live
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification_sound'), // Optional custom sound for reminders
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(defaultChannel);
    await androidImplementation?.createNotificationChannel(scheduledChannel);
    await androidImplementation?.createNotificationChannel(reminderChannel);
    print("Android Notification Channels Created.");
  }

  // Helper method to access the config safely
  NotificationFormatConfig _getLoadedConfig() {
    if (_formatConfigInternal == null) {
      _logger.fatal("_getLoadedConfig called before config was loaded!");
      // Decide on fallback: throw or return default? Throwing exposes errors earlier.
      throw StateError("Attempted to use notification config before it was loaded.");
    }
    return _formatConfigInternal!;
  }

  @override
  Future<void> showNotification(NotificationInstruction instruction) async {
    _logger.debug("showNotification called for instruction: ${instruction.eventType}");
    try {
      // --- 1. Format Title & Body ---
      final config = _getLoadedConfig(); // Use helper to get config
      final formatted = _formatNotification(instruction, _formatConfig);
      if (formatted == null) {
        _logger.warning("Could not format notification for event type ${instruction.eventType}. Aborting show.");
        return;
      }
      final String title = formatted.title;
      final String body = formatted.body;
      final String payload = instruction.videoId;

      _logger.debug("Formatted Notification ($payload): Title='$title', Body='$body'");

      // --- 2. Get Large Icon (Avatar) ---
      AndroidBitmap<Object>? largeIcon;
      // String? largeIconPath; // Not needed for Darwin attachments currently
      if (instruction.channelAvatarUrl != null) {
        try {
          final file = await _cacheManager.getSingleFile(instruction.channelAvatarUrl!);
          // largeIconPath = file.path;
          largeIcon = FilePathAndroidBitmap(file.path);
          _logger.debug("Avatar fetched for notification: ${file.path}");
        } catch (e) {
          _logger.error("Failed to fetch/cache avatar: ${instruction.channelAvatarUrl}", e);
        }
      }

      // --- 3. Determine Channel and Details ---
      final String channelId = _getChannelIdForInstruction(instruction);
      final String channelName = _getChannelNameFromId(channelId); // Helper to get name
      final String channelDesc = _getChannelDescFromId(channelId); // Helper to get desc
      final Importance importance = _getImportanceFromId(channelId);
      final Priority priority = _getPriorityFromId(channelId);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: importance,
        priority: priority,
        largeIcon: largeIcon,
        ticker: title, // Use formatted title for ticker
      );

      final DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // attachments: largeIconPath != null ? [DarwinNotificationAttachment(largeIconPath)] : null,
      );

      final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

      // --- 4. Generate ID and Show ---
      final int notificationId = _generateImmediateNotificationId(instruction.videoId, instruction.eventType);

      await _flutterLocalNotificationsPlugin.show(notificationId, title, body, notificationDetails, payload: payload);
      _logger.info("Notification shown with ID: $notificationId Type: ${instruction.eventType}");
    } catch (e, s) {
      _logger.error("Error in showNotification for ${instruction.videoId}", e, s);
      // Rethrow or handle as appropriate
    }
  }

  @override
  Future<int?> scheduleNotification({
    required NotificationInstruction instruction, // Use instruction
    required DateTime scheduledTime,
  }) async {
    _logger.debug("scheduleNotification called for ${instruction.eventType} - ${instruction.videoId} at $scheduledTime");
    try {
      // --- 1. Format Title & Body ---
      final config = _getLoadedConfig(); // Use helper to get config

      // We need to pass scheduledTime here to calculate relative time for reminders
      final formatted = _formatNotification(instruction, _formatConfig, scheduledTime: scheduledTime);
      if (formatted == null) {
        _logger.warning("Could not format scheduled notification for event type ${instruction.eventType}. Aborting schedule.");
        return null;
      }
      final String title = formatted.title;
      final String body = formatted.body;
      final String payload = instruction.videoId; // Typically videoId

      _logger.debug("Formatted Scheduled Notification ($payload): Title='$title', Body='$body'");

      // --- 2. Determine Channel and Details ---
      final String channelId = _getChannelIdForInstruction(instruction); // Use helper
      final String channelName = _getChannelNameFromId(channelId);
      final String channelDesc = _getChannelDescFromId(channelId);
      final Importance importance = _getImportanceFromId(channelId);
      final Priority priority = _getPriorityFromId(channelId);

      // Avatar is generally NOT fetched for scheduled notifications (could be outdated)
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: importance,
        priority: priority,
        ticker: title,
      );
      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
      final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

      // --- 3. Convert time and Schedule ---
      final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Generate ID based on type (Reminder vs Live)
      final int notificationId =
          instruction.eventType == NotificationEventType.reminder
              ? _generateReminderNotificationId(instruction.videoId)
              : _generateScheduledNotificationId(instruction.videoId);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTZTime,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Needs permission
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Or match full date/time
      );

      _logger.info("Notification scheduled with ID: $notificationId for $scheduledTZTime Type: ${instruction.eventType}");
      return notificationId;
    } catch (e, s) {
      _logger.error("Failed to schedule notification for ${instruction.videoId}", e, s);
      return null;
    }
  }

  // --- Formatting Helper ---
  ({String title, String body})? _formatNotification(
    NotificationInstruction instruction,
    NotificationFormatConfig config, {
    DateTime? scheduledTime,
  }) {
    final format = config.formats[instruction.eventType];
    if (format == null) {
      _logger.warning("No format found for event type ${instruction.eventType}");
      // {{ Provide a basic fallback format }}
      return (title: instruction.channelName, body: instruction.videoTitle);
    }

    DateTime? baseTime;
    if (scheduledTime != null) {
      // If it's a scheduled notification (Live or Reminder), use the provided scheduledTime
      baseTime = scheduledTime;
    } else {
      // If it's an immediate notification (showNotification was called)
      switch (instruction.eventType) {
        case NotificationEventType.live:
        case NotificationEventType.update:
        case NotificationEventType.mention:
          // For immediate Live, Update, Mention use the current time
          baseTime = DateTime.now();
          break;
        case NotificationEventType.newMedia:
          // For immediate New Media, use the availableAt time from the instruction
          baseTime = instruction.availableAt;
          break;
        case NotificationEventType.reminder:
          // Immediate reminders shouldn't really happen, but use availableAt as a fallback? Or now()?
          // Let's use availableAt, as it's related to the media itself.
          baseTime = instruction.availableAt;
          break;
      }
    }

    final localBaseTime = baseTime?.toLocal(); // Convert to local time for formatting

    // Format {mediaTime} - use local time format 'h:mm a'
    final String mediaTime = baseTime != null ? DateFormat.jm().format(baseTime.toLocal()) : 'Time N/A';

    // Format {relativeTime} only for reminders
    String relativeTime = 'soon'; // Default for reminder
    if (instruction.eventType == NotificationEventType.reminder && scheduledTime != null) {
      try {
        relativeTime = timeago.format(scheduledTime, locale: 'en_short', allowFromNow: true);
      } catch (e) {
        _logger.error("Error formatting relative time", e);
        relativeTime = "soon"; // fallback
      }
    }

    String mediaType = instruction.videoType ?? 'Video'; // Use 'Video' as fallback
    // Handle potential empty string from API or parsing
    if (mediaType.isEmpty) {
      mediaType = 'Video';
    }
    String mediaTypeCaps = mediaType.toUpperCase();

    String dateYMD = 'Date N/A';
    String dateDMY = 'Date N/A';
    String dateMDY = 'Date N/A';
    String dateMD = 'Date N/A';
    String dateDM = 'Date N/A';
    String dateAsia = '日N/A';

    if (localBaseTime != null) {
      dateYMD = DateFormat('yyyy-MM-dd').format(localBaseTime);
      dateDMY = DateFormat('dd-MM-yyyy').format(localBaseTime);
      dateMDY = DateFormat('MM-dd-yyyy').format(localBaseTime);
      dateMD = DateFormat('MM-dd').format(localBaseTime);
      dateDM = DateFormat('dd-MM').format(localBaseTime);
      // Manually construct Asia format
      dateAsia = '${DateFormat('yyyy').format(localBaseTime)}年${DateFormat('MM').format(localBaseTime)}月${DateFormat('dd').format(localBaseTime)}日';
    }

    Map<String, String> replacements = {
      '{channelName}': instruction.channelName,
      '{mediaTitle}': instruction.videoTitle,
      '{mediaTime}': mediaTime, // Use calculated mediaTime
      '{relativeTime}': relativeTime, // Use calculated relativeTime
      '{mediaType}': mediaType, // Use actual mediaType
      '{mediaTypeCaps}': mediaTypeCaps, // Use actual mediaTypeCaps
      '{newLine}': '\n',
      '{mediaDateYMD}': dateYMD,
      '{mediaDateDMY}': dateDMY,
      '{mediaDateMDY}': dateMDY,
      '{mediaDateMD}': dateMD,
      '{mediaDateDM}': dateDM,
      '{mediaDateAsia}': dateAsia,
    };

    String title = format.titleTemplate;
    String body = format.bodyTemplate;

    replacements.forEach((key, value) {
      title = title.replaceAll(key, value);
      body = body.replaceAll(key, value);
    });

    return (title: title, body: body);
  }

  // --- Channel Info Helpers ---
  String _getChannelIdForInstruction(NotificationInstruction instruction) {
    switch (instruction.eventType) {
      case NotificationEventType.reminder:
        return reminderChannelId;
      case NotificationEventType.live: // Scheduled Live uses scheduled channel
        return scheduledChannelId;
      // Other types use default (New, Mention, Update)
      case NotificationEventType.newMedia:
      case NotificationEventType.update:
      case NotificationEventType.mention:
      default:
        return defaultChannelId;
    }
  }

  // Add helpers to get name/desc/importance/priority from ID
  String _getChannelNameFromId(String id) {
    if (id == scheduledChannelId) return scheduledChannelName;
    if (id == reminderChannelId) return reminderChannelName;
    return defaultChannelName;
  }

  String _getChannelDescFromId(String id) {
    if (id == scheduledChannelId) return scheduledChannelDesc;
    if (id == reminderChannelId) return reminderChannelDesc;
    return defaultChannelDesc;
  }

  Importance _getImportanceFromId(String id) {
    if (id == scheduledChannelId) return Importance.high;
    if (id == reminderChannelId) return Importance.defaultImportance;
    return Importance.max; // Default is Max
  }

  Priority _getPriorityFromId(String id) {
    if (id == scheduledChannelId) return Priority.high; // Live schedule is high
    if (id == reminderChannelId) return Priority.defaultPriority;
    return Priority.high; // Default is high
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
    return hash;
  }

  // Generate distinct IDs for immediate vs scheduled, avoiding clashes.
  int _generateImmediateNotificationId(String videoId, NotificationEventType type) {
    // Combine videoId with event type for slightly more uniqueness, especially if grouping is complex later
    return _generateConsistentId("immediate_${videoId}_${type.name}");
  }

  int _generateScheduledNotificationId(String videoId) {
    // Use a different prefix for scheduled IDs
    return _generateConsistentId("scheduled_$videoId");
  }

  int _generateReminderNotificationId(String videoId) {
    return _generateConsistentId("scheduled_reminder_$videoId");
  }

  // --- Other Methods (cancel, cancelAll) remain the same ---
  @override
  Future<void> cancelScheduledNotification(int notificationId) async {
    _logger.debug("Cancelling notification with ID: $notificationId");
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  @override
  Future<void> cancelAllNotifications() async {
    _logger.debug("Cancelling ALL notifications");
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
