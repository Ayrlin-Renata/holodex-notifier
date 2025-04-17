part of 'video_full.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

VideoFull _$VideoFullFromJson(Map<String, dynamic> json) {
  return _VideoFull.fromJson(json);
}

mixin _$VideoFull {
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
  List<VideoWithChannel>? get clips => throw _privateConstructorUsedError;
  List<VideoWithChannel>? get sources => throw _privateConstructorUsedError;
  List<VideoWithChannel>? get refers => throw _privateConstructorUsedError;
  List<VideoWithChannel>? get simulcasts => throw _privateConstructorUsedError;
  List<ChannelMinWithOrg>? get mentions => throw _privateConstructorUsedError;
  int? get songs => throw _privateConstructorUsedError;
  String? get certainty => throw _privateConstructorUsedError;
  String? get thumbnail => throw _privateConstructorUsedError;
  String? get link => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $VideoFullCopyWith<VideoFull> get copyWith => throw _privateConstructorUsedError;
}

abstract class $VideoFullCopyWith<$Res> {
  factory $VideoFullCopyWith(VideoFull value, $Res Function(VideoFull) then) = _$VideoFullCopyWithImpl<$Res, VideoFull>;
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
    List<VideoWithChannel>? clips,
    List<VideoWithChannel>? sources,
    List<VideoWithChannel>? refers,
    List<VideoWithChannel>? simulcasts,
    List<ChannelMinWithOrg>? mentions,
    int? songs,
    String? certainty,
    String? thumbnail,
    String? link,
  });

  $ChannelMinCopyWith<$Res> get channel;
}

class _$VideoFullCopyWithImpl<$Res, $Val extends VideoFull> implements $VideoFullCopyWith<$Res> {
  _$VideoFullCopyWithImpl(this._value, this._then);

  final $Val _value;
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
    Object? clips = freezed,
    Object? sources = freezed,
    Object? refers = freezed,
    Object? simulcasts = freezed,
    Object? mentions = freezed,
    Object? songs = freezed,
    Object? certainty = freezed,
    Object? thumbnail = freezed,
    Object? link = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id ? _value.id : id as String,
            title: null == title ? _value.title : title as String,
            type: null == type ? _value.type : type as String,
            topicId: freezed == topicId ? _value.topicId : topicId as String?,
            publishedAt: freezed == publishedAt ? _value.publishedAt : publishedAt as DateTime?,
            availableAt: null == availableAt ? _value.availableAt : availableAt as DateTime,
            duration: null == duration ? _value.duration : duration as int,
            status: null == status ? _value.status : status as String,
            startScheduled: freezed == startScheduled ? _value.startScheduled : startScheduled as DateTime?,
            startActual: freezed == startActual ? _value.startActual : startActual as DateTime?,
            endActual: freezed == endActual ? _value.endActual : endActual as DateTime?,
            liveViewers: freezed == liveViewers ? _value.liveViewers : liveViewers as int?,
            description: freezed == description ? _value.description : description as String?,
            songcount: freezed == songcount ? _value.songcount : songcount as int?,
            channel: null == channel ? _value.channel : channel as ChannelMin,
            clips: freezed == clips ? _value.clips : clips as List<VideoWithChannel>?,
            sources: freezed == sources ? _value.sources : sources as List<VideoWithChannel>?,
            refers: freezed == refers ? _value.refers : refers as List<VideoWithChannel>?,
            simulcasts: freezed == simulcasts ? _value.simulcasts : simulcasts as List<VideoWithChannel>?,
            mentions: freezed == mentions ? _value.mentions : mentions as List<ChannelMinWithOrg>?,
            songs: freezed == songs ? _value.songs : songs as int?,
            certainty: freezed == certainty ? _value.certainty : certainty as String?,
            thumbnail: freezed == thumbnail ? _value.thumbnail : thumbnail as String?,
            link: freezed == link ? _value.link : link as String?,
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

abstract class _$$VideoFullImplCopyWith<$Res> implements $VideoFullCopyWith<$Res> {
  factory _$$VideoFullImplCopyWith(_$VideoFullImpl value, $Res Function(_$VideoFullImpl) then) = __$$VideoFullImplCopyWithImpl<$Res>;
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
    List<VideoWithChannel>? clips,
    List<VideoWithChannel>? sources,
    List<VideoWithChannel>? refers,
    List<VideoWithChannel>? simulcasts,
    List<ChannelMinWithOrg>? mentions,
    int? songs,
    String? certainty,
    String? thumbnail,
    String? link,
  });

  @override
  $ChannelMinCopyWith<$Res> get channel;
}

