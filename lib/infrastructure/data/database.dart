import 'dart:io';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';

part 'database.g.dart';

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String? fromDb) {
    if (fromDb == null || fromDb.isEmpty) {
      return [];
    }
    try {
      final decoded = json.decode(fromDb);
      if (decoded is List) {
        return List<String>.from(decoded.map((item) => item.toString()));
      }
      if (kDebugMode) {
        print("StringListConverter WARN: Decoded DB value is not a List: $fromDb");
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print("StringListConverter ERROR decoding from DB: $e, value: $fromDb");
      }
      return [];
    }
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

@DataClassName('CachedVideo')
class CachedVideos extends Table {
  TextColumn get videoId => text().named('video_id')();
  TextColumn get channelId => text().named('channel_id').withDefault(const Constant('Unknown'))();
  TextColumn? get topicId => text().named('topic_id').nullable()();
  TextColumn get status => text().named('status')();
  TextColumn? get startScheduled => text().named('start_scheduled').nullable()();
  TextColumn? get startActual => text().named('start_actual').nullable()();
  TextColumn get availableAt => text().named('available_at')();
  TextColumn? get videoType => text().named('video_type').nullable()();
  TextColumn? get thumbnailUrl => text().named('thumbnail_url').nullable()();
  TextColumn? get certainty => text().named('certainty').nullable()();
  TextColumn get mentionedChannelIds => text().named('mentioned_channel_ids').map(const StringListConverter()).withDefault(const Constant('[]'))();
  TextColumn get videoTitle => text().named('video_title').withDefault(const Constant('Unknown Title'))();
  TextColumn get channelName => text().named('channel_name').withDefault(const Constant('Unknown Channel'))();
  TextColumn? get channelAvatarUrl => text().named('channel_avatar_url').nullable()();

  BoolColumn get isPendingNewMediaNotification => boolean().named('is_pending_new_media_notification').withDefault(const Constant(false))();
  IntColumn get lastSeenTimestamp => integer().named('last_seen_timestamp')();
  IntColumn? get scheduledLiveNotificationId => integer().named('scheduled_live_notification_id').nullable()();
  IntColumn? get lastLiveNotificationSentTime => integer().named('last_live_notification_sent_time').nullable()();
  IntColumn? get scheduledReminderNotificationId => integer().named('scheduled_reminder_notification_id').nullable()();
  IntColumn? get scheduledReminderTime => integer().named('scheduled_reminder_time').nullable()();

  IntColumn? get userDismissedAt => integer().named('user_dismissed_at').nullable()();

  TextColumn get sentMentionTargetIds => text().named('sent_mention_target_ids').map(const StringListConverter()).withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {videoId};
}

@DataClassName('ChannelNameCacheEntry')
class ChannelNameCache extends Table {
  TextColumn get channelId => text().named('channel_id')();
  TextColumn get channelName => text().named('channel_name')();
  IntColumn get lastUpdated => integer().named('last_updated')();

  @override
  Set<Column> get primaryKey => {channelId};
}

@DriftDatabase(tables: [CachedVideos, ChannelNameCache])
class AppDatabase extends _$AppDatabase {
  final ILoggingService _logger;
  AppDatabase(super.e, this._logger);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      _logger.info("Drift DB onCreate: Creating all tables for schema v$schemaVersion...");
      await m.createAll();
      _logger.info("Drift DB onCreate: Tables created.");
    },
    onUpgrade: (Migrator m, int from, int to) async {
      _logger.info("Drift DB onUpgrade: Upgrading schema from v$from to v$to...");
      for (int targetVersion = from + 1; targetVersion <= to; targetVersion++) {
        _logger.info("Drift DB onUpgrade: Applying migration to v$targetVersion...");
        switch (targetVersion) {
          case 2:
            await m.createTable(channelNameCache);
            _logger.info("Drift DB Migration V2: Created channelNameCache table.");
            break;
          default:
            _logger.warning("Drift DB onUpgrade: No migration logic defined for v$targetVersion");
        }
        _logger.info("Drift DB onUpgrade: Migration to v$targetVersion applied.");
      }
    },
    beforeOpen: (details) async {
      _logger.info(
        "Drift DB: Opening database. Was Created: ${details.wasCreated}, Version Before: ${details.versionBefore}, Current Version: ${details.versionNow}",
      );

      await customStatement('PRAGMA journal_mode=WAL;');
      await customStatement('PRAGMA foreign_keys = ON;');
    },
  );

  Future<CachedVideo?> getVideo(String id) {
    return (select(cachedVideos)..where((t) => t.videoId.equals(id))).getSingleOrNull();
  }

  Future<int> countScheduledVideosInternal() async {
    final count =
        await customSelect(
          'SELECT COUNT(*) FROM cached_videos WHERE (scheduled_live_notification_id IS NOT NULL OR scheduled_reminder_notification_id IS NOT NULL) AND user_dismissed_at IS NULL;',
          readsFrom: {cachedVideos},
        ).getSingle();
    return count.data.values.first as int;
  }

  Future<void> upsertVideo(CachedVideosCompanion entry) {
    return into(cachedVideos).insertOnConflictUpdate(entry);
  }

  Future<void> deleteVideo(String id) {
    return (delete(cachedVideos)..where((t) => t.videoId.equals(id))).go();
  }

  Future<List<CachedVideo>> getVideosByStatus(String statusFilter) {
    return (select(cachedVideos)..where((t) => t.status.equals(statusFilter))).get();
  }

  Future<List<CachedVideo>> getVideosMentioningChannelInternal(String channelId) {
    return (select(cachedVideos)..where((t) => t.mentionedChannelIds.like('%"$channelId"%'))).get();
  }

  Future<List<CachedVideo>> getVideosByChannelInternal(String channelId) {
    return (select(cachedVideos)..where((t) => t.channelId.equals(channelId))).get();
  }

  Future<List<CachedVideo>> getMembersOnlyVideosByChannelInternal(String channelIdFilter) {
    return (select(cachedVideos)..where((t) => t.channelId.equals(channelIdFilter) & t.topicId.equals('membersonly'))).get();
  }

  Future<List<CachedVideo>> getClipVideosByChannelInternal(String channelIdFilter) {
    return (select(cachedVideos)..where((t) => t.channelId.equals(channelIdFilter) & t.videoType.equals('clip'))).get();
  }

  Future<int> prunePastVideos() async {
    final count = await (delete(cachedVideos)..where((t) => t.status.equals('past'))).go();
    _logger.info("Pruned $count 'past' videos.");
    return count;
  }

  Future<int> pruneOldVideos(DateTime cutoff) async {
    final cutoffIso = cutoff.toIso8601String();
    final count = await (delete(cachedVideos)..where((t) => t.availableAt.isSmallerThanValue(cutoffIso))).go();
    _logger.info("Pruned $count videos older than $cutoffIso.");
    return count;
  }

  Future<void> updateVideoStatusInternal(String id, String newStatus) {
    return (update(cachedVideos)..where((t) => t.videoId.equals(id))).write(CachedVideosCompanion(status: Value(newStatus)));
  }

  Future<void> updateScheduledNotificationIdInternal(String id, int? notificationId) {
    return (update(cachedVideos)
      ..where((t) => t.videoId.equals(id))).write(CachedVideosCompanion(scheduledLiveNotificationId: Value(notificationId)));
  }

  Future<void> updateLastLiveNotificationTimeInternal(String id, DateTime? time) {
    final timestamp = time?.millisecondsSinceEpoch;
    return (update(cachedVideos)..where((t) => t.videoId.equals(id))).write(CachedVideosCompanion(lastLiveNotificationSentTime: Value(timestamp)));
  }

  Future<void> setPendingNewMediaFlagInternal(String id, bool isPending) {
    return (update(cachedVideos)..where((t) => t.videoId.equals(id))).write(CachedVideosCompanion(isPendingNewMediaNotification: Value(isPending)));
  }

  Future<List<CachedVideo>> getScheduledVideosInternal() {
    return (select(cachedVideos)
          ..where(
            (tbl) => (tbl.scheduledLiveNotificationId.isNotNull() | tbl.scheduledReminderNotificationId.isNotNull()) & tbl.userDismissedAt.isNull(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(
              CustomExpression<int>(
                "CASE WHEN scheduled_reminder_notification_id IS NOT NULL THEN scheduled_reminder_time ELSE CAST(strftime('%s', start_scheduled) * 1000 AS INTEGER) END",
                precedence: Precedence.primary,
              ),
            ),
          ]))
        .get();
  }

  Stream<List<CachedVideo>> watchScheduledVideosInternal() {
    return (select(cachedVideos)
          ..where(
            (tbl) => (tbl.scheduledLiveNotificationId.isNotNull() | tbl.scheduledReminderNotificationId.isNotNull()) & tbl.userDismissedAt.isNull(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(
              CustomExpression<int>(
                "CASE WHEN scheduled_reminder_notification_id IS NOT NULL THEN scheduled_reminder_time ELSE CAST(strftime('%s', start_scheduled) * 1000 AS INTEGER) END",
                precedence: Precedence.primary,
              ),
            ),
          ]))
        .watch();
  }

  Future<List<CachedVideo>> getVideosWithScheduledRemindersInternal() {
    return (select(cachedVideos)..where((tbl) => tbl.scheduledReminderNotificationId.isNotNull())).get();
  }

  Future<void> updateScheduledReminderNotificationIdInternal(String id, int? notificationId) {
    return (update(cachedVideos)
      ..where((t) => t.videoId.equals(id))).write(CachedVideosCompanion(scheduledReminderNotificationId: Value(notificationId)));
  }

  Future<void> updateScheduledReminderTimeInternal(String id, DateTime? time) {
    final timestamp = time?.millisecondsSinceEpoch;
    return (update(cachedVideos)..where((t) => t.videoId.equals(id))).write(CachedVideosCompanion(scheduledReminderTime: Value(timestamp)));
  }

  Future<List<CachedVideo>> getDismissedScheduledVideosInternal() {
    return (select(cachedVideos)
          ..where(
            (tbl) =>
                (tbl.scheduledLiveNotificationId.isNotNull() | tbl.scheduledReminderNotificationId.isNotNull()) & tbl.userDismissedAt.isNotNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.userDismissedAt)]))
        .get();
  }

  Future<void> updateDismissalStatusInternal(String videoId, int? dismissalTimestamp) {
    return (update(cachedVideos)..where((t) => t.videoId.equals(videoId))).write(CachedVideosCompanion(userDismissedAt: Value(dismissalTimestamp)));
  }

  Future<List<String>> getSentMentionTargetsInternal(String videoId) async {
    final video = await getVideo(videoId);
    return video?.sentMentionTargetIds ?? [];
  }

  Future<void> updateSentMentionTargetsInternal(String videoId, List<String> targetIds) {
    return (update(cachedVideos)..where((t) => t.videoId.equals(videoId))).write(CachedVideosCompanion(sentMentionTargetIds: Value(targetIds)));
  }

  Future<void> upsertChannelNames(List<ChannelNameCacheCompanion> entries) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(channelNameCache, entries);
    });
  }

  Future<String?> getChannelNameInternal(String channelId) async {
    final result = await (select(channelNameCache)..where((t) => t.channelId.equals(channelId))).getSingleOrNull();
    return result?.channelName;
  }
}

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'holodex_notifier_db.sqlite'));
    if (kDebugMode) {
      print("Database file path: ${file.path}");
    }
    return NativeDatabase.createInBackground(file, logStatements: kDebugMode);
  });
}
