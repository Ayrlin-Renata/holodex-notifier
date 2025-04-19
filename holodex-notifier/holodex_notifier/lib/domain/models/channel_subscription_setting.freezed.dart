// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_subscription_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelSubscriptionSetting {

 String get channelId; String get name; String? get avatarUrl; bool get notifyNewMedia; bool get notifyMentions; bool get notifyLive; bool get notifyUpdates; bool get notifyMembersOnly; bool get notifyClips;
/// Create a copy of ChannelSubscriptionSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelSubscriptionSettingCopyWith<ChannelSubscriptionSetting> get copyWith => _$ChannelSubscriptionSettingCopyWithImpl<ChannelSubscriptionSetting>(this as ChannelSubscriptionSetting, _$identity);

  /// Serializes this ChannelSubscriptionSetting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelSubscriptionSetting&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.notifyNewMedia, notifyNewMedia) || other.notifyNewMedia == notifyNewMedia)&&(identical(other.notifyMentions, notifyMentions) || other.notifyMentions == notifyMentions)&&(identical(other.notifyLive, notifyLive) || other.notifyLive == notifyLive)&&(identical(other.notifyUpdates, notifyUpdates) || other.notifyUpdates == notifyUpdates)&&(identical(other.notifyMembersOnly, notifyMembersOnly) || other.notifyMembersOnly == notifyMembersOnly)&&(identical(other.notifyClips, notifyClips) || other.notifyClips == notifyClips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channelId,name,avatarUrl,notifyNewMedia,notifyMentions,notifyLive,notifyUpdates,notifyMembersOnly,notifyClips);

@override
String toString() {
  return 'ChannelSubscriptionSetting(channelId: $channelId, name: $name, avatarUrl: $avatarUrl, notifyNewMedia: $notifyNewMedia, notifyMentions: $notifyMentions, notifyLive: $notifyLive, notifyUpdates: $notifyUpdates, notifyMembersOnly: $notifyMembersOnly, notifyClips: $notifyClips)';
}


}

