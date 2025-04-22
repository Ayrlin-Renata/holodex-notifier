import 'package:holodex_notifier/domain/interfaces/cache_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/infrastructure/data/database.dart';

class DriftCacheService implements ICacheService {
  final AppDatabase _db;
  final ILoggingService _logger;

  DriftCacheService(this._db, this._logger);

  @override
  Future<int> countScheduledVideos() => _db.countScheduledVideosInternal();

  @override
  Future<CachedVideo?> getVideo(String videoId) => _db.getVideo(videoId);

  @override
  Future<void> upsertVideo(CachedVideosCompanion video) => _db.upsertVideo(video);

  @override
  Future<int> updateVideo(String videoId, CachedVideosCompanion partialCompanion) {
    _logger.trace("[DriftCacheService] Updating video $videoId with companion: ${partialCompanion.toColumns(true)}");
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
  Future<List<CachedVideo>> getScheduledVideos() {
    _logger.trace("[DriftCacheService] Getting ACTIVE scheduled videos.");
    return _db.getScheduledVideosInternal();
  }

  @override
  Stream<List<CachedVideo>> watchScheduledVideos() {
    _logger.trace("[DriftCacheService] Watching ACTIVE scheduled videos.");
    return _db.watchScheduledVideosInternal();
  }

  @override
  Future<List<CachedVideo>> getVideosWithScheduledReminders() {
    _logger.trace("[DriftCacheService] Getting videos with scheduled reminders (might include dismissed).");
    return _db.getVideosWithScheduledRemindersInternal();
  }

  @override
  Future<List<CachedVideo>> getVideosByChannel(String channelId) => _db.getVideosByChannelInternal(channelId);

    @override
  Future<List<CachedVideo>> getVideosMentioningChannel(String channelId) {
    _logger.trace("[DriftCacheService] Getting videos mentioning channel $channelId.");
    return _db.getVideosMentioningChannelInternal(channelId);
  }
  
  @override
  Future<List<CachedVideo>> getMembersOnlyVideosByChannel(String channelId) => _db.getMembersOnlyVideosByChannelInternal(channelId);

  @override
  Future<List<CachedVideo>> getClipVideosByChannel(String channelId) => _db.getClipVideosByChannelInternal(channelId);

  @override
  Future<List<String>> getSentMentionTargets(String videoId) async {
    return _db.getSentMentionTargetsInternal(videoId);
  }

  @override
  Future<void> addSentMentionTarget(String videoId, String targetChannelId) async {
    _logger.debug("[DriftCacheService] Adding sent mention target $targetChannelId for video $videoId");
    try {
      await _db.transaction(() async {
        final currentTargets = await _db.getSentMentionTargetsInternal(videoId);
        if (!currentTargets.contains(targetChannelId)) {
          final updatedTargets = [...currentTargets, targetChannelId];
          await _db.updateSentMentionTargetsInternal(videoId, updatedTargets);
          _logger.trace("[DriftCacheService] Updated sent mentions for $videoId: $updatedTargets");
        } else {
          _logger.trace("[DriftCacheService] Mention target $targetChannelId already marked as sent for $videoId.");
        }
      });
    } catch (e, s) {
      _logger.error("[DriftCacheService] Failed to add sent mention target for $videoId", e, s);
    }
  }

  @override
  Future<List<CachedVideo>> getDismissedScheduledVideos() {
    _logger.trace("[DriftCacheService] Getting DISMISSED scheduled videos.");
    return _db.getDismissedScheduledVideosInternal();
  }

  @override
  Future<void> updateDismissalStatus(String videoId, bool isDismissed) {
    _logger.debug("[DriftCacheService] Updating dismissal status for video $videoId to $isDismissed");
    final int? dismissalTimestamp = isDismissed ? DateTime.now().millisecondsSinceEpoch : null;
    return _db.updateDismissalStatusInternal(videoId, dismissalTimestamp);
  }
}
