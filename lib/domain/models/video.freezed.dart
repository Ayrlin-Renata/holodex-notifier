// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Video {

 String get id; String get title; String get type; String? get topicId;@JsonKey(fromJson: _dateTimeFromString) DateTime? get publishedAt;@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime get availableAt; int get duration; String get status;@JsonKey(fromJson: _dateTimeFromString) DateTime? get startScheduled;@JsonKey(fromJson: _dateTimeFromString) DateTime? get startActual;@JsonKey(fromJson: _dateTimeFromString) DateTime? get endActual; int? get liveViewers; String? get description; int? get songcount; ChannelMin get channel;
/// Create a copy of Video
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoCopyWith<Video> get copyWith => _$VideoCopyWithImpl<Video>(this as Video, _$identity);

  /// Serializes this Video to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Video&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.status, status) || other.status == status)&&(identical(other.startScheduled, startScheduled) || other.startScheduled == startScheduled)&&(identical(other.startActual, startActual) || other.startActual == startActual)&&(identical(other.endActual, endActual) || other.endActual == endActual)&&(identical(other.liveViewers, liveViewers) || other.liveViewers == liveViewers)&&(identical(other.description, description) || other.description == description)&&(identical(other.songcount, songcount) || other.songcount == songcount)&&(identical(other.channel, channel) || other.channel == channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,topicId,publishedAt,availableAt,duration,status,startScheduled,startActual,endActual,liveViewers,description,songcount,channel);

@override
String toString() {
  return 'Video(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel)';
}


}

/// @nodoc
abstract mixin class $VideoCopyWith<$Res>  {
  factory $VideoCopyWith(Video value, $Res Function(Video) _then) = _$VideoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String type, String? topicId,@JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt, int duration, String status,@JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,@JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,@JsonKey(fromJson: _dateTimeFromString) DateTime? endActual, int? liveViewers, String? description, int? songcount, ChannelMin channel
});


$ChannelMinCopyWith<$Res> get channel;

}
/// @nodoc
class _$VideoCopyWithImpl<$Res>
    implements $VideoCopyWith<$Res> {
  _$VideoCopyWithImpl(this._self, this._then);

  final Video _self;
  final $Res Function(Video) _then;

/// Create a copy of Video
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? type = null,Object? topicId = freezed,Object? publishedAt = freezed,Object? availableAt = null,Object? duration = null,Object? status = null,Object? startScheduled = freezed,Object? startActual = freezed,Object? endActual = freezed,Object? liveViewers = freezed,Object? description = freezed,Object? songcount = freezed,Object? channel = null,}) {
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
as ChannelMin,
  ));
}
/// Create a copy of Video
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
class _Video implements Video {
  const _Video({required this.id, required this.title, required this.type, this.topicId, @JsonKey(fromJson: _dateTimeFromString) this.publishedAt, @JsonKey(fromJson: _dateTimeFromStringRequired) required this.availableAt, required this.duration, required this.status, @JsonKey(fromJson: _dateTimeFromString) this.startScheduled, @JsonKey(fromJson: _dateTimeFromString) this.startActual, @JsonKey(fromJson: _dateTimeFromString) this.endActual, this.liveViewers, this.description, this.songcount, required this.channel});
  factory _Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

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

/// Create a copy of Video
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoCopyWith<_Video> get copyWith => __$VideoCopyWithImpl<_Video>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Video&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.status, status) || other.status == status)&&(identical(other.startScheduled, startScheduled) || other.startScheduled == startScheduled)&&(identical(other.startActual, startActual) || other.startActual == startActual)&&(identical(other.endActual, endActual) || other.endActual == endActual)&&(identical(other.liveViewers, liveViewers) || other.liveViewers == liveViewers)&&(identical(other.description, description) || other.description == description)&&(identical(other.songcount, songcount) || other.songcount == songcount)&&(identical(other.channel, channel) || other.channel == channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,topicId,publishedAt,availableAt,duration,status,startScheduled,startActual,endActual,liveViewers,description,songcount,channel);

