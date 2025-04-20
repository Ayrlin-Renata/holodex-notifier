import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart';
import 'package:holodex_notifier/domain/interfaces/background_polling_service.dart';
import 'package:holodex_notifier/domain/interfaces/api_service.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/connectivity_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/services/local_notification_service.dart';
import 'package:holodex_notifier/main.dart' hide ErrorApp, appControllerProvider;
import 'package:holodex_notifier/main.dart' as main_providers show isolateContextProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:io' show Platform;

class BackgroundPollerService implements IBackgroundPollingService {
  final ILoggingService _logger;
  final _service = FlutterBackgroundService();
  static const String backgroundChannelId = 'holodex_notifier_background_service';

  BackgroundPollerService(this._logger);

  @override
  Future<void> initialize() async {
    _logger.info('[BG Poller Service] Initializing...');

    if (Platform.isAndroid) {
      _logger.info('[BG Poller Service] Creating notification channel: $backgroundChannelId');
      try {
        final flp = FlutterLocalNotificationsPlugin();
        await flp.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
          const AndroidNotificationChannel(
            backgroundChannelId,
            'Holodex Background Service',
            description: 'Status updates for background polling.',
            importance: Importance.low,
            playSound: false,
            showBadge: false,
          ),
        );
        _logger.info('[BG Poller Service] Notification channel $backgroundChannelId created/ensured.');
      } catch (e, s) {
        _logger.error('[BG Poller Service] ERROR creating notification channel $backgroundChannelId', e, s);
      }
    }

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: backgroundChannelId,
        initialNotificationTitle: 'Holodex Notifier',
        initialNotificationContent: 'Initializing service...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),
    );

    _logger.info('[BG Poller Service] Configuration complete.');
  }

  @override
  Future<void> startPolling() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      _logger.info('[BG Poller Service] Attempting to start background service via startService()...');
      try {
        await _service.startService();
        _logger.info('[BG Poller Service] startService() called successfully.');
      } catch (e, s) {
        _logger.error('[BG Poller Service] ERROR calling startService()', e, s);
      }
    } else {
      _logger.info('[BG Poller Service] Service is already running.');
    }
  }

  @override
  Future<void> stopPolling() async {
    _logger.info('[BG Poller Service] Stopping service...');
    _service.invoke("stopService");
  }

  @override
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  @override
  Future<void> triggerPoll() async {
    _service.invoke("triggerPoll");
  }

  @override
  void notifySettingChanged(String key, dynamic value) {
    _logger.debug('[BG Poller Service Invoke] Notifying background: Setting changed - Key=$key');
    _service.invoke('updateSetting', {'key': key, 'value': value});
  }
}

