import 'package:holodex_notifier/infrastructure/data/database.dart';

abstract class ICacheService {
  Future<CachedVideo?> getVideo(String videoId);

  Future<void> upsertVideo(CachedVideosCompanion video);

  Future<int> updateVideo(String videoId, CachedVideosCompanion partialCompanion);

  Future<void> deleteVideo(String videoId);

  Future<List<CachedVideo>> getVideosByStatus(String status);

  Future<int> pruneOldVideos(Duration maxAge);

  Future<void> updateVideoStatus(String videoId, String newStatus);

  Future<void> updateScheduledNotificationId(String videoId, int? notificationId);

  Future<void> updateLastLiveNotificationTime(String videoId, DateTime? time);

  Future<void> setPendingNewMediaFlag(String videoId, bool isPending);

  Future<List<CachedVideo>> getScheduledVideos();
  Stream<List<CachedVideo>> watchScheduledVideos();
  Future<List<CachedVideo>> getVideosWithScheduledReminders();
  Future<void> updateScheduledReminderNotificationId(String videoId, int? notificationId);
  Future<void> updateScheduledReminderTime(String videoId, DateTime? time);
  Future<List<CachedVideo>> getMembersOnlyVideosByChannel(String channelId);
  Future<List<CachedVideo>> getClipVideosByChannel(String channelId);
}
