// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_instruction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationInstruction {

 String get videoId; NotificationEventType get eventType; String get channelId; String get channelName; String get videoTitle; String? get videoType; String? get channelAvatarUrl; DateTime get availableAt; String? get mentionTargetChannelId; String? get mentionTargetChannelName; String? get videoThumbnailUrl; String? get videoSourceLink;
/// Create a copy of NotificationInstruction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationInstructionCopyWith<NotificationInstruction> get copyWith => _$NotificationInstructionCopyWithImpl<NotificationInstruction>(this as NotificationInstruction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationInstruction&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.videoTitle, videoTitle) || other.videoTitle == videoTitle)&&(identical(other.videoType, videoType) || other.videoType == videoType)&&(identical(other.channelAvatarUrl, channelAvatarUrl) || other.channelAvatarUrl == channelAvatarUrl)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.mentionTargetChannelId, mentionTargetChannelId) || other.mentionTargetChannelId == mentionTargetChannelId)&&(identical(other.mentionTargetChannelName, mentionTargetChannelName) || other.mentionTargetChannelName == mentionTargetChannelName)&&(identical(other.videoThumbnailUrl, videoThumbnailUrl) || other.videoThumbnailUrl == videoThumbnailUrl)&&(identical(other.videoSourceLink, videoSourceLink) || other.videoSourceLink == videoSourceLink));
}


@override
int get hashCode => Object.hash(runtimeType,videoId,eventType,channelId,channelName,videoTitle,videoType,channelAvatarUrl,availableAt,mentionTargetChannelId,mentionTargetChannelName,videoThumbnailUrl,videoSourceLink);

@override
String toString() {
  return 'NotificationInstruction(videoId: $videoId, eventType: $eventType, channelId: $channelId, channelName: $channelName, videoTitle: $videoTitle, videoType: $videoType, channelAvatarUrl: $channelAvatarUrl, availableAt: $availableAt, mentionTargetChannelId: $mentionTargetChannelId, mentionTargetChannelName: $mentionTargetChannelName, videoThumbnailUrl: $videoThumbnailUrl, videoSourceLink: $videoSourceLink)';
}


}

