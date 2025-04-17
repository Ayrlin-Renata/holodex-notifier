// ... existing imports ...
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
// {{ REMOVE: No longer need explicit flutter_hooks import if only using useTextEditingController via HookConsumerWidget }}
// import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart'; // For NotificationEventType enum
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // {{ Import FontAwesome for icons }}
import 'package:holodex_notifier/application/state/notification_format_providers.dart'; // {{ Import new providers }}
import 'package:holodex_notifier/main.dart'; // {{ Import logger }}
import 'package:holodex_notifier/domain/models/notification_format_config.dart'; // {{ Import model }}

// TODO: Define providers for managing format editor state REMOVED - they are defined elsewhere now

class NotificationFormatPage extends HookConsumerWidget {
  const NotificationFormatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logger = ref.watch(loggingServiceProvider); // Get logger
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Get messenger

    // == Watch Providers ==
    final selectedType = ref.watch(selectedNotificationFormatTypeProvider);
    final formatConfigAsync = ref.watch(notificationFormatEditorProvider); // Watch the editable config

    // == Text Controllers ==
    final titleController = useTextEditingController();
    final bodyController = useTextEditingController();

    // == Effect to update UI when selected type or config changes ==
    useEffect(() {
      formatConfigAsync.whenData((config) {
        final format = config.formats[selectedType];
        logger.trace("[FormatPage Effect] Updating fields for type $selectedType. Format found: ${format != null}");
        if (format != null) {
          if (titleController.text != format.titleTemplate) {
            titleController.text = format.titleTemplate;
          }
          if (bodyController.text != format.bodyTemplate) {
            bodyController.text = format.bodyTemplate;
          }
          // Toggle states are read directly from the provider's value in the build method
        } else {
          // Handle case where format for selected type doesn't exist (e.g., loading error, new enum?)
           logger.warning("[FormatPage Effect] No format found for type $selectedType in config. Clearing fields.");
          titleController.clear();
          bodyController.clear();
        }
      });
      return null; // No cleanup needed
    }, [selectedType, formatConfigAsync]); // Re-run when type or config data changes

    // Function to extract the current UI state into a NotificationFormat
    NotificationFormat? getCurrentFormatFromUi() {
       final type = ref.read(selectedNotificationFormatTypeProvider); // Get current type
       // Read the current config to get the boolean values directly
       final currentFormat = ref.read(notificationFormatEditorProvider).valueOrNull?.formats[type];
       if (currentFormat == null) {
            logger.error("Cannot get current format from UI: Format not found in provider for type $type");
            return null; // Should not happen if effect works correctly
       }

       return NotificationFormat(
           titleTemplate: titleController.text,
           bodyTemplate: bodyController.text,
           showThumbnail: currentFormat.showThumbnail,
           showYoutubeLink: currentFormat.showYoutubeLink,
           showHolodexLink: currentFormat.showHolodexLink,
           showSourceLink: currentFormat.showSourceLink,
       );
    }
    // Function to update a specific bool value in the provider
     Future<void> updateBoolField(NotificationEventType type, NotificationFormat currentFormat, String fieldName, bool newValue) async {
        NotificationFormat updatedFormat;
        switch (fieldName) {
          case 'showThumbnail': updatedFormat = currentFormat.copyWith(showThumbnail: newValue); break;
          case 'showYoutubeLink': updatedFormat = currentFormat.copyWith(showYoutubeLink: newValue); break;
          case 'showHolodexLink': updatedFormat = currentFormat.copyWith(showHolodexLink: newValue); break;
          case 'showSourceLink': updatedFormat = currentFormat.copyWith(showSourceLink: newValue); break;
          default:
            logger.error("Unknown boolean field name: $fieldName");
                  return;
        }
         try {
            await ref.read(notificationFormatEditorProvider.notifier).updateFormat(type, updatedFormat);
            // Optional: Show quick feedback, but main save button is primary
            // scaffoldMessenger.showSnackBar( SnackBar(content: Text('Saved $fieldName = $newValue'), duration: Duration(milliseconds: 800)),);
            logger.debug("Successfully updated and saved bool field '$fieldName' for type $type to $newValue");
         } catch (e) {
            logger.error("Failed to update bool field '$fieldName' via notifier", e);
            scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving change: $e'), backgroundColor: theme.colorScheme.error));
            // State should revert automatically if notifier handles error
         }
    }


