part of 'app_config.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) {
  return _AppConfig.fromJson(json);
}

mixin _$AppConfig {
  int get pollFrequencyMinutes => throw _privateConstructorUsedError;
  bool get notificationGrouping => throw _privateConstructorUsedError;
  bool get delayNewMedia => throw _privateConstructorUsedError;
  int get reminderLeadTimeMinutes => throw _privateConstructorUsedError;
  List<ChannelSubscriptionSetting> get channelSubscriptions => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppConfigCopyWith<AppConfig> get copyWith => throw _privateConstructorUsedError;
}

abstract class $AppConfigCopyWith<$Res> {
  factory $AppConfigCopyWith(AppConfig value, $Res Function(AppConfig) then) = _$AppConfigCopyWithImpl<$Res, AppConfig>;
  @useResult
  $Res call({
    int pollFrequencyMinutes,
    bool notificationGrouping,
    bool delayNewMedia,
    int reminderLeadTimeMinutes,
    List<ChannelSubscriptionSetting> channelSubscriptions,
    int version,
  });
}

class _$AppConfigCopyWithImpl<$Res, $Val extends AppConfig> implements $AppConfigCopyWith<$Res> {
  _$AppConfigCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

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
    return _then(
      _value.copyWith(
            pollFrequencyMinutes: null == pollFrequencyMinutes ? _value.pollFrequencyMinutes : pollFrequencyMinutes as int,
            notificationGrouping: null == notificationGrouping ? _value.notificationGrouping : notificationGrouping as bool,
            delayNewMedia: null == delayNewMedia ? _value.delayNewMedia : delayNewMedia as bool,
            reminderLeadTimeMinutes: null == reminderLeadTimeMinutes ? _value.reminderLeadTimeMinutes : reminderLeadTimeMinutes as int,
            channelSubscriptions:
                null == channelSubscriptions ? _value.channelSubscriptions : channelSubscriptions as List<ChannelSubscriptionSetting>,
            version: null == version ? _value.version : version as int,
          )
          as $Val,
    );
  }
}

abstract class _$$AppConfigImplCopyWith<$Res> implements $AppConfigCopyWith<$Res> {
  factory _$$AppConfigImplCopyWith(_$AppConfigImpl value, $Res Function(_$AppConfigImpl) then) = __$$AppConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int pollFrequencyMinutes,
    bool notificationGrouping,
    bool delayNewMedia,
    int reminderLeadTimeMinutes,
    List<ChannelSubscriptionSetting> channelSubscriptions,
    int version,
  });
}

class __$$AppConfigImplCopyWithImpl<$Res> extends _$AppConfigCopyWithImpl<$Res, _$AppConfigImpl> implements _$$AppConfigImplCopyWith<$Res> {
  __$$AppConfigImplCopyWithImpl(_$AppConfigImpl _value, $Res Function(_$AppConfigImpl) _then) : super(_value, _then);

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
    return _then(
      _$AppConfigImpl(
        pollFrequencyMinutes: null == pollFrequencyMinutes ? _value.pollFrequencyMinutes : pollFrequencyMinutes as int,
        notificationGrouping: null == notificationGrouping ? _value.notificationGrouping : notificationGrouping as bool,
        delayNewMedia: null == delayNewMedia ? _value.delayNewMedia : delayNewMedia as bool,
        reminderLeadTimeMinutes: null == reminderLeadTimeMinutes ? _value.reminderLeadTimeMinutes : reminderLeadTimeMinutes as int,
        channelSubscriptions: null == channelSubscriptions ? _value._channelSubscriptions : channelSubscriptions as List<ChannelSubscriptionSetting>,
        version: null == version ? _value.version : version as int,
      ),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class _$AppConfigImpl implements _AppConfig {
  const _$AppConfigImpl({
    required this.pollFrequencyMinutes,
    required this.notificationGrouping,
    required this.delayNewMedia,
    required this.reminderLeadTimeMinutes,
    required final List<ChannelSubscriptionSetting> channelSubscriptions,
    this.version = 1,
  }) : _channelSubscriptions = channelSubscriptions;

  factory _$AppConfigImpl.fromJson(Map<String, dynamic> json) => _$$AppConfigImplFromJson(json);

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
    if (_channelSubscriptions is EqualUnmodifiableListView) return _channelSubscriptions;
    return EqualUnmodifiableListView(_channelSubscriptions);
  }

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
            (identical(other.pollFrequencyMinutes, pollFrequencyMinutes) || other.pollFrequencyMinutes == pollFrequencyMinutes) &&
            (identical(other.notificationGrouping, notificationGrouping) || other.notificationGrouping == notificationGrouping) &&
            (identical(other.delayNewMedia, delayNewMedia) || other.delayNewMedia == delayNewMedia) &&
            (identical(other.reminderLeadTimeMinutes, reminderLeadTimeMinutes) || other.reminderLeadTimeMinutes == reminderLeadTimeMinutes) &&
            const DeepCollectionEquality().equals(other._channelSubscriptions, _channelSubscriptions) &&
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
    version,
  );

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppConfigImplCopyWith<_$AppConfigImpl> get copyWith => __$$AppConfigImplCopyWithImpl<_$AppConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppConfigImplToJson(this);
  }
}

abstract class _AppConfig implements AppConfig {
  const factory _AppConfig({
    required final int pollFrequencyMinutes,
    required final bool notificationGrouping,
    required final bool delayNewMedia,
    required final int reminderLeadTimeMinutes,
    required final List<ChannelSubscriptionSetting> channelSubscriptions,
    final int version,
  }) = _$AppConfigImpl;

  factory _AppConfig.fromJson(Map<String, dynamic> json) = _$AppConfigImpl.fromJson;

  @override
  int get pollFrequencyMinutes;
  @override
  bool get notificationGrouping;
  @override
  bool get delayNewMedia;
  @override
  int get reminderLeadTimeMinutes;
  @override
  List<ChannelSubscriptionSetting> get channelSubscriptions;
  @override
  int get version;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppConfigImplCopyWith<_$AppConfigImpl> get copyWith => throw _privateConstructorUsedError;
}
