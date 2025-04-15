import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/main.dart'; // For main providers
// For scheduledNotificationsProvider
// Removed: import 'package:holodex_notifier/ui/widgets/settings_card.dart';
import 'package:intl/intl.dart'; // For date formatting

class ScheduledNotificationsCard extends HookConsumerWidget {
  const ScheduledNotificationsCard({super.key});
  static const int _initialItemLimit = 16;

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime date, ThemeData theme) {
    // Format the date nicely (e.g., Tuesday, April 15)
    final String formattedDate = DateFormat('EEEE, MMMM d').format(date);
    return Padding(
      // Add padding above the header to separate it from the previous item/card edge
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0, right: 4.0),
      child: Text(
        formattedDate,
        style: theme.textTheme.titleSmall?.copyWith(
          // Use titleSmall or similar
          color: theme.colorScheme.secondary, // Use an accent color
          fontWeight: FontWeight.w600, // Slightly bolder
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // {{ Watch the FILTERED provider }}
    final scheduledListAsync = ref.watch(filteredScheduledNotificationsProvider);
    final logger = ref.watch(loggingServiceProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    // {{ Import and read CacheService correctly }}
    final cacheService = ref.watch(cacheServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isExpanded = useState(false);

    logger.debug(
      "[ScheduledNotificationsCard] Build. Filtered Async state: isRefreshing=${scheduledListAsync.isRefreshing}, isLoading=${scheduledListAsync.isLoading}, hasValue=${scheduledListAsync.hasValue}, hasError=${scheduledListAsync.hasError}",
    );

    return scheduledListAsync.when(
      data: (List<ScheduledNotificationItem> filteredItems) {
        // This is now the filtered list
        logger.info("[ScheduledNotificationsCard] Rebuilt with filtered data. List length: ${filteredItems.length}");
        if (filteredItems.isEmpty) {
          // Show message indicating filtering might be active if the *base* list is not empty
          final baseListCount = ref.read(scheduledNotificationsProvider).asData?.value.length ?? 0;
          if (baseListCount > 0) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text('No scheduled items match current filters.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            );
          } else {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text('No upcoming notifications scheduled.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            );
          }
        }
        // Determine how many items to show (Show All/Fewer logic)
        final itemCount = isExpanded.value ? filteredItems.length : min(filteredItems.length, _initialItemLimit);

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final videoData = item.videoData;
                final int? notificationId = item.notificationId;
                final String displayTitle = item.formattedTitle;
                final String displayBody = item.formattedBody;

                bool showHeader = false;
                if (index == 0) {
                  // Always show header for the first item
                  showHeader = true;
                } else {
                  // Show header if the date is different from the previous item
                  final previousItem = filteredItems[index - 1];
                  if (!_isSameDay(item.scheduledTime.toLocal(), previousItem.scheduledTime.toLocal())) {
                    showHeader = true;
                  }
                }

                final listTile = ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    backgroundImage: videoData.channelAvatarUrl != null ? CachedNetworkImageProvider(videoData.channelAvatarUrl!) : null,
                    child: videoData.channelAvatarUrl == null ? const Icon(Icons.person_outline, size: 20) : null,
                  ),
                  // {{ Use the formatted fields for display }}
                  title: Text(displayTitle, style: theme.textTheme.titleSmall),
                  subtitle: Text(
                    displayBody,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2, // Allow more lines for body
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing:
                      notificationId != null
                          ? IconButton(
                            icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
                            tooltip: 'Cancel Scheduled ${item.type == NotificationEventType.reminder ? 'Reminder' : 'Live'}', // Dynamic tooltip
                            onPressed: () async {
                              if (!context.mounted) return;
                              try {
                                logger.info("Attempting to cancel scheduled ${item.type.name} ID: $notificationId for video: ${videoData.videoId}");
                                await notificationService.cancelScheduledNotification(notificationId);

                                // Update cache to remove the specific ID based on type
                                if (item.type == NotificationEventType.reminder) {
                                  await cacheService.updateScheduledReminderNotificationId(videoData.videoId, null);
                                  await cacheService.updateScheduledReminderTime(videoData.videoId, null);
                                } else {
                                  // Must be live
                                  await cacheService.updateScheduledNotificationId(videoData.videoId, null);
                                }
                                logger.debug("Cache updated to remove scheduled ID.");
                                if (!context.mounted) return;
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Scheduled notification cancelled.'), duration: Duration(seconds: 2)),
                                );
                                // Refresh BASE provider manually after successful cancel
                                ref.read(scheduledNotificationsProvider.notifier).fetchScheduledNotifications(isRefreshing: true);
                              } catch (e, s) {
                                logger.error("Error cancelling notification ID: $notificationId", e, s);
                                if (!context.mounted) return;
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: theme.colorScheme.error),
                                );
                              }
                            },
                          )
                          : null,
                  dense: true,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) _buildDateHeader(item.scheduledTime.toLocal(), theme),
                    listTile, // Always include the ListTile
                  ],
                );
              },
            ),
            // --- Show All/Fewer Button ---
            // {{ Use filteredItems length }}
            if (filteredItems.length > _initialItemLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton(
                  child: Text(isExpanded.value ? 'Show Fewer' : 'Show All (${filteredItems.length})'),
                  onPressed: () {
                    isExpanded.value = !isExpanded.value;
                  },
                ),
              ),
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