    return Scaffold(
      body: formatConfigAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading format config: $error', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ),
        data: (config) {
          // Get the specific format for the selected type, or a default if missing (should not happen ideally)
          final currentFormat = config.formats[selectedType] ?? NotificationFormatConfig.defaultConfig().formats[selectedType]!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Event Type Selector ---
              DropdownButtonFormField<NotificationEventType>(
                value: selectedType, // Use watched value
                items: NotificationEventType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(_getEventTypeLabel(type)));
                }).toList(),
                onChanged: (NotificationEventType? newValue) {
                  if (newValue != null) {
                    ref.read(selectedNotificationFormatTypeProvider.notifier).state = newValue;
                    logger.debug("Selected Notification Format Type changed to: $newValue");
                    // Effect hook will handle updating text fields etc.
                  }
                },
                decoration: const InputDecoration(labelText: 'Notification Type', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              // --- Title Template ---
              TextFormField(
                controller: titleController, // Use the hook controller
                decoration: InputDecoration( // {{ Use InputDecoration }}
                   labelText: 'Title Format', // {{ Use labelText }}
                   hintText: 'Enter title template...', // Use hintText as secondary
                   border: const OutlineInputBorder(),
                 ),
                maxLines: 3,
                minLines: 1,
                 // {{ Add onChanged to immediately update the provider on text change }}
                onChanged: (value) {
                  // This is potentially too frequent. Consider saving only on button press.
                   // final format = getCurrentFormatFromUi();
                   // if (format != null) {
                   //   ref.read(notificationFormatEditorProvider.notifier).updateFormat(selectedType, format.copyWith(titleTemplate: value));
                   // }
                },
              ),
              const SizedBox(height: 16),

              // --- Body Template ---
              TextFormField(
                controller: bodyController, // Use the hook controller
                decoration: InputDecoration( // {{ Use InputDecoration }}
                  labelText: 'Body Format', // {{ Use labelText }}
                  hintText: 'Enter body template...', // Use hintText as secondary
                  border: const OutlineInputBorder(),
                  helperText: 'Use { replacements } from the list below. Mak',
                 ),
                maxLines: 5,
                minLines: 2,
                // {{ Add onChanged  }}
                onChanged: (value) {
                  // Potentially too frequent saving.
                   // final format = getCurrentFormatFromUi();
                   // if (format != null) {
                   //   ref.read(notificationFormatEditorProvider.notifier).updateFormat(selectedType, format.copyWith(bodyTemplate: value));
                   // }
                },
              ),
              const SizedBox(height: 16),
          // --- Included Links Toggle Row ---
          Text('Included Links', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FilterChip(
                // {{ Read value directly from provider }}
                selected: currentFormat.showYoutubeLink,
                // (...) Avatar styling
                avatar: FaIcon(FontAwesomeIcons.youtube, size: 18, color: currentFormat.showYoutubeLink ? Colors.red : theme.disabledColor),
                 showCheckmark: false,
                label: const Text('YouTube'),
                onSelected: (selected) async {
                   // {{ Update provider state }}
                   final format = getCurrentFormatFromUi(); // Get current state first
                  if (format != null) { await updateBoolField(selectedType, format, 'showYoutubeLink', selected); }
                },
              ),
              FilterChip(
                 // {{ Read value directly from provider }}
                 selected: currentFormat.showHolodexLink,
                 // (...) Avatar styling
                  avatar: Icon(Icons.play_arrow_outlined, size: 20, color: currentFormat.showHolodexLink ? Colors.blueAccent : theme.disabledColor),
                  showCheckmark: false,
                 label: const Text('Holodex'),
                onSelected: (selected) async {
                  // {{ Update provider state }}
                  final format = getCurrentFormatFromUi();
                  if (format != null) { await updateBoolField(selectedType, format, 'showHolodexLink', selected); }
                },
              ),
               FilterChip(
                  // {{ Read value directly from provider }}
                  selected: currentFormat.showSourceLink,
                  // (...) Avatar styling
                  avatar: Icon(Icons.link_outlined, size: 20, color: currentFormat.showSourceLink ? theme.colorScheme.onSurfaceVariant : theme.disabledColor),
                 showCheckmark: false,
                label: const Text('Source'),
                 onSelected: (selected) async {
                  // {{ Update provider state }}
                    final format = getCurrentFormatFromUi();
                   if (format != null) { await updateBoolField(selectedType, format, 'showSourceLink', selected); }
                 },
               ),
            ],
          ),
          const SizedBox(height: 8), // {{ Reduce space a bit }}
          Text(
            'Note: Available links depend on the video type (e.g., "Source" is mainly for placeholders). Disabling a link type here will prevent it from showing even if available.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16), // {{ Add space before next section }}
          // --- Thumbnail Toggle ---
          SwitchListTile(
            title: const Text('Show Thumbnail Image'),
            subtitle: const Text('Display video thumbnail in the notification body (if available & format supports it).', style: TextStyle(fontSize: 12)),
            // {{ Read value directly from provider }}
            value: currentFormat.showThumbnail,
            onChanged: (value) async {
              // {{ Update provider state }}
                final format = getCurrentFormatFromUi();
               if (format != null) { await updateBoolField(selectedType, format, 'showThumbnail', value); }
            },
            secondary: const Icon(Icons.image_outlined),
            contentPadding: const EdgeInsets.only(left: 0, right: 0),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(height: 24),

          // --- Save Button ---
          ElevatedButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Format'), // Adjusted label
            onPressed: () async { // {{ Add async }}
              // {{ Implement save logic }}
              final formatToSave = getCurrentFormatFromUi();
              if (formatToSave == null) {
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Error: Could not read current format state.'), backgroundColor: Colors.red));
                return;
              }
               logger.info("Saving format for type: $selectedType");
              try {
                await ref.read(notificationFormatEditorProvider.notifier).updateFormat(selectedType, formatToSave);
                 scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Notification format saved successfully!'), duration: Duration(seconds: 2)));
              } catch (e) {
                 logger.error("Failed to save format via notifier", e);
                scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving format: $e'), backgroundColor: theme.colorScheme.error));
              }
            },
             // {{ Style to match Apply Defaults button }}
            style: ElevatedButton.styleFrom(
                // backgroundColor: theme.colorScheme.primary,
                // foregroundColor: theme.colorScheme.onPrimary,
             ),
          ),
          const SizedBox(height: 24),

          // --- Placeholder List (remains the same) ---
          ExpansionTile(
            //...
             title: Text('{ Replacements }', style: theme.textTheme.titleSmall),
              children: const [
              ListTile(title: Text('{channelName}'), subtitle: Text('Name of the channel')),
              ListTile(title: Text('{mediaTitle}'), subtitle: Text('Title of the video/stream')),
              ListTile(title: Text('{mediaTime}'), subtitle: Text('Actual/scheduled start time (e.g., 7:30 PM). Excludes date.')),
              ListTile(title: Text('{relativeTime}'), subtitle: Text('Time relative to now (e.g., "in 5 mins", "10 mins ago")')),
              ListTile(title: Text('{mediaType}'), subtitle: Text('Type (e.g., "Stream", "Clip")')),
              ListTile(title: Text('{mediaTypeCaps}'), subtitle: Text('Type in ALL CAPS (e.g., "STREAM")')),
              ListTile(title: Text('{newLine}'), subtitle: Text('Inserts a line break')),
              ListTile(title: Text('{mediaDateYMD}'), subtitle: Text('Date (YYYY-MM-DD)')),
              ListTile(title: Text('{mediaDateDMY}'), subtitle: Text('Date (DD-MM-YYYY)')),
              ListTile(title: Text('{mediaDateMDY}'), subtitle: Text('Date (MM-DD-YYYY)')),
              ListTile(title: Text('{mediaDateMD}'), subtitle: Text('Date (MM-DD)')),
              ListTile(title: Text('{mediaDateDM}'), subtitle: Text('Date (DD-MM)')),
              ListTile(title: Text('{mediaDateAsia}'), subtitle: Text('Date (YYYY年MM月DD日)')),
              /* ... list tiles ... */ ],
          ),
        ],
      );
    },
  ),
);
}

  // Helper to get user-friendly labels for enum types (remains the same)
  String _getEventTypeLabel(NotificationEventType type) {
    // ... switch statement ...
       switch (type) {
      case NotificationEventType.newMedia:
        return 'New Media';
      case NotificationEventType.live:
        return 'Live Start';
      case NotificationEventType.update:
        return 'Info Update';
      case NotificationEventType.mention:
        return 'Mention';
      case NotificationEventType.reminder:
        return 'Reminder';
      default:
        return type.name;
    }
  }
}
