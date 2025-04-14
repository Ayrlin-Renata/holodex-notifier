// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Channel _$ChannelFromJson(Map<String, dynamic> json) {
  return _Channel.fromJson(json);
}

/// @nodoc
mixin _$Channel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get englishName =>
      throw _privateConstructorUsedError; // API uses enum: ["vtuber", "subber"]
  String? get type => throw _privateConstructorUsedError;
  String? get org =>
      throw _privateConstructorUsedError; // This field is specific to ChannelWithGroup used in the /channels response
  String? get group => throw _privateConstructorUsedError;
  String? get photo => throw _privateConstructorUsedError;
  String? get banner => throw _privateConstructorUsedError;
  String? get twitter => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromStringNullable)
  int? get videoCount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromStringNullable)
  int? get subscriberCount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromStringNullable)
  int? get viewCount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _intFromStringNullable)
  int? get clipCount => throw _privateConstructorUsedError;
  String? get lang => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromStringNullable)
  DateTime? get publishedAt => throw _privateConstructorUsedError;
  bool? get inactive => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this Channel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelCopyWith<Channel> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChannelCopyWith<$Res> {
  factory $ChannelCopyWith(Channel value, $Res Function(Channel) then) =
      _$ChannelCopyWithImpl<$Res, Channel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? englishName,
    String? type,
    String? org,
    String? group,
    String? photo,
    String? banner,
    String? twitter,
    @JsonKey(fromJson: _intFromStringNullable) int? videoCount,
    @JsonKey(fromJson: _intFromStringNullable) int? subscriberCount,
    @JsonKey(fromJson: _intFromStringNullable) int? viewCount,
    @JsonKey(fromJson: _intFromStringNullable) int? clipCount,
    String? lang,
    @JsonKey(fromJson: _dateTimeFromStringNullable) DateTime? publishedAt,
    bool? inactive,
    String? description,
  });
}

/// @nodoc
class _$ChannelCopyWithImpl<$Res, $Val extends Channel>
    implements $ChannelCopyWith<$Res> {
  _$ChannelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? englishName = freezed,
    Object? type = freezed,
    Object? org = freezed,
    Object? group = freezed,
    Object? photo = freezed,
    Object? banner = freezed,
    Object? twitter = freezed,
    Object? videoCount = freezed,
    Object? subscriberCount = freezed,
    Object? viewCount = freezed,
    Object? clipCount = freezed,
    Object? lang = freezed,
    Object? publishedAt = freezed,
    Object? inactive = freezed,
    Object? description = freezed,
  }) {
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
                freezed == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String?,
            org:
                freezed == org
                    ? _value.org
                    : org // ignore: cast_nullable_to_non_nullable
                        as String?,
            group:
                freezed == group
                    ? _value.group
                    : group // ignore: cast_nullable_to_non_nullable
                        as String?,
            photo:
                freezed == photo
                    ? _value.photo
                    : photo // ignore: cast_nullable_to_non_nullable
                        as String?,
            banner:
                freezed == banner
                    ? _value.banner
                    : banner // ignore: cast_nullable_to_non_nullable
                        as String?,
            twitter:
                freezed == twitter
                    ? _value.twitter
                    : twitter // ignore: cast_nullable_to_non_nullable
                        as String?,
            videoCount:
                freezed == videoCount
                    ? _value.videoCount
                    : videoCount // ignore: cast_nullable_to_non_nullable
                        as int?,
            subscriberCount:
                freezed == subscriberCount
                    ? _value.subscriberCount
                    : subscriberCount // ignore: cast_nullable_to_non_nullable
                        as int?,
            viewCount:
                freezed == viewCount
                    ? _value.viewCount
                    : viewCount // ignore: cast_nullable_to_non_nullable
                        as int?,
            clipCount:
                freezed == clipCount
                    ? _value.clipCount
                    : clipCount // ignore: cast_nullable_to_non_nullable
                        as int?,
            lang:
                freezed == lang
                    ? _value.lang
                    : lang // ignore: cast_nullable_to_non_nullable
                        as String?,
            publishedAt:
                freezed == publishedAt
                    ? _value.publishedAt
                    : publishedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            inactive:
                freezed == inactive
                    ? _value.inactive
                    : inactive // ignore: cast_nullable_to_non_nullable
                        as bool?,
            description:
                freezed == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChannelImplCopyWith<$Res> implements $ChannelCopyWith<$Res> {
  factory _$$ChannelImplCopyWith(
    _$ChannelImpl value,
    $Res Function(_$ChannelImpl) then,
  ) = __$$ChannelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? englishName,
    String? type,
    String? org,
    String? group,
    String? photo,
    String? banner,
    String? twitter,
    @JsonKey(fromJson: _intFromStringNullable) int? videoCount,
    @JsonKey(fromJson: _intFromStringNullable) int? subscriberCount,
    @JsonKey(fromJson: _intFromStringNullable) int? viewCount,
    @JsonKey(fromJson: _intFromStringNullable) int? clipCount,
    String? lang,
    @JsonKey(fromJson: _dateTimeFromStringNullable) DateTime? publishedAt,
    bool? inactive,
    String? description,
  });
}

