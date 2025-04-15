// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_instruction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NotificationInstruction {
  String get videoId => throw _privateConstructorUsedError;
  NotificationEventType get eventType => throw _privateConstructorUsedError;
  String get channelId => throw _privateConstructorUsedError;
  String get channelName => throw _privateConstructorUsedError;
  String get videoTitle => throw _privateConstructorUsedError;
  String? get videoType => throw _privateConstructorUsedError;
  String? get channelAvatarUrl => throw _privateConstructorUsedError;
  DateTime get availableAt =>
      throw _privateConstructorUsedError; // {{ ADD required availableAt }}
// Fields specific to certain types (optional)
  String? get mentionTargetChannelId => throw _privateConstructorUsedError;
  String? get mentionTargetChannelName => throw _privateConstructorUsedError;

  /// Create a copy of NotificationInstruction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationInstructionCopyWith<NotificationInstruction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationInstructionCopyWith<$Res> {
  factory $NotificationInstructionCopyWith(NotificationInstruction value,
          $Res Function(NotificationInstruction) then) =
      _$NotificationInstructionCopyWithImpl<$Res, NotificationInstruction>;
  @useResult
  $Res call(
      {String videoId,
      NotificationEventType eventType,
      String channelId,
      String channelName,
      String videoTitle,
      String? videoType,
      String? channelAvatarUrl,
      DateTime availableAt,
      String? mentionTargetChannelId,
      String? mentionTargetChannelName});
}

