import 'dart:async';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/main.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class ScheduledNotificationItem {
  final CachedVideo videoData;
  final NotificationEventType type;
  final DateTime scheduledTime;
  final String formattedTitle;
  final String formattedBody;

  ScheduledNotificationItem({
    required this.videoData,
    required this.type,
    required this.scheduledTime,
    required this.formattedTitle,
    required this.formattedBody,
  });
  int? get notificationId {
    return type == NotificationEventType.reminder ? videoData.scheduledReminderNotificationId : videoData.scheduledLiveNotificationId;
  }

  String get channelId => videoData.channelId;
}


class ScheduledNotificationsNotifier extends StateNotifier<AsyncValue<List<CachedVideo>>> {
  final ICacheService _cacheService;
  final ILoggingService _logger;
  bool _isFetching = false;

  ScheduledNotificationsNotifier(this._cacheService, this._logger) : super(const AsyncValue.loading()) {
    fetchScheduledNotifications();
  }

  Future<void> fetchScheduledNotifications({bool isRefreshing = false}) async {
    if (_isFetching && !isRefreshing) {
      _logger.debug("[ScheduledNotificationsNotifier] Fetch already in progress, skipping.");
      return;
    }
    _isFetching = true;
    _logger.info("[ScheduledNotificationsNotifier] Fetching scheduled notifications...");

    if (isRefreshing && state.hasValue) {
      state = AsyncLoading<List<CachedVideo>>().copyWithPrevious(state);
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _cacheService.getScheduledVideos();
      if (mounted) {
        state = AsyncValue.data(data);
        _logger.info("[ScheduledNotificationsNotifier] Fetch successful, found ${data.length} items.");
      } else {
        _logger.info("[ScheduledNotificationsNotifier] Notifier unmounted after fetch, discarding data.");
      }
    } catch (e, s) {
      _logger.error("[ScheduledNotificationsNotifier] Error fetching scheduled notifications", e, s);
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    } finally {
      if (mounted) {
        _isFetching = false;
      }
    }
  }
}

final scheduledNotificationsProvider = StateNotifierProvider.autoDispose<ScheduledNotificationsNotifier, AsyncValue<List<CachedVideo>>>((ref) {
  final log = ref.watch(loggingServiceProvider);
  log.info("Creating ScheduledNotificationsNotifier...");
  final cacheService = ref.watch(cacheServiceProvider);
  ref.onDispose(() => log.info("Disposed scheduled notifications notifier."));
  return ScheduledNotificationsNotifier(cacheService, log);
}, name: 'scheduledNotificationsProvider');

// lib/application/state/scheduled_notifications_state.dart
// ... other imports and providers ...

// --- MODIFY PROVIDER INITIALIZATION ---
final scheduledFilterTypeProvider = StateProvider.autoDispose<Set<NotificationEventType>>((ref) {
  // 1. Get the SettingsService
  final settingsService = ref.read(settingsServiceProvider);
  final logger = ref.read(loggingServiceProvider);

  // 2. Load the saved filter types from SettingsService (synchronously during provider init)
  try {
    final savedTypes = settingsService.getScheduledFilterTypesSync(); // Assuming a synchronous getter exists or create one
    logger.debug("Scheduled filter types initialized from saved settings: ${savedTypes.map((e) => e.name).join(',')}");
    return savedTypes;
  } catch (e, s) {
    logger.error("Error loading saved scheduled filter types, defaulting to empty set.", e, s);
    return <NotificationEventType>{}; // Default to empty set on error
  }
});

final scheduledFilterChannelProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
}, name: 'scheduledFilterChannelProvider');

final notificationFormatConfigProvider = FutureProvider.autoDispose<NotificationFormatConfig>((ref) async {
  final settingsService = ref.watch(settingsServiceProvider);
  return await settingsService.getNotificationFormatConfig();
}, name: 'notificationFormatConfigProvider');


// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\application\state\scheduled_notifications_state.dart
// ... existing imports ...

// Provider for Dismissed Notifications (now reads from DB)
class DismissedNotificationsNotifier extends StateNotifier<AsyncValue<List<ScheduledNotificationItem>>> { // {{change 1: Use AsyncValue}}
  final ILoggingService _logger;
  final ICacheService _cacheService; // {{change 2: Use CacheService}}
  final NotificationFormatConfig? _formatConfig; // {{change 3: Need formatter}}

