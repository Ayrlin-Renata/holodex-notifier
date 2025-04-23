// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_full.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VideoFull _$VideoFullFromJson(Map<String, dynamic> json) => _VideoFull(
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
  clips: (json['clips'] as List<dynamic>?)?.map((e) => VideoWithChannel.fromJson(e as Map<String, dynamic>)).toList(),
  sources: (json['sources'] as List<dynamic>?)?.map((e) => VideoWithChannel.fromJson(e as Map<String, dynamic>)).toList(),
  refers: (json['refers'] as List<dynamic>?)?.map((e) => VideoWithChannel.fromJson(e as Map<String, dynamic>)).toList(),
  simulcasts: (json['simulcasts'] as List<dynamic>?)?.map((e) => VideoWithChannel.fromJson(e as Map<String, dynamic>)).toList(),
  mentions: (json['mentions'] as List<dynamic>?)?.map((e) => ChannelMinWithOrg.fromJson(e as Map<String, dynamic>)).toList(),
  songs: (json['songs'] as num?)?.toInt(),
  certainty: json['certainty'] as String?,
  thumbnail: json['thumbnail'] as String?,
  link: json['link'] as String?,
);

Map<String, dynamic> _$VideoFullToJson(_VideoFull instance) => <String, dynamic>{
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
  'clips': instance.clips?.map((e) => e.toJson()).toList(),
  'sources': instance.sources?.map((e) => e.toJson()).toList(),
  'refers': instance.refers?.map((e) => e.toJson()).toList(),
  'simulcasts': instance.simulcasts?.map((e) => e.toJson()).toList(),
  'mentions': instance.mentions?.map((e) => e.toJson()).toList(),
  'songs': instance.songs,
  'certainty': instance.certainty,
  'thumbnail': instance.thumbnail,
  'link': instance.link,
};
