// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\application\state\scheduled_notifications_state.dart
import 'dart:async';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/main.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago; // For service providers

class ScheduledNotificationItem {
  final CachedVideo videoData; // The original data
  final NotificationEventType type; // Live or Reminder
  final DateTime scheduledTime; // The time this specific notification fires
  final String formattedTitle;
  final String formattedBody;

  ScheduledNotificationItem({
    required this.videoData,
    required this.type,
    required this.scheduledTime,
    required this.formattedTitle,
    required this.formattedBody,
  });
  // Getter for the specific notification ID for cancellation
  int? get notificationId {
    return type == NotificationEventType.reminder ? videoData.scheduledReminderNotificationId : videoData.scheduledLiveNotificationId;
  }

  // Getter for channelId for filtering
  String get channelId => videoData.channelId;
}

// --- ScheduledNotificationsNotifier ---
class ScheduledNotificationsNotifier extends StateNotifier<AsyncValue<List<CachedVideo>>> {
  final ICacheService _cacheService;
  final ILoggingService _logger;
  bool _isFetching = false; // Basic lock to prevent concurrent fetches

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

// --- Provider Definition ---
final scheduledNotificationsProvider = StateNotifierProvider.autoDispose<ScheduledNotificationsNotifier, AsyncValue<List<CachedVideo>>>((ref) {
  final log = ref.watch(loggingServiceProvider);
  log.info("Creating ScheduledNotificationsNotifier...");
  final cacheService = ref.watch(cacheServiceProvider);
  ref.onDispose(() => log.info("Disposed scheduled notifications notifier."));
  return ScheduledNotificationsNotifier(cacheService, log);
}, name: 'scheduledNotificationsProvider');

// --- Filter State Providers ---

/// Controls which notification types (Live, Reminder) are shown.
final scheduledFilterTypeProvider = StateProvider.autoDispose<Set<NotificationEventType>>((ref) {
  // Default to showing both types
  return {NotificationEventType.live, NotificationEventType.reminder};
}, name: 'scheduledFilterTypeProvider');

/// Controls which channels are shown (null means show all).
final scheduledFilterChannelProvider = StateProvider.autoDispose<String?>((ref) {
  // Default to showing all channels
  return null;
}, name: 'scheduledFilterChannelProvider');


// --- Provider for Notification Format Configuration ---
final notificationFormatConfigProvider = FutureProvider.autoDispose<NotificationFormatConfig>((ref) async {
  // Depend on the synchronously available settings service provider
  final settingsService = ref.watch(settingsServiceProvider);
  return await settingsService.getNotificationFormatConfig();
}, name: 'notificationFormatConfigProvider');

// --- Derived Filtered List Provider ---
final filteredScheduledNotificationsProvider = Provider.autoDispose<AsyncValue<List<ScheduledNotificationItem>>>((ref) {
  // Watch both async dependencies
  final baseAsyncValue = ref.watch(scheduledNotificationsProvider);
  final formatConfigAsyncValue = ref.watch(notificationFormatConfigProvider); // Watch the new provider

  // Get synchronous filter values
  final allowedTypes = ref.watch(scheduledFilterTypeProvider);
  final selectedChannelId = ref.watch(scheduledFilterChannelProvider);
  final logger = ref.watch(loggingServiceProvider);

  // --- Handle Combined Loading/Error States ---
  // If either dependency is loading, the result is loading.
  if (baseAsyncValue.isLoading || formatConfigAsyncValue.isLoading) {
    // Combine loading states, keeping previous data if available
    return const AsyncLoading<List<ScheduledNotificationItem>>();
  }

  // If either dependency has an error, the result is an error.
  // Combine error states, preferring the first error encountered.
  if (baseAsyncValue.hasError) {
    return AsyncError<List<ScheduledNotificationItem>>(baseAsyncValue.error!, baseAsyncValue.stackTrace!);
  }
  if (formatConfigAsyncValue.hasError) {
     return AsyncError<List<ScheduledNotificationItem>>(formatConfigAsyncValue.error!, formatConfigAsyncValue.stackTrace!);
  }
  // --- End Combined State Handling ---


  // --- Helper for IN-PROVIDER Formatter (remains the same) ---
  ({String title, String body}) formatItem(
    CachedVideo video,
    NotificationEventType type,
    DateTime scheduledTime,
    NotificationFormatConfig config,
  ) {
     final format = config.formats[type];
    if (format == null) {
      logger.warning("No format found for event type $type in UI provider");
      return (title: video.channelName, body: video.videoTitle); // Basic fallback
    }
    
    final localScheduledTime = scheduledTime.toLocal();
    final String mediaTime = DateFormat.jm().format(localScheduledTime);
    String relativeTime = 'soon';
    if (type == NotificationEventType.reminder) {
      try {
        relativeTime = timeago.format(scheduledTime, locale: 'en_short', allowFromNow: true);
      } catch (e) {
        logger.error("Error formatting relative time in UI provider", e);
      }
    }

    String videoType = video.videoType ?? 'Video'; // Default if null in cache
    if (videoType.isEmpty) { // Also handle empty string case
        videoType = 'Video';
    }
    String mediaTypeCaps = videoType.toUpperCase();

    String dateYMD = DateFormat('yyyy-MM-dd').format(localScheduledTime);
    String dateDMY = DateFormat('dd-MM-yyyy').format(localScheduledTime);
    String dateMDY = DateFormat('MM-dd-yyyy').format(localScheduledTime);
    String dateMD = DateFormat('MM-dd').format(localScheduledTime);
    String dateDM = DateFormat('dd-MM').format(localScheduledTime);
    String dateAsia = '${DateFormat('yyyy').format(localScheduledTime)}年${DateFormat('MM').format(localScheduledTime)}月${DateFormat('dd').format(localScheduledTime)}日';

    final replacements = {
      '{channelName}': video.channelName,
      '{mediaTitle}': video.videoTitle,
      '{mediaTime}': mediaTime, // Time part
      '{relativeTime}': relativeTime,
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
  // --- End Formatter Helper ---

  // Only proceed if both dependencies have data
  final videoList = baseAsyncValue.requireValue;
  // {{ Get formatConfig safely from the AsyncValue }}
  final NotificationFormatConfig formatConfig = formatConfigAsyncValue.requireValue;

  // --- Start Actual Filtering and Formatting ---
  final List<ScheduledNotificationItem> expandedItems = [];

  // 1. Expand the list and FORMAT (using the successful formatConfig)
  for (final video in videoList) {
    // Handle Reminder
    if (video.scheduledReminderNotificationId != null && video.scheduledReminderTime != null) {
      try {
        final reminderTime = DateTime.fromMillisecondsSinceEpoch(video.scheduledReminderTime!);
        if (reminderTime.isAfter(DateTime.now())) {
          final formatted = formatItem(video, NotificationEventType.reminder, reminderTime, formatConfig);
          expandedItems.add(ScheduledNotificationItem(
            videoData: video,
            type: NotificationEventType.reminder,
            scheduledTime: reminderTime,
            formattedTitle: formatted.title,
            formattedBody: formatted.body,
          ));
        }
      } catch (e) { logger.error("Error processing reminder item ${video.videoId}", e); }
    }

    // Handle Live
    if (video.scheduledLiveNotificationId != null && video.startScheduled != null) {
      try {
        final liveTime = DateTime.parse(video.startScheduled!);
        if (liveTime.isAfter(DateTime.now())) {
          final formatted = formatItem(video, NotificationEventType.live, liveTime, formatConfig);
          expandedItems.add(ScheduledNotificationItem(
            videoData: video,
            type: NotificationEventType.live,
            scheduledTime: liveTime,
            formattedTitle: formatted.title,
            formattedBody: formatted.body,
          ));
        }
      } catch (e) { logger.error("Error processing live item ${video.videoId}", e); }
    }
  }
  // --- End Expanding and Formatting ---

  // 2. Filter the formatted & expanded list
  final List<ScheduledNotificationItem> filteredItems = expandedItems.where((item) {
    bool typeMatch = allowedTypes.contains(item.type);
    if (!typeMatch) return false;
    bool channelMatch = selectedChannelId == null || selectedChannelId == item.channelId;
    if (!channelMatch) return false;
    return true;
  }).toList();

  // 3. Sort the final filtered list by scheduledTime
  filteredItems.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

  // Return the final list wrapped in AsyncData
  return AsyncData(filteredItems);

}, name: 'filteredScheduledNotificationsProvider');