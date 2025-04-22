// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Video _$VideoFromJson(Map<String, dynamic> json) => _Video(
  id: json['id'] as String,
  title: json['title'] as String,
  type: json['type'] as String,
  topicId: json['topic_id'] as String?,
  publishedAt: _dateTimeFromString(json['published_at'] as String?),
  availableAt: _dateTimeFromStringRequired(json['available_at'] as String),
  duration: (json['duration'] as num).toInt(),
  status: json['status'] as String,
  startScheduled: _dateTimeFromString(json['start_scheduled'] as String?),
  startActual: _dateTimeFromString(json['start_actual'] as String?),
  endActual: _dateTimeFromString(json['end_actual'] as String?),
  liveViewers: (json['live_viewers'] as num?)?.toInt(),
  description: json['description'] as String?,
  songcount: (json['songcount'] as num?)?.toInt(),
  channel: ChannelMin.fromJson(json['channel'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VideoToJson(_Video instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'type': instance.type,
  'topic_id': instance.topicId,
  'published_at': instance.publishedAt?.toIso8601String(),
  'available_at': instance.availableAt.toIso8601String(),
  'duration': instance.duration,
  'status': instance.status,
  'start_scheduled': instance.startScheduled?.toIso8601String(),
  'start_actual': instance.startActual?.toIso8601String(),
  'end_actual': instance.endActual?.toIso8601String(),
  'live_viewers': instance.liveViewers,
  'description': instance.description,
  'songcount': instance.songcount,
  'channel': instance.channel.toJson(),
};

_VideoWithChannel _$VideoWithChannelFromJson(Map<String, dynamic> json) =>
    _VideoWithChannel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      topicId: json['topic_id'] as String?,
      publishedAt: _dateTimeFromString(json['published_at'] as String?),
      availableAt: _dateTimeFromStringRequired(json['available_at'] as String),
      duration: (json['duration'] as num).toInt(),
      status: json['status'] as String,
      startScheduled: _dateTimeFromString(json['start_scheduled'] as String?),
      startActual: _dateTimeFromString(json['start_actual'] as String?),
      endActual: _dateTimeFromString(json['end_actual'] as String?),
      liveViewers: (json['live_viewers'] as num?)?.toInt(),
      description: json['description'] as String?,
      songcount: (json['songcount'] as num?)?.toInt(),
      channel: ChannelMin.fromJson(json['channel'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VideoWithChannelToJson(_VideoWithChannel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'type': instance.type,
      'topic_id': instance.topicId,
      'published_at': instance.publishedAt?.toIso8601String(),
      'available_at': instance.availableAt.toIso8601String(),
      'duration': instance.duration,
      'status': instance.status,
      'start_scheduled': instance.startScheduled?.toIso8601String(),
      'start_actual': instance.startActual?.toIso8601String(),
      'end_actual': instance.endActual?.toIso8601String(),
      'live_viewers': instance.liveViewers,
      'description': instance.description,
      'songcount': instance.songcount,
      'channel': instance.channel.toJson(),
    };
