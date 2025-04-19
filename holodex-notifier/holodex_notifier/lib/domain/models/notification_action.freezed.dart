// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_action.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

mixin _$NotificationAction {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId) schedule,
    required TResult Function(int notificationId, String? videoId, NotificationEventType? type) cancel,
    required TResult Function(NotificationInstruction instruction) dispatch,
    required TResult Function(String videoId, CachedVideosCompanion companion) updateCache,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult? Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult? Function(NotificationInstruction instruction)? dispatch,
    TResult? Function(String videoId, CachedVideosCompanion companion)? updateCache,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult Function(NotificationInstruction instruction)? dispatch,
    TResult Function(String videoId, CachedVideosCompanion companion)? updateCache,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScheduleNotificationAction value) schedule,
    required TResult Function(CancelNotificationAction value) cancel,
    required TResult Function(DispatchNotificationAction value) dispatch,
    required TResult Function(UpdateCacheAction value) updateCache,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScheduleNotificationAction value)? schedule,
    TResult? Function(CancelNotificationAction value)? cancel,
    TResult? Function(DispatchNotificationAction value)? dispatch,
    TResult? Function(UpdateCacheAction value)? updateCache,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScheduleNotificationAction value)? schedule,
    TResult Function(CancelNotificationAction value)? cancel,
    TResult Function(DispatchNotificationAction value)? dispatch,
    TResult Function(UpdateCacheAction value)? updateCache,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

abstract class $NotificationActionCopyWith<$Res> {
  factory $NotificationActionCopyWith(NotificationAction value, $Res Function(NotificationAction) then) =
      _$NotificationActionCopyWithImpl<$Res, NotificationAction>;
}

class _$NotificationActionCopyWithImpl<$Res, $Val extends NotificationAction> implements $NotificationActionCopyWith<$Res> {
  _$NotificationActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

abstract class _$$ScheduleNotificationActionImplCopyWith<$Res> {
  factory _$$ScheduleNotificationActionImplCopyWith(_$ScheduleNotificationActionImpl value, $Res Function(_$ScheduleNotificationActionImpl) then) =
      __$$ScheduleNotificationActionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({NotificationInstruction instruction, DateTime scheduleTime, String? videoId});

  $NotificationInstructionCopyWith<$Res> get instruction;
}

class __$$ScheduleNotificationActionImplCopyWithImpl<$Res> extends _$NotificationActionCopyWithImpl<$Res, _$ScheduleNotificationActionImpl>
    implements _$$ScheduleNotificationActionImplCopyWith<$Res> {
  __$$ScheduleNotificationActionImplCopyWithImpl(_$ScheduleNotificationActionImpl _value, $Res Function(_$ScheduleNotificationActionImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? instruction = null, Object? scheduleTime = null, Object? videoId = freezed}) {
    return _then(
      _$ScheduleNotificationActionImpl(
        instruction:
            null == instruction
                ? _value.instruction
                : instruction // ignore: cast_nullable_to_non_nullable
                    as NotificationInstruction,
        scheduleTime:
            null == scheduleTime
                ? _value.scheduleTime
                : scheduleTime // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        videoId:
            freezed == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $NotificationInstructionCopyWith<$Res> get instruction {
    return $NotificationInstructionCopyWith<$Res>(_value.instruction, (value) {
      return _then(_value.copyWith(instruction: value));
    });
  }
}

class _$ScheduleNotificationActionImpl implements ScheduleNotificationAction {
  const _$ScheduleNotificationActionImpl({required this.instruction, required this.scheduleTime, this.videoId});

  @override
  final NotificationInstruction instruction;
  @override
  final DateTime scheduleTime;
  @override
  final String? videoId;

  @override
  String toString() {
    return 'NotificationAction.schedule(instruction: $instruction, scheduleTime: $scheduleTime, videoId: $videoId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleNotificationActionImpl &&
            (identical(other.instruction, instruction) || other.instruction == instruction) &&
            (identical(other.scheduleTime, scheduleTime) || other.scheduleTime == scheduleTime) &&
            (identical(other.videoId, videoId) || other.videoId == videoId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, instruction, scheduleTime, videoId);

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleNotificationActionImplCopyWith<_$ScheduleNotificationActionImpl> get copyWith =>
      __$$ScheduleNotificationActionImplCopyWithImpl<_$ScheduleNotificationActionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId) schedule,
    required TResult Function(int notificationId, String? videoId, NotificationEventType? type) cancel,
    required TResult Function(NotificationInstruction instruction) dispatch,
    required TResult Function(String videoId, CachedVideosCompanion companion) updateCache,
  }) {
    return schedule(instruction, scheduleTime, videoId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult? Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult? Function(NotificationInstruction instruction)? dispatch,
    TResult? Function(String videoId, CachedVideosCompanion companion)? updateCache,
  }) {
    return schedule?.call(instruction, scheduleTime, videoId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult Function(NotificationInstruction instruction)? dispatch,
    TResult Function(String videoId, CachedVideosCompanion companion)? updateCache,
    required TResult orElse(),
  }) {
    if (schedule != null) {
      return schedule(instruction, scheduleTime, videoId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScheduleNotificationAction value) schedule,
    required TResult Function(CancelNotificationAction value) cancel,
    required TResult Function(DispatchNotificationAction value) dispatch,
    required TResult Function(UpdateCacheAction value) updateCache,
  }) {
    return schedule(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScheduleNotificationAction value)? schedule,
    TResult? Function(CancelNotificationAction value)? cancel,
    TResult? Function(DispatchNotificationAction value)? dispatch,
    TResult? Function(UpdateCacheAction value)? updateCache,
  }) {
    return schedule?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScheduleNotificationAction value)? schedule,
    TResult Function(CancelNotificationAction value)? cancel,
    TResult Function(DispatchNotificationAction value)? dispatch,
    TResult Function(UpdateCacheAction value)? updateCache,
    required TResult orElse(),
  }) {
    if (schedule != null) {
      return schedule(this);
    }
    return orElse();
  }
}

