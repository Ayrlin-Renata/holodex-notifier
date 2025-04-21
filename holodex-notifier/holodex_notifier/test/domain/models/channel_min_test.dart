import 'package:flutter_test/flutter_test.dart';
import 'package:holodex_notifier/domain/models/channel_min.dart';

void main() {
  group('ChannelMin', () {
    test('fromJson creates ChannelMin with correct values', () {
      final json = {
        'id': 'UCdn5BQ06XqgXo9lLPejJObw',
        'name': 'Sakura Miko',
        'english_name': 'Sakura Miko',
        'type': 'vtuber',
        'org': 'Hololive',
      };

      final channelMin = ChannelMin.fromJson(json);

      expect(channelMin.id, 'UCdn5BQ06XqgXo9lLPejJObw');
      expect(channelMin.name, 'Sakura Miko');
      expect(channelMin.englishName, 'Sakura Miko');
      expect(channelMin.type, 'vtuber');
    });

    test('toJson returns correct JSON representation', () {
      final channelMin = ChannelMin(
        id: 'UCdn5BQ06XqgXo9lLPejJObw',
        name: 'Sakura Miko',
        englishName: 'Sakura Miko',
        type: 'vtuber',
      );

      final json = channelMin.toJson();

      expect(json['id'], 'UCdn5BQ06XqgXo9lLPejJObw');
      expect(json['name'], 'Sakura Miko');
      expect(json['english_name'], 'Sakura Miko');
      expect(json['type'], 'vtuber');
      expect(json['org'], 'Hololive');
    });
  });
}