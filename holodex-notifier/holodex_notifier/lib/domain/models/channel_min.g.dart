part of 'channel_min.dart';

_$ChannelMinImpl _$$ChannelMinImplFromJson(Map<String, dynamic> json) => _$ChannelMinImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  englishName: json['english_name'] as String?,
  type: json['type'] as String? ?? 'vtuber',
  photo: json['photo'] as String?,
);

Map<String, dynamic> _$$ChannelMinImplToJson(_$ChannelMinImpl instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'english_name': instance.englishName,
  'type': instance.type,
  'photo': instance.photo,
};
