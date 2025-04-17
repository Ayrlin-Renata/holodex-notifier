// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\infrastructure\services\background_poller_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui'; // Required for DartPluginRegistrant

import 'package:drift/drift.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:holodex_notifier/application/state/background_service_state.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart'; // Need lastErrorProvider
import 'package:holodex_notifier/domain/interfaces/background_polling_service.dart';
import 'package:holodex_notifier/domain/interfaces/api_service.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/connectivity_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart'; // Import notification service
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart'; // Import database for CachedVideo
import 'package:holodex_notifier/infrastructure/services/local_notification_service.dart';
import 'package:holodex_notifier/main.dart' hide ErrorApp, MainApp, appControllerProvider; // Hide specific exports if needed
import 'package:holodex_notifier/main.dart' as main_providers show isolateContextProvider; // *** Import with prefix ***
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// Manages the setup and control of the background service (from main isolate).
class BackgroundPollerService implements IBackgroundPollingService {
  final _service = FlutterBackgroundService();
  static const String backgroundChannelId = 'holodex_notifier_background_service';

  @override
  Future<void> initialize() async {
    // TODO: Replace print with real logging if injectable here
    print('[BG Poller Service] Initializing...');

    if (Platform.isAndroid) {
      print('[BG Poller Service] Creating notification channel: $backgroundChannelId');
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
        print('[BG Poller Service] Notification channel $backgroundChannelId created/ensured.');
      } catch (e, s) {
        print('[BG Poller Service] ERROR creating notification channel $backgroundChannelId: $e\n$s');
      }
    }

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // MUST be false for main isolate init to work
        autoStartOnBoot: true, // Enable auto-start on boot
        isForegroundMode: true,
        notificationChannelId: backgroundChannelId,
        initialNotificationTitle: 'Holodex Notifier',
        initialNotificationContent: 'Initializing service...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true, // Auto-start for iOS might need different handling
        onForeground: onStart,
        // onBackground: onIosBackground, // Define this if needed for iOS background tasks
      ),
    );

    print('[BG Poller Service] Configuration complete.');
  }

  @override
  Future<void> startPolling() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      print('[BG Poller Service] Attempting to start background service via startService()...');
      try {
        await _service.startService();
        print('[BG Poller Service] startService() called successfully.');
      } catch (e, s) {
        print('[BG Poller Service] ERROR calling startService(): $e\n$s');
      }
    } else {
      print('[BG Poller Service] Service is already running.');
    }
  }

  @override
  Future<void> stopPolling() async {
    print('[BG Poller Service] Stopping service...');
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
    // Use a non-injectable logger or print for this simple cross-isolate trigger.
    // The background isolate has its own logger instance.
    print('[BG Poller Service Invoke] Notifying background: Setting changed - Key=$key');
    _service.invoke('updateSetting', {'key': key, 'value': value});
  }
}

// --- Background Isolate Entry Point Variables (accessible within onStart scope) ---
Timer? pollingTimer;
Duration currentPollFrequency = const Duration(minutes: 10); // Default used until settings resolved
bool isPolling = false; // Flag to prevent concurrent cycles

