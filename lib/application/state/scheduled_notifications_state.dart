import 'dart:async';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/utils/notification_formatter.dart'; 

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
      final count = await _cacheService.countScheduledVideos();
      final data = await _cacheService.getScheduledVideos();
      _logger.info(
        "[ScheduledNotificationsNotifier] Raw videos fetched from DB: ${data.length} out of $count counted and confirmed items in the database.",
      );
      if (data.isNotEmpty) {
        for (final video in data) {
          _logger.debug(
            "[ScheduledNotificationsNotifier] Fetched video: ${video.videoId}, title: ${video.videoTitle}, scheduledLiveNotificationId: ${video.scheduledLiveNotificationId}, scheduledReminderNotificationId: ${video.scheduledReminderNotificationId}",
          );
        }
      }
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
  final settingsService = ref.read(settingsServiceProvider);
  final logger = ref.read(loggingServiceProvider);

  try {
    final savedTypes = settingsService.getScheduledFilterTypesSync();
    if (savedTypes.isEmpty) {
      logger.debug("No saved scheduled filter types found, defaulting to 'live' and 'reminder'.");
      return {NotificationEventType.live, NotificationEventType.reminder};
    }
    logger.debug("Scheduled filter types initialized from saved settings: ${savedTypes.map((e) => e.name).join(',')}");
    return savedTypes;
  } catch (e, s) {
    logger.error("Error loading saved scheduled filter types, defaulting to 'live' and 'reminder'.", e, s);
    return {NotificationEventType.live, NotificationEventType.reminder};
  }
});

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
  final channelSettingsList = ref.watch(channelListProvider); 
  final allowedTypes = ref.watch(scheduledFilterTypeProvider);
  final selectedChannelId = ref.watch(scheduledFilterChannelProvider);
  final logger = ref.watch(loggingServiceProvider);

  
  if (baseAsyncValue.hasError) return AsyncError(baseAsyncValue.error!, baseAsyncValue.stackTrace!);
  if (formatConfigAsyncValue.hasError) {
    logger.error("[FilteredScheduled] Error loading formatConfig: ${formatConfigAsyncValue.error}");
    return AsyncError(formatConfigAsyncValue.error!, formatConfigAsyncValue.stackTrace!);
  }
  if (baseAsyncValue.isLoading || formatConfigAsyncValue.isLoading) return const AsyncLoading();

  final videoList = baseAsyncValue.requireValue;
  final NotificationFormatConfig? formatConfig = formatConfigAsyncValue.valueOrNull;
  if (formatConfig == null) {
    logger.error("[FilteredScheduled] Format config is null after loading check. Cannot format items.");
    return const AsyncValue.data([]); 
  }

  final List<ScheduledNotificationItem> expandedItems = [];
  final DateTime now = DateTime.now();

  for (final video in videoList) {
    
    List<String>? mentionedNames = video.mentionedChannelIds.isNotEmpty
      ? channelSettingsList
          .where((channel) => video.mentionedChannelIds.contains(channel.channelId))
          .map((channel) => channel.name)
          .toList()
      : null;
    if (mentionedNames != null && mentionedNames.isEmpty) {
        mentionedNames = null; 
        logger.trace("[FilteredScheduled] (${video.videoId}) Could not find names for mentioned IDs ${video.mentionedChannelIds}, using null.");
    }


    
    DateTime? eventTimeUtc = DateTime.tryParse(video.availableAt)?.toUtc();
    if (eventTimeUtc == null) {
       logger.error("[FilteredScheduled] (${video.videoId}) Failed to parse availableAt: ${video.availableAt}");
       continue; 
     }


    
    if (video.scheduledReminderNotificationId != null && video.scheduledReminderTime != null) {
      try {
        final reminderTimeUtc = DateTime.fromMillisecondsSinceEpoch(video.scheduledReminderTime!, isUtc: true); 
        if (reminderTimeUtc.isAfter(DateTime.now().toUtc())) { 
          
          final formatted = formatNotificationContent(
            config: formatConfig,
            eventType: NotificationEventType.reminder,
            channelName: video.channelName,
            videoTitle: video.videoTitle,
            videoType: video.videoType,
            availableAt: eventTimeUtc,           
            notificationScheduledTime: reminderTimeUtc, 
            mentionTargetChannelName: null,       
            mentionedChannelNames: mentionedNames,
            logger: logger,
          );
          
          expandedItems.add(
            ScheduledNotificationItem(
              videoData: video,
              type: NotificationEventType.reminder,
              scheduledTime: reminderTimeUtc.toLocal(), 
              formattedTitle: formatted.title,
              formattedBody: formatted.body,
            ),
          );
        }
      } catch (e, s) {
        logger.error("[FilteredScheduled] Error processing reminder item ${video.videoId}", e, s);
      }
    }

    
    if (video.scheduledLiveNotificationId != null && video.startScheduled != null) {
      try {
        final liveTimeUtc = DateTime.tryParse(video.startScheduled!)?.toUtc(); 
        if (liveTimeUtc != null && liveTimeUtc.isAfter(DateTime.now().toUtc())) { 
          
          final formatted = formatNotificationContent(
            config: formatConfig,
            eventType: NotificationEventType.live,
            channelName: video.channelName,
            videoTitle: video.videoTitle,
            videoType: video.videoType,
            availableAt: liveTimeUtc, 
            notificationScheduledTime: liveTimeUtc, 
            mentionTargetChannelName: null,
            mentionedChannelNames: mentionedNames,
            logger: logger,
          );
          
          expandedItems.add(
            ScheduledNotificationItem(
              videoData: video,
              type: NotificationEventType.live,
              scheduledTime: liveTimeUtc.toLocal(), 
              formattedTitle: formatted.title,
              formattedBody: formatted.body,
            ),
          );
        } else if (liveTimeUtc == null) {
          logger.warning("[FilteredScheduled] Failed to parse liveTime (startScheduled) for video ${video.videoId}: ${video.startScheduled}");
        }
      } catch (e, s) {
        logger.error("[FilteredScheduled] Error processing live item ${video.videoId}", e, s);
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

final dismissedNotificationsNotifierProvider = StateNotifierProvider.autoDispose<DismissedNotificationsNotifier, AsyncValue<List<ScheduledNotificationItem>>>(
  (ref) {
    final logger = ref.watch(loggingServiceProvider);
    final cacheService = ref.watch(cacheServiceProvider);
    
    
    final formatConfigAsyncValue = ref.watch(notificationFormatConfigProvider);
    final channelSettingsAsyncValue = ref.watch(channelListProvider.select((value) => AsyncValue.data(value))); 

    final notifier = DismissedNotificationsNotifier(logger, cacheService, formatConfigAsyncValue, channelSettingsAsyncValue);
    
    return notifier;
  },
  name: 'dismissedNotificationsNotifierProvider', 
);


class DismissedNotificationsNotifier extends StateNotifier<AsyncValue<List<ScheduledNotificationItem>>> {
  final ILoggingService _logger;
  final ICacheService _cacheService;
  NotificationFormatConfig? _formatConfig;

  List<ChannelSubscriptionSetting>? _channelSettingsList;

  DismissedNotificationsNotifier(
    this._logger,
    this._cacheService,
    AsyncValue<NotificationFormatConfig> formatConfigAsyncValue,
    AsyncValue<List<ChannelSubscriptionSetting>> channelSettingsAsyncValue,
  ) : super(const AsyncValue.loading()) {
    formatConfigAsyncValue
        .combineLatest(channelSettingsAsyncValue, (config, settings) {
          _formatConfig = config;
          _channelSettingsList = settings;
          _loadDismissedItems();
        })
        .whenData((_) {});

    if (formatConfigAsyncValue.isLoading || channelSettingsAsyncValue.isLoading) {
      state = const AsyncValue.loading();
    } else if (formatConfigAsyncValue.hasError) {
      state = AsyncValue.error(formatConfigAsyncValue.error!, formatConfigAsyncValue.stackTrace!);
    } else if (channelSettingsAsyncValue.hasError) {
      state = AsyncValue.error(channelSettingsAsyncValue.error!, channelSettingsAsyncValue.stackTrace!);
    }
  }

  Future<void> _loadDismissedItems() async {
    _logger.info("[DismissedNotifier] Loading dismissed items from CacheService...");
    if (!mounted) return;

    if (_formatConfig == null || _channelSettingsList == null) {
      _logger.error("[DismissedNotifier:_loadDismissedItems] Cannot load items, formatConfig or channelSettingsList is unexpectedly null.");

      if (mounted) {
        if (state is! AsyncError) {
          state = const AsyncValue.data([]);
        }
      }
      return;
    }

    try {
      final dismissedVideos = await _cacheService.getDismissedScheduledVideos();

      final formattedItems = _formatItems(dismissedVideos, _formatConfig!, _logger, _channelSettingsList!);
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

  List<ScheduledNotificationItem> _formatItems(
    List<CachedVideo> videos,
    NotificationFormatConfig config,
    ILoggingService logger,
    List<ChannelSubscriptionSetting> channelSettingsList,
  ) {
    final List<ScheduledNotificationItem> items = [];

    for (final video in videos) {
      DateTime? eventTimeUtc;
      DateTime? notificationScheduledTimeUtc;
      NotificationEventType? type;

      
      if (video.scheduledReminderNotificationId != null && video.scheduledReminderTime != null) {
        type = NotificationEventType.reminder;
        notificationScheduledTimeUtc = DateTime.fromMillisecondsSinceEpoch(video.scheduledReminderTime!, isUtc: true);
        
        eventTimeUtc = DateTime.tryParse(video.availableAt)?.toUtc();
      } else if (video.scheduledLiveNotificationId != null && video.startScheduled != null) {
        type = NotificationEventType.live;
        notificationScheduledTimeUtc = DateTime.tryParse(video.startScheduled!)?.toUtc();
        
        eventTimeUtc = notificationScheduledTimeUtc;
      }

      if (type != null && notificationScheduledTimeUtc != null && eventTimeUtc != null) {
        try {
          
          List<String>? mentionedNames = video.mentionedChannelIds.isNotEmpty
            ? channelSettingsList
                .where((channel) => video.mentionedChannelIds.contains(channel.channelId))
                .map((channel) => channel.name)
                .toList()
            : null;
           if (mentionedNames != null && mentionedNames.isEmpty) mentionedNames = null;

          
          final formatted = formatNotificationContent(
             config: config,
             eventType: type,
             channelName: video.channelName,
             videoTitle: video.videoTitle,
             videoType: video.videoType,
             availableAt: eventTimeUtc, 
             notificationScheduledTime: notificationScheduledTimeUtc, 
             mentionTargetChannelName: null, 
             mentionedChannelNames: mentionedNames,
             logger: logger,
           );
          

          items.add(
            ScheduledNotificationItem(
              videoData: video,
              type: type,
              scheduledTime: notificationScheduledTimeUtc.toLocal(), 
              formattedTitle: formatted.title,
              formattedBody: formatted.body,
            ),
          );
        } catch (e, s) {
          logger.error("[DismissedNotifier:_formatItems] Error formatting dismissed item ${video.videoId}", e, s);
        }
      } else {
         logger.warning("[DismissedNotifier:_formatItems] Could not determine valid type/time for dismissed video ${video.videoId}");
         
         eventTimeUtc = DateTime.tryParse(video.availableAt)?.toUtc();
         if (eventTimeUtc != null) {
            
         }
      }
    }
     
    
    return items;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    if (_formatConfig == null || _channelSettingsList == null) {
      _logger.warning(
        "[DismissedNotifier] Cannot refresh, dependencies (_formatConfig or _channelSettingsList) are null. Attempting to reload dependencies indirectly.",
      );

      await Future.delayed(Duration.zero);
      if (_formatConfig == null || _channelSettingsList == null) {
        _logger.error("[DismissedNotifier] Refresh abandoned, dependencies still null after delay.");
        if (mounted) state = const AsyncData([]);
        return;
      }
    }
    await _loadDismissedItems();
  }
}

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
