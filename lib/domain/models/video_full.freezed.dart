// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_full.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoFull {

 String get id; String get title; String get type; String? get topicId;@JsonKey(fromJson: _dateTimeFromString) DateTime? get publishedAt;@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime get availableAt; int get duration; String get status;@JsonKey(fromJson: _dateTimeFromString) DateTime? get startScheduled;@JsonKey(fromJson: _dateTimeFromString) DateTime? get startActual;@JsonKey(fromJson: _dateTimeFromString) DateTime? get endActual; int? get liveViewers; String? get description; int? get songcount; ChannelMin get channel; List<VideoWithChannel>? get clips; List<VideoWithChannel>? get sources; List<VideoWithChannel>? get refers; List<VideoWithChannel>? get simulcasts; List<ChannelMinWithOrg>? get mentions; int? get songs; String? get certainty; String? get thumbnail; String? get link;
/// Create a copy of VideoFull
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoFullCopyWith<VideoFull> get copyWith => _$VideoFullCopyWithImpl<VideoFull>(this as VideoFull, _$identity);

  /// Serializes this VideoFull to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoFull&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.status, status) || other.status == status)&&(identical(other.startScheduled, startScheduled) || other.startScheduled == startScheduled)&&(identical(other.startActual, startActual) || other.startActual == startActual)&&(identical(other.endActual, endActual) || other.endActual == endActual)&&(identical(other.liveViewers, liveViewers) || other.liveViewers == liveViewers)&&(identical(other.description, description) || other.description == description)&&(identical(other.songcount, songcount) || other.songcount == songcount)&&(identical(other.channel, channel) || other.channel == channel)&&const DeepCollectionEquality().equals(other.clips, clips)&&const DeepCollectionEquality().equals(other.sources, sources)&&const DeepCollectionEquality().equals(other.refers, refers)&&const DeepCollectionEquality().equals(other.simulcasts, simulcasts)&&const DeepCollectionEquality().equals(other.mentions, mentions)&&(identical(other.songs, songs) || other.songs == songs)&&(identical(other.certainty, certainty) || other.certainty == certainty)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,type,topicId,publishedAt,availableAt,duration,status,startScheduled,startActual,endActual,liveViewers,description,songcount,channel,const DeepCollectionEquality().hash(clips),const DeepCollectionEquality().hash(sources),const DeepCollectionEquality().hash(refers),const DeepCollectionEquality().hash(simulcasts),const DeepCollectionEquality().hash(mentions),songs,certainty,thumbnail,link]);

@override
String toString() {
  return 'VideoFull(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel, clips: $clips, sources: $sources, refers: $refers, simulcasts: $simulcasts, mentions: $mentions, songs: $songs, certainty: $certainty, thumbnail: $thumbnail, link: $link)';
}


}

