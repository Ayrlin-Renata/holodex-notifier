// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\models\channel.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel.freezed.dart';
part 'channel.g.dart';

// Define helper functions for parsing potentially null string fields into specific types
int? _intFromStringNullable(String? value) => value == null ? null : int.tryParse(value);

DateTime? _dateTimeFromStringNullable(String? dateString) => dateString == null ? null : DateTime.tryParse(dateString);

// The API seems to return ChannelWithGroup from the /channels endpoint
@freezed
@JsonSerializable(fieldRename: FieldRename.snake)
class Channel with _$Channel {
  const factory Channel({
    required String id,
    required String name,
    String? englishName,
    // API uses enum: ["vtuber", "subber"]
    String? type,
    String? org,
    // This field is specific to ChannelWithGroup used in the /channels response
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
