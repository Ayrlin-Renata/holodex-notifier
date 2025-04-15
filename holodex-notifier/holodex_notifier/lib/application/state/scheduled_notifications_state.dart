// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\application\state\scheduled_notifications_state.dart
import 'dart:async';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/main.dart'; // For service providers

class ScheduledNotificationItem {
  final CachedVideo videoData; // The original data
  final NotificationEventType type; // Live or Reminder
  final DateTime scheduledTime; // The time this specific notification fires

  ScheduledNotificationItem({required this.videoData, required this.type, required this.scheduledTime});

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

// --- Derived Filtered List Provider ---

final filteredScheduledNotificationsProvider = Provider.autoDispose<AsyncValue<List<ScheduledNotificationItem>>>((ref) {
  // Watch the base provider and the filter states
  final baseAsyncValue = ref.watch(scheduledNotificationsProvider);
  final allowedTypes = ref.watch(scheduledFilterTypeProvider);
  final selectedChannelId = ref.watch(scheduledFilterChannelProvider);

  // If base data is loading or has error, pass that through
  if (baseAsyncValue.isLoading) {
    // {{ Need explicit cast for AsyncValue type change when error/loading }}
    return const AsyncLoading<List<ScheduledNotificationItem>>();
  }
  if (baseAsyncValue.hasError) {
    // If base has error, derived has error. Propagate the error and stack trace.
    return AsyncError<List<ScheduledNotificationItem>>(baseAsyncValue.error!, baseAsyncValue.stackTrace!);
  }

  // Only proceed if baseAsyncValue has data (guaranteed by checks above)
  if (baseAsyncValue.hasValue) {
    final videoList = baseAsyncValue.requireValue; // Safely get List<CachedVideo>

    final List<ScheduledNotificationItem> expandedItems = [];

    // 1. Expand the list: Create individual items for each scheduled notification type
    for (final video in videoList) {
      // Create Reminder item if applicable and time exists
      if (video.scheduledReminderNotificationId != null && video.scheduledReminderTime != null) {
        try {
          final reminderTime = DateTime.fromMillisecondsSinceEpoch(video.scheduledReminderTime!);
          // Only add if the calculated reminder time is in the future
          if (reminderTime.isAfter(DateTime.now())) {
            expandedItems.add(ScheduledNotificationItem(videoData: video, type: NotificationEventType.reminder, scheduledTime: reminderTime));
          }
        } catch (e) {
          // Log error parsing reminder time?
          print("Error parsing reminder time for ${video.videoId}: $e");
        }
      }

      // Create Live item if applicable and time exists
      if (video.scheduledLiveNotificationId != null && video.startScheduled != null) {
        try {
          final liveTime = DateTime.parse(video.startScheduled!);
          // Only add if the scheduled live time is in the future
          if (liveTime.isAfter(DateTime.now())) {
            expandedItems.add(ScheduledNotificationItem(videoData: video, type: NotificationEventType.live, scheduledTime: liveTime));
          }
        } catch (e) {
          // Log error parsing live time?
          print("Error parsing live time for ${video.videoId}: $e");
        }
      }
    }

    // 2. Filter the expanded list
    final List<ScheduledNotificationItem> filteredItems =
        expandedItems.where((item) {
          // Check Type Filter
          bool typeMatch = allowedTypes.contains(item.type);
          if (!typeMatch) return false;

          // Check Channel Filter
          bool channelMatch = selectedChannelId == null || selectedChannelId == item.channelId;
          if (!channelMatch) return false;

          return true; // Keep item if both filters pass
        }).toList();

    // 3. Sort the final filtered list by scheduledTime
    filteredItems.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    // Return the final list wrapped in AsyncData
    return AsyncData(filteredItems);
    // --- End existing logic ---
  } else {
    // Should not happen due to initial checks, but return loading as fallback
    return const AsyncLoading<List<ScheduledNotificationItem>>();
  }
}, name: 'filteredScheduledNotificationsProvider'); // Ensure name is set