abstract class ScheduleNotificationAction implements NotificationAction {
  const factory ScheduleNotificationAction({
    required final NotificationInstruction instruction,
    required final DateTime scheduleTime,
    final String? videoId,
  }) = _$ScheduleNotificationActionImpl;

  NotificationInstruction get instruction;
  DateTime get scheduleTime;
  String? get videoId;

  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScheduleNotificationActionImplCopyWith<_$ScheduleNotificationActionImpl> get copyWith => throw _privateConstructorUsedError;
}

abstract class _$$CancelNotificationActionImplCopyWith<$Res> {
  factory _$$CancelNotificationActionImplCopyWith(_$CancelNotificationActionImpl value, $Res Function(_$CancelNotificationActionImpl) then) =
      __$$CancelNotificationActionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int notificationId, String? videoId, NotificationEventType? type});
}

class __$$CancelNotificationActionImplCopyWithImpl<$Res> extends _$NotificationActionCopyWithImpl<$Res, _$CancelNotificationActionImpl>
    implements _$$CancelNotificationActionImplCopyWith<$Res> {
  __$$CancelNotificationActionImplCopyWithImpl(_$CancelNotificationActionImpl _value, $Res Function(_$CancelNotificationActionImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notificationId = null, Object? videoId = freezed, Object? type = freezed}) {
    return _then(
      _$CancelNotificationActionImpl(
        notificationId:
            null == notificationId
                ? _value.notificationId
                : notificationId // ignore: cast_nullable_to_non_nullable
                    as int,
        videoId:
            freezed == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                    as String?,
        type:
            freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as NotificationEventType?,
      ),
    );
  }
}

class _$CancelNotificationActionImpl implements CancelNotificationAction {
  const _$CancelNotificationActionImpl({required this.notificationId, this.videoId, this.type});

  @override
  final int notificationId;
  @override
  final String? videoId;
  @override
  final NotificationEventType? type;

  @override
  String toString() {
    return 'NotificationAction.cancel(notificationId: $notificationId, videoId: $videoId, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CancelNotificationActionImpl &&
            (identical(other.notificationId, notificationId) || other.notificationId == notificationId) &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, notificationId, videoId, type);

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CancelNotificationActionImplCopyWith<_$CancelNotificationActionImpl> get copyWith =>
      __$$CancelNotificationActionImplCopyWithImpl<_$CancelNotificationActionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId) schedule,
    required TResult Function(int notificationId, String? videoId, NotificationEventType? type) cancel,
    required TResult Function(NotificationInstruction instruction) dispatch,
    required TResult Function(String videoId, CachedVideosCompanion companion) updateCache,
  }) {
    return cancel(notificationId, videoId, type);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult? Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult? Function(NotificationInstruction instruction)? dispatch,
    TResult? Function(String videoId, CachedVideosCompanion companion)? updateCache,
  }) {
    return cancel?.call(notificationId, videoId, type);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult Function(NotificationInstruction instruction)? dispatch,
    TResult Function(String videoId, CachedVideosCompanion companion)? updateCache,
    required TResult orElse(),
  }) {
    if (cancel != null) {
      return cancel(notificationId, videoId, type);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScheduleNotificationAction value) schedule,
    required TResult Function(CancelNotificationAction value) cancel,
    required TResult Function(DispatchNotificationAction value) dispatch,
    required TResult Function(UpdateCacheAction value) updateCache,
  }) {
    return cancel(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScheduleNotificationAction value)? schedule,
    TResult? Function(CancelNotificationAction value)? cancel,
    TResult? Function(DispatchNotificationAction value)? dispatch,
    TResult? Function(UpdateCacheAction value)? updateCache,
  }) {
    return cancel?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScheduleNotificationAction value)? schedule,
    TResult Function(CancelNotificationAction value)? cancel,
    TResult Function(DispatchNotificationAction value)? dispatch,
    TResult Function(UpdateCacheAction value)? updateCache,
    required TResult orElse(),
  }) {
    if (cancel != null) {
      return cancel(this);
    }
    return orElse();
  }
}

