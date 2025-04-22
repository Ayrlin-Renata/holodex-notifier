import 'package:holodex_notifier/domain/models/channel.dart';
import 'package:holodex_notifier/domain/models/video_full.dart';

abstract class IApiService {
  Future<List<VideoFull>> fetchLiveVideos({required Set<String> channelIds});

  Future<List<VideoFull>> fetchCollabVideos({required String channelId, required bool includeClips, required DateTime from});

  Future<List<Channel>> searchChannels(String query);
}
