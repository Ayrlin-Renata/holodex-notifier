// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_subscription_setting.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChannelSubscriptionSetting _$ChannelSubscriptionSettingFromJson(Map<String, dynamic> json) {
  return _ChannelSubscriptionSetting.fromJson(json);
}

mixin _$ChannelSubscriptionSetting {
  String get channelId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  bool get notifyNewMedia => throw _privateConstructorUsedError;
  bool get notifyMentions => throw _privateConstructorUsedError;
  bool get notifyLive => throw _privateConstructorUsedError;
  bool get notifyUpdates => throw _privateConstructorUsedError;
  bool get notifyMembersOnly => throw _privateConstructorUsedError;
  bool get notifyClips => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelSubscriptionSettingCopyWith<ChannelSubscriptionSetting> get copyWith => throw _privateConstructorUsedError;
}

abstract class $ChannelSubscriptionSettingCopyWith<$Res> {
  factory $ChannelSubscriptionSettingCopyWith(ChannelSubscriptionSetting value, $Res Function(ChannelSubscriptionSetting) then) =
      _$ChannelSubscriptionSettingCopyWithImpl<$Res, ChannelSubscriptionSetting>;
  @useResult
  $Res call({
    String channelId,
    String name,
    String? avatarUrl,
    bool notifyNewMedia,
    bool notifyMentions,
    bool notifyLive,
    bool notifyUpdates,
    bool notifyMembersOnly,
    bool notifyClips,
  });
}

