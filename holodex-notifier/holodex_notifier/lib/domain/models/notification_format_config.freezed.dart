// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_format_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NotificationFormat _$NotificationFormatFromJson(Map<String, dynamic> json) {
  return _NotificationFormat.fromJson(json);
}

/// @nodoc
mixin _$NotificationFormat {
  String get titleTemplate => throw _privateConstructorUsedError;
  String get bodyTemplate => throw _privateConstructorUsedError;

  /// Serializes this NotificationFormat to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationFormatCopyWith<NotificationFormat> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationFormatCopyWith<$Res> {
  factory $NotificationFormatCopyWith(
          NotificationFormat value, $Res Function(NotificationFormat) then) =
      _$NotificationFormatCopyWithImpl<$Res, NotificationFormat>;
  @useResult
  $Res call({String titleTemplate, String bodyTemplate});
}

/// @nodoc
class _$NotificationFormatCopyWithImpl<$Res, $Val extends NotificationFormat>
    implements $NotificationFormatCopyWith<$Res> {
  _$NotificationFormatCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationFormat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? titleTemplate = null,
    Object? bodyTemplate = null,
  }) {
    return _then(_value.copyWith(
      titleTemplate: null == titleTemplate
          ? _value.titleTemplate
          : titleTemplate // ignore: cast_nullable_to_non_nullable
              as String,
      bodyTemplate: null == bodyTemplate
          ? _value.bodyTemplate
          : bodyTemplate // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationFormatImplCopyWith<$Res>
    implements $NotificationFormatCopyWith<$Res> {
  factory _$$NotificationFormatImplCopyWith(_$NotificationFormatImpl value,
          $Res Function(_$NotificationFormatImpl) then) =
      __$$NotificationFormatImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String titleTemplate, String bodyTemplate});
}

/// @nodoc
class __$$NotificationFormatImplCopyWithImpl<$Res>
    extends _$NotificationFormatCopyWithImpl<$Res, _$NotificationFormatImpl>
    implements _$$NotificationFormatImplCopyWith<$Res> {
  __$$NotificationFormatImplCopyWithImpl(_$NotificationFormatImpl _value,
      $Res Function(_$NotificationFormatImpl) _then)
      : super(_value, _then);

  /// Create a copy of NotificationFormat
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? titleTemplate = null,
    Object? bodyTemplate = null,
  }) {
    return _then(_$NotificationFormatImpl(
      titleTemplate: null == titleTemplate
          ? _value.titleTemplate
          : titleTemplate // ignore: cast_nullable_to_non_nullable
              as String,
      bodyTemplate: null == bodyTemplate
          ? _value.bodyTemplate
          : bodyTemplate // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

@JsonSerializable()
class _$NotificationFormatImpl implements _NotificationFormat {
  const _$NotificationFormatImpl(
      {required this.titleTemplate, required this.bodyTemplate});

  factory _$NotificationFormatImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationFormatImplFromJson(json);

  @override
  final String titleTemplate;
  @override
  final String bodyTemplate;

  @override
  String toString() {
    return 'NotificationFormat(titleTemplate: $titleTemplate, bodyTemplate: $bodyTemplate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationFormatImpl &&
            (identical(other.titleTemplate, titleTemplate) ||
                other.titleTemplate == titleTemplate) &&
            (identical(other.bodyTemplate, bodyTemplate) ||
                other.bodyTemplate == bodyTemplate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, titleTemplate, bodyTemplate);

  /// Create a copy of NotificationFormat
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationFormatImplCopyWith<_$NotificationFormatImpl> get copyWith =>
      __$$NotificationFormatImplCopyWithImpl<_$NotificationFormatImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationFormatImplToJson(
      this,
    );
  }
}

abstract class _NotificationFormat implements NotificationFormat {
  const factory _NotificationFormat(
      {required final String titleTemplate,
      required final String bodyTemplate}) = _$NotificationFormatImpl;

  factory _NotificationFormat.fromJson(Map<String, dynamic> json) =
      _$NotificationFormatImpl.fromJson;

  @override
  String get titleTemplate;
  @override
  String get bodyTemplate;

  /// Create a copy of NotificationFormat
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationFormatImplCopyWith<_$NotificationFormatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NotificationFormatConfig _$NotificationFormatConfigFromJson(
    Map<String, dynamic> json) {
  return _NotificationFormatConfig.fromJson(json);
}

/// @nodoc
mixin _$NotificationFormatConfig {
// Use a Map where the key is NotificationEventType and value is the format.
// Need a custom converter because NotificationEventType cannot be a Map key directly in JSON.
  @JsonKey(
      fromJson: _notificationFormatMapFromJson,
      toJson: _notificationFormatMapToJson)
  Map<NotificationEventType, NotificationFormat> get formats =>
      throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;

  /// Serializes this NotificationFormatConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationFormatConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationFormatConfigCopyWith<NotificationFormatConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationFormatConfigCopyWith<$Res> {
  factory $NotificationFormatConfigCopyWith(NotificationFormatConfig value,
          $Res Function(NotificationFormatConfig) then) =
      _$NotificationFormatConfigCopyWithImpl<$Res, NotificationFormatConfig>;
  @useResult
  $Res call(
      {@JsonKey(
          fromJson: _notificationFormatMapFromJson,
          toJson: _notificationFormatMapToJson)
      Map<NotificationEventType, NotificationFormat> formats,
      int version});
}

/// @nodoc
class _$NotificationFormatConfigCopyWithImpl<$Res,
        $Val extends NotificationFormatConfig>
    implements $NotificationFormatConfigCopyWith<$Res> {
  _$NotificationFormatConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationFormatConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formats = null,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      formats: null == formats
          ? _value.formats
          : formats // ignore: cast_nullable_to_non_nullable
              as Map<NotificationEventType, NotificationFormat>,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationFormatConfigImplCopyWith<$Res>
    implements $NotificationFormatConfigCopyWith<$Res> {
  factory _$$NotificationFormatConfigImplCopyWith(
          _$NotificationFormatConfigImpl value,
          $Res Function(_$NotificationFormatConfigImpl) then) =
      __$$NotificationFormatConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(
          fromJson: _notificationFormatMapFromJson,
          toJson: _notificationFormatMapToJson)
      Map<NotificationEventType, NotificationFormat> formats,
      int version});
}

/// @nodoc
class __$$NotificationFormatConfigImplCopyWithImpl<$Res>
    extends _$NotificationFormatConfigCopyWithImpl<$Res,
        _$NotificationFormatConfigImpl>
    implements _$$NotificationFormatConfigImplCopyWith<$Res> {
  __$$NotificationFormatConfigImplCopyWithImpl(
      _$NotificationFormatConfigImpl _value,
      $Res Function(_$NotificationFormatConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of NotificationFormatConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formats = null,
    Object? version = null,
  }) {
    return _then(_$NotificationFormatConfigImpl(
      formats: null == formats
          ? _value._formats
          : formats // ignore: cast_nullable_to_non_nullable
              as Map<NotificationEventType, NotificationFormat>,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$NotificationFormatConfigImpl implements _NotificationFormatConfig {
  const _$NotificationFormatConfigImpl(
      {@JsonKey(
          fromJson: _notificationFormatMapFromJson,
          toJson: _notificationFormatMapToJson)
      required final Map<NotificationEventType, NotificationFormat> formats,
      this.version = 1})
      : _formats = formats;

  factory _$NotificationFormatConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationFormatConfigImplFromJson(json);

// Use a Map where the key is NotificationEventType and value is the format.
// Need a custom converter because NotificationEventType cannot be a Map key directly in JSON.
  final Map<NotificationEventType, NotificationFormat> _formats;
// Use a Map where the key is NotificationEventType and value is the format.
// Need a custom converter because NotificationEventType cannot be a Map key directly in JSON.
  @override
  @JsonKey(
      fromJson: _notificationFormatMapFromJson,
      toJson: _notificationFormatMapToJson)
  Map<NotificationEventType, NotificationFormat> get formats {
    if (_formats is EqualUnmodifiableMapView) return _formats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_formats);
  }

  @override
  @JsonKey()
  final int version;

  @override
  String toString() {
    return 'NotificationFormatConfig(formats: $formats, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationFormatConfigImpl &&
            const DeepCollectionEquality().equals(other._formats, _formats) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_formats), version);

  /// Create a copy of NotificationFormatConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationFormatConfigImplCopyWith<_$NotificationFormatConfigImpl>
      get copyWith => __$$NotificationFormatConfigImplCopyWithImpl<
          _$NotificationFormatConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationFormatConfigImplToJson(
      this,
    );
  }
}

abstract class _NotificationFormatConfig implements NotificationFormatConfig {
  const factory _NotificationFormatConfig(
      {@JsonKey(
          fromJson: _notificationFormatMapFromJson,
          toJson: _notificationFormatMapToJson)
      required final Map<NotificationEventType, NotificationFormat> formats,
      final int version}) = _$NotificationFormatConfigImpl;

  factory _NotificationFormatConfig.fromJson(Map<String, dynamic> json) =
      _$NotificationFormatConfigImpl.fromJson;

// Use a Map where the key is NotificationEventType and value is the format.
// Need a custom converter because NotificationEventType cannot be a Map key directly in JSON.
  @override
  @JsonKey(
      fromJson: _notificationFormatMapFromJson,
      toJson: _notificationFormatMapToJson)
  Map<NotificationEventType, NotificationFormat> get formats;
  @override
  int get version;

  /// Create a copy of NotificationFormatConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationFormatConfigImplCopyWith<_$NotificationFormatConfigImpl>
      get copyWith => throw _privateConstructorUsedError;
}