/// @nodoc
class _$NotificationInstructionCopyWithImpl<$Res,
        $Val extends NotificationInstruction>
    implements $NotificationInstructionCopyWith<$Res> {
  _$NotificationInstructionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationInstruction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? eventType = null,
    Object? channelId = null,
    Object? channelName = null,
    Object? videoTitle = null,
    Object? videoType = freezed,
    Object? channelAvatarUrl = freezed,
    Object? availableAt = null,
    Object? mentionTargetChannelId = freezed,
    Object? mentionTargetChannelName = freezed,
  }) {
    return _then(_value.copyWith(
      videoId: null == videoId
          ? _value.videoId
          : videoId // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as NotificationEventType,
      channelId: null == channelId
          ? _value.channelId
          : channelId // ignore: cast_nullable_to_non_nullable
              as String,
      channelName: null == channelName
          ? _value.channelName
          : channelName // ignore: cast_nullable_to_non_nullable
              as String,
      videoTitle: null == videoTitle
          ? _value.videoTitle
          : videoTitle // ignore: cast_nullable_to_non_nullable
              as String,
      videoType: freezed == videoType
          ? _value.videoType
          : videoType // ignore: cast_nullable_to_non_nullable
              as String?,
      channelAvatarUrl: freezed == channelAvatarUrl
          ? _value.channelAvatarUrl
          : channelAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      availableAt: null == availableAt
          ? _value.availableAt
          : availableAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mentionTargetChannelId: freezed == mentionTargetChannelId
          ? _value.mentionTargetChannelId
          : mentionTargetChannelId // ignore: cast_nullable_to_non_nullable
              as String?,
      mentionTargetChannelName: freezed == mentionTargetChannelName
          ? _value.mentionTargetChannelName
          : mentionTargetChannelName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationInstructionImplCopyWith<$Res>
    implements $NotificationInstructionCopyWith<$Res> {
  factory _$$NotificationInstructionImplCopyWith(
          _$NotificationInstructionImpl value,
          $Res Function(_$NotificationInstructionImpl) then) =
      __$$NotificationInstructionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String videoId,
      NotificationEventType eventType,
      String channelId,
      String channelName,
      String videoTitle,
      String? videoType,
      String? channelAvatarUrl,
      DateTime availableAt,
      String? mentionTargetChannelId,
      String? mentionTargetChannelName});
}

/// @nodoc
class __$$NotificationInstructionImplCopyWithImpl<$Res>
    extends _$NotificationInstructionCopyWithImpl<$Res,
        _$NotificationInstructionImpl>
    implements _$$NotificationInstructionImplCopyWith<$Res> {
  __$$NotificationInstructionImplCopyWithImpl(
      _$NotificationInstructionImpl _value,
      $Res Function(_$NotificationInstructionImpl) _then)
      : super(_value, _then);

  /// Create a copy of NotificationInstruction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoId = null,
    Object? eventType = null,
    Object? channelId = null,
    Object? channelName = null,
    Object? videoTitle = null,
    Object? videoType = freezed,
    Object? channelAvatarUrl = freezed,
    Object? availableAt = null,
    Object? mentionTargetChannelId = freezed,
    Object? mentionTargetChannelName = freezed,
  }) {
    return _then(_$NotificationInstructionImpl(
      videoId: null == videoId
          ? _value.videoId
          : videoId // ignore: cast_nullable_to_non_nullable
              as String,
      eventType: null == eventType
          ? _value.eventType
          : eventType // ignore: cast_nullable_to_non_nullable
              as NotificationEventType,
      channelId: null == channelId
          ? _value.channelId
          : channelId // ignore: cast_nullable_to_non_nullable
              as String,
      channelName: null == channelName
          ? _value.channelName
          : channelName // ignore: cast_nullable_to_non_nullable
              as String,
      videoTitle: null == videoTitle
          ? _value.videoTitle
          : videoTitle // ignore: cast_nullable_to_non_nullable
              as String,
      videoType: freezed == videoType
          ? _value.videoType
          : videoType // ignore: cast_nullable_to_non_nullable
              as String?,
      channelAvatarUrl: freezed == channelAvatarUrl
          ? _value.channelAvatarUrl
          : channelAvatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      availableAt: null == availableAt
          ? _value.availableAt
          : availableAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mentionTargetChannelId: freezed == mentionTargetChannelId
          ? _value.mentionTargetChannelId
          : mentionTargetChannelId // ignore: cast_nullable_to_non_nullable
              as String?,
      mentionTargetChannelName: freezed == mentionTargetChannelName
          ? _value.mentionTargetChannelName
          : mentionTargetChannelName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NotificationInstructionImpl implements _NotificationInstruction {
  const _$NotificationInstructionImpl(
      {required this.videoId,
      required this.eventType,
      required this.channelId,
      required this.channelName,
      required this.videoTitle,
      this.videoType,
      this.channelAvatarUrl,
      required this.availableAt,
      this.mentionTargetChannelId,
      this.mentionTargetChannelName});

  @override
  final String videoId;
  @override
  final NotificationEventType eventType;
  @override
  final String channelId;
  @override
  final String channelName;
  @override
  final String videoTitle;
  @override
  final String? videoType;
  @override
  final String? channelAvatarUrl;
  @override
  final DateTime availableAt;
// {{ ADD required availableAt }}
// Fields specific to certain types (optional)
  @override
  final String? mentionTargetChannelId;
  @override
  final String? mentionTargetChannelName;

  @override
  String toString() {
    return 'NotificationInstruction(videoId: $videoId, eventType: $eventType, channelId: $channelId, channelName: $channelName, videoTitle: $videoTitle, videoType: $videoType, channelAvatarUrl: $channelAvatarUrl, availableAt: $availableAt, mentionTargetChannelId: $mentionTargetChannelId, mentionTargetChannelName: $mentionTargetChannelName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInstructionImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            (identical(other.channelName, channelName) ||
                other.channelName == channelName) &&
            (identical(other.videoTitle, videoTitle) ||
                other.videoTitle == videoTitle) &&
            (identical(other.videoType, videoType) ||
                other.videoType == videoType) &&
            (identical(other.channelAvatarUrl, channelAvatarUrl) ||
                other.channelAvatarUrl == channelAvatarUrl) &&
            (identical(other.availableAt, availableAt) ||
                other.availableAt == availableAt) &&
            (identical(other.mentionTargetChannelId, mentionTargetChannelId) ||
                other.mentionTargetChannelId == mentionTargetChannelId) &&
            (identical(
                    other.mentionTargetChannelName, mentionTargetChannelName) ||
                other.mentionTargetChannelName == mentionTargetChannelName));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      videoId,
      eventType,
      channelId,
      channelName,
      videoTitle,
      videoType,
      channelAvatarUrl,
      availableAt,
      mentionTargetChannelId,
      mentionTargetChannelName);

  /// Create a copy of NotificationInstruction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationInstructionImplCopyWith<_$NotificationInstructionImpl>
      get copyWith => __$$NotificationInstructionImplCopyWithImpl<
          _$NotificationInstructionImpl>(this, _$identity);
}

abstract class _NotificationInstruction implements NotificationInstruction {
  const factory _NotificationInstruction(
      {required final String videoId,
      required final NotificationEventType eventType,
      required final String channelId,
      required final String channelName,
      required final String videoTitle,
      final String? videoType,
      final String? channelAvatarUrl,
      required final DateTime availableAt,
      final String? mentionTargetChannelId,
      final String? mentionTargetChannelName}) = _$NotificationInstructionImpl;

  @override
  String get videoId;
  @override
  NotificationEventType get eventType;
  @override
  String get channelId;
  @override
  String get channelName;
  @override
  String get videoTitle;
  @override
  String? get videoType;
  @override
  String? get channelAvatarUrl;
  @override
  DateTime get availableAt; // {{ ADD required availableAt }}
// Fields specific to certain types (optional)
  @override
  String? get mentionTargetChannelId;
  @override
  String? get mentionTargetChannelName;

  /// Create a copy of NotificationInstruction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationInstructionImplCopyWith<_$NotificationInstructionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
