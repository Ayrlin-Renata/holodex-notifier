import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';

abstract class IApiService {
  Future<List<VideoFull>> fetchVideos({required Set<String> channelIds, required Set<String> mentionChannelIds, required DateTime from});

  Future<List<Channel>> searchChannels(String query);
}
