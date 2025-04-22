import 'dart:async';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/channel_min.dart';
import 'package:holodex_notifier/domain/models/channel_min_with_org.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';



class VideoProcessingContext {
  final VideoFull fetchedVideo;
  final CachedVideo? cachedVideo;
  final ChannelSubscriptionSetting? directChannelSettings;
  final List<ChannelSubscriptionSetting> mentionTargetSettings;
  final bool delayNewMedia;
  final Duration reminderLeadTime;
  final DateTime? userDismissedAt;
  final List<String> sentMentionTargetIds;
  final int? scheduledLiveNotificationId;
  final int? scheduledReminderNotificationId;
  final DateTime? scheduledReminderTime;
  final bool wasPendingNewMedia;
  final DateTime? lastLiveNotificationSentTime;

  
  final bool isNewVideo;
  final bool isCertain;
  final bool wasCertain;
  final bool statusChanged;
  final bool scheduleChanged;
  final bool mentionsChanged;
  final bool becameCertain;
  final bool reminderTimeChanged;

  VideoProcessingContext({
    required this.fetchedVideo,
    required this.cachedVideo,
    required List<ChannelSubscriptionSetting> allChannelSettings,
    required Set<String>? mentionedForChannels, 
    required this.delayNewMedia,
    required this.reminderLeadTime,
  }) : directChannelSettings = allChannelSettings.firstWhereOrNull((s) => s.channelId == fetchedVideo.channel.id),
       mentionTargetSettings = allChannelSettings.where((s) => mentionedForChannels?.contains(s.channelId) ?? false).toList(),
       userDismissedAt = cachedVideo?.userDismissedAt != null ? DateTime.fromMillisecondsSinceEpoch(cachedVideo!.userDismissedAt!) : null,
       sentMentionTargetIds = cachedVideo?.sentMentionTargetIds ?? [],
       scheduledLiveNotificationId = cachedVideo?.scheduledLiveNotificationId,
       scheduledReminderNotificationId = cachedVideo?.scheduledReminderNotificationId,
       scheduledReminderTime =
           cachedVideo?.scheduledReminderTime != null ? DateTime.fromMillisecondsSinceEpoch(cachedVideo!.scheduledReminderTime!) : null,
       wasPendingNewMedia = cachedVideo?.isPendingNewMediaNotification ?? false,
       lastLiveNotificationSentTime =
           cachedVideo?.lastLiveNotificationSentTime != null ? DateTime.fromMillisecondsSinceEpoch(cachedVideo!.lastLiveNotificationSentTime!) : null,
       
       isNewVideo = cachedVideo == null,
       isCertain = (fetchedVideo.certainty == 'certain' || fetchedVideo.certainty == null || fetchedVideo.type != 'placeholder'),
       wasCertain =
           cachedVideo != null && (cachedVideo.certainty == 'certain' || cachedVideo.certainty == null || cachedVideo.videoType != 'placeholder'),
       statusChanged = cachedVideo != null && cachedVideo.status != fetchedVideo.status,
       scheduleChanged = cachedVideo != null && cachedVideo.startScheduled != fetchedVideo.startScheduled?.toIso8601String(),
       mentionsChanged =
           cachedVideo != null &&
           !const ListEquality().equals(cachedVideo.mentionedChannelIds, fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? []),
       becameCertain =
           !(cachedVideo != null &&
               (cachedVideo.certainty == 'certain' || cachedVideo.certainty == null || cachedVideo.videoType != 'placeholder')) &&
           (fetchedVideo.certainty == 'certain' || fetchedVideo.certainty == null || fetchedVideo.type != 'placeholder'),
       reminderTimeChanged =
           cachedVideo?.scheduledReminderTime != null && cachedVideo!.startScheduled != fetchedVideo.startScheduled?.toIso8601String();

  
  bool get hasMentionSubscription => mentionTargetSettings.any((s) => s.notifyMentions);

  
  ChannelSubscriptionSetting? getSettingsForMentionTarget(String channelId) {
    return mentionTargetSettings.firstWhereOrNull((s) => s.channelId == channelId);
  }

  
  bool get wantsDirectNotifications {
    if (directChannelSettings == null) return false;
    if (fetchedVideo.topicId == 'membersonly' && !directChannelSettings!.notifyMembersOnly) return false;
    if (fetchedVideo.type == 'clip' && !directChannelSettings!.notifyClips) return false;

    
    return directChannelSettings!.notifyLive || directChannelSettings!.notifyNewMedia || directChannelSettings!.notifyUpdates;
  }

  
  bool wantsMentionNotificationsFor(String targetChannelId) {
    final setting = getSettingsForMentionTarget(targetChannelId);
    if (setting == null || !setting.notifyMentions) return false;
    if (fetchedVideo.topicId == 'membersonly' && !setting.notifyMembersOnly) return false;
    if (fetchedVideo.type == 'clip' && !setting.notifyClips) return false;
    return true;
  }

  bool get isDismissed => userDismissedAt != null;

  
  bool get wantsAnyLiveNotification {
    
    if (directChannelSettings != null && directChannelSettings!.notifyLive) {
      
      if (fetchedVideo.topicId == 'membersonly' && !directChannelSettings!.notifyMembersOnly) return false;
      if (fetchedVideo.type == 'clip' && !directChannelSettings!.notifyClips) return false;
      return true; 
    }

    
    return mentionTargetSettings.any((setting) {
      bool wantsMentionLive = setting.notifyLive && setting.notifyMentions; 
      if (!wantsMentionLive) return false;
      
      if (fetchedVideo.topicId == 'membersonly' && !setting.notifyMembersOnly) return false;
      if (fetchedVideo.type == 'clip' && !setting.notifyClips) return false;
      return true; 
    });
  }
}




