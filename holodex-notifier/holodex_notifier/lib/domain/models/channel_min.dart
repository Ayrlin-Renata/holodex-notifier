// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\models\channel_min.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_min.freezed.dart';
part 'channel_min.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake) // Automatically convert snake_case from JSON
class ChannelMin with _$ChannelMin {
  const factory ChannelMin({
    required String id,
    required String name,
    String? englishName,
    // TODO: Consider using an enum for type
    @Default('vtuber') String type, // Default based on typical usage, API says enum: ['vtuber', 'subber']
    String? photo, // API schema says string, but example shows potentially missing
  }) = _ChannelMin;

  factory ChannelMin.fromJson(Map<String, dynamic> json) => _$ChannelMinFromJson(json);
}
