import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/channel_min.dart';
import 'package:holodex_notifier/domain/models/channel_min_with_org.dart';
import 'package:holodex_notifier/domain/models/video.dart';

part 'video_full.freezed.dart';
part 'video_full.g.dart';

DateTime? _dateTimeFromString(String? dateString) => dateString == null ? null : DateTime.tryParse(dateString)?.toUtc();
DateTime _dateTimeFromStringRequired(String dateString) => DateTime.parse(dateString).toUtc();

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VideoFull with _$VideoFull {
  const factory VideoFull({
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
    List<VideoWithChannel>? clips,
    List<VideoWithChannel>? sources,
    List<VideoWithChannel>? refers,
    List<VideoWithChannel>? simulcasts,
    List<ChannelMinWithOrg>? mentions,
    int? songs,

    String? certainty,
    String? thumbnail,
    String? link,
  }) = _VideoFull;

  factory VideoFull.fromJson(Map<String, dynamic> json) => _$VideoFullFromJson(json);
}
