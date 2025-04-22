// ignore_for_file: unused_local_variable

import 'package:drift/drift.dart' hide isNull;
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
        final action = ScheduleNotificationAction(
          instruction: instruction,
          scheduleTime: scheduleTime,
          videoId: videoId,
        );

        expect(action.instruction, instruction);
        expect(action.scheduleTime, scheduleTime);
        expect(action.videoId, videoId);
      });
    });

    group('CancelNotificationAction', () {
      test('creates valid CancelNotificationAction', () {
        const notificationId = 123;
        const videoId = 'test-video';
        const type = NotificationEventType.live;
        final action = CancelNotificationAction(
          notificationId: notificationId,
          videoId: videoId,
          type: type,
        );

        expect(action.notificationId, notificationId);
        expect(action.videoId, videoId);
        expect(action.type, NotificationEventType.live);
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
        final action = DispatchNotificationAction(instruction: instruction);

        expect(action.instruction, instruction);
      });
    });

    group('UpdateCacheAction', () {
      test('creates valid UpdateCacheAction', () {
        const videoId = 'test-video';
        final companion = CachedVideosCompanion(
          videoId: Value(videoId),
          status: Value('live'),
        );
        final action = UpdateCacheAction(
          videoId: videoId,
          companion: companion,
        );

        expect(action.videoId, videoId);
        expect(action.companion, companion);
      });
    });

    group('UntrackAndCleanAction', () {
      test('UntrackAndCleanAction properties', () {
        const videoId = 'testVideoIdUntrack';
        const liveId = 123;
        const reminderId = 456;

        final action = UntrackAndCleanAction(
          videoId: videoId,
          liveNotificationId: liveId,
          reminderNotificationId: reminderId,
        );

        expect(action.videoId, videoId);
        expect(action.liveNotificationId, liveId);
        expect(action.reminderNotificationId, reminderId);

        final actionNoIds = UntrackAndCleanAction(videoId: videoId);
        expect(actionNoIds.liveNotificationId, isNull);
        expect(actionNoIds.reminderNotificationId, isNull);
      });
    });
  });
}