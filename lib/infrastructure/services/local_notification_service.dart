// ignore_for_file: unused_local_variable, unreachable_switch_default

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:intl/intl.dart';
import 'package:synchronized/synchronized.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:disable_battery_optimization/disable_battery_optimization.dart';


import 'package:holodex_notifier/domain/utils/notification_formatter.dart'; 

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (kDebugMode) {
    print(
      'Background Notification Tapped: ID=${notificationResponse.id}, ActionID=${notificationResponse.actionId}, Payload=${notificationResponse.payload}',
    );
  }
  _handleTap(payload: notificationResponse.payload, actionId: notificationResponse.actionId, isBackground: true);
}

Future<void> _handleTap({required String? payload, required String? actionId, required bool isBackground}) async {
  if (kDebugMode) {
    print("Handling Tap: Payload=$payload, ActionID=$actionId, Background=$isBackground");
  }
  if (payload == null || payload.isEmpty) {
    if (kDebugMode) {
      print("Tap Handler: No payload (videoId expected), ignoring.");
    }
    return;
  }

  
  String? videoId;
  String? sourceUrl;
  try {
    final decodedPayload = jsonDecode(payload) as Map<String, dynamic>;
    videoId = decodedPayload['videoId'] as String?;
    sourceUrl = decodedPayload['sourceUrl'] as String?; 
  } catch (e) {
    if (kDebugMode) print("Tap Handler: Failed to decode JSON payload '$payload'. Assuming plain video ID. Error: $e");
    
    videoId = payload;
    sourceUrl = null;
  }

  if (videoId == null) {
    if (kDebugMode) print("Tap Handler: videoId missing from payload '$payload'. Ignoring tap.");
    return;
  }
  if (kDebugMode) print("Tap Handler: Decoded videoId=$videoId, sourceUrl=$sourceUrl");

  

  String? urlToLaunch;
  bool openApp = false; 

  if (actionId == LocalNotificationService.actionOpenYoutube) {
    urlToLaunch = 'https://www.youtube.com/watch?v=$videoId';
  } else if (actionId == LocalNotificationService.actionOpenHolodex) {
    urlToLaunch = 'https://holodex.net/watch/$videoId';
  } else if (actionId == LocalNotificationService.actionOpenSource) {
    
    urlToLaunch = sourceUrl; 
    if (urlToLaunch == null) {
      if (kDebugMode) {
        print(
          "Tap Handler WARNING: action_open_source tapped but sourceUrl not found in payload '$payload'. Falling back to Holodex for video $videoId",
        );
      }
      urlToLaunch = 'https://holodex.net/watch/$videoId';
    }
    
  } else if (actionId == LocalNotificationService.actionOpenApp) {
    openApp = true;
    
    if (kDebugMode) {
      print("Tap Handler: App open action requested for video $videoId. (Currently does nothing)");
    }
    
    
    return; 
  } else {
    
    if (kDebugMode) {
      print("Tap Handler: Main notification tap. Defaulting to Holodex.");
    }
    urlToLaunch = 'https://holodex.net/watch/$videoId';
  }

  final uri = Uri.tryParse(urlToLaunch);
  if (uri != null) {
    try {
      
      if (isBackground && Platform.isAndroid) {
        if (kDebugMode) {
          print("Attempting to launch $uri from background using AndroidIntent...");
        }
        final AndroidIntent intent = AndroidIntent(
          action: 'action_view', 
          data: uri.toString(),
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK], 
        );
        await intent.launch();
        if (kDebugMode) {
          print("AndroidIntent launch attempted for $uri.");
        }
      } else {
        
        if (kDebugMode) {
          print("Attempting to launch $uri using url_launcher...");
        }
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (kDebugMode) {
            print("Launched URL via url_launcher: $uri");
          }
        } else {
          if (kDebugMode) {
            print('url_launcher could not launch URI: $uri');
          }
        }
      }
      
    } catch (e, s) {
      if (kDebugMode) {
        print('Error launching URL $uri (isBackground: $isBackground): $e\n$s');
      }
      
      
    }
  } else {
    if (kDebugMode) {
      print('Failed to parse URI: $urlToLaunch');
    }
    
  }
}

class LocalNotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final BaseCacheManager _cacheManager = DefaultCacheManager();

  final StreamController<String?> _notificationTapController = StreamController<String?>.broadcast();

  static const String _androidIconReference = '@mipmap/notification_icon';

  final ILoggingService _logger;
  final ISettingsService _settingsService;

  static bool _isInitialized = false;
  static final _initLock = Lock();

  static const String defaultChannelId = 'holodex_notifier_default';
  static const String defaultChannelName = 'Holodex Notifications';
  static const String defaultChannelDesc = 'General notifications from Holodex Notifier';

  static const String scheduledChannelId = 'holodex_notifier_scheduled';
  static const String scheduledChannelName = 'Scheduled Live Streams';
  static const String scheduledChannelDesc = 'Notifications for when streams are about to go live';

  static const String reminderChannelId = 'holodex_notifier_reminders';
  static const String reminderChannelName = 'Upcoming Stream Reminders';
  static const String reminderChannelDesc = 'Reminders for streams that are due soon';

  static const String actionOpenYoutube = 'action_open_youtube';
  static const String actionOpenHolodex = 'action_open_holodex';
  static const String actionOpenSource = 'action_open_source';
  static const String actionOpenApp = 'action_open_app';

  LocalNotificationService(this._logger, this._settingsService);

  Stream<String?> get notificationTapStream => _notificationTapController.stream;

  NotificationFormatConfig? _formatConfigInternal;
  bool _configLoadAttempted = false;

  NotificationFormatConfig get _formatConfig {
    if (_formatConfigInternal == null) {
      _logger.fatal("_formatConfig accessed before successful load! Ensure loadFormatConfig() or _ensureConfigLoaded() is called first.");
      throw StateError("Notification Format Config not loaded!");
    }
    return _formatConfigInternal!;
  }

  Future<void> loadFormatConfig() async {
    if (_configLoadAttempted) {
      _logger.trace("Notification Format Config load already attempted/completed.");
      return;
    }
    _configLoadAttempted = true;
    try {
      _logger.debug("Loading Notification Format Config...");
      _formatConfigInternal = await _settingsService.getNotificationFormatConfig();
      _logger.debug("Notification Format Config loaded (Version: ${_formatConfigInternal?.version}).");
    } catch (e, s) {
      _logger.error("Failed to load Notification Format Config. Using defaults.", e, s);
      _formatConfigInternal = NotificationFormatConfig.defaultConfig();
    }
  }

  @override
  Future<void> reloadFormatConfig() async {
    _logger.info("Reloading Notification Format Config...");
    try {
      _formatConfigInternal = await _settingsService.getNotificationFormatConfig();
      _logger.info("Notification Format Config reloaded successfully (Version: ${_formatConfigInternal?.version}).");
    } catch (e, s) {
      _logger.error("Failed to reload Notification Format Config. Existing config (if any) will be kept.", e, s);
    }
  }

  Future<void> _ensureConfigLoaded() async {
    if (_formatConfigInternal == null) {
      _logger.debug("_ensureConfigLoaded: Config not yet loaded, calling loadFormatConfig().");
      await loadFormatConfig();
    }
  }

  @override
  Future<void> initialize() async {
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
      await loadFormatConfig();

      _logger.debug("Initializing timezones...");
      tz.initializeTimeZones();
      _logger.debug("Timezones initialized.");

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(_androidIconReference);
      final DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const LinuxInitializationSettings initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'Open');

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
        macOS: initializationSettingsDarwin,
        linux: initializationSettingsLinux,
      );

      _logger.debug("Calling _flutterLocalNotificationsPlugin.initialize()...");
      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          final payload = notificationResponse.payload ?? '<null>';
          final actionId = notificationResponse.actionId;
          _logger.info("Foreground Notification Tapped: ActionID=$actionId, Payload=$payload");

          await _handleTap(payload: payload, actionId: actionId, isBackground: false);

          if ((actionId == null || actionId.isEmpty || actionId == actionOpenApp) && payload != '<null>') {
            _logger.debug("Signaling TapController from foreground callback for payload: $payload");
            _notificationTapController.add(payload);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      _logger.debug("_flutterLocalNotificationsPlugin.initialize() COMPLETED.");

      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      _logger.info("LocalNotificationService initialized successfully.");
    } catch (e, s) {
      await _initLock.synchronized(() {
        _isInitialized = false;
      });
      _logger.fatal("LocalNotificationService Initialization FAILED.", e, s);
      rethrow;
    }
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestRequiredPermissions() async {
    _logger.info("[Notification Service] Requesting Notification and Exact Alarm permissions...");
    Map<Permission, PermissionStatus> statuses = {};

    final notificationStatus = await Permission.notification.request();
    _logger.info("[Notification Service] Notification permission status: $notificationStatus");
    statuses[Permission.notification] = notificationStatus;

    if (notificationStatus.isGranted || notificationStatus.isLimited) {
      if (Platform.isAndroid) {
        _logger.info("[Notification Service] Requesting Exact Alarm permission...");
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        _logger.info("[Notification Service] Exact Alarm permission status: $alarmStatus");
        statuses[Permission.scheduleExactAlarm] = alarmStatus;
      } else {
        _logger.info("[Notification Service] Skipping Exact Alarm permission request (Not Android).");

        statuses[Permission.scheduleExactAlarm] = PermissionStatus.granted;
      }
    } else {
      _logger.warning("[Notification Service] Skipping Exact Alarm permission request because Notification permission was denied.");

      statuses[Permission.scheduleExactAlarm] = PermissionStatus.denied;
    }

    _logger.info("[Notification Service] Finished requesting permissions.");
    return statuses;
  }

  @override
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) {
      _logger.trace("[Notification Service] Skipping battery optimization check (Not Android). Reporting as disabled.");
      return true;
    }
    try {
      bool? isDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled;
      _logger.trace("[Notification Service] Battery optimization status check returned: $isDisabled");
      return isDisabled ?? false;
    } catch (e, s) {
      _logger.error("[Notification Service] Error checking battery optimization status", e, s);
      return false;
    }
  }

  @override
  Future<bool> requestBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) {
      _logger.info("[Notification Service] Skipping battery optimization request (Not Android).");
      return true;
    }
    _logger.info("[Notification Service] Requesting user to disable battery optimization...");
    try {
      bool alreadyDisabled = await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;
      if (alreadyDisabled) {
        _logger.info("[Notification Service] Battery optimization is already disabled.");
        return true;
      } else {
        _logger.info("[Notification Service] Showing system settings page for disabling battery optimization...");

        bool? success = await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();

        _logger.info("[Notification Service] Directed user to battery optimization settings.");
        return success ?? false;
      }
    } catch (e, s) {
      _logger.error("[Notification Service] Error requesting battery optimization disable", e, s);
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final enabled =
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: false,
          badge: false,
          sound: false,
        ) ??
        true;
    _logger.debug("Notification enabled check: $enabled");
    return enabled;
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      defaultChannelId,
      defaultChannelName,
      description: defaultChannelDesc,
      importance: Importance.max,
      playSound: true,
    );
    const AndroidNotificationChannel scheduledChannel = AndroidNotificationChannel(
      scheduledChannelId,
      scheduledChannelName,
      description: scheduledChannelDesc,
      importance: Importance.high,
      playSound: true,
    );
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      reminderChannelId,
      reminderChannelName,
      description: reminderChannelDesc,
      importance: Importance.high,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    try {
      await androidImplementation?.createNotificationChannel(defaultChannel);
      await androidImplementation?.createNotificationChannel(scheduledChannel);
      await androidImplementation?.createNotificationChannel(reminderChannel);
      _logger.info("Android Notification Channels Created/Ensured.");
    } catch (e, s) {
      _logger.error("Failed to create Android notification channels", e, s);
    }
  }

  @override
  Future<int?> showNotification(NotificationInstruction instruction) async {
    _logger.debug("[ShowNotification] Start instruction: ${instruction.eventType}, videoId: ${instruction.videoId}");
    try {
      await _ensureConfigLoaded(); 
      final config = _formatConfigInternal!; 

      
      final formatted = formatNotificationContent(
        config: config,
        eventType: instruction.eventType,
        channelName: instruction.channelName,
        videoTitle: instruction.videoTitle,
        videoType: instruction.videoType,
        availableAt: instruction.availableAt, 
        notificationScheduledTime: null, 
        mentionTargetChannelName: instruction.mentionTargetChannelName,
        mentionedChannelNames: instruction.mentionedChannelNames,
        logger: _logger,
      );
      

      
      final title = formatted.title;
      final body = formatted.body;
      
      final payloadMap = <String, String>{'videoId': instruction.videoId};
      if (instruction.videoType == 'placeholder' &&
          instruction.videoSourceLink != null &&
          instruction.videoSourceLink!.isNotEmpty) {
        
        final format = config.formats[instruction.eventType] ?? NotificationFormatConfig.defaultConfig().formats[instruction.eventType]!;
        if (format.showSourceLink) {
          payloadMap['sourceUrl'] = instruction.videoSourceLink!;
          _logger.trace("[ShowNotification] Adding sourceUrl to payload for ${instruction.videoId}");
        }
      }
      final payload = jsonEncode(payloadMap);
      _logger.debug("[ShowNotification] Formatted: Title='$title', Body='$body', Payload='$payload'");

      AndroidBitmap<Object>? largeIconBitmap;
      String? largeIconPath;
      StyleInformation? styleInformation;
      List<DarwinNotificationAttachment>? darwinAttachments;

      if (instruction.channelAvatarUrl != null && instruction.channelAvatarUrl!.isNotEmpty) {
        try {
          final avatarFile = await _cacheManager.getSingleFile(instruction.channelAvatarUrl!);
          largeIconPath = avatarFile.path;
          largeIconBitmap = FilePathAndroidBitmap(avatarFile.path);
          _logger.debug("[ShowNotification] Avatar fetched for largeIcon: $largeIconPath");
        } catch (e) {
          _logger.error("[ShowNotification] Failed fetch avatar", e);
        }
      }
      if (config.formats[instruction.eventType]!.showThumbnail && instruction.videoThumbnailUrl != null && instruction.videoThumbnailUrl!.isNotEmpty) {
        try {
          _logger.trace("[ShowNotification] Fetching thumbnail (showThumbnail=true): ${instruction.videoThumbnailUrl}");
          final thumbnailFile = await _cacheManager.getSingleFile(instruction.videoThumbnailUrl!);
          styleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(thumbnailFile.path),
            largeIcon: largeIconBitmap,
            hideExpandedLargeIcon: false,
          );
          _logger.debug("[ShowNotification] Thumbnail fetched for BigPicture: ${thumbnailFile.path}");
          darwinAttachments = [DarwinNotificationAttachment(thumbnailFile.path)];
        } catch (e) {
          _logger.error("[ShowNotification] Failed fetch thumbnail", e);
          if (largeIconPath != null) {
            darwinAttachments = [DarwinNotificationAttachment(largeIconPath)];
            _logger.debug("[ShowNotification] Using avatar as Darwin attachment due to thumbnail error.");
          }
        }
      } else if (largeIconPath != null) {
        darwinAttachments = [DarwinNotificationAttachment(largeIconPath)];
        _logger.debug("[ShowNotification] Using avatar as Darwin attachment (thumbnail disabled or unavailable).");
      }
      if (!config.formats[instruction.eventType]!.showThumbnail) {
        _logger.debug("[ShowNotification] Thumbnail display skipped (showThumbnail=false).");
      }

      final String channelId = _getChannelIdForInstruction(instruction);
      final String channelName = _getChannelNameFromId(channelId);
      final String channelDesc = _getChannelDescFromId(channelId);
      final Importance importance = _getImportanceFromId(channelId);
      final Priority priority = _getPriorityFromId(channelId);
      _logger.debug("[ShowNotification] Using channel: $channelId");

      final List<AndroidNotificationAction> androidActions = _buildAndroidActions(instruction, config.formats[instruction.eventType] ?? NotificationFormatConfig.defaultConfig().formats[instruction.eventType]!); 

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: importance,
        priority: priority,
        largeIcon: largeIconBitmap,
        styleInformation: styleInformation,
        actions: androidActions,
        ticker: title,
      );
      final DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: darwinAttachments,
      );
      final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

      final int notificationId = _generateImmediateNotificationId(instruction.videoId, instruction.eventType);
      _logger.debug("[ShowNotification] Showing notification ID: $notificationId");
      await _flutterLocalNotificationsPlugin.show(notificationId, title, body, notificationDetails, payload: payload);
      _logger.info("[ShowNotification] Notification shown successfully. ID: $notificationId Type: ${instruction.eventType}");
      return notificationId;
    } catch (e, s) {
      _logger.error("[ShowNotification] Error for ${instruction.videoId}", e, s);
      return null;
    }
  }

  @override
  Future<int?> scheduleNotification({required NotificationInstruction instruction, required DateTime scheduledTime}) async {
    _logger.debug("[ScheduleNotification] Start instruction: ${instruction.eventType}, videoId: ${instruction.videoId}, time: $scheduledTime");
    try {
      await _ensureConfigLoaded(); 
      final config = _formatConfigInternal!; 

      
      final formatted = formatNotificationContent(
        config: config,
        eventType: instruction.eventType,
        channelName: instruction.channelName,
        videoTitle: instruction.videoTitle,
        videoType: instruction.videoType,
        availableAt: instruction.availableAt, 
        notificationScheduledTime: scheduledTime, 
        mentionTargetChannelName: instruction.mentionTargetChannelName,
        mentionedChannelNames: instruction.mentionedChannelNames,
        logger: _logger,
      );
      

      
      final title = formatted.title;
      final body = formatted.body;
      
      final payloadMap = <String, String>{'videoId': instruction.videoId};
      if (instruction.videoType == 'placeholder' &&
          instruction.videoSourceLink != null &&
          instruction.videoSourceLink!.isNotEmpty) {
        
        final format = config.formats[instruction.eventType] ?? NotificationFormatConfig.defaultConfig().formats[instruction.eventType]!;
        if (format.showSourceLink) {
          payloadMap['sourceUrl'] = instruction.videoSourceLink!;
          _logger.trace("[ShowNotification] Adding sourceUrl to payload for ${instruction.videoId}");
        }
      }
      final payload = jsonEncode(payloadMap);
      _logger.debug("[ScheduleNotification] Formatted: Title='$title', Body='$body', Payload='$payload'");

      
      final String channelId = _getChannelIdForScheduleInstruction(instruction);
      final String channelName = _getChannelNameFromId(channelId);
      final String channelDesc = _getChannelDescFromId(channelId);
      final Importance importance = _getImportanceFromId(channelId);
      final Priority priority = _getPriorityFromId(channelId);
      _logger.debug("[ScheduleNotification] Using channel: $channelId");

      final List<AndroidNotificationAction> androidActions = _buildAndroidActions(instruction, config.formats[instruction.eventType] ?? NotificationFormatConfig.defaultConfig().formats[instruction.eventType]!); 

      AndroidBitmap<Object>? largeIconBitmap;
      if (instruction.channelAvatarUrl != null && instruction.channelAvatarUrl!.isNotEmpty) {
        try {
          final file = await _cacheManager.getSingleFile(instruction.channelAvatarUrl!);
          largeIconBitmap = FilePathAndroidBitmap(file.path);
        } catch (e) {
          _logger.warning("[ScheduleNotification] Failed fetch scheduled avatar", e);
        }
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: importance,
        priority: priority,
        largeIcon: largeIconBitmap,
        actions: androidActions,
        ticker: title,
      );
      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
      final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

      final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(scheduledTime, tz.local);
      final int notificationId =
          instruction.eventType == NotificationEventType.reminder
              ? _generateReminderNotificationId(instruction.videoId)
              : _generateScheduledNotificationId(instruction.videoId);

      await _flutterLocalNotificationsPlugin.cancel(notificationId);
      _logger.debug("[ScheduleNotification] Pre-cancelled existing notification ID $notificationId before scheduling.");

      _logger.debug("[ScheduleNotification] Scheduling notification ID: $notificationId for time: $scheduledTZTime");
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledTZTime,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      _logger.info(
        "[ScheduleNotification] Notification scheduled successfully. ID: $notificationId for $scheduledTZTime Type: ${instruction.eventType}",
      );
      return notificationId;
    } catch (e, s) {
      _logger.error("[ScheduleNotification] Failed for ${instruction.videoId}", e, s);
      return null;
    }
  }

  
  List<AndroidNotificationAction> _buildAndroidActions(NotificationInstruction instruction, NotificationFormat format) {
    
    
    
    
    final List<AndroidNotificationAction> actions = [];
    final String? sourceLink = instruction.videoSourceLink;
    final bool isPlaceholder = instruction.videoType == 'placeholder';

    _logger.trace(
      "[BuildActions] Building actions for Video ${instruction.videoId}. Format flags: YT=${format.showYoutubeLink}, HDX=${format.showHolodexLink}, SRC=${format.showSourceLink}",
    );

    if (isPlaceholder && sourceLink != null && sourceLink.isNotEmpty && format.showSourceLink) {
      _logger.debug("[BuildActions] Adding 'Open Source' action for placeholder video ${instruction.videoId}.");
      actions.add(AndroidNotificationAction(actionOpenSource, 'Open Source', showsUserInterface: false));
    } else if (!isPlaceholder) {
      if (format.showYoutubeLink) {
        _logger.debug("[BuildActions] Adding 'Open YouTube' action for regular video ${instruction.videoId}.");
        actions.add(AndroidNotificationAction(actionOpenYoutube, 'Open YouTube', showsUserInterface: false));
      }
      if (format.showHolodexLink) {
        _logger.debug("[BuildActions] Adding 'Open Holodex' action for regular video ${instruction.videoId}.");
        actions.add(AndroidNotificationAction(actionOpenHolodex, 'Open Holodex', showsUserInterface: false));
      }
    } else if (isPlaceholder && !format.showSourceLink) {
      _logger.debug("[BuildActions] Skipping 'Open Source' action for ${instruction.videoId} (showSourceLink=false).");
    }
    _logger.debug("[BuildActions] Final actions for ${instruction.videoId}: ${actions.map((a) => a.id).join(', ')}");
    return actions;
  }

  String _getChannelIdForInstruction(NotificationInstruction instruction) {
    switch (instruction.eventType) {
      case NotificationEventType.live:
      case NotificationEventType.newMedia:
      case NotificationEventType.update:
      case NotificationEventType.mention:
        _logger.trace("_getChannelIdForInstruction: Event ${instruction.eventType} -> defaultChannelId");
        return defaultChannelId;
      case NotificationEventType.reminder:
        _logger.warning("_getChannelIdForInstruction: Unexpected immediate REMINDER event -> defaultChannelId (fallback)");
        return defaultChannelId;
      default:
        _logger.warning("Unknown event type in _getChannelIdForInstruction: ${instruction.eventType} -> defaultChannelId (fallback)");
        return defaultChannelId;
    }
  }

  String _getChannelIdForScheduleInstruction(NotificationInstruction instruction) {
    switch (instruction.eventType) {
      case NotificationEventType.live:
        _logger.trace("_getChannelIdForScheduleInstruction: Event ${instruction.eventType} -> scheduledChannelId");
        return scheduledChannelId;
      case NotificationEventType.reminder:
        _logger.trace("_getChannelIdForScheduleInstruction: Event ${instruction.eventType} -> reminderChannelId");
        return reminderChannelId;
      case NotificationEventType.newMedia:
      case NotificationEventType.update:
      case NotificationEventType.mention:
      default:
        _logger.warning("Attempting to SCHEDULE unexpected notification type: ${instruction.eventType}. Using default channel.");
        return defaultChannelId;
    }
  }

  String _getChannelNameFromId(String id) {
    if (id == scheduledChannelId) return scheduledChannelName;
    if (id == reminderChannelId) return reminderChannelName;
    return defaultChannelName;
  }

  String _getChannelDescFromId(String id) {
    if (id == scheduledChannelDesc) return scheduledChannelDesc;
    if (id == reminderChannelId) return reminderChannelDesc;
    return defaultChannelDesc;
  }

  Importance _getImportanceFromId(String id) {
    if (id == scheduledChannelId) return Importance.high;
    if (id == reminderChannelId) return Importance.high;
    return Importance.max;
  }

  Priority _getPriorityFromId(String id) {
    if (id == scheduledChannelId) return Priority.high;
    if (id == reminderChannelId) return Priority.high;
    return Priority.high;
  }

  int _generateConsistentId(String uniqueString) {
    const maxInt = 0x7FFFFFFF;
    var hash = 0;
    for (var i = 0; i < uniqueString.length; i++) {
      hash = (31 * hash + uniqueString.codeUnitAt(i)) & maxInt;
    }
    return hash;
  }

  int _generateImmediateNotificationId(String videoId, NotificationEventType type) {
    return _generateConsistentId("immediate_${videoId}_${type.name}");
  }

  int _generateScheduledNotificationId(String videoId) {
    return _generateConsistentId("scheduled_live_$videoId");
  }

  int _generateReminderNotificationId(String videoId) {
    return _generateConsistentId("scheduled_reminder_$videoId");
  }

  @override
  Future<void> cancelNotification(int notificationId) async {
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

  Future<void> cancelScheduledLiveNotification(String videoId) async {
    final id = _generateScheduledNotificationId(videoId);
    await cancelNotification(id);
  }

  Future<void> cancelScheduledReminderNotification(String videoId) async {
    final id = _generateReminderNotificationId(videoId);
    await cancelNotification(id);
  }
}