/// @nodoc
abstract mixin class $NotificationInstructionCopyWith<$Res>  {
  factory $NotificationInstructionCopyWith(NotificationInstruction value, $Res Function(NotificationInstruction) _then) = _$NotificationInstructionCopyWithImpl;
@useResult
$Res call({
 String videoId, NotificationEventType eventType, String channelId, String channelName, String videoTitle, String? videoType, String? channelAvatarUrl, DateTime availableAt, String? mentionTargetChannelId, String? mentionTargetChannelName, String? videoThumbnailUrl, String? videoSourceLink
});




}
/// @nodoc
class _$NotificationInstructionCopyWithImpl<$Res>
    implements $NotificationInstructionCopyWith<$Res> {
  _$NotificationInstructionCopyWithImpl(this._self, this._then);

  final NotificationInstruction _self;
  final $Res Function(NotificationInstruction) _then;

/// Create a copy of NotificationInstruction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoId = null,Object? eventType = null,Object? channelId = null,Object? channelName = null,Object? videoTitle = null,Object? videoType = freezed,Object? channelAvatarUrl = freezed,Object? availableAt = null,Object? mentionTargetChannelId = freezed,Object? mentionTargetChannelName = freezed,Object? videoThumbnailUrl = freezed,Object? videoSourceLink = freezed,}) {
  return _then(_self.copyWith(
videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as NotificationEventType,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,channelName: null == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String,videoTitle: null == videoTitle ? _self.videoTitle : videoTitle // ignore: cast_nullable_to_non_nullable
as String,videoType: freezed == videoType ? _self.videoType : videoType // ignore: cast_nullable_to_non_nullable
as String?,channelAvatarUrl: freezed == channelAvatarUrl ? _self.channelAvatarUrl : channelAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,availableAt: null == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as DateTime,mentionTargetChannelId: freezed == mentionTargetChannelId ? _self.mentionTargetChannelId : mentionTargetChannelId // ignore: cast_nullable_to_non_nullable
as String?,mentionTargetChannelName: freezed == mentionTargetChannelName ? _self.mentionTargetChannelName : mentionTargetChannelName // ignore: cast_nullable_to_non_nullable
as String?,videoThumbnailUrl: freezed == videoThumbnailUrl ? _self.videoThumbnailUrl : videoThumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,videoSourceLink: freezed == videoSourceLink ? _self.videoSourceLink : videoSourceLink // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc


class _NotificationInstruction implements NotificationInstruction {
  const _NotificationInstruction({required this.videoId, required this.eventType, required this.channelId, required this.channelName, required this.videoTitle, this.videoType, this.channelAvatarUrl, required this.availableAt, this.mentionTargetChannelId, this.mentionTargetChannelName, this.videoThumbnailUrl, this.videoSourceLink});
  

@override final  String videoId;
@override final  NotificationEventType eventType;
@override final  String channelId;
@override final  String channelName;
@override final  String videoTitle;
@override final  String? videoType;
@override final  String? channelAvatarUrl;
@override final  DateTime availableAt;
@override final  String? mentionTargetChannelId;
@override final  String? mentionTargetChannelName;
@override final  String? videoThumbnailUrl;
@override final  String? videoSourceLink;

/// Create a copy of NotificationInstruction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationInstructionCopyWith<_NotificationInstruction> get copyWith => __$NotificationInstructionCopyWithImpl<_NotificationInstruction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationInstruction&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelName, channelName) || other.channelName == channelName)&&(identical(other.videoTitle, videoTitle) || other.videoTitle == videoTitle)&&(identical(other.videoType, videoType) || other.videoType == videoType)&&(identical(other.channelAvatarUrl, channelAvatarUrl) || other.channelAvatarUrl == channelAvatarUrl)&&(identical(other.availableAt, availableAt) || other.availableAt == availableAt)&&(identical(other.mentionTargetChannelId, mentionTargetChannelId) || other.mentionTargetChannelId == mentionTargetChannelId)&&(identical(other.mentionTargetChannelName, mentionTargetChannelName) || other.mentionTargetChannelName == mentionTargetChannelName)&&(identical(other.videoThumbnailUrl, videoThumbnailUrl) || other.videoThumbnailUrl == videoThumbnailUrl)&&(identical(other.videoSourceLink, videoSourceLink) || other.videoSourceLink == videoSourceLink));
}


@override
int get hashCode => Object.hash(runtimeType,videoId,eventType,channelId,channelName,videoTitle,videoType,channelAvatarUrl,availableAt,mentionTargetChannelId,mentionTargetChannelName,videoThumbnailUrl,videoSourceLink);

@override
String toString() {
  return 'NotificationInstruction(videoId: $videoId, eventType: $eventType, channelId: $channelId, channelName: $channelName, videoTitle: $videoTitle, videoType: $videoType, channelAvatarUrl: $channelAvatarUrl, availableAt: $availableAt, mentionTargetChannelId: $mentionTargetChannelId, mentionTargetChannelName: $mentionTargetChannelName, videoThumbnailUrl: $videoThumbnailUrl, videoSourceLink: $videoSourceLink)';
}


}

/// @nodoc
abstract mixin class _$NotificationInstructionCopyWith<$Res> implements $NotificationInstructionCopyWith<$Res> {
  factory _$NotificationInstructionCopyWith(_NotificationInstruction value, $Res Function(_NotificationInstruction) _then) = __$NotificationInstructionCopyWithImpl;
@override @useResult
$Res call({
 String videoId, NotificationEventType eventType, String channelId, String channelName, String videoTitle, String? videoType, String? channelAvatarUrl, DateTime availableAt, String? mentionTargetChannelId, String? mentionTargetChannelName, String? videoThumbnailUrl, String? videoSourceLink
});




}
/// @nodoc
class __$NotificationInstructionCopyWithImpl<$Res>
    implements _$NotificationInstructionCopyWith<$Res> {
  __$NotificationInstructionCopyWithImpl(this._self, this._then);

  final _NotificationInstruction _self;
  final $Res Function(_NotificationInstruction) _then;

/// Create a copy of NotificationInstruction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoId = null,Object? eventType = null,Object? channelId = null,Object? channelName = null,Object? videoTitle = null,Object? videoType = freezed,Object? channelAvatarUrl = freezed,Object? availableAt = null,Object? mentionTargetChannelId = freezed,Object? mentionTargetChannelName = freezed,Object? videoThumbnailUrl = freezed,Object? videoSourceLink = freezed,}) {
  return _then(_NotificationInstruction(
videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as NotificationEventType,channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,channelName: null == channelName ? _self.channelName : channelName // ignore: cast_nullable_to_non_nullable
as String,videoTitle: null == videoTitle ? _self.videoTitle : videoTitle // ignore: cast_nullable_to_non_nullable
as String,videoType: freezed == videoType ? _self.videoType : videoType // ignore: cast_nullable_to_non_nullable
as String?,channelAvatarUrl: freezed == channelAvatarUrl ? _self.channelAvatarUrl : channelAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,availableAt: null == availableAt ? _self.availableAt : availableAt // ignore: cast_nullable_to_non_nullable
as DateTime,mentionTargetChannelId: freezed == mentionTargetChannelId ? _self.mentionTargetChannelId : mentionTargetChannelId // ignore: cast_nullable_to_non_nullable
as String?,mentionTargetChannelName: freezed == mentionTargetChannelName ? _self.mentionTargetChannelName : mentionTargetChannelName // ignore: cast_nullable_to_non_nullable
as String?,videoThumbnailUrl: freezed == videoThumbnailUrl ? _self.videoThumbnailUrl : videoThumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,videoSourceLink: freezed == videoSourceLink ? _self.videoSourceLink : videoSourceLink // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