/// --- Background Isolate Entry Point ---
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final container = ProviderContainer(
    overrides: [
      // Override the isolate context for this container
      main_providers.isolateContextProvider.overrideWithValue(IsolateContext.background),
    ],
  );
  final ILoggingService logger = container.read(loggingServiceProvider);
  tz.initializeTimeZones();
  logger.info('BG Isolate: STARTED.');

  // --- Setup Service Listeners ---
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
    container.dispose(); // Dispose container when service stops
  });

  // Listener for manual poll trigger
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
      // Pass container down
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
        // Update notification after finishing
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

  // Listener for settings updates from main isolate
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
        pollingTimer?.cancel(); // Cancel existing timer
        if (isPolling) {
          logger.warning("BG Isolate: Poll cycle active during frequency update. New timer will start after cycle completes.");
          // The new frequency will be used when the current cycle finishes and the timer restarts.
        } else {
          logger.debug("BG Isolate: Restarting timer with new frequency.");
          // Pass container down
          await startPollingTimer(container, service); // Restart with new freq
        }
      } else {
        logger.debug("BG Isolate: Received poll frequency update, but value ($value min) is unchanged.");
      }
    } else if (key == 'reminderLeadTime' && value is int) {
      // No immediate action needed in the background timer itself.
      // The new lead time will be read from settingsService
      // at the beginning of the *next* _executePollCycle.
      logger.info("BG Isolate: Received reminderLeadTime update ($value min). Value will be used on next poll cycle.");
      // Optionally, trigger an immediate poll if desired, but usually unnecessary:
      // service.invoke('triggerPoll');
    } else if (key == 'apiKey') {
      // No immediate action needed, Dio interceptor gets it on next request.
      logger.debug("BG Isolate: Received API Key update notification. No background action needed.");
    } else if (key == 'notificationFormat') {
      logger.info("BG Isolate: Received 'notificationFormat' update notification.");
      try {
        // Resolve the NotificationService within the background isolate's container
        final notificationService = container.read(notificationServiceProvider);
        // Call the new reload method
        await notificationService.reloadFormatConfig();
        logger.info("BG Isolate: Successfully instructed NotificationService to reload format config.");
      } catch (e, s) {
        logger.error("BG Isolate: Error reloading notification format config.", e, s);
        // Potentially update error state or take other action if reload fails
      }
    } else {
      logger.warning("BG Isolate: Received unhandled setting update key: $key");
    }
  });

  // --- Initialization Wait Loop ---
  ISettingsService? settingsService;
  try {
    logger.info("BG Isolate: Initializing dependencies and waiting for main isolate readiness...");
    try {
      logger.debug("BG Isolate: Ensuring SettingsService instance is resolved...");
      // Read the FutureProvider directly to ensure it completes
      settingsService = await container.read(settingsServiceFutureProvider.future);
      logger.debug("BG Isolate: SettingsService instance resolved.");
    } catch (e, s) {
      logger.fatal("BG Isolate: FATAL: Failed to resolve SettingsService FutureProvider.", e, s);
      service.stopSelf();
      container.dispose();
      return; // Cannot proceed without settings
    }
    bool mainReady = false;
    while (!mainReady) {
      try {
        // Read (which resolves the FutureProvider if needed)
        mainReady = await settingsService!.getMainServicesReady();
      } catch (e, s) {
        // This catch might be necessary if settingsServiceFutureProvider itself fails during resolution
        logger.error("BG Isolate: Error resolving SettingsService or checking readiness flag, retrying in 5s...", e, s);
        await Future.delayed(const Duration(seconds: 5));
      }

      if (!mainReady) {
        logger.info("BG Isolate: Main isolate not ready yet, waiting 2 seconds...");
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    logger.info("BG Isolate: Main isolate readiness confirmed. Proceeding with background initialization.");

    late INotificationService notificationServiceInstance; // {{ Define instance variable }}
    try {
      logger.debug("BG Isolate: Ensuring NotificationService instance is resolved...");
      notificationServiceInstance = await container.read(notificationServiceFutureProvider.future);
      logger.info("BG Isolate: Notification Service resolved.");

      if (notificationServiceInstance is LocalNotificationService) {
        try {
          logger.debug("BG Isolate: Ensuring Notification Format Config is loaded...");
          await notificationServiceInstance.loadFormatConfig(); // Await the loading
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
      return; // Cannot proceed without notification service if it's required by handlers
    }

    // Dependencies needed for the timer/poll cycle itself will be resolved inside _executePollCycle
    // or startPollingTimer.

    logger.info("BG Isolate: Starting the main polling timer...");
    // Null assertion ok - settingsService guaranteed non-null if loop succeeded
    currentPollFrequency = await settingsService!.getPollFrequency();
    // Pass container down
    await startPollingTimer(container, service);
  } catch (e, s) {
    logger.fatal("BG Isolate: FATAL error during initial setup/readiness check.", e, s);
    service.stopSelf();
    container.dispose();
  }
}

/// Starts or restarts the periodic polling timer.
Future<void> startPollingTimer(ProviderContainer container, ServiceInstance service) async {
  final ILoggingService logger = container.read(loggingServiceProvider);
  // ############## CHANGE 7: Resolve SettingsService inside the function ##############
  final ISettingsService settingsService = container.read(settingsServiceProvider);

  try {
    pollingTimer?.cancel();
    logger.debug("BG Isolate: Polling timer (if exists) cancelled.");

    // Resolve SettingsService to get frequency
    currentPollFrequency = await settingsService.getPollFrequency();
    // ############## END CHANGE 7 ##############
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
        // Pass the container down
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
          // Update notification after finishing
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
    // Use logger from container
    logger.fatal("BG Isolate: Error retrieving poll frequency or starting timer.", e, s);
    pollingTimer?.cancel();
    try {
      service.stopSelf(); // Attempt to stop the service on critical timer error
      container.dispose();
    } catch (stopErr, stopST) {
      logger.error("BG Isolate: Failed to stop service/dispose container during timer start error.", stopErr, stopST);
    }
  }
}

/// The Core Polling Logic, now including processing video updates.
Future<void> _executePollCycle(ProviderContainer container) async {
  // ############## CHANGE 8: Resolve all needed services inside the cycle ##############
  // This ensures the background container resolves them correctly after the readiness check
  final ILoggingService logger = container.read(loggingServiceProvider);
  final ISettingsService settingsService = container.read(settingsServiceProvider);
  final IConnectivityService connectivityService = container.read(connectivityServiceProvider);
  final IApiService apiService = container.read(apiServiceProvider);
  final ICacheService cacheService = container.read(cacheServiceProvider); // Directly use cache service
  final INotificationDecisionService decisionService = container.read(notificationDecisionServiceProvider);
  final INotificationActionHandler actionHandler = container.read(notificationActionHandlerProvider);

  final errorNotifier = container.read(backgroundLastErrorProvider.notifier);
  // ############## END CHANGE 8 ##############
  String currentError = ''; // Track first error in this cycle

  try {
    logger.debug("BG Poll Cycle: Checking connectivity...");
    final bool isConnected = await connectivityService.isConnected();
    if (!isConnected) {
      currentError = 'No internet connection.';
      logger.warning("BG Poll Cycle: $currentError Skipping poll.");
      errorNotifier.state = currentError; // Update error state provider
      return; // Exit cycle early
    }
    logger.debug("BG Poll Cycle: Internet connection available.");

    final DateTime? lastPollTime = await settingsService.getLastPollTime();
    final DateTime currentPollTime = DateTime.now().toUtc(); // Use consistent time for 'from' and 'setLastPoll'
    // Determine the time range for the API query
    final DateTime fromTime = lastPollTime ?? currentPollTime.subtract(const Duration(hours: 6)); // Default lookback
    logger.info("BG Poll Cycle: Checking for videos since ${fromTime.toIso8601String()}");

    final Duration reminderLeadTime = await settingsService.getReminderLeadTime();
    logger.debug("BG Poll Cycle: Current Reminder Lead Time: ${reminderLeadTime.inMinutes} minutes");

    logger.debug("BG Poll Cycle: Loading channel subscriptions for fetch...");
    final List<ChannelSubscriptionSetting> channelSettingsList = await settingsService.getChannelSubscriptions();
    if (channelSettingsList.isEmpty) {
      logger.info("BG Poll Cycle: No channels subscribed. Skipping API fetch.");
      await settingsService.setLastPollTime(currentPollTime); // Still update poll time
      errorNotifier.state = null; // Clear any previous error
      return; // Exit cycle early
    }
    // Prepare data structures for API call
    final Map<String, ChannelSubscriptionSetting> channelSettingsMap = {for (var s in channelSettingsList) s.channelId: s};
    final Set<String> subscribedIds = {};
    final Set<String> mentionIds = {};
    for (final setting in channelSettingsList) {
      subscribedIds.add(setting.channelId);
      if (setting.notifyMentions) {
        mentionIds.add(setting.channelId);
      }
    }
    logger.debug("BG Poll Cycle: Subscribed IDs: ${subscribedIds.length}, Mention IDs: ${mentionIds.length}");

    logger.debug("BG Poll Cycle: Fetching videos from API...");
    // API Service is resolved above
    final List<VideoFull> fetchedVideos = await apiService.fetchVideos(
      channelIds: subscribedIds,
      mentionChannelIds: mentionIds,
      from: fromTime, // Pass calculated 'from' time
    );
    logger.info("BG Poll Cycle: Fetched ${fetchedVideos.length} videos from API.");

    // --- Batch Update Variables ---
    final List<CachedVideosCompanion> companionsToUpsert = [];
    final List<NotificationAction> allActions = []; // Collect ALL actions here

    int processedCount = 0;
    int errorCount = 0;
    if (fetchedVideos.isNotEmpty) {
      logger.debug("BG Poll Cycle: Processing ${fetchedVideos.length} fetched videos...");
      for (final fetchedVideo in fetchedVideos) {
        final videoId = fetchedVideo.id;
        try {
          // 1. Get cached video data
          final cachedVideo = await cacheService.getVideo(videoId);

          // 2. Create the BASE state companion (non-notification fields)
          final baseCompanion = CachedVideosCompanion(
            videoId: Value(videoId),
            channelId: Value(fetchedVideo.channel.id),
            status: Value(fetchedVideo.status),
            startScheduled: Value(fetchedVideo.startScheduled?.toIso8601String()),
            startActual: Value(fetchedVideo.startActual?.toIso8601String()),
            availableAt: Value(fetchedVideo.availableAt.toIso8601String()),
            videoType: Value(fetchedVideo.type),
            topicId: Value(fetchedVideo.topicId),
            certainty: Value(fetchedVideo.certainty),
            mentionedChannelIds: Value(fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? []),
            videoTitle: Value(fetchedVideo.title),
            channelName: Value(fetchedVideo.channel.name),
            channelAvatarUrl: Value(fetchedVideo.channel.photo),
            // !! Always update lastSeenTimestamp !!
            lastSeenTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
            // Notification fields are NOT set here, they come from UpdateCacheAction
            isPendingNewMediaNotification: const Value.absent(),
            scheduledLiveNotificationId: const Value.absent(),
            scheduledReminderNotificationId: const Value.absent(),
            scheduledReminderTime: const Value.absent(),
            lastLiveNotificationSentTime: const Value.absent(),
          );
          companionsToUpsert.add(baseCompanion); // Add base info for DB upsert

          // 3. Get notification actions from Decision Service
          // Pass fetched and cached data. Settings are handled inside the service.
          final List<NotificationAction> videoActions = await decisionService.determineActionsForVideoUpdate(
            fetchedVideo: fetchedVideo,
            cachedVideo: cachedVideo,
          );
          allActions.addAll(videoActions); // Collect actions

          // 4. Passively update avatar (can remain here)
          try {
            await settingsService.updateChannelAvatar(fetchedVideo.channel.id, fetchedVideo.channel.photo);
            logger.debug("[BG Poll Cycle] ($videoId) Attempted passive avatar update.");
          } catch (e, s) {
            logger.error("[BG Poll Cycle] ($videoId) Error updating channel avatar via SettingsService", e, s);
          }

          processedCount++;
        } catch (e, s) {
          logger.error("BG Poll Cycle: Error processing video ${fetchedVideo.id}.", e, s);
          errorCount++;
          final truncatedError = e.toString().split('\n').first;
          if (currentError.isEmpty) {
            currentError = "Error processing video ${fetchedVideo.id}: $truncatedError";
          }
        }
      }
      logger.debug("BG Poll Cycle: Processed $processedCount videos ($errorCount errors during processing).");

      // --- Perform Batch Database Update AFTER Loop ---
      if (companionsToUpsert.isNotEmpty) {
        logger.info("BG Poll Cycle: Performing batch database upsert for ${companionsToUpsert.length} videos...");
        try {
          container.read(cacheServiceProvider); // Resolve cache service here
          final db = container.read(databaseProvider); // Resolve database for batch
          await db.batch((batch) {
            // Use batch.insertAll with onConflict strategy for upsert behavior
            batch.insertAll(
              db.cachedVideos,
              companionsToUpsert,
              mode: InsertMode.insertOrReplace, // Upsert mode
            );
          });
          logger.info("BG Poll Cycle: Batch database upsert successful.");
        } catch (e, s) {
          logger.error("BG Poll Cycle: FAILED batch database upsert.", e, s);
          if (currentError.isEmpty) {
            currentError = "DB Batch Upsert Error: ${e.toString().split('\n').first}";
          }
          errorCount++; // Count DB error as a processing error for the cycle
        }
      }
      // --- End Batch Database Update ---

      // --- Execute ALL Collected Notification Actions ---
      logger.info("BG Poll Cycle: Executing ${allActions.length} collected notification actions...");
      try {
        // actionHandler resolved above
        await actionHandler.executeActions(allActions);
        logger.info("BG Poll Cycle: Action handler finished executing actions.");
      } catch (e, s) {
        logger.error("BG Poll Cycle: Error dispatching notifications/cancellations after batch DB write.", e, s);
        if (currentError.isEmpty) {
          currentError = "Notification Dispatch Error: ${e.toString().split('\n').first}";
        }
        errorCount++;
      }
      // --- End Dispatch ---
    } else {
      logger.info("BG Poll Cycle: No new video data to process.");
    }

    // --- Update State and Signal UI (remains mostly the same) ---
    if (errorCount > 0) {
      errorNotifier.state = currentError; // Report the first error encountered
    } else {
      errorNotifier.state = null; // Clear error state if cycle was successful
    }
    await settingsService.setLastPollTime(currentPollTime); // Update last successful poll time
    logger.info("BG Poll Cycle: Updated last poll time to ${currentPollTime.toIso8601String()}");
  } catch (e, s) {
    // Catch errors in the main polling logic (connectivity, API call, settings read)
    logger.error("BG Poll Cycle: Unhandled error during cycle execution.", e, s);
    try {
      final truncatedError = e.toString().split('\n').first;
      errorNotifier.state = "Poll Error: $truncatedError"; // Update error state
    } catch (notifierError) {
      logger.error("BG Poll Cycle: Failed to update background error state.", notifierError);
    }
    // Do NOT update last poll time if the cycle failed catastrophically here
  }
}
