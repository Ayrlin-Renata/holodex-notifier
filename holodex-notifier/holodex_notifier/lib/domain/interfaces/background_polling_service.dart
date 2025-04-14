abstract class IBackgroundPollingService {
  Future<void> initialize();
  Future<void> startPolling();
  Future<void> stopPolling();
  Future<bool> isRunning();
  // TODO: Add method to update poll frequency dynamically if needed
  // Future<void> updatePollFrequency(Duration frequency);
}