// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\models\channel_min_with_org.dart
import 'package:freezed_annotation/freezed_annotation.dart';
// Import base ChannelMin

part 'channel_min_with_org.freezed.dart';
part 'channel_min_with_org.g.dart';

@freezed
class ChannelMinWithOrg with _$ChannelMinWithOrg {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChannelMinWithOrg({
    // Reuse fields from ChannelMin by embedding or duplicating
    // Embedding is cleaner but requires manual fromJson/toJson handling typically.
    // Let's duplicate for simplicity with freezed generation:
    required String id,
    required String name,
    String? englishName,
    @Default('vtuber') String type,
    String? photo,
    // Add the specific field
    String? org,
  }) = _ChannelMinWithOrg;

  // You can add convenience getters if you want ChannelMin behavior
  // ChannelMin get channelMin => ChannelMin(id: id, name: name, englishName: englishName, type: type, photo: photo);

  factory ChannelMinWithOrg.fromJson(Map<String, dynamic> json) =>
      _$ChannelMinWithOrgFromJson(json);
}
