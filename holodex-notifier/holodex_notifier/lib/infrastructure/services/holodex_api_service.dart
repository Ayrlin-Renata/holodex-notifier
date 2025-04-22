import 'package:dio/dio.dart';
import 'package:holodex_notifier/domain/interfaces/api_service.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';

class HolodexApiService implements IApiService {
  final Dio _dio;
  final ILoggingService _logger;

  HolodexApiService(this._dio, this._logger);

  @override
  Future<List<VideoFull>> fetchLiveVideos({required Set<String> channelIds}) async {
    if (channelIds.isEmpty) {
      _logger.info('[API Service - Live] Channel ID set is empty. Skipping /users/live fetch.');
      return [];
    }
    _logger.info('[API Service - Live] Fetching live/upcoming videos for ${channelIds.length} channels...');
    final String channelsParam = channelIds.join(',');

    try {
      _logger.debug('[API Service - Live] Requesting /users/live with channels: $channelsParam');
      final response = await _dio.get('/users/live', queryParameters: {'channels': channelsParam});

      if (response.statusCode == 200 && response.data is List) {
        final videosData = List<Map<String, dynamic>>.from(response.data);
        final parsedVideos = _parseVideoList(videosData, '/users/live');
        _logger.info('[API Service - Live] Success: Received and parsed ${parsedVideos.length} videos.');
        return parsedVideos;
      } else {
        _logger.warning(
          '[API Service - Live] WARN: Problem fetching live videos. Status: ${response.statusCode}, Data Type: ${response.data?.runtimeType}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _logger.error('[API Service - Live] Dio ERROR fetching live videos. Code:${e.response?.statusCode} Message: ${e.message}', e, s);
      return [];
    } catch (e, s) {
      _logger.error('[API Service - Live] UNEXPECTED ERROR fetching live videos', e, s);
      return [];
    }
  }

  @override
  Future<List<VideoFull>> fetchCollabVideos({required String channelId, required bool includeClips, required DateTime from}) async {
    _logger.info(
      '[API Service - Collabs] Fetching collab videos for channel: $channelId (includeClips: $includeClips, from: ${from.toIso8601String()})...',
    );

    final List<String> includeParts = ['live_info', 'mentions'];
    if (includeClips) {
      includeParts.add('clips');
    }
    final String includeParam = includeParts.join(',');
    _logger.trace('[API Service - Collabs] Using include parameter: "$includeParam"');

    try {
      _logger.debug('[API Service - Collabs] Requesting /videos');
      final response = await _dio.get(
        '/videos',
        queryParameters: {
          'mentioned_channel_id': channelId,
          'lang': 'en',
          'type': 'stream,placeholder',
          'include': includeParam,
          'from': from.toIso8601String(),
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final videosData = List<Map<String, dynamic>>.from(response.data);
        final parsedVideos = _parseVideoList(videosData, '/channels/$channelId/collabs');
        _logger.info('[API Service - Collabs] Success: Received and parsed ${parsedVideos.length} videos for channel $channelId.');
        return parsedVideos;
      } else {
        _logger.warning(
          '[API Service - Collabs] WARN: Problem fetching collab videos for $channelId. Status: ${response.statusCode}, Data Type: ${response.data?.runtimeType}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _logger.error(
        '[API Service - Collabs] Dio ERROR fetching collab videos for $channelId. Code:${e.response?.statusCode} Message: ${e.message}',
        e,
        s,
      );
      return [];
    } catch (e, s) {
      _logger.error('[API Service - Collabs] UNEXPECTED ERROR fetching collab videos for $channelId', e, s);
      return [];
    }
  }

  List<VideoFull> _parseVideoList(List<Map<String, dynamic>> videosData, String endpointName) {
    final List<VideoFull> parsedVideos = [];
    for (final jsonData in videosData) {
      try {
        parsedVideos.add(VideoFull.fromJson(jsonData));
      } catch (e, s) {
        _logger.error('[API Service - Parse] Failed to parse VideoFull from $endpointName: $e\nData: $jsonData', e, s);
      }
    }
    return parsedVideos;
  }

  @override
  Future<List<Channel>> searchChannels(String query) async {
    _logger.info('[API Service] Searching channels for "$query" using autocomplete...');
    if (query.isEmpty || query.length < 3) {
      _logger.debug('[API Service] Query too short, returning empty list.');
      return [];
    }

    try {
      _logger.debug('[API Service] Requesting autocomplete for query: $query');
      final response = await _dio.get('/search/autocomplete', queryParameters: {'q': query});

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> searchResults = response.data;
        _logger.debug('[API Service] Success: Received ${searchResults.length} autocomplete results for "$query"');

        final List<Channel> parsedChannels = [];
        for (var item in searchResults) {
          if (item is Map<String, dynamic> && item['type'] == 'channel') {
            final String? channelId = item['value'];
            final String? channelText = item['text'];

            if (channelId != null && channelText != null) {
              parsedChannels.add(
                Channel(
                  id: channelId,
                  name: channelText,

                  englishName: null,
                  type: 'vtuber',
                  org: null,
                  group: null,
                  photo: null,
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
              _logger.warning('[API Service] WARN: Autocomplete item missing ID or Text: $item');
            }
          } else {
            _logger.debug('[API Service] Skipping non-channel autocomplete item: $item');
          }
        }
        _logger.info('[API Service] Finished searching channels for "$query". Found ${parsedChannels.length} channels.');
        return parsedChannels;
      } else {
        _logger.warning(
          '[API Service] WARN: Problem searching autocomplete for "$query". Status: ${response.statusCode}, Data Type: ${response.data?.runtimeType}',
        );
        return [];
      }
    } on DioException catch (e, s) {
      _logger.error('[API Service] Dio ERROR searching autocomplete "$query". Code:${e.response?.statusCode} Message: ${e.message}', e, s);
      return [];
    } catch (e, s) {
      _logger.error('[API Service] UNEXPECTED ERROR searching autocomplete "$query"', e, s);
      return [];
    }
  }
}