@override
String toString() {
  return 'Video(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel)';
}


}

/// @nodoc
abstract mixin class _$VideoCopyWith<$Res> implements $VideoCopyWith<$Res> {
  factory _$VideoCopyWith(_Video value, $Res Function(_Video) _then) = __$VideoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String type, String? topicId,@JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt, int duration, String status,@JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,@JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,@JsonKey(fromJson: _dateTimeFromString) DateTime? endActual, int? liveViewers, String? description, int? songcount, ChannelMin channel
});


@override $ChannelMinCopyWith<$Res> get channel;

}
/// @nodoc
class __$VideoCopyWithImpl<$Res>
    implements _$VideoCopyWith<$Res> {
  __$VideoCopyWithImpl(this._self, this._then);

  final _Video _self;
  final $Res Function(_Video) _then;

/// Create a copy of Video
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? type = null,Object? topicId = freezed,Object? publishedAt = freezed,Object? availableAt = null,Object? duration = null,Object? status = null,Object? startScheduled = freezed,Object? startActual = freezed,Object? endActual = freezed,Object? liveViewers = freezed,Object? description = freezed,Object? songcount = freezed,Object? channel = null,}) {
  return _then(_Video(
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
as ChannelMin,
  ));
}

/// Create a copy of Video
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
mixin _$VideoWithChannel {

 String get id; String get title; String get type; String? get topicId;@JsonKey(fromJson: _dateTimeFromString) DateTime? get publishedAt;@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime get availableAt; int get duration; String get status;@JsonKey(fromJson: _dateTimeFromString) DateTime? get startScheduled;@JsonKey(fromJson: _dateTimeFromString) DateTime? get startActual;@JsonKey(fromJson: _dateTimeFromString) DateTime? get endActual; int? get liveViewers; String? get description; int? get songcount; ChannelMin get channel;
/// Create a copy of VideoWithChannel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoWithChannelCopyWith<VideoWithChannel> get copyWith => _$VideoWithChannelCopyWithImpl<VideoWithChannel>(this as VideoWithChannel, _$identity);

  /// Serializes this VideoWithChannel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoWithChannel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.status, status) || other.status == status)&&(identical(other.startScheduled, startScheduled) || other.startScheduled == startScheduled)&&(identical(other.startActual, startActual) || other.startActual == startActual)&&(identical(other.endActual, endActual) || other.endActual == endActual)&&(identical(other.liveViewers, liveViewers) || other.liveViewers == liveViewers)&&(identical(other.description, description) || other.description == description)&&(identical(other.songcount, songcount) || other.songcount == songcount)&&(identical(other.channel, channel) || other.channel == channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,topicId,publishedAt,availableAt,duration,status,startScheduled,startActual,endActual,liveViewers,description,songcount,channel);

@override
String toString() {
  return 'VideoWithChannel(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel)';
}


}

/// @nodoc
abstract mixin class $VideoWithChannelCopyWith<$Res>  {
  factory $VideoWithChannelCopyWith(VideoWithChannel value, $Res Function(VideoWithChannel) _then) = _$VideoWithChannelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String type, String? topicId,@JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt, int duration, String status,@JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,@JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,@JsonKey(fromJson: _dateTimeFromString) DateTime? endActual, int? liveViewers, String? description, int? songcount, ChannelMin channel
});


