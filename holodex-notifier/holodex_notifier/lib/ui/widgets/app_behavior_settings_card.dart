import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Import hooks
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import hooks_riverpod
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/main.dart';
import 'package:url_launcher/url_launcher.dart'; // For AppControllerProvider

// Helper to format Duration
String _formatDuration(Duration d) {
  if (d.inMinutes < 1) {
    return "< 1 min"; // Handle very short durations if needed
  }
  if (d.inMinutes < 60) {
    return "${d.inMinutes} min";
  } else {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (minutes == 0) {
      return "$hours hr";
    } else {
      // Only show minutes if they exist
      return "$hours hr ${minutes} min";
    }
  }
}

// Define minimum and maximum poll frequencies in minutes
const double _minPollFrequencyMinutes = 5.0;
const double _maxPollFrequencyMinutes = 720.0; // 12 hours
// {{ Power for logarithmic-like scaling (e.g., 2 = quadratic, higher = more compressed lower end) }}
const double _sliderExponent = 2.0;

double _durationToSliderValue(Duration duration) {
  final minutes = duration.inMinutes.toDouble().clamp(_minPollFrequencyMinutes, _maxPollFrequencyMinutes);
  if (minutes <= _minPollFrequencyMinutes) return 0.0;
  if (minutes >= _maxPollFrequencyMinutes) return 1.0;

  final normalized = (minutes - _minPollFrequencyMinutes) / (_maxPollFrequencyMinutes - _minPollFrequencyMinutes);
  // Apply inverse of the power function
  return pow(normalized, 1.0 / _sliderExponent).toDouble();
}

Duration _sliderValueToDuration(double sliderValue) {
  final clampedValue = sliderValue.clamp(0.0, 1.0);
  // Apply power function
  final scaledValue = pow(clampedValue, _sliderExponent);
  final minutes = _minPollFrequencyMinutes + (_maxPollFrequencyMinutes - _minPollFrequencyMinutes) * scaledValue;
  // Round to nearest minute
  return Duration(minutes: minutes.round());
}

const double _minReminderLeadMinutes = 0.0; // 0 means disabled
const double _maxReminderLeadMinutes = 1440.0; // 24 hours
const double _reminderSliderExponent = 2.5; // Less aggressive curve than poll freq

String _formatReminderDuration(Duration d) {
  if (d.inMinutes <= 0) {
    return "Disabled";
  }
  if (d.inMinutes < 60) {
    return "${d.inMinutes} min before";
  } else {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (minutes == 0) {
      return "$hours hr before";
    } else {
      return "$hours hr ${minutes} min before";
    }
  }
}

double _reminderDurationToSliderValue(Duration duration) {
  final minutes = duration.inMinutes.toDouble().clamp(_minReminderLeadMinutes, _maxReminderLeadMinutes);
  if (minutes <= _minReminderLeadMinutes) return 0.0;
  if (minutes >= _maxReminderLeadMinutes) return 1.0;

  final range = _maxReminderLeadMinutes - _minReminderLeadMinutes;
  if (range == 0) return 0.0; // Avoid division by zero if min == max

  final normalized = (minutes - _minReminderLeadMinutes) / range;
  return pow(normalized, 1.0 / _reminderSliderExponent).toDouble();
}

Duration _reminderSliderValueToDuration(double sliderValue) {
  final clampedValue = sliderValue.clamp(0.0, 1.0);
  final scaledValue = pow(clampedValue, _reminderSliderExponent);
  final totalMinutes = _minReminderLeadMinutes + (_maxReminderLeadMinutes - _minReminderLeadMinutes) * scaledValue;
  // Round to sensible steps (e.g., nearest 5 minutes? Or 1 min?)
  final roundedMinutes = (totalMinutes / 5).round() * 5; // Round to nearest 5 minutes
  // Ensure 0 remains 0 after rounding
  return Duration(minutes: max(0, roundedMinutes)); // Ensure non-negative
}

// Change to HookConsumerWidget to use hooks
class AppBehaviorSettingsCard extends HookConsumerWidget {
  const AppBehaviorSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers for current values
    final groupNotifications = ref.watch(notificationGroupingProvider);
    final delayNewMedia = ref.watch(delayNewMediaProvider);
    final pollFrequency = ref.watch(pollFrequencyProvider);
    final reminderLeadTime = ref.watch(reminderLeadTimeProvider);
    final apiKeyAsyncValue = ref.watch(apiKeyProvider); // WATCH the key state (now AsyncValue)
    final logger = ref.watch(loggingServiceProvider);

