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
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
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
    _logger.info('[BG Poller Service] Attempting to stop service via invoke...');
    try {
      _service.invoke("stopService");
      _logger.info('[BG Poller Service] Invoked "stopService".');
    } catch (e, s) {
      _logger.error('[BG Poller Service] ERROR invoking "stopService"', e, s);
    }
  }

  @override
  Future<bool> isRunning() async {
    try {
      final running = await _service.isRunning();
      _logger.trace('[BG Poller Service] isRunning check returned: $running');
      return running;
    } catch (e, s) {
      _logger.error('[BG Poller Service] ERROR checking if service is running', e, s);
      return false;
    }
  }

  @override
  Future<void> triggerPoll() async {
    _logger.info('[BG Poller Service] Attempting to trigger manual poll via invoke...');
    try {
      _service.invoke("triggerPoll");
      _logger.info('[BG Poller Service] Invoked "triggerPoll".');
    } catch (e, s) {
      _logger.error('[BG Poller Service] ERROR invoking "triggerPoll"', e, s);
    }
  }

  @override
  void notifySettingChanged(String key, dynamic value) {
    _logger.debug('[BG Poller Service Invoke] Notifying background: Setting changed - Key=$key');
    try {
      _service.invoke('updateSetting', {'key': key, 'value': value});
      _logger.trace('[BG Poller Service Invoke] Invoked "updateSetting" for key: $key');
    } catch (e, s) {
      _logger.error('[BG Poller Service Invoke] ERROR invoking "updateSetting" for key: $key', e, s);
    }
  }
}

