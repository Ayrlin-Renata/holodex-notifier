part of 'database.dart';

class $CachedVideosTable extends CachedVideos with TableInfo<$CachedVideosTable, CachedVideo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedVideosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta('videoId');
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unknown'),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta('topicId');
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startScheduledMeta = const VerificationMeta('startScheduled');
  @override
  late final GeneratedColumn<String> startScheduled = GeneratedColumn<String>(
    'start_scheduled',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startActualMeta = const VerificationMeta('startActual');
  @override
  late final GeneratedColumn<String> startActual = GeneratedColumn<String>(
    'start_actual',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _availableAtMeta = const VerificationMeta('availableAt');
  @override
  late final GeneratedColumn<String> availableAt = GeneratedColumn<String>(
    'available_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoTypeMeta = const VerificationMeta('videoType');
  @override
  late final GeneratedColumn<String> videoType = GeneratedColumn<String>(
    'video_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certaintyMeta = const VerificationMeta('certainty');
  @override
  late final GeneratedColumn<String> certainty = GeneratedColumn<String>(
    'certainty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mentionedChannelIdsMeta = const VerificationMeta('mentionedChannelIds');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> mentionedChannelIds = GeneratedColumn<String>(
    'mentioned_channel_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<List<String>>($CachedVideosTable.$convertermentionedChannelIds);
  static const VerificationMeta _videoTitleMeta = const VerificationMeta('videoTitle');
  @override
  late final GeneratedColumn<String> videoTitle = GeneratedColumn<String>(
    'video_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unknown Title'),
  );
  static const VerificationMeta _channelNameMeta = const VerificationMeta('channelName');
  @override
  late final GeneratedColumn<String> channelName = GeneratedColumn<String>(
    'channel_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Unknown Channel'),
  );
  static const VerificationMeta _channelAvatarUrlMeta = const VerificationMeta('channelAvatarUrl');
  @override
  late final GeneratedColumn<String> channelAvatarUrl = GeneratedColumn<String>(
    'channel_avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPendingNewMediaNotificationMeta = const VerificationMeta('isPendingNewMediaNotification');
  @override
  late final GeneratedColumn<bool> isPendingNewMediaNotification = GeneratedColumn<bool>(
    'is_pending_new_media_notification',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_pending_new_media_notification" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSeenTimestampMeta = const VerificationMeta('lastSeenTimestamp');
  @override
  late final GeneratedColumn<int> lastSeenTimestamp = GeneratedColumn<int>(
    'last_seen_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledLiveNotificationIdMeta = const VerificationMeta('scheduledLiveNotificationId');
  @override
  late final GeneratedColumn<int> scheduledLiveNotificationId = GeneratedColumn<int>(
    'scheduled_live_notification_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastLiveNotificationSentTimeMeta = const VerificationMeta('lastLiveNotificationSentTime');
  @override
  late final GeneratedColumn<int> lastLiveNotificationSentTime = GeneratedColumn<int>(
    'last_live_notification_sent_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledReminderNotificationIdMeta = const VerificationMeta('scheduledReminderNotificationId');
  @override
  late final GeneratedColumn<int> scheduledReminderNotificationId = GeneratedColumn<int>(
    'scheduled_reminder_notification_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledReminderTimeMeta = const VerificationMeta('scheduledReminderTime');
  @override
  late final GeneratedColumn<int> scheduledReminderTime = GeneratedColumn<int>(
    'scheduled_reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    videoId,
    channelId,
    topicId,
    status,
    startScheduled,
    startActual,
    availableAt,
    videoType,
    certainty,
    mentionedChannelIds,
    videoTitle,
    channelName,
    channelAvatarUrl,
    isPendingNewMediaNotification,
    lastSeenTimestamp,
    scheduledLiveNotificationId,
    lastLiveNotificationSentTime,
    scheduledReminderNotificationId,
    scheduledReminderTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_videos';
  @override
  VerificationContext validateIntegrity(Insertable<CachedVideo> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(_videoIdMeta, videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta));
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta, channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(_topicIdMeta, topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('start_scheduled')) {
      context.handle(_startScheduledMeta, startScheduled.isAcceptableOrUnknown(data['start_scheduled']!, _startScheduledMeta));
    }
    if (data.containsKey('start_actual')) {
      context.handle(_startActualMeta, startActual.isAcceptableOrUnknown(data['start_actual']!, _startActualMeta));
    }
    if (data.containsKey('available_at')) {
      context.handle(_availableAtMeta, availableAt.isAcceptableOrUnknown(data['available_at']!, _availableAtMeta));
    } else if (isInserting) {
      context.missing(_availableAtMeta);
    }
    if (data.containsKey('video_type')) {
      context.handle(_videoTypeMeta, videoType.isAcceptableOrUnknown(data['video_type']!, _videoTypeMeta));
    }
    if (data.containsKey('certainty')) {
      context.handle(_certaintyMeta, certainty.isAcceptableOrUnknown(data['certainty']!, _certaintyMeta));
    }
    context.handle(_mentionedChannelIdsMeta, const VerificationResult.success());
    if (data.containsKey('video_title')) {
      context.handle(_videoTitleMeta, videoTitle.isAcceptableOrUnknown(data['video_title']!, _videoTitleMeta));
    }
    if (data.containsKey('channel_name')) {
      context.handle(_channelNameMeta, channelName.isAcceptableOrUnknown(data['channel_name']!, _channelNameMeta));
    }
    if (data.containsKey('channel_avatar_url')) {
      context.handle(_channelAvatarUrlMeta, channelAvatarUrl.isAcceptableOrUnknown(data['channel_avatar_url']!, _channelAvatarUrlMeta));
    }
    if (data.containsKey('is_pending_new_media_notification')) {
      context.handle(
        _isPendingNewMediaNotificationMeta,
        isPendingNewMediaNotification.isAcceptableOrUnknown(data['is_pending_new_media_notification']!, _isPendingNewMediaNotificationMeta),
      );
    }
    if (data.containsKey('last_seen_timestamp')) {
      context.handle(_lastSeenTimestampMeta, lastSeenTimestamp.isAcceptableOrUnknown(data['last_seen_timestamp']!, _lastSeenTimestampMeta));
    } else if (isInserting) {
      context.missing(_lastSeenTimestampMeta);
    }
    if (data.containsKey('scheduled_live_notification_id')) {
      context.handle(
        _scheduledLiveNotificationIdMeta,
        scheduledLiveNotificationId.isAcceptableOrUnknown(data['scheduled_live_notification_id']!, _scheduledLiveNotificationIdMeta),
      );
    }
    if (data.containsKey('last_live_notification_sent_time')) {
      context.handle(
        _lastLiveNotificationSentTimeMeta,
        lastLiveNotificationSentTime.isAcceptableOrUnknown(data['last_live_notification_sent_time']!, _lastLiveNotificationSentTimeMeta),
      );
    }
    if (data.containsKey('scheduled_reminder_notification_id')) {
      context.handle(
        _scheduledReminderNotificationIdMeta,
        scheduledReminderNotificationId.isAcceptableOrUnknown(data['scheduled_reminder_notification_id']!, _scheduledReminderNotificationIdMeta),
      );
    }
    if (data.containsKey('scheduled_reminder_time')) {
      context.handle(
        _scheduledReminderTimeMeta,
        scheduledReminderTime.isAcceptableOrUnknown(data['scheduled_reminder_time']!, _scheduledReminderTimeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId};
  @override
  CachedVideo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedVideo(
      videoId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_id'])!,
      channelId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_id'])!,
      topicId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}topic_id']),
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      startScheduled: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}start_scheduled']),
      startActual: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}start_actual']),
      availableAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}available_at'])!,
      videoType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_type']),
      certainty: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}certainty']),
      mentionedChannelIds: $CachedVideosTable.$convertermentionedChannelIds.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}mentioned_channel_ids'])!,
      ),
      videoTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_title'])!,
      channelName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_name'])!,
      channelAvatarUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}channel_avatar_url']),
      isPendingNewMediaNotification:
          attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_pending_new_media_notification'])!,
      lastSeenTimestamp: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}last_seen_timestamp'])!,
      scheduledLiveNotificationId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}scheduled_live_notification_id']),
      lastLiveNotificationSentTime: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}last_live_notification_sent_time']),
      scheduledReminderNotificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_reminder_notification_id'],
      ),
      scheduledReminderTime: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}scheduled_reminder_time']),
    );
  }

  @override
  $CachedVideosTable createAlias(String alias) {
    return $CachedVideosTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertermentionedChannelIds = const StringListConverter();
}

