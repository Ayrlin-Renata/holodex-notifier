import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart'; // For avatars
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/main.dart';

// Assuming you have AppController methods eventually
// import 'package:holodex_notifier/application/controllers/app_controller.dart';
// import 'package:holodex_notifier/main.dart'; // For appControllerProvider

class ChannelSettingsTile extends ConsumerWidget {
  final ChannelSubscriptionSetting channelSetting;

  const ChannelSettingsTile({required this.channelSetting, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appController = ref.watch(appControllerProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            // Reorder Handle
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Icon(Icons.drag_handle)),

            // Avatar
                        SizedBox(
              width: 64,
              height: 64,
              child: ClipOval(
                child: CachedNetworkImage(
                  // Use the avatarUrl from the setting object
                  imageUrl: channelSetting.avatarUrl ?? '', // Use null-aware operator and provide empty string if null
                  placeholder: (context, url) => const CircleAvatar(
                     backgroundColor: Colors.grey, // Placeholder background
                     child: Icon(Icons.person_outline, color: Colors.white70),
                  ),
                  errorWidget: (context, url, error) => const CircleAvatar(
                     backgroundColor: Colors.grey, // Placeholder background
                     child: Icon(Icons.error_outline, color: Colors.white70), // Error icon
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Channel Name & Toggles
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(channelSetting.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  // Wrap toggles for smaller screens if necessary
                  Wrap(
                    spacing: 4.0, // Horizontal spacing
                    runSpacing: 0.0, // Vertical spacing
                    children: [
                      _buildToggleChip(
                        context: context,
                        label: 'New',
                        icon: Icons.new_releases_outlined,
                        value: channelSetting.notifyNewMedia,
                        onChanged: (v) => appController.updateChannelNotificationSetting(channelSetting.channelId, 'notifyNewMedia', v),
                      ),
                      _buildToggleChip(
                        context: context,
                        label: 'Mentions',
                        icon: Icons.alternate_email_outlined,
                        value: channelSetting.notifyMentions,
                        onChanged: (v) => appController.updateChannelNotificationSetting(channelSetting.channelId, 'notifyMentions', v),
                      ),
                      _buildToggleChip(
                        context: context,
                        label: 'Live',
                        icon: Icons.live_tv_outlined,
                        value: channelSetting.notifyLive,
                        onChanged: (v) => appController.updateChannelNotificationSetting(channelSetting.channelId, 'notifyLive', v),
                      ),
                      _buildToggleChip(
                        context: context,
                        label: 'Updates',
                        icon: Icons.update_outlined,
                        value: channelSetting.notifyUpdates,
                        onChanged: (v) => appController.updateChannelNotificationSetting(channelSetting.channelId, 'notifyUpdates', v),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Remove Channel',
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    return AlertDialog(
                      title: const Text('Remove Channel?'),
                      content: Text('Are you sure you want to remove "${channelSetting.name}"?'),
                      actions: <Widget>[
                        TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
                        TextButton(
                          child: const Text('Remove', style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            // Call the AppController method which includes cleanup
                            await appController.removeChannel(channelSetting.channelId);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Removed ${channelSetting.name}'), duration: Duration(seconds: 2)));
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper for toggle chips
  Widget _buildToggleChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: value,
      onSelected: onChanged,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      selectedColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      showCheckmark: false, // More explicit toggle state
    );
  }
}
