import 'package:freezed_annotation/freezed_annotation.dart';

part 'channel_min.freezed.dart';
part 'channel_min.g.dart';

@freezed
class ChannelMin with _$ChannelMin {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChannelMin({required String id, required String name, String? englishName, @Default('vtuber') String type, String? photo}) =
      _ChannelMin;

  factory ChannelMin.fromJson(Map<String, dynamic> json) => _$ChannelMinFromJson(json);
}
