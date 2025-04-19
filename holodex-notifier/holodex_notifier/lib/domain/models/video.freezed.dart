// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Video _$VideoFromJson(Map<String, dynamic> json) {
  return _Video.fromJson(json);
}

mixin _$Video {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get topicId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get publishedAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromStringRequired)
  DateTime get availableAt => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get startScheduled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get startActual => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get endActual => throw _privateConstructorUsedError;
  int? get liveViewers => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int? get songcount => throw _privateConstructorUsedError;
  ChannelMin get channel => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoCopyWith<Video> get copyWith => throw _privateConstructorUsedError;
}

abstract class $VideoCopyWith<$Res> {
  factory $VideoCopyWith(Video value, $Res Function(Video) then) = _$VideoCopyWithImpl<$Res, Video>;
  @useResult
  $Res call({
    String id,
    String title,
    String type,
    String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt,
    int duration,
    String status,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? endActual,
    int? liveViewers,
    String? description,
    int? songcount,
    ChannelMin channel,
  });

  $ChannelMinCopyWith<$Res> get channel;
}

class _$VideoCopyWithImpl<$Res, $Val extends Video> implements $VideoCopyWith<$Res> {
  _$VideoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? type = null,
    Object? topicId = freezed,
    Object? publishedAt = freezed,
    Object? availableAt = null,
    Object? duration = null,
    Object? status = null,
    Object? startScheduled = freezed,
    Object? startActual = freezed,
    Object? endActual = freezed,
    Object? liveViewers = freezed,
    Object? description = freezed,
    Object? songcount = freezed,
    Object? channel = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String,
            topicId:
                freezed == topicId
                    ? _value.topicId
                    : topicId // ignore: cast_nullable_to_non_nullable
                        as String?,
            publishedAt:
                freezed == publishedAt
                    ? _value.publishedAt
                    : publishedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            availableAt:
                null == availableAt
                    ? _value.availableAt
                    : availableAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            duration:
                null == duration
                    ? _value.duration
                    : duration // ignore: cast_nullable_to_non_nullable
                        as int,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            startScheduled:
                freezed == startScheduled
                    ? _value.startScheduled
                    : startScheduled // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            startActual:
                freezed == startActual
                    ? _value.startActual
                    : startActual // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            endActual:
                freezed == endActual
                    ? _value.endActual
                    : endActual // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            liveViewers:
                freezed == liveViewers
                    ? _value.liveViewers
                    : liveViewers // ignore: cast_nullable_to_non_nullable
                        as int?,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            songcount:
                freezed == songcount
                    ? _value.songcount
                    : songcount // ignore: cast_nullable_to_non_nullable
                        as int?,
            channel:
                null == channel
                    ? _value.channel
                    : channel // ignore: cast_nullable_to_non_nullable
                        as ChannelMin,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $ChannelMinCopyWith<$Res> get channel {
    return $ChannelMinCopyWith<$Res>(_value.channel, (value) {
      return _then(_value.copyWith(channel: value) as $Val);
    });
  }
}

abstract class _$$VideoImplCopyWith<$Res> implements $VideoCopyWith<$Res> {
  factory _$$VideoImplCopyWith(_$VideoImpl value, $Res Function(_$VideoImpl) then) = __$$VideoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String type,
    String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt,
    int duration,
    String status,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? endActual,
    int? liveViewers,
    String? description,
    int? songcount,
    ChannelMin channel,
  });

  @override
  $ChannelMinCopyWith<$Res> get channel;
}