class _$ChannelSubscriptionSettingCopyWithImpl<$Res, $Val extends ChannelSubscriptionSetting> implements $ChannelSubscriptionSettingCopyWith<$Res> {
  _$ChannelSubscriptionSettingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channelId = null,
    Object? name = null,
    Object? avatarUrl = freezed,
    Object? notifyNewMedia = null,
    Object? notifyMentions = null,
    Object? notifyLive = null,
    Object? notifyUpdates = null,
    Object? notifyMembersOnly = null,
    Object? notifyClips = null,
  }) {
    return _then(
      _value.copyWith(
            channelId:
                null == channelId
                    ? _value.channelId
                    : channelId // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            avatarUrl:
                freezed == avatarUrl
                    ? _value.avatarUrl
                    : avatarUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
            notifyNewMedia:
                null == notifyNewMedia
                    ? _value.notifyNewMedia
                    : notifyNewMedia // ignore: cast_nullable_to_non_nullable
                        as bool,
            notifyMentions:
                null == notifyMentions
                    ? _value.notifyMentions
                    : notifyMentions // ignore: cast_nullable_to_non_nullable
                        as bool,
            notifyLive:
                null == notifyLive
                    ? _value.notifyLive
                    : notifyLive // ignore: cast_nullable_to_non_nullable
                        as bool,
            notifyUpdates:
                null == notifyUpdates
                    ? _value.notifyUpdates
                    : notifyUpdates // ignore: cast_nullable_to_non_nullable
                        as bool,
            notifyMembersOnly:
                null == notifyMembersOnly
                    ? _value.notifyMembersOnly
                    : notifyMembersOnly // ignore: cast_nullable_to_non_nullable
                        as bool,
            notifyClips:
                null == notifyClips
                    ? _value.notifyClips
                    : notifyClips // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

abstract class _$$ChannelSubscriptionSettingImplCopyWith<$Res> implements $ChannelSubscriptionSettingCopyWith<$Res> {
  factory _$$ChannelSubscriptionSettingImplCopyWith(_$ChannelSubscriptionSettingImpl value, $Res Function(_$ChannelSubscriptionSettingImpl) then) =
      __$$ChannelSubscriptionSettingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String channelId,
    String name,
    String? avatarUrl,
    bool notifyNewMedia,
    bool notifyMentions,
    bool notifyLive,
    bool notifyUpdates,
    bool notifyMembersOnly,
    bool notifyClips,
  });
}

class __$$ChannelSubscriptionSettingImplCopyWithImpl<$Res> extends _$ChannelSubscriptionSettingCopyWithImpl<$Res, _$ChannelSubscriptionSettingImpl>
    implements _$$ChannelSubscriptionSettingImplCopyWith<$Res> {
  __$$ChannelSubscriptionSettingImplCopyWithImpl(_$ChannelSubscriptionSettingImpl _value, $Res Function(_$ChannelSubscriptionSettingImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? channelId = null,
    Object? name = null,
    Object? avatarUrl = freezed,
    Object? notifyNewMedia = null,
    Object? notifyMentions = null,
    Object? notifyLive = null,
    Object? notifyUpdates = null,
    Object? notifyMembersOnly = null,
    Object? notifyClips = null,
  }) {
    return _then(
      _$ChannelSubscriptionSettingImpl(
        channelId:
            null == channelId
                ? _value.channelId
                : channelId // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        avatarUrl:
            freezed == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
        notifyNewMedia:
            null == notifyNewMedia
                ? _value.notifyNewMedia
                : notifyNewMedia // ignore: cast_nullable_to_non_nullable
                    as bool,
        notifyMentions:
            null == notifyMentions
                ? _value.notifyMentions
                : notifyMentions // ignore: cast_nullable_to_non_nullable
                    as bool,
        notifyLive:
            null == notifyLive
                ? _value.notifyLive
                : notifyLive // ignore: cast_nullable_to_non_nullable
                    as bool,
        notifyUpdates:
            null == notifyUpdates
                ? _value.notifyUpdates
                : notifyUpdates // ignore: cast_nullable_to_non_nullable
                    as bool,
        notifyMembersOnly:
            null == notifyMembersOnly
                ? _value.notifyMembersOnly
                : notifyMembersOnly // ignore: cast_nullable_to_non_nullable
                    as bool,
        notifyClips:
            null == notifyClips
                ? _value.notifyClips
                : notifyClips // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

@JsonSerializable()
class _$ChannelSubscriptionSettingImpl implements _ChannelSubscriptionSetting {
  const _$ChannelSubscriptionSettingImpl({
    required this.channelId,
    required this.name,
    this.avatarUrl,
    this.notifyNewMedia = true,
    this.notifyMentions = true,
    this.notifyLive = true,
    this.notifyUpdates = true,
    this.notifyMembersOnly = true,
    this.notifyClips = true,
  });

  factory _$ChannelSubscriptionSettingImpl.fromJson(Map<String, dynamic> json) => _$$ChannelSubscriptionSettingImplFromJson(json);

  @override
  final String channelId;
  @override
  final String name;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final bool notifyNewMedia;
  @override
  @JsonKey()
  final bool notifyMentions;
  @override
  @JsonKey()
  final bool notifyLive;
  @override
  @JsonKey()
  final bool notifyUpdates;
  @override
  @JsonKey()
  final bool notifyMembersOnly;
  @override
  @JsonKey()
  final bool notifyClips;

  @override
  String toString() {
    return 'ChannelSubscriptionSetting(channelId: $channelId, name: $name, avatarUrl: $avatarUrl, notifyNewMedia: $notifyNewMedia, notifyMentions: $notifyMentions, notifyLive: $notifyLive, notifyUpdates: $notifyUpdates, notifyMembersOnly: $notifyMembersOnly, notifyClips: $notifyClips)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelSubscriptionSettingImpl &&
            (identical(other.channelId, channelId) || other.channelId == channelId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl) &&
            (identical(other.notifyNewMedia, notifyNewMedia) || other.notifyNewMedia == notifyNewMedia) &&
            (identical(other.notifyMentions, notifyMentions) || other.notifyMentions == notifyMentions) &&
            (identical(other.notifyLive, notifyLive) || other.notifyLive == notifyLive) &&
            (identical(other.notifyUpdates, notifyUpdates) || other.notifyUpdates == notifyUpdates) &&
            (identical(other.notifyMembersOnly, notifyMembersOnly) || other.notifyMembersOnly == notifyMembersOnly) &&
            (identical(other.notifyClips, notifyClips) || other.notifyClips == notifyClips));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, channelId, name, avatarUrl, notifyNewMedia, notifyMentions, notifyLive, notifyUpdates, notifyMembersOnly, notifyClips);

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelSubscriptionSettingImplCopyWith<_$ChannelSubscriptionSettingImpl> get copyWith =>
      __$$ChannelSubscriptionSettingImplCopyWithImpl<_$ChannelSubscriptionSettingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelSubscriptionSettingImplToJson(this);
  }
}

abstract class _ChannelSubscriptionSetting implements ChannelSubscriptionSetting {
  const factory _ChannelSubscriptionSetting({
    required final String channelId,
    required final String name,
    final String? avatarUrl,
    final bool notifyNewMedia,
    final bool notifyMentions,
    final bool notifyLive,
    final bool notifyUpdates,
    final bool notifyMembersOnly,
    final bool notifyClips,
  }) = _$ChannelSubscriptionSettingImpl;

  factory _ChannelSubscriptionSetting.fromJson(Map<String, dynamic> json) = _$ChannelSubscriptionSettingImpl.fromJson;

  @override
  String get channelId;
  @override
  String get name;
  @override
  String? get avatarUrl;
  @override
  bool get notifyNewMedia;
  @override
  bool get notifyMentions;
  @override
  bool get notifyLive;
  @override
  bool get notifyUpdates;
  @override
  bool get notifyMembersOnly;
  @override
  bool get notifyClips;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelSubscriptionSettingImplCopyWith<_$ChannelSubscriptionSettingImpl> get copyWith => throw _privateConstructorUsedError;
}
