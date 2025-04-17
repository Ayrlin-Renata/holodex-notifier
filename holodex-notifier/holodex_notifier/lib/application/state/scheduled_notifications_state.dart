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

final scheduledFilterTypeProvider = StateProvider.autoDispose<Set<NotificationEventType>>((ref) {
  return {NotificationEventType.live, NotificationEventType.reminder};
}, name: 'scheduledFilterTypeProvider');

final scheduledFilterChannelProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
}, name: 'scheduledFilterChannelProvider');

final notificationFormatConfigProvider = FutureProvider.autoDispose<NotificationFormatConfig>((ref) async {
  final settingsService = ref.watch(settingsServiceProvider);
  return await settingsService.getNotificationFormatConfig();
}, name: 'notificationFormatConfigProvider');

final filteredScheduledNotificationsProvider = Provider.autoDispose<AsyncValue<List<ScheduledNotificationItem>>>((ref) {
  final baseAsyncValue = ref.watch(scheduledNotificationsProvider);
  final formatConfigAsyncValue = ref.watch(notificationFormatConfigProvider);

  final allowedTypes = ref.watch(scheduledFilterTypeProvider);
  final selectedChannelId = ref.watch(scheduledFilterChannelProvider);
  final logger = ref.watch(loggingServiceProvider);

  if (baseAsyncValue.isLoading || formatConfigAsyncValue.isLoading) {
    return const AsyncLoading<List<ScheduledNotificationItem>>();
  }

  if (baseAsyncValue.hasError) {
    return AsyncError<List<ScheduledNotificationItem>>(baseAsyncValue.error!, baseAsyncValue.stackTrace!);
  }
  if (formatConfigAsyncValue.hasError) {
    return AsyncError<List<ScheduledNotificationItem>>(formatConfigAsyncValue.error!, formatConfigAsyncValue.stackTrace!);
  }

  ({String title, String body}) formatItem(CachedVideo video, NotificationEventType type, DateTime scheduledTime, NotificationFormatConfig config) {
    final format = config.formats[type];
    if (format == null) {
      logger.warning("No format found for event type $type in UI provider");
      return (title: video.channelName, body: video.videoTitle);
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

    String videoType = video.videoType ?? 'Media';
    if (videoType.isEmpty || videoType == 'placeholder') {
      videoType = 'Media';
    }
    String mediaTypeCaps = videoType.toUpperCase();

    String dateYMD = DateFormat('yyyy-MM-dd').format(localScheduledTime);
    String dateDMY = DateFormat('dd-MM-yyyy').format(localScheduledTime);
    String dateMDY = DateFormat('MM-dd-yyyy').format(localScheduledTime);
    String dateMD = DateFormat('MM-dd').format(localScheduledTime);
    String dateDM = DateFormat('dd-MM').format(localScheduledTime);
    String dateAsia =
        '${DateFormat('yyyy').format(localScheduledTime)}年${DateFormat('MM').format(localScheduledTime)}月${DateFormat('dd').format(localScheduledTime)}日';

    final replacements = {
      '{channelName}': video.channelName,
      '{mediaTitle}': video.videoTitle,
      '{mediaTime}': mediaTime,
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

  final videoList = baseAsyncValue.requireValue;
  final NotificationFormatConfig formatConfig = formatConfigAsyncValue.requireValue;

  final List<ScheduledNotificationItem> expandedItems = [];

  for (final video in videoList) {
    if (video.scheduledReminderNotificationId != null && video.scheduledReminderTime != null) {
      try {
        final reminderTime = DateTime.fromMillisecondsSinceEpoch(video.scheduledReminderTime!);
        if (reminderTime.isAfter(DateTime.now())) {
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
      } catch (e) {
        logger.error("Error processing reminder item ${video.videoId}", e);
      }
    }

    if (video.scheduledLiveNotificationId != null && video.startScheduled != null) {
      try {
        final liveTime = DateTime.parse(video.startScheduled!);
        if (liveTime.isAfter(DateTime.now())) {
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
        }
      } catch (e) {
        logger.error("Error processing live item ${video.videoId}", e);
      }
    }
  }

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