class __$$VideoImplCopyWithImpl<$Res> extends _$VideoCopyWithImpl<$Res, _$VideoImpl> implements _$$VideoImplCopyWith<$Res> {
  __$$VideoImplCopyWithImpl(_$VideoImpl _value, $Res Function(_$VideoImpl) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? type = null,
    Object? topicId = freezed,
    Object? publishedAt = freezed,
    Object? availableAt = null,
    Object? duration = null,
    Object? status = null,
    Object? startScheduled = freezed,
    Object? startActual = freezed,
    Object? endActual = freezed,
    Object? liveViewers = freezed,
    Object? description = freezed,
    Object? songcount = freezed,
    Object? channel = null,
  }) {
    return _then(
      _$VideoImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String,
        topicId:
            freezed == topicId
                ? _value.topicId
                : topicId // ignore: cast_nullable_to_non_nullable
                    as String?,
        publishedAt:
            freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        availableAt:
            null == availableAt
                ? _value.availableAt
                : availableAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        duration:
            null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                    as int,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        startScheduled:
            freezed == startScheduled
                ? _value.startScheduled
                : startScheduled // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        startActual:
            freezed == startActual
                ? _value.startActual
                : startActual // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        endActual:
            freezed == endActual
                ? _value.endActual
                : endActual // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        liveViewers:
            freezed == liveViewers
                ? _value.liveViewers
                : liveViewers // ignore: cast_nullable_to_non_nullable
                    as int?,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        songcount:
            freezed == songcount
                ? _value.songcount
                : songcount // ignore: cast_nullable_to_non_nullable
                    as int?,
        channel:
            null == channel
                ? _value.channel
                : channel // ignore: cast_nullable_to_non_nullable
                    as ChannelMin,
      ),
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$VideoImpl implements _Video {
  const _$VideoImpl({
    required this.id,
    required this.title,
    required this.type,
    this.topicId,
    @JsonKey(fromJson: _dateTimeFromString) this.publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) required this.availableAt,
    required this.duration,
    required this.status,
    @JsonKey(fromJson: _dateTimeFromString) this.startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) this.startActual,
    @JsonKey(fromJson: _dateTimeFromString) this.endActual,
    this.liveViewers,
    this.description,
    this.songcount,
    required this.channel,
  });

  factory _$VideoImpl.fromJson(Map<String, dynamic> json) => _$$VideoImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String type;
  @override
  final String? topicId;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  final DateTime? publishedAt;
  @override
  @JsonKey(fromJson: _dateTimeFromStringRequired)
  final DateTime availableAt;
  @override
  final int duration;
  @override
  final String status;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  final DateTime? startScheduled;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  final DateTime? startActual;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  final DateTime? endActual;
  @override
  final int? liveViewers;
  @override
  final String? description;
  @override
  final int? songcount;
  @override
  final ChannelMin channel;

  @override
  String toString() {
    return 'Video(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt) &&
            (identical(other.availableAt, availableAt) || other.availableAt == availableAt) &&
            (identical(other.duration, duration) || other.duration == duration) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startScheduled, startScheduled) || other.startScheduled == startScheduled) &&
            (identical(other.startActual, startActual) || other.startActual == startActual) &&
            (identical(other.endActual, endActual) || other.endActual == endActual) &&
            (identical(other.liveViewers, liveViewers) || other.liveViewers == liveViewers) &&
            (identical(other.description, description) || other.description == description) &&
            (identical(other.songcount, songcount) || other.songcount == songcount) &&
            (identical(other.channel, channel) || other.channel == channel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    type,
    topicId,
    publishedAt,
    availableAt,
    duration,
    status,
    startScheduled,
    startActual,
    endActual,
    liveViewers,
    description,
    songcount,
    channel,
  );

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoImplCopyWith<_$VideoImpl> get copyWith => __$$VideoImplCopyWithImpl<_$VideoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoImplToJson(this);
  }
}

abstract class _Video implements Video {
  const factory _Video({
    required final String id,
    required final String title,
    required final String type,
    final String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) final DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) required final DateTime availableAt,
    required final int duration,
    required final String status,
    @JsonKey(fromJson: _dateTimeFromString) final DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) final DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) final DateTime? endActual,
    final int? liveViewers,
    final String? description,
    final int? songcount,
    required final ChannelMin channel,
  }) = _$VideoImpl;

  factory _Video.fromJson(Map<String, dynamic> json) = _$VideoImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get type;
  @override
  String? get topicId;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get publishedAt;
  @override
  @JsonKey(fromJson: _dateTimeFromStringRequired)
  DateTime get availableAt;
  @override
  int get duration;
  @override
  String get status;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get startScheduled;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get startActual;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get endActual;
  @override
  int? get liveViewers;
  @override
  String? get description;
  @override
  int? get songcount;
  @override
  ChannelMin get channel;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoImplCopyWith<_$VideoImpl> get copyWith => throw _privateConstructorUsedError;
}

VideoWithChannel _$VideoWithChannelFromJson(Map<String, dynamic> json) {
  return _VideoWithChannel.fromJson(json);
}

mixin _$VideoWithChannel {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get topicId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get publishedAt => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromStringRequired)
  DateTime get availableAt => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get startScheduled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get startActual => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get endActual => throw _privateConstructorUsedError;
  int? get liveViewers => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int? get songcount => throw _privateConstructorUsedError;
  ChannelMin get channel => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoWithChannelCopyWith<VideoWithChannel> get copyWith => throw _privateConstructorUsedError;
}

