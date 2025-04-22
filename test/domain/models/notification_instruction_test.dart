import 'package:flutter_test/flutter_test.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';

void main() {
  group('NotificationEventType', () {
    test('has correct enum values', () {
      expect(NotificationEventType.values.length, 5);
      expect(NotificationEventType.newMedia.name, 'newMedia');
      expect(NotificationEventType.live.name, 'live');
    });
  });

  group('NotificationInstruction', () {
    test('creates valid instance with required fields', () {
      const channelId = 'test-channel';
      const channelName = 'Test Channel';
      const videoId = 'test-video';
      const videoTitle = 'Test Title';
      final availableAt = DateTime.now();

      final instruction = NotificationInstruction(
        videoId: videoId,
        eventType: NotificationEventType.live,
        channelId: channelId,
        channelName: channelName,
        videoTitle: videoTitle,
        availableAt: availableAt,
      );

      expect(instruction.videoId, videoId);
      expect(instruction.eventType, NotificationEventType.live);
      expect(instruction.channelId, channelId);
      expect(instruction.channelName, channelName);
      expect(instruction.videoTitle, videoTitle);
      expect(instruction.availableAt, availableAt);
    });

    test('allows optional fields to be null', () {
      const videoId = 'test-video';
      const channelId = 'test-channel';
      const channelName = 'Test Channel';
      const videoTitle = 'Test Title';
      final availableAt = DateTime.now();

      final instruction = NotificationInstruction(
        videoId: videoId,
        eventType: NotificationEventType.live,
        channelId: channelId,
        channelName: channelName,
        videoTitle: videoTitle,
        availableAt: availableAt,
      );

      expect(instruction.videoType, isNull);
      expect(instruction.channelAvatarUrl, isNull);
      expect(instruction.mentionedChannelNames, isNull);
    });

    test('sets optional fields when provided', () {
      const videoType = 'stream';
      const channelAvatarUrl = 'avatar_url';
      final mentionedChannels = ['channel1', 'channel2'];

      final instruction = NotificationInstruction(
        videoId: 'test-video',
        eventType: NotificationEventType.live,
        channelId: 'test-channel',
        channelName: 'Test Channel',
        videoTitle: 'Test Title',
        availableAt: DateTime.now(),
        videoType: videoType,
        channelAvatarUrl: channelAvatarUrl,
        mentionedChannelNames: mentionedChannels,
      );

      expect(instruction.videoType, videoType);
      expect(instruction.channelAvatarUrl, channelAvatarUrl);
      expect(instruction.mentionedChannelNames, mentionedChannels);
    });
  });
}