import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/domain/interfaces/settings_service.dart'; // Import SettingsService
// {{ Add import for IBackgroundPollingService }}
import 'package:holodex_notifier/main.dart'; // For settingsServiceProvider etc.

/// Provider to hold the currently selected NotificationEventType in the editor UI.
// {{ Remove .autoDispose to persist state across page navigations }}
final selectedNotificationFormatTypeProvider = StateProvider<NotificationEventType>(
  (ref) => NotificationEventType.live, // Default selection
  name: 'selectedNotificationFormatTypeProvider',
);

/// State Notifier for managing the NotificationFormatConfig during editing.
class NotificationFormatEditorNotifier extends StateNotifier<AsyncValue<NotificationFormatConfig>> {
  final ISettingsService _settingsService;
  final Ref _ref;

  NotificationFormatEditorNotifier(this._settingsService, this._ref) : super(const AsyncValue.loading()) {
    _loadInitialConfig();
  }

  // Load initial config from settings
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

  // Update the format for a specific event type
  Future<void> updateFormat(NotificationEventType type, NotificationFormat newFormat) async {
    // Ensure we have data before proceeding
    final currentConfig = state.valueOrNull;
    if (currentConfig == null) return; // Cannot update if not loaded

    _ref.read(loggingServiceProvider).debug("Updating format for type $type: $newFormat");

    // Create a new map with the updated format
    final newFormats = Map<NotificationEventType, NotificationFormat>.from(currentConfig.formats);
    newFormats[type] = newFormat;

    // Create the new config state
    final updatedConfig = currentConfig.copyWith(formats: newFormats);

    // Update the state optimistically
    state = AsyncValue.data(updatedConfig);

    // Persist the change using SettingsService
    try {
      await _settingsService.setNotificationFormatConfig(updatedConfig);
      _ref.read(loggingServiceProvider).info("Successfully saved updated NotificationFormatConfig.");
      // Invalidate the global provider so other parts of the app pick it up
      _ref.invalidate(notificationFormatConfigProvider);

      // ****** {{ Add this line back }} ******
      _ref.read(backgroundServiceProvider).notifySettingChanged('notificationFormat', null);
      // ****** END CHANGE ******

    } catch (e, s) {
       _ref.read(loggingServiceProvider).error("Failed to save updated NotificationFormatConfig", e, s);
       // Revert state on failure? Or show error? For now, log and keep optimistic update.
       // state = AsyncValue.data(currentConfig); // Example: revert state
       state = AsyncValue.error(e, s).copyWithPrevious(state) as AsyncValue<NotificationFormatConfig>; // Show error but keep previous data
       rethrow; // Rethrow to allow UI to catch and display error
    }
  }
}

/// Provider for the NotificationFormatEditorNotifier.
final notificationFormatEditorProvider = StateNotifierProvider.autoDispose<NotificationFormatEditorNotifier, AsyncValue<NotificationFormatConfig>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return NotificationFormatEditorNotifier(settingsService, ref);
}, name: 'notificationFormatEditorProvider');