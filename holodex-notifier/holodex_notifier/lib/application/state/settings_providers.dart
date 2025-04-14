// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\application\state\settings_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// REMOVED: No longer need to import SettingsService or main.dart here

// --- StateProviders now only return defaults ---
// The actual initial values are loaded asynchronously in main.dart and provided via overrides.

final pollFrequencyProvider = StateProvider<Duration>((ref) {
  // This logs when the provider is created *before* the override from main.dart is applied.
  print("pollFrequencyProvider initialized with DEFAULT value (Duration(minutes: 10)).");
  return const Duration(minutes: 10); // Default value
});

final notificationGroupingProvider = StateProvider<bool>((ref) {
  print("notificationGroupingProvider initialized with DEFAULT value (true).");
  return true; // Default value
});

final delayNewMediaProvider = StateProvider<bool>((ref) {
  print("delayNewMediaProvider initialized with DEFAULT value (false).");
  return false; // Default value
});

final apiKeyProvider = StateProvider<String?>((ref) {
  print("apiKeyProvider initialized with DEFAULT value (null).");
  return null; // Default value
});

// --- Global Switch defaults remain simple states ---
// These don't store persistent state, they are just UI state for the switches themselves.
final globalNewMediaDefaultProvider = StateProvider<bool>((ref) => true);
final globalMentionsDefaultProvider = StateProvider<bool>((ref) => true);
final globalLiveDefaultProvider = StateProvider<bool>((ref) => true);
final globalUpdateDefaultProvider = StateProvider<bool>((ref) => true);