abstract class CancelNotificationAction implements NotificationAction {
  const factory CancelNotificationAction({required final int notificationId, final String? videoId, final NotificationEventType? type}) =
      _$CancelNotificationActionImpl;

  int get notificationId;
  String? get videoId;
  NotificationEventType? get type;

  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CancelNotificationActionImplCopyWith<_$CancelNotificationActionImpl> get copyWith => throw _privateConstructorUsedError;
}

abstract class _$$DispatchNotificationActionImplCopyWith<$Res> {
  factory _$$DispatchNotificationActionImplCopyWith(_$DispatchNotificationActionImpl value, $Res Function(_$DispatchNotificationActionImpl) then) =
      __$$DispatchNotificationActionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({NotificationInstruction instruction});

  $NotificationInstructionCopyWith<$Res> get instruction;
}

class __$$DispatchNotificationActionImplCopyWithImpl<$Res> extends _$NotificationActionCopyWithImpl<$Res, _$DispatchNotificationActionImpl>
    implements _$$DispatchNotificationActionImplCopyWith<$Res> {
  __$$DispatchNotificationActionImplCopyWithImpl(_$DispatchNotificationActionImpl _value, $Res Function(_$DispatchNotificationActionImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? instruction = null}) {
    return _then(
      _$DispatchNotificationActionImpl(
        instruction:
            null == instruction
                ? _value.instruction
                : instruction // ignore: cast_nullable_to_non_nullable
                    as NotificationInstruction,
      ),
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $NotificationInstructionCopyWith<$Res> get instruction {
    return $NotificationInstructionCopyWith<$Res>(_value.instruction, (value) {
      return _then(_value.copyWith(instruction: value));
    });
  }
}

class _$DispatchNotificationActionImpl implements DispatchNotificationAction {
  const _$DispatchNotificationActionImpl({required this.instruction});

  @override
  final NotificationInstruction instruction;

  @override
  String toString() {
    return 'NotificationAction.dispatch(instruction: $instruction)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DispatchNotificationActionImpl &&
            (identical(other.instruction, instruction) || other.instruction == instruction));
  }

  @override
  int get hashCode => Object.hash(runtimeType, instruction);

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DispatchNotificationActionImplCopyWith<_$DispatchNotificationActionImpl> get copyWith =>
      __$$DispatchNotificationActionImplCopyWithImpl<_$DispatchNotificationActionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId) schedule,
    required TResult Function(int notificationId, String? videoId, NotificationEventType? type) cancel,
    required TResult Function(NotificationInstruction instruction) dispatch,
    required TResult Function(String videoId, CachedVideosCompanion companion) updateCache,
  }) {
    return dispatch(instruction);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult? Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult? Function(NotificationInstruction instruction)? dispatch,
    TResult? Function(String videoId, CachedVideosCompanion companion)? updateCache,
  }) {
    return dispatch?.call(instruction);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult Function(NotificationInstruction instruction)? dispatch,
    TResult Function(String videoId, CachedVideosCompanion companion)? updateCache,
    required TResult orElse(),
  }) {
    if (dispatch != null) {
      return dispatch(instruction);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScheduleNotificationAction value) schedule,
    required TResult Function(CancelNotificationAction value) cancel,
    required TResult Function(DispatchNotificationAction value) dispatch,
    required TResult Function(UpdateCacheAction value) updateCache,
  }) {
    return dispatch(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScheduleNotificationAction value)? schedule,
    TResult? Function(CancelNotificationAction value)? cancel,
    TResult? Function(DispatchNotificationAction value)? dispatch,
    TResult? Function(UpdateCacheAction value)? updateCache,
  }) {
    return dispatch?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScheduleNotificationAction value)? schedule,
    TResult Function(CancelNotificationAction value)? cancel,
    TResult Function(DispatchNotificationAction value)? dispatch,
    TResult Function(UpdateCacheAction value)? updateCache,
    required TResult orElse(),
  }) {
    if (dispatch != null) {
      return dispatch(this);
    }
    return orElse();
  }
}

