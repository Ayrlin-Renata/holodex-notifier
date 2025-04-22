import 'package:flutter_test/flutter_test.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';

void main() {
  group('NotificationFormat', () {
    test('creates with default values', () {
      const format = NotificationFormat(
        titleTemplate: 'Test Title',
        bodyTemplate: 'Test Body',
      );
      expect(format.titleTemplate, 'Test Title');
      expect(format.bodyTemplate, 'Test Body');
      expect(format.showThumbnail, isTrue);
      expect(format.showYoutubeLink, isTrue);
      expect(format.showHolodexLink, isTrue);
      expect(format.showSourceLink, isTrue);
    });

    test('fromJson creates valid NotificationFormat', () {
      final json = {
        'titleTemplate': 'Test Title',
        'bodyTemplate': 'Test Body',
        'showThumbnail': false,
        'showYoutubeLink': false,
        'showHolodexLink': false,
        'showSourceLink': false,
      };
      final format = NotificationFormat.fromJson(json);
      expect(format.titleTemplate, 'Test Title');
      expect(format.bodyTemplate, 'Test Body');
      expect(format.showThumbnail, isFalse);
    });
  });

  group('NotificationFormatConfig', () {
    test('defaultConfig creates config with all event types', () {
      final config = NotificationFormatConfig.defaultConfig();
      expect(config.formats.length, NotificationEventType.values.length);
      expect(config.formats[NotificationEventType.live]?.titleTemplate, contains('LIVE'));
    });
  });
}