abstract class $VideoWithChannelCopyWith<$Res> {
  factory $VideoWithChannelCopyWith(VideoWithChannel value, $Res Function(VideoWithChannel) then) =
      _$VideoWithChannelCopyWithImpl<$Res, VideoWithChannel>;
  @useResult
  $Res call({
    String id,
    String title,
    String type,
    String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt,
    int duration,
    String status,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? endActual,
    int? liveViewers,
    String? description,
    int? songcount,
    ChannelMin channel,
  });

  $ChannelMinCopyWith<$Res> get channel;
}

class _$VideoWithChannelCopyWithImpl<$Res, $Val extends VideoWithChannel> implements $VideoWithChannelCopyWith<$Res> {
  _$VideoWithChannelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? type = null,
    Object? topicId = freezed,
    Object? publishedAt = freezed,
    Object? availableAt = null,
    Object? duration = null,
    Object? status = null,
    Object? startScheduled = freezed,
    Object? startActual = freezed,
    Object? endActual = freezed,
    Object? liveViewers = freezed,
    Object? description = freezed,
    Object? songcount = freezed,
    Object? channel = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String,
            topicId:
                freezed == topicId
                    ? _value.topicId
                    : topicId // ignore: cast_nullable_to_non_nullable
                        as String?,
            publishedAt:
                freezed == publishedAt
                    ? _value.publishedAt
                    : publishedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            availableAt:
                null == availableAt
                    ? _value.availableAt
                    : availableAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            duration:
                null == duration
                    ? _value.duration
                    : duration // ignore: cast_nullable_to_non_nullable
                        as int,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            startScheduled:
                freezed == startScheduled
                    ? _value.startScheduled
                    : startScheduled // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            startActual:
                freezed == startActual
                    ? _value.startActual
                    : startActual // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            endActual:
                freezed == endActual
                    ? _value.endActual
                    : endActual // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            liveViewers:
                freezed == liveViewers
                    ? _value.liveViewers
                    : liveViewers // ignore: cast_nullable_to_non_nullable
                        as int?,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
            songcount:
                freezed == songcount
                    ? _value.songcount
                    : songcount // ignore: cast_nullable_to_non_nullable
                        as int?,
            channel:
                null == channel
                    ? _value.channel
                    : channel // ignore: cast_nullable_to_non_nullable
                        as ChannelMin,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $ChannelMinCopyWith<$Res> get channel {
    return $ChannelMinCopyWith<$Res>(_value.channel, (value) {
      return _then(_value.copyWith(channel: value) as $Val);
    });
  }
}

abstract class _$$VideoWithChannelImplCopyWith<$Res> implements $VideoWithChannelCopyWith<$Res> {
  factory _$$VideoWithChannelImplCopyWith(_$VideoWithChannelImpl value, $Res Function(_$VideoWithChannelImpl) then) =
      __$$VideoWithChannelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String type,
    String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt,
    int duration,
    String status,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? endActual,
    int? liveViewers,
    String? description,
    int? songcount,
    ChannelMin channel,
  });

  @override
  $ChannelMinCopyWith<$Res> get channel;
}

