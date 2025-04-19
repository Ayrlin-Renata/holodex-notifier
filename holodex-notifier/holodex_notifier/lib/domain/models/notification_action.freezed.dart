// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationAction {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationAction);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NotificationAction()';
}


}

/// @nodoc
class $NotificationActionCopyWith<$Res>  {
$NotificationActionCopyWith(NotificationAction _, $Res Function(NotificationAction) __);
}


/// @nodoc


class ScheduleNotificationAction implements NotificationAction {
  const ScheduleNotificationAction({required this.instruction, required this.scheduleTime, this.videoId});
  

 final  NotificationInstruction instruction;
 final  DateTime scheduleTime;
 final  String? videoId;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleNotificationActionCopyWith<ScheduleNotificationAction> get copyWith => _$ScheduleNotificationActionCopyWithImpl<ScheduleNotificationAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleNotificationAction&&(identical(other.instruction, instruction) || other.instruction == instruction)&&(identical(other.scheduleTime, scheduleTime) || other.scheduleTime == scheduleTime)&&(identical(other.videoId, videoId) || other.videoId == videoId));
}


@override
int get hashCode => Object.hash(runtimeType,instruction,scheduleTime,videoId);

@override
String toString() {
  return 'NotificationAction.schedule(instruction: $instruction, scheduleTime: $scheduleTime, videoId: $videoId)';
}


}

/// @nodoc
abstract mixin class $ScheduleNotificationActionCopyWith<$Res> implements $NotificationActionCopyWith<$Res> {
  factory $ScheduleNotificationActionCopyWith(ScheduleNotificationAction value, $Res Function(ScheduleNotificationAction) _then) = _$ScheduleNotificationActionCopyWithImpl;
@useResult
$Res call({
 NotificationInstruction instruction, DateTime scheduleTime, String? videoId
});


$NotificationInstructionCopyWith<$Res> get instruction;

}
/// @nodoc
class _$ScheduleNotificationActionCopyWithImpl<$Res>
    implements $ScheduleNotificationActionCopyWith<$Res> {
  _$ScheduleNotificationActionCopyWithImpl(this._self, this._then);

  final ScheduleNotificationAction _self;
  final $Res Function(ScheduleNotificationAction) _then;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? instruction = null,Object? scheduleTime = null,Object? videoId = freezed,}) {
  return _then(ScheduleNotificationAction(
instruction: null == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as NotificationInstruction,scheduleTime: null == scheduleTime ? _self.scheduleTime : scheduleTime // ignore: cast_nullable_to_non_nullable
as DateTime,videoId: freezed == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationInstructionCopyWith<$Res> get instruction {
  
  return $NotificationInstructionCopyWith<$Res>(_self.instruction, (value) {
    return _then(_self.copyWith(instruction: value));
  });
}
}

/// @nodoc


class CancelNotificationAction implements NotificationAction {
  const CancelNotificationAction({required this.notificationId, this.videoId, this.type});
  

 final  int notificationId;
 final  String? videoId;
 final  NotificationEventType? type;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CancelNotificationActionCopyWith<CancelNotificationAction> get copyWith => _$CancelNotificationActionCopyWithImpl<CancelNotificationAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CancelNotificationAction&&(identical(other.notificationId, notificationId) || other.notificationId == notificationId)&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,notificationId,videoId,type);

@override
String toString() {
  return 'NotificationAction.cancel(notificationId: $notificationId, videoId: $videoId, type: $type)';
}


}

/// @nodoc
abstract mixin class $CancelNotificationActionCopyWith<$Res> implements $NotificationActionCopyWith<$Res> {
  factory $CancelNotificationActionCopyWith(CancelNotificationAction value, $Res Function(CancelNotificationAction) _then) = _$CancelNotificationActionCopyWithImpl;
@useResult
$Res call({
 int notificationId, String? videoId, NotificationEventType? type
});




}
/// @nodoc
class _$CancelNotificationActionCopyWithImpl<$Res>
    implements $CancelNotificationActionCopyWith<$Res> {
  _$CancelNotificationActionCopyWithImpl(this._self, this._then);

  final CancelNotificationAction _self;
  final $Res Function(CancelNotificationAction) _then;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? notificationId = null,Object? videoId = freezed,Object? type = freezed,}) {
  return _then(CancelNotificationAction(
notificationId: null == notificationId ? _self.notificationId : notificationId // ignore: cast_nullable_to_non_nullable
as int,videoId: freezed == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as NotificationEventType?,
  ));
}


}

