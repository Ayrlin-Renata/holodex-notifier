// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\interfaces\cache_service.dart
import 'package:holodex_notifier/infrastructure/data/database.dart';

/// Defines the contract for managing the cached video data.
abstract class ICacheService {
  /// Fetches a single cached video by its ID.
  Future<CachedVideo?> getVideo(String videoId);

  /// Inserts a new video or updates an existing one based on the video ID.
  Future<void> upsertVideo(CachedVideosCompanion video);

  /// Deletes a cached video by its ID.
  Future<void> deleteVideo(String videoId);

  /// Retrieves all cached videos matching a specific status.
  Future<List<CachedVideo>> getVideosByStatus(String status);

  /// Prunes old or 'past' videos from the cache based on defined criteria (e.g., age).
  /// Returns the number of videos pruned.
  Future<int> pruneOldVideos(Duration maxAge);

  /// Updates the status field of a specific cached video.
  Future<void> updateVideoStatus(String videoId, String newStatus);

  /// Updates the scheduled notification ID for a specific video.
  /// Set to null to indicate no notification is scheduled.
  Future<void> updateScheduledNotificationId(String videoId, int? notificationId);

  /// Updates the timestamp when the last immediate 'live' notification was sent for a video.
  Future<void> updateLastLiveNotificationTime(String videoId, DateTime? time);

  /// Sets or clears the flag indicating a new media notification is pending (e.g., waiting for certainty).
  Future<void> setPendingNewMediaFlag(String videoId, bool isPending);

  /// Retrieves all videos that currently have a live notification scheduled.
  Future<List<CachedVideo>> getScheduledVideos();

  /// Returns a stream that emits the list of scheduled videos whenever it changes.
  Stream<List<CachedVideo>> watchScheduledVideos();

  Future<List<CachedVideo>> getVideosWithScheduledReminders();

  Future<void> updateScheduledReminderNotificationId(String videoId, int? notificationId);
  Future<void> updateScheduledReminderTime(String videoId, DateTime? time);
}
