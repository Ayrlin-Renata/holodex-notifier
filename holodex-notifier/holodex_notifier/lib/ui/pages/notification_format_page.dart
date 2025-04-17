// ignore_for_file: unreachable_switch_default

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:holodex_notifier/application/state/notification_format_providers.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';

class NotificationFormatPage extends HookConsumerWidget {
  const NotificationFormatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logger = ref.watch(loggingServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final selectedType = ref.watch(selectedNotificationFormatTypeProvider);
    final formatConfigAsync = ref.watch(notificationFormatEditorProvider);

    final titleController = useTextEditingController();
    final bodyController = useTextEditingController();

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
        } else {
          logger.warning("[FormatPage Effect] No format found for type $selectedType in config. Clearing fields.");
          titleController.clear();
          bodyController.clear();
        }
      });
      return null;
    }, [selectedType, formatConfigAsync]);

    NotificationFormat? getCurrentFormatFromUi() {
      final type = ref.read(selectedNotificationFormatTypeProvider);
      final currentFormat = ref.read(notificationFormatEditorProvider).valueOrNull?.formats[type];
      if (currentFormat == null) {
        logger.error("Cannot get current format from UI: Format not found in provider for type $type");
        return null;
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

    Future<void> updateBoolField(NotificationEventType type, NotificationFormat currentFormat, String fieldName, bool newValue) async {
      NotificationFormat updatedFormat;
      switch (fieldName) {
        case 'showThumbnail':
          updatedFormat = currentFormat.copyWith(showThumbnail: newValue);
          break;
        case 'showYoutubeLink':
          updatedFormat = currentFormat.copyWith(showYoutubeLink: newValue);
          break;
        case 'showHolodexLink':
          updatedFormat = currentFormat.copyWith(showHolodexLink: newValue);
          break;
        case 'showSourceLink':
          updatedFormat = currentFormat.copyWith(showSourceLink: newValue);
          break;
        default:
          logger.error("Unknown boolean field name: $fieldName");
          return;
      }
      try {
        await ref.read(notificationFormatEditorProvider.notifier).updateFormat(type, updatedFormat);
        logger.debug("Successfully updated and saved bool field '$fieldName' for type $type to $newValue");
      } catch (e) {
        logger.error("Failed to update bool field '$fieldName' via notifier", e);
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving change: $e'), backgroundColor: theme.colorScheme.error));
      }
    }

    return Scaffold(
      body: formatConfigAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading format config: $error', style: TextStyle(color: theme.colorScheme.error)),
              ),
            ),
        data: (config) {
          final currentFormat = config.formats[selectedType] ?? NotificationFormatConfig.defaultConfig().formats[selectedType]!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              DropdownButtonFormField<NotificationEventType>(
                value: selectedType,
                items:
                    NotificationEventType.values.map((type) {
                      return DropdownMenuItem(value: type, child: Text(_getEventTypeLabel(type)));
                    }).toList(),
                onChanged: (NotificationEventType? newValue) {
                  if (newValue != null) {
                    ref.read(selectedNotificationFormatTypeProvider.notifier).state = newValue;
                    logger.debug("Selected Notification Format Type changed to: $newValue");
                  }
                },
                decoration: const InputDecoration(labelText: 'Notification Type', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title Format', hintText: 'Enter title template...', border: const OutlineInputBorder()),
                maxLines: 3,
                minLines: 1,
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: bodyController,
                decoration: InputDecoration(
                  labelText: 'Body Format',
                  hintText: 'Enter body template...',
                  border: const OutlineInputBorder(),
                  helperText: 'Use { replacements } from the list below. Mak',
                ),
                maxLines: 5,
                minLines: 2,
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              Text('Included Links', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FilterChip(
                    selected: currentFormat.showYoutubeLink,
                    avatar: FaIcon(FontAwesomeIcons.youtube, size: 18, color: currentFormat.showYoutubeLink ? Colors.red : theme.disabledColor),
                    showCheckmark: false,
                    label: const Text('YouTube'),
                    onSelected: (selected) async {
                      final format = getCurrentFormatFromUi();
                      if (format != null) {
                        await updateBoolField(selectedType, format, 'showYoutubeLink', selected);
                      }
                    },
                  ),
                  FilterChip(
                    selected: currentFormat.showHolodexLink,
                    avatar: Icon(Icons.play_arrow_outlined, size: 20, color: currentFormat.showHolodexLink ? Colors.blueAccent : theme.disabledColor),
                    showCheckmark: false,
                    label: const Text('Holodex'),
                    onSelected: (selected) async {
                      final format = getCurrentFormatFromUi();
                      if (format != null) {
                        await updateBoolField(selectedType, format, 'showHolodexLink', selected);
                      }
                    },
                  ),
                  FilterChip(
                    selected: currentFormat.showSourceLink,
                    avatar: Icon(
                      Icons.link_outlined,
                      size: 20,
                      color: currentFormat.showSourceLink ? theme.colorScheme.onSurfaceVariant : theme.disabledColor,
                    ),
                    showCheckmark: false,
                    label: const Text('Source'),
                    onSelected: (selected) async {
                      final format = getCurrentFormatFromUi();
                      if (format != null) {
                        await updateBoolField(selectedType, format, 'showSourceLink', selected);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Available links depend on the video type (e.g., "Source" is mainly for placeholders). Disabling a link type here will prevent it from showing even if available.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Show Thumbnail Image'),
                subtitle: const Text(
                  'Display video thumbnail in the notification body (if available & format supports it).',
                  style: TextStyle(fontSize: 12),
                ),
                value: currentFormat.showThumbnail,
                onChanged: (value) async {
                  final format = getCurrentFormatFromUi();
                  if (format != null) {
                    await updateBoolField(selectedType, format, 'showThumbnail', value);
                  }
                },
                secondary: const Icon(Icons.image_outlined),
                contentPadding: const EdgeInsets.only(left: 0, right: 0),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Format'),
                onPressed: () async {
                  final formatToSave = getCurrentFormatFromUi();
                  if (formatToSave == null) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Error: Could not read current format state.'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  logger.info("Saving format for type: $selectedType");
                  try {
                    await ref.read(notificationFormatEditorProvider.notifier).updateFormat(selectedType, formatToSave);
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Notification format saved successfully!'), duration: Duration(seconds: 2)),
                    );
                  } catch (e) {
                    logger.error("Failed to save format via notifier", e);
                    scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving format: $e'), backgroundColor: theme.colorScheme.error));
                  }
                },
                style: ElevatedButton.styleFrom(),
              ),
              const SizedBox(height: 24),

              ExpansionTile(
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
                  /* ... list tiles ... */
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _getEventTypeLabel(NotificationEventType type) {
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