Timer? pollingTimer;
Duration currentPollFrequency = const Duration(minutes: 10);
bool isPolling = false;
ProviderContainer? _backgroundContainer;

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // ignore: avoid_print
  print("BG Isolate: onStart ENTRY POINT.");

  try {
    DartPluginRegistrant.ensureInitialized();
    // ignore: avoid_print
    print("BG Isolate: DartPluginRegistrant ensured.");

    _backgroundContainer = ProviderContainer(overrides: [main_providers.isolateContextProvider.overrideWithValue(IsolateContext.background)]);
    // ignore: avoid_print
    print("BG Isolate: ProviderContainer created.");

    final ILoggingService logger = _backgroundContainer!.read(loggingServiceProvider);
    logger.info('BG Isolate: onStart() called, Logger Service obtained from Container.');

    try {
      tz.initializeTimeZones();
      logger.info('BG Isolate: Timezones initialized.');
    } catch (e, s) {
      logger.error("BG Isolate: Failed to initialize timezones.", e, s);
    }

    logger.info('BG Isolate: STARTED successfully.');

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        try {
          logger.info("BG Isolate Listen(setAsForeground): Received.");
          service.setAsForegroundService();
          logger.info("BG Isolate Listen(setAsForeground): Set to foreground OK.");
        } catch (e, s) {
          logger.error("BG Isolate Listen(setAsForeground): ERROR", e, s);
        }
      });
      service.on('setAsBackground').listen((event) {
        try {
          logger.info("BG Isolate Listen(setAsBackground): Received.");
          service.setAsBackgroundService();
          logger.info("BG Isolate Listen(setAsBackground): Set to background OK.");
        } catch (e, s) {
          logger.error("BG Isolate Listen(setAsBackground): ERROR", e, s);
        }
      });
    }
    service.on('stopService').listen((event) {
      try {
        logger.info("BG Isolate Listen(stopService): Received.");
        pollingTimer?.cancel();
        logger.info("BG Isolate Listen(stopService): Polling timer cancelled.");
        service.stopSelf();
        logger.info("BG Isolate Listen(stopService): stopSelf() called.");

        _backgroundContainer?.dispose();
        _backgroundContainer = null;
        logger.info("BG Isolate Listen(stopService): Container disposed.");
      } catch (e, s) {
        logger.error("BG Isolate Listen(stopService): ERROR", e, s);

        try {
          service.stopSelf();
          _backgroundContainer?.dispose();
          _backgroundContainer = null;
        } catch (_) {} // Ignore cleanup errors during error handling
      }
    });

    service.on('triggerPoll').listen((event) async {
      if (isPolling) {
        logger.warning("BG Isolate Listen(triggerPoll): Received while already polling, skipping.");
        return;
      }
      logger.info('BG Isolate Listen(triggerPoll): --- Manual Poll START ---');
      isPolling = true;
      try {
        if (service is AndroidServiceInstance) {
          try {
            service.setForegroundNotificationInfo(
              title: "Holodex Notifier",
              content: "Manual poll starting @ ${DateTime.now().toLocal().toString().substring(11, 19)}",
            );
            logger.debug('BG Isolate Listen(triggerPoll): setForegroundNotificationInfo (Starting)');
          } catch (e, s) {
            logger.error('BG Isolate Listen(triggerPoll): Failed to set starting foreground notification', e, s);
          }
        }

        if (_backgroundContainer == null) {
          logger.fatal("BG Isolate Listen(triggerPoll): Container is NULL before executing poll cycle. Aborting poll.");
          throw Exception("Background container was null before manual poll execution.");
        }
        await _executePollCycle(_backgroundContainer!);
      } catch (e, s) {
        logger.fatal("BG Isolate Listen(triggerPoll): Unhandled FATAL error during MANUAL poll cycle execution.", e, s);
        try {
          _backgroundContainer?.read(backgroundLastErrorProvider.notifier).state = "Manual Poll FATAL Error: ${e.toString().split('\n').first}";
        } catch (notifierError, notifierStack) {
          logger.error("BG Isolate Listen(triggerPoll): Failed to update error state during FATAL poll error.", notifierError, notifierStack);
        }
      } finally {
        isPolling = false;
        logger.info('BG Isolate Listen(triggerPoll): --- Manual Poll END ---');
        if (service is AndroidServiceInstance) {
          try {
            final lastError = _backgroundContainer?.read(backgroundLastErrorProvider);
            service.setForegroundNotificationInfo(
              title: "Holodex Notifier",
              content:
                  lastError != null
                      ? "Manual poll finished with error @ ${DateTime.now().toLocal().toString().substring(11, 19)}"
                      : "Manual poll finished @ ${DateTime.now().toLocal().toString().substring(11, 19)} - Waiting...",
            );
            logger.debug('BG Isolate Listen(triggerPoll): setForegroundNotificationInfo (Finished)');
          } catch (e, s) {
            logger.error('BG Isolate Listen(triggerPoll): Failed to set finished foreground notification', e, s);
          }
        }
      }
    });

    service.on('updateSetting').listen((event) async {
      try {
        if (event == null || event['key'] == null || _backgroundContainer == null) {
          logger.warning("BG Isolate Listen(updateSetting): Received invalid event or container is null: $event");
          return;
        }

        final String key = event['key'];
        final dynamic value = event['value'];
        logger.info("BG Isolate Listen(updateSetting): Received Key=$key, Value=$value");

        if (key == 'pollFrequency' && value is int) {
          final newFrequency = Duration(minutes: value);
          if (newFrequency != currentPollFrequency && newFrequency.inMinutes > 0) {
            logger.info("BG Isolate Listen(updateSetting): Updating poll frequency to $value minutes.");
            currentPollFrequency = newFrequency;
            pollingTimer?.cancel();
            logger.debug("BG Isolate Listen(updateSetting): Timer cancelled due to frequency update.");
            if (isPolling) {
              logger.warning("BG Isolate Listen(updateSetting): Poll active during frequency update. New timer starts after current poll.");
            } else {
              logger.debug("BG Isolate Listen(updateSetting): Restarting timer with new frequency immediately.");

              if (_backgroundContainer != null) {
                await startPollingTimer(_backgroundContainer!, service);
              } else {
                logger.error("BG Isolate Listen(updateSetting): Container is NULL, cannot restart timer.");
              }
            }
          } else if (newFrequency.inMinutes <= 0) {
            logger.warning("BG Isolate Listen(updateSetting): Received invalid poll frequency ($value minutes). Ignoring.");
          } else {
            logger.debug("BG Isolate Listen(updateSetting): Poll frequency ($value min) unchanged.");
          }
        } else if (key == 'reminderLeadTime' && value is int) {
          logger.info("BG Isolate Listen(updateSetting): Received reminderLeadTime update ($value min). Will use on next poll cycle.");
        } else if (key == 'apiKey') {
          logger.debug("BG Isolate Listen(updateSetting): API Key update notification received. No immediate background action.");
        } else if (key == 'notificationFormat') {
          logger.info("BG Isolate Listen(updateSetting): Received 'notificationFormat' update.");
          if (_backgroundContainer != null) {
            try {
              final notificationService = _backgroundContainer!.read(notificationServiceProvider);
              await notificationService.reloadFormatConfig();
              logger.info("BG Isolate Listen(updateSetting): Instructed NotificationService to reload format config.");
            } catch (e, s) {
              logger.error("BG Isolate Listen(updateSetting): Error instructing NotificationService to reload format config.", e, s);
            }
          } else {
            logger.error("BG Isolate Listen(updateSetting): Container is NULL, cannot reload format config.");
          }
        } else {
          logger.warning("BG Isolate Listen(updateSetting): Received unhandled setting update key: $key");
        }
      } catch (e, s) {
        logger.error("BG Isolate Listen(updateSetting): Unhandled ERROR in listener callback", e, s);
      }
    });

    ISettingsService? settingsService;
    try {
      logger.info("BG Isolate: Starting main initialization logic...");
      logger.debug("BG Isolate: Ensuring SettingsService resolution...");
      if (_backgroundContainer == null) throw Exception("Background Container is null during settings service resolution");
      settingsService = await _backgroundContainer!.read(settingsServiceFutureProvider.future);
      logger.info("BG Isolate: SettingsService resolved.");

      logger.debug("BG Isolate: Waiting for Main Isolate readiness flag...");
      bool mainReady = false;
      int waitAttempts = 0;
      const maxWaitAttempts = 30;
      while (!mainReady && waitAttempts < maxWaitAttempts) {
        waitAttempts++;
        try {
          mainReady = await settingsService!.getMainServicesReady();
        } catch (e, s) {
          logger.error("BG Isolate: Error checking main readiness flag (Attempt $waitAttempts/$maxWaitAttempts). Retrying in 2s...", e, s);
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }

        if (!mainReady) {
          logger.info("BG Isolate: Main isolate not ready (Attempt $waitAttempts/$maxWaitAttempts), waiting 2 seconds...");
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (!mainReady) {
        logger.fatal("BG Isolate: FATAL: Main isolate did not become ready after $maxWaitAttempts attempts. Stopping service.");
        throw Exception("Main isolate readiness timeout");
      }
      logger.info("BG Isolate: Main isolate readiness confirmed.");

      logger.debug("BG Isolate: Ensuring NotificationService resolution...");
      if (_backgroundContainer == null) throw Exception("Background Container is null during notification service resolution");
      final notificationServiceInstance = await _backgroundContainer!.read(notificationServiceFutureProvider.future);
      logger.info("BG Isolate: Notification Service resolved.");

      if (notificationServiceInstance is LocalNotificationService) {
        try {
          logger.debug("BG Isolate: Ensuring Notification Format Config is loaded in Background...");
          await notificationServiceInstance.loadFormatConfig();
          logger.info("BG Isolate: Notification Format Config loading attempted/ensured.");
        } catch (e, s) {
          logger.warning("BG Isolate: WARNING: Failed to load Notification Format Config in background.", e, s);
        }
      } else {
        logger.warning("BG Isolate: Resolved Notification Service is not LocalNotificationService type.");
      }

      logger.info("BG Isolate: Starting the main polling timer...");
      if (_backgroundContainer == null) throw Exception("Background Container is null before starting timer");
      currentPollFrequency = await settingsService!.getPollFrequency();
      logger.info("BG Isolate: Initial poll frequency read: ${currentPollFrequency.inMinutes} minutes.");
      await startPollingTimer(_backgroundContainer!, service);
    } catch (e, s) {
      logger.fatal("BG Isolate: FATAL error during main background initialization.", e, s);
      try {
        service.stopSelf();
        _backgroundContainer?.dispose();
        _backgroundContainer = null;
      } catch (stopErr, stopST) {
        logger.error("BG Isolate: Failed to stop service/dispose container during FATAL init error.", stopErr, stopST);
      }
    }
  } catch (e, s) {
    // ignore: avoid_print
    print("BG Isolate: VERY EARLY FATAL ERROR in onStart: $e\n$s");

    try {
      service.stopSelf();
    } catch (_) {}

    _backgroundContainer?.dispose();
    _backgroundContainer = null;
  }
}