/// @nodoc
class __$$ChannelImplCopyWithImpl<$Res>
    extends _$ChannelCopyWithImpl<$Res, _$ChannelImpl>
    implements _$$ChannelImplCopyWith<$Res> {
  __$$ChannelImplCopyWithImpl(
    _$ChannelImpl _value,
    $Res Function(_$ChannelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? englishName = freezed,
    Object? type = freezed,
    Object? org = freezed,
    Object? group = freezed,
    Object? photo = freezed,
    Object? banner = freezed,
    Object? twitter = freezed,
    Object? videoCount = freezed,
    Object? subscriberCount = freezed,
    Object? viewCount = freezed,
    Object? clipCount = freezed,
    Object? lang = freezed,
    Object? publishedAt = freezed,
    Object? inactive = freezed,
    Object? description = freezed,
  }) {
    return _then(
      _$ChannelImpl(
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
            freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String?,
        org:
            freezed == org
                ? _value.org
                : org // ignore: cast_nullable_to_non_nullable
                    as String?,
        group:
            freezed == group
                ? _value.group
                : group // ignore: cast_nullable_to_non_nullable
                    as String?,
        photo:
            freezed == photo
                ? _value.photo
                : photo // ignore: cast_nullable_to_non_nullable
                    as String?,
        banner:
            freezed == banner
                ? _value.banner
                : banner // ignore: cast_nullable_to_non_nullable
                    as String?,
        twitter:
            freezed == twitter
                ? _value.twitter
                : twitter // ignore: cast_nullable_to_non_nullable
                    as String?,
        videoCount:
            freezed == videoCount
                ? _value.videoCount
                : videoCount // ignore: cast_nullable_to_non_nullable
                    as int?,
        subscriberCount:
            freezed == subscriberCount
                ? _value.subscriberCount
                : subscriberCount // ignore: cast_nullable_to_non_nullable
                    as int?,
        viewCount:
            freezed == viewCount
                ? _value.viewCount
                : viewCount // ignore: cast_nullable_to_non_nullable
                    as int?,
        clipCount:
            freezed == clipCount
                ? _value.clipCount
                : clipCount // ignore: cast_nullable_to_non_nullable
                    as int?,
        lang:
            freezed == lang
                ? _value.lang
                : lang // ignore: cast_nullable_to_non_nullable
                    as String?,
        publishedAt:
            freezed == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        inactive:
            freezed == inactive
                ? _value.inactive
                : inactive // ignore: cast_nullable_to_non_nullable
                    as bool?,
        description:
            freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ChannelImpl implements _Channel {
  const _$ChannelImpl({
    required this.id,
    required this.name,
    this.englishName,
    this.type,
    this.org,
    this.group,
    this.photo,
    this.banner,
    this.twitter,
    @JsonKey(fromJson: _intFromStringNullable) this.videoCount,
    @JsonKey(fromJson: _intFromStringNullable) this.subscriberCount,
    @JsonKey(fromJson: _intFromStringNullable) this.viewCount,
    @JsonKey(fromJson: _intFromStringNullable) this.clipCount,
    this.lang,
    @JsonKey(fromJson: _dateTimeFromStringNullable) this.publishedAt,
    this.inactive,
    this.description,
  });

  factory _$ChannelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChannelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? englishName;
  // API uses enum: ["vtuber", "subber"]
  @override
  final String? type;
  @override
  final String? org;
  // This field is specific to ChannelWithGroup used in the /channels response
  @override
  final String? group;
  @override
  final String? photo;
  @override
  final String? banner;
  @override
  final String? twitter;
  @override
  @JsonKey(fromJson: _intFromStringNullable)
  final int? videoCount;
  @override
  @JsonKey(fromJson: _intFromStringNullable)
  final int? subscriberCount;
  @override
  @JsonKey(fromJson: _intFromStringNullable)
  final int? viewCount;
  @override
  @JsonKey(fromJson: _intFromStringNullable)
  final int? clipCount;
  @override
  final String? lang;
  @override
  @JsonKey(fromJson: _dateTimeFromStringNullable)
  final DateTime? publishedAt;
  @override
  final bool? inactive;
  @override
  final String? description;

  @override
  String toString() {
    return 'Channel(id: $id, name: $name, englishName: $englishName, type: $type, org: $org, group: $group, photo: $photo, banner: $banner, twitter: $twitter, videoCount: $videoCount, subscriberCount: $subscriberCount, viewCount: $viewCount, clipCount: $clipCount, lang: $lang, publishedAt: $publishedAt, inactive: $inactive, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.englishName, englishName) ||
                other.englishName == englishName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.org, org) || other.org == org) &&
            (identical(other.group, group) || other.group == group) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.banner, banner) || other.banner == banner) &&
            (identical(other.twitter, twitter) || other.twitter == twitter) &&
            (identical(other.videoCount, videoCount) ||
                other.videoCount == videoCount) &&
            (identical(other.subscriberCount, subscriberCount) ||
                other.subscriberCount == subscriberCount) &&
            (identical(other.viewCount, viewCount) ||
                other.viewCount == viewCount) &&
            (identical(other.clipCount, clipCount) ||
                other.clipCount == clipCount) &&
            (identical(other.lang, lang) || other.lang == lang) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            (identical(other.inactive, inactive) ||
                other.inactive == inactive) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    englishName,
    type,
    org,
    group,
    photo,
    banner,
    twitter,
    videoCount,
    subscriberCount,
    viewCount,
    clipCount,
    lang,
    publishedAt,
    inactive,
    description,
  );

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelImplCopyWith<_$ChannelImpl> get copyWith =>
      __$$ChannelImplCopyWithImpl<_$ChannelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelImplToJson(this);
  }
}

