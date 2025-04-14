// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_min_with_org.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChannelMinWithOrgImpl _$$ChannelMinWithOrgImplFromJson(
        Map<String, dynamic> json) =>
    _$ChannelMinWithOrgImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      englishName: json['english_name'] as String?,
      type: json['type'] as String? ?? 'vtuber',
      photo: json['photo'] as String?,
      org: json['org'] as String?,
    );

Map<String, dynamic> _$$ChannelMinWithOrgImplToJson(
        _$ChannelMinWithOrgImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'english_name': instance.englishName,
      'type': instance.type,
      'photo': instance.photo,
      'org': instance.org,
    };
