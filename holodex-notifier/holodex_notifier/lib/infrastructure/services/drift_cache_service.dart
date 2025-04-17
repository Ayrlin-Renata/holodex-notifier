import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

class DriftCacheService implements ICacheService {
  final AppDatabase _db;
  final ILoggingService _logger;

  DriftCacheService(this._db, this._logger);

  @override
  Future<CachedVideo?> getVideo(String videoId) => _db.getVideo(videoId);

  @override
  Future<void> upsertVideo(CachedVideosCompanion video) => _db.upsertVideo(video);

  @override
  Future<int> updateVideo(String videoId, CachedVideosCompanion partialCompanion) {
    return (_db.update(_db.cachedVideos)..where((t) => t.videoId.equals(videoId))).write(partialCompanion);
  }

  @override
  Future<void> deleteVideo(String videoId) => _db.deleteVideo(videoId);

  @override
  Future<List<CachedVideo>> getVideosByStatus(String status) => _db.getVideosByStatus(status);

  @override
  Future<int> pruneOldVideos(Duration maxAge) async {
    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(maxAge);

    final countPast = await _db.prunePastVideos();
    final countOld = await _db.pruneOldVideos(cutoff);

    _logger.info("[DriftCacheService] Pruned $countPast 'past' videos and $countOld videos older than $cutoff.");
    return countPast + countOld;
  }

  @override
  Future<void> updateVideoStatus(String videoId, String newStatus) => _db.updateVideoStatusInternal(videoId, newStatus);

  @override
  Future<void> updateScheduledNotificationId(String videoId, int? notificationId) =>
      _db.updateScheduledNotificationIdInternal(videoId, notificationId);

  @override
  Future<void> updateLastLiveNotificationTime(String videoId, DateTime? time) => _db.updateLastLiveNotificationTimeInternal(videoId, time);

  @override
  Future<void> setPendingNewMediaFlag(String videoId, bool isPending) => _db.setPendingNewMediaFlagInternal(videoId, isPending);

  @override
  Future<void> updateScheduledReminderNotificationId(String videoId, int? notificationId) =>
      _db.updateScheduledReminderNotificationIdInternal(videoId, notificationId);

  @override
  Future<void> updateScheduledReminderTime(String videoId, DateTime? time) => _db.updateScheduledReminderTimeInternal(videoId, time);

  @override
  Future<List<CachedVideo>> getScheduledVideos() => _db.getScheduledVideosInternal();

  @override
  Stream<List<CachedVideo>> watchScheduledVideos() => _db.watchScheduledVideosInternal();

  @override
  Future<List<CachedVideo>> getVideosWithScheduledReminders() => _db.getVideosWithScheduledRemindersInternal();

  @override
  Future<List<CachedVideo>> getMembersOnlyVideosByChannel(String channelId) => _db.getMembersOnlyVideosByChannelInternal(channelId);

  @override
  Future<List<CachedVideo>> getClipVideosByChannel(String channelId) => _db.getClipVideosByChannelInternal(channelId);
}