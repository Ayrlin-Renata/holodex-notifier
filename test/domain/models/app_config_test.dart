import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:holodex_notifier/domain/models/app_config.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';

void main() {
  group('AppConfig Serialization', () {
    test('fromJson should correctly deserialize JSON', () {
      final jsonMap = {
        "version": 1,
        "pollFrequencyMinutes": 15,
        "notificationGrouping": true,
        "delayNewMedia": false,
        "reminderLeadTimeMinutes": 5,
        "channelSubscriptions": [
          {
            "channelId": "UC123",
            "name": "Test Channel 1",
            "avatarUrl": "url1",
            "notifyNewMedia": true,
            "notifyMentions": true,
            "notifyLive": true,
            "notifyUpdates": true,
            "notifyMembersOnly": false,
            "notifyClips": false
          },
          {
            "channelId": "UC456",
            "name": "Test Channel 2",
            "avatarUrl": "url2",
            "notifyNewMedia": false,
            "notifyMentions": false,
            "notifyLive": true,
            "notifyUpdates": false,
            "notifyMembersOnly": true,
            "notifyClips": true
          }
        ]
      };

      final appConfig = AppConfig.fromJson(jsonMap);

      expect(appConfig.version, 1);
      expect(appConfig.pollFrequencyMinutes, 15);
      expect(appConfig.notificationGrouping, isTrue);
      expect(appConfig.delayNewMedia, isFalse);
      expect(appConfig.reminderLeadTimeMinutes, 5);
      expect(appConfig.channelSubscriptions, hasLength(2));
      expect(appConfig.channelSubscriptions[0].channelId, 'UC123');
      expect(appConfig.channelSubscriptions[0].name, 'Test Channel 1');
      expect(appConfig.channelSubscriptions[0].notifyMembersOnly, isFalse);
      expect(appConfig.channelSubscriptions[1].channelId, 'UC456');
      expect(appConfig.channelSubscriptions[1].name, 'Test Channel 2');
      expect(appConfig.channelSubscriptions[1].notifyNewMedia, isFalse);
    });

    test('toJson should correctly serialize the object', () {
      const channel1 = ChannelSubscriptionSetting(channelId: 'UC1', name: 'Chan 1');
      const channel2 = ChannelSubscriptionSetting(
        channelId: 'UC2',
        name: 'Chan 2',
        notifyLive: false,
        notifyMembersOnly: true,
      );
      const appConfig = AppConfig(
        version: 2,
        pollFrequencyMinutes: 30,
        notificationGrouping: false,
        delayNewMedia: true,
        reminderLeadTimeMinutes: 10,
        channelSubscriptions: [channel1, channel2],
      );

      final jsonMap = appConfig.toJson();
      final jsonString = jsonEncode(jsonMap);
      final expectedJsonString = jsonEncode({
        "pollFrequencyMinutes": 30,
        "notificationGrouping": false,
        "delayNewMedia": true,
        "reminderLeadTimeMinutes": 10,
        "channelSubscriptions": [
          {
            "channelId": "UC1",
            "name": "Chan 1",
            "avatarUrl": null,
            "notifyNewMedia": true,
            "notifyMentions": true,
            "notifyLive": true,
            "notifyUpdates": true,
            "notifyMembersOnly": true,
            "notifyClips": true
          },
          {
            "channelId": "UC2",
            "name": "Chan 2",
            "avatarUrl": null,
            "notifyNewMedia": true,
            "notifyMentions": true,
            "notifyLive": false,
            "notifyUpdates": true,
            "notifyMembersOnly": true,
            "notifyClips": true
          }
        ],
        "version": 2
      });

      expect(jsonString, expectedJsonString);
    });
  });
}