Timer? pollingTimer;
Duration currentPollFrequency = const Duration(minutes: 10);
bool isPolling = false;

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final container = ProviderContainer(overrides: [main_providers.isolateContextProvider.overrideWithValue(IsolateContext.background)]);
  final ILoggingService logger = container.read(loggingServiceProvider);
  tz.initializeTimeZones();
  logger.info('BG Isolate: STARTED.');

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
      logger.info("BG Isolate: Set to foreground.");
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
      logger.info("BG Isolate: Set to background.");
    });
  }
  service.on('stopService').listen((event) {
    logger.info("BG Isolate: Received 'stopService' invoke.");
    pollingTimer?.cancel();
    service.stopSelf();
    logger.info("BG Isolate: Timer cancelled, stopping service.");
    container.dispose();
  });

  service.on('triggerPoll').listen((event) async {
    if (isPolling) {
      logger.warning("BG Isolate: Received 'triggerPoll' while already polling, skipping.");
      return;
    }
    logger.info('BG Isolate: --- Manual Poll START ---');
    isPolling = true;
    try {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Holodex Notifier",
          content: "Manual poll started @ ${DateTime.now().toLocal().toString().substring(11, 19)}",
        );
      }
      await _executePollCycle(container);
    } catch (e, s) {
      logger.fatal("BG Isolate: Unhandled error during MANUAL poll cycle execution.", e, s);
      try {
        container.read(backgroundLastErrorProvider.notifier).state = "Manual Poll Error: ${e.toString()}";
      } catch (_) {}
    } finally {
      isPolling = false;
      logger.info('BG Isolate: --- Manual Poll END ---');
      if (service is AndroidServiceInstance) {
        final lastError = container.read(backgroundLastErrorProvider);
        service.setForegroundNotificationInfo(
          title: "Holodex Notifier",
          content:
              lastError != null
                  ? "Manual poll finished with error @ ${DateTime.now().toLocal().toString().substring(11, 19)}"
                  : "Manual poll finished @ ${DateTime.now().toLocal().toString().substring(11, 19)} - Waiting for next timed poll.",
        );
      }
    }
  });

  service.on('updateSetting').listen((event) async {
    if (event == null || event['key'] == null) {
      logger.warning("BG Isolate: Received invalid 'updateSetting' event: $event");
      return;
    }

    final String key = event['key'];
    final dynamic value = event['value'];
    logger.info("BG Isolate: Received 'updateSetting': Key=$key, Value=$value");

    if (key == 'pollFrequency' && value is int) {
      final newFrequency = Duration(minutes: value);
      if (newFrequency != currentPollFrequency) {
        logger.info("BG Isolate: Updating poll frequency to $value minutes.");
        currentPollFrequency = newFrequency;
        pollingTimer?.cancel();
        if (isPolling) {
          logger.warning("BG Isolate: Poll cycle active during frequency update. New timer will start after cycle completes.");
        } else {
          logger.debug("BG Isolate: Restarting timer with new frequency.");
          await startPollingTimer(container, service);
        }
      } else {
        logger.debug("BG Isolate: Received poll frequency update, but value ($value min) is unchanged.");
      }
    } else if (key == 'reminderLeadTime' && value is int) {
      logger.info("BG Isolate: Received reminderLeadTime update ($value min). Value will be used on next poll cycle.");
    } else if (key == 'apiKey') {
      logger.debug("BG Isolate: Received API Key update notification. No background action needed.");
    } else if (key == 'notificationFormat') {
      logger.info("BG Isolate: Received 'notificationFormat' update notification.");
      try {
        final notificationService = container.read(notificationServiceProvider);
        await notificationService.reloadFormatConfig();
        logger.info("BG Isolate: Successfully instructed NotificationService to reload format config.");
      } catch (e, s) {
        logger.error("BG Isolate: Error reloading notification format config.", e, s);
      }
    } else {
      logger.warning("BG Isolate: Received unhandled setting update key: $key");
    }
  });

  ISettingsService? settingsService;
  try {
    logger.info("BG Isolate: Initializing dependencies and waiting for main isolate readiness...");
    try {
      logger.debug("BG Isolate: Ensuring SettingsService instance is resolved...");
      settingsService = await container.read(settingsServiceFutureProvider.future);
      logger.debug("BG Isolate: SettingsService instance resolved.");
    } catch (e, s) {
      logger.fatal("BG Isolate: FATAL: Failed to resolve SettingsService FutureProvider.", e, s);
      service.stopSelf();
      container.dispose();
      return;
    }
    bool mainReady = false;
    while (!mainReady) {
      try {
        mainReady = await settingsService!.getMainServicesReady();
      } catch (e, s) {
        logger.error("BG Isolate: Error resolving SettingsService or checking readiness flag, retrying in 5s...", e, s);
        await Future.delayed(const Duration(seconds: 5));
      }

      if (!mainReady) {
        logger.info("BG Isolate: Main isolate not ready yet, waiting 2 seconds...");
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    logger.info("BG Isolate: Main isolate readiness confirmed. Proceeding with background initialization.");

    late INotificationService notificationServiceInstance;
    try {
      logger.debug("BG Isolate: Ensuring NotificationService instance is resolved...");
      notificationServiceInstance = await container.read(notificationServiceFutureProvider.future);
      logger.info("BG Isolate: Notification Service resolved.");

      if (notificationServiceInstance is LocalNotificationService) {
        try {
          logger.debug("BG Isolate: Ensuring Notification Format Config is loaded...");
          await notificationServiceInstance.loadFormatConfig();
          logger.info("BG Isolate: Notification Format Config ensured.");
        } catch (e, s) {
          logger.fatal("BG Isolate: FATAL: Failed to load Notification Format Config.", e, s);
          service.stopSelf();
          container.dispose();
          return;
        }
      } else {
        logger.warning("BG Isolate: Resolved Notification Service is not LocalNotificationService, cannot explicitly load format config.");
      }
    } catch (e, s) {
      logger.fatal("BG Isolate: FATAL: Failed to resolve NotificationService FutureProvider.", e, s);
      service.stopSelf();
      container.dispose();
      return;
    }

    logger.info("BG Isolate: Starting the main polling timer...");
    currentPollFrequency = await settingsService!.getPollFrequency();
    await startPollingTimer(container, service);
  } catch (e, s) {
    logger.fatal("BG Isolate: FATAL error during initial setup/readiness check.", e, s);
    service.stopSelf();
    container.dispose();
  }
}

Future<void> startPollingTimer(ProviderContainer container, ServiceInstance service) async {
  final ILoggingService logger = container.read(loggingServiceProvider);
  final ISettingsService settingsService = container.read(settingsServiceProvider);

  try {
    pollingTimer?.cancel();
    logger.debug("BG Isolate: Polling timer (if exists) cancelled.");

    currentPollFrequency = await settingsService.getPollFrequency();
    logger.info("BG Isolate: Setting poll frequency to: ${currentPollFrequency.inMinutes} minutes");

    pollingTimer = Timer.periodic(currentPollFrequency, (timer) async {
      if (isPolling) {
        logger.warning("BG Isolate: Timed poll triggered, but a previous cycle is still running. Skipping.");
        return;
      }
      logger.info('BG Isolate: --- Timed Poll START ---');
      isPolling = true;
      try {
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "Holodex Notifier",
            content: "Polling @ ${DateTime.now().toLocal().toString().substring(11, 19)}",
          );
        }
        await _executePollCycle(container);
      } catch (e, s) {
        logger.fatal("BG Isolate: Unhandled error during TIMED poll cycle execution.", e, s);
        try {
          container.read(backgroundLastErrorProvider.notifier).state = "Timed Poll Error: ${e.toString()}";
        } catch (_) {}
      } finally {
        isPolling = false;
        logger.info('BG Isolate: --- Timed Poll END ---');
        if (service is AndroidServiceInstance) {
          final lastError = container.read(backgroundLastErrorProvider);
          service.setForegroundNotificationInfo(
            title: "Holodex Notifier",
            content:
                lastError != null
                    ? "Poll finished with error @ ${DateTime.now().toLocal().toString().substring(11, 19)}"
                    : "Poll finished @ ${DateTime.now().toLocal().toString().substring(11, 19)} - Waiting for next poll.",
          );
        }
      }
    });
    logger.info("BG Isolate: Polling timer started successfully.");
  } catch (e, s) {
    logger.fatal("BG Isolate: Error retrieving poll frequency or starting timer.", e, s);
    pollingTimer?.cancel();
    try {
      service.stopSelf();
      container.dispose();
    } catch (stopErr, stopST) {
      logger.error("BG Isolate: Failed to stop service/dispose container during timer start error.", stopErr, stopST);
    }
  }
}