abstract class _Channel implements Channel {
  const factory _Channel({
    required final String id,
    required final String name,
    final String? englishName,
    final String? type,
    final String? org,
    final String? group,
    final String? photo,
    final String? banner,
    final String? twitter,
    @JsonKey(fromJson: _intFromStringNullable) final int? videoCount,
    @JsonKey(fromJson: _intFromStringNullable) final int? subscriberCount,
    @JsonKey(fromJson: _intFromStringNullable) final int? viewCount,
    @JsonKey(fromJson: _intFromStringNullable) final int? clipCount,
    final String? lang,
    @JsonKey(fromJson: _dateTimeFromStringNullable) final DateTime? publishedAt,
    final bool? inactive,
    final String? description,
  }) = _$ChannelImpl;

  factory _Channel.fromJson(Map<String, dynamic> json) = _$ChannelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get englishName; // API uses enum: ["vtuber", "subber"]
  @override
  String? get type;
  @override
  String? get org; // This field is specific to ChannelWithGroup used in the /channels response
  @override
  String? get group;
  @override
  String? get photo;
  @override
  String? get banner;
  @override
  String? get twitter;
  @override
  @JsonKey(fromJson: _intFromStringNullable)
  int? get videoCount;
  @override
  @JsonKey(fromJson: _intFromStringNullable)
  int? get subscriberCount;
  @override
  @JsonKey(fromJson: _intFromStringNullable)
  int? get viewCount;
  @override
  @JsonKey(fromJson: _intFromStringNullable)
  int? get clipCount;
  @override
  String? get lang;
  @override
  @JsonKey(fromJson: _dateTimeFromStringNullable)
  DateTime? get publishedAt;
  @override
  bool? get inactive;
  @override
  String? get description;

  /// Create a copy of Channel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelImplCopyWith<_$ChannelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