    // Local state Hooks for API key visibility and editing
    final isApiKeyVisible = useState(false);
    final apiKeyTextController = useTextEditingController(text: apiKeyAsyncValue.valueOrNull ?? ''); // Initialize with current key if exists
    final isEditingApiKey = useState(false); // Track editing state

    final String? apiKey = apiKeyAsyncValue.valueOrNull; // Get value safely
    final bool apiKeyIsLoading = apiKeyAsyncValue.isLoading;
    final Object? apiKeyError = apiKeyAsyncValue.error;
    logger.debug(
      "[AppBehaviorSettingsCard] Build - API Key AsyncValue: isLoading=$apiKeyIsLoading, hasError=${apiKeyError != null}, value='$apiKey'",
    );

    final theme = Theme.of(context); // Get theme

    // Get AppController for persisting changes
    final appController = ref.watch(appControllerProvider);

    // Update text field if API key provider changes (e.g., loaded after init)
    useEffect(() {
      if (!apiKeyIsLoading && apiKeyError == null && apiKeyTextController.text != (apiKey ?? '')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          apiKeyTextController.text = apiKey ?? '';
        });
      }
      return null; // No cleanup needed
    }, [apiKey, apiKeyIsLoading, apiKeyError]);

    // Calculate the current slider value based on the duration
    final currentPollSliderValue = _durationToSliderValue(pollFrequency);
    final currentReminderSliderValue = _reminderDurationToSliderValue(reminderLeadTime); // {{ Calc reminder slider value }}

    return Column(
      children: [
        // --- Notification Grouping ---
        SwitchListTile(
          title: const Text('Group Notifications'),
          subtitle: const Text('Combine notifications for the same video'),
          value: groupNotifications,
          onChanged: (bool value) {
            // Use AppController to update the setting
            logger.info("[AppBehaviorSettingsCard] Grouping onChanged triggered with value: $value");
            ref.read(notificationGroupingProvider.notifier).update((_) => value);
            appController.updateGlobalSetting('notificationGrouping', value);
          },
          secondary: const Icon(Icons.group_work_outlined),
        ),

        // --- Delay New Media ---
        SwitchListTile(
          title: const Text('Delay New Media'),
          subtitle: const Text('Wait until scheduled time for new media notifications (if possible)'),
          value: delayNewMedia,
          onChanged: (bool value) {
            logger.info("[AppBehaviorSettingsCard] Delay onChanged triggered with value: $value");
            ref.read(delayNewMediaProvider.notifier).update((_) => value);
            appController.updateGlobalSetting('delayNewMedia', value);
          },
          secondary: const Icon(Icons.schedule_outlined),
        ),

        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Live Stream Reminder'),
          subtitle: Text('Notify ${_formatReminderDuration(reminderLeadTime)} ${reminderLeadTime.compareTo(Duration.zero) == 0 ? '' : 'start time'}'),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: currentReminderSliderValue,
            min: 0.0,
            max: 1.0,
            divisions: 100, // Adjust divisions as needed
            label: _formatReminderDuration(_reminderSliderValueToDuration(currentReminderSliderValue)),
            onChanged: (double value) {
              final newDuration = _reminderSliderValueToDuration(value);
              ref.read(reminderLeadTimeProvider.notifier).state = newDuration;
            },
            onChangeEnd: (double value) async {
              final newDuration = _reminderSliderValueToDuration(value);
              ref.read(reminderLeadTimeProvider.notifier).state = newDuration; // Ensure final state
              logger.info("Reminder Lead Time Slider onChangeEnd: Duration = $newDuration");
              await appController.updateGlobalSetting('reminderLeadTime', newDuration);
            },
          ),
        ),
        const SizedBox(height: 8), // Spacing
        // --- Poll Frequency ---
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Poll Frequency'),
          subtitle: Text('Current: ${_formatDuration(pollFrequency)}'), // Display the actual duration
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            // {{ Use the calculated slider value }}
            value: currentPollSliderValue,
            min: 0.0, // Slider range is always 0.0 to 1.0
            max: 1.0,
            // {{ Divisions on the 0-1 scale. Adjust for desired granularity }}
            // E.g., 100 divisions provides fine control, but labels might overlap
            divisions: 100,
            // {{ Label shows the *Duration* derived from the current slider position }}
            label: _formatDuration(_sliderValueToDuration(currentPollSliderValue)),
            onChanged: (double value) {
              // {{ Convert slider value back to Duration and update provider }}
              final newDuration = _sliderValueToDuration(value);
              ref.read(pollFrequencyProvider.notifier).state = newDuration;
            },
            // Persist value when user stops dragging
            onChangeEnd: (double value) async {
              // {{ Convert final slider value to Duration }}
              final newDuration = _sliderValueToDuration(value);
              // Ensure final provider state is accurate (might be slightly different due to rounding)
              ref.read(pollFrequencyProvider.notifier).state = newDuration;
              logger.info("Poll Frequency Slider onChangeEnd: Duration = $newDuration");
              // Use AppController to update setting and notify background
              await appController.updateGlobalSetting('pollFrequency', newDuration);
            },
          ),
        ),
        const SizedBox(height: 8), // Spacing
        // --- API Key ---
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: const Text('Holodex API Key'),
          subtitle:
              isEditingApiKey.value
                  ? TextField(
                    controller: apiKeyTextController,
                    obscureText: !isApiKeyVisible.value,
                    decoration: InputDecoration(
                      hintText: 'Enter your Holodex API Key',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(isApiKeyVisible.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => isApiKeyVisible.value = !isApiKeyVisible.value,
                      ),
                    ),
                  )
                  : Text(
                    apiKey == null || apiKey.isEmpty
                        ? 'Not Set'
                        : (isApiKeyVisible.value
                            ? apiKey
                            : '******${apiKey.length > 4 ? apiKey.substring(apiKey.length - 4) : ''}'), // Show last 4 chars or full if visible/short
                    style: TextStyle(
                      color:
                          apiKey == null || apiKey.isEmpty
                              ? Theme.of(context)
                                  .disabledColor // Use theme disabled color
                              : null,
                      fontFamily: isApiKeyVisible.value ? null : 'monospace', // Hint at obscured content
                    ),
                  ),
          trailing:
              isEditingApiKey.value
                  ? IconButton(
                    icon: const Icon(Icons.save_outlined),
                    tooltip: 'Save API Key',
                    // Disable save button while notifier is saving (optional but good UX)
                    // onPressed: apiKeyAsyncValue.isLoading ? null : () async { ... }, // Need to track notifier's internal state for this
                    onPressed: () async {
                      final newKeyValue = apiKeyTextController.text.trim();
                      logger.debug("[AppBehaviorSettingsCard] Save Button Pressed. Trimmed value from TextField: '$newKeyValue'");
                      try {
                        // Use AppController to call notifier method
                        await appController.updateGlobalSetting('apiKey', newKeyValue);

                        isEditingApiKey.value = false;
                        isApiKeyVisible.value = false;
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key saved'), duration: Duration(seconds: 2)));
                      } catch (e) {
                        // Error is likely already handled/logged by the notifier, but show feedback anyway
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save API Key: ${e.toString().split('\n').first}'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    },
                  )
                  : Row(
                    // Edit/Show Buttons - Disable Edit if loading/error
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!apiKeyIsLoading && apiKeyError == null && apiKey != null && apiKey.isNotEmpty)
                        IconButton(
                          icon: Icon(isApiKeyVisible.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          tooltip: isApiKeyVisible.value ? 'Hide Key' : 'Show Key',
                          onPressed: () => isApiKeyVisible.value = !isApiKeyVisible.value,
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit API Key',
                        // Disable Edit button if loading/error
                        onPressed:
                            apiKeyIsLoading || apiKeyError != null
                                ? null
                                : () {
                                  isApiKeyVisible.value = true;
                                  isEditingApiKey.value = true;
                                },
                      ),
                    ],
                  ),
        ),
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
          title: Text('How to get an API Key?', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: <Widget>[
            Text(
              'An API key allows this app to access data from Holodex.\n\n'
              '1. Log in to your account on holodex.net.\n'
              '2. Go to your Account Settings page (click your avatar in the top right).\n'
              '3. Find the "API Key" section.\n'
              '4. If you don\'t have one, click "GET NEW API KEY".\n'
              '5. Copy the generated key and paste it here.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Go to Holodex Account Settings'),
                onPressed: () async {
                  final url = Uri.parse('https://holodex.net/login');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Holodex Account Settings page.')));
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
