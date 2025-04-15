// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) {
  return _AppConfig.fromJson(json);
}

/// @nodoc
mixin _$AppConfig {
// Include non-sensitive settings
  int get pollFrequencyMinutes => throw _privateConstructorUsedError;
  bool get notificationGrouping => throw _privateConstructorUsedError;
  bool get delayNewMedia => throw _privateConstructorUsedError;
  int get reminderLeadTimeMinutes => throw _privateConstructorUsedError;
  List<ChannelSubscriptionSetting> get channelSubscriptions =>
      throw _privateConstructorUsedError; // DO NOT include API Key or other sensitive/runtime data like lastPollTime
// Add version if needed for future compatibility
  int get version => throw _privateConstructorUsedError;

  /// Serializes this AppConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppConfigCopyWith<AppConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppConfigCopyWith<$Res> {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) then) =
      _$AppConfigCopyWithImpl<$Res, AppConfig>;
  @useResult
  $Res call(
      {int pollFrequencyMinutes,
      bool notificationGrouping,
      bool delayNewMedia,
      int reminderLeadTimeMinutes,
      List<ChannelSubscriptionSetting> channelSubscriptions,
      int version});
}

/// @nodoc
class _$AppConfigCopyWithImpl<$Res, $Val extends AppConfig>
    implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pollFrequencyMinutes = null,
    Object? notificationGrouping = null,
    Object? delayNewMedia = null,
    Object? reminderLeadTimeMinutes = null,
    Object? channelSubscriptions = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      pollFrequencyMinutes: null == pollFrequencyMinutes
          ? _value.pollFrequencyMinutes
          : pollFrequencyMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      notificationGrouping: null == notificationGrouping
          ? _value.notificationGrouping
          : notificationGrouping // ignore: cast_nullable_to_non_nullable
              as bool,
      delayNewMedia: null == delayNewMedia
          ? _value.delayNewMedia
          : delayNewMedia // ignore: cast_nullable_to_non_nullable
              as bool,
      reminderLeadTimeMinutes: null == reminderLeadTimeMinutes
          ? _value.reminderLeadTimeMinutes
          : reminderLeadTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      channelSubscriptions: null == channelSubscriptions
          ? _value.channelSubscriptions
          : channelSubscriptions // ignore: cast_nullable_to_non_nullable
              as List<ChannelSubscriptionSetting>,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppConfigImplCopyWith<$Res>
    implements $AppConfigCopyWith<$Res> {
  factory _$$AppConfigImplCopyWith(
          _$AppConfigImpl value, $Res Function(_$AppConfigImpl) then) =
      __$$AppConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int pollFrequencyMinutes,
      bool notificationGrouping,
      bool delayNewMedia,
      int reminderLeadTimeMinutes,
      List<ChannelSubscriptionSetting> channelSubscriptions,
      int version});
}

