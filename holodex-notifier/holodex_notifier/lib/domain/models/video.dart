// Create this file: f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\models\video.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:holodex_notifier/domain/models/channel_min.dart'; // Needed for channel property later

part 'video.freezed.dart';
part 'video.g.dart';

// Helper function for parsing DateTime from ISO 8601 string
DateTime? _dateTimeFromString(String? dateString) => dateString == null ? null : DateTime.tryParse(dateString);

// Helper function specifically for available_at which should not be null
DateTime _dateTimeFromStringRequired(String dateString) => DateTime.parse(dateString);

@freezed
class Video with _$Video {
  @JsonSerializable(
    fieldRename: FieldRename.snake, // Handle JSON snake_case
    explicitToJson: true, // Needed if nested models have toJson
  )
  const factory Video({
    required String id,
    required String title,
    // TODO: Consider using an enum for type. Enum: "stream", "clip"
    required String type,
    String? topicId,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? publishedAt,
    @JsonKey(fromJson: _dateTimeFromStringRequired) required DateTime availableAt,
    required int duration, // in seconds
    // TODO: Consider using an enum for status. Enum: "new", "upcoming", "live", "past", "missing"
    required String status,

    // Optional fields included via 'include' parameter
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startScheduled,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? startActual,
    @JsonKey(fromJson: _dateTimeFromString) DateTime? endActual,
    // API spec shows live_viewers as int, let's keep it nullable int
    int? liveViewers,
    String? description, // Included when 'description' is in include
    // API uses songcount and songs inconsistently (number/int), using int?
    int? songcount,
    // The Base Video schema in OpenAPI doesn't have 'channel', but VideoWithChannel does.
    // Let's add channel here for practicality, as VideoFull always includes it.
    required ChannelMin channel,

    // The Base Video schema also doesn't have mentions, added in VideoFull
    // List<ChannelMinWithOrg>? mentions, // Moved to VideoFull
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}

// --- VideoWithChannel Definition ---
// As per OpenAPI, VideoWithChannel = Video + ChannelMin.
// Since we added ChannelMin directly to Video model above, we can often
// just use the Video type where VideoWithChannel was intended.
// However, if strict adherence is needed, define it:

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class VideoWithChannel with _$VideoWithChannel {
  // Freezed doesn't directly support 'allOf', so we combine properties.
  // This largely duplicates the Video model, which isn't ideal.
  // Recommendation: Primarily use the 'Video' model defined above
  // which already includes the 'channel' field.

  const factory VideoWithChannel({
    // Copy all fields from Video
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
    // Any other fields specific to VideoWithChannel if they existed
  }) = _VideoWithChannel;

  factory VideoWithChannel.fromJson(Map<String, dynamic> json) => _$VideoWithChannelFromJson(json);
}