/// @nodoc
abstract mixin class $ChannelSubscriptionSettingCopyWith<$Res>  {
  factory $ChannelSubscriptionSettingCopyWith(ChannelSubscriptionSetting value, $Res Function(ChannelSubscriptionSetting) _then) = _$ChannelSubscriptionSettingCopyWithImpl;
@useResult
$Res call({
 String channelId, String name, String? avatarUrl, bool notifyNewMedia, bool notifyMentions, bool notifyLive, bool notifyUpdates, bool notifyMembersOnly, bool notifyClips
});




}
/// @nodoc
class _$ChannelSubscriptionSettingCopyWithImpl<$Res>
    implements $ChannelSubscriptionSettingCopyWith<$Res> {
  _$ChannelSubscriptionSettingCopyWithImpl(this._self, this._then);

  final ChannelSubscriptionSetting _self;
  final $Res Function(ChannelSubscriptionSetting) _then;

/// Create a copy of ChannelSubscriptionSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channelId = null,Object? name = null,Object? avatarUrl = freezed,Object? notifyNewMedia = null,Object? notifyMentions = null,Object? notifyLive = null,Object? notifyUpdates = null,Object? notifyMembersOnly = null,Object? notifyClips = null,}) {
  return _then(_self.copyWith(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,notifyNewMedia: null == notifyNewMedia ? _self.notifyNewMedia : notifyNewMedia // ignore: cast_nullable_to_non_nullable
as bool,notifyMentions: null == notifyMentions ? _self.notifyMentions : notifyMentions // ignore: cast_nullable_to_non_nullable
as bool,notifyLive: null == notifyLive ? _self.notifyLive : notifyLive // ignore: cast_nullable_to_non_nullable
as bool,notifyUpdates: null == notifyUpdates ? _self.notifyUpdates : notifyUpdates // ignore: cast_nullable_to_non_nullable
as bool,notifyMembersOnly: null == notifyMembersOnly ? _self.notifyMembersOnly : notifyMembersOnly // ignore: cast_nullable_to_non_nullable
as bool,notifyClips: null == notifyClips ? _self.notifyClips : notifyClips // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc

@JsonSerializable()
class _ChannelSubscriptionSetting implements ChannelSubscriptionSetting {
  const _ChannelSubscriptionSetting({required this.channelId, required this.name, this.avatarUrl, this.notifyNewMedia = true, this.notifyMentions = true, this.notifyLive = true, this.notifyUpdates = true, this.notifyMembersOnly = true, this.notifyClips = true});
  factory _ChannelSubscriptionSetting.fromJson(Map<String, dynamic> json) => _$ChannelSubscriptionSettingFromJson(json);

@override final  String channelId;
@override final  String name;
@override final  String? avatarUrl;
@override@JsonKey() final  bool notifyNewMedia;
@override@JsonKey() final  bool notifyMentions;
@override@JsonKey() final  bool notifyLive;
@override@JsonKey() final  bool notifyUpdates;
@override@JsonKey() final  bool notifyMembersOnly;
@override@JsonKey() final  bool notifyClips;

/// Create a copy of ChannelSubscriptionSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelSubscriptionSettingCopyWith<_ChannelSubscriptionSetting> get copyWith => __$ChannelSubscriptionSettingCopyWithImpl<_ChannelSubscriptionSetting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChannelSubscriptionSettingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelSubscriptionSetting&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.notifyNewMedia, notifyNewMedia) || other.notifyNewMedia == notifyNewMedia)&&(identical(other.notifyMentions, notifyMentions) || other.notifyMentions == notifyMentions)&&(identical(other.notifyLive, notifyLive) || other.notifyLive == notifyLive)&&(identical(other.notifyUpdates, notifyUpdates) || other.notifyUpdates == notifyUpdates)&&(identical(other.notifyMembersOnly, notifyMembersOnly) || other.notifyMembersOnly == notifyMembersOnly)&&(identical(other.notifyClips, notifyClips) || other.notifyClips == notifyClips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channelId,name,avatarUrl,notifyNewMedia,notifyMentions,notifyLive,notifyUpdates,notifyMembersOnly,notifyClips);

@override
String toString() {
  return 'ChannelSubscriptionSetting(channelId: $channelId, name: $name, avatarUrl: $avatarUrl, notifyNewMedia: $notifyNewMedia, notifyMentions: $notifyMentions, notifyLive: $notifyLive, notifyUpdates: $notifyUpdates, notifyMembersOnly: $notifyMembersOnly, notifyClips: $notifyClips)';
}


}

/// @nodoc
abstract mixin class _$ChannelSubscriptionSettingCopyWith<$Res> implements $ChannelSubscriptionSettingCopyWith<$Res> {
  factory _$ChannelSubscriptionSettingCopyWith(_ChannelSubscriptionSetting value, $Res Function(_ChannelSubscriptionSetting) _then) = __$ChannelSubscriptionSettingCopyWithImpl;
@override @useResult
$Res call({
 String channelId, String name, String? avatarUrl, bool notifyNewMedia, bool notifyMentions, bool notifyLive, bool notifyUpdates, bool notifyMembersOnly, bool notifyClips
});




}
/// @nodoc
class __$ChannelSubscriptionSettingCopyWithImpl<$Res>
    implements _$ChannelSubscriptionSettingCopyWith<$Res> {
  __$ChannelSubscriptionSettingCopyWithImpl(this._self, this._then);

  final _ChannelSubscriptionSetting _self;
  final $Res Function(_ChannelSubscriptionSetting) _then;

/// Create a copy of ChannelSubscriptionSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channelId = null,Object? name = null,Object? avatarUrl = freezed,Object? notifyNewMedia = null,Object? notifyMentions = null,Object? notifyLive = null,Object? notifyUpdates = null,Object? notifyMembersOnly = null,Object? notifyClips = null,}) {
  return _then(_ChannelSubscriptionSetting(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,notifyNewMedia: null == notifyNewMedia ? _self.notifyNewMedia : notifyNewMedia // ignore: cast_nullable_to_non_nullable
as bool,notifyMentions: null == notifyMentions ? _self.notifyMentions : notifyMentions // ignore: cast_nullable_to_non_nullable
as bool,notifyLive: null == notifyLive ? _self.notifyLive : notifyLive // ignore: cast_nullable_to_non_nullable
as bool,notifyUpdates: null == notifyUpdates ? _self.notifyUpdates : notifyUpdates // ignore: cast_nullable_to_non_nullable
as bool,notifyMembersOnly: null == notifyMembersOnly ? _self.notifyMembersOnly : notifyMembersOnly // ignore: cast_nullable_to_non_nullable
as bool,notifyClips: null == notifyClips ? _self.notifyClips : notifyClips // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