class __$$VideoWithChannelImplCopyWithImpl<$Res> extends _$VideoWithChannelCopyWithImpl<$Res, _$VideoWithChannelImpl>
    implements _$$VideoWithChannelImplCopyWith<$Res> {
  __$$VideoWithChannelImplCopyWithImpl(_$VideoWithChannelImpl _value, $Res Function(_$VideoWithChannelImpl) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? type = null,
    Object? topicId = freezed,
    Object? publishedAt = freezed,
    Object? availableAt = null,
    Object? duration = null,
    Object? status = null,
    Object? startScheduled = freezed,
    Object? startActual = freezed,
    Object? endActual = freezed,
    Object? liveViewers = freezed,
    Object? description = freezed,
    Object? songcount = freezed,
    Object? channel = null,
  }) {
    return _then(
      _$VideoWithChannelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String,
        topicId:
            freezed == topicId
                ? _value.topicId
                : topicId // ignore: cast_nullable_to_non_nullable
                    as String?,
        publishedAt:
            freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        availableAt:
            null == availableAt
                ? _value.availableAt
                : availableAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        duration:
            null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                    as int,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        startScheduled:
            freezed == startScheduled
                ? _value.startScheduled
                : startScheduled // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        startActual:
            freezed == startActual
                ? _value.startActual
                : startActual // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        endActual:
            freezed == endActual
                ? _value.endActual
                : endActual // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        liveViewers:
            freezed == liveViewers
                ? _value.liveViewers
                : liveViewers // ignore: cast_nullable_to_non_nullable
                    as int?,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
        songcount:
            freezed == songcount
                ? _value.songcount
                : songcount // ignore: cast_nullable_to_non_nullable
                    as int?,
        channel:
            null == channel
                ? _value.channel
                : channel // ignore: cast_nullable_to_non_nullable
                    as ChannelMin,
      ),
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$VideoWithChannelImpl implements _VideoWithChannel {
  const _$VideoWithChannelImpl({
    required this.id,
    required this.title,
    required this.type,
    this.topicId,
    @JsonKey(fromJson: _dateTimeFromString) this.publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) required this.availableAt,
    required this.duration,
    required this.status,
    @JsonKey(fromJson: _dateTimeFromString) this.startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) this.startActual,
    @JsonKey(fromJson: _dateTimeFromString) this.endActual,
    this.liveViewers,
    this.description,
    this.songcount,
    required this.channel,
  });

  factory _$VideoWithChannelImpl.fromJson(Map<String, dynamic> json) => _$$VideoWithChannelImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String type;
  @override
  final String? topicId;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  final DateTime? publishedAt;
  @override
  @JsonKey(fromJson: _dateTimeFromStringRequired)
  final DateTime availableAt;
  @override
  final int duration;
  @override
  final String status;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  final DateTime? startScheduled;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  final DateTime? startActual;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  final DateTime? endActual;
  @override
  final int? liveViewers;
  @override
  final String? description;
  @override
  final int? songcount;
  @override
  final ChannelMin channel;

  @override
  String toString() {
    return 'VideoWithChannel(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoWithChannelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.topicId, topicId) || other.topicId == topicId) &&
            (identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt) &&
            (identical(other.availableAt, availableAt) || other.availableAt == availableAt) &&
            (identical(other.duration, duration) || other.duration == duration) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startScheduled, startScheduled) || other.startScheduled == startScheduled) &&
            (identical(other.startActual, startActual) || other.startActual == startActual) &&
            (identical(other.endActual, endActual) || other.endActual == endActual) &&
            (identical(other.liveViewers, liveViewers) || other.liveViewers == liveViewers) &&
            (identical(other.description, description) || other.description == description) &&
            (identical(other.songcount, songcount) || other.songcount == songcount) &&
            (identical(other.channel, channel) || other.channel == channel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    type,
    topicId,
    publishedAt,
    availableAt,
    duration,
    status,
    startScheduled,
    startActual,
    endActual,
    liveViewers,
    description,
    songcount,
    channel,
  );

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoWithChannelImplCopyWith<_$VideoWithChannelImpl> get copyWith =>
      __$$VideoWithChannelImplCopyWithImpl<_$VideoWithChannelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoWithChannelImplToJson(this);
  }
}

abstract class _VideoWithChannel implements VideoWithChannel {
  const factory _VideoWithChannel({
    required final String id,
    required final String title,
    required final String type,
    final String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) final DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) required final DateTime availableAt,
    required final int duration,
    required final String status,
    @JsonKey(fromJson: _dateTimeFromString) final DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) final DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) final DateTime? endActual,
    final int? liveViewers,
    final String? description,
    final int? songcount,
    required final ChannelMin channel,
  }) = _$VideoWithChannelImpl;

  factory _VideoWithChannel.fromJson(Map<String, dynamic> json) = _$VideoWithChannelImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get type;
  @override
  String? get topicId;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get publishedAt;
  @override
  @JsonKey(fromJson: _dateTimeFromStringRequired)
  DateTime get availableAt;
  @override
  int get duration;
  @override
  String get status;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get startScheduled;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get startActual;
  @override
  @JsonKey(fromJson: _dateTimeFromString)
  DateTime? get endActual;
  @override
  int? get liveViewers;
  @override
  String? get description;
  @override
  int? get songcount;
  @override
  ChannelMin get channel;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoWithChannelImplCopyWith<_$VideoWithChannelImpl> get copyWith => throw _privateConstructorUsedError;
}
