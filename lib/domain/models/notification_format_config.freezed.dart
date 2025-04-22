// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_format_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationFormat {

 String get titleTemplate; String get bodyTemplate; bool get showThumbnail; bool get showYoutubeLink; bool get showHolodexLink; bool get showSourceLink;
/// Create a copy of NotificationFormat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationFormatCopyWith<NotificationFormat> get copyWith => _$NotificationFormatCopyWithImpl<NotificationFormat>(this as NotificationFormat, _$identity);

  /// Serializes this NotificationFormat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationFormat&&(identical(other.titleTemplate, titleTemplate) || other.titleTemplate == titleTemplate)&&(identical(other.bodyTemplate, bodyTemplate) || other.bodyTemplate == bodyTemplate)&&(identical(other.showThumbnail, showThumbnail) || other.showThumbnail == showThumbnail)&&(identical(other.showYoutubeLink, showYoutubeLink) || other.showYoutubeLink == showYoutubeLink)&&(identical(other.showHolodexLink, showHolodexLink) || other.showHolodexLink == showHolodexLink)&&(identical(other.showSourceLink, showSourceLink) || other.showSourceLink == showSourceLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,titleTemplate,bodyTemplate,showThumbnail,showYoutubeLink,showHolodexLink,showSourceLink);

@override
String toString() {
  return 'NotificationFormat(titleTemplate: $titleTemplate, bodyTemplate: $bodyTemplate, showThumbnail: $showThumbnail, showYoutubeLink: $showYoutubeLink, showHolodexLink: $showHolodexLink, showSourceLink: $showSourceLink)';
}


}

