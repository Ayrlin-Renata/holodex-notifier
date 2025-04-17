abstract class IBackgroundPollingService {
  Future<void> initialize();
  Future<void> startPolling();
  Future<void> stopPolling();
  Future<bool> isRunning();
  Future<void> triggerPoll();
  notifySettingChanged(String key, dynamic value);
}
