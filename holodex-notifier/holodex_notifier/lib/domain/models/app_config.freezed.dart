// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppConfig {

 int get pollFrequencyMinutes; bool get notificationGrouping; bool get delayNewMedia; int get reminderLeadTimeMinutes; List<ChannelSubscriptionSetting> get channelSubscriptions; int get version;
/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppConfigCopyWith<AppConfig> get copyWith => _$AppConfigCopyWithImpl<AppConfig>(this as AppConfig, _$identity);

  /// Serializes this AppConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppConfig&&(identical(other.pollFrequencyMinutes, pollFrequencyMinutes) || other.pollFrequencyMinutes == pollFrequencyMinutes)&&(identical(other.notificationGrouping, notificationGrouping) || other.notificationGrouping == notificationGrouping)&&(identical(other.delayNewMedia, delayNewMedia) || other.delayNewMedia == delayNewMedia)&&(identical(other.reminderLeadTimeMinutes, reminderLeadTimeMinutes) || other.reminderLeadTimeMinutes == reminderLeadTimeMinutes)&&const DeepCollectionEquality().equals(other.channelSubscriptions, channelSubscriptions)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pollFrequencyMinutes,notificationGrouping,delayNewMedia,reminderLeadTimeMinutes,const DeepCollectionEquality().hash(channelSubscriptions),version);

@override
String toString() {
  return 'AppConfig(pollFrequencyMinutes: $pollFrequencyMinutes, notificationGrouping: $notificationGrouping, delayNewMedia: $delayNewMedia, reminderLeadTimeMinutes: $reminderLeadTimeMinutes, channelSubscriptions: $channelSubscriptions, version: $version)';
}


}

/// @nodoc
abstract mixin class $AppConfigCopyWith<$Res>  {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) _then) = _$AppConfigCopyWithImpl;
@useResult
$Res call({
 int pollFrequencyMinutes, bool notificationGrouping, bool delayNewMedia, int reminderLeadTimeMinutes, List<ChannelSubscriptionSetting> channelSubscriptions, int version
});




}
/// @nodoc
class _$AppConfigCopyWithImpl<$Res>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._self, this._then);

  final AppConfig _self;
  final $Res Function(AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pollFrequencyMinutes = null,Object? notificationGrouping = null,Object? delayNewMedia = null,Object? reminderLeadTimeMinutes = null,Object? channelSubscriptions = null,Object? version = null,}) {
  return _then(_self.copyWith(
pollFrequencyMinutes: null == pollFrequencyMinutes ? _self.pollFrequencyMinutes : pollFrequencyMinutes // ignore: cast_nullable_to_non_nullable
as int,notificationGrouping: null == notificationGrouping ? _self.notificationGrouping : notificationGrouping // ignore: cast_nullable_to_non_nullable
as bool,delayNewMedia: null == delayNewMedia ? _self.delayNewMedia : delayNewMedia // ignore: cast_nullable_to_non_nullable
as bool,reminderLeadTimeMinutes: null == reminderLeadTimeMinutes ? _self.reminderLeadTimeMinutes : reminderLeadTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,channelSubscriptions: null == channelSubscriptions ? _self.channelSubscriptions : channelSubscriptions // ignore: cast_nullable_to_non_nullable
as List<ChannelSubscriptionSetting>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _AppConfig implements AppConfig {
  const _AppConfig({required this.pollFrequencyMinutes, required this.notificationGrouping, required this.delayNewMedia, required this.reminderLeadTimeMinutes, required final  List<ChannelSubscriptionSetting> channelSubscriptions, this.version = 1}): _channelSubscriptions = channelSubscriptions;
  factory _AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);

@override final  int pollFrequencyMinutes;
@override final  bool notificationGrouping;
@override final  bool delayNewMedia;
@override final  int reminderLeadTimeMinutes;
 final  List<ChannelSubscriptionSetting> _channelSubscriptions;
@override List<ChannelSubscriptionSetting> get channelSubscriptions {
  if (_channelSubscriptions is EqualUnmodifiableListView) return _channelSubscriptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_channelSubscriptions);
}

@override@JsonKey() final  int version;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppConfigCopyWith<_AppConfig> get copyWith => __$AppConfigCopyWithImpl<_AppConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppConfig&&(identical(other.pollFrequencyMinutes, pollFrequencyMinutes) || other.pollFrequencyMinutes == pollFrequencyMinutes)&&(identical(other.notificationGrouping, notificationGrouping) || other.notificationGrouping == notificationGrouping)&&(identical(other.delayNewMedia, delayNewMedia) || other.delayNewMedia == delayNewMedia)&&(identical(other.reminderLeadTimeMinutes, reminderLeadTimeMinutes) || other.reminderLeadTimeMinutes == reminderLeadTimeMinutes)&&const DeepCollectionEquality().equals(other._channelSubscriptions, _channelSubscriptions)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pollFrequencyMinutes,notificationGrouping,delayNewMedia,reminderLeadTimeMinutes,const DeepCollectionEquality().hash(_channelSubscriptions),version);

@override
String toString() {
  return 'AppConfig(pollFrequencyMinutes: $pollFrequencyMinutes, notificationGrouping: $notificationGrouping, delayNewMedia: $delayNewMedia, reminderLeadTimeMinutes: $reminderLeadTimeMinutes, channelSubscriptions: $channelSubscriptions, version: $version)';
}


}

/// @nodoc
abstract mixin class _$AppConfigCopyWith<$Res> implements $AppConfigCopyWith<$Res> {
  factory _$AppConfigCopyWith(_AppConfig value, $Res Function(_AppConfig) _then) = __$AppConfigCopyWithImpl;
@override @useResult
$Res call({
 int pollFrequencyMinutes, bool notificationGrouping, bool delayNewMedia, int reminderLeadTimeMinutes, List<ChannelSubscriptionSetting> channelSubscriptions, int version
});




}
/// @nodoc
class __$AppConfigCopyWithImpl<$Res>
    implements _$AppConfigCopyWith<$Res> {
  __$AppConfigCopyWithImpl(this._self, this._then);

  final _AppConfig _self;
  final $Res Function(_AppConfig) _then;

/// Create a copy of AppConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pollFrequencyMinutes = null,Object? notificationGrouping = null,Object? delayNewMedia = null,Object? reminderLeadTimeMinutes = null,Object? channelSubscriptions = null,Object? version = null,}) {
  return _then(_AppConfig(
pollFrequencyMinutes: null == pollFrequencyMinutes ? _self.pollFrequencyMinutes : pollFrequencyMinutes // ignore: cast_nullable_to_non_nullable
as int,notificationGrouping: null == notificationGrouping ? _self.notificationGrouping : notificationGrouping // ignore: cast_nullable_to_non_nullable
as bool,delayNewMedia: null == delayNewMedia ? _self.delayNewMedia : delayNewMedia // ignore: cast_nullable_to_non_nullable
as bool,reminderLeadTimeMinutes: null == reminderLeadTimeMinutes ? _self.reminderLeadTimeMinutes : reminderLeadTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,channelSubscriptions: null == channelSubscriptions ? _self._channelSubscriptions : channelSubscriptions // ignore: cast_nullable_to_non_nullable
as List<ChannelSubscriptionSetting>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
