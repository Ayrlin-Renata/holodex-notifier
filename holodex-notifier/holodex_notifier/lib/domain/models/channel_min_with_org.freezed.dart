part of 'channel_min_with_org.dart';

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChannelMinWithOrg _$ChannelMinWithOrgFromJson(Map<String, dynamic> json) {
  return _ChannelMinWithOrg.fromJson(json);
}

mixin _$ChannelMinWithOrg {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get englishName => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String? get photo => throw _privateConstructorUsedError;
  String? get org => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChannelMinWithOrgCopyWith<ChannelMinWithOrg> get copyWith => throw _privateConstructorUsedError;
}

abstract class $ChannelMinWithOrgCopyWith<$Res> {
  factory $ChannelMinWithOrgCopyWith(ChannelMinWithOrg value, $Res Function(ChannelMinWithOrg) then) =
      _$ChannelMinWithOrgCopyWithImpl<$Res, ChannelMinWithOrg>;
  @useResult
  $Res call({String id, String name, String? englishName, String type, String? photo, String? org});
}

class _$ChannelMinWithOrgCopyWithImpl<$Res, $Val extends ChannelMinWithOrg> implements $ChannelMinWithOrgCopyWith<$Res> {
  _$ChannelMinWithOrgCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? englishName = freezed,
    Object? type = null,
    Object? photo = freezed,
    Object? org = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id ? _value.id : id as String,
            name: null == name ? _value.name : name as String,
            englishName: freezed == englishName ? _value.englishName : englishName as String?,
            type: null == type ? _value.type : type as String,
            photo: freezed == photo ? _value.photo : photo as String?,
            org: freezed == org ? _value.org : org as String?,
          )
          as $Val,
    );
  }
}

abstract class _$$ChannelMinWithOrgImplCopyWith<$Res> implements $ChannelMinWithOrgCopyWith<$Res> {
  factory _$$ChannelMinWithOrgImplCopyWith(_$ChannelMinWithOrgImpl value, $Res Function(_$ChannelMinWithOrgImpl) then) =
      __$$ChannelMinWithOrgImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? englishName, String type, String? photo, String? org});
}

class __$$ChannelMinWithOrgImplCopyWithImpl<$Res> extends _$ChannelMinWithOrgCopyWithImpl<$Res, _$ChannelMinWithOrgImpl>
    implements _$$ChannelMinWithOrgImplCopyWith<$Res> {
  __$$ChannelMinWithOrgImplCopyWithImpl(_$ChannelMinWithOrgImpl _value, $Res Function(_$ChannelMinWithOrgImpl) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? englishName = freezed,
    Object? type = null,
    Object? photo = freezed,
    Object? org = freezed,
  }) {
    return _then(
      _$ChannelMinWithOrgImpl(
        id: null == id ? _value.id : id as String,
        name: null == name ? _value.name : name as String,
        englishName: freezed == englishName ? _value.englishName : englishName as String?,
        type: null == type ? _value.type : type as String,
        photo: freezed == photo ? _value.photo : photo as String?,
        org: freezed == org ? _value.org : org as String?,
      ),
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class _$ChannelMinWithOrgImpl implements _ChannelMinWithOrg {
  const _$ChannelMinWithOrgImpl({required this.id, required this.name, this.englishName, this.type = 'vtuber', this.photo, this.org});

  factory _$ChannelMinWithOrgImpl.fromJson(Map<String, dynamic> json) => _$$ChannelMinWithOrgImplFromJson(json);

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
  final String? org;

  @override
  String toString() {
    return 'ChannelMinWithOrg(id: $id, name: $name, englishName: $englishName, type: $type, photo: $photo, org: $org)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChannelMinWithOrgImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.englishName, englishName) || other.englishName == englishName) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.photo, photo) || other.photo == photo) &&
            (identical(other.org, org) || other.org == org));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, englishName, type, photo, org);

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChannelMinWithOrgImplCopyWith<_$ChannelMinWithOrgImpl> get copyWith =>
      __$$ChannelMinWithOrgImplCopyWithImpl<_$ChannelMinWithOrgImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChannelMinWithOrgImplToJson(this);
  }
}

abstract class _ChannelMinWithOrg implements ChannelMinWithOrg {
  const factory _ChannelMinWithOrg({
    required final String id,
    required final String name,
    final String? englishName,
    final String type,
    final String? photo,
    final String? org,
  }) = _$ChannelMinWithOrgImpl;

  factory _ChannelMinWithOrg.fromJson(Map<String, dynamic> json) = _$ChannelMinWithOrgImpl.fromJson;

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
  String? get org;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChannelMinWithOrgImplCopyWith<_$ChannelMinWithOrgImpl> get copyWith => throw _privateConstructorUsedError;
}
