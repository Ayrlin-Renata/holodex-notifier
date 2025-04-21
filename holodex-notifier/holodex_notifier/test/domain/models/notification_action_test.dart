// ignore_for_file: unused_local_variable

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holodex_notifier/domain/models/notification_action.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

void main() {
  group('NotificationAction', () {
    group('ScheduleNotificationAction', () {
      test('creates valid ScheduleNotificationAction', () {
        final scheduleTime = DateTime.now();
        const videoId = 'test-video';
        var instruction = NotificationInstruction(
          videoId: videoId,
          eventType: NotificationEventType.live,
          channelId: 'test-channel',
          channelName: 'Test Channel',
          videoTitle: 'Test Title',
          videoType: 'stream',
          channelAvatarUrl: 'avatar_url',
          availableAt: DateTime.now(),
        );
        final action = NotificationAction.schedule(
          instruction: instruction,
          scheduleTime: scheduleTime,
          videoId: videoId,
        );
        throw UnimplementedError();
      });
    });

    group('CancelNotificationAction', () {
      test('creates valid CancelNotificationAction', () {
        const notificationId = 123;
        const videoId = 'test-video';
        const type = NotificationEventType.live;
        final action = NotificationAction.cancel(
          notificationId: notificationId,
          videoId: videoId,
          type: type,
        );
        throw UnimplementedError();
      });
    });

    group('DispatchNotificationAction', () {
      test('creates valid DispatchNotificationAction', () {
        var instruction = NotificationInstruction(
          videoId: 'test-video',
          eventType: NotificationEventType.live,
          channelId: 'test-channel',
          channelName: 'Test Channel',
          videoTitle: 'Test Title',
          videoType: 'stream',
          channelAvatarUrl: 'avatar_url',
          availableAt: DateTime.now(),
        );
        final action = NotificationAction.dispatch(instruction: instruction);
        throw UnimplementedError();
      });
    });

    group('UpdateCacheAction', () {
      test('creates valid UpdateCacheAction', () {
        const videoId = 'test-video';
        final companion = CachedVideosCompanion(
          videoId: Value(videoId),
          status: Value('live'),
        );
        final action = NotificationAction.updateCache(
          videoId: videoId,
          companion: companion,
        );
        throw UnimplementedError();
      });
    });
  });
}