/// @nodoc
abstract mixin class $VideoFullCopyWith<$Res>  {
  factory $VideoFullCopyWith(VideoFull value, $Res Function(VideoFull) _then) = _$VideoFullCopyWithImpl;
@useResult
$Res call({
 String id, String title, String type, String? topicId,@JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt, int duration, String status,@JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,@JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,@JsonKey(fromJson: _dateTimeFromString) DateTime? endActual, int? liveViewers, String? description, int? songcount, ChannelMin channel, List<VideoWithChannel>? clips, List<VideoWithChannel>? sources, List<VideoWithChannel>? refers, List<VideoWithChannel>? simulcasts, List<ChannelMinWithOrg>? mentions, int? songs, String? certainty, String? thumbnail, String? link
});


$ChannelMinCopyWith<$Res> get channel;

}
/// @nodoc
class _$VideoFullCopyWithImpl<$Res>
    implements $VideoFullCopyWith<$Res> {
  _$VideoFullCopyWithImpl(this._self, this._then);

  final VideoFull _self;
  final $Res Function(VideoFull) _then;

/// Create a copy of VideoFull
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? type = null,Object? topicId = freezed,Object? publishedAt = freezed,Object? availableAt = null,Object? duration = null,Object? status = null,Object? startScheduled = freezed,Object? startActual = freezed,Object? endActual = freezed,Object? liveViewers = freezed,Object? description = freezed,Object? songcount = freezed,Object? channel = null,Object? clips = freezed,Object? sources = freezed,Object? refers = freezed,Object? simulcasts = freezed,Object? mentions = freezed,Object? songs = freezed,Object? certainty = freezed,Object? thumbnail = freezed,Object? link = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,topicId: freezed == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,availableAt: null == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startScheduled: freezed == startScheduled ? _self.startScheduled : startScheduled // ignore: cast_nullable_to_non_nullable
as DateTime?,startActual: freezed == startActual ? _self.startActual : startActual // ignore: cast_nullable_to_non_nullable
as DateTime?,endActual: freezed == endActual ? _self.endActual : endActual // ignore: cast_nullable_to_non_nullable
as DateTime?,liveViewers: freezed == liveViewers ? _self.liveViewers : liveViewers // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,songcount: freezed == songcount ? _self.songcount : songcount // ignore: cast_nullable_to_non_nullable
as int?,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as ChannelMin,clips: freezed == clips ? _self.clips : clips // ignore: cast_nullable_to_non_nullable
as List<VideoWithChannel>?,sources: freezed == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<VideoWithChannel>?,refers: freezed == refers ? _self.refers : refers // ignore: cast_nullable_to_non_nullable
as List<VideoWithChannel>?,simulcasts: freezed == simulcasts ? _self.simulcasts : simulcasts // ignore: cast_nullable_to_non_nullable
as List<VideoWithChannel>?,mentions: freezed == mentions ? _self.mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<ChannelMinWithOrg>?,songs: freezed == songs ? _self.songs : songs // ignore: cast_nullable_to_non_nullable
as int?,certainty: freezed == certainty ? _self.certainty : certainty // ignore: cast_nullable_to_non_nullable
as String?,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of VideoFull
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChannelMinCopyWith<$Res> get channel {
  
  return $ChannelMinCopyWith<$Res>(_self.channel, (value) {
    return _then(_self.copyWith(channel: value));
  });
}
}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _VideoFull implements VideoFull {
  const _VideoFull({required this.id, required this.title, required this.type, this.topicId, @JsonKey(fromJson: _dateTimeFromString) this.publishedAt, @JsonKey(fromJson: _dateTimeFromStringRequired) required this.availableAt, required this.duration, required this.status, @JsonKey(fromJson: _dateTimeFromString) this.startScheduled, @JsonKey(fromJson: _dateTimeFromString) this.startActual, @JsonKey(fromJson: _dateTimeFromString) this.endActual, this.liveViewers, this.description, this.songcount, required this.channel, final  List<VideoWithChannel>? clips, final  List<VideoWithChannel>? sources, final  List<VideoWithChannel>? refers, final  List<VideoWithChannel>? simulcasts, final  List<ChannelMinWithOrg>? mentions, this.songs, this.certainty, this.thumbnail, this.link}): _clips = clips,_sources = sources,_refers = refers,_simulcasts = simulcasts,_mentions = mentions;
  factory _VideoFull.fromJson(Map<String, dynamic> json) => _$VideoFullFromJson(json);

@override final  String id;
@override final  String title;
@override final  String type;
@override final  String? topicId;
@override@JsonKey(fromJson: _dateTimeFromString) final  DateTime? publishedAt;
@override@JsonKey(fromJson: _dateTimeFromStringRequired) final  DateTime availableAt;
@override final  int duration;
@override final  String status;
@override@JsonKey(fromJson: _dateTimeFromString) final  DateTime? startScheduled;
@override@JsonKey(fromJson: _dateTimeFromString) final  DateTime? startActual;
@override@JsonKey(fromJson: _dateTimeFromString) final  DateTime? endActual;
@override final  int? liveViewers;
@override final  String? description;
@override final  int? songcount;
@override final  ChannelMin channel;
 final  List<VideoWithChannel>? _clips;
@override List<VideoWithChannel>? get clips {
  final value = _clips;
  if (value == null) return null;
  if (_clips is EqualUnmodifiableListView) return _clips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<VideoWithChannel>? _sources;
@override List<VideoWithChannel>? get sources {
  final value = _sources;
  if (value == null) return null;
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<VideoWithChannel>? _refers;
@override List<VideoWithChannel>? get refers {
  final value = _refers;
  if (value == null) return null;
  if (_refers is EqualUnmodifiableListView) return _refers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<VideoWithChannel>? _simulcasts;
@override List<VideoWithChannel>? get simulcasts {
  final value = _simulcasts;
  if (value == null) return null;
  if (_simulcasts is EqualUnmodifiableListView) return _simulcasts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<ChannelMinWithOrg>? _mentions;
@override List<ChannelMinWithOrg>? get mentions {
  final value = _mentions;
  if (value == null) return null;
  if (_mentions is EqualUnmodifiableListView) return _mentions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? songs;
@override final  String? certainty;
@override final  String? thumbnail;
@override final  String? link;

/// Create a copy of VideoFull
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoFullCopyWith<_VideoFull> get copyWith => __$VideoFullCopyWithImpl<_VideoFull>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoFullToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoFull&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.status, status) || other.status == status)&&(identical(other.startScheduled, startScheduled) || other.startScheduled == startScheduled)&&(identical(other.startActual, startActual) || other.startActual == startActual)&&(identical(other.endActual, endActual) || other.endActual == endActual)&&(identical(other.liveViewers, liveViewers) || other.liveViewers == liveViewers)&&(identical(other.description, description) || other.description == description)&&(identical(other.songcount, songcount) || other.songcount == songcount)&&(identical(other.channel, channel) || other.channel == channel)&&const DeepCollectionEquality().equals(other._clips, _clips)&&const DeepCollectionEquality().equals(other._sources, _sources)&&const DeepCollectionEquality().equals(other._refers, _refers)&&const DeepCollectionEquality().equals(other._simulcasts, _simulcasts)&&const DeepCollectionEquality().equals(other._mentions, _mentions)&&(identical(other.songs, songs) || other.songs == songs)&&(identical(other.certainty, certainty) || other.certainty == certainty)&&(identical(other.thumbnail, thumbnail) || other.thumbnail == thumbnail)&&(identical(other.link, link) || other.link == link));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,type,topicId,publishedAt,availableAt,duration,status,startScheduled,startActual,endActual,liveViewers,description,songcount,channel,const DeepCollectionEquality().hash(_clips),const DeepCollectionEquality().hash(_sources),const DeepCollectionEquality().hash(_refers),const DeepCollectionEquality().hash(_simulcasts),const DeepCollectionEquality().hash(_mentions),songs,certainty,thumbnail,link]);

@override
String toString() {
  return 'VideoFull(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel, clips: $clips, sources: $sources, refers: $refers, simulcasts: $simulcasts, mentions: $mentions, songs: $songs, certainty: $certainty, thumbnail: $thumbnail, link: $link)';
}


}

