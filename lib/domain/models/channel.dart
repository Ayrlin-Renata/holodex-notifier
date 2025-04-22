import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel.freezed.dart';
part 'channel.g.dart';

int? _intFromStringNullable(String? value) => value == null ? null : int.tryParse(value);

DateTime? _dateTimeFromStringNullable(String? dateString) => dateString == null ? null : DateTime.tryParse(dateString);

@freezed
abstract class Channel with _$Channel {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Channel({
    required String id,
    required String name,
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
  }) = _Channel;

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);
}
