// ignore_for_file: unused_result

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/application/state/scheduled_notifications_state.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/models/channel_subscription_setting.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/main.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drift/drift.dart' show Value;

class ScheduledNotificationsCard extends HookConsumerWidget {
  const ScheduledNotificationsCard({super.key});
  static const int _initialItemLimit = 16;

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> _launchUrlHelper(BuildContext context, String urlString, ILoggingService logger) async {
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

  Widget _buildDateHeader(DateTime date, ThemeData theme) {
    final String formattedDate = DateFormat('EEEE, MMMM d').format(date);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0, right: 4.0),
      child: Text(formattedDate, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoBar(ScheduledNotificationItem item, List<ChannelSubscriptionSetting> subscribedChannels, ThemeData theme, WidgetRef ref) {
    final videoData = item.videoData;
    final mentionedIds = videoData.mentionedChannelIds;
    final dateFormat = DateFormat.jm();
    final scheduledTimeLocal = item.scheduledTime.toLocal();

    if (mentionedIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
        margin: const EdgeInsets.only(bottom: 8.0),
        constraints: const BoxConstraints(minHeight: 28),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2.0,
          runSpacing: 0.0,
          children: [
            const SizedBox(width: 4),
            Icon(
              item.type == NotificationEventType.reminder ? Icons.notifications_active_outlined : Icons.timer_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Tooltip(
              message:
                  item.type == NotificationEventType.reminder
                      ? 'Reminder scheduled for ${dateFormat.format(scheduledTimeLocal)}'
                      : 'Live notification scheduled for ${dateFormat.format(scheduledTimeLocal)}',
              child: Text(
                dateFormat.format(scheduledTimeLocal),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> mentionWidgets = [];
    mentionWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 4.0),
        child: Icon(Icons.alternate_email, size: 14, color: theme.colorScheme.onSurfaceVariant),
      ),
    );

    for (String id in mentionedIds) {
      final nameAsyncValue = ref.watch(channelNameProvider(id));
      final sub = subscribedChannels.firstWhereOrNull((s) => s.channelId == id);
      final bool isSubscribed = sub != null;

      mentionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0.0),
          child: nameAsyncValue.when(
            loading:
                () => Chip(
                  label: Text(
                    id.substring(0, min(id.length, 6)) + (id.length > 6 ? '...' : ''),
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
            error:
                (err, stack) => Tooltip(
                  message: 'Error loading name for $id',
                  child: Chip(
                    label: Text(id, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error)),

                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
                    backgroundColor: theme.colorScheme.errorContainer,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
            data: (cachedName) {
              final String name = cachedName ?? sub?.name ?? id;
              return Tooltip(
                message: isSubscribed ? '$name (Subscribed)' : name,
                child: Chip(
                  label: Text(name, overflow: TextOverflow.ellipsis),
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: isSubscribed ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSubscribed ? FontWeight.bold : FontWeight.normal,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
                  backgroundColor:
                      isSubscribed ? theme.colorScheme.primaryContainer.withValues(alpha: 0.7) : theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      constraints: const BoxConstraints(minHeight: 28),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2.0,
        runSpacing: 2.0,
        children: [
          Icon(
            item.type == NotificationEventType.reminder ? Icons.notifications_active_outlined : Icons.timer_outlined,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Tooltip(
            message:
                item.type == NotificationEventType.reminder
                    ? 'Reminder scheduled for ${dateFormat.format(scheduledTimeLocal)}'
                    : 'Live notification scheduled for ${dateFormat.format(scheduledTimeLocal)}',
            child: Text(
              dateFormat.format(scheduledTimeLocal),
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ...mentionWidgets,
        ],
      ),
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

    final subscribedChannels = ref.watch(channelListProvider);

    logger.trace(
      "[ScheduledNotificationsCard] Build. Filtered Async state: isRefreshing=${scheduledListAsync.isRefreshing}, isLoading=${scheduledListAsync.isLoading}, hasValue=${scheduledListAsync.hasValue}, hasError=${scheduledListAsync.hasError}",
    );

    return scheduledListAsync.when(
      data: (List<ScheduledNotificationItem> filteredItems) {
        if (filteredItems.isEmpty) {
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
                final String displayBody = item.formattedBody;

                bool showHeader = index == 0 || !_isSameDay(item.scheduledTime.toLocal(), filteredItems[index - 1].scheduledTime.toLocal());

                String? imageUrl = videoData.thumbnailUrl;

                if (imageUrl == null || imageUrl.isEmpty) {
                  logger.warning(
                    "[ScheduledNotificationsCard] imageURL is null or empty for video ${videoData.videoId} (Type: ${videoData.videoType}, Title: ${videoData.videoTitle})",
                  );
                }

                final bool isPlaceholder = videoData.videoType == 'placeholder';
                final String? sourceLink = null;
                final String youtubeLink = 'https://www.youtube.com/watch?v=${videoData.videoId}';
                final String holodexLink = 'https://holodex.net/watch/${videoData.videoId}';

                final listTileContent = ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    backgroundImage: videoData.channelAvatarUrl != null ? CachedNetworkImageProvider(videoData.channelAvatarUrl!) : null,
                    child: videoData.channelAvatarUrl == null ? const Icon(Icons.person_outline, size: 20) : null,
                  ),
                  title: Text(displayTitle, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(displayBody, style: theme.textTheme.bodySmall),
                  dense: false,
                );

                final cardContent = Card(
                  elevation: 0.5,
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: listTileContent,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0).copyWith(top: 0, bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInfoBar(item, subscribedChannels, theme, ref),

                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            color: theme.colorScheme.surfaceContainerHighest,
                                            child: Center(child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant)),
                                          ),
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
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Center(child: Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.onSurfaceVariant)),
                                  ),
                                ),
                              ),

                            OverflowBar(
                              alignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (isPlaceholder && sourceLink != null)
                                  TextButton.icon(
                                    icon: const Icon(Icons.link, size: 16),
                                    label: const Text("Source"),
                                    onPressed: () => _launchUrlHelper(context, sourceLink, logger),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                  )
                                else if (!isPlaceholder) ...[
                                  TextButton.icon(
                                    icon: FaIcon(FontAwesomeIcons.youtube, size: 18, color: Colors.red.shade600),
                                    label: const Text("YouTube"),
                                    onPressed: () => _launchUrlHelper(context, youtubeLink, logger),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                  ),
                                  TextButton.icon(
                                    icon: Icon(Icons.play_arrow_outlined, size: 20, color: Colors.blue.shade600),
                                    label: const Text("Holodex"),
                                    onPressed: () => _launchUrlHelper(context, holodexLink, logger),
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                  ),
                                ],
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
                    () {
                      final Widget itemWidget;

                      if (notificationId != null) {
                        final dismissibleWidget = Dismissible(
                          key: ValueKey('${item.videoData.videoId}_${item.type.name}_${item.scheduledTime.millisecondsSinceEpoch}'),
                          direction: DismissDirection.startToEnd,
                          behavior: HitTestBehavior.translucent,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                color: Colors.red.shade400,
                                padding: const EdgeInsets.only(left: 20.0),
                                alignment: Alignment.centerLeft,
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                            ),
                          ),
                          onDismissed: (direction) async {
                            logger.info("Dismissed item UI, STARTING dismissal process for video: ${videoData.videoId} (${item.type.name})");

                            try {
                              await notificationService.cancelNotification(notificationId);
                              logger.debug("OS Notification $notificationId cancelled.");

                              await cacheService.updateDismissalStatus(videoData.videoId, true);
                              logger.debug("Database dismissal status updated for ${videoData.videoId}.");

                              CachedVideosCompanion clearCompanion;
                              if (item.type == NotificationEventType.reminder) {
                                clearCompanion = const CachedVideosCompanion(
                                  scheduledReminderNotificationId: Value(null),
                                  scheduledReminderTime: Value(null),
                                );
                              } else if (item.type == NotificationEventType.live) {
                                clearCompanion = const CachedVideosCompanion(scheduledLiveNotificationId: Value(null));
                              } else {
                                clearCompanion = const CachedVideosCompanion();
                              }
                              if (clearCompanion != const CachedVideosCompanion()) {
                                await cacheService.updateVideo(videoData.videoId, clearCompanion);
                              }

                              if (context.mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Dismissed "${videoData.videoTitle}"'), duration: const Duration(seconds: 2)),
                                );
                              }

                              ref.refresh(scheduledNotificationsProvider);
                              ref.refresh(dismissedNotificationsNotifierProvider);
                              logger.info("Dismissal process COMPLETED for ${videoData.videoId}. Providers refreshed.");
                            } catch (e, s) {
                              logger.error("Error cancelling notification ID after dismiss: $notificationId", e, s);
                              if (context.mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(content: Text('Failed to dismiss: $e'), backgroundColor: theme.colorScheme.error),
                                );
                              }

                              ref.refresh(scheduledNotificationsProvider);
                              ref.refresh(dismissedNotificationsNotifierProvider);
                            }
                          },
                          child: cardContent,
                        );

                        itemWidget = GestureDetector(behavior: HitTestBehavior.deferToChild, child: dismissibleWidget);
                      } else {
                        itemWidget = cardContent;
                      }
                      return itemWidget;
                    }(),
                  ],
                );
              },
            ),
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
