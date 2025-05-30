import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_min_with_org.freezed.dart';
part 'channel_min_with_org.g.dart';

@freezed
abstract class ChannelMinWithOrg with _$ChannelMinWithOrg {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChannelMinWithOrg({
    required String id,
    required String name,
    String? englishName,
    @Default('vtuber') String type,
    String? photo,
    String? org,
  }) = _ChannelMinWithOrg;

  factory ChannelMinWithOrg.fromJson(Map<String, dynamic> json) => _$ChannelMinWithOrgFromJson(json);
}
