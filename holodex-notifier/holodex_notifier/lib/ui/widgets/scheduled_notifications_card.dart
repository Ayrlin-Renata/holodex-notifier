import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // {{ Import FontAwesome }}
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart'; // Ensure LoggingService is imported
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/main.dart'; // For main providers
import 'package:intl/intl.dart'; // For date formatting
import 'package:url_launcher/url_launcher.dart'; // For url_launcher

class ScheduledNotificationsCard extends HookConsumerWidget {
  const ScheduledNotificationsCard({super.key});
  static const int _initialItemLimit = 16;

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  // --- Helper to launch URL ---
  Future<void> _launchUrlHelper(BuildContext context, String urlString, ILoggingService logger) async {
    // ... (remains the same) ...
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        logger.info("Launched URL: $urlString");
      } else {
        logger.warning("Could not launch URL: $urlString");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $urlString')));
        }
      }
    } catch (e, s) {
      logger.error("Error launching URL: $urlString", e, s);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
      }
    }
  }
  // --- End Helper ---

  Widget _buildDateHeader(DateTime date, ThemeData theme) {
    // ... (remains the same) ...
    final String formattedDate = DateFormat('EEEE, MMMM d').format(date);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0, right: 4.0),
      child: Text(
        formattedDate,
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600),
      ),
    );
  }

  // --- Helper to show cancel confirmation dialog ---
  Future<bool?> _showCancelConfirmation(BuildContext context, String itemTitle) {
    // ... (remains the same) ...
      return showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Cancel Scheduled Notification?'),
            content: Text('Are you sure you want to cancel the scheduled notification for "$itemTitle"?'),
            actions: <Widget>[
              TextButton(child: const Text('Keep'), onPressed: () => Navigator.of(ctx).pop(false)), // Return false
              TextButton(
                child: const Text('Cancel It', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(ctx).pop(true), // Return true
              ),
            ],
          );
        },
      );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheduledListAsync = ref.watch(filteredScheduledNotificationsProvider);
    final logger = ref.watch(loggingServiceProvider);
    final notificationService = ref.watch(notificationServiceProvider);
    final cacheService = ref.watch(cacheServiceProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final isExpanded = useState(false);

    logger.trace( // Changed to trace for less noise
      "[ScheduledNotificationsCard] Build. Filtered Async state: isRefreshing=${scheduledListAsync.isRefreshing}, isLoading=${scheduledListAsync.isLoading}, hasValue=${scheduledListAsync.hasValue}, hasError=${scheduledListAsync.hasError}",
    );

    return scheduledListAsync.when(
      data: (List<ScheduledNotificationItem> filteredItems) {
        logger.trace("[ScheduledNotificationsCard] Rebuilt with filtered data. List length: ${filteredItems.length}"); // Changed to trace
        if (filteredItems.isEmpty) {
           // ... (empty list handling remains the same) ...
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
                final String displayBody = item.formattedBody; // Keep the full body for potential expansion

                bool showHeader = index == 0 ||
                    !_isSameDay(
                      item.scheduledTime.toLocal(),
                      filteredItems[index - 1].scheduledTime.toLocal(),
                    );

                // --- Derived Image URL ---
                String? imageUrl;
                if (videoData.videoType != 'placeholder') {
                   imageUrl = 'https://i.ytimg.com/vi/${videoData.videoId}/mqdefault.jpg';
                } else {
                    // TODO: Get placeholder thumbnail URL from cache if available
                    // imageUrl = videoData.placeholderThumbnailUrl ?? null;
                }

                // --- Derived Action URLs ---
                final bool isPlaceholder = videoData.videoType == 'placeholder';
                // TODO: Get sourceLink from cache if available
                final String? sourceLink = null; // Use null as per CHANGE
                final String youtubeLink = 'https://www.youtube.com/watch?v=${videoData.videoId}';
                final String holodexLink = 'https://holodex.net/watch/${videoData.videoId}';

                // Build the main ListTile content separately
                final listTileContent = ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Restore some padding
                   leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    backgroundImage: videoData.channelAvatarUrl != null ? CachedNetworkImageProvider(videoData.channelAvatarUrl!) : null,
                    child: videoData.channelAvatarUrl == null ? const Icon(Icons.person_outline, size: 20) : null,
                  ),
                  title: Text(displayTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)), // Slightly bolder title
                  subtitle: Text(
                    displayBody,
                    style: theme.textTheme.bodySmall,
                  ),
                  dense: false,
                );

                // The actual card content, to be placed inside Dismissible
                final cardContent = Card(
                  elevation: 0.5,
                  // Use symmetric vertical margin
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3))
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero, // Let ListTile handle padding
                    title: listTileContent,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(bottom: 16), // Ensure bottom padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- Image Display ---
                            // ... (Image logic remains the same) ...
                             if (imageUrl != null)
                               Padding(
                                 padding: const EdgeInsets.only(bottom: 12.0), // More space below image
                                 child: ClipRRect(
                                     borderRadius: BorderRadius.circular(8.0),
                                     child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: Colors.grey[300], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                        errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image_outlined))),
                                      ),
                                    ),
                                  ),
                               )
                             else
                                 Padding(
                                   padding: const EdgeInsets.only(bottom: 12.0),
                                   child: AspectRatio(
                                       aspectRatio: 16 / 9,
                                       child: DecoratedBox(
                                          decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8.0),),
                                           child: Center(child:Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.onSurfaceVariant),)))
                                 ),

                            // --- Action Buttons ---
                            ButtonBar(
                                 alignment: MainAxisAlignment.spaceEvenly,
                                 buttonPadding: EdgeInsets.zero,
                                 children: [
                                   if (isPlaceholder && sourceLink != null)
                                       TextButton.icon(
                                          icon: const Icon(Icons.link, size: 16),
                                          label: const Text("Source"),
                                          onPressed: () => _launchUrlHelper(context, sourceLink, logger),
                                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                       )
                                   else if (!isPlaceholder) ...[
                                        // {{ YouTube Button }}
                                        TextButton.icon(
                                          icon: FaIcon(FontAwesomeIcons.youtube, size: 18, color: Colors.red.shade600), // Use FontAwesome icon
                                          label: const Text("YouTube"),
                                          onPressed: () => _launchUrlHelper(context, youtubeLink, logger),
                                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                        ),
                                        TextButton.icon(
                                            // {{ Use outlined play button for Holodex }}
                                            icon: Icon(Icons.play_arrow_outlined, size: 20, color: Colors.blue.shade600),
                                            label: const Text("Holodex"),
                                            onPressed: () => _launchUrlHelper(context, holodexLink, logger),
                                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                        ),
                                   ]
                                 ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) _buildDateHeader(item.scheduledTime.toLocal(), theme),
                    // {{ Introduce Dismissible }}
                    if (notificationId != null)
                      Dismissible(
                          // Unique key per item
                            key: ValueKey('${item.videoData.videoId}_${item.type.name}'),
                           // Direction: swipe right-to-left
                            direction: DismissDirection.startToEnd,
                            // --- Updated Background ---
                            background: Container(
                                // Apply the SAME vertical margin as the Card
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                // {{ Wrap the colored Container in ClipRRect }}
                                child: ClipRRect(
                                  // {{ Apply the SAME border radius as the Card }}
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                      color: Colors.red.shade400,
                                      padding: const EdgeInsets.only(left: 20.0),
                                      alignment: Alignment.centerLeft,
                                      child: const Icon(Icons.delete_outline, color: Colors.white),
                                  ),
                                ),
                            ),
                           // --- End Updated Background ---
                            // Confirmation before dismissing
                            confirmDismiss: (direction) async {
                              // ... (confirm logic remains the same) ...
                              if (!context.mounted) return false;
                              final confirm = await _showCancelConfirmation(context, videoData.videoTitle);
                              return confirm ?? false;
                            },
                             // Action after dismissal confirmation
                            onDismissed: (direction) async {
                              // ... (cancellation logic remains the same) ...
                              logger.info("Dismissed item, cancelling ID: $notificationId for video: ${videoData.videoId}");
                              try {
                                await notificationService.cancelScheduledNotification(notificationId);
                                if (item.type == NotificationEventType.reminder) {
                                  await cacheService.updateScheduledReminderNotificationId(videoData.videoId, null);
                                  await cacheService.updateScheduledReminderTime(videoData.videoId, null);
                                } else {
                                  await cacheService.updateScheduledNotificationId(videoData.videoId, null);
                                }
                                if (context.mounted) {
                                  scaffoldMessenger.showSnackBar( SnackBar(content: Text('Cancelled "${videoData.videoTitle}"'), duration: const Duration(seconds: 2)),);
                                }
                                ref.read(scheduledNotificationsProvider.notifier).fetchScheduledNotifications(isRefreshing: true);
                              } catch (e, s) {
                                logger.error("Error cancelling notification ID after dismiss: $notificationId", e, s);
                                if (context.mounted) {
                                  scaffoldMessenger.showSnackBar( SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: theme.colorScheme.error),);
                                }
                                ref.read(scheduledNotificationsProvider.notifier).fetchScheduledNotifications(isRefreshing: true);
                              }
                            },
                           // The actual card content
                           child: cardContent,
                        )
                      else
                         // If not dismissible, show the card directly without Dismissible wrapper
                         cardContent,
                      // {{ End Dismissible Section Update }}
                    ],
                  );
              },
            ),
            // --- Show All/Fewer Button ---
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
      loading: () => const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: CircularProgressIndicator())),
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
}