Future<void> startPollingTimer(ProviderContainer container, ServiceInstance service) async {
  ILoggingService? logger;
  try {
    logger = container.read(loggingServiceProvider)!;
    logger.info("BG Isolate: startPollingTimer invoked.");

    final ISettingsService settingsService = container.read(settingsServiceProvider);

    pollingTimer?.cancel();
    logger.debug("BG Isolate Timer Control: Previous timer (if any) cancelled.");

    currentPollFrequency = await settingsService.getPollFrequency();
    if (currentPollFrequency.inMinutes <= 0) {
      logger.warning(
        "BG Isolate Timer Control: Invalid poll frequency (${currentPollFrequency.inMinutes} min) read from settings. Defaulting to 10 min.",
      );
      currentPollFrequency = const Duration(minutes: 10);
    }
    logger.info("BG Isolate Timer Control: Setting poll frequency to: ${currentPollFrequency.inMinutes} minutes");

    pollingTimer = Timer.periodic(currentPollFrequency, (timer) async {
      ILoggingService? callbackLogger;
      try {
        callbackLogger = container.read(loggingServiceProvider)!;
        callbackLogger.trace("BG Isolate Timer Tick: Timer fired. Checking polling status.");

        if (isPolling) {
          callbackLogger.warning("BG Isolate Timer Tick: Skipping timed poll, previous cycle still running.");
          return;
        }
        callbackLogger.info('BG Isolate Timer Tick: --- Timed Poll START ---');
        isPolling = true;

        if (service is AndroidServiceInstance) {
          try {
            service.setForegroundNotificationInfo(
              title: "Holodex Notifier",
              content: "Polling @ ${DateTime.now().toLocal().toString().substring(11, 19)}...",
            );
            callbackLogger.debug('BG Isolate Timer Tick: setForegroundNotificationInfo (Starting)');
          } catch (e, s) {
            callbackLogger.error('BG Isolate Timer Tick: Failed to set starting foreground notification', e, s);
          }
        }

        await _executePollCycle(container);
      } catch (e, s) {
        final currentLogger = callbackLogger ?? container.read(loggingServiceProvider)!;
        currentLogger.fatal("BG Isolate Timer Tick: Unhandled FATAL error during TIMED poll cycle.", e, s);
        try {
          container.read(backgroundLastErrorProvider.notifier).state = "Timed Poll FATAL Error: ${e.toString().split('\n').first}";
        } catch (notifierError, notifierStack) {
          currentLogger.error("BG Isolate Timer Tick: Failed to update error state during FATAL poll error.", notifierError, notifierStack);
        }
      } finally {
        final currentLogger = callbackLogger ?? container.read(loggingServiceProvider)!;
        isPolling = false;
        currentLogger.info('BG Isolate Timer Tick: --- Timed Poll END ---');

        if (service is AndroidServiceInstance) {
          try {
            final lastError = container.read(backgroundLastErrorProvider);
            service.setForegroundNotificationInfo(
              title: "Holodex Notifier",
              content:
                  lastError != null
                      ? "Poll finished with error @ ${DateTime.now().toLocal().toString().substring(11, 19)}"
                      : "Poll finished @ ${DateTime.now().toLocal().toString().substring(11, 19)} - Waiting...",
            );
            currentLogger.debug('BG Isolate Timer Tick: setForegroundNotificationInfo (Finished)');
          } catch (e, s) {
            currentLogger.error('BG Isolate Timer Tick: Failed to set finished foreground notification', e, s);
          }
        }

        currentLogger.trace("BG Isolate Timer Tick: Waiting for next tick in ${currentPollFrequency.inMinutes} min.");
      }
    });
    logger.info("BG Isolate Timer Control: New Polling timer started successfully for ${currentPollFrequency.inMinutes} minutes.");
  } catch (e, s) {
    final currentLogger = logger ?? container.read(loggingServiceProvider)!;
    currentLogger.fatal("BG Isolate Timer Control: FATAL error setting up timer.", e, s);
    pollingTimer?.cancel();
    try {
      currentLogger.error("BG Isolate Timer Control: Timer setup failed, background tasks will likely stop functioning correctly.");
    } catch (stopErr, stopST) {
      currentLogger.error("BG Isolate Timer Control: Error during timer setup's error handling.", stopErr, stopST);
    }
  }
}

