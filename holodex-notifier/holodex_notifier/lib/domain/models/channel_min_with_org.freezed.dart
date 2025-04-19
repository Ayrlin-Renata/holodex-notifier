// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_min_with_org.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelMinWithOrg {

 String get id; String get name; String? get englishName; String get type; String? get photo; String? get org;
/// Create a copy of ChannelMinWithOrg
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelMinWithOrgCopyWith<ChannelMinWithOrg> get copyWith => _$ChannelMinWithOrgCopyWithImpl<ChannelMinWithOrg>(this as ChannelMinWithOrg, _$identity);

  /// Serializes this ChannelMinWithOrg to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelMinWithOrg&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.englishName, englishName) || other.englishName == englishName)&&(identical(other.type, type) || other.type == type)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.org, org) || other.org == org));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,englishName,type,photo,org);

@override
String toString() {
  return 'ChannelMinWithOrg(id: $id, name: $name, englishName: $englishName, type: $type, photo: $photo, org: $org)';
}


}

/// @nodoc
abstract mixin class $ChannelMinWithOrgCopyWith<$Res>  {
  factory $ChannelMinWithOrgCopyWith(ChannelMinWithOrg value, $Res Function(ChannelMinWithOrg) _then) = _$ChannelMinWithOrgCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? englishName, String type, String? photo, String? org
});




}
/// @nodoc
class _$ChannelMinWithOrgCopyWithImpl<$Res>
    implements $ChannelMinWithOrgCopyWith<$Res> {
  _$ChannelMinWithOrgCopyWithImpl(this._self, this._then);

  final ChannelMinWithOrg _self;
  final $Res Function(ChannelMinWithOrg) _then;

/// Create a copy of ChannelMinWithOrg
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? englishName = freezed,Object? type = null,Object? photo = freezed,Object? org = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,englishName: freezed == englishName ? _self.englishName : englishName // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,org: freezed == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _ChannelMinWithOrg implements ChannelMinWithOrg {
  const _ChannelMinWithOrg({required this.id, required this.name, this.englishName, this.type = 'vtuber', this.photo, this.org});
  factory _ChannelMinWithOrg.fromJson(Map<String, dynamic> json) => _$ChannelMinWithOrgFromJson(json);

@override final  String id;
@override final  String name;
@override final  String? englishName;
@override@JsonKey() final  String type;
@override final  String? photo;
@override final  String? org;

/// Create a copy of ChannelMinWithOrg
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelMinWithOrgCopyWith<_ChannelMinWithOrg> get copyWith => __$ChannelMinWithOrgCopyWithImpl<_ChannelMinWithOrg>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChannelMinWithOrgToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelMinWithOrg&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.englishName, englishName) || other.englishName == englishName)&&(identical(other.type, type) || other.type == type)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.org, org) || other.org == org));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,englishName,type,photo,org);

@override
String toString() {
  return 'ChannelMinWithOrg(id: $id, name: $name, englishName: $englishName, type: $type, photo: $photo, org: $org)';
}


}

/// @nodoc
abstract mixin class _$ChannelMinWithOrgCopyWith<$Res> implements $ChannelMinWithOrgCopyWith<$Res> {
  factory _$ChannelMinWithOrgCopyWith(_ChannelMinWithOrg value, $Res Function(_ChannelMinWithOrg) _then) = __$ChannelMinWithOrgCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? englishName, String type, String? photo, String? org
});




}
/// @nodoc
class __$ChannelMinWithOrgCopyWithImpl<$Res>
    implements _$ChannelMinWithOrgCopyWith<$Res> {
  __$ChannelMinWithOrgCopyWithImpl(this._self, this._then);

  final _ChannelMinWithOrg _self;
  final $Res Function(_ChannelMinWithOrg) _then;

/// Create a copy of ChannelMinWithOrg
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? englishName = freezed,Object? type = null,Object? photo = freezed,Object? org = freezed,}) {
  return _then(_ChannelMinWithOrg(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,englishName: freezed == englishName ? _self.englishName : englishName // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,photo: freezed == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String?,org: freezed == org ? _self.org : org // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