/// @nodoc


class DispatchNotificationAction implements NotificationAction {
  const DispatchNotificationAction({required this.instruction});
  

 final  NotificationInstruction instruction;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DispatchNotificationActionCopyWith<DispatchNotificationAction> get copyWith => _$DispatchNotificationActionCopyWithImpl<DispatchNotificationAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DispatchNotificationAction&&(identical(other.instruction, instruction) || other.instruction == instruction));
}


@override
int get hashCode => Object.hash(runtimeType,instruction);

@override
String toString() {
  return 'NotificationAction.dispatch(instruction: $instruction)';
}


}

/// @nodoc
abstract mixin class $DispatchNotificationActionCopyWith<$Res> implements $NotificationActionCopyWith<$Res> {
  factory $DispatchNotificationActionCopyWith(DispatchNotificationAction value, $Res Function(DispatchNotificationAction) _then) = _$DispatchNotificationActionCopyWithImpl;
@useResult
$Res call({
 NotificationInstruction instruction
});


$NotificationInstructionCopyWith<$Res> get instruction;

}
/// @nodoc
class _$DispatchNotificationActionCopyWithImpl<$Res>
    implements $DispatchNotificationActionCopyWith<$Res> {
  _$DispatchNotificationActionCopyWithImpl(this._self, this._then);

  final DispatchNotificationAction _self;
  final $Res Function(DispatchNotificationAction) _then;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? instruction = null,}) {
  return _then(DispatchNotificationAction(
instruction: null == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as NotificationInstruction,
  ));
}

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationInstructionCopyWith<$Res> get instruction {
  
  return $NotificationInstructionCopyWith<$Res>(_self.instruction, (value) {
    return _then(_self.copyWith(instruction: value));
  });
}
}

/// @nodoc


class UpdateCacheAction implements NotificationAction {
  const UpdateCacheAction({required this.videoId, required this.companion});
  

 final  String videoId;
 final  CachedVideosCompanion companion;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateCacheActionCopyWith<UpdateCacheAction> get copyWith => _$UpdateCacheActionCopyWithImpl<UpdateCacheAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateCacheAction&&(identical(other.videoId, videoId) || other.videoId == videoId)&&const DeepCollectionEquality().equals(other.companion, companion));
}


@override
int get hashCode => Object.hash(runtimeType,videoId,const DeepCollectionEquality().hash(companion));

@override
String toString() {
  return 'NotificationAction.updateCache(videoId: $videoId, companion: $companion)';
}


}

/// @nodoc
abstract mixin class $UpdateCacheActionCopyWith<$Res> implements $NotificationActionCopyWith<$Res> {
  factory $UpdateCacheActionCopyWith(UpdateCacheAction value, $Res Function(UpdateCacheAction) _then) = _$UpdateCacheActionCopyWithImpl;
@useResult
$Res call({
 String videoId, CachedVideosCompanion companion
});




}
/// @nodoc
class _$UpdateCacheActionCopyWithImpl<$Res>
    implements $UpdateCacheActionCopyWith<$Res> {
  _$UpdateCacheActionCopyWithImpl(this._self, this._then);

  final UpdateCacheAction _self;
  final $Res Function(UpdateCacheAction) _then;

/// Create a copy of NotificationAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? videoId = null,Object? companion = freezed,}) {
  return _then(UpdateCacheAction(
videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,companion: freezed == companion ? _self.companion : companion // ignore: cast_nullable_to_non_nullable
as CachedVideosCompanion,
  ));
}


}

// dart format on
