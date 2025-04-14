// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChannelImpl _$$ChannelImplFromJson(Map<String, dynamic> json) =>
    _$ChannelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      englishName: json['english_name'] as String?,
      type: json['type'] as String?,
      org: json['org'] as String?,
      group: json['group'] as String?,
      photo: json['photo'] as String?,
      banner: json['banner'] as String?,
      twitter: json['twitter'] as String?,
      videoCount: _intFromStringNullable(json['video_count'] as String?),
      subscriberCount: _intFromStringNullable(
        json['subscriber_count'] as String?,
      ),
      viewCount: _intFromStringNullable(json['view_count'] as String?),
      clipCount: _intFromStringNullable(json['clip_count'] as String?),
      lang: json['lang'] as String?,
      publishedAt: _dateTimeFromStringNullable(json['published_at'] as String?),
      inactive: json['inactive'] as bool?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$ChannelImplToJson(_$ChannelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'english_name': instance.englishName,
      'type': instance.type,
      'org': instance.org,
      'group': instance.group,
      'photo': instance.photo,
      'banner': instance.banner,
      'twitter': instance.twitter,
      'video_count': instance.videoCount,
      'subscriber_count': instance.subscriberCount,
      'view_count': instance.viewCount,
      'clip_count': instance.clipCount,
      'lang': instance.lang,
      'published_at': instance.publishedAt?.toIso8601String(),
      'inactive': instance.inactive,
      'description': instance.description,
    };
