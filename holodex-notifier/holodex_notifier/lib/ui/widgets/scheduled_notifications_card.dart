import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/main.dart'; // For main providers
// For scheduledNotificationsProvider
// Removed: import 'package:holodex_notifier/ui/widgets/settings_card.dart';
import 'package:intl/intl.dart'; // For date formatting

// Removed the SettingsCard wrapper. This widget now returns the content directly.
class ScheduledNotificationsCard extends HookConsumerWidget {
  const ScheduledNotificationsCard({super.key});
  static const int _initialItemLimit = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // The type is now AsyncValue<List<CachedVideo>>
    final scheduledListAsync = ref.watch(scheduledNotificationsProvider);
    final logger = ref.watch(loggingServiceProvider); // Get logger

    // Access needed services/controllers for cancel action
    final notificationService = ref.watch(notificationServiceProvider);
    final cacheService = ref.watch(cacheServiceProvider); // To update cache after cancel
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isExpanded = useState(false);

    logger.debug(
      "[ScheduledNotificationsCard] Build method called. AsyncValue state: isRefreshing=${scheduledListAsync.isRefreshing}, isLoading=${scheduledListAsync.isLoading}, hasValue=${scheduledListAsync.hasValue}, hasError=${scheduledListAsync.hasError}",
    );

    // REMOVED: SettingsCard wrapper
    // Return the primary content based on the AsyncValue state
    return scheduledListAsync.when(
      data: (scheduledList) {
        logger.info("[ScheduledNotificationsCard] Rebuilt with data. List length: ${scheduledList.length}");
        if (scheduledList.isNotEmpty) {
          // Log details of the first item for inspection
          final firstItem = scheduledList.first;
          logger.debug(
            "[ScheduledNotificationsCard] First item details: videoId=${firstItem.videoId}, status=${firstItem.status}, scheduledTime=${firstItem.startScheduled}, scheduledId=${firstItem.scheduledLiveNotificationId}, title=${firstItem.videoTitle}",
          );
        }
        if (scheduledList.isEmpty) {
          // Return only the 'empty' message. Refresh is handled by parent page.
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0), // Added more padding
              child: Text('No upcoming notifications scheduled.', style: TextStyle(fontStyle: FontStyle.italic)),
            ),
          );
          // REMOVED: Column wrapper and Refresh button for empty state
        }
        final itemCount = isExpanded.value ? scheduledList.length : min(scheduledList.length, _initialItemLimit);
        return Column(
          // Keep Column to hold list and Show All/Fewer button
          children: [
            ListView.builder(
              shrinkWrap: true, // Important inside another scrollable
              physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling
              itemCount: itemCount, // Use calculated item count
              itemBuilder: (context, index) {
                final item = scheduledList[index];
                logger.debug(
                  "[ScheduledNotificationsCard] Building tile for index $index, Video ID: ${item.videoId}, Scheduled ID: ${item.scheduledLiveNotificationId}",
                );
                final scheduledTime = item.startScheduled != null ? DateTime.tryParse(item.startScheduled!) : null;
                final notificationId = item.scheduledLiveNotificationId; // Get the ID

                final String channelName = item.channelName; // Use cached name
                final String? avatarUrl = item.channelAvatarUrl; // Use cached avatar URL
                final String videoTitle = item.videoTitle; // Use cached title

                return ListTile(
                    // --- Add Avatar ---
                    leading: CircleAvatar(
                      radius: 20, // Adjust size as needed
                      backgroundColor: theme.colorScheme.secondaryContainer, // Placeholder color
                      backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                      child: avatarUrl == null ? const Icon(Icons.person_outline, size: 20) : null,
                    ),
                    // --- Use cached names ---
                    title: Text(channelName, style: theme.textTheme.titleSmall),
                    subtitle: Text(
                      // Use cached title
                      "$videoTitle\nScheduled: ${scheduledTime != null ? DateFormat.yMd().add_jm().format(scheduledTime.toLocal()) : 'Unknown'}",
                      style: theme.textTheme.bodySmall,
                      maxLines: 3, // Allow title to wrap
                      overflow: TextOverflow.ellipsis,
                      // Make subtitle slightly smaller if needed
                      // textScaleFactor: 0.9,
                    ),
                    trailing: notificationId != null
                        ? IconButton(
                            icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
                            tooltip: 'Cancel Scheduled Notification',
                            onPressed: () async {
                              if (!context.mounted) return;
                              try {
                                logger.info("Attempting to cancel scheduled notification ID: $notificationId for video: ${item.videoId}");
                                // 1. Cancel platform notification
                                await notificationService.cancelScheduledNotification(notificationId);
                                logger.debug("Platform notification cancelled.");
                                // 2. Update cache to remove scheduled ID
                                // NOTE: The stream provider will automatically pick up this change
                                await cacheService.updateScheduledNotificationId(item.videoId, null);
                                logger.debug("Cache updated to remove scheduled ID.");
                                if (!context.mounted) return;
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Scheduled notification cancelled.'), duration: Duration(seconds: 2)),
                                );
                                // Refresh provider manually after successful cancel
                                ref.read(scheduledNotificationsProvider.notifier).fetchScheduledNotifications(isRefreshing: true);
                              } catch (e, s) {
                                logger.error("Error cancelling notification: $notificationId", e, s);
                                if (!context.mounted) return;
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: theme.colorScheme.error),
                                );
                              }
                            },
                          )
                        : null, // No button if ID is null (shouldn't happen based on query)
                    dense: true,
                  );
              },
            ),
             // --- Show All/Fewer Button ---
            if (scheduledList.length > _initialItemLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  child: Text(isExpanded.value ? 'Show Fewer' : 'Show All (${scheduledList.length})'),
                  onPressed: () {
                    isExpanded.value = !isExpanded.value; // Toggle expansion state
                  },
                ),
              ),
            // --- End Show All/Fewer Button ---

             // REMOVED: Refresh Button - handled by parent page's RefreshIndicator
          ],
        );
      },
      loading: () => const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: CircularProgressIndicator())), // Added padding
      error: (error, stack) {
        logger.error("[ScheduledNotificationsCard] Rebuilt with error.", error, stack);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading scheduled notifications: $error', style: TextStyle(color: theme.colorScheme.error)),
          ),
        );
      },
    );
  }

  // REMOVED: _buildRefreshButton helper widget
}