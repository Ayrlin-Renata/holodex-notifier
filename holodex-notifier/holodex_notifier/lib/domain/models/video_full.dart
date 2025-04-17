// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\models\video_full.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/channel_min.dart';
import 'package:holodex_notifier/domain/models/channel_min_with_org.dart';
import 'package:holodex_notifier/domain/models/video.dart'; // Import base Video and VideoWithChannel

part 'video_full.freezed.dart';
part 'video_full.g.dart';

// Re-use DateTime parsers if needed, or rely on them being defined in video.dart (if in same library scope)
DateTime? _dateTimeFromString(String? dateString) => dateString == null ? null : DateTime.tryParse(dateString)?.toUtc();
DateTime _dateTimeFromStringRequired(String dateString) => DateTime.parse(dateString).toUtc();

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VideoFull with _$VideoFull {
  const factory VideoFull({
    // --- Fields from base Video ---
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
    int? songcount, // Base Video schema has this
    required ChannelMin channel, // Added this to base Video model
    // --- Fields specific to VideoFull ---
    List<VideoWithChannel>? clips,
    List<VideoWithChannel>? sources,
    List<VideoWithChannel>? refers,
    List<VideoWithChannel>? simulcasts,
    List<ChannelMinWithOrg>? mentions,
    // API spec shows 'songs' as number under VideoFull properties, but 'songcount' under Video properties.
    // Let's use 'songs' as potentially distinct from 'songcount' and make it nullable int.
    int? songs,

    // Add the 'certainty' field needed by the design doc, even if not in OpenAPI spec explicitly
    // It's often implicitly part of YT data sources Holodex might use. Make it nullable.
    String? certainty,
    String? thumbnail, // {{ Add placeholder thumbnail }}
    String? link, // {{ Add placeholder link }}
  }) = _VideoFull;

  factory VideoFull.fromJson(Map<String, dynamic> json) => _$VideoFullFromJson(json);
}