/// @nodoc
abstract mixin class $NotificationFormatCopyWith<$Res>  {
  factory $NotificationFormatCopyWith(NotificationFormat value, $Res Function(NotificationFormat) _then) = _$NotificationFormatCopyWithImpl;
@useResult
$Res call({
 String titleTemplate, String bodyTemplate, bool showThumbnail, bool showYoutubeLink, bool showHolodexLink, bool showSourceLink
});




}
/// @nodoc
class _$NotificationFormatCopyWithImpl<$Res>
    implements $NotificationFormatCopyWith<$Res> {
  _$NotificationFormatCopyWithImpl(this._self, this._then);

  final NotificationFormat _self;
  final $Res Function(NotificationFormat) _then;

/// Create a copy of NotificationFormat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? titleTemplate = null,Object? bodyTemplate = null,Object? showThumbnail = null,Object? showYoutubeLink = null,Object? showHolodexLink = null,Object? showSourceLink = null,}) {
  return _then(_self.copyWith(
titleTemplate: null == titleTemplate ? _self.titleTemplate : titleTemplate // ignore: cast_nullable_to_non_nullable
as String,bodyTemplate: null == bodyTemplate ? _self.bodyTemplate : bodyTemplate // ignore: cast_nullable_to_non_nullable
as String,showThumbnail: null == showThumbnail ? _self.showThumbnail : showThumbnail // ignore: cast_nullable_to_non_nullable
as bool,showYoutubeLink: null == showYoutubeLink ? _self.showYoutubeLink : showYoutubeLink // ignore: cast_nullable_to_non_nullable
as bool,showHolodexLink: null == showHolodexLink ? _self.showHolodexLink : showHolodexLink // ignore: cast_nullable_to_non_nullable
as bool,showSourceLink: null == showSourceLink ? _self.showSourceLink : showSourceLink // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// @nodoc

@JsonSerializable()
class _NotificationFormat implements NotificationFormat {
  const _NotificationFormat({required this.titleTemplate, required this.bodyTemplate, this.showThumbnail = true, this.showYoutubeLink = true, this.showHolodexLink = true, this.showSourceLink = true});
  factory _NotificationFormat.fromJson(Map<String, dynamic> json) => _$NotificationFormatFromJson(json);

@override final  String titleTemplate;
@override final  String bodyTemplate;
@override@JsonKey() final  bool showThumbnail;
@override@JsonKey() final  bool showYoutubeLink;
@override@JsonKey() final  bool showHolodexLink;
@override@JsonKey() final  bool showSourceLink;

/// Create a copy of NotificationFormat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationFormatCopyWith<_NotificationFormat> get copyWith => __$NotificationFormatCopyWithImpl<_NotificationFormat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationFormatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationFormat&&(identical(other.titleTemplate, titleTemplate) || other.titleTemplate == titleTemplate)&&(identical(other.bodyTemplate, bodyTemplate) || other.bodyTemplate == bodyTemplate)&&(identical(other.showThumbnail, showThumbnail) || other.showThumbnail == showThumbnail)&&(identical(other.showYoutubeLink, showYoutubeLink) || other.showYoutubeLink == showYoutubeLink)&&(identical(other.showHolodexLink, showHolodexLink) || other.showHolodexLink == showHolodexLink)&&(identical(other.showSourceLink, showSourceLink) || other.showSourceLink == showSourceLink));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,titleTemplate,bodyTemplate,showThumbnail,showYoutubeLink,showHolodexLink,showSourceLink);

@override
String toString() {
  return 'NotificationFormat(titleTemplate: $titleTemplate, bodyTemplate: $bodyTemplate, showThumbnail: $showThumbnail, showYoutubeLink: $showYoutubeLink, showHolodexLink: $showHolodexLink, showSourceLink: $showSourceLink)';
}


}

/// @nodoc
abstract mixin class _$NotificationFormatCopyWith<$Res> implements $NotificationFormatCopyWith<$Res> {
  factory _$NotificationFormatCopyWith(_NotificationFormat value, $Res Function(_NotificationFormat) _then) = __$NotificationFormatCopyWithImpl;
@override @useResult
$Res call({
 String titleTemplate, String bodyTemplate, bool showThumbnail, bool showYoutubeLink, bool showHolodexLink, bool showSourceLink
});




}
/// @nodoc
class __$NotificationFormatCopyWithImpl<$Res>
    implements _$NotificationFormatCopyWith<$Res> {
  __$NotificationFormatCopyWithImpl(this._self, this._then);

  final _NotificationFormat _self;
  final $Res Function(_NotificationFormat) _then;

/// Create a copy of NotificationFormat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? titleTemplate = null,Object? bodyTemplate = null,Object? showThumbnail = null,Object? showYoutubeLink = null,Object? showHolodexLink = null,Object? showSourceLink = null,}) {
  return _then(_NotificationFormat(
titleTemplate: null == titleTemplate ? _self.titleTemplate : titleTemplate // ignore: cast_nullable_to_non_nullable
as String,bodyTemplate: null == bodyTemplate ? _self.bodyTemplate : bodyTemplate // ignore: cast_nullable_to_non_nullable
as String,showThumbnail: null == showThumbnail ? _self.showThumbnail : showThumbnail // ignore: cast_nullable_to_non_nullable
as bool,showYoutubeLink: null == showYoutubeLink ? _self.showYoutubeLink : showYoutubeLink // ignore: cast_nullable_to_non_nullable
as bool,showHolodexLink: null == showHolodexLink ? _self.showHolodexLink : showHolodexLink // ignore: cast_nullable_to_non_nullable
as bool,showSourceLink: null == showSourceLink ? _self.showSourceLink : showSourceLink // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$NotificationFormatConfig {

@JsonKey(fromJson: _notificationFormatMapFromJson, toJson: _notificationFormatMapToJson) Map<NotificationEventType, NotificationFormat> get formats; int get version;
/// Create a copy of NotificationFormatConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationFormatConfigCopyWith<NotificationFormatConfig> get copyWith => _$NotificationFormatConfigCopyWithImpl<NotificationFormatConfig>(this as NotificationFormatConfig, _$identity);

  /// Serializes this NotificationFormatConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationFormatConfig&&const DeepCollectionEquality().equals(other.formats, formats)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(formats),version);

@override
String toString() {
  return 'NotificationFormatConfig(formats: $formats, version: $version)';
}


}

/// @nodoc
abstract mixin class $NotificationFormatConfigCopyWith<$Res>  {
  factory $NotificationFormatConfigCopyWith(NotificationFormatConfig value, $Res Function(NotificationFormatConfig) _then) = _$NotificationFormatConfigCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _notificationFormatMapFromJson, toJson: _notificationFormatMapToJson) Map<NotificationEventType, NotificationFormat> formats, int version
});




}
/// @nodoc
class _$NotificationFormatConfigCopyWithImpl<$Res>
    implements $NotificationFormatConfigCopyWith<$Res> {
  _$NotificationFormatConfigCopyWithImpl(this._self, this._then);

  final NotificationFormatConfig _self;
  final $Res Function(NotificationFormatConfig) _then;

/// Create a copy of NotificationFormatConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? formats = null,Object? version = null,}) {
  return _then(_self.copyWith(
formats: null == formats ? _self.formats : formats // ignore: cast_nullable_to_non_nullable
as Map<NotificationEventType, NotificationFormat>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _NotificationFormatConfig implements NotificationFormatConfig {
  const _NotificationFormatConfig({@JsonKey(fromJson: _notificationFormatMapFromJson, toJson: _notificationFormatMapToJson) required final  Map<NotificationEventType, NotificationFormat> formats, this.version = 1}): _formats = formats;
  factory _NotificationFormatConfig.fromJson(Map<String, dynamic> json) => _$NotificationFormatConfigFromJson(json);

 final  Map<NotificationEventType, NotificationFormat> _formats;
@override@JsonKey(fromJson: _notificationFormatMapFromJson, toJson: _notificationFormatMapToJson) Map<NotificationEventType, NotificationFormat> get formats {
  if (_formats is EqualUnmodifiableMapView) return _formats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_formats);
}

@override@JsonKey() final  int version;

/// Create a copy of NotificationFormatConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationFormatConfigCopyWith<_NotificationFormatConfig> get copyWith => __$NotificationFormatConfigCopyWithImpl<_NotificationFormatConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationFormatConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationFormatConfig&&const DeepCollectionEquality().equals(other._formats, _formats)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_formats),version);

@override
String toString() {
  return 'NotificationFormatConfig(formats: $formats, version: $version)';
}


}

/// @nodoc
abstract mixin class _$NotificationFormatConfigCopyWith<$Res> implements $NotificationFormatConfigCopyWith<$Res> {
  factory _$NotificationFormatConfigCopyWith(_NotificationFormatConfig value, $Res Function(_NotificationFormatConfig) _then) = __$NotificationFormatConfigCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _notificationFormatMapFromJson, toJson: _notificationFormatMapToJson) Map<NotificationEventType, NotificationFormat> formats, int version
});




}
/// @nodoc
class __$NotificationFormatConfigCopyWithImpl<$Res>
    implements _$NotificationFormatConfigCopyWith<$Res> {
  __$NotificationFormatConfigCopyWithImpl(this._self, this._then);

  final _NotificationFormatConfig _self;
  final $Res Function(_NotificationFormatConfig) _then;

/// Create a copy of NotificationFormatConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? formats = null,Object? version = null,}) {
  return _then(_NotificationFormatConfig(
formats: null == formats ? _self._formats : formats // ignore: cast_nullable_to_non_nullable
as Map<NotificationEventType, NotificationFormat>,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
