import 'package:dio/dio.dart';
import 'package:holodex_notifier/domain/interfaces/api_service.dart';
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';

// TODO: Import actual VideoFull and Channel models once defined (e.g., using freezed)
// For now, we'll work with dynamic types (List<Map<String, dynamic>>)

class HolodexApiService implements IApiService {
  final Dio _dio;
  // Optionally inject logger: final ILoggingService _logger;

  HolodexApiService(this._dio /*, {ILoggingService? logger} */)/* : _logger = logger */;

  /// Fetches videos based on channel subscriptions and mentions since a specific time.
  /// Implements the iterative logic described in Design Doc Section III.4.
  @override
  Future<List<VideoFull>> fetchVideos({
    required Set<String> channelIds, // IDs for direct video uploads
    required Set<String> mentionChannelIds, // IDs for mentions
    required DateTime from,
    int limit = 50, // Max limit per API spec
  }) async {
    print(
        '[API Service] Fetching videos for channels: ${channelIds.length}, mentions: ${mentionChannelIds.length} since ${from.toIso8601String()}');

    final List<Map<String, dynamic>> allVideos = [];
    final Set<String> processedChannelIds = {}; // Track IDs processed for direct videos
    final Set<String> processedMentionIds = {}; // Track IDs processed for mentions

    final fromIso = from.toIso8601String();
    const includeParams = 'live_info,mentions'; // As per design doc III.4

    // 1. Fetch videos directly uploaded by subscribed channels
    for (final id in channelIds) {
      if (processedChannelIds.contains(id)) continue; // Skip if already processed
      try {
        final response = await _dio.get('/videos', queryParameters: {
          'channel_id': id,
          'include': includeParams,
          'from': fromIso,
          'limit': limit,
          'type': 'stream,clip,placeholder', // As per design doc III.4
          'status': 'new,upcoming,live,past,missing' // Fetch all relevant statuses
        });

        if (response.statusCode == 200 && response.data is List) {
          // Expecting a List<Map<String, dynamic>> which represents List<VideoFull>
          allVideos.addAll(List<Map<String, dynamic>>.from(response.data));
        } else {
          // TODO: Log warning/error - Non-200 status or unexpected data format
          print('[API Service] WARN: Received status ${response.statusCode} or invalid data for channel $id');
        }
        processedChannelIds.add(id);
      } on DioException catch (e) {
        // TODO: More robust error logging/handling (delegate to interceptor later)
        print('[API Service] ERROR fetching videos for channel $id: ${e.message}');
        // Optionally rethrow or handle specific errors (like 404 maybe?)
      } catch (e) {
         print('[API Service] UNEXPECTED ERROR fetching videos for channel $id: $e');
      }
    }

    // 2. Fetch videos mentioning specified channels (avoid refetching direct uploads)
    for (final id in mentionChannelIds) {
      // Only fetch if this ID wasn't already fetched for direct subscriptions
      // or specifically for mentions
      if (processedChannelIds.contains(id) || processedMentionIds.contains(id)) continue;

      try {
        final response = await _dio.get('/videos', queryParameters: {
          'mentioned_channel_id': id,
          'include': includeParams,
          'from': fromIso,
          'limit': limit,
           'type': 'stream,clip,placeholder',// As per design doc III.4
           'status': 'new,upcoming,live,past,missing' // Fetch all relevant statuses
        });

        if (response.statusCode == 200 && response.data is List) {
            // Expecting a List<Map<String, dynamic>>
           allVideos.addAll(List<Map<String, dynamic>>.from(response.data));
        } else {
             // TODO: Log warning/error
            print('[API Service] WARN: Received status ${response.statusCode} or invalid data for mention $id');
        }
         processedMentionIds.add(id);
      } on DioException catch (e) {
           // TODO: More robust error logging/handling
           print('[API Service] ERROR fetching mentions for channel $id: ${e.message}');
      } catch (e) {
           print('[API Service] UNEXPECTED ERROR fetching mentions for channel $id: $e');
      }
    }

    // 3. Deduplicate results based on video ID
    // Using Set to ensure uniqueness based on video ID
    final Set<String?> seenVideoIds = {};
    final List<Map<String, dynamic>> distinctVideos = [];

    for (final video in allVideos) {
      final videoId = video['id'] as String?;
      if (seenVideoIds.add(videoId)) { // Set.add() returns true if the item was newly added (i.e., not already present)
        distinctVideos.add(video);
      }
    }
    // distinctVideos now contains only unique videos based on their 'id'

    print('[API Service] Fetched ${allVideos.length} videos raw, ${distinctVideos.length} distinct videos.');

    final List<VideoFull> parsedVideos = distinctVideos
    .map((jsonData) {
        try {
            return VideoFull.fromJson(jsonData);
        } catch (e, s) {
            // TODO: Use logging service
            print('Failed to parse VideoFull: $e\n$s\nData: $jsonData');
            return null; // Or handle error differently
        }
    })
    .whereType<VideoFull>() // Filter out nulls from failed parses
    .toList();
    print('[API Service] Parsed ${parsedVideos.length} VideoFull objects.');
    return parsedVideos;
  }


