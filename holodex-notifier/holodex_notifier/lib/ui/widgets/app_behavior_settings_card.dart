import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Import hooks
import 'package:hooks_riverpod/hooks_riverpod.dart'; // Import hooks_riverpod
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/main.dart';
import 'package:url_launcher/url_launcher.dart'; // For AppControllerProvider
// REMOVED: No need for SettingsCard import - no longer wrapping with it
// import 'package:holodex_notifier/ui/widgets/settings_card.dart';

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

    // REMOVED: SettingsCard(...) wrapper
    // Return a Column containing the setting widgets directly
    return Column(
      children: [
        // --- Notification Grouping ---
        SwitchListTile(
          title: const Text('Group Notifications'),
          subtitle: const Text('Combine notifications for the same video'),
          value: groupNotifications,
          onChanged: (bool value) async {
            // Use AppController to update the setting
            await appController.updateGlobalSetting('notificationGrouping', value);
          },
          secondary: const Icon(Icons.group_work_outlined),
        ),

        // --- Delay New Media ---
        SwitchListTile(
          title: const Text('Delay New Media'),
          subtitle: const Text('Wait until scheduled time for new media notifications (if possible)'),
          value: delayNewMedia,
          onChanged: (bool value) async {
            await appController.updateGlobalSetting('delayNewMedia', value);
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
            value: pollFrequency.inMinutes.toDouble().clamp(_minPollFrequencyMinutes, _maxPollFrequencyMinutes),
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
              'An API key allows this app to access more data from Holodex.\n\n'
              '1. Log in to your Google Account on holodex.net.\n'
              '2. Go to your Account page (click your avatar in the top right).\n'
              '3. Find the "API Key" section.\n'
              '4. If you don\'t have one, click "Generate".\n'
              '5. Copy the generated key and paste it here.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Go to Holodex Account'),
                onPressed: () async {
                  final url = Uri.parse('https://holodex.net/account');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Holodex Account page.')));
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
