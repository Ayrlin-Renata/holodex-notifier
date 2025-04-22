abstract class IConnectivityService {
  Future<bool> isConnected();
  Stream<bool> get connectivityStream;
}
