import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/models/notification_format_config.dart';
import 'package:holodex_notifier/domain/models/notification_instruction.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Formats notification title and body based on provided data and configuration.
///
/// Parameters:
/// - `config`: The loaded NotificationFormatConfig.
/// - `eventType`: The type of notification event (live, reminder, etc.).
/// - `channelName`: Name of the video's primary channel.
/// - `videoTitle`: Title of the video/media.
/// - `videoType`: Type of the video ('stream', 'clip', 'placeholder').
/// - `availableAt`: The actual time the event is available/scheduled (UTC).
/// - `notificationScheduledTime`: The time this specific notification is scheduled to be shown (UTC). Can be null for immediate notifications.
/// - `mentionTargetChannelName`: Name of the specific channel being mentioned (for Mention events).
/// - `mentionedChannelNames`: List of names of all mentioned channels (used if mentionTargetChannelName is null).
/// - `logger`: Logging service instance.
///
/// Returns a record containing the formatted title and body.
({String title, String body}) formatNotificationContent({
  required NotificationFormatConfig config,
  required NotificationEventType eventType,
  required String channelName,
  required String videoTitle,
  required String? videoType, // Can be null from CachedVideo
  required DateTime availableAt, // The actual EVENT time (UTC)
  required DateTime? notificationScheduledTime, // When the NOTIFICATION is shown (UTC)
  required String? mentionTargetChannelName,
  required List<String>? mentionedChannelNames,
  required ILoggingService logger,
}) {
  logger.trace("[FormatUtil] Input: type=$eventType, scheduled=$notificationScheduledTime, eventTime=$availableAt");
  final format = config.formats[eventType] ?? NotificationFormatConfig.defaultConfig().formats[eventType]!;
  logger.trace("[FormatUtil] Using format: Title='${format.titleTemplate}', Body='${format.bodyTemplate}'");

  final DateTime now = DateTime.now(); // Local time for comparison
  // --- Use event time (availableAt) for event-related formatting ---
  final DateTime localEventTime = availableAt.toLocal();

  // --- Use notification schedule time for time-to-notification formatting ---
  final DateTime? localNotificationTime = notificationScheduledTime?.toLocal();

  String timeToEventString = '';
  String timeToNotifString = '';

  // Calculate time relative to the EVENT time
  try {
    // Ensure timeago uses the local time equivalent of the event time
    timeToEventString = timeago.format(localEventTime, locale: 'en_short', allowFromNow: true);
    logger.trace("[FormatUtil] Calculated timeToEventString: '$timeToEventString' (from local event time: $localEventTime)");
  } catch (e) {
    logger.error("[FormatUtil] Error formatting timeToEventString using localEventTime: $localEventTime", e);
    timeToEventString = (localEventTime.isBefore(now)) ? "just now" : "soon";
  }

  // Calculate time relative to the NOTIFICATION show time
  if (localNotificationTime != null) {
    try {
      timeToNotifString = timeago.format(localNotificationTime, locale: 'en_short', allowFromNow: true);
      logger.trace("[FormatUtil] Calculated timeToNotifString: '$timeToNotifString' (from local notification time: $localNotificationTime)");
    } catch (e) {
      logger.error("[FormatUtil] Error formatting timeToNotifString using localNotificationTime: $localNotificationTime", e);
      timeToNotifString = (localNotificationTime.isBefore(now)) ? "now" : "soon";
    }
  } else {
    // Immediate notification
    timeToNotifString = "now";
    logger.trace("[FormatUtil] timeToNotifString set to 'now' (immediate notification)");
  }

  String mentionedChannelsDisplay = mentionTargetChannelName ??
      (mentionedChannelNames != null && mentionedChannelNames.isNotEmpty
          ? mentionedChannelNames.join(', ')
          : '');

  // --- Use localEventTime for displaying the event's time/date ---
  final String mediaTime = DateFormat.jm().format(localEventTime);
  final String actualVideoType = videoType ?? 'media';
  final String mediaTypeUserFriendly = ((actualVideoType == 'placeholder') ? 'media' : actualVideoType);
  final String mediaTypeCaps = mediaTypeUserFriendly.toUpperCase();

  final String dateYMD = DateFormat('yyyy-MM-dd').format(localEventTime);
  final String dateDMY = DateFormat('dd-MM-yyyy').format(localEventTime);
  final String dateMDY = DateFormat('MM-dd-yyyy').format(localEventTime);
  final String dateMD = DateFormat('MM-dd').format(localEventTime);
  final String dateDM = DateFormat('dd-MM').format(localEventTime);
  final String dateAsia =
      '${DateFormat('yyyy').format(localEventTime)}年${DateFormat('MM').format(localEventTime)}月${DateFormat('dd').format(localEventTime)}日';

  final Map<String, String> replacements = {
    '{channelName}': channelName,
    '{mentionedChannels}': mentionedChannelsDisplay,
    '{mediaTitle}': videoTitle,
    '{mediaType}': mediaTypeUserFriendly,
    '{mediaTypeCaps}': mediaTypeCaps,
    '{mediaTime}': mediaTime, // Based on event time
    '{timeToEvent}': timeToEventString, // Based on event time
    '{timeToNotif}': timeToNotifString, // Based on notification show time
    '{mediaDateYMD}': dateYMD,
    '{mediaDateDMY}': dateDMY,
    '{mediaDateMDY}': dateMDY,
    '{mediaDateMD}': dateMD,
    '{mediaDateDM}': dateDM,
    '{mediaDateAsia}': dateAsia,
    '{newLine}': '\n',
  };

  String title = format.titleTemplate;
  String body = format.bodyTemplate;

  replacements.forEach((key, value) {
    title = title.replaceAll(key, value);
    body = body.replaceAll(key, value);
  });

  logger.trace("[FormatUtil] Result -> Title='$title', Body='$body'");
  return (title: title, body: body);
}
