import 'dart:async';
import 'dart:io'; // For Platform check

// For kDebugMode
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
// Import CachedVideo
import 'package:synchronized/synchronized.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// Import logger service if you want to inject it
// import 'package:holodex_notifier/domain/interfaces/logging_service.dart';

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

  // TODO: Inject ILoggingService if needed for enhanced logging
  // final ILoggingService? _logger;
  // LocalNotificationService({ILoggingService? logger}) : _logger = logger;

  static bool _isInitialized = false;
  static final _initLock = Lock(); // Basic lock object

  // --- Channel Definitions ---
  static const String defaultChannelId = 'holodex_notifier_default';
  static const String defaultChannelName = 'Holodex Notifications';
  static const String defaultChannelDesc = 'General notifications from Holodex Notifier';

  static const String scheduledChannelId = 'holodex_notifier_scheduled';
  static const String scheduledChannelName = 'Scheduled Live Streams';
  static const String scheduledChannelDesc = 'Notifications for when streams are about to go live';

  @override
  Stream<String?> get notificationTapStream => _notificationTapController.stream;

  @override
  Future<void> initialize() async {
    bool shouldInitialize = false;
    await _initLock.synchronized(() {
      if (!_isInitialized) {
        shouldInitialize = true;
        _isInitialized = true; // Set flag immediately inside lock
      }
    });

    if (!shouldInitialize) {
      print("LocalNotificationService already initialized or initialization in progress. Skipping.");
      return;
    }
    print("Initializing LocalNotificationService...");
    try {
      // --- Timezone Setup ---
      try {
        print("Initializing timezones...");
        tz.initializeTimeZones();
        print("Timezones initialized.");
      } catch (e, s) {
        print("Error initializing timezones: $e\n$s");
        // Decide if this is fatal or if the app can continue
      }

      // --- Android Settings ---
      print("Creating AndroidInitializationSettings using '$_androidIconReference'...");
      // --- FIX: Use the variable ---
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(_androidIconReference);
      // --- End Fix ---
      print("AndroidInitializationSettings created.");

      // --- iOS/macOS Settings ---
      print("Creating DarwinInitializationSettings...");
      final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
          // Handle older iOS versions if needed
          print("iOS Legacy Notification Received (id=$id, payload=$payload)");
        },
      );
      print("DarwinInitializationSettings created.");

      // --- Linux Settings (Optional) ---
      print("Creating LinuxInitializationSettings...");
      const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open');
      print("LinuxInitializationSettings created.");

      // --- Combine Settings ---
      print("Combining InitializationSettings...");
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
      );
      print("InitializationSettings combined.");

      // --- Initialize Plugin ---
      print("Calling _flutterLocalNotificationsPlugin.initialize()...");
      try {
        await _flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
            print("Foreground Notification Tapped: Payload=${notificationResponse.payload}");
            _notificationTapController.add(notificationResponse.payload);
          },
          // Background Tap Handler
          onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        );
        print("_flutterLocalNotificationsPlugin.initialize() COMPLETED.");
      } catch (e, s) {
        print("ERROR during _flutterLocalNotificationsPlugin.initialize(): $e\n$s");
        // Rethrow or handle the error appropriately. Initialization failed.
        rethrow;
      }

      // --- Request Permissions (Android 13+) ---
      if (Platform.isAndroid) {
        print("Attempting to resolve Android platform implementation...");
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          print("Requesting Android notification permissions...");
          try {
            final bool? granted = await androidImplementation.requestNotificationsPermission();
            print("Android Notification Permission Granted: $granted");
          } catch (e, s) {
            print("ERROR requesting notification permissions: $e\n$s");
          }

          // Optionally request exact alarm permission if precise scheduling is critical
          // Needed for AndroidScheduleMode.exactAllowWhileIdle
          print("Requesting Android exact alarm permissions...");
          try {
            final bool? grantedExact = await androidImplementation.requestExactAlarmsPermission(); // Requires Manifest permission
            print("Android Exact Alarm Permission Granted: $grantedExact");
          } catch (e, s) {
            print("ERROR requesting exact alarm permissions: $e\n$s");
          }
        } else {
          print("Could not resolve Android platform implementation for permissions.");
        }
      }

      // --- Create Android Channels ---
      print("Attempting to create Android channels...");
      try {
        await _createAndroidChannels();
        print(" Finished creating Android channels.");
      } catch (e, s) {
        print("ERROR creating Android channels: $e\n$s");
      }

      print("LocalNotificationService initialized successfully (End of initialize method).");
    } catch (e) {
      // If init fails, reset the flag so it can be tried again later? Or is it fatal?
      await _initLock.synchronized(() {
        _isInitialized = false;
      });
      print("LocalNotificationService Initialization FAILED.");
      rethrow; // Rethrow the error
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

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(defaultChannel);
    await androidImplementation?.createNotificationChannel(scheduledChannel);
    print("Android Notification Channels Created.");
  }

  @override
  Future<void> showNotification(NotificationInstruction instruction) async {
    // _logger?.debug("Showing notification for instruction: ${instruction.}") print(...)
    print("Showing notification for instruction: ${instruction.eventType} - ${instruction.videoId}");

    final String title = _formatTitle(instruction);
    final String body = _formatBody(instruction);
    // Use videoId as payload for simplicity in tap handling
    final String payload = instruction.videoId;

    // --- Get Large Icon (Avatar) ---
    AndroidBitmap<Object>? largeIcon;
    String? largeIconPath;
    if (instruction.channelAvatarUrl != null) {
      try {
        final file = await _cacheManager.getSingleFile(instruction.channelAvatarUrl!);
        largeIconPath = file.path;
        largeIcon = FilePathAndroidBitmap(largeIconPath);
        print("Avatar fetched for notification: $largeIconPath");
      } catch (e) {
        // _logger?.error("Failed to fetch/cache avatar: $e") print(...)
        print("Failed to fetch/cache avatar for notification: $e");
      }
    }

    // --- Android Details ---
    // TODO: Add specific icons per type if desired
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      defaultChannelId, // Use the appropriate channel ID based on type if needed
      defaultChannelName,
      channelDescription: defaultChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      largeIcon: largeIcon,
      // TODO: Consider adding style information (BigTextStyle for longer bodies)
      // Ticker text is optional (shows briefly in status bar)
      ticker: title,
    );

    // --- Darwin (iOS/macOS) Details ---
    final DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true, // Or manage badge count elsewhere
      presentSound: true,
      // attachments: largeIconPath != null ? [DarwinNotificationAttachment(largeIconPath)] : null, // Use attachments for images
    );

    // --- Linux Details (Optional) ---
    // final LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(...);

    // --- Combine Details ---
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      // linux: linuxDetails,
    );

    // --- Generate ID and Show ---
    // Use a consistent hash of videoId for the immediate notification ID
    // to potentially allow updating/cancelling if needed, though distinct IDs are often simpler.
    final int notificationId = _generateImmediateNotificationId(instruction.videoId, instruction.eventType);

    await _flutterLocalNotificationsPlugin.show(notificationId, title, body, notificationDetails, payload: payload);
    print("Notification shown with ID: $notificationId");
  }

  @override
  Future<int?> scheduleNotification({
    required String videoId,
    required DateTime scheduledTime,
    required String payload, // Expecting videoId here usually
    required String title, // Receive title directly
    required String channelName, // Receive channel name directly
  }) async {
    print("Scheduling notification for videoId: $videoId at $scheduledTime");
    try {
      // Use passed-in title and channel name
      final String notificationTitle = "$channelName is scheduled to go live!";
      final String notificationBody = title; // Use the passed video title

      // --- Prepare Notification Details ---
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        scheduledChannelId, // Use the specific channel for scheduled notifications
        scheduledChannelName,
        channelDescription: scheduledChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        ticker: title,
      );
      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
      NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

      // --- Convert time to TZDateTime ---
      final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(scheduledTime, tz.local /* or specific tz.getLocation */);

      // --- Generate ID ---
      // Use a predictable ID for scheduled notifications based on videoId for cancellation
      final int notificationId = _generateScheduledNotificationId(videoId);

      // --- Schedule ---
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        notificationTitle, // Use constructed title
        notificationBody, // Use constructed body
        scheduledTZTime,
        notificationDetails,
        payload: payload, // Use passed payload
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Needs permission
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Or match full date/time if needed
      );

      print("Notification scheduled with ID: $notificationId for $scheduledTZTime");
      return notificationId;
    } catch (e, s) {
      // _logger?.error("Failed to schedule notification for $videoId", e, s) print(...)
      print("Failed to schedule notification for $videoId: $e\n$s");
      return null;
    }
  }

  @override
  Future<void> cancelScheduledNotification(int notificationId) async {
    print("Cancelling notification with ID: $notificationId");
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  @override
  Future<void> cancelAllNotifications() async {
    print("Cancelling ALL notifications");
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // --- Helper Methods ---

  String _formatTitle(NotificationInstruction instruction) {
    switch (instruction.eventType) {
      case NotificationEventType.newMedia:
      case NotificationEventType.update:
        return instruction.channelName; // Channel name as title
      case NotificationEventType.live:
        return "${instruction.channelName} is Live!";
      case NotificationEventType.mention:
        return "${instruction.channelName} mentioned ${instruction.mentionTargetChannelName ?? 'someone'}";
    }
  }

  String _formatBody(NotificationInstruction instruction) {
    switch (instruction.eventType) {
      case NotificationEventType.newMedia:
      case NotificationEventType.update:
      case NotificationEventType.live:
        return instruction.videoTitle; // Video title as body
      case NotificationEventType.mention:
        return "${instruction.videoTitle} (Mention)"; // Clarify it's a mention
    }
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
}
