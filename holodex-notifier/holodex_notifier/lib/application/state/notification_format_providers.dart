import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart';
import 'package:holodex_notifier/main.dart';

final selectedNotificationFormatTypeProvider = StateProvider<NotificationEventType>(
  (ref) => NotificationEventType.live,
  name: 'selectedNotificationFormatTypeProvider',
);

class NotificationFormatEditorNotifier extends StateNotifier<AsyncValue<NotificationFormatConfig>> {
  final ISettingsService _settingsService;
  final Ref _ref;

  NotificationFormatEditorNotifier(this._settingsService, this._ref) : super(const AsyncValue.loading()) {
    _loadInitialConfig();
  }

  Future<void> _loadInitialConfig() async {
    state = const AsyncValue.loading();
    try {
      final config = await _settingsService.getNotificationFormatConfig();
      state = AsyncValue.data(config);
    } catch (e, s) {
      _ref.read(loggingServiceProvider).error("Failed to load initial NotificationFormatConfig for editor", e, s);
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateFormat(NotificationEventType type, NotificationFormat newFormat) async {
    final currentConfig = state.valueOrNull;
    if (currentConfig == null) return;

    _ref.read(loggingServiceProvider).debug("Updating format for type $type: $newFormat");

    final newFormats = Map<NotificationEventType, NotificationFormat>.from(currentConfig.formats);
    newFormats[type] = newFormat;

    final updatedConfig = currentConfig.copyWith(formats: newFormats);

    state = AsyncValue.data(updatedConfig);

    try {
      await _settingsService.setNotificationFormatConfig(updatedConfig);
      _ref.read(loggingServiceProvider).info("Successfully saved updated NotificationFormatConfig.");
      _ref.invalidate(notificationFormatConfigProvider);

      _ref.read(backgroundServiceProvider).notifySettingChanged('notificationFormat', null);
    } catch (e, s) {
      _ref.read(loggingServiceProvider).error("Failed to save updated NotificationFormatConfig", e, s);
      state = AsyncValue.error(e, s).copyWithPrevious(state) as AsyncValue<NotificationFormatConfig>;
      rethrow;
    }
  }
}

final notificationFormatEditorProvider = StateNotifierProvider.autoDispose<NotificationFormatEditorNotifier, AsyncValue<NotificationFormatConfig>>((
  ref,
) {
  final settingsService = ref.watch(settingsServiceProvider);
  return NotificationFormatEditorNotifier(settingsService, ref);
}, name: 'notificationFormatEditorProvider');
