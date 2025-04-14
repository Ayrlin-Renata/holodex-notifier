import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Import hooks
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import hooks_riverpod
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/main.dart'; // For settingsServiceProvider
import 'package:holodex_notifier/ui/widgets/settings_card.dart';

// Helper to format Duration
String _formatDuration(Duration d) {
  if (d.inMinutes < 60) {
    return "${d.inMinutes} min";
  } else {
    return "${d.inHours} hr";
  }
}

// Define minimum and maximum poll frequencies in minutes
const double _minPollFrequencyMinutes = 5.0;
const double _maxPollFrequencyMinutes = 720.0; // 12 hours

// Change to HookConsumerWidget to use hooks
class AppBehaviorSettingsCard extends HookConsumerWidget {
  const AppBehaviorSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers for current values
    final groupNotifications = ref.watch(notificationGroupingProvider);
    final delayNewMedia = ref.watch(delayNewMediaProvider);
    final pollFrequency = ref.watch(pollFrequencyProvider);
    final apiKey = ref.watch(apiKeyProvider); // Watch the key state

    // Local state Hooks for API key visibility and editing
    final isApiKeyVisible = useState(false);
    final apiKeyTextController = useTextEditingController(text: apiKey ?? ''); // Initialize with current key if exists
    final isEditingApiKey = useState(false); // Track editing state

    // Access SettingsService for persistence
    final settingsService = ref.watch(settingsServiceProvider);

    // Update text field if API key provider changes (e.g., loaded after init)
    useEffect(() {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if(apiKeyTextController.text != (apiKey ?? '')) {
            apiKeyTextController.text = apiKey ?? '';
         }
       });
      return null;
    }, [apiKey]);


    return SettingsCard(
      title: 'App Behavior',
      children: [
        // --- Notification Grouping ---
        SwitchListTile(
          title: const Text('Group Notifications'),
          subtitle: const Text('Combine notifications for the same video'),
          value: groupNotifications,
          onChanged: (bool value) async {
            // Update Riverpod state first for immediate UI feedback
            ref.read(notificationGroupingProvider.notifier).state = value;
            // Persist change via SettingsService
            await settingsService.setNotificationGrouping(value);
          },
          secondary: const Icon(Icons.group_work_outlined),
        ),

        // --- Delay New Media ---
        SwitchListTile(
          title: const Text('Delay New Media'),
          subtitle: const Text(
            'Wait until scheduled time for new media notifications (if possible)',
          ),
          value: delayNewMedia,
          onChanged: (bool value) async {
            ref.read(delayNewMediaProvider.notifier).state = value;
            await settingsService.setDelayNewMedia(value);
          },
          secondary: const Icon(Icons.schedule_outlined),
        ),

        // --- Poll Frequency ---
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Poll Frequency'),
          subtitle: Text('Current: ${_formatDuration(pollFrequency)}'),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: pollFrequency.inMinutes.toDouble().clamp(
                  _minPollFrequencyMinutes,
                  _maxPollFrequencyMinutes,
                ),
            min: _minPollFrequencyMinutes,
            max: _maxPollFrequencyMinutes,
            divisions: (_maxPollFrequencyMinutes - _minPollFrequencyMinutes) ~/ 5, // Divisions every 5 minutes
            label: _formatDuration(Duration(minutes: pollFrequency.inMinutes)), // Display label on drag
            onChanged: (double value) {
              // Update provider state during drag for immediate feedback
              ref.read(pollFrequencyProvider.notifier).state = Duration(minutes: value.round());
            },
            // Persist value when user stops dragging
            onChangeEnd: (double value) async {
               final newDuration = Duration(minutes: value.round());
               // Ensure final provider state is accurate
               ref.read(pollFrequencyProvider.notifier).state = newDuration;
              await settingsService.setPollFrequency(newDuration);
               // TODO: Notify background service to update timer interval if needed
            },
          ),
        ),
        const SizedBox(height: 8), // Spacing

        // --- API Key ---
        ListTile(
           leading: const Icon(Icons.key_outlined),
           title: const Text('Holodex API Key'),
           subtitle: isEditingApiKey.value
              ? TextField(
                  controller: apiKeyTextController,
                  obscureText: !isApiKeyVisible.value,
                  decoration: InputDecoration(
                    hintText: 'Enter your Holodex API Key',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        isApiKeyVisible.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                       onPressed: () => isApiKeyVisible.value = !isApiKeyVisible.value,
                    ),
                  ),
                )
              : Text(
                  apiKey == null || apiKey.isEmpty
                     ? 'Not Set'
                     : (isApiKeyVisible.value ? apiKey : '******${apiKey.substring(apiKey.length-4)}'), // Show last 4 chars or full if visible
                  style: TextStyle(
                     color: apiKey == null || apiKey.isEmpty
                         ? Colors.grey
                         : null,
                     fontFamily: isApiKeyVisible.value ? null : 'monospace', // Hint at obscured content
                  ),
                ),
          trailing: isEditingApiKey.value
              ? IconButton( // Save Button
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Save API Key',
                  onPressed: () async {
                    final newKeyValue = apiKeyTextController.text.trim();
                     try {
                       // Update secure storage via settings service
                       await settingsService.setApiKey(newKeyValue.isEmpty ? null : newKeyValue);
                       // Update the Riverpod state
                       ref.read(apiKeyProvider.notifier).state = newKeyValue.isEmpty ? null: newKeyValue;
                       // Exit editing mode
                       isEditingApiKey.value = false;
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('API Key saved'), duration: Duration(seconds: 2)),
                       );
                     } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Failed to save API Key: $e'), backgroundColor: Colors.red),
                         );
                     }
                  },
                )
               : Row( // Edit/Show Buttons
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     if(apiKey != null && apiKey.isNotEmpty)
                       IconButton(
                         icon: Icon(isApiKeyVisible.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                         tooltip: isApiKeyVisible.value ? 'Hide Key' : 'Show Key',
                         onPressed: () => isApiKeyVisible.value = !isApiKeyVisible.value,
                      ),
                     IconButton(
                       icon: const Icon(Icons.edit_outlined),
                       tooltip: 'Edit API Key',
                       onPressed: () {
                         isApiKeyVisible.value = true; // Show key when editing starts
                         isEditingApiKey.value = true;
                       },
                     ),
                  ],
               ),
        ),
      ],
    );
  }
}