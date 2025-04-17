import 'package:dio/dio.dart';
import 'package:holodex_notifier/domain/interfaces/api_service.dart';
import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';

class HolodexApiService implements IApiService {
  final Dio _dio;

  HolodexApiService(this._dio /*, {ILoggingService? logger} */) /* : _logger = logger */;

  @override
  Future<List<VideoFull>> fetchVideos({
    required Set<String> channelIds,
    required Set<String> mentionChannelIds,
    required DateTime from,
    int limit = 50,
  }) async {
    print('[API Service] Fetching videos for channels: ${channelIds.length}, mentions: ${mentionChannelIds.length} since ${from.toIso8601String()}');

    final List<Map<String, dynamic>> allVideos = [];
    final Set<String> processedChannelIds = {};
    final Set<String> processedMentionIds = {};

    final fromIso = from.toIso8601String();
    const includeParams = 'live_info,mentions';

    for (final id in channelIds) {
      if (processedChannelIds.contains(id)) continue;
      try {
        final response = await _dio.get(
          '/videos',
          queryParameters: {
            'channel_id': id,
            'include': includeParams,
            'from': fromIso,
            'limit': limit,
            'type': 'stream,clip,placeholder',
            'status': 'new,upcoming,live,past,missing',
          },
        );

        if (response.statusCode == 200 && response.data is List) {
          allVideos.addAll(List<Map<String, dynamic>>.from(response.data));
        } else {
          print('[API Service] WARN: Received status ${response.statusCode} or invalid data for channel $id');
        }
        processedChannelIds.add(id);
      } on DioException catch (e) {
        print('[API Service] ERROR fetching videos for channel $id: ${e.message}');
      } catch (e) {
        print('[API Service] UNEXPECTED ERROR fetching videos for channel $id: $e');
      }
    }

    for (final id in mentionChannelIds) {
      if (processedChannelIds.contains(id) || processedMentionIds.contains(id)) continue;

      try {
        final response = await _dio.get(
          '/videos',
          queryParameters: {
            'mentioned_channel_id': id,
            'include': includeParams,
            'from': fromIso,
            'limit': limit,
            'type': 'stream,clip,placeholder',
            'status': 'new,upcoming,live,past,missing',
          },
        );

        if (response.statusCode == 200 && response.data is List) {
          allVideos.addAll(List<Map<String, dynamic>>.from(response.data));
        } else {
          print('[API Service] WARN: Received status ${response.statusCode} or invalid data for mention $id');
        }
        processedMentionIds.add(id);
      } on DioException catch (e) {
        print('[API Service] ERROR fetching mentions for channel $id: ${e.message}');
      } catch (e) {
        print('[API Service] UNEXPECTED ERROR fetching mentions for channel $id: $e');
      }
    }

    final Set<String?> seenVideoIds = {};
    final List<Map<String, dynamic>> distinctVideos = [];

    for (final video in allVideos) {
      final videoId = video['id'] as String?;
      if (seenVideoIds.add(videoId)) {
        distinctVideos.add(video);
      }
    }

    print('[API Service] Fetched ${allVideos.length} videos raw, ${distinctVideos.length} distinct videos.');

    final List<VideoFull> parsedVideos =
        distinctVideos
            .map((jsonData) {
              try {
                return VideoFull.fromJson(jsonData);
              } catch (e, s) {
                print('Failed to parse VideoFull: $e\n$s\nData: $jsonData');
                return null;
              }
            })
            .whereType<VideoFull>()
            .toList();
    print('[API Service] Parsed ${parsedVideos.length} VideoFull objects.');
    return parsedVideos;
  }

  @override
  Future<List<Channel>> searchChannels(String query) async {
    print('[API Service] Searching channels for "$query" using autocomplete...');
    if (query.isEmpty || query.length < 3) return [];

    try {
      final response = await _dio.get('/search/autocomplete', queryParameters: {'q': query});

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> searchResults = response.data;

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
              print('[API Service] WARN: Autocomplete item missing ID or Text: $item');
            }
          }
        }
        print('[API Service] Found ${parsedChannels.length} channels via autocomplete.');
        return parsedChannels;
      } else {
        print('[API Service] WARN: Received status ${response.statusCode} or invalid data for autocomplete "$query"');
        return [];
      }
    } on DioException catch (e) {
      print('[API Service] ERROR searching autocomplete "$query": ${e.message}');
      return [];
    } catch (e) {
      print('[API Service] UNEXPECTED ERROR searching autocomplete "$query": $e');
      return [];
    }
  }
}