  /// Searches for channels based on a query string.
  /// Note: The Holodex API v2 /channels endpoint doesn't directly support free-text search.
  /// This implementation fetches a list and filters client-side, which might be inefficient.
  /// A better approach might require a different endpoint or strategy.
  @override
  Future<List<Channel>> searchChannels(String query) async {
    // _logger?.info('Searching channels for "$query" using autocomplete...');
    print('[API Service] Searching channels for "$query" using autocomplete...');
    if (query.isEmpty || query.length < 3) return [];

    try {
      // Use the /search/autocomplete endpoint
      final response = await _dio.get('/search/autocomplete', queryParameters: {
        'q': query,
      });

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> searchResults = response.data;

        // Filter and Parse results
        final List<Channel> parsedChannels = [];
        for (var item in searchResults) {
          if (item is Map<String, dynamic> && item['type'] == 'channel') {
            // Extract data based on the example response structure
            final String? channelId = item['value'];
            final String? channelText = item['text']; // This seems to be the display name

            if (channelId != null && channelText != null) {
              // Create a minimal Channel object.
              // We don't get org, photo, etc. from this endpoint.
              parsedChannels.add(
                Channel(
                  id: channelId,
                  name: channelText, // Use 'text' as the primary name
                  // Set other fields to null or default values as appropriate
                  englishName: null,
                  type: 'vtuber', // Assume vtuber, or null? API doesn't specify here
                  org: null,
                  group: null,
                  photo: null, // No photo from autocomplete
                  banner: null,
                  twitter: null,
                  videoCount: null,
                  subscriberCount: null,
                  viewCount: null,
                  clipCount: null,
                  lang: null,
                  publishedAt: null,
                  inactive: null,
                  description: null,
                ),
              );
            } else {
               // _logger?.warning('Autocomplete item missing ID or Text: $item');
               print('[API Service] WARN: Autocomplete item missing ID or Text: $item');
            }
          }
        }
        // _logger?.info('Found ${parsedChannels.length} channels via autocomplete.');
        print('[API Service] Found ${parsedChannels.length} channels via autocomplete.');
        return parsedChannels;

      } else {
        // _logger?.warning('Received status ${response.statusCode} or invalid data for autocomplete "$query"');
         print('[API Service] WARN: Received status ${response.statusCode} or invalid data for autocomplete "$query"');
        return [];
      }
    } on DioException catch (e) {
      // _logger?.error('DioError searching autocomplete "$query"', e.message);
       print('[API Service] ERROR searching autocomplete "$query": ${e.message}');
      return [];
    } catch (e) {
      // _logger?.error('Unexpected Error searching autocomplete "$query"', e);
       print('[API Service] UNEXPECTED ERROR searching autocomplete "$query": $e');
      return [];
    }
  }
}