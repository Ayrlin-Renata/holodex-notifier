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

  if (baseAsyncValue.hasError) {
    return AsyncError<List<ScheduledNotificationItem>>(baseAsyncValue.error!, baseAsyncValue.stackTrace!);
  }
  if (formatConfigAsyncValue.hasError) {
     logger.error("[FilteredScheduled] Error loading formatConfig: ${formatConfigAsyncValue.error}");
    return AsyncError<List<ScheduledNotificationItem>>(formatConfigAsyncValue.error!, formatConfigAsyncValue.stackTrace!);
  }

  if (baseAsyncValue.isLoading || formatConfigAsyncValue.isLoading) {
    return const AsyncLoading<List<ScheduledNotificationItem>>();
  }


  ({String title, String body}) formatItem(
    CachedVideo video,
    NotificationEventType type,
    DateTime notificationScheduledTime,
    NotificationFormatConfig config,
  ) {
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
        logger.warning("[$video.videoId] Missing eventActualStartTime for calculating timeToEventString in UI provider.");
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

  final videoList = baseAsyncValue.requireValue;
  final NotificationFormatConfig? formatConfig = formatConfigAsyncValue.valueOrNull;
  if (formatConfig == null) {
     logger.error("[FilteredScheduled] Format config is null after loading check. Cannot format items.");
    return const AsyncValue.data([]);
  }


  final List<ScheduledNotificationItem> expandedItems = [];
  final DateTime now = DateTime.now();

  for (final video in videoList) {
    if (video.scheduledReminderNotificationId != null && video.scheduledReminderTime != null) {
      try {
        final reminderTime = DateTime.fromMillisecondsSinceEpoch(video.scheduledReminderTime!);
        if (reminderTime.isAfter(now)) {
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

    if (video.scheduledLiveNotificationId != null && video.startScheduled != null) {
       try {
        final liveTime = DateTime.tryParse(video.startScheduled!);
        if (liveTime != null && liveTime.isAfter(now)) {
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
        } else if (liveTime == null){
            logger.warning("[FilteredScheduled] Failed to parse liveTime for video ${video.videoId}: ${video.startScheduled}");
        }
      } catch (e, s) {
        logger.error("Error processing live item ${video.videoId}", e, s);
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
