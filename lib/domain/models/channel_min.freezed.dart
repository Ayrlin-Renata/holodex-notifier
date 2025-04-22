// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_min.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelMin {

 String get id; String get name; String? get englishName; String get type; String? get photo;
/// Create a copy of ChannelMin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelMinCopyWith<ChannelMin> get copyWith => _$ChannelMinCopyWithImpl<ChannelMin>(this as ChannelMin, _$identity);

  /// Serializes this ChannelMin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelMin&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.englishName, englishName) || other.englishName == englishName)&&(identical(other.type, type) || other.type == type)&&(identical(other.photo, photo) || other.photo == photo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,englishName,type,photo);

@override
String toString() {
  return 'ChannelMin(id: $id, name: $name, englishName: $englishName, type: $type, photo: $photo)';
}


}

/// @nodoc
abstract mixin class $ChannelMinCopyWith<$Res>  {
  factory $ChannelMinCopyWith(ChannelMin value, $Res Function(ChannelMin) _then) = _$ChannelMinCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? englishName, String type, String? photo
});




}
/// @nodoc
class _$ChannelMinCopyWithImpl<$Res>
    implements $ChannelMinCopyWith<$Res> {
  _$ChannelMinCopyWithImpl(this._self, this._then);

  final ChannelMin _self;
  final $Res Function(ChannelMin) _then;

/// Create a copy of ChannelMin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? englishName = freezed,Object? type = null,Object? photo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,englishName: freezed == englishName ? _self.englishName : englishName // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ChannelMin implements ChannelMin {
  const _ChannelMin({required this.id, required this.name, this.englishName, this.type = 'vtuber', this.photo});
  factory _ChannelMin.fromJson(Map<String, dynamic> json) => _$ChannelMinFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? englishName;
@override@JsonKey() final  String type;
@override final  String? photo;

/// Create a copy of ChannelMin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelMinCopyWith<_ChannelMin> get copyWith => __$ChannelMinCopyWithImpl<_ChannelMin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChannelMinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelMin&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.englishName, englishName) || other.englishName == englishName)&&(identical(other.type, type) || other.type == type)&&(identical(other.photo, photo) || other.photo == photo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,englishName,type,photo);

@override
String toString() {
  return 'ChannelMin(id: $id, name: $name, englishName: $englishName, type: $type, photo: $photo)';
}


}

/// @nodoc
abstract mixin class _$ChannelMinCopyWith<$Res> implements $ChannelMinCopyWith<$Res> {
  factory _$ChannelMinCopyWith(_ChannelMin value, $Res Function(_ChannelMin) _then) = __$ChannelMinCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? englishName, String type, String? photo
});




}
/// @nodoc
class __$ChannelMinCopyWithImpl<$Res>
    implements _$ChannelMinCopyWith<$Res> {
  __$ChannelMinCopyWithImpl(this._self, this._then);

  final _ChannelMin _self;
  final $Res Function(_ChannelMin) _then;

/// Create a copy of ChannelMin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? englishName = freezed,Object? type = null,Object? photo = freezed,}) {
  return _then(_ChannelMin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,englishName: freezed == englishName ? _self.englishName : englishName // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