abstract class DispatchNotificationAction implements NotificationAction {
  const factory DispatchNotificationAction({required final NotificationInstruction instruction}) = _$DispatchNotificationActionImpl;

  NotificationInstruction get instruction;

  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DispatchNotificationActionImplCopyWith<_$DispatchNotificationActionImpl> get copyWith => throw _privateConstructorUsedError;
}

abstract class _$$UpdateCacheActionImplCopyWith<$Res> {
  factory _$$UpdateCacheActionImplCopyWith(_$UpdateCacheActionImpl value, $Res Function(_$UpdateCacheActionImpl) then) =
      __$$UpdateCacheActionImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String videoId, CachedVideosCompanion companion});
}

class __$$UpdateCacheActionImplCopyWithImpl<$Res> extends _$NotificationActionCopyWithImpl<$Res, _$UpdateCacheActionImpl>
    implements _$$UpdateCacheActionImplCopyWith<$Res> {
  __$$UpdateCacheActionImplCopyWithImpl(_$UpdateCacheActionImpl _value, $Res Function(_$UpdateCacheActionImpl) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? videoId = null, Object? companion = freezed}) {
    return _then(
      _$UpdateCacheActionImpl(
        videoId:
            null == videoId
                ? _value.videoId
                : videoId // ignore: cast_nullable_to_non_nullable
                    as String,
        companion:
            freezed == companion
                ? _value.companion
                : companion // ignore: cast_nullable_to_non_nullable
                    as CachedVideosCompanion,
      ),
    );
  }
}

class _$UpdateCacheActionImpl implements UpdateCacheAction {
  const _$UpdateCacheActionImpl({required this.videoId, required this.companion});

  @override
  final String videoId;
  @override
  final CachedVideosCompanion companion;

  @override
  String toString() {
    return 'NotificationAction.updateCache(videoId: $videoId, companion: $companion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateCacheActionImpl &&
            (identical(other.videoId, videoId) || other.videoId == videoId) &&
            const DeepCollectionEquality().equals(other.companion, companion));
  }

  @override
  int get hashCode => Object.hash(runtimeType, videoId, const DeepCollectionEquality().hash(companion));

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateCacheActionImplCopyWith<_$UpdateCacheActionImpl> get copyWith =>
      __$$UpdateCacheActionImplCopyWithImpl<_$UpdateCacheActionImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId) schedule,
    required TResult Function(int notificationId, String? videoId, NotificationEventType? type) cancel,
    required TResult Function(NotificationInstruction instruction) dispatch,
    required TResult Function(String videoId, CachedVideosCompanion companion) updateCache,
  }) {
    return updateCache(videoId, companion);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult? Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult? Function(NotificationInstruction instruction)? dispatch,
    TResult? Function(String videoId, CachedVideosCompanion companion)? updateCache,
  }) {
    return updateCache?.call(videoId, companion);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(NotificationInstruction instruction, DateTime scheduleTime, String? videoId)? schedule,
    TResult Function(int notificationId, String? videoId, NotificationEventType? type)? cancel,
    TResult Function(NotificationInstruction instruction)? dispatch,
    TResult Function(String videoId, CachedVideosCompanion companion)? updateCache,
    required TResult orElse(),
  }) {
    if (updateCache != null) {
      return updateCache(videoId, companion);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ScheduleNotificationAction value) schedule,
    required TResult Function(CancelNotificationAction value) cancel,
    required TResult Function(DispatchNotificationAction value) dispatch,
    required TResult Function(UpdateCacheAction value) updateCache,
  }) {
    return updateCache(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ScheduleNotificationAction value)? schedule,
    TResult? Function(CancelNotificationAction value)? cancel,
    TResult? Function(DispatchNotificationAction value)? dispatch,
    TResult? Function(UpdateCacheAction value)? updateCache,
  }) {
    return updateCache?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ScheduleNotificationAction value)? schedule,
    TResult Function(CancelNotificationAction value)? cancel,
    TResult Function(DispatchNotificationAction value)? dispatch,
    TResult Function(UpdateCacheAction value)? updateCache,
    required TResult orElse(),
  }) {
    if (updateCache != null) {
      return updateCache(this);
    }
    return orElse();
  }
}

abstract class UpdateCacheAction implements NotificationAction {
  const factory UpdateCacheAction({required final String videoId, required final CachedVideosCompanion companion}) = _$UpdateCacheActionImpl;

  String get videoId;
  CachedVideosCompanion get companion;

  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateCacheActionImplCopyWith<_$UpdateCacheActionImpl> get copyWith => throw _privateConstructorUsedError;
}
