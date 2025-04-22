// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Channel {

 String get id; String get name; String? get englishName; String? get type; String? get org; String? get group; String? get photo; String? get banner; String? get twitter;@JsonKey(fromJson: _intFromStringNullable) int? get videoCount;@JsonKey(fromJson: _intFromStringNullable) int? get subscriberCount;@JsonKey(fromJson: _intFromStringNullable) int? get viewCount;@JsonKey(fromJson: _intFromStringNullable) int? get clipCount; String? get lang;@JsonKey(fromJson: _dateTimeFromStringNullable) DateTime? get publishedAt; bool? get inactive; String? get description;
/// Create a copy of Channel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelCopyWith<Channel> get copyWith => _$ChannelCopyWithImpl<Channel>(this as Channel, _$identity);

  /// Serializes this Channel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Channel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.englishName, englishName) || other.englishName == englishName)&&(identical(other.type, type) || other.type == type)&&(identical(other.org, org) || other.org == org)&&(identical(other.group, group) || other.group == group)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.banner, banner) || other.banner == banner)&&(identical(other.twitter, twitter) || other.twitter == twitter)&&(identical(other.videoCount, videoCount) || other.videoCount == videoCount)&&(identical(other.subscriberCount, subscriberCount) || other.subscriberCount == subscriberCount)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.clipCount, clipCount) || other.clipCount == clipCount)&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.inactive, inactive) || other.inactive == inactive)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,englishName,type,org,group,photo,banner,twitter,videoCount,subscriberCount,viewCount,clipCount,lang,publishedAt,inactive,description);

@override
String toString() {
  return 'Channel(id: $id, name: $name, englishName: $englishName, type: $type, org: $org, group: $group, photo: $photo, banner: $banner, twitter: $twitter, videoCount: $videoCount, subscriberCount: $subscriberCount, viewCount: $viewCount, clipCount: $clipCount, lang: $lang, publishedAt: $publishedAt, inactive: $inactive, description: $description)';
}


}