Future<void> _executePollCycle(ProviderContainer container) async {
  ILoggingService logger;
  ISettingsService settingsService;
  IConnectivityService connectivityService;
  IApiService apiService;
  ICacheService cacheService;
  INotificationDecisionService decisionService;
  INotificationActionHandler actionHandler;
  StateController<String?> errorNotifier;

  try {
    logger = container.read(loggingServiceProvider);
    settingsService = container.read(settingsServiceProvider);
    connectivityService = container.read(connectivityServiceProvider);
    apiService = container.read(apiServiceProvider);
    cacheService = container.read(cacheServiceProvider);
    decisionService = container.read(notificationDecisionServiceProvider);
    actionHandler = container.read(notificationActionHandlerProvider);
    errorNotifier = container.read(backgroundLastErrorProvider.notifier);
  } catch (e, s) {
    final tempLogger = container.exists(loggingServiceProvider) ? container.read(loggingServiceProvider) : null;
    if (tempLogger == null) {
      // ignore: avoid_print
      print("BG Poll Cycle: FATAL ERROR resolving dependencies. Cycle cannot run. $e\n$s");
    }

    try {
      container.read(backgroundLastErrorProvider.notifier).state = "FATAL Dependency Error: $e";
    } catch (_) {}
    return;
  }

  logger.info("BG Poll Cycle: --- _executePollCycle START ---");
  String currentCycleError = '';

  try {
    try {
      logger.debug("BG Poll Cycle: Checking connectivity...");
      final bool isConnected = await connectivityService.isConnected();
      if (!isConnected) {
        currentCycleError = 'No internet connection.';
        logger.warning("BG Poll Cycle: $currentCycleError Skipping poll this cycle.");

        return;
      }
      logger.debug("BG Poll Cycle: Internet connection confirmed.");
    } catch (e, s) {
      currentCycleError = "Connectivity Check Error: ${e.toString().split('\n').first}";
      logger.error("BG Poll Cycle: Failed connectivity check.", e, s);

      errorNotifier.state = currentCycleError;
      return;
    }

    final DateTime currentPollTime = DateTime.now().toUtc();
    logger.info("BG Poll Cycle: Starting poll sequence at ${currentPollTime.toIso8601String()}");
    final DateTime fromTime = currentPollTime;

    Duration reminderLeadTime;
    List<ChannelSubscriptionSetting> channelSettingsList;
    try {
      reminderLeadTime = await settingsService.getReminderLeadTime();
      logger.debug("BG Poll Cycle: Current Reminder Lead Time: ${reminderLeadTime.inMinutes} minutes");

      logger.debug("BG Poll Cycle: Loading channel subscriptions...");
      channelSettingsList = await settingsService.getChannelSubscriptions();
    } catch (e, s) {
      currentCycleError = "Settings Load Error: ${e.toString().split('\n').first}";
      logger.error("BG Poll Cycle: Failed to load critical settings.", e, s);
      errorNotifier.state = currentCycleError;
      return;
    }

    if (channelSettingsList.isEmpty) {
      logger.info("BG Poll Cycle: No channels subscribed. Poll cycle complete (No API fetch needed).");
      await settingsService.setLastPollTime(currentPollTime);
      errorNotifier.state = null;
      return;
    }

    final Map<String, ChannelSubscriptionSetting> channelSettingsMap = {for (var s in channelSettingsList) s.channelId: s};
    final Set<String> subscribedIds = channelSettingsList.map((s) => s.channelId).toSet();
    logger.debug("BG Poll Cycle: Subscribed IDs: ${subscribedIds.length}");

    List<VideoFull> liveFeedVideos = [];
    List<VideoFull> allCollabVideos = [];

    logger.debug("BG Poll Cycle: Attempting to fetch live feed videos from API...");
    try {
      liveFeedVideos = await apiService.fetchLiveVideos(channelIds: subscribedIds);
      logger.info("BG Poll Cycle: Fetched ${liveFeedVideos.length} videos from /users/live.");
    } catch (e, s) {
      logger.error("BG Poll Cycle: Error fetching live feed videos.", e, s);
      if (currentCycleError.isEmpty) currentCycleError = "Live Feed Fetch Error: ${e.toString().split('\n').first}";
    }

    logger.debug(
      "BG Poll Cycle: Attempting to fetch collab videos for ${subscribedIds.length} applicable channels (from: ${fromTime.toIso8601String()})...",
    );
    for (final channelSetting in channelSettingsList) {
      final channelId = channelSetting.channelId;
      if (!channelSetting.notifyMentions) {
        logger.trace("[BG Poll Cycle] Skipping collabs fetch for $channelId (notifyMentions=false).");
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
        if (currentCycleError.isEmpty) currentCycleError = "Collab Fetch Error ($channelId): ${e.toString().split('\n').first}";
      }
    }

    List<VideoFull> distinctVideos = [];
    Map<String, Set<String>> mentionContextMap = {};
    try {
      logger.debug("BG Poll Cycle: Processing fetched video data...");
      List<VideoFull> combinedVideos = [...liveFeedVideos, ...allCollabVideos];
      final Set<String> seenVideoIds = {};

      for (final video in combinedVideos) {
        if (seenVideoIds.add(video.id)) {
          distinctVideos.add(video);
        }
      }
      logger.info("BG Poll Cycle: Combined ${combinedVideos.length} videos -> ${distinctVideos.length} distinct videos after deduplication.");

      logger.debug("BG Poll Cycle: Building mention context map for ${subscribedIds.length} channels...");
      for (final video in distinctVideos) {
        if (video.mentions != null) {
          for (final mention in video.mentions!) {
            if (subscribedIds.contains(mention.id)) {
              mentionContextMap.putIfAbsent(video.id, () => {}).add(mention.id);
              logger.trace("BG Poll Cycle Map: Added mention ${mention.id} for video ${video.id}");
            }
          }
        }
      }
      logger.info("BG Poll Cycle: Mention context map built with ${mentionContextMap.length} entries relevant to subscriptions.");
    } catch (e, s) {
      currentCycleError = "Data Processing Error: ${e.toString().split('\n').first}";
      logger.error("BG Poll Cycle: Error during video data processing (dedup/mapping).", e, s);
      errorNotifier.state = currentCycleError;

      return;
    }

    final List<NotificationAction> allActions = [];
    int processedCount = 0;
    int processingErrorCount = 0;

    if (distinctVideos.isNotEmpty) {
      logger.debug("BG Poll Cycle: Determining notification actions for ${distinctVideos.length} videos...");
      for (final fetchedVideo in distinctVideos) {
        final videoId = fetchedVideo.id;
        try {
          CachedVideo? cachedVideo;
          try {
            cachedVideo = await cacheService.getVideo(videoId);
          } catch (cacheError, cacheStack) {
            logger.warning("BG Poll Cycle ($videoId): Failed to get cached video state. Proceeding without cache.", cacheError, cacheStack);
          }

          final Set<String>? mentionedForChannels = mentionContextMap[videoId];

          List<NotificationAction> videoActions = [];
          try {
            videoActions = await decisionService.determineActionsForVideoUpdate(
              fetchedVideo: fetchedVideo,
              cachedVideo: cachedVideo,
              allChannelSettings: channelSettingsList,
              mentionedForChannels: mentionedForChannels,
            );
            logger.trace("BG Poll Cycle ($videoId): Determined ${videoActions.length} actions.");
            allActions.addAll(videoActions);
          } catch (decisionError, decisionStack) {
            logger.error("BG Poll Cycle ($videoId): ERROR in NotificationDecisionService.", decisionError, decisionStack);
            processingErrorCount++;
            if (currentCycleError.isEmpty) {
              currentCycleError = "Decision Error ($videoId): ${decisionError.toString().split('\n').first}";
            }

            continue;
          }

          try {
            final channelSetting = channelSettingsMap[fetchedVideo.channel.id];
            if (channelSetting != null && fetchedVideo.channel.photo != null && channelSetting.avatarUrl != fetchedVideo.channel.photo) {
              await settingsService.updateChannelAvatar(fetchedVideo.channel.id, fetchedVideo.channel.photo);
              logger.trace("[BG Poll Cycle] ($videoId): Attempted passive avatar update for subscribed channel.");
            } else if (channelSetting != null) {}
          } catch (e, s) {
            logger.error("[BG Poll Cycle] ($videoId): Error during passive avatar update.", e, s);
          }

          processedCount++;
        } catch (e, s) {
          logger.error("BG Poll Cycle: Unhandled loop error processing video $videoId.", e, s);
          processingErrorCount++;
          if (currentCycleError.isEmpty) {
            currentCycleError = "Video Loop Error ($videoId): ${e.toString().split('\n').first}";
          }
        }
      }
      logger.debug(
        "BG Poll Cycle: Finished determining actions. Processed $processedCount videos ($processingErrorCount errors). Total actions: ${allActions.length}.",
      );

      if (allActions.isNotEmpty) {
        logger.info("BG Poll Cycle: Executing ${allActions.length} collected notification actions...");
        try {
          await actionHandler.executeActions(allActions);
          logger.info("BG Poll Cycle: Action handler finished executing actions successfully.");
        } catch (e, s) {
          logger.error("BG Poll Cycle: Error executing notification actions via Handler.", e, s);
          if (currentCycleError.isEmpty) currentCycleError = "Notification Action Handler Error: ${e.toString().split('\n').first}";
        }
      } else {
        logger.info("BG Poll Cycle: No notification actions to execute.");
      }
    } else {
      logger.info("BG Poll Cycle: No distinct videos found after fetching/deduplication. No actions needed.");
    }

    if (currentCycleError.isNotEmpty) {
      logger.warning("BG Poll Cycle: Cycle completed with errors: $currentCycleError");
      errorNotifier.state = currentCycleError;
    } else {
      logger.info("BG Poll Cycle: Cycle completed successfully.");
      errorNotifier.state = null;
    }
    try {
      await settingsService.setLastPollTime(currentPollTime);
      logger.info("BG Poll Cycle: Updated last successful poll time to ${currentPollTime.toIso8601String()}");
    } catch (e, s) {
      logger.error("BG Poll Cycle: Failed to update last poll time in settings.", e, s);

      errorNotifier.state = "${errorNotifier.state ?? ""} | Failed to save poll time.";
    }
  } catch (e, s) {
    logger.fatal("BG Poll Cycle: Unhandled FATAL error during cycle execution.", e, s);
    try {
      errorNotifier.state = "FATAL Poll Cycle Error: ${e.toString().split('\n').first}";
    } catch (notifierError, notifierStack) {
      logger.error("BG Poll Cycle: Failed to update error state during FATAL cycle error.", notifierError, notifierStack);
    }
  } finally {
    logger.info("BG Poll Cycle: --- _executePollCycle END ---");
  }
}
