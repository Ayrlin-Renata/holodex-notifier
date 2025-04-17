part of 'notification_instruction.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

mixin _$NotificationInstruction {
  String get videoId => throw _privateConstructorUsedError;
  NotificationEventType get eventType => throw _privateConstructorUsedError;
  String get channelId => throw _privateConstructorUsedError;
  String get channelName => throw _privateConstructorUsedError;
  String get videoTitle => throw _privateConstructorUsedError;
  String? get videoType => throw _privateConstructorUsedError;
  String? get channelAvatarUrl => throw _privateConstructorUsedError;
  DateTime get availableAt => throw _privateConstructorUsedError;
  String? get mentionTargetChannelId => throw _privateConstructorUsedError;
  String? get mentionTargetChannelName => throw _privateConstructorUsedError;
  String? get videoThumbnailUrl => throw _privateConstructorUsedError;
  String? get videoSourceLink => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationInstructionCopyWith<NotificationInstruction> get copyWith => throw _privateConstructorUsedError;
}

abstract class $NotificationInstructionCopyWith<$Res> {
  factory $NotificationInstructionCopyWith(NotificationInstruction value, $Res Function(NotificationInstruction) then) =
      _$NotificationInstructionCopyWithImpl<$Res, NotificationInstruction>;
  @useResult
  $Res call({
    String videoId,
    NotificationEventType eventType,
    String channelId,
    String channelName,
    String videoTitle,
    String? videoType,
    String? channelAvatarUrl,
    DateTime availableAt,
    String? mentionTargetChannelId,
    String? mentionTargetChannelName,
    String? videoThumbnailUrl,
    String? videoSourceLink,
  });
}

class _$NotificationInstructionCopyWithImpl<$Res, $Val extends NotificationInstruction> implements $NotificationInstructionCopyWith<$Res> {
  _$NotificationInstructionCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

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
    Object? videoThumbnailUrl = freezed,
    Object? videoSourceLink = freezed,
  }) {
    return _then(
      _value.copyWith(
            videoId: null == videoId ? _value.videoId : videoId as String,
            eventType: null == eventType ? _value.eventType : eventType as NotificationEventType,
            channelId: null == channelId ? _value.channelId : channelId as String,
            channelName: null == channelName ? _value.channelName : channelName as String,
            videoTitle: null == videoTitle ? _value.videoTitle : videoTitle as String,
            videoType: freezed == videoType ? _value.videoType : videoType as String?,
            channelAvatarUrl: freezed == channelAvatarUrl ? _value.channelAvatarUrl : channelAvatarUrl as String?,
            availableAt: null == availableAt ? _value.availableAt : availableAt as DateTime,
            mentionTargetChannelId: freezed == mentionTargetChannelId ? _value.mentionTargetChannelId : mentionTargetChannelId as String?,
            mentionTargetChannelName: freezed == mentionTargetChannelName ? _value.mentionTargetChannelName : mentionTargetChannelName as String?,
            videoThumbnailUrl: freezed == videoThumbnailUrl ? _value.videoThumbnailUrl : videoThumbnailUrl as String?,
            videoSourceLink: freezed == videoSourceLink ? _value.videoSourceLink : videoSourceLink as String?,
          )
          as $Val,
    );
  }
}

abstract class _$$NotificationInstructionImplCopyWith<$Res> implements $NotificationInstructionCopyWith<$Res> {
  factory _$$NotificationInstructionImplCopyWith(_$NotificationInstructionImpl value, $Res Function(_$NotificationInstructionImpl) then) =
      __$$NotificationInstructionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String videoId,
    NotificationEventType eventType,
    String channelId,
    String channelName,
    String videoTitle,
    String? videoType,
    String? channelAvatarUrl,
    DateTime availableAt,
    String? mentionTargetChannelId,
    String? mentionTargetChannelName,
    String? videoThumbnailUrl,
    String? videoSourceLink,
  });
}