/// @nodoc
abstract mixin class $ChannelCopyWith<$Res>  {
  factory $ChannelCopyWith(Channel value, $Res Function(Channel) _then) = _$ChannelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? englishName, String? type, String? org, String? group, String? photo, String? banner, String? twitter,@JsonKey(fromJson: _intFromStringNullable) int? videoCount,@JsonKey(fromJson: _intFromStringNullable) int? subscriberCount,@JsonKey(fromJson: _intFromStringNullable) int? viewCount,@JsonKey(fromJson: _intFromStringNullable) int? clipCount, String? lang,@JsonKey(fromJson: _dateTimeFromStringNullable) DateTime? publishedAt, bool? inactive, String? description
});




}
/// @nodoc
class _$ChannelCopyWithImpl<$Res>
    implements $ChannelCopyWith<$Res> {
  _$ChannelCopyWithImpl(this._self, this._then);

  final Channel _self;
  final $Res Function(Channel) _then;

/// Create a copy of Channel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? englishName = freezed,Object? type = freezed,Object? org = freezed,Object? group = freezed,Object? photo = freezed,Object? banner = freezed,Object? twitter = freezed,Object? videoCount = freezed,Object? subscriberCount = freezed,Object? viewCount = freezed,Object? clipCount = freezed,Object? lang = freezed,Object? publishedAt = freezed,Object? inactive = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,englishName: freezed == englishName ? _self.englishName : englishName // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,org: freezed == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as String?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,banner: freezed == banner ? _self.banner : banner // ignore: cast_nullable_to_non_nullable
as String?,twitter: freezed == twitter ? _self.twitter : twitter // ignore: cast_nullable_to_non_nullable
as String?,videoCount: freezed == videoCount ? _self.videoCount : videoCount // ignore: cast_nullable_to_non_nullable
as int?,subscriberCount: freezed == subscriberCount ? _self.subscriberCount : subscriberCount // ignore: cast_nullable_to_non_nullable
as int?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,clipCount: freezed == clipCount ? _self.clipCount : clipCount // ignore: cast_nullable_to_non_nullable
as int?,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,inactive: freezed == inactive ? _self.inactive : inactive // ignore: cast_nullable_to_non_nullable
as bool?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Channel implements Channel {
  const _Channel({required this.id, required this.name, this.englishName, this.type, this.org, this.group, this.photo, this.banner, this.twitter, @JsonKey(fromJson: _intFromStringNullable) this.videoCount, @JsonKey(fromJson: _intFromStringNullable) this.subscriberCount, @JsonKey(fromJson: _intFromStringNullable) this.viewCount, @JsonKey(fromJson: _intFromStringNullable) this.clipCount, this.lang, @JsonKey(fromJson: _dateTimeFromStringNullable) this.publishedAt, this.inactive, this.description});
  factory _Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? englishName;
@override final  String? type;
@override final  String? org;
@override final  String? group;
@override final  String? photo;
@override final  String? banner;
@override final  String? twitter;
@override@JsonKey(fromJson: _intFromStringNullable) final  int? videoCount;
@override@JsonKey(fromJson: _intFromStringNullable) final  int? subscriberCount;
@override@JsonKey(fromJson: _intFromStringNullable) final  int? viewCount;
@override@JsonKey(fromJson: _intFromStringNullable) final  int? clipCount;
@override final  String? lang;
@override@JsonKey(fromJson: _dateTimeFromStringNullable) final  DateTime? publishedAt;
@override final  bool? inactive;
@override final  String? description;

/// Create a copy of Channel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelCopyWith<_Channel> get copyWith => __$ChannelCopyWithImpl<_Channel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChannelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Channel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.englishName, englishName) || other.englishName == englishName)&&(identical(other.type, type) || other.type == type)&&(identical(other.org, org) || other.org == org)&&(identical(other.group, group) || other.group == group)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.banner, banner) || other.banner == banner)&&(identical(other.twitter, twitter) || other.twitter == twitter)&&(identical(other.videoCount, videoCount) || other.videoCount == videoCount)&&(identical(other.subscriberCount, subscriberCount) || other.subscriberCount == subscriberCount)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.clipCount, clipCount) || other.clipCount == clipCount)&&(identical(other.lang, lang) || other.lang == lang)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.inactive, inactive) || other.inactive == inactive)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,englishName,type,org,group,photo,banner,twitter,videoCount,subscriberCount,viewCount,clipCount,lang,publishedAt,inactive,description);

@override
String toString() {
  return 'Channel(id: $id, name: $name, englishName: $englishName, type: $type, org: $org, group: $group, photo: $photo, banner: $banner, twitter: $twitter, videoCount: $videoCount, subscriberCount: $subscriberCount, viewCount: $viewCount, clipCount: $clipCount, lang: $lang, publishedAt: $publishedAt, inactive: $inactive, description: $description)';
}


}

/// @nodoc
abstract mixin class _$ChannelCopyWith<$Res> implements $ChannelCopyWith<$Res> {
  factory _$ChannelCopyWith(_Channel value, $Res Function(_Channel) _then) = __$ChannelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? englishName, String? type, String? org, String? group, String? photo, String? banner, String? twitter,@JsonKey(fromJson: _intFromStringNullable) int? videoCount,@JsonKey(fromJson: _intFromStringNullable) int? subscriberCount,@JsonKey(fromJson: _intFromStringNullable) int? viewCount,@JsonKey(fromJson: _intFromStringNullable) int? clipCount, String? lang,@JsonKey(fromJson: _dateTimeFromStringNullable) DateTime? publishedAt, bool? inactive, String? description
});




}
/// @nodoc
class __$ChannelCopyWithImpl<$Res>
    implements _$ChannelCopyWith<$Res> {
  __$ChannelCopyWithImpl(this._self, this._then);

  final _Channel _self;
  final $Res Function(_Channel) _then;

/// Create a copy of Channel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? englishName = freezed,Object? type = freezed,Object? org = freezed,Object? group = freezed,Object? photo = freezed,Object? banner = freezed,Object? twitter = freezed,Object? videoCount = freezed,Object? subscriberCount = freezed,Object? viewCount = freezed,Object? clipCount = freezed,Object? lang = freezed,Object? publishedAt = freezed,Object? inactive = freezed,Object? description = freezed,}) {
  return _then(_Channel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,englishName: freezed == englishName ? _self.englishName : englishName // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,org: freezed == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as String?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String?,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,banner: freezed == banner ? _self.banner : banner // ignore: cast_nullable_to_non_nullable
as String?,twitter: freezed == twitter ? _self.twitter : twitter // ignore: cast_nullable_to_non_nullable
as String?,videoCount: freezed == videoCount ? _self.videoCount : videoCount // ignore: cast_nullable_to_non_nullable
as int?,subscriberCount: freezed == subscriberCount ? _self.subscriberCount : subscriberCount // ignore: cast_nullable_to_non_nullable
as int?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,clipCount: freezed == clipCount ? _self.clipCount : clipCount // ignore: cast_nullable_to_non_nullable
as int?,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,inactive: freezed == inactive ? _self.inactive : inactive // ignore: cast_nullable_to_non_nullable
as bool?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