class CachedVideo extends DataClass implements Insertable<CachedVideo> {
  final String videoId;
  final String channelId;
  final String? topicId;
  final String status;
  final String? startScheduled;
  final String? startActual;
  final String availableAt;
  final String? videoType;
  final String? certainty;
  final List<String> mentionedChannelIds;
  final String videoTitle;
  final String channelName;
  final String? channelAvatarUrl;
  final bool isPendingNewMediaNotification;
  final int lastSeenTimestamp;
  final int? scheduledLiveNotificationId;
  final int? lastLiveNotificationSentTime;
  final int? scheduledReminderNotificationId;
  final int? scheduledReminderTime;
  const CachedVideo({
    required this.videoId,
    required this.channelId,
    this.topicId,
    required this.status,
    this.startScheduled,
    this.startActual,
    required this.availableAt,
    this.videoType,
    this.certainty,
    required this.mentionedChannelIds,
    required this.videoTitle,
    required this.channelName,
    this.channelAvatarUrl,
    required this.isPendingNewMediaNotification,
    required this.lastSeenTimestamp,
    this.scheduledLiveNotificationId,
    this.lastLiveNotificationSentTime,
    this.scheduledReminderNotificationId,
    this.scheduledReminderTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['channel_id'] = Variable<String>(channelId);
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<String>(topicId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || startScheduled != null) {
      map['start_scheduled'] = Variable<String>(startScheduled);
    }
    if (!nullToAbsent || startActual != null) {
      map['start_actual'] = Variable<String>(startActual);
    }
    map['available_at'] = Variable<String>(availableAt);
    if (!nullToAbsent || videoType != null) {
      map['video_type'] = Variable<String>(videoType);
    }
    if (!nullToAbsent || certainty != null) {
      map['certainty'] = Variable<String>(certainty);
    }
    {
      map['mentioned_channel_ids'] = Variable<String>($CachedVideosTable.$convertermentionedChannelIds.toSql(mentionedChannelIds));
    }
    map['video_title'] = Variable<String>(videoTitle);
    map['channel_name'] = Variable<String>(channelName);
    if (!nullToAbsent || channelAvatarUrl != null) {
      map['channel_avatar_url'] = Variable<String>(channelAvatarUrl);
    }
    map['is_pending_new_media_notification'] = Variable<bool>(isPendingNewMediaNotification);
    map['last_seen_timestamp'] = Variable<int>(lastSeenTimestamp);
    if (!nullToAbsent || scheduledLiveNotificationId != null) {
      map['scheduled_live_notification_id'] = Variable<int>(scheduledLiveNotificationId);
    }
    if (!nullToAbsent || lastLiveNotificationSentTime != null) {
      map['last_live_notification_sent_time'] = Variable<int>(lastLiveNotificationSentTime);
    }
    if (!nullToAbsent || scheduledReminderNotificationId != null) {
      map['scheduled_reminder_notification_id'] = Variable<int>(scheduledReminderNotificationId);
    }
    if (!nullToAbsent || scheduledReminderTime != null) {
      map['scheduled_reminder_time'] = Variable<int>(scheduledReminderTime);
    }
    return map;
  }

  CachedVideosCompanion toCompanion(bool nullToAbsent) {
    return CachedVideosCompanion(
      videoId: Value(videoId),
      channelId: Value(channelId),
      topicId: topicId == null && nullToAbsent ? const Value.absent() : Value(topicId),
      status: Value(status),
      startScheduled: startScheduled == null && nullToAbsent ? const Value.absent() : Value(startScheduled),
      startActual: startActual == null && nullToAbsent ? const Value.absent() : Value(startActual),
      availableAt: Value(availableAt),
      videoType: videoType == null && nullToAbsent ? const Value.absent() : Value(videoType),
      certainty: certainty == null && nullToAbsent ? const Value.absent() : Value(certainty),
      mentionedChannelIds: Value(mentionedChannelIds),
      videoTitle: Value(videoTitle),
      channelName: Value(channelName),
      channelAvatarUrl: channelAvatarUrl == null && nullToAbsent ? const Value.absent() : Value(channelAvatarUrl),
      isPendingNewMediaNotification: Value(isPendingNewMediaNotification),
      lastSeenTimestamp: Value(lastSeenTimestamp),
      scheduledLiveNotificationId: scheduledLiveNotificationId == null && nullToAbsent ? const Value.absent() : Value(scheduledLiveNotificationId),
      lastLiveNotificationSentTime: lastLiveNotificationSentTime == null && nullToAbsent ? const Value.absent() : Value(lastLiveNotificationSentTime),
      scheduledReminderNotificationId:
          scheduledReminderNotificationId == null && nullToAbsent ? const Value.absent() : Value(scheduledReminderNotificationId),
      scheduledReminderTime: scheduledReminderTime == null && nullToAbsent ? const Value.absent() : Value(scheduledReminderTime),
    );
  }

  factory CachedVideo.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedVideo(
      videoId: serializer.fromJson<String>(json['videoId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      topicId: serializer.fromJson<String?>(json['topicId']),
      status: serializer.fromJson<String>(json['status']),
      startScheduled: serializer.fromJson<String?>(json['startScheduled']),
      startActual: serializer.fromJson<String?>(json['startActual']),
      availableAt: serializer.fromJson<String>(json['availableAt']),
      videoType: serializer.fromJson<String?>(json['videoType']),
      certainty: serializer.fromJson<String?>(json['certainty']),
      mentionedChannelIds: serializer.fromJson<List<String>>(json['mentionedChannelIds']),
      videoTitle: serializer.fromJson<String>(json['videoTitle']),
      channelName: serializer.fromJson<String>(json['channelName']),
      channelAvatarUrl: serializer.fromJson<String?>(json['channelAvatarUrl']),
      isPendingNewMediaNotification: serializer.fromJson<bool>(json['isPendingNewMediaNotification']),
      lastSeenTimestamp: serializer.fromJson<int>(json['lastSeenTimestamp']),
      scheduledLiveNotificationId: serializer.fromJson<int?>(json['scheduledLiveNotificationId']),
      lastLiveNotificationSentTime: serializer.fromJson<int?>(json['lastLiveNotificationSentTime']),
      scheduledReminderNotificationId: serializer.fromJson<int?>(json['scheduledReminderNotificationId']),
      scheduledReminderTime: serializer.fromJson<int?>(json['scheduledReminderTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'channelId': serializer.toJson<String>(channelId),
      'topicId': serializer.toJson<String?>(topicId),
      'status': serializer.toJson<String>(status),
      'startScheduled': serializer.toJson<String?>(startScheduled),
      'startActual': serializer.toJson<String?>(startActual),
      'availableAt': serializer.toJson<String>(availableAt),
      'videoType': serializer.toJson<String?>(videoType),
      'certainty': serializer.toJson<String?>(certainty),
      'mentionedChannelIds': serializer.toJson<List<String>>(mentionedChannelIds),
      'videoTitle': serializer.toJson<String>(videoTitle),
      'channelName': serializer.toJson<String>(channelName),
      'channelAvatarUrl': serializer.toJson<String?>(channelAvatarUrl),
      'isPendingNewMediaNotification': serializer.toJson<bool>(isPendingNewMediaNotification),
      'lastSeenTimestamp': serializer.toJson<int>(lastSeenTimestamp),
      'scheduledLiveNotificationId': serializer.toJson<int?>(scheduledLiveNotificationId),
      'lastLiveNotificationSentTime': serializer.toJson<int?>(lastLiveNotificationSentTime),
      'scheduledReminderNotificationId': serializer.toJson<int?>(scheduledReminderNotificationId),
      'scheduledReminderTime': serializer.toJson<int?>(scheduledReminderTime),
    };
  }

  CachedVideo copyWith({
    String? videoId,
    String? channelId,
    Value<String?> topicId = const Value.absent(),
    String? status,
    Value<String?> startScheduled = const Value.absent(),
    Value<String?> startActual = const Value.absent(),
    String? availableAt,
    Value<String?> videoType = const Value.absent(),
    Value<String?> certainty = const Value.absent(),
    List<String>? mentionedChannelIds,
    String? videoTitle,
    String? channelName,
    Value<String?> channelAvatarUrl = const Value.absent(),
    bool? isPendingNewMediaNotification,
    int? lastSeenTimestamp,
    Value<int?> scheduledLiveNotificationId = const Value.absent(),
    Value<int?> lastLiveNotificationSentTime = const Value.absent(),
    Value<int?> scheduledReminderNotificationId = const Value.absent(),
    Value<int?> scheduledReminderTime = const Value.absent(),
  }) => CachedVideo(
    videoId: videoId ?? this.videoId,
    channelId: channelId ?? this.channelId,
    topicId: topicId.present ? topicId.value : this.topicId,
    status: status ?? this.status,
    startScheduled: startScheduled.present ? startScheduled.value : this.startScheduled,
    startActual: startActual.present ? startActual.value : this.startActual,
    availableAt: availableAt ?? this.availableAt,
    videoType: videoType.present ? videoType.value : this.videoType,
    certainty: certainty.present ? certainty.value : this.certainty,
    mentionedChannelIds: mentionedChannelIds ?? this.mentionedChannelIds,
    videoTitle: videoTitle ?? this.videoTitle,
    channelName: channelName ?? this.channelName,
    channelAvatarUrl: channelAvatarUrl.present ? channelAvatarUrl.value : this.channelAvatarUrl,
    isPendingNewMediaNotification: isPendingNewMediaNotification ?? this.isPendingNewMediaNotification,
    lastSeenTimestamp: lastSeenTimestamp ?? this.lastSeenTimestamp,
    scheduledLiveNotificationId: scheduledLiveNotificationId.present ? scheduledLiveNotificationId.value : this.scheduledLiveNotificationId,
    lastLiveNotificationSentTime: lastLiveNotificationSentTime.present ? lastLiveNotificationSentTime.value : this.lastLiveNotificationSentTime,
    scheduledReminderNotificationId:
        scheduledReminderNotificationId.present ? scheduledReminderNotificationId.value : this.scheduledReminderNotificationId,
    scheduledReminderTime: scheduledReminderTime.present ? scheduledReminderTime.value : this.scheduledReminderTime,
  );
  CachedVideo copyWithCompanion(CachedVideosCompanion data) {
    return CachedVideo(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      status: data.status.present ? data.status.value : this.status,
      startScheduled: data.startScheduled.present ? data.startScheduled.value : this.startScheduled,
      startActual: data.startActual.present ? data.startActual.value : this.startActual,
      availableAt: data.availableAt.present ? data.availableAt.value : this.availableAt,
      videoType: data.videoType.present ? data.videoType.value : this.videoType,
      certainty: data.certainty.present ? data.certainty.value : this.certainty,
      mentionedChannelIds: data.mentionedChannelIds.present ? data.mentionedChannelIds.value : this.mentionedChannelIds,
      videoTitle: data.videoTitle.present ? data.videoTitle.value : this.videoTitle,
      channelName: data.channelName.present ? data.channelName.value : this.channelName,
      channelAvatarUrl: data.channelAvatarUrl.present ? data.channelAvatarUrl.value : this.channelAvatarUrl,
      isPendingNewMediaNotification:
          data.isPendingNewMediaNotification.present ? data.isPendingNewMediaNotification.value : this.isPendingNewMediaNotification,
      lastSeenTimestamp: data.lastSeenTimestamp.present ? data.lastSeenTimestamp.value : this.lastSeenTimestamp,
      scheduledLiveNotificationId:
          data.scheduledLiveNotificationId.present ? data.scheduledLiveNotificationId.value : this.scheduledLiveNotificationId,
      lastLiveNotificationSentTime:
          data.lastLiveNotificationSentTime.present ? data.lastLiveNotificationSentTime.value : this.lastLiveNotificationSentTime,
      scheduledReminderNotificationId:
          data.scheduledReminderNotificationId.present ? data.scheduledReminderNotificationId.value : this.scheduledReminderNotificationId,
      scheduledReminderTime: data.scheduledReminderTime.present ? data.scheduledReminderTime.value : this.scheduledReminderTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedVideo(')
          ..write('videoId: $videoId, ')
          ..write('channelId: $channelId, ')
          ..write('topicId: $topicId, ')
          ..write('status: $status, ')
          ..write('startScheduled: $startScheduled, ')
          ..write('startActual: $startActual, ')
          ..write('availableAt: $availableAt, ')
          ..write('videoType: $videoType, ')
          ..write('certainty: $certainty, ')
          ..write('mentionedChannelIds: $mentionedChannelIds, ')
          ..write('videoTitle: $videoTitle, ')
          ..write('channelName: $channelName, ')
          ..write('channelAvatarUrl: $channelAvatarUrl, ')
          ..write('isPendingNewMediaNotification: $isPendingNewMediaNotification, ')
          ..write('lastSeenTimestamp: $lastSeenTimestamp, ')
          ..write('scheduledLiveNotificationId: $scheduledLiveNotificationId, ')
          ..write('lastLiveNotificationSentTime: $lastLiveNotificationSentTime, ')
          ..write('scheduledReminderNotificationId: $scheduledReminderNotificationId, ')
          ..write('scheduledReminderTime: $scheduledReminderTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    videoId,
    channelId,
    topicId,
    status,
    startScheduled,
    startActual,
    availableAt,
    videoType,
    certainty,
    mentionedChannelIds,
    videoTitle,
    channelName,
    channelAvatarUrl,
    isPendingNewMediaNotification,
    lastSeenTimestamp,
    scheduledLiveNotificationId,
    lastLiveNotificationSentTime,
    scheduledReminderNotificationId,
    scheduledReminderTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedVideo &&
          other.videoId == this.videoId &&
          other.channelId == this.channelId &&
          other.topicId == this.topicId &&
          other.status == this.status &&
          other.startScheduled == this.startScheduled &&
          other.startActual == this.startActual &&
          other.availableAt == this.availableAt &&
          other.videoType == this.videoType &&
          other.certainty == this.certainty &&
          other.mentionedChannelIds == this.mentionedChannelIds &&
          other.videoTitle == this.videoTitle &&
          other.channelName == this.channelName &&
          other.channelAvatarUrl == this.channelAvatarUrl &&
          other.isPendingNewMediaNotification == this.isPendingNewMediaNotification &&
          other.lastSeenTimestamp == this.lastSeenTimestamp &&
          other.scheduledLiveNotificationId == this.scheduledLiveNotificationId &&
          other.lastLiveNotificationSentTime == this.lastLiveNotificationSentTime &&
          other.scheduledReminderNotificationId == this.scheduledReminderNotificationId &&
          other.scheduledReminderTime == this.scheduledReminderTime);
}

class CachedVideosCompanion extends UpdateCompanion<CachedVideo> {
  final Value<String> videoId;
  final Value<String> channelId;
  final Value<String?> topicId;
  final Value<String> status;
  final Value<String?> startScheduled;
  final Value<String?> startActual;
  final Value<String> availableAt;
  final Value<String?> videoType;
  final Value<String?> certainty;
  final Value<List<String>> mentionedChannelIds;
  final Value<String> videoTitle;
  final Value<String> channelName;
  final Value<String?> channelAvatarUrl;
  final Value<bool> isPendingNewMediaNotification;
  final Value<int> lastSeenTimestamp;
  final Value<int?> scheduledLiveNotificationId;
  final Value<int?> lastLiveNotificationSentTime;
  final Value<int?> scheduledReminderNotificationId;
  final Value<int?> scheduledReminderTime;
  final Value<int> rowid;
  const CachedVideosCompanion({
    this.videoId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.status = const Value.absent(),
    this.startScheduled = const Value.absent(),
    this.startActual = const Value.absent(),
    this.availableAt = const Value.absent(),
    this.videoType = const Value.absent(),
    this.certainty = const Value.absent(),
    this.mentionedChannelIds = const Value.absent(),
    this.videoTitle = const Value.absent(),
    this.channelName = const Value.absent(),
    this.channelAvatarUrl = const Value.absent(),
    this.isPendingNewMediaNotification = const Value.absent(),
    this.lastSeenTimestamp = const Value.absent(),
    this.scheduledLiveNotificationId = const Value.absent(),
    this.lastLiveNotificationSentTime = const Value.absent(),
    this.scheduledReminderNotificationId = const Value.absent(),
    this.scheduledReminderTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedVideosCompanion.insert({
    required String videoId,
    this.channelId = const Value.absent(),
    this.topicId = const Value.absent(),
    required String status,
    this.startScheduled = const Value.absent(),
    this.startActual = const Value.absent(),
    required String availableAt,
    this.videoType = const Value.absent(),
    this.certainty = const Value.absent(),
    this.mentionedChannelIds = const Value.absent(),
    this.videoTitle = const Value.absent(),
    this.channelName = const Value.absent(),
    this.channelAvatarUrl = const Value.absent(),
    this.isPendingNewMediaNotification = const Value.absent(),
    required int lastSeenTimestamp,
    this.scheduledLiveNotificationId = const Value.absent(),
    this.lastLiveNotificationSentTime = const Value.absent(),
    this.scheduledReminderNotificationId = const Value.absent(),
    this.scheduledReminderTime = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       status = Value(status),
       availableAt = Value(availableAt),
       lastSeenTimestamp = Value(lastSeenTimestamp);
  static Insertable<CachedVideo> custom({
    Expression<String>? videoId,
    Expression<String>? channelId,
    Expression<String>? topicId,
    Expression<String>? status,
    Expression<String>? startScheduled,
    Expression<String>? startActual,
    Expression<String>? availableAt,
    Expression<String>? videoType,
    Expression<String>? certainty,
    Expression<String>? mentionedChannelIds,
    Expression<String>? videoTitle,
    Expression<String>? channelName,
    Expression<String>? channelAvatarUrl,
    Expression<bool>? isPendingNewMediaNotification,
    Expression<int>? lastSeenTimestamp,
    Expression<int>? scheduledLiveNotificationId,
    Expression<int>? lastLiveNotificationSentTime,
    Expression<int>? scheduledReminderNotificationId,
    Expression<int>? scheduledReminderTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (channelId != null) 'channel_id': channelId,
      if (topicId != null) 'topic_id': topicId,
      if (status != null) 'status': status,
      if (startScheduled != null) 'start_scheduled': startScheduled,
      if (startActual != null) 'start_actual': startActual,
      if (availableAt != null) 'available_at': availableAt,
      if (videoType != null) 'video_type': videoType,
      if (certainty != null) 'certainty': certainty,
      if (mentionedChannelIds != null) 'mentioned_channel_ids': mentionedChannelIds,
      if (videoTitle != null) 'video_title': videoTitle,
      if (channelName != null) 'channel_name': channelName,
      if (channelAvatarUrl != null) 'channel_avatar_url': channelAvatarUrl,
      if (isPendingNewMediaNotification != null) 'is_pending_new_media_notification': isPendingNewMediaNotification,
      if (lastSeenTimestamp != null) 'last_seen_timestamp': lastSeenTimestamp,
      if (scheduledLiveNotificationId != null) 'scheduled_live_notification_id': scheduledLiveNotificationId,
      if (lastLiveNotificationSentTime != null) 'last_live_notification_sent_time': lastLiveNotificationSentTime,
      if (scheduledReminderNotificationId != null) 'scheduled_reminder_notification_id': scheduledReminderNotificationId,
      if (scheduledReminderTime != null) 'scheduled_reminder_time': scheduledReminderTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedVideosCompanion copyWith({
    Value<String>? videoId,
    Value<String>? channelId,
    Value<String?>? topicId,
    Value<String>? status,
    Value<String?>? startScheduled,
    Value<String?>? startActual,
    Value<String>? availableAt,
    Value<String?>? videoType,
    Value<String?>? certainty,
    Value<List<String>>? mentionedChannelIds,
    Value<String>? videoTitle,
    Value<String>? channelName,
    Value<String?>? channelAvatarUrl,
    Value<bool>? isPendingNewMediaNotification,
    Value<int>? lastSeenTimestamp,
    Value<int?>? scheduledLiveNotificationId,
    Value<int?>? lastLiveNotificationSentTime,
    Value<int?>? scheduledReminderNotificationId,
    Value<int?>? scheduledReminderTime,
    Value<int>? rowid,
  }) {
    return CachedVideosCompanion(
      videoId: videoId ?? this.videoId,
      channelId: channelId ?? this.channelId,
      topicId: topicId ?? this.topicId,
      status: status ?? this.status,
      startScheduled: startScheduled ?? this.startScheduled,
      startActual: startActual ?? this.startActual,
      availableAt: availableAt ?? this.availableAt,
      videoType: videoType ?? this.videoType,
      certainty: certainty ?? this.certainty,
      mentionedChannelIds: mentionedChannelIds ?? this.mentionedChannelIds,
      videoTitle: videoTitle ?? this.videoTitle,
      channelName: channelName ?? this.channelName,
      channelAvatarUrl: channelAvatarUrl ?? this.channelAvatarUrl,
      isPendingNewMediaNotification: isPendingNewMediaNotification ?? this.isPendingNewMediaNotification,
      lastSeenTimestamp: lastSeenTimestamp ?? this.lastSeenTimestamp,
      scheduledLiveNotificationId: scheduledLiveNotificationId ?? this.scheduledLiveNotificationId,
      lastLiveNotificationSentTime: lastLiveNotificationSentTime ?? this.lastLiveNotificationSentTime,
      scheduledReminderNotificationId: scheduledReminderNotificationId ?? this.scheduledReminderNotificationId,
      scheduledReminderTime: scheduledReminderTime ?? this.scheduledReminderTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startScheduled.present) {
      map['start_scheduled'] = Variable<String>(startScheduled.value);
    }
    if (startActual.present) {
      map['start_actual'] = Variable<String>(startActual.value);
    }
    if (availableAt.present) {
      map['available_at'] = Variable<String>(availableAt.value);
    }
    if (videoType.present) {
      map['video_type'] = Variable<String>(videoType.value);
    }
    if (certainty.present) {
      map['certainty'] = Variable<String>(certainty.value);
    }
    if (mentionedChannelIds.present) {
      map['mentioned_channel_ids'] = Variable<String>($CachedVideosTable.$convertermentionedChannelIds.toSql(mentionedChannelIds.value));
    }
    if (videoTitle.present) {
      map['video_title'] = Variable<String>(videoTitle.value);
    }
    if (channelName.present) {
      map['channel_name'] = Variable<String>(channelName.value);
    }
    if (channelAvatarUrl.present) {
      map['channel_avatar_url'] = Variable<String>(channelAvatarUrl.value);
    }
    if (isPendingNewMediaNotification.present) {
      map['is_pending_new_media_notification'] = Variable<bool>(isPendingNewMediaNotification.value);
    }
    if (lastSeenTimestamp.present) {
      map['last_seen_timestamp'] = Variable<int>(lastSeenTimestamp.value);
    }
    if (scheduledLiveNotificationId.present) {
      map['scheduled_live_notification_id'] = Variable<int>(scheduledLiveNotificationId.value);
    }
    if (lastLiveNotificationSentTime.present) {
      map['last_live_notification_sent_time'] = Variable<int>(lastLiveNotificationSentTime.value);
    }
    if (scheduledReminderNotificationId.present) {
      map['scheduled_reminder_notification_id'] = Variable<int>(scheduledReminderNotificationId.value);
    }
    if (scheduledReminderTime.present) {
      map['scheduled_reminder_time'] = Variable<int>(scheduledReminderTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedVideosCompanion(')
          ..write('videoId: $videoId, ')
          ..write('channelId: $channelId, ')
          ..write('topicId: $topicId, ')
          ..write('status: $status, ')
          ..write('startScheduled: $startScheduled, ')
          ..write('startActual: $startActual, ')
          ..write('availableAt: $availableAt, ')
          ..write('videoType: $videoType, ')
          ..write('certainty: $certainty, ')
          ..write('mentionedChannelIds: $mentionedChannelIds, ')
          ..write('videoTitle: $videoTitle, ')
          ..write('channelName: $channelName, ')
          ..write('channelAvatarUrl: $channelAvatarUrl, ')
          ..write('isPendingNewMediaNotification: $isPendingNewMediaNotification, ')
          ..write('lastSeenTimestamp: $lastSeenTimestamp, ')
          ..write('scheduledLiveNotificationId: $scheduledLiveNotificationId, ')
          ..write('lastLiveNotificationSentTime: $lastLiveNotificationSentTime, ')
          ..write('scheduledReminderNotificationId: $scheduledReminderNotificationId, ')
          ..write('scheduledReminderTime: $scheduledReminderTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedVideosTable cachedVideos = $CachedVideosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cachedVideos];
}

typedef $$CachedVideosTableCreateCompanionBuilder =
    CachedVideosCompanion Function({
      required String videoId,
      Value<String> channelId,
      Value<String?> topicId,
      required String status,
      Value<String?> startScheduled,
      Value<String?> startActual,
      required String availableAt,
      Value<String?> videoType,
      Value<String?> certainty,
      Value<List<String>> mentionedChannelIds,
      Value<String> videoTitle,
      Value<String> channelName,
      Value<String?> channelAvatarUrl,
      Value<bool> isPendingNewMediaNotification,
      required int lastSeenTimestamp,
      Value<int?> scheduledLiveNotificationId,
      Value<int?> lastLiveNotificationSentTime,
      Value<int?> scheduledReminderNotificationId,
      Value<int?> scheduledReminderTime,
      Value<int> rowid,
    });
typedef $$CachedVideosTableUpdateCompanionBuilder =
    CachedVideosCompanion Function({
      Value<String> videoId,
      Value<String> channelId,
      Value<String?> topicId,
      Value<String> status,
      Value<String?> startScheduled,
      Value<String?> startActual,
      Value<String> availableAt,
      Value<String?> videoType,
      Value<String?> certainty,
      Value<List<String>> mentionedChannelIds,
      Value<String> videoTitle,
      Value<String> channelName,
      Value<String?> channelAvatarUrl,
      Value<bool> isPendingNewMediaNotification,
      Value<int> lastSeenTimestamp,
      Value<int?> scheduledLiveNotificationId,
      Value<int?> lastLiveNotificationSentTime,
      Value<int?> scheduledReminderNotificationId,
      Value<int?> scheduledReminderTime,
      Value<int> rowid,
    });

class $$CachedVideosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedVideosTable,
          CachedVideo,
          $$CachedVideosTableFilterComposer,
          $$CachedVideosTableOrderingComposer,
          $$CachedVideosTableCreateCompanionBuilder,
          $$CachedVideosTableUpdateCompanionBuilder
        > {
  $$CachedVideosTableTableManager(_$AppDatabase db, $CachedVideosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$CachedVideosTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$CachedVideosTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> startScheduled = const Value.absent(),
                Value<String?> startActual = const Value.absent(),
                Value<String> availableAt = const Value.absent(),
                Value<String?> videoType = const Value.absent(),
                Value<String?> certainty = const Value.absent(),
                Value<List<String>> mentionedChannelIds = const Value.absent(),
                Value<String> videoTitle = const Value.absent(),
                Value<String> channelName = const Value.absent(),
                Value<String?> channelAvatarUrl = const Value.absent(),
                Value<bool> isPendingNewMediaNotification = const Value.absent(),
                Value<int> lastSeenTimestamp = const Value.absent(),
                Value<int?> scheduledLiveNotificationId = const Value.absent(),
                Value<int?> lastLiveNotificationSentTime = const Value.absent(),
                Value<int?> scheduledReminderNotificationId = const Value.absent(),
                Value<int?> scheduledReminderTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedVideosCompanion(
                videoId: videoId,
                channelId: channelId,
                topicId: topicId,
                status: status,
                startScheduled: startScheduled,
                startActual: startActual,
                availableAt: availableAt,
                videoType: videoType,
                certainty: certainty,
                mentionedChannelIds: mentionedChannelIds,
                videoTitle: videoTitle,
                channelName: channelName,
                channelAvatarUrl: channelAvatarUrl,
                isPendingNewMediaNotification: isPendingNewMediaNotification,
                lastSeenTimestamp: lastSeenTimestamp,
                scheduledLiveNotificationId: scheduledLiveNotificationId,
                lastLiveNotificationSentTime: lastLiveNotificationSentTime,
                scheduledReminderNotificationId: scheduledReminderNotificationId,
                scheduledReminderTime: scheduledReminderTime,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                Value<String> channelId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                required String status,
                Value<String?> startScheduled = const Value.absent(),
                Value<String?> startActual = const Value.absent(),
                required String availableAt,
                Value<String?> videoType = const Value.absent(),
                Value<String?> certainty = const Value.absent(),
                Value<List<String>> mentionedChannelIds = const Value.absent(),
                Value<String> videoTitle = const Value.absent(),
                Value<String> channelName = const Value.absent(),
                Value<String?> channelAvatarUrl = const Value.absent(),
                Value<bool> isPendingNewMediaNotification = const Value.absent(),
                required int lastSeenTimestamp,
                Value<int?> scheduledLiveNotificationId = const Value.absent(),
                Value<int?> lastLiveNotificationSentTime = const Value.absent(),
                Value<int?> scheduledReminderNotificationId = const Value.absent(),
                Value<int?> scheduledReminderTime = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedVideosCompanion.insert(
                videoId: videoId,
                channelId: channelId,
                topicId: topicId,
                status: status,
                startScheduled: startScheduled,
                startActual: startActual,
                availableAt: availableAt,
                videoType: videoType,
                certainty: certainty,
                mentionedChannelIds: mentionedChannelIds,
                videoTitle: videoTitle,
                channelName: channelName,
                channelAvatarUrl: channelAvatarUrl,
                isPendingNewMediaNotification: isPendingNewMediaNotification,
                lastSeenTimestamp: lastSeenTimestamp,
                scheduledLiveNotificationId: scheduledLiveNotificationId,
                lastLiveNotificationSentTime: lastLiveNotificationSentTime,
                scheduledReminderNotificationId: scheduledReminderNotificationId,
                scheduledReminderTime: scheduledReminderTime,
                rowid: rowid,
              ),
        ),
      );
}

class $$CachedVideosTableFilterComposer extends FilterComposer<_$AppDatabase, $CachedVideosTable> {
  $$CachedVideosTableFilterComposer(super.$state);
  ColumnFilters<String> get videoId =>
      $state.composableBuilder(column: $state.table.videoId, builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get channelId =>
      $state.composableBuilder(column: $state.table.channelId, builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get topicId =>
      $state.composableBuilder(column: $state.table.topicId, builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status =>
      $state.composableBuilder(column: $state.table.status, builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get startScheduled => $state.composableBuilder(
    column: $state.table.startScheduled,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<String> get startActual => $state.composableBuilder(
    column: $state.table.startActual,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<String> get availableAt => $state.composableBuilder(
    column: $state.table.availableAt,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<String> get videoType =>
      $state.composableBuilder(column: $state.table.videoType, builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get certainty =>
      $state.composableBuilder(column: $state.table.certainty, builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get mentionedChannelIds => $state.composableBuilder(
    column: $state.table.mentionedChannelIds,
    builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<String> get videoTitle =>
      $state.composableBuilder(column: $state.table.videoTitle, builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get channelName => $state.composableBuilder(
    column: $state.table.channelName,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<String> get channelAvatarUrl => $state.composableBuilder(
    column: $state.table.channelAvatarUrl,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<bool> get isPendingNewMediaNotification => $state.composableBuilder(
    column: $state.table.isPendingNewMediaNotification,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<int> get lastSeenTimestamp => $state.composableBuilder(
    column: $state.table.lastSeenTimestamp,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<int> get scheduledLiveNotificationId => $state.composableBuilder(
    column: $state.table.scheduledLiveNotificationId,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<int> get lastLiveNotificationSentTime => $state.composableBuilder(
    column: $state.table.lastLiveNotificationSentTime,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<int> get scheduledReminderNotificationId => $state.composableBuilder(
    column: $state.table.scheduledReminderNotificationId,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );

  ColumnFilters<int> get scheduledReminderTime => $state.composableBuilder(
    column: $state.table.scheduledReminderTime,
    builder: (column, joinBuilders) => ColumnFilters(column, joinBuilders: joinBuilders),
  );
}

class $$CachedVideosTableOrderingComposer extends OrderingComposer<_$AppDatabase, $CachedVideosTable> {
  $$CachedVideosTableOrderingComposer(super.$state);
  ColumnOrderings<String> get videoId =>
      $state.composableBuilder(column: $state.table.videoId, builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get channelId => $state.composableBuilder(
    column: $state.table.channelId,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get topicId =>
      $state.composableBuilder(column: $state.table.topicId, builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status =>
      $state.composableBuilder(column: $state.table.status, builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get startScheduled => $state.composableBuilder(
    column: $state.table.startScheduled,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get startActual => $state.composableBuilder(
    column: $state.table.startActual,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get availableAt => $state.composableBuilder(
    column: $state.table.availableAt,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get videoType => $state.composableBuilder(
    column: $state.table.videoType,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get certainty => $state.composableBuilder(
    column: $state.table.certainty,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get mentionedChannelIds => $state.composableBuilder(
    column: $state.table.mentionedChannelIds,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get videoTitle => $state.composableBuilder(
    column: $state.table.videoTitle,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get channelName => $state.composableBuilder(
    column: $state.table.channelName,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<String> get channelAvatarUrl => $state.composableBuilder(
    column: $state.table.channelAvatarUrl,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<bool> get isPendingNewMediaNotification => $state.composableBuilder(
    column: $state.table.isPendingNewMediaNotification,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<int> get lastSeenTimestamp => $state.composableBuilder(
    column: $state.table.lastSeenTimestamp,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<int> get scheduledLiveNotificationId => $state.composableBuilder(
    column: $state.table.scheduledLiveNotificationId,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<int> get lastLiveNotificationSentTime => $state.composableBuilder(
    column: $state.table.lastLiveNotificationSentTime,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<int> get scheduledReminderNotificationId => $state.composableBuilder(
    column: $state.table.scheduledReminderNotificationId,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );

  ColumnOrderings<int> get scheduledReminderTime => $state.composableBuilder(
    column: $state.table.scheduledReminderTime,
    builder: (column, joinBuilders) => ColumnOrderings(column, joinBuilders: joinBuilders),
  );
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedVideosTableTableManager get cachedVideos => $$CachedVideosTableTableManager(_db, _db.cachedVideos);
}