$ChannelMinCopyWith<$Res> get channel;

}
/// @nodoc
class _$VideoWithChannelCopyWithImpl<$Res>
    implements $VideoWithChannelCopyWith<$Res> {
  _$VideoWithChannelCopyWithImpl(this._self, this._then);

  final VideoWithChannel _self;
  final $Res Function(VideoWithChannel) _then;

/// Create a copy of VideoWithChannel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? type = null,Object? topicId = freezed,Object? publishedAt = freezed,Object? availableAt = null,Object? duration = null,Object? status = null,Object? startScheduled = freezed,Object? startActual = freezed,Object? endActual = freezed,Object? liveViewers = freezed,Object? description = freezed,Object? songcount = freezed,Object? channel = null,}) {
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
as ChannelMin,
  ));
}
/// Create a copy of VideoWithChannel
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
class _VideoWithChannel implements VideoWithChannel {
  const _VideoWithChannel({required this.id, required this.title, required this.type, this.topicId, @JsonKey(fromJson: _dateTimeFromString) this.publishedAt, @JsonKey(fromJson: _dateTimeFromStringRequired) required this.availableAt, required this.duration, required this.status, @JsonKey(fromJson: _dateTimeFromString) this.startScheduled, @JsonKey(fromJson: _dateTimeFromString) this.startActual, @JsonKey(fromJson: _dateTimeFromString) this.endActual, this.liveViewers, this.description, this.songcount, required this.channel});
  factory _VideoWithChannel.fromJson(Map<String, dynamic> json) => _$VideoWithChannelFromJson(json);

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

/// Create a copy of VideoWithChannel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoWithChannelCopyWith<_VideoWithChannel> get copyWith => __$VideoWithChannelCopyWithImpl<_VideoWithChannel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoWithChannelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoWithChannel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.type, type) || other.type == type)&&(identical(other.topicId, topicId) || other.topicId == topicId)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.status, status) || other.status == status)&&(identical(other.startScheduled, startScheduled) || other.startScheduled == startScheduled)&&(identical(other.startActual, startActual) || other.startActual == startActual)&&(identical(other.endActual, endActual) || other.endActual == endActual)&&(identical(other.liveViewers, liveViewers) || other.liveViewers == liveViewers)&&(identical(other.description, description) || other.description == description)&&(identical(other.songcount, songcount) || other.songcount == songcount)&&(identical(other.channel, channel) || other.channel == channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,type,topicId,publishedAt,availableAt,duration,status,startScheduled,startActual,endActual,liveViewers,description,songcount,channel);

@override
String toString() {
  return 'VideoWithChannel(id: $id, title: $title, type: $type, topicId: $topicId, publishedAt: $publishedAt, availableAt: $availableAt, duration: $duration, status: $status, startScheduled: $startScheduled, startActual: $startActual, endActual: $endActual, liveViewers: $liveViewers, description: $description, songcount: $songcount, channel: $channel)';
}


}

/// @nodoc
abstract mixin class _$VideoWithChannelCopyWith<$Res> implements $VideoWithChannelCopyWith<$Res> {
  factory _$VideoWithChannelCopyWith(_VideoWithChannel value, $Res Function(_VideoWithChannel) _then) = __$VideoWithChannelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String type, String? topicId,@JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,@JsonKey(fromJson: _dateTimeFromStringRequired) DateTime availableAt, int duration, String status,@JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,@JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,@JsonKey(fromJson: _dateTimeFromString) DateTime? endActual, int? liveViewers, String? description, int? songcount, ChannelMin channel
});


@override $ChannelMinCopyWith<$Res> get channel;

}
/// @nodoc
class __$VideoWithChannelCopyWithImpl<$Res>
    implements _$VideoWithChannelCopyWith<$Res> {
  __$VideoWithChannelCopyWithImpl(this._self, this._then);

  final _VideoWithChannel _self;
  final $Res Function(_VideoWithChannel) _then;

/// Create a copy of VideoWithChannel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? type = null,Object? topicId = freezed,Object? publishedAt = freezed,Object? availableAt = null,Object? duration = null,Object? status = null,Object? startScheduled = freezed,Object? startActual = freezed,Object? endActual = freezed,Object? liveViewers = freezed,Object? description = freezed,Object? songcount = freezed,Object? channel = null,}) {
  return _then(_VideoWithChannel(
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
as ChannelMin,
  ));
}

/// Create a copy of VideoWithChannel
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