Future<void> _executePollCycle(ProviderContainer container) async {
  final ILoggingService logger = container.read(loggingServiceProvider);
  final ISettingsService settingsService = container.read(settingsServiceProvider);
  final IConnectivityService connectivityService = container.read(connectivityServiceProvider);
  final IApiService apiService = container.read(apiServiceProvider);
  final ICacheService cacheService = container.read(cacheServiceProvider);
  final INotificationDecisionService decisionService = container.read(notificationDecisionServiceProvider);
  final INotificationActionHandler actionHandler = container.read(notificationActionHandlerProvider);

  final errorNotifier = container.read(backgroundLastErrorProvider.notifier);
  String currentError = '';

  logger.info("BG Poll Cycle: --- _executePollCycle START ---");

  try {
    logger.debug("BG Poll Cycle: Checking connectivity...");
    final bool isConnected = await connectivityService.isConnected();
    if (!isConnected) {
      currentError = 'No internet connection.';
      logger.warning("BG Poll Cycle: $currentError Skipping poll.");
      errorNotifier.state = currentError;
      return;
    }
    logger.debug("BG Poll Cycle: Internet connection available.");

    final DateTime currentPollTime = DateTime.now().toUtc();
    logger.info("BG Poll Cycle: Starting poll at ${currentPollTime.toIso8601String()}");
    final DateTime fromTime = currentPollTime;

    final Duration reminderLeadTime = await settingsService.getReminderLeadTime();
    logger.debug("BG Poll Cycle: Current Reminder Lead Time: ${reminderLeadTime.inMinutes} minutes");

    logger.debug("BG Poll Cycle: Loading channel subscriptions...");
    final List<ChannelSubscriptionSetting> channelSettingsList = await settingsService.getChannelSubscriptions();
    if (channelSettingsList.isEmpty) {
      logger.info("BG Poll Cycle: No channels subscribed. Skipping fetch.");
      await settingsService.setLastPollTime(currentPollTime);
      errorNotifier.state = null;
      return;
    }

    final Map<String, ChannelSubscriptionSetting> channelSettingsMap = {for (var s in channelSettingsList) s.channelId: s};
    final Set<String> subscribedIds = channelSettingsList.map((s) => s.channelId).toSet();
    logger.debug("BG Poll Cycle: Subscribed IDs: ${subscribedIds.length}");

    List<VideoFull> liveFeedVideos = [];
    List<VideoFull> allCollabVideos = [];
    Map<String, Set<String>> mentionContextMap = {};

    logger.debug("BG Poll Cycle: Fetching live feed videos from API...");
    try {
      liveFeedVideos = await apiService.fetchLiveVideos(channelIds: subscribedIds);
      logger.info("BG Poll Cycle: Fetched ${liveFeedVideos.length} videos from /users/live.");
    } catch (e, s) {
      logger.error("BG Poll Cycle: Error fetching live feed videos.", e, s);
      if (currentError.isEmpty) currentError = "Live Feed Fetch Error: ${e.toString().split('\n').first}";
    }

    logger.debug(
      "BG Poll Cycle: Fetching collab videos for ${subscribedIds.length} channels (conditionally, from: ${fromTime.toIso8601String()})...",
    );
    for (final channelSetting in channelSettingsList) {
      final channelId = channelSetting.channelId;
      if (!channelSetting.notifyMentions) {
        logger.trace("[BG Poll Cycle] Skipping collabs fetch for $channelId (notifyMentions is false).");
        continue;
      }

      final bool includeClips = channelSetting.notifyClips;
      logger.trace("[BG Poll Cycle] Fetching collabs for $channelId (includeClips: $includeClips, from: ${fromTime.toIso8601String()})");
      try {
        final collabVids = await apiService.fetchCollabVideos(channelId: channelId, includeClips: includeClips, from: fromTime);
        logger.debug("BG Poll Cycle: Fetched ${collabVids.length} collab videos for channel $channelId.");
        allCollabVideos.addAll(collabVids);
      } catch (e, s) {
        logger.error("BG Poll Cycle: Error fetching collab videos for channel $channelId.", e, s);
        if (currentError.isEmpty) currentError = "Collab Fetch Error ($channelId): ${e.toString().split('\n').first}";
      }
    }
    logger.info("BG Poll Cycle: Mention context map built containing ${mentionContextMap.length} unique collab video entries.");

    List<VideoFull> combinedVideos = [...liveFeedVideos, ...allCollabVideos];
    final Set<String> seenVideoIds = {};
    final List<VideoFull> distinctVideos = [];
    for (final video in combinedVideos) {
      if (seenVideoIds.add(video.id)) {
        distinctVideos.add(video);
      }
    }
    logger.info("BG Poll Cycle: Combined ${combinedVideos.length} videos -> ${distinctVideos.length} distinct videos.");

    logger.info(
      "BG Poll Cycle: Building mention context map from ${distinctVideos.length} distinct videos for ${subscribedIds.length} subscribed channels...",
    );
    for (final video in distinctVideos) {
      if (video.mentions != null) {
        for (final mention in video.mentions!) {
          if (subscribedIds.contains(mention.id)) {
            mentionContextMap.putIfAbsent(video.id, () => {}).add(mention.id);
          }
        }
      }
    }
    logger.info(
      "BG Poll Cycle: Mention context map built containing ${mentionContextMap.length} unique video entries with mentions relevant to subscribed channels.",
    );

    final List<NotificationAction> allActions = [];
    int processedCount = 0;
    int processingErrorCount = 0;

    if (distinctVideos.isNotEmpty) {
      logger.debug("BG Poll Cycle: Processing ${distinctVideos.length} distinct videos...");
      for (final fetchedVideo in distinctVideos) {
        final videoId = fetchedVideo.id;
        try {
          final cachedVideo = await cacheService.getVideo(videoId);

          final Set<String>? mentionedForChannels = mentionContextMap[videoId];

          final List<NotificationAction> videoActions = await decisionService.determineActionsForVideoUpdate(
            fetchedVideo: fetchedVideo,
            cachedVideo: cachedVideo,
            allChannelSettings: channelSettingsList,
            mentionedForChannels: mentionedForChannels,
          );
          allActions.addAll(videoActions);

          try {
            final channelSetting = channelSettingsMap[fetchedVideo.channel.id];
            if (channelSetting != null && fetchedVideo.channel.photo != null && channelSetting.avatarUrl != fetchedVideo.channel.photo) {
              await settingsService.updateChannelAvatar(fetchedVideo.channel.id, fetchedVideo.channel.photo);
              logger.trace("[BG Poll Cycle] ($videoId) Attempted passive avatar update for subscribed channel.");
            } else if (channelSetting != null) {
              logger.trace("[BG Poll Cycle] ($videoId) Avatar already up-to-date or no photo available. Skipping passive update.");
            }
          } catch (e, s) {
            logger.error("[BG Poll Cycle] ($videoId) Error updating channel avatar via SettingsService", e, s);
          }

          processedCount++;
        } catch (e, s) {
          logger.error("BG Poll Cycle: Error processing video $videoId.", e, s);
          processingErrorCount++;
          if (currentError.isEmpty) {
            currentError = "Error processing video ${fetchedVideo.id}: ${e.toString().split('\n').first}";
          }
        }
      }
      logger.debug("BG Poll Cycle: Processed $processedCount videos ($processingErrorCount errors during processing).");

      logger.info("BG Poll Cycle: Executing ${allActions.length} collected notification actions...");
      try {
        await actionHandler.executeActions(allActions);
        logger.info("BG Poll Cycle: Action handler finished executing actions.");
      } catch (e, s) {
        logger.error("BG Poll Cycle: Error executing notification actions.", e, s);
        if (currentError.isEmpty) currentError = "Notification Action Error: ${e.toString().split('\n').first}";
      }
    } else {
      logger.info("BG Poll Cycle: No distinct videos to process after fetching and deduplication.");
    }

    if (currentError.isNotEmpty) {
      errorNotifier.state = currentError;
    } else {
      errorNotifier.state = null;
    }
    await settingsService.setLastPollTime(currentPollTime);
    logger.info("BG Poll Cycle: Updated last poll time to ${currentPollTime.toIso8601String()}");
  } catch (e, s) {
    logger.fatal("BG Poll Cycle: Unhandled FATAL error during cycle execution.", e, s);
    try {
      errorNotifier.state = "FATAL Poll Error: ${e.toString().split('\n').first}";
    } catch (notifierError) {
      logger.error("BG Poll Cycle: Failed to update background error state during FATAL error.", notifierError);
    }
  } finally {
    logger.info("BG Poll Cycle: --- _executePollCycle END ---");
  }
}