class NotificationDecisionService implements INotificationDecisionService {
  final ICacheService _cacheService;
  final ISettingsService _settingsService;
  final ILoggingService _logger;
  static const Duration _videoMaxAge = Duration(hours: 76); 

  NotificationDecisionService(this._cacheService, this._settingsService, this._logger);

  @override
  Future<List<NotificationAction>> determineActionsForVideoUpdate({
    required VideoFull fetchedVideo,
    required CachedVideo? cachedVideo,
    required List<ChannelSubscriptionSetting> allChannelSettings,
    required Set<String>? mentionedForChannels, 
  }) async {
    final String videoId = fetchedVideo.id;
    final List<NotificationAction> actions = [];
    final DateTime currentSystemTime = DateTime.now();
    _logger.debug("[DecisionService] ($videoId) Determining actions...");

    try {
      
      final bool delayNewMedia = await _settingsService.getDelayNewMedia();
      final Duration reminderLeadTime = await _settingsService.getReminderLeadTime();
      final context = VideoProcessingContext(
        fetchedVideo: fetchedVideo,
        cachedVideo: cachedVideo,
        allChannelSettings: allChannelSettings,
        mentionedForChannels: mentionedForChannels,
        delayNewMedia: delayNewMedia,
        reminderLeadTime: reminderLeadTime,
      );

      
      if (!_shouldTrackVideo(context, currentSystemTime)) {
        _logger.info("[DecisionService] ($videoId) Video should NOT be tracked. Generating untrack actions.");
        actions.add(
          UntrackAndCleanAction(
            videoId: videoId,
            liveNotificationId: context.scheduledLiveNotificationId,
            reminderNotificationId: context.scheduledReminderNotificationId,
          ),
        );
        return actions; 
      }

      _logger.debug("[DecisionService] ($videoId) Video is tracked. Proceeding with action determination.");

      
      actions.addAll(_determineDispatchActions(context, currentSystemTime));

      
      actions.addAll(_determineScheduleActions(context, currentSystemTime));

      
      _addBaseCacheUpdateAction(fetchedVideo, cachedVideo, actions, context);

      _logger.info("[DecisionService] ($videoId) Finished determining ${actions.length} actions for tracked video.");
      return actions;
    } catch (e, s) {
      _logger.error("[DecisionService] ($videoId) Error determining actions for video update", e, s);
      return [];
    }
  }

  
  bool _shouldTrackVideo(VideoProcessingContext context, DateTime now) {
    final videoId = context.fetchedVideo.id;
    final videoChannelId = context.fetchedVideo.channel.id;

    
    bool subscribedDirect = false;
    if (context.directChannelSettings != null) {
      if (context.directChannelSettings!.notifyLive ||
          context.directChannelSettings!.notifyNewMedia ||
          context.directChannelSettings!.notifyUpdates ||
          context.directChannelSettings!.notifyClips) {
        
        
        if (context.fetchedVideo.topicId == 'membersonly' && !context.directChannelSettings!.notifyMembersOnly) {
          
        } else if (context.fetchedVideo.type == 'clip' && !context.directChannelSettings!.notifyClips) {
          
        } else {
          subscribedDirect = true;
          _logger.trace("[DecisionService] ($videoId) Track check: Subscribed directly True (Channel: $videoChannelId).");
        }
      }
    }
    if (subscribedDirect && context.fetchedVideo.topicId == 'membersonly' && !context.directChannelSettings!.notifyMembersOnly) {
      _logger.trace("[DecisionService] ($videoId) Track check: Overriding direct subscription due to members-only filter.");
      subscribedDirect = false;
    }

    if (subscribedDirect && context.fetchedVideo.type == 'clip' && !context.directChannelSettings!.notifyClips) {
      _logger.trace("[DecisionService] ($videoId) Track check: Overriding direct subscription due to clip filter.");
      subscribedDirect = false;
    }

    
    bool subscribedMention = false;
    if (context.mentionTargetSettings.isNotEmpty) {
      subscribedMention = context.mentionTargetSettings.any((setting) {
        bool wantsMention = setting.notifyMentions;
        if (!wantsMention) return false;
        
        if (context.fetchedVideo.topicId == 'membersonly' && !setting.notifyMembersOnly) return false;
        if (context.fetchedVideo.type == 'clip' && !setting.notifyClips) return false;
        return true; 
      });
      if (subscribedMention) {
        _logger.trace(
          "[DecisionService] ($videoId) Track check: Subscribed via mentions True (Targets: ${context.mentionTargetSettings.map((s) => s.channelId).join(',')}).",
        );
      }
    }

    
    if (!subscribedDirect && !subscribedMention) {
      _logger.info("[DecisionService] ($videoId) Untracking: Not subscribed directly or via mentions.");
      return false;
    }

    
    final videoStartTime = context.fetchedVideo.startScheduled ?? context.fetchedVideo.startActual ?? context.fetchedVideo.availableAt;
    if (now.difference(videoStartTime) > _videoMaxAge) {
      _logger.info(
        "[DecisionService] ($videoId) Untracking: Video start time ($videoStartTime) is older than max age (${_videoMaxAge.inHours} hours).",
      );
      return false;
    }

    _logger.trace("[DecisionService] ($videoId) Track check: Passed all checks. Should track.");
    return true; 
  }

  
  List<NotificationAction> _determineDispatchActions(VideoProcessingContext context, DateTime now) {
    final List<NotificationAction> actions = [];
    final videoId = context.fetchedVideo.id;
    _logger.trace("[$videoId] _determineDispatchActions START");

    
    if (context.wantsDirectNotifications) {
      _logger.trace("[$videoId] Checking direct dispatch actions...");
      final channelSettings = context.directChannelSettings!; 

      
      
      final bool isPotentialNew =
          context.isNewVideo || (context.statusChanged && context.cachedVideo?.status == 'missing' && context.fetchedVideo.status == 'new');
      if (isPotentialNew && channelSettings.notifyNewMedia) {
        _logger.trace('[$videoId] Potential New Media Event.');
        if (context.delayNewMedia && !context.isCertain) {
          _logger.info('[$videoId] Delaying New Media notification (Uncertainty + Setting ON). Setting pending flag.');
          
          actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(true))));
        } else if (context.isDismissed) {
          _logger.info('[$videoId] Suppressing New Media dispatch (Recently Dismissed). Setting pending flag if uncertain.');
          
          if (!context.isCertain) {
            actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(true))));
          } else {
            actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
          }
        } else {
          _logger.info('[$videoId] Dispatching New Media notification.');
          
          actions.add(DispatchNotificationAction(instruction: _createNotificationInstruction(context.fetchedVideo, NotificationEventType.newMedia)));
          actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
        }
      }

      
      if (context.wasPendingNewMedia && channelSettings.notifyNewMedia) {
        final bool triggerConditionMet =
            context.becameCertain || (context.statusChanged && context.fetchedVideo.status != 'upcoming' && context.fetchedVideo.status != 'new');
        if (triggerConditionMet) {
          if (context.isDismissed) {
            _logger.info('[$videoId] Suppressing Pending New Media dispatch (Recently Dismissed). Clearing pending flag.');
            
            actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
          } else {
            _logger.info('[$videoId] Pending New Media condition met. Dispatching.');
            
            actions.add(
              DispatchNotificationAction(instruction: _createNotificationInstruction(context.fetchedVideo, NotificationEventType.newMedia)),
            );
            actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
          }
        }
      }

      
      if (!context.isNewVideo && channelSettings.notifyUpdates && context.scheduleChanged) {
        _logger.trace('[$videoId] Potential Update Event (Schedule Changed).');
        
        bool onlyCertaintyChangedWithDelay =
            context.becameCertain && !context.statusChanged && !context.mentionsChanged && !context.scheduleChanged && context.delayNewMedia;

        if (!onlyCertaintyChangedWithDelay) {
          if (context.isDismissed) {
            _logger.info('[$videoId] Suppressing Update notification (Recently Dismissed).');
          } else {
            _logger.info('[$videoId] Dispatching Update notification.');
            
            actions.add(DispatchNotificationAction(instruction: _createNotificationInstruction(context.fetchedVideo, NotificationEventType.update)));
            
            
            actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));
          }
        } else {
          _logger.info('[$videoId] SUPPRESSING Update notification (Only certainty changed & Delay ON).');
        }
      }

      
      if (context.statusChanged && context.fetchedVideo.status == 'live' && channelSettings.notifyLive) {
        _logger.trace('[$videoId] Live Event detected (Became Live).');
        const Duration debounceDuration = Duration(minutes: 2);
        DateTime? lastSentTime = context.lastLiveNotificationSentTime;
        bool shouldSend = true;
        if (lastSentTime != null) {
          final timeSinceLastSent = now.difference(lastSentTime);
          if (timeSinceLastSent < debounceDuration) {
            _logger.info('[$videoId] SUPPRESSING Live notification (Sent ${timeSinceLastSent.inSeconds}s ago).');
            shouldSend = false;
          }
        }

        if (shouldSend) {
          if (context.isDismissed) {
            _logger.info('[$videoId] SUPPRESSING Live notification (Recently Dismissed).');
          } else {
            _logger.info('[$videoId] Dispatching immediate Live notification.');
            
            actions.add(DispatchNotificationAction(instruction: _createNotificationInstruction(context.fetchedVideo, NotificationEventType.live)));
            
            
            actions.add(
              UpdateCacheAction(videoId: videoId, companion: CachedVideosCompanion(lastLiveNotificationSentTime: Value(now.millisecondsSinceEpoch))),
            );
            
            
            actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));
          }
        }
      }
    } else {
      _logger.trace("[$videoId] Skipping direct dispatch actions (user settings).");
    }

    
    if (context.mentionTargetSettings.isNotEmpty) {
      _logger.trace("[$videoId] Checking mention dispatch actions...");
      final List<String> newlySentMentions = [];

      for (final mentionedChannelId in context.mentionTargetSettings.map((s) => s.channelId)) {
        if (context.wantsMentionNotificationsFor(mentionedChannelId)) {
          if (!context.sentMentionTargetIds.contains(mentionedChannelId)) {
            if (context.isDismissed) {
              _logger.info('[$videoId] SUPPRESSING Mention notification for target $mentionedChannelId (Recently Dismissed).');
            } else {
              final mentionDetails = context.fetchedVideo.mentions?.firstWhereOrNull((m) => m.id == mentionedChannelId);
              final targetChannelName = mentionDetails?.name ?? context.getSettingsForMentionTarget(mentionedChannelId)!.name;
              _logger.info('[$videoId] Dispatching Mention notification for target $mentionedChannelId ($targetChannelName).');

              
              actions.add(
                DispatchNotificationAction(
                  instruction: _createNotificationInstruction(
                    context.fetchedVideo,
                    NotificationEventType.mention,
                    mentionTargetId: mentionedChannelId,
                    mentionTargetName: targetChannelName,
                    
                    mentionedChannelNames: null,
                  ),
                ),
              );
              newlySentMentions.add(mentionedChannelId);
              
              
              actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(userDismissedAt: Value(null))));
            }
          } else {
            _logger.trace('[$videoId] Skipping mention dispatch for $mentionedChannelId (already sent).');
          }
        } else {
          _logger.trace('[$videoId] Skipping mention dispatch for $mentionedChannelId (user settings/filters).');
        }
      }
      if (newlySentMentions.isNotEmpty) {
        final updatedList = [...context.sentMentionTargetIds, ...newlySentMentions];
        
        actions.add(UpdateCacheAction(videoId: videoId, companion: CachedVideosCompanion(sentMentionTargetIds: Value(updatedList))));
      }
    }

    _logger.trace("[$videoId] _determineDispatchActions END - Actions: ${actions.length}");
    return actions;
  }

  
  List<NotificationAction> _determineScheduleActions(VideoProcessingContext context, DateTime now) {
    
    final List<NotificationAction> actions = [];
    final videoId = context.fetchedVideo.id;
    _logger.trace("[$videoId] _determineScheduleActions START");

    final scheduledTime = context.fetchedVideo.startScheduled;

    
    final bool canSchedule = scheduledTime != null && scheduledTime.isAfter(now) && !context.isDismissed;

    if (!canSchedule) {
      _logger.trace("[$videoId] Cannot schedule (time in past, not upcoming, or dismissed). Cancelling existing.");
      if (context.scheduledLiveNotificationId != null) {
        
        actions.add(
          CancelNotificationAction(notificationId: context.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live),
        );
        actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
      }
      if (context.scheduledReminderNotificationId != null) {
        
        actions.add(
          CancelNotificationAction(notificationId: context.scheduledReminderNotificationId!, videoId: videoId, type: NotificationEventType.reminder),
        );
        actions.add(
          UpdateCacheAction(
            videoId: videoId,
            companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
          ),
        );
      }
      return actions;
    }

    
    final bool wantsLive = context.wantsAnyLiveNotification; 
    final bool shouldScheduleLive = wantsLive && context.fetchedVideo.status == 'upcoming'; 
    final bool isLiveScheduled = context.scheduledLiveNotificationId != null;
    final bool needsLiveReschedule = context.scheduleChanged || context.becameCertain;

    _logger.trace(
      "[$videoId] Live Schedule Check: wantsLive=$wantsLive, shouldScheduleLive=$shouldScheduleLive, isLiveScheduled=$isLiveScheduled, needsLiveReschedule=$needsLiveReschedule",
    );

    if (shouldScheduleLive) {
      if (!isLiveScheduled || needsLiveReschedule) {
        _logger.info("[$videoId] Scheduling/Rescheduling LIVE notification for $scheduledTime.");
        if (isLiveScheduled) {
          
          actions.add(
            CancelNotificationAction(notificationId: context.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live),
          );
          actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
        }
        final instruction = _createNotificationInstruction(context.fetchedVideo, NotificationEventType.live, mentionedChannelNames: []);
        
        actions.add(
          ScheduleNotificationAction(instruction: instruction, scheduleTime: scheduledTime, videoId: videoId),
        ); 
        
        actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(-1))));
      } else {
        _logger.trace("[$videoId] Live notification already scheduled correctly.");
      }
    } else if (isLiveScheduled) {
      _logger.info("[$videoId] Cancelling existing LIVE notification.");
      
      actions.add(CancelNotificationAction(notificationId: context.scheduledLiveNotificationId!, videoId: videoId, type: NotificationEventType.live));
      actions.add(UpdateCacheAction(videoId: videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
    }

    
    final bool wantsReminders = wantsLive && context.reminderLeadTime > Duration.zero; 
    final bool shouldScheduleReminder = wantsReminders && context.fetchedVideo.status == 'upcoming';
    final bool isReminderScheduled = context.scheduledReminderNotificationId != null;
    final bool needsReminderReschedule = context.scheduleChanged || context.becameCertain || context.reminderTimeChanged;
    final DateTime targetReminderTime = scheduledTime.subtract(context.reminderLeadTime);

    _logger.trace(
      "[$videoId] Reminder Schedule Check: wantsReminders=$wantsReminders, shouldScheduleReminder=$shouldScheduleReminder, isReminderScheduled=$isReminderScheduled, needsReminderReschedule=$needsReminderReschedule, targetTime=$targetReminderTime",
    );

    if (shouldScheduleReminder && targetReminderTime.isAfter(now)) {
      if (!isReminderScheduled || needsReminderReschedule) {
        _logger.info("[$videoId] Scheduling/Rescheduling REMINDER notification for $targetReminderTime.");
        if (isReminderScheduled) {
          
          actions.add(
            CancelNotificationAction(
              notificationId: context.scheduledReminderNotificationId!,
              videoId: videoId,
              type: NotificationEventType.reminder,
            ),
          );
          actions.add(
            UpdateCacheAction(
              videoId: videoId,
              companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
            ),
          );
        }
        final instruction = _createNotificationInstruction(context.fetchedVideo, NotificationEventType.reminder, mentionedChannelNames: []);
        
        actions.add(ScheduleNotificationAction(instruction: instruction, scheduleTime: targetReminderTime, videoId: videoId));
        
        actions.add(
          UpdateCacheAction(
            videoId: videoId,
            companion: CachedVideosCompanion(
              scheduledReminderNotificationId: const Value(-1),
              scheduledReminderTime: Value(targetReminderTime.millisecondsSinceEpoch),
            ),
          ),
        );
      } else {
        _logger.trace("[$videoId] Reminder notification already scheduled correctly.");
      }
    } else if (isReminderScheduled) {
      _logger.info("[$videoId] Cancelling existing REMINDER notification (should not be scheduled or time is past).");
      
      actions.add(
        CancelNotificationAction(notificationId: context.scheduledReminderNotificationId!, videoId: videoId, type: NotificationEventType.reminder),
      );
      actions.add(
        UpdateCacheAction(
          videoId: videoId,
          companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
        ),
      );
    }

    _logger.trace("[$videoId] _determineScheduleActions END - Actions: ${actions.length}");
    return actions;
  }

  void _addBaseCacheUpdateAction(VideoFull fetchedVideo, CachedVideo? cachedVideo, List<NotificationAction> actions, VideoProcessingContext context) {
    final videoId = fetchedVideo.id;
    String? videoThumbnailUrl;
    if (fetchedVideo.type == 'placeholder' && fetchedVideo.thumbnail != null && fetchedVideo.thumbnail!.isNotEmpty) {
      videoThumbnailUrl = fetchedVideo.thumbnail;
    } else {
      videoThumbnailUrl = 'https://i.ytimg.com/vi/${fetchedVideo.id}/mqdefault.jpg';
    }

    final companion = CachedVideosCompanion(
      videoId: Value(videoId),
      channelId: Value(fetchedVideo.channel.id),
      status: Value(fetchedVideo.status),
      startScheduled: Value(fetchedVideo.startScheduled?.toIso8601String()),
      startActual: Value(fetchedVideo.startActual?.toIso8601String()),
      availableAt: Value(fetchedVideo.availableAt.toIso8601String()),
      videoType: Value(fetchedVideo.type),
      thumbnailUrl: Value(videoThumbnailUrl),
      topicId: Value(fetchedVideo.topicId),
      certainty: Value(fetchedVideo.certainty),
      mentionedChannelIds: Value(fetchedVideo.mentions?.map((m) => m.id).whereType<String>().toList() ?? []),
      videoTitle: Value(fetchedVideo.title),
      channelName: Value(fetchedVideo.channel.name),
      channelAvatarUrl: Value(fetchedVideo.channel.photo),
      lastSeenTimestamp: Value(DateTime.now().millisecondsSinceEpoch),
      
    );

    
    actions.add(UpdateCacheAction(videoId: videoId, companion: companion));
    _logger.trace("[DecisionService] ($videoId) Added base cache update action.");
  }

  NotificationInstruction _createNotificationInstruction(
    VideoFull video,
    NotificationEventType type, {
    String? mentionTargetId,
    String? mentionTargetName,
    List<String>? mentionedChannelNames, 
  }) {
    String? thumbnailUrl;
    String? sourceLink;

    if (video.type == 'placeholder' && video.thumbnail != null && video.thumbnail!.isNotEmpty) {
      thumbnailUrl = video.thumbnail;
      if (video.link != null && video.link!.isNotEmpty) {
        sourceLink = video.link;
      }
    } else {
      thumbnailUrl = 'https://i.ytimg.com/vi/${video.id}/mqdefault.jpg';
    }

    
    
    
    
    
    

    return NotificationInstruction(
      videoId: video.id,
      eventType: type,
      channelId: video.channel.id,
      channelName: video.channel.name,
      videoTitle: video.title,
      videoType: video.type,
      channelAvatarUrl: video.channel.photo,
      availableAt: video.availableAt,
      mentionTargetChannelId: mentionTargetId,
      mentionTargetChannelName: mentionTargetName,
      mentionedChannelNames: mentionedChannelNames, 
      videoThumbnailUrl: thumbnailUrl,
      videoSourceLink: sourceLink,
    );
  }

  
  @override
  Future<List<NotificationAction>> determineActionsForChannelSettingChange({
    required String channelId,
    required String settingKey,
    required bool oldValue,
    required bool newValue,
  }) async {
    
    _logger.info("[DecisionService] ($channelId) Determining actions for setting change: $settingKey ($oldValue -> $newValue)");
    final List<NotificationAction> actions = [];
    if (newValue == oldValue) return actions;
    final allCurrentSettings = await _settingsService.getChannelSubscriptions();

    if (!newValue) {
      
      if (settingKey == 'notifyLive') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyLive. Fetching Live/Reminder notifications to cancel...");
        final List<CachedVideo> scheduledVids = (await _cacheService.getScheduledVideos()).where((v) => v.channelId == channelId).toList();
        for (final video in scheduledVids) {
          if (video.scheduledLiveNotificationId != null) {
            actions.add(
              CancelNotificationAction(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
            );
            actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
          }
          if (video.scheduledReminderNotificationId != null) {
            actions.add(
              CancelNotificationAction(
                notificationId: video.scheduledReminderNotificationId!,
                videoId: video.videoId,
                type: NotificationEventType.reminder,
              ),
            );
            actions.add(
              UpdateCacheAction(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
              ),
            );
          }
        }
      } else if (settingKey == 'notifyMembersOnly') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyMembersOnly. Fetching members-only videos to cancel/clear pending...");
        final List<CachedVideo> membersVids = await _cacheService.getMembersOnlyVideosByChannel(channelId);
        for (final video in membersVids) {
          if (video.scheduledLiveNotificationId != null) {
            actions.add(
              CancelNotificationAction(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
            );
            actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
          }
          if (video.scheduledReminderNotificationId != null) {
            actions.add(
              CancelNotificationAction(
                notificationId: video.scheduledReminderNotificationId!,
                videoId: video.videoId,
                type: NotificationEventType.reminder,
              ),
            );
            actions.add(
              UpdateCacheAction(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
              ),
            );
          }
          if (video.isPendingNewMediaNotification) {
            actions.add(
              UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))),
            );
          }
        }
      } else if (settingKey == 'notifyClips') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyClips. Fetching clip videos to cancel/clear pending...");
        final List<CachedVideo> clipVids = await _cacheService.getClipVideosByChannel(channelId);
        for (final video in clipVids) {
          if (video.isPendingNewMediaNotification) {
            actions.add(
              UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))),
            );
          }
          
          if (video.scheduledLiveNotificationId != null) {
            actions.add(
              CancelNotificationAction(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
            );
            actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
          }
          if (video.scheduledReminderNotificationId != null) {
            actions.add(
              CancelNotificationAction(
                notificationId: video.scheduledReminderNotificationId!,
                videoId: video.videoId,
                type: NotificationEventType.reminder,
              ),
            );
            actions.add(
              UpdateCacheAction(
                videoId: video.videoId,
                companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
              ),
            );
          }
        }
      } else if (settingKey == 'notifyNewMedia') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyNewMedia. Clearing pending flags...");
        final List<CachedVideo> potentiallyPending =
            (await _cacheService.getVideosByStatus('new') + await _cacheService.getVideosByStatus('upcoming'))
                .where((v) => v.channelId == channelId && v.isPendingNewMediaNotification)
                .toList();
        for (final video in potentiallyPending) {
          actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
        }
      } else if (settingKey == 'notifyMentions') {
        _logger.debug("[DecisionService] ($channelId) Disabling notifyMentions. Checking potentially affected videos mentioning this channel...");
        try {
          final List<CachedVideo> mentionedVideos = await _cacheService.getVideosMentioningChannel(channelId);
          _logger.debug("[DecisionService] ($channelId) Found ${mentionedVideos.length} videos mentioning this channel.");

          
          final settingsWithMentionOff =
              allCurrentSettings.map((s) {
                return s.channelId == channelId ? s.copyWith(notifyMentions: false) : s;
              }).toList();

          for (final video in mentionedVideos) {
            
            final VideoProcessingContext tempContext = VideoProcessingContext(
              fetchedVideo: video.toVideoFull(), 
              cachedVideo: video,
              allChannelSettings: settingsWithMentionOff, 
              mentionedForChannels: video.mentionedChannelIds.toSet(), 
              delayNewMedia: await _settingsService.getDelayNewMedia(), 
              reminderLeadTime: await _settingsService.getReminderLeadTime(), 
            );

            
            if (!_shouldTrackVideo(tempContext, DateTime.now())) {
              _logger.info(
                "[DecisionService] ($channelId -> ${video.videoId}) Video no longer tracked after disabling mentions. Adding Untrack action.",
              );
              actions.add(
                UntrackAndCleanAction(
                  videoId: video.videoId,
                  liveNotificationId: video.scheduledLiveNotificationId,
                  reminderNotificationId: video.scheduledReminderNotificationId,
                ),
              );
            } else {
              _logger.trace("[DecisionService] ($channelId -> ${video.videoId}) Video still tracked by other means. No untrack action needed.");
            }
          }
        } catch (e, s) {
          _logger.error("[DecisionService] ($channelId) Error during notifyMentions disable check.", e, s);
        }

        
      }
      
    } else {
      
      bool needsScheduleCheck = false;
      List<CachedVideo> videosToCheck = [];

      final allCurrentSettings = await _settingsService.getChannelSubscriptions();
      final currentPersistedSetting = allCurrentSettings.firstWhereOrNull((s) => s.channelId == channelId);

      if (currentPersistedSetting == null) {
        _logger.error("[DecisionService] ($channelId) CRITICAL: Cannot find persisted settings for channel during $settingKey enable check.");
        return []; 
      }

      
      final effectiveSetting = currentPersistedSetting.copyWith(
        notifyLive: (settingKey == 'notifyLive') ? newValue : currentPersistedSetting.notifyLive,
        notifyMembersOnly: (settingKey == 'notifyMembersOnly') ? newValue : currentPersistedSetting.notifyMembersOnly,
        notifyClips: (settingKey == 'notifyClips') ? newValue : currentPersistedSetting.notifyClips,
        
      );

      
      if (settingKey == 'notifyLive' || settingKey == 'notifyMembersOnly' || settingKey == 'notifyClips') {
        _logger.debug("[DecisionService] ($channelId) Enabling $settingKey. Checking for missing schedules...");
        needsScheduleCheck = true;
        
        videosToCheck = (await _cacheService.getVideosByStatus('upcoming')).where((v) => v.channelId == channelId).toList();
      }
      

      if (needsScheduleCheck && videosToCheck.isNotEmpty) {
        _logger.debug("[DecisionService] ($channelId) Found ${videosToCheck.length} videos for schedule check after enabling $settingKey.");
        final reminderLeadTime = await _settingsService.getReminderLeadTime(); 

        for (final video in videosToCheck) {
          
          if (!effectiveSetting.notifyLive) continue; 
          if (video.topicId == 'membersonly' && !effectiveSetting.notifyMembersOnly) continue;
          if (video.videoType == 'clip' && !effectiveSetting.notifyClips) continue;

          final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
          if (scheduledTime == null || scheduledTime.isBefore(DateTime.now())) continue;

          
          if (video.scheduledLiveNotificationId == null) {
            _logger.debug("[DecisionService] ($channelId) Queuing schedule action for LIVE on ${video.videoId}.");
            actions.add(
              ScheduleNotificationAction(
                instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.live),
                scheduleTime: scheduledTime,
                videoId: video.videoId,
              ),
            );
            actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(-1))));
          }

          
          if (reminderLeadTime > Duration.zero && video.scheduledReminderNotificationId == null) {
            final calculatedReminderTime = scheduledTime.subtract(reminderLeadTime);
            if (calculatedReminderTime.isAfter(DateTime.now())) {
              _logger.debug("[DecisionService] ($channelId) Queuing schedule action for REMINDER on ${video.videoId}.");
              actions.add(
                ScheduleNotificationAction(
                  instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.reminder),
                  scheduleTime: calculatedReminderTime,
                  videoId: video.videoId,
                ),
              );
              actions.add(
                UpdateCacheAction(
                  videoId: video.videoId,
                  companion: CachedVideosCompanion(
                    scheduledReminderNotificationId: const Value(-1),
                    scheduledReminderTime: Value(calculatedReminderTime.millisecondsSinceEpoch),
                  ),
                ),
              );
            }
          }
        }
      } else if (needsScheduleCheck) {
        _logger.debug("[DecisionService] ($channelId) No relevant videos found for schedule check after enabling $settingKey.");
      }
    }

    _logger.info("[DecisionService] ($channelId/$settingKey) Determined ${actions.length} actions for setting change.");
    return actions;
  }

  @override
  Future<List<NotificationAction>> determineActionsForApplyGlobalDefaults({
    required List<ChannelSubscriptionSetting> oldSettings,
    required List<ChannelSubscriptionSetting> newSettings,
  }) async {
    
    _logger.info("[DecisionService] Determining actions for applying global defaults...");
    final List<NotificationAction> allActions = [];
    final Map<String, ChannelSubscriptionSetting> oldSettingsMap = {for (var s in oldSettings) s.channelId: s};

    for (final newSetting in newSettings) {
      final oldSetting = oldSettingsMap[newSetting.channelId];
      if (oldSetting == null) continue;

      if (oldSetting.notifyLive != newSetting.notifyLive) {
        allActions.addAll(
          await determineActionsForChannelSettingChange(
            channelId: newSetting.channelId,
            settingKey: 'notifyLive',
            oldValue: oldSetting.notifyLive,
            newValue: newSetting.notifyLive,
          ),
        );
      }
      if (oldSetting.notifyMembersOnly != newSetting.notifyMembersOnly) {
        allActions.addAll(
          await determineActionsForChannelSettingChange(
            channelId: newSetting.channelId,
            settingKey: 'notifyMembersOnly',
            oldValue: oldSetting.notifyMembersOnly,
            newValue: newSetting.notifyMembersOnly,
          ),
        );
      }
      if (oldSetting.notifyClips != newSetting.notifyClips) {
        allActions.addAll(
          await determineActionsForChannelSettingChange(
            channelId: newSetting.channelId,
            settingKey: 'notifyClips',
            oldValue: oldSetting.notifyClips,
            newValue: newSetting.notifyClips,
          ),
        );
      }
      if (oldSetting.notifyNewMedia != newSetting.notifyNewMedia) {
        allActions.addAll(
          await determineActionsForChannelSettingChange(
            channelId: newSetting.channelId,
            settingKey: 'notifyNewMedia',
            oldValue: oldSetting.notifyNewMedia,
            newValue: newSetting.notifyNewMedia,
          ),
        );
      }
      if (oldSetting.notifyUpdates != newSetting.notifyUpdates) {
        allActions.addAll(
          await determineActionsForChannelSettingChange(
            channelId: newSetting.channelId,
            settingKey: 'notifyUpdates',
            oldValue: oldSetting.notifyUpdates,
            newValue: newSetting.notifyUpdates,
          ),
        );
      }
      if (oldSetting.notifyMentions != newSetting.notifyMentions) {
        allActions.addAll(
          await determineActionsForChannelSettingChange(
            channelId: newSetting.channelId,
            settingKey: 'notifyMentions',
            oldValue: oldSetting.notifyMentions,
            newValue: newSetting.notifyMentions,
          ),
        );
      }
    }
    _logger.info("[DecisionService] Determined ${allActions.length} actions for global defaults application.");
    return allActions;
  }

  @override
  Future<List<NotificationAction>> determineActionsForChannelRemoval({required String channelId}) async {
    
    _logger.info("[DecisionService] ($channelId) Determining actions for channel removal...");
    final List<NotificationAction> actions = [];

    final List<CachedVideo> scheduledVids = (await _cacheService.getScheduledVideos()).where((v) => v.channelId == channelId).toList();

    for (final video in scheduledVids) {
      if (video.scheduledLiveNotificationId != null) {
        actions.add(
          CancelNotificationAction(notificationId: video.scheduledLiveNotificationId!, videoId: video.videoId, type: NotificationEventType.live),
        );
        actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(scheduledLiveNotificationId: Value(null))));
      }
      if (video.scheduledReminderNotificationId != null) {
        actions.add(
          CancelNotificationAction(
            notificationId: video.scheduledReminderNotificationId!,
            videoId: video.videoId,
            type: NotificationEventType.reminder,
          ),
        );
        actions.add(
          UpdateCacheAction(
            videoId: video.videoId,
            companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
          ),
        );
      }
    }
    final List<CachedVideo> potentialPending =
        (await _cacheService.getVideosByStatus('new') + await _cacheService.getVideosByStatus('upcoming'))
            .where((v) => v.channelId == channelId && v.isPendingNewMediaNotification)
            .toList();
    for (final video in potentialPending) {
      actions.add(UpdateCacheAction(videoId: video.videoId, companion: const CachedVideosCompanion(isPendingNewMediaNotification: Value(false))));
      _logger.debug("[DecisionService] ($channelId/${video.videoId}) Clearing pending flag due to channel removal.");
    }

    
    
    try {
      final List<String> videosToRemove = (await _cacheService.getVideosByChannel(channelId)).map((v) => v.videoId).toList();
      _logger.info("[DecisionService] ($channelId) Found ${videosToRemove.length} videos in cache associated with removed channel.");
      for (final videoIdToRemove in videosToRemove) {
        
        
        
        _logger.debug("[DecisionService] ($channelId) Adding cache deletion for video $videoIdToRemove");
        
        
        
        final cachedVid = await _cacheService.getVideo(videoIdToRemove); 
        actions.add(
          UntrackAndCleanAction(
            videoId: videoIdToRemove,
            liveNotificationId: cachedVid?.scheduledLiveNotificationId,
            reminderNotificationId: cachedVid?.scheduledReminderNotificationId,
          ),
        );
      }
    } catch (e, s) {
      _logger.error("[DecisionService] ($channelId) Error querying/processing videos for removal cleanup.", e, s);
    }

    _logger.info("[DecisionService] ($channelId) Determined ${actions.length} cancellation/cleanup actions for channel removal.");
    return actions;
  }

  @override
  Future<List<NotificationAction>> determineActionsForReminderLeadTimeChange({required Duration oldLeadTime, required Duration newLeadTime}) async {
    
    _logger.info("[DecisionService] Determining actions for reminder lead time change ($oldLeadTime -> $newLeadTime)");
    final List<NotificationAction> allActions = [];
    final List<ChannelSubscriptionSetting> activeChannels = (await _settingsService.getChannelSubscriptions()).where((s) => s.notifyLive).toList();

    if (activeChannels.isEmpty) {
      _logger.debug("[DecisionService] No channels active for live notifications. No reminder changes needed.");
      return [];
    }

    final List<CachedVideo> allUpcomingVideos =
        (await _cacheService.getVideosByStatus('upcoming')).where((v) => activeChannels.any((ch) => ch.channelId == v.channelId)).toList();

    _logger.debug("[DecisionService] Found ${allUpcomingVideos.length} upcoming videos for channels with notifyLive enabled.");

    for (final video in allUpcomingVideos) {
      final channelSetting = activeChannels.firstWhereOrNull((ch) => ch.channelId == video.channelId);
      if (channelSetting == null) continue;

      if (video.topicId == 'membersonly' && !channelSetting.notifyMembersOnly) continue;
      if (video.videoType == 'clip' && !channelSetting.notifyClips) continue;

      _logger.trace("[DecisionService] (${video.videoId}) Processing for reminder lead time change.");

      
      if (video.scheduledReminderNotificationId != null) {
        _logger.debug(
          "[DecisionService] (${video.videoId}) Cancelling existing reminder ID ${video.scheduledReminderNotificationId} due to lead time change.",
        );
        allActions.add(
          CancelNotificationAction(
            notificationId: video.scheduledReminderNotificationId!,
            videoId: video.videoId,
            type: NotificationEventType.reminder,
          ),
        );
        allActions.add(
          UpdateCacheAction(
            videoId: video.videoId,
            companion: const CachedVideosCompanion(scheduledReminderNotificationId: Value(null), scheduledReminderTime: Value(null)),
          ),
        );
      }

      
      final scheduledTime = DateTime.tryParse(video.startScheduled ?? '');
      if (newLeadTime > Duration.zero && scheduledTime != null && scheduledTime.isAfter(DateTime.now())) {
        final calculatedReminderTime = scheduledTime.subtract(newLeadTime);
        if (calculatedReminderTime.isAfter(DateTime.now())) {
          _logger.debug(
            "[DecisionService] (${video.videoId}) Scheduling new reminder for $calculatedReminderTime with lead time ${newLeadTime.inMinutes} min.",
          );
          allActions.add(
            ScheduleNotificationAction(
              instruction: _createNotificationInstruction(video.toVideoFull(), NotificationEventType.reminder),
              scheduleTime: calculatedReminderTime,
              videoId: video.videoId,
            ),
          );
          allActions.add(
            UpdateCacheAction(
              videoId: video.videoId,
              companion: CachedVideosCompanion(
                scheduledReminderNotificationId: const Value(-1),
                scheduledReminderTime: Value(calculatedReminderTime.millisecondsSinceEpoch),
              ),
            ),
          );
        } else {
          _logger.trace("[DecisionService] (${video.videoId}) New calculated reminder time $calculatedReminderTime is in the past. Not scheduling.");
        }
      } else {
        _logger.trace("[DecisionService] (${video.videoId}) Not scheduling new reminder (lead time zero or video not applicable).");
      }
    }

    _logger.info("[DecisionService] Determined ${allActions.length} actions for reminder lead time change.");
    return allActions;
  }
} 






extension on CachedVideo {
  VideoFull toVideoFull() {
    DateTime? tryParseDateTime(String? iso) => iso == null ? null : DateTime.tryParse(iso);
    DateTime parseDateTimeReq(String iso) => DateTime.parse(iso); 

    List<ChannelMinWithOrg> mentions = [];
    try {
      mentions = mentionedChannelIds.map((id) => ChannelMinWithOrg(id: id, name: 'Unknown Channel')).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error in CachedVideo extension: $e');
    }

    return VideoFull(
      id: videoId,
      title: videoTitle,
      type: videoType ?? 'unknown',
      topicId: topicId,
      publishedAt: null, 
      availableAt: parseDateTimeReq(availableAt), 
      duration: 0, 
      status: status,
      startScheduled: tryParseDateTime(startScheduled),
      startActual: tryParseDateTime(startActual),
      endActual: null, 
      liveViewers: null, 
      description: null, 
      songcount: null, 
      channel: ChannelMin(id: channelId, name: channelName, photo: channelAvatarUrl, type: 'vtuber'), 
      certainty: certainty,
      thumbnail: null, 
      link: null, 
      mentions: mentions,
    );
  }
}