/// @nodoc
abstract mixin class _$VideoFullCopyWith<$Res> implements $VideoFullCopyWith<$Res> {
  factory _$VideoFullCopyWith(_VideoFull value, $Res Function(_VideoFull) _then) = __$VideoFullCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String type, String? topicId,@JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt, int duration, String status,@JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,@JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,@JsonKey(fromJson: _dateTimeFromString) DateTime? endActual, int? liveViewers, String? description, int? songcount, ChannelMin channel, List<VideoWithChannel>? clips, List<VideoWithChannel>? sources, List<VideoWithChannel>? refers, List<VideoWithChannel>? simulcasts, List<ChannelMinWithOrg>? mentions, int? songs, String? certainty, String? thumbnail, String? link
});


@override $ChannelMinCopyWith<$Res> get channel;

}
/// @nodoc
class __$VideoFullCopyWithImpl<$Res>
    implements _$VideoFullCopyWith<$Res> {
  __$VideoFullCopyWithImpl(this._self, this._then);

  final _VideoFull _self;
  final $Res Function(_VideoFull) _then;

/// Create a copy of VideoFull
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? type = null,Object? topicId = freezed,Object? publishedAt = freezed,Object? availableAt = null,Object? duration = null,Object? status = null,Object? startScheduled = freezed,Object? startActual = freezed,Object? endActual = freezed,Object? liveViewers = freezed,Object? description = freezed,Object? songcount = freezed,Object? channel = null,Object? clips = freezed,Object? sources = freezed,Object? refers = freezed,Object? simulcasts = freezed,Object? mentions = freezed,Object? songs = freezed,Object? certainty = freezed,Object? thumbnail = freezed,Object? link = freezed,}) {
  return _then(_VideoFull(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,topicId: freezed == topicId ? _self.topicId : topicId // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,availableAt: null == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,startScheduled: freezed == startScheduled ? _self.startScheduled : startScheduled // ignore: cast_nullable_to_non_nullable
as DateTime?,startActual: freezed == startActual ? _self.startActual : startActual // ignore: cast_nullable_to_non_nullable
as DateTime?,endActual: freezed == endActual ? _self.endActual : endActual // ignore: cast_nullable_to_non_nullable
as DateTime?,liveViewers: freezed == liveViewers ? _self.liveViewers : liveViewers // ignore: cast_nullable_to_non_nullable
as int?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,songcount: freezed == songcount ? _self.songcount : songcount // ignore: cast_nullable_to_non_nullable
as int?,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as ChannelMin,clips: freezed == clips ? _self._clips : clips // ignore: cast_nullable_to_non_nullable
as List<VideoWithChannel>?,sources: freezed == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<VideoWithChannel>?,refers: freezed == refers ? _self._refers : refers // ignore: cast_nullable_to_non_nullable
as List<VideoWithChannel>?,simulcasts: freezed == simulcasts ? _self._simulcasts : simulcasts // ignore: cast_nullable_to_non_nullable
as List<VideoWithChannel>?,mentions: freezed == mentions ? _self._mentions : mentions // ignore: cast_nullable_to_non_nullable
as List<ChannelMinWithOrg>?,songs: freezed == songs ? _self.songs : songs // ignore: cast_nullable_to_non_nullable
as int?,certainty: freezed == certainty ? _self.certainty : certainty // ignore: cast_nullable_to_non_nullable
as String?,thumbnail: freezed == thumbnail ? _self.thumbnail : thumbnail // ignore: cast_nullable_to_non_nullable
as String?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of VideoFull
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChannelMinCopyWith<$Res> get channel {
  
  return $ChannelMinCopyWith<$Res>(_self.channel, (value) {
    return _then(_self.copyWith(channel: value));
  });
}
}

// dart format on