class __$$VideoFullImplCopyWithImpl<$Res> extends _$VideoFullCopyWithImpl<$Res, _$VideoFullImpl> implements _$$VideoFullImplCopyWith<$Res> {
  __$$VideoFullImplCopyWithImpl(_$VideoFullImpl _value, $Res Function(_$VideoFullImpl) _then) : super(_value, _then);

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
    Object? clips = freezed,
    Object? sources = freezed,
    Object? refers = freezed,
    Object? simulcasts = freezed,
    Object? mentions = freezed,
    Object? songs = freezed,
    Object? certainty = freezed,
    Object? thumbnail = freezed,
    Object? link = freezed,
  }) {
    return _then(
      _$VideoFullImpl(
        id: null == id ? _value.id : id as String,
        title: null == title ? _value.title : title as String,
        type: null == type ? _value.type : type as String,
        topicId: freezed == topicId ? _value.topicId : topicId as String?,
        publishedAt: freezed == publishedAt ? _value.publishedAt : publishedAt as DateTime?,
        availableAt: null == availableAt ? _value.availableAt : availableAt as DateTime,
        duration: null == duration ? _value.duration : duration as int,
        status: null == status ? _value.status : status as String,
        startScheduled: freezed == startScheduled ? _value.startScheduled : startScheduled as DateTime?,
        startActual: freezed == startActual ? _value.startActual : startActual as DateTime?,
        endActual: freezed == endActual ? _value.endActual : endActual as DateTime?,
        liveViewers: freezed == liveViewers ? _value.liveViewers : liveViewers as int?,
        description: freezed == description ? _value.description : description as String?,
        songcount: freezed == songcount ? _value.songcount : songcount as int?,
        channel: null == channel ? _value.channel : channel as ChannelMin,
        clips: freezed == clips ? _value._clips : clips as List<VideoWithChannel>?,
        sources: freezed == sources ? _value._sources : sources as List<VideoWithChannel>?,
        refers: freezed == refers ? _value._refers : refers as List<VideoWithChannel>?,
        simulcasts: freezed == simulcasts ? _value._simulcasts : simulcasts as List<VideoWithChannel>?,
        mentions: freezed == mentions ? _value._mentions : mentions as List<ChannelMinWithOrg>?,
        songs: freezed == songs ? _value.songs : songs as int?,
        certainty: freezed == certainty ? _value.certainty : certainty as String?,
        thumbnail: freezed == thumbnail ? _value.thumbnail : thumbnail as String?,
        link: freezed == link ? _value.link : link as String?,
      ),
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _$VideoFullImpl implements _VideoFull {
  const _$VideoFullImpl({
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
    final List<VideoWithChannel>? clips,
    final List<VideoWithChannel>? sources,
    final List<VideoWithChannel>? refers,
    final List<VideoWithChannel>? simulcasts,
    final List<ChannelMinWithOrg>? mentions,
    this.songs,
    this.certainty,
    this.thumbnail,
    this.link,
  }) : _clips = clips,
       _sources = sources,
       _refers = refers,
       _simulcasts = simulcasts,
       _mentions = mentions;

  factory _$VideoFullImpl.fromJson(Map<String, dynamic> json) => _$$VideoFullImplFromJson(json);

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
  final List<VideoWithChannel>? _clips;
  @override
  List<VideoWithChannel>? get clips {
    final value = _clips;
    if (value == null) return null;
    if (_clips is EqualUnmodifiableListView) return _clips;
    return EqualUnmodifiableListView(value);
  }

  final List<VideoWithChannel>? _sources;
  @override
  List<VideoWithChannel>? get sources {
    final value = _sources;
    if (value == null) return null;
    if (_sources is EqualUnmodifiableListView) return _sources;
    return EqualUnmodifiableListView(value);
  }

  final List<VideoWithChannel>? _refers;
  @override
  List<VideoWithChannel>? get refers {
    final value = _refers;
    if (value == null) return null;
    if (_refers is EqualUnmodifiableListView) return _refers;
    return EqualUnmodifiableListView(value);
  }

  final List<VideoWithChannel>? _simulcasts;
  @override
  List<VideoWithChannel>? get simulcasts {
    final value = _simulcasts;
    if (value == null) return null;
    if (_simulcasts is EqualUnmodifiableListView) return _simulcasts;
    return EqualUnmodifiableListView(value);
  }

  final List<ChannelMinWithOrg>? _mentions;
  @override
  List<ChannelMinWithOrg>? get mentions {
    final value = _mentions;
    if (value == null) return null;
    if (_mentions is EqualUnmodifiableListView) return _mentions;
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? songs;
  @override
  final String? certainty;
  @override
  final String? thumbnail;
  @override
  final String? link;

  @override
  String toString() {
    return 'VideoFull(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel, clips: $clips, sources: $sources, refers: $refers, simulcasts: $simulcasts, mentions: $mentions, songs: $songs, certainty: $certainty, thumbnail: $thumbnail, link: $link)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoFullImpl &&
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
            (identical(other.channel, channel) || other.channel == channel) &&
            const DeepCollectionEquality().equals(other._clips, _clips) &&
            const DeepCollectionEquality().equals(other._sources, _sources) &&
            const DeepCollectionEquality().equals(other._refers, _refers) &&
            const DeepCollectionEquality().equals(other._simulcasts, _simulcasts) &&
            const DeepCollectionEquality().equals(other._mentions, _mentions) &&
            (identical(other.songs, songs) || other.songs == songs) &&
            (identical(other.certainty, certainty) || other.certainty == certainty) &&
            (identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail) &&
            (identical(other.link, link) || other.link == link));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
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
    const DeepCollectionEquality().hash(_clips),
    const DeepCollectionEquality().hash(_sources),
    const DeepCollectionEquality().hash(_refers),
    const DeepCollectionEquality().hash(_simulcasts),
    const DeepCollectionEquality().hash(_mentions),
    songs,
    certainty,
    thumbnail,
    link,
  ]);

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoFullImplCopyWith<_$VideoFullImpl> get copyWith => __$$VideoFullImplCopyWithImpl<_$VideoFullImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoFullImplToJson(this);
  }
}

abstract class _VideoFull implements VideoFull {
  const factory _VideoFull({
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
    final List<VideoWithChannel>? clips,
    final List<VideoWithChannel>? sources,
    final List<VideoWithChannel>? refers,
    final List<VideoWithChannel>? simulcasts,
    final List<ChannelMinWithOrg>? mentions,
    final int? songs,
    final String? certainty,
    final String? thumbnail,
    final String? link,
  }) = _$VideoFullImpl;

  factory _VideoFull.fromJson(Map<String, dynamic> json) = _$VideoFullImpl.fromJson;

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
  List<VideoWithChannel>? get clips;
  @override
  List<VideoWithChannel>? get sources;
  @override
  List<VideoWithChannel>? get refers;
  @override
  List<VideoWithChannel>? get simulcasts;
  @override
  List<ChannelMinWithOrg>? get mentions;
  @override
  int? get songs;
  @override
  String? get certainty;
  @override
  String? get thumbnail;
  @override
  String? get link;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoFullImplCopyWith<_$VideoFullImpl> get copyWith => throw _privateConstructorUsedError;
}
