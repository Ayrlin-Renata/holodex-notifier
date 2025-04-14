// f:\Fun\Dev\holodex-notifier\holodex-notifier\holodex_notifier\lib\domain\interfaces\api_service.dart
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';

/// Defines the contract for interacting with the Holodex API.
abstract class IApiService {
  /// Fetches videos based on channel subscriptions and mentions.
  ///
  /// Parameters:
  ///   - `channelIds`: A set of channel IDs for which to fetch direct uploads.
  ///   - `mentionChannelIds`: A set of channel IDs for which to fetch mentions.
  ///   - `from`: The starting point in time (UTC) to fetch videos from.
  ///
  /// Returns a list of [VideoFull] objects representing the fetched videos.
  Future<List<VideoFull>> fetchVideos({
    required Set<String> channelIds,
    required Set<String> mentionChannelIds,
    required DateTime from,
    // Consider adding limit, type, status parameters if needed by the poller directly.
  });

  /// Searches for channels based on a query string.
  ///
  /// This likely uses an autocomplete or search endpoint.
  ///
  /// Returns a list of [Channel] objects matching the query.
  Future<List<Channel>> searchChannels(String query);

  // /// Optional: Method to check the validity of an API key directly with the service.
  // ///
  // /// Returns `true` if the key is valid, `false` otherwise.
  // Future<bool> checkApiKey(String apiKey);
}