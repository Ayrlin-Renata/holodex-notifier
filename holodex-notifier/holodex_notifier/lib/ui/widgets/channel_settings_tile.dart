import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/main.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: channelSetting.avatarUrl ?? '',
                  placeholder:
                      (context, url) => const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person_outline, color: Colors.white70)),
                  errorWidget:
                      (context, url, error) =>
                          const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.error_outline, color: Colors.white70)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(channelSetting.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 0.0,
                    alignment: WrapAlignment.spaceBetween,
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
                      _buildToggleChip(
                        context: context,
                        label: 'Members',
                        icon: Icons.card_membership_outlined,
                        value: channelSetting.notifyMembersOnly,
                        onChanged: (v) => appController.updateChannelNotificationSetting(channelSetting.channelId, 'notifyMembersOnly', v),
                      ),
                      _buildToggleChip(
                        context: context,
                        label: 'Clips',
                        icon: Icons.content_cut_outlined,
                        value: channelSetting.notifyClips,
                        onChanged: (v) => appController.updateChannelNotificationSetting(channelSetting.channelId, 'notifyClips', v),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Remove Channel',
              onPressed: () {
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
                            await appController.removeChannel(channelSetting.channelId);
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('Removed ${channelSetting.name}'), duration: Duration(seconds: 2)));
                            }
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
      showCheckmark: false,
    );
  }
}