/// @nodoc
class __$$AppConfigImplCopyWithImpl<$Res>
    extends _$AppConfigCopyWithImpl<$Res, _$AppConfigImpl>
    implements _$$AppConfigImplCopyWith<$Res> {
  __$$AppConfigImplCopyWithImpl(
      _$AppConfigImpl _value, $Res Function(_$AppConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pollFrequencyMinutes = null,
    Object? notificationGrouping = null,
    Object? delayNewMedia = null,
    Object? reminderLeadTimeMinutes = null,
    Object? channelSubscriptions = null,
    Object? version = null,
  }) {
    return _then(_$AppConfigImpl(
      pollFrequencyMinutes: null == pollFrequencyMinutes
          ? _value.pollFrequencyMinutes
          : pollFrequencyMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      notificationGrouping: null == notificationGrouping
          ? _value.notificationGrouping
          : notificationGrouping // ignore: cast_nullable_to_non_nullable
              as bool,
      delayNewMedia: null == delayNewMedia
          ? _value.delayNewMedia
          : delayNewMedia // ignore: cast_nullable_to_non_nullable
              as bool,
      reminderLeadTimeMinutes: null == reminderLeadTimeMinutes
          ? _value.reminderLeadTimeMinutes
          : reminderLeadTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      channelSubscriptions: null == channelSubscriptions
          ? _value._channelSubscriptions
          : channelSubscriptions // ignore: cast_nullable_to_non_nullable
              as List<ChannelSubscriptionSetting>,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$AppConfigImpl implements _AppConfig {
  const _$AppConfigImpl(
      {required this.pollFrequencyMinutes,
      required this.notificationGrouping,
      required this.delayNewMedia,
      required this.reminderLeadTimeMinutes,
      required final List<ChannelSubscriptionSetting> channelSubscriptions,
      this.version = 1})
      : _channelSubscriptions = channelSubscriptions;

  factory _$AppConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppConfigImplFromJson(json);

// Include non-sensitive settings
  @override
  final int pollFrequencyMinutes;
  @override
  final bool notificationGrouping;
  @override
  final bool delayNewMedia;
  @override
  final int reminderLeadTimeMinutes;
  final List<ChannelSubscriptionSetting> _channelSubscriptions;
  @override
  List<ChannelSubscriptionSetting> get channelSubscriptions {
    if (_channelSubscriptions is EqualUnmodifiableListView)
      return _channelSubscriptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_channelSubscriptions);
  }

// DO NOT include API Key or other sensitive/runtime data like lastPollTime
// Add version if needed for future compatibility
  @override
  @JsonKey()
  final int version;

  @override
  String toString() {
    return 'AppConfig(pollFrequencyMinutes: $pollFrequencyMinutes, notificationGrouping: $notificationGrouping, delayNewMedia: $delayNewMedia, reminderLeadTimeMinutes: $reminderLeadTimeMinutes, channelSubscriptions: $channelSubscriptions, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppConfigImpl &&
            (identical(other.pollFrequencyMinutes, pollFrequencyMinutes) ||
                other.pollFrequencyMinutes == pollFrequencyMinutes) &&
            (identical(other.notificationGrouping, notificationGrouping) ||
                other.notificationGrouping == notificationGrouping) &&
            (identical(other.delayNewMedia, delayNewMedia) ||
                other.delayNewMedia == delayNewMedia) &&
            (identical(
                    other.reminderLeadTimeMinutes, reminderLeadTimeMinutes) ||
                other.reminderLeadTimeMinutes == reminderLeadTimeMinutes) &&
            const DeepCollectionEquality()
                .equals(other._channelSubscriptions, _channelSubscriptions) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      pollFrequencyMinutes,
      notificationGrouping,
      delayNewMedia,
      reminderLeadTimeMinutes,
      const DeepCollectionEquality().hash(_channelSubscriptions),
      version);

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppConfigImplCopyWith<_$AppConfigImpl> get copyWith =>
      __$$AppConfigImplCopyWithImpl<_$AppConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppConfigImplToJson(
      this,
    );
  }
}

abstract class _AppConfig implements AppConfig {
  const factory _AppConfig(
      {required final int pollFrequencyMinutes,
      required final bool notificationGrouping,
      required final bool delayNewMedia,
      required final int reminderLeadTimeMinutes,
      required final List<ChannelSubscriptionSetting> channelSubscriptions,
      final int version}) = _$AppConfigImpl;

  factory _AppConfig.fromJson(Map<String, dynamic> json) =
      _$AppConfigImpl.fromJson;

// Include non-sensitive settings
  @override
  int get pollFrequencyMinutes;
  @override
  bool get notificationGrouping;
  @override
  bool get delayNewMedia;
  @override
  int get reminderLeadTimeMinutes;
  @override
  List<ChannelSubscriptionSetting>
      get channelSubscriptions; // DO NOT include API Key or other sensitive/runtime data like lastPollTime
// Add version if needed for future compatibility
  @override
  int get version;

  /// Create a copy of AppConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppConfigImplCopyWith<_$AppConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