  DismissedNotificationsNotifier(this._logger, this._cacheService, this._formatConfig) // {{change 4: Update constructor}}
      : super(const AsyncValue.loading()) { // {{change 5: Init as loading}}
    _loadDismissedItems();
  }

  Future<void> _loadDismissedItems() async { // {{change 6: Load from CacheService}}
    _logger.info("[DismissedNotifier] Loading dismissed items from CacheService...");
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final dismissedVideos = await _cacheService.getDismissedScheduledVideos();
      // Format the items for display
      final formattedItems = _formatItems(dismissedVideos, _formatConfig, _logger);
      if (mounted) {
        state = AsyncValue.data(formattedItems);
        _logger.info("[DismissedNotifier] Loaded ${formattedItems.length} dismissed items.");
      }
    } catch (e, s) {
      _logger.error("[DismissedNotifier] Error loading dismissed items.", e, s);
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  // Helper function to format items (similar to filteredScheduledNotificationsProvider)
  List<ScheduledNotificationItem> _formatItems(
    List<CachedVideo> videos,
    NotificationFormatConfig? config,
    ILoggingService logger,
  ) {
    if (config == null) {
      logger.error("[DismissedNotifier:_formatItems] Cannot format items, formatConfig is null.");
      return []; // Return empty list if config is somehow null
    }
    final List<ScheduledNotificationItem> items = [];

    for (final video in videos) {
      DateTime? scheduledTime;
      NotificationEventType? type;

      // Determine the type and scheduled time from the video data
      // This logic might need adjustment based on how items are dismissed
      if (video.scheduledReminderNotificationId != null && video.scheduledReminderTime != null) {
        type = NotificationEventType.reminder;
        scheduledTime = DateTime.fromMillisecondsSinceEpoch(video.scheduledReminderTime!);
      } else if (video.scheduledLiveNotificationId != null && video.startScheduled != null) {
         type = NotificationEventType.live;
         try {
            scheduledTime = DateTime.parse(video.startScheduled!);
         } catch (_) {
            logger.warning("[DismissedNotifier:_formatItems] Failed to parse startScheduled for dismissed video ${video.videoId}");
         }
      }

      // Ensure we have a valid type and time before proceeding
       if (type != null && scheduledTime != null /* && scheduledTime.isAfter(now) */) { // Keep past dismissed items? Yes.
         try {
            final formatted = formatItem(video, type, scheduledTime, config); // Use the existing global formatItem function
            items.add(ScheduledNotificationItem(
              videoData: video,
              type: type,
              scheduledTime: scheduledTime,
              formattedTitle: formatted.title,
              formattedBody: formatted.body,
            ));
         } catch (e, s) {
            logger.error("[DismissedNotifier:_formatItems] Error formatting dismissed item ${video.videoId}", e, s);
         }
       } else {
          logger.warning("[DismissedNotifier:_formatItems] Could not determine type/time for dismissed video ${video.videoId}");
       }
    }
    // Sorting might not be needed if we order by dismissal time in the query
    // items.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return items;
  }

  // Add and Remove now don't modify the state directly, they trigger DB updates
  // The UI will react automatically when the provider reloads its data from DB

  // Note: 'add' is effectively handled by the dismissal logic in the UI setting the DB flag
  // void add(ScheduledNotificationItem item) { /* Now Handled by UI triggering DB update */ }

  // Note: 'remove' is effectively handled by the restore logic in the UI setting the DB flag
  // void remove(ScheduledNotificationItem itemToRemove) { /* Now Handled by UI triggering DB update */ }

  // Provide a manual refresh method if needed
  Future<void> refresh() async {
     await _loadDismissedItems();
  }
}

// {{change 7: Update provider definition}}
final dismissedNotificationsProvider = StateNotifierProvider.autoDispose<
    DismissedNotificationsNotifier, AsyncValue<List<ScheduledNotificationItem>>>((ref) {
  final logger = ref.watch(loggingServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  // Get the format config, it might be loading initially
  final formatConfig = ref.watch(notificationFormatConfigProvider).valueOrNull;

  // Watch the format config provider so this provider rebuilds when config changes
  ref.watch(notificationFormatConfigProvider);

  final notifier = DismissedNotificationsNotifier(logger, cacheService, formatConfig);
  return notifier; // loading happens inside constructor
}, name: 'dismissedNotificationsProvider');

// --- Existing `formatItem` function (can be moved to keep DRY) ---
// This function is now used by both filteredScheduledNotificationsProvider
// and DismissedNotificationsNotifier
 // Ensure it's accessible, maybe move it outside the provider scope or pass it
 ({String title, String body}) formatItem(
    CachedVideo video,
    NotificationEventType type,
    DateTime notificationScheduledTime, // When the notification itself is scheduled
    NotificationFormatConfig config,
     // Add logger as argument if needed or make it global/static access
     // ILoggingService logger,
  ) {
     final logger = ProviderContainer().read(loggingServiceProvider); // Hacky way to get logger if needed globally
     // ... rest of the formatItem implementation remains the same ...
    final format = config.formats[type];
    if (format == null) {
      logger.warning("No format found for event type $type in UI provider");
      return (title: video.channelName, body: video.videoTitle);
    }

    final DateTime now = DateTime.now();
    final DateTime? eventActualStartTime = DateTime.tryParse(video.startScheduled ?? video.availableAt);
    final DateTime localNotificationScheduledTime = notificationScheduledTime.toLocal();
    final DateTime? localEventActualStartTime = eventActualStartTime?.toLocal();


    String timeToNotifString = '';
    String timeToEventString = '';

    try {
      timeToNotifString = timeago.format(localNotificationScheduledTime, locale: 'en_short', allowFromNow: true);
    } catch (e) {
      logger.error("Error formatting timeToNotifString in UI provider for $localNotificationScheduledTime", e);
       timeToNotifString = (localNotificationScheduledTime.isBefore(now)) ? "now" : "soon";
    }

    if (localEventActualStartTime != null) {
       try {
         timeToEventString = timeago.format(localEventActualStartTime, locale: 'en_short', allowFromNow: true);
       } catch (e) {
         logger.error("Error formatting timeToEventString in UI provider for $localEventActualStartTime", e);
         timeToEventString = (localEventActualStartTime.isBefore(now)) ? "started" : "soon";
       }
    } else {
        logger.warning("[${video.videoId}] Missing eventActualStartTime for calculating timeToEventString in UI provider.");
        timeToEventString = "N/A";
    }


    String videoType = video.videoType ?? 'Media';
    if (videoType.isEmpty || videoType == 'placeholder') {
      videoType = 'Media';
    }
    String mediaTypeCaps = videoType.toUpperCase();


    final DateTime timeForFormatting = localEventActualStartTime ?? localNotificationScheduledTime;


    String mediaTime = DateFormat.jm().format(timeForFormatting);
    String dateYMD = DateFormat('yyyy-MM-dd').format(timeForFormatting);
    String dateDMY = DateFormat('dd-MM-yyyy').format(timeForFormatting);
    String dateMDY = DateFormat('MM-dd-yyyy').format(timeForFormatting);
    String dateMD = DateFormat('MM-dd').format(timeForFormatting);
    String dateDM = DateFormat('dd-MM').format(timeForFormatting);
    String dateAsia =
        '${DateFormat('yyyy').format(timeForFormatting)}年${DateFormat('MM').format(timeForFormatting)}月${DateFormat('dd').format(timeForFormatting)}日';

    final replacements = {
      '{channelName}': video.channelName,
      '{mediaTitle}': video.videoTitle,
      '{mediaTime}': mediaTime,
      '{timeToEvent}': timeToEventString,
      '{timeToNotif}': timeToNotifString,
      '{mediaType}': videoType,
      '{mediaTypeCaps}': mediaTypeCaps,
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

// Make sure filteredScheduledNotificationsProvider also uses the global formatItem
final filteredScheduledNotificationsProvider = Provider.autoDispose<AsyncValue<List<ScheduledNotificationItem>>>((ref) {
  final baseAsyncValue = ref.watch(scheduledNotificationsProvider); // Reads non-dismissed items now
  final formatConfigAsyncValue = ref.watch(notificationFormatConfigProvider);
  final allowedTypes = ref.watch(scheduledFilterTypeProvider);
  final selectedChannelId = ref.watch(scheduledFilterChannelProvider);
  final logger = ref.watch(loggingServiceProvider);

  if (baseAsyncValue.hasError) {
    return AsyncError<List<ScheduledNotificationItem>>(baseAsyncValue.error!, baseAsyncValue.stackTrace!);
  }
  if (formatConfigAsyncValue.hasError) {
    logger.error("[FilteredScheduled] Error loading formatConfig: ${formatConfigAsyncValue.error}");
    return AsyncError<List<ScheduledNotificationItem>>(formatConfigAsyncValue.error!, formatConfigAsyncValue.stackTrace!);
  }

  // ... existing loading/error checks ...
  if (baseAsyncValue.isLoading || formatConfigAsyncValue.isLoading) {
    return const AsyncLoading<List<ScheduledNotificationItem>>();
  }

  final videoList = baseAsyncValue.requireValue; // These are already filtered by DB query
  final NotificationFormatConfig? formatConfig = formatConfigAsyncValue.valueOrNull;
  if (formatConfig == null) {
     logger.error("[FilteredScheduled] Format config is null after loading check. Cannot format items.");
     return const AsyncValue.data([]);
  }

  // --- Format using the global/shared formatItem function ---
   final List<ScheduledNotificationItem> expandedItems = [];
   final DateTime now = DateTime.now();

   for (final video in videoList) {
      // Reminder
      if (video.scheduledReminderNotificationId != null && video.scheduledReminderTime != null) {
         // ... (existing try-catch for reminder processing) ...
          try {
            final reminderTime = DateTime.fromMillisecondsSinceEpoch(video.scheduledReminderTime!);
            if (reminderTime.isAfter(now)) {
              // Use the global formatItem
              final formatted = formatItem(video, NotificationEventType.reminder, reminderTime, formatConfig);
              expandedItems.add(
                ScheduledNotificationItem(
                  videoData: video,
                  type: NotificationEventType.reminder,
                  scheduledTime: reminderTime,
                  formattedTitle: formatted.title,
                  formattedBody: formatted.body,
                ),
              );
            }
          } catch (e,s) {
             logger.error("Error processing reminder item ${video.videoId}", e, s);
          }
      }
      // Live
      if (video.scheduledLiveNotificationId != null && video.startScheduled != null) {
          // ... (existing try-catch for live processing) ...
          try {
            final liveTime = DateTime.tryParse(video.startScheduled!);
            if (liveTime != null && liveTime.isAfter(now)) {
               // Use the global formatItem
              final formatted = formatItem(video, NotificationEventType.live, liveTime, formatConfig);
              expandedItems.add(
                ScheduledNotificationItem(
                  videoData: video,
                  type: NotificationEventType.live,
                  scheduledTime: liveTime,
                  formattedTitle: formatted.title,
                  formattedBody: formatted.body,
                ),
              );
            } else if (liveTime == null) {
              logger.warning("[FilteredScheduled] Failed to parse liveTime for video ${video.videoId}: ${video.startScheduled}");
            }
          } catch (e, s) {
            logger.error("Error processing live item ${video.videoId}", e, s);
          }
      }
   }

  // --- Filtering by UI settings ---
  final List<ScheduledNotificationItem> filteredItems =
      expandedItems.where((item) {
        bool typeMatch = allowedTypes.contains(item.type);
        if (!typeMatch) return false;
        bool channelMatch = selectedChannelId == null || selectedChannelId == item.channelId;
        if (!channelMatch) return false;
        return true;
      }).toList();

  filteredItems.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

  return AsyncData(filteredItems);
}, name: 'filteredScheduledNotificationsProvider');



// ... extensions ...
extension AsyncValueCombineLatest<T1, T2> on AsyncValue<T1> {
  AsyncValue<R> combineLatest<R>(AsyncValue<T2> other, R Function(T1, T2) combiner) {
    return when(
      data:
          (d1) => other.when(
            data: (d2) {
              try {
                return AsyncData(combiner(d1, d2));
              } catch (e, st) {
                return AsyncError(e, st);
              }
            },
            loading: () => const AsyncLoading(),
            error: (e, st) => AsyncError(e, st),
          ),
      loading: () => other.maybeWhen(error: (e, st) => AsyncError(e, st), orElse: () => const AsyncLoading()),
      error: (e, st) => other.maybeWhen(error: (e2, st2) => AsyncError(e, st), orElse: () => AsyncError(e, st)),
    );
  }
}

extension AsyncValueStateToString on AsyncValue<dynamic> {
  String stateToString() {
    if (isLoading) return 'loading';
    if (hasError) return 'error';
    if (hasValue) return 'data';
    return 'unknown';
  }
}

