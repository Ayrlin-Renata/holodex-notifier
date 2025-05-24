import 'dart:convert';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_action_handler.dart';
import 'package:holodex_notifier/domain/interfaces/notification_decision_service.dart';
import 'package:holodex_notifier/domain/interfaces/notification_service.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:holodex_notifier/main.dart' hide ErrorApp, appControllerProvider;
import 'package:holodex_notifier/main.dart' as main_providers show isolateContextProvider;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('FCM Background Message: Handling a background message: ${message.messageId}');

  try {
    DartPluginRegistrant.ensureInitialized();
    print('FCM Background Message: DartPluginRegistrant ensured.');

    final _backgroundContainer = ProviderContainer(overrides: [main_providers.isolateContextProvider.overrideWithValue(IsolateContext.background)]);
    print('FCM Background Message: ProviderContainer created.');

    final ILoggingService logger = _backgroundContainer.read(loggingServiceProvider);
    final ICacheService cacheService = _backgroundContainer.read(cacheServiceProvider);
    final ISettingsService settingsService = await _backgroundContainer.read(settingsServiceFutureProvider.future);
    final INotificationDecisionService decisionService = _backgroundContainer.read(notificationDecisionServiceProvider);
    final INotificationActionHandler actionHandler = _backgroundContainer.read(notificationActionHandlerProvider);
    final INotificationService notificationService = _backgroundContainer.read(notificationServiceProvider);

    logger.info('FCM Background Message: Services resolved.');

    logger.info("FCM Background Message: Extracting JSON payload...");
    final String? videoJsonString = message.data["video"];

    if (videoJsonString != null) {
      try {
        logger.debug('FCM Background Message: JSON extracted: "$videoJsonString". Parsing...');
        final Map<String, dynamic> parsedJson = jsonDecode(videoJsonString);
        final VideoFull videoFullFromFcm = VideoFull.fromJson(parsedJson);
        logger.info('[FCM Background Message] Successfully parsed VideoFull: ${videoFullFromFcm.id} - ${videoFullFromFcm.title}');

        CachedVideo? cachedVideo;
        try {
          cachedVideo = await cacheService.getVideo(videoFullFromFcm.id);
          logger.debug('FCM Background Message: CachedVideo fetched for ${videoFullFromFcm.id}: ${cachedVideo != null}');
        } catch (cacheError, cacheStack) {
          logger.warning('FCM Background Message: Error fetching cached video.', cacheError, cacheStack);
        }

        List<ChannelSubscriptionSetting> allChannelSettings = await settingsService.getChannelSubscriptions();
        Set<String> mentionedForChannels = videoFullFromFcm.mentions?.map((m) => m.id).toSet() ?? {};

        final actions = await decisionService.determineActionsForVideoUpdate(
          fetchedVideo: videoFullFromFcm,
          cachedVideo: cachedVideo,
          allChannelSettings: allChannelSettings,
          mentionedForChannels: mentionedForChannels,
        );
        logger.info('FCM Background Message: determineActionsForVideoUpdate returned ${actions.length} actions.');

        await actionHandler.executeActions(actions);
        logger.info('FCM Background Message: Actions executed successfully.');
      } catch (jsonError, jsonStack) {
        logger.error('[FCM Background Message] Error processing JSON or determining actions', jsonError, jsonStack);
      }
    } else {
      logger.error('[FCM Background Message] ERROR: No valid JSON payload found in FCM data. Message payload: ${message.data}');
    }
  } catch (e, s) {
    print('FCM Background Message: ERROR - Failed to initialize services or parse FCM data: $e $s');
  }
}
