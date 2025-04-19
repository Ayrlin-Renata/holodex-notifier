// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_min.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChannelMin _$ChannelMinFromJson(Map<String, dynamic> json) {
  return _ChannelMin.fromJson(json);
}

mixin _$ChannelMin {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get englishName => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get photo => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelMinCopyWith<ChannelMin> get copyWith => throw _privateConstructorUsedError;
}

abstract class $ChannelMinCopyWith<$Res> {
  factory $ChannelMinCopyWith(ChannelMin value, $Res Function(ChannelMin) then) = _$ChannelMinCopyWithImpl<$Res, ChannelMin>;
  @useResult
  $Res call({String id, String name, String? englishName, String type, String? photo});
}

class _$ChannelMinCopyWithImpl<$Res, $Val extends ChannelMin> implements $ChannelMinCopyWith<$Res> {
  _$ChannelMinCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? englishName = freezed, Object? type = null, Object? photo = freezed}) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            englishName:
                freezed == englishName
                    ? _value.englishName
                    : englishName // ignore: cast_nullable_to_non_nullable
                        as String?,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String,
            photo:
                freezed == photo
                    ? _value.photo
                    : photo // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

abstract class _$$ChannelMinImplCopyWith<$Res> implements $ChannelMinCopyWith<$Res> {
  factory _$$ChannelMinImplCopyWith(_$ChannelMinImpl value, $Res Function(_$ChannelMinImpl) then) = __$$ChannelMinImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? englishName, String type, String? photo});
}

class __$$ChannelMinImplCopyWithImpl<$Res> extends _$ChannelMinCopyWithImpl<$Res, _$ChannelMinImpl> implements _$$ChannelMinImplCopyWith<$Res> {
  __$$ChannelMinImplCopyWithImpl(_$ChannelMinImpl _value, $Res Function(_$ChannelMinImpl) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? englishName = freezed, Object? type = null, Object? photo = freezed}) {
    return _then(
      _$ChannelMinImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        englishName:
            freezed == englishName
                ? _value.englishName
                : englishName // ignore: cast_nullable_to_non_nullable
                    as String?,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String,
        photo:
            freezed == photo
                ? _value.photo
                : photo // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ChannelMinImpl implements _ChannelMin {
  const _$ChannelMinImpl({required this.id, required this.name, this.englishName, this.type = 'vtuber', this.photo});

  factory _$ChannelMinImpl.fromJson(Map<String, dynamic> json) => _$$ChannelMinImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? englishName;
  @override
  @JsonKey()
  final String type;
  @override
  final String? photo;

  @override
  String toString() {
    return 'ChannelMin(id: $id, name: $name, englishName: $englishName, type: $type, photo: $photo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelMinImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.englishName, englishName) || other.englishName == englishName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.photo, photo) || other.photo == photo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, englishName, type, photo);

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelMinImplCopyWith<_$ChannelMinImpl> get copyWith => __$$ChannelMinImplCopyWithImpl<_$ChannelMinImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelMinImplToJson(this);
  }
}

abstract class _ChannelMin implements ChannelMin {
  const factory _ChannelMin({
    required final String id,
    required final String name,
    final String? englishName,
    final String type,
    final String? photo,
  }) = _$ChannelMinImpl;

  factory _ChannelMin.fromJson(Map<String, dynamic> json) = _$ChannelMinImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get englishName;
  @override
  String get type;
  @override
  String? get photo;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelMinImplCopyWith<_$ChannelMinImpl> get copyWith => throw _privateConstructorUsedError;
}