class __$$NotificationInstructionImplCopyWithImpl<$Res> extends _$NotificationInstructionCopyWithImpl<$Res, _$NotificationInstructionImpl>
    implements _$$NotificationInstructionImplCopyWith<$Res> {
  __$$NotificationInstructionImplCopyWithImpl(_$NotificationInstructionImpl _value, $Res Function(_$NotificationInstructionImpl) _then)
    : super(_value, _then);

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
    Object? videoThumbnailUrl = freezed,
    Object? videoSourceLink = freezed,
  }) {
    return _then(
      _$NotificationInstructionImpl(
        videoId: null == videoId ? _value.videoId : videoId as String,
        eventType: null == eventType ? _value.eventType : eventType as NotificationEventType,
        channelId: null == channelId ? _value.channelId : channelId as String,
        channelName: null == channelName ? _value.channelName : channelName as String,
        videoTitle: null == videoTitle ? _value.videoTitle : videoTitle as String,
        videoType: freezed == videoType ? _value.videoType : videoType as String?,
        channelAvatarUrl: freezed == channelAvatarUrl ? _value.channelAvatarUrl : channelAvatarUrl as String?,
        availableAt: null == availableAt ? _value.availableAt : availableAt as DateTime,
        mentionTargetChannelId: freezed == mentionTargetChannelId ? _value.mentionTargetChannelId : mentionTargetChannelId as String?,
        mentionTargetChannelName: freezed == mentionTargetChannelName ? _value.mentionTargetChannelName : mentionTargetChannelName as String?,
        videoThumbnailUrl: freezed == videoThumbnailUrl ? _value.videoThumbnailUrl : videoThumbnailUrl as String?,
        videoSourceLink: freezed == videoSourceLink ? _value.videoSourceLink : videoSourceLink as String?,
      ),
    );
  }
}

class _$NotificationInstructionImpl implements _NotificationInstruction {
  const _$NotificationInstructionImpl({
    required this.videoId,
    required this.eventType,
    required this.channelId,
    required this.channelName,
    required this.videoTitle,
    this.videoType,
    this.channelAvatarUrl,
    required this.availableAt,
    this.mentionTargetChannelId,
    this.mentionTargetChannelName,
    this.videoThumbnailUrl,
    this.videoSourceLink,
  });

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
  @override
  final String? mentionTargetChannelId;
  @override
  final String? mentionTargetChannelName;
  @override
  final String? videoThumbnailUrl;
  @override
  final String? videoSourceLink;

  @override
  String toString() {
    return 'NotificationInstruction(videoId: $videoId, eventType: $eventType, channelId: $channelId, channelName: $channelName, videoTitle: $videoTitle, videoType: $videoType, channelAvatarUrl: $channelAvatarUrl, availableAt: $availableAt, mentionTargetChannelId: $mentionTargetChannelId, mentionTargetChannelName: $mentionTargetChannelName, videoThumbnailUrl: $videoThumbnailUrl, videoSourceLink: $videoSourceLink)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInstructionImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.eventType, eventType) || other.eventType == eventType) &&
            (identical(other.channelId, channelId) || other.channelId == channelId) &&
            (identical(other.channelName, channelName) || other.channelName == channelName) &&
            (identical(other.videoTitle, videoTitle) || other.videoTitle == videoTitle) &&
            (identical(other.videoType, videoType) || other.videoType == videoType) &&
            (identical(other.channelAvatarUrl, channelAvatarUrl) || other.channelAvatarUrl == channelAvatarUrl) &&
            (identical(other.availableAt, availableAt) || other.availableAt == availableAt) &&
            (identical(other.mentionTargetChannelId, mentionTargetChannelId) || other.mentionTargetChannelId == mentionTargetChannelId) &&
            (identical(other.mentionTargetChannelName, mentionTargetChannelName) || other.mentionTargetChannelName == mentionTargetChannelName) &&
            (identical(other.videoThumbnailUrl, videoThumbnailUrl) || other.videoThumbnailUrl == videoThumbnailUrl) &&
            (identical(other.videoSourceLink, videoSourceLink) || other.videoSourceLink == videoSourceLink));
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
    mentionTargetChannelName,
    videoThumbnailUrl,
    videoSourceLink,
  );

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationInstructionImplCopyWith<_$NotificationInstructionImpl> get copyWith =>
      __$$NotificationInstructionImplCopyWithImpl<_$NotificationInstructionImpl>(this, _$identity);
}

abstract class _NotificationInstruction implements NotificationInstruction {
  const factory _NotificationInstruction({
    required final String videoId,
    required final NotificationEventType eventType,
    required final String channelId,
    required final String channelName,
    required final String videoTitle,
    final String? videoType,
    final String? channelAvatarUrl,
    required final DateTime availableAt,
    final String? mentionTargetChannelId,
    final String? mentionTargetChannelName,
    final String? videoThumbnailUrl,
    final String? videoSourceLink,
  }) = _$NotificationInstructionImpl;

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
  DateTime get availableAt;
  @override
  String? get mentionTargetChannelId;
  @override
  String? get mentionTargetChannelName;
  @override
  String? get videoThumbnailUrl;
  @override
  String? get videoSourceLink;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationInstructionImplCopyWith<_$NotificationInstructionImpl> get copyWith => throw _privateConstructorUsedError;
}
