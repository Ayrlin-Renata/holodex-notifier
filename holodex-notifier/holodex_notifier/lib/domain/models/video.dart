import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/channel_min.dart';

part 'video.freezed.dart';
part 'video.g.dart';

DateTime? _dateTimeFromString(String? dateString) => dateString == null ? null : DateTime.tryParse(dateString);

DateTime _dateTimeFromStringRequired(String dateString) => DateTime.parse(dateString);

@freezed
class Video with _$Video {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Video({
    required String id,
    required String title,
    required String type,
    String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) required DateTime availableAt,
    required int duration,
    required String status,

    @JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? endActual,
    int? liveViewers,
    String? description,
    int? songcount,
    required ChannelMin channel,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}

@freezed
class VideoWithChannel with _$VideoWithChannel {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory VideoWithChannel({
    required String id,
    required String title,
    required String type,
    String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) required DateTime availableAt,
    required int duration,
    required String status,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? endActual,
    int? liveViewers,
    String? description,
    int? songcount,
    required ChannelMin channel,
  }) = _VideoWithChannel;

  factory VideoWithChannel.fromJson(Map<String, dynamic> json) => _$VideoWithChannelFromJson(json);
}
