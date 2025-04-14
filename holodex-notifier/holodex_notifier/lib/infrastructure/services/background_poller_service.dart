// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\infrastructure\services\background_poller_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui'; // Required for DartPluginRegistrant

import 'package:drift/drift.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart'; // Need lastErrorProvider
import 'package:holodex_notifier/domain/interfaces/background_polling_service.dart';
import 'package:holodex_notifier/domain/interfaces/api_service.dart';
import 'package:holodex_notifier/domain/interfaces/connectivity_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart'; // Import notification service
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart'; // Import database for CachedVideo
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
    } else if (key == 'apiKey') {
      // No immediate action needed, Dio interceptor gets it on next request.
      logger.debug("BG Isolate: Received API Key update notification. No background action needed.");
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

    // ############## CHANGE 6: REMOVE await for notificationServiceFutureProvider here ##############
    // The readiness flag confirmation implies the main isolate already successfully initialized it.
    // We just need to resolve it synchronously when needed later.
    // REMOVED: await container.read(notificationServiceFutureProvider.future);
    // REMOVED: logger.info("BG Isolate: Notification Service resolved.");
    // ############## END CHANGE 6 ##############

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
  // Cache and Notification services are resolved within _processVideoUpdate
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
    final List<NotificationInstruction> allNotificationsToDispatch = [];
    final List<int> allScheduledNotificationsToCancel = [];
    // --- End Batch Variables ---

    int processedCount = 0;
    int errorCount = 0;
    if (fetchedVideos.isNotEmpty) {
      logger.debug("BG Poll Cycle: Processing ${fetchedVideos.length} fetched videos...");
      for (final fetchedVideo in fetchedVideos) {
        try {
          // --- Modify _processVideoUpdate Call ---
          // It now returns the actions instead of performing them directly
          final processingResult = await _processVideoUpdate(fetchedVideo, container, channelSettingsMap);

          // Accumulate results if successful
          companionsToUpsert.add(processingResult.companionToUpsert);
          allNotificationsToDispatch.addAll(processingResult.notificationsToDispatch);
          allScheduledNotificationsToCancel.addAll(processingResult.scheduledNotificationsToCancel);
          // --- End Modification ---
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

      // --- Dispatch Accumulated Notifications/Cancellations AFTER Loop and DB Write ---
      try {
        final notificationService = await container.read(notificationServiceFutureProvider.future);
        await _dispatchCancellations(allScheduledNotificationsToCancel, notificationService, logger);
        await _dispatchNotifications(allNotificationsToDispatch, notificationService, logger);
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

// --- Define a return type for _processVideoUpdate ---
class VideoProcessingResult {
  final CachedVideosCompanion companionToUpsert;
  final List<NotificationInstruction> notificationsToDispatch;
  final List<int> scheduledNotificationsToCancel;

  VideoProcessingResult({required this.companionToUpsert, required this.notificationsToDispatch, required this.scheduledNotificationsToCancel});
}

// --- End Return Type ---
/// Helper for Processing a Single Video Update.
Future<VideoProcessingResult> _processVideoUpdate(
  VideoFull fetchedVideo,
  ProviderContainer container, // Pass container
  Map<String, ChannelSubscriptionSetting> channelSettingsMap,
) async {
  final videoId = fetchedVideo.id;
  final DateTime currentSystemTime = DateTime.now();

  final logger = container.read(loggingServiceProvider);
  // Resolve CacheService synchronously
  final cacheService = container.read(cacheServiceProvider);
  // Resolve NotificationService synchronously (relying on main isolate init)

  //final notificationService = container.read(notificationServiceProvider);
  logger.debug("[_processVideoUpdate] ($videoId) Awaiting notificationServiceFutureProvider...");
  late final INotificationService notificationService;
  try {
    notificationService = await container.read(notificationServiceFutureProvider.future);
    logger.debug("[_processVideoUpdate] ($videoId) notificationServiceFutureProvider resolved successfully.");
  } catch (e, s) {
    logger.fatal("[_processVideoUpdate] ($videoId) FAILED to resolve notificationServiceFutureProvider.", e, s);
    rethrow; // Propagate the error
  }

  // Resolve SettingsService synchronously
  final settingsService = container.read(settingsServiceProvider);
  logger.debug("[_processVideoUpdate] ($videoId) Starting processing...");

  // Get specific channel settings and global settings
  final channelSettings = channelSettingsMap[fetchedVideo.channel.id];
  if (channelSettings == null) {
    logger.warning(
      "[_processVideoUpdate] ($videoId) Channel ${fetchedVideo.channel.id} settings not found. Skipping processing logic and returning default companion.",
    );
    // Create a minimal companion if settings are missing to avoid errors downstream
    final defaultCompanion = CachedVideosCompanion(
      videoId: Value(videoId),
      channelId: Value(fetchedVideo.channel.id),
      status: Value(fetchedVideo.status),
      availableAt: Value(fetchedVideo.availableAt.toIso8601String()),
      videoTitle: Value(fetchedVideo.title),
      channelName: Value(fetchedVideo.channel.name),
      lastSeenTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
    );
    return VideoProcessingResult(companionToUpsert: defaultCompanion, notificationsToDispatch: [], scheduledNotificationsToCancel: []);
  }
  final bool delayNewMedia = await settingsService.getDelayNewMedia();

  // Get previous state from cache
  final CachedVideo? cachedData = await cacheService.getVideo(videoId);
  logger.debug("[_processVideoUpdate] ($videoId) Previous cache state: ${cachedData != null ? 'Found' : 'Not Found'}");

  // Determine state transitions
  final processingState = _ProcessingState(currentCacheData: cachedData, fetchedVideoData: fetchedVideo);

  // Accumulate results
  final List<NotificationInstruction> notificationsToDispatch = [];
  final List<int> scheduledNotificationsToCancel = [];

  // --- Execute Event Logic Helpers ---
  // Pass resolved notificationService instance where needed

  await _handleLiveScheduling(
    fetchedVideo: fetchedVideo,
    cachedVideo: cachedData,
    channelSettings: channelSettings,
    processingState: processingState,
    notificationService: notificationService, // Pass instance
    cancellations: scheduledNotificationsToCancel,
    logger: logger,
  );

  await _handleNewMediaEvent(
    fetchedVideo: fetchedVideo,
    cachedVideo: cachedData,
    channelSettings: channelSettings,
    processingState: processingState,
    delayNewMedia: delayNewMedia,
    dispatches: notificationsToDispatch,
    cancellations: scheduledNotificationsToCancel, // New Media can cancel schedules
    logger: logger,
  );

  await _handlePendingNewMediaTrigger(
    fetchedVideo: fetchedVideo,
    cachedVideo: cachedData,
    channelSettings: channelSettings,
    processingState: processingState,
    dispatches: notificationsToDispatch,
    cancellations: scheduledNotificationsToCancel, // Trigger can also cancel schedules
    logger: logger,
  );

  await _handleLiveEvent(
    fetchedVideo: fetchedVideo,
    cachedVideo: cachedData,
    channelSettings: channelSettings,
    processingState: processingState,
    currentSystemTime: currentSystemTime,
    // notificationService is not directly used here currently
    dispatches: notificationsToDispatch,
    cancellations: scheduledNotificationsToCancel, // Live event cancels schedules
    logger: logger,
  );

  await _handleUpdateEvent(
    fetchedVideo: fetchedVideo,
    cachedVideo: cachedData,
    channelSettings: channelSettings,
    processingState: processingState,
    delayNewMedia: delayNewMedia,
    // notificationService is not directly used here currently
    dispatches: notificationsToDispatch,
    logger: logger,
  );

  await _handleMentionEvent(
    fetchedVideo: fetchedVideo,
    cachedVideo: cachedData,
    channelSettingsMap: channelSettingsMap, // Need map for mention target check
    processingState: processingState,
    // notificationService is not directly used here currently
    dispatches: notificationsToDispatch,
    logger: logger,
  );

  // --- Prepare final Cache State ---
  logger.debug("[_processVideoUpdate] ($videoId) Preparing final cache state...");
  final companion = CachedVideosCompanion(
    videoId: Value(videoId),
    channelId: Value(fetchedVideo.channel.id),
    status: Value(fetchedVideo.status),
    startScheduled: Value(fetchedVideo.startScheduled?.toIso8601String()),
    startActual: Value(fetchedVideo.startActual?.toIso8601String()),
    availableAt: Value(fetchedVideo.availableAt.toIso8601String()),
    certainty: Value(fetchedVideo.certainty),
    mentionedChannelIds: Value(fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? []),
    videoTitle: Value(fetchedVideo.title),
    channelName: Value(fetchedVideo.channel.name),
    channelAvatarUrl: Value(fetchedVideo.channel.photo),
    lastSeenTimestamp: Value(DateTime.now().millisecondsSinceEpoch), // Use current time for last seen
    isPendingNewMediaNotification: Value(processingState.isPendingNewMedia),
    scheduledLiveNotificationId: Value(processingState.scheduledLiveNotificationId),
    lastLiveNotificationSentTime: Value(processingState.lastLiveNotificationSentTime?.millisecondsSinceEpoch),
  );

  logger.info("[_processVideoUpdate] ($videoId) Processing finished. Returning results.");
  return VideoProcessingResult(
    companionToUpsert: companion,
    notificationsToDispatch: notificationsToDispatch,
    scheduledNotificationsToCancel: scheduledNotificationsToCancel,
  );
}

// --- Processing State Helper Class ---
// (Keep this class without changes)
class _ProcessingState {
  // Mutable state reflecting decisions made during processing
  int? scheduledLiveNotificationId;
  bool isPendingNewMedia = false;
  DateTime? lastLiveNotificationSentTime;

  // Immutable state transitions detected at the start
  final bool isNewVideo;
  final bool isCertain;
  final bool wasCertain;
  final bool statusChanged;
  final bool scheduleChanged;
  final bool becameCertain; // Derived: !wasCertain && isCertain
  final bool mentionsChanged;
  final bool wasPendingNewMedia;

  _ProcessingState({required CachedVideo? currentCacheData, required VideoFull fetchedVideoData})
    : // Initialize immutable finals here
      isNewVideo = currentCacheData == null,
      isCertain = (fetchedVideoData.certainty == 'certain' || fetchedVideoData.certainty == null),
      wasCertain = currentCacheData != null && (currentCacheData.certainty == 'certain' || currentCacheData.certainty == null),
      statusChanged = currentCacheData != null && currentCacheData.status != fetchedVideoData.status,
      scheduleChanged = currentCacheData != null && currentCacheData.startScheduled != fetchedVideoData.startScheduled?.toIso8601String(),
      mentionsChanged =
          currentCacheData != null && !_listEquals(currentCacheData.mentionedChannelIds, fetchedVideoData.mentions?.map((m) => m.id).toList() ?? []),
      wasPendingNewMedia = currentCacheData?.isPendingNewMediaNotification ?? false,
      becameCertain =
          !(currentCacheData != null && (currentCacheData.certainty == 'certain' || currentCacheData.certainty == null)) &&
          (fetchedVideoData.certainty == 'certain' || fetchedVideoData.certainty == null) // Calculate derived state last
          {
    // Initialize mutable state from cache
    scheduledLiveNotificationId = currentCacheData?.scheduledLiveNotificationId;
    isPendingNewMedia = currentCacheData?.isPendingNewMediaNotification ?? false;
    lastLiveNotificationSentTime =
        currentCacheData?.lastLiveNotificationSentTime != null
            ? DateTime.fromMillisecondsSinceEpoch(currentCacheData!.lastLiveNotificationSentTime!)
            : null;
  }

  // Helper for comparing mention lists
  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    // Use Sets for efficient comparison regardless of order
    return Set<String>.from(a).containsAll(b);
  }
}

// ############## CHANGE 10: Ensure Helper functions receive notificationService if they call it ##############

// --- Event Logic Helpers ---

Future<void> _handleLiveScheduling({
  required VideoFull fetchedVideo,
  required CachedVideo? cachedVideo,
  required ChannelSubscriptionSetting channelSettings,
  required _ProcessingState processingState,
  required INotificationService notificationService, // RECEIVE THE INSTANCE
  required List<int> cancellations,
  required ILoggingService logger,
}) async {
  final videoId = fetchedVideo.id;
  final scheduledTime = fetchedVideo.startScheduled;

  final bool shouldBeScheduled =
      channelSettings.notifyLive && // User wants live notifications
      fetchedVideo.status == 'upcoming' && // Video is upcoming
      scheduledTime != null; // And has a scheduled time

  final bool isCurrentlyScheduled = processingState.scheduledLiveNotificationId != null;
  final bool scheduleTimeChanged = processingState.scheduleChanged; // Check if schedule time changed

  if (shouldBeScheduled) {
    // Schedule if not already scheduled, OR if the time changed
    if (!isCurrentlyScheduled || scheduleTimeChanged) {
      logger.info('[EventLogic] ($videoId) Needs Scheduling/Rescheduling (Current: $isCurrentlyScheduled, Changed: $scheduleTimeChanged)');
      // If rescheduling due to time change, cancel the old one first
      if (isCurrentlyScheduled && scheduleTimeChanged) {
        logger.debug('[EventLogic] ($videoId) Adding previous schedule ID ${processingState.scheduledLiveNotificationId} to cancellations.');
        cancellations.add(processingState.scheduledLiveNotificationId!);
        processingState.scheduledLiveNotificationId = null; // Assume cancellation will succeed
      }
      try {
        // CALL METHOD ON THE PASSED INSTANCE
        final newId = await notificationService.scheduleNotification(
          videoId: videoId,
          scheduledTime: scheduledTime, // Null checked by shouldBeScheduled logic
          payload: videoId, // Using videoId as payload
          title: fetchedVideo.title,
          channelName: fetchedVideo.channel.name,
        );
        if (newId != null) {
          logger.info('[EventLogic] ($videoId) Successfully scheduled/rescheduled with ID: $newId.');
          processingState.scheduledLiveNotificationId = newId; // Update state
        } else {
          logger.warning('[EventLogic] ($videoId) Scheduling returned null ID (plugin might have failed internally?).');
          processingState.scheduledLiveNotificationId = null; // Ensure it's null if scheduling failed
        }
      } catch (e, s) {
        logger.error('[EventLogic] ($videoId) Failed to schedule notification.', e, s);
        processingState.scheduledLiveNotificationId = null; // Ensure it's null on error
      }
    } else {
      // Already scheduled correctly, no change needed
      logger.debug('[EventLogic] ($videoId) Already correctly scheduled (ID: ${processingState.scheduledLiveNotificationId}). No action.');
    }
  } else if (isCurrentlyScheduled) {
    // Conditions for scheduling are no longer met (e.g., status changed from upcoming, no longer live notify)
    logger.info(
      '[EventLogic] ($videoId) Conditions for scheduling no longer met. Cancelling schedule ID: ${processingState.scheduledLiveNotificationId}.',
    );
    cancellations.add(processingState.scheduledLiveNotificationId!);
    processingState.scheduledLiveNotificationId = null; // Update state
  }
  // else: No need to schedule and wasn't scheduled before -> No action needed
}

Future<void> _handleNewMediaEvent({
  required VideoFull fetchedVideo,
  required CachedVideo? cachedVideo,
  required ChannelSubscriptionSetting channelSettings,
  required _ProcessingState processingState,
  required bool delayNewMedia,
  required List<NotificationInstruction> dispatches,
  required List<int> cancellations, // ** Added **
  required ILoggingService logger,
}) async {
  final videoId = fetchedVideo.id;
  // Skip if user doesn't want this notification type
  if (!channelSettings.notifyNewMedia) return;

  // Determine if this is potentially a 'New Media' event
  final bool isPotentialNew =
      processingState.isNewVideo || // First time seeing this video
      (processingState.statusChanged && // Status changed...
          (cachedVideo?.status == 'missing' || fetchedVideo.status == 'new')); // ...from missing or explicitly to 'new'

  if (!isPotentialNew) return; // Not a new media event

  logger.debug('[EventLogic] ($videoId) Potential New Media Event Detected.');

  // Check if delay is enabled AND video certainty is not 'certain'
  if (delayNewMedia && !processingState.isCertain) {
    logger.info('[EventLogic] ($videoId) Delaying New Media notification (Uncertainty + Setting ON). Setting pending flag.');
    processingState.isPendingNewMedia = true; // Set flag in mutable state
  } else {
    // Dispatch immediately if delay is off OR video is certain
    logger.info('[EventLogic] ($videoId) Dispatching New Media notification (Certainty or Setting OFF).');
    dispatches.add(_createNotificationInstruction(fetchedVideo, NotificationEventType.newMedia));
    processingState.isPendingNewMedia = false; // Clear pending flag
  }
}

Future<void> _handlePendingNewMediaTrigger({
  required VideoFull fetchedVideo,
  required CachedVideo? cachedVideo,
  required ChannelSubscriptionSetting channelSettings,
  required _ProcessingState processingState,
  required List<NotificationInstruction> dispatches,
  required List<int> cancellations, // ** Added **
  required ILoggingService logger,
}) async {
  final videoId = fetchedVideo.id;
  // Skip if it wasn't pending or user doesn't want new media notifications
  if (!processingState.wasPendingNewMedia || !channelSettings.notifyNewMedia) {
    return;
  }

  logger.debug('[EventLogic] ($videoId) Checking Pending New Media Trigger (wasPending=${processingState.wasPendingNewMedia}).');

  // Conditions to trigger the pending notification:
  final bool triggerConditionMet =
      processingState.becameCertain || // Video became certain (certainty changed from false to true)
      // OR status changed to something other than upcoming/new (meaning we won't get another chance)
      (processingState.statusChanged && fetchedVideo.status != 'upcoming' && fetchedVideo.status != 'new');

  if (triggerConditionMet) {
    logger.info(
      '[EventLogic] ($videoId) Pending New Media condition met (BecameCertain: ${processingState.becameCertain}, StatusChange: ${processingState.statusChanged} to ${fetchedVideo.status}). Dispatching.',
    );
    dispatches.add(_createNotificationInstruction(fetchedVideo, NotificationEventType.newMedia));
    processingState.isPendingNewMedia = false; // Clear pending flag
  } else {
    // Conditions not met, keep it pending
    logger.debug('[EventLogic] ($videoId) Pending trigger conditions not met. Keeping pending flag.');
    processingState.isPendingNewMedia = true; // Ensure flag remains set
  }
}

Future<void> _handleLiveEvent({
  required VideoFull fetchedVideo,
  required CachedVideo? cachedVideo,
  required ChannelSubscriptionSetting channelSettings,
  required _ProcessingState processingState,
  required DateTime currentSystemTime,
  // INotificationService notificationService, // Currently not needed here
  required List<NotificationInstruction> dispatches,
  required List<int> cancellations, // ** Added **
  required ILoggingService logger,
}) async {
  final videoId = fetchedVideo.id;
  // Skip if user doesn't want live notifications
  if (!channelSettings.notifyLive) return;

  // Check if video *just* became live
  final bool becameLive = processingState.statusChanged && fetchedVideo.status == 'live';

  if (!becameLive) return;

  logger.debug('[EventLogic] ($videoId) Live Event detected (Became Live).');

  // Check debounce logic
  const Duration debounceDuration = Duration(minutes: 2); // Prevent duplicates within 2 minutes
  DateTime? lastSentTime = processingState.lastLiveNotificationSentTime;
  bool shouldSend = true;
  if (lastSentTime != null) {
    final timeSinceLastSent = currentSystemTime.difference(lastSentTime);
    if (timeSinceLastSent < debounceDuration) {
      logger.info('[EventLogic] ($videoId) SUPPRESSING Live notification (Sent ${timeSinceLastSent.inSeconds}s ago).');
      shouldSend = false;
    }
  }

  if (shouldSend) {
    logger.info('[EventLogic] ($videoId) Dispatching immediate Live notification.');
    dispatches.add(_createNotificationInstruction(fetchedVideo, NotificationEventType.live));
    processingState.lastLiveNotificationSentTime = currentSystemTime; // Update last sent time

    // ** Added: If dispatching Live, cancel any pending live schedule **
    if (processingState.scheduledLiveNotificationId != null) {
      logger.debug(
        '[EventLogic] ($videoId) Cancelling scheduled notification ID ${processingState.scheduledLiveNotificationId} due to Live dispatch.',
      );
      cancellations.add(processingState.scheduledLiveNotificationId!);
      processingState.scheduledLiveNotificationId = null;
    }
  }
}

Future<void> _handleUpdateEvent({
  required VideoFull fetchedVideo,
  required CachedVideo? cachedVideo,
  required ChannelSubscriptionSetting channelSettings,
  required _ProcessingState processingState,
  required bool delayNewMedia,
  // INotificationService notificationService, // Currently not needed here
  required List<NotificationInstruction> dispatches,
  required ILoggingService logger,
}) async {
  final videoId = fetchedVideo.id;
  // Skip if user doesn't want updates or if it's the first time seeing the video
  if (!channelSettings.notifyUpdates || processingState.isNewVideo) return;

  // Check if schedule changed (other changes might be added later)
  if (processingState.scheduleChanged) {
    logger.debug('[EventLogic] ($videoId) Potential Update Event detected (Schedule Changed).');

    // Check if we should suppress this update (only certainty changed with delay enabled)
    bool onlyCertaintyChangedWithDelay =
        processingState.becameCertain &&
        !processingState.statusChanged && // Status didn't change
        !processingState.mentionsChanged && // Mentions didn't change
        delayNewMedia; // And delay setting is on

    if (!onlyCertaintyChangedWithDelay) {
      logger.info('[EventLogic] ($videoId) Dispatching Update notification (Schedule Changed).');
      dispatches.add(_createNotificationInstruction(fetchedVideo, NotificationEventType.update));
    } else {
      // Suppress notification if only certainty changed and delay is on
      logger.info('[EventLogic] ($videoId) SUPPRESSING Update notification (Only certainty changed & Delay ON).');
    }
  }
}

Future<void> _handleMentionEvent({
  required VideoFull fetchedVideo,
  required CachedVideo? cachedVideo,
  required Map<String, ChannelSubscriptionSetting> channelSettingsMap, // Pass full map
  required _ProcessingState processingState,
  // INotificationService notificationService, // Currently not needed here
  required List<NotificationInstruction> dispatches,
  required ILoggingService logger,
}) async {
  final videoId = fetchedVideo.id;
  // Skip if mentions haven't changed
  if (!processingState.mentionsChanged) return;

  logger.debug('[EventLogic] ($videoId) Mention Event detected (Mention list changed).');

  // Find *newly added* mentions
  final List<String> currentMentions = fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? [];
  final List<String> previousMentions = cachedVideo?.mentionedChannelIds ?? [];
  // Find items in currentMentions that are not in previousMentions
  final Set<String> newMentions = Set<String>.from(currentMentions).difference(Set<String>.from(previousMentions));

  if (newMentions.isEmpty) {
    logger.debug('[EventLogic] ($videoId) Mention list changed, but no *new* mentions found.');
    return;
  }

  logger.info('[EventLogic] ($videoId) Found new mentions: ${newMentions.join(', ')}');

  // Dispatch notification for each *new* mention *if* user subscribed to mentions for that specific channel
  for (final mentionedId in newMentions) {
    final mentionTargetSettings = channelSettingsMap[mentionedId];
    // Check if user is subscribed to THIS mentioned channel AND wants mention notifications for it
    if (mentionTargetSettings != null && mentionTargetSettings.notifyMentions) {
      // Find the mention details to get the name
      final mentionDetails = fetchedVideo.mentions?.firstWhere((m) => m.id == mentionedId);
      logger.info(
        '[EventLogic] ($videoId) User wants mentions for $mentionedId (${mentionDetails?.name ?? '??'}). Dispatching Mention notification.',
      );
      dispatches.add(
        _createNotificationInstruction(
          fetchedVideo,
          NotificationEventType.mention,
          mentionTargetId: mentionedId,
          mentionTargetName: mentionDetails?.name ?? 'Unknown Channel', // Use fetched name or default
        ),
      );
    } else {
      logger.debug('[EventLogic] ($videoId) User DOES NOT want mentions for newly mentioned channel $mentionedId. Skipping dispatch.');
    }
  }
}

// --- Notification Creation & Dispatch Helpers ---

NotificationInstruction _createNotificationInstruction(
  VideoFull video,
  NotificationEventType type, {
  String? mentionTargetId,
  String? mentionTargetName,
}) {
  return NotificationInstruction(
    videoId: video.id,
    eventType: type,
    channelId: video.channel.id,
    channelName: video.channel.name,
    videoTitle: video.title,
    channelAvatarUrl: video.channel.photo,
    mentionTargetChannelId: mentionTargetId,
    mentionTargetChannelName: mentionTargetName,
  );
}

Future<void> _dispatchCancellations(
  List<int> cancellationIds,
  INotificationService notificationService, // RECEIVE THE INSTANCE
  ILoggingService logger,
) async {
  // Use toSet() to avoid cancelling the same ID multiple times if logic slip occurs
  final uniqueIds = cancellationIds.toSet();
  if (uniqueIds.isEmpty) return;

  logger.info('[Dispatch] Cancelling ${uniqueIds.length} scheduled notifications.');
  for (final notificationId in uniqueIds) {
    try {
      // CALL METHOD ON THE PASSED INSTANCE
      await notificationService.cancelScheduledNotification(notificationId);
      logger.debug('[Dispatch] Cancelled schedule ID: $notificationId');
    } catch (e, s) {
      logger.error('[Dispatch] Failed to cancel notification ID: $notificationId', e, s);
      // Continue trying to cancel others
    }
  }
}

Future<void> _dispatchNotifications(
  List<NotificationInstruction> notifications,
  INotificationService notificationService, // RECEIVE THE INSTANCE
  ILoggingService logger,
) async {
  if (notifications.isEmpty) return;

  // TODO: Implement grouping logic here if needed before dispatching
  final List<NotificationInstruction> notificationsToSend = notifications;
  // if (groupNotifications) {
  //   notificationsToSend = _groupNotifications(notifications);
  // } else {
  //   notificationsToSend = notifications;
  // }

  logger.info('[Dispatch] Dispatching ${notificationsToSend.length} immediate notification(s).');
  for (final instruction in notificationsToSend) {
    try {
      // CALL METHOD ON THE PASSED INSTANCE
      await notificationService.showNotification(instruction);
      logger.debug('[Dispatch] Dispatched ${instruction.eventType} notification for ${instruction.videoId}.');
    } catch (e, s) {
      logger.error('[Dispatch] Failed to dispatch notification for ${instruction.videoId}', e, s);
      // Continue trying to dispatch others
    }
  }
}

// Placeholder for grouping logic
// List<NotificationInstruction> _groupNotifications(List<NotificationInstruction> instructions) {
//   // Implement grouping logic based on videoId, etc.
//   return instructions; // Return unmodified for now
// }


// --- END OF FILE ---