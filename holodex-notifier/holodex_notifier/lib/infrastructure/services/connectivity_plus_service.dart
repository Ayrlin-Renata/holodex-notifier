import 'dart:async';
import 'package:holodex_notifier/domain/interfaces/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:holodex_notifier/domain/interfaces/logging_service.dart';

class ConnectivityPlusService implements IConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final ILoggingService _logger;

  ConnectivityPlusService(this._logger);

  @override
  Future<bool> isConnected() async {
    _logger.debug('[Connectivity Service] Checking current connectivity...');
    final connectivityResult = await _connectivity.checkConnectivity();
    final bool connected =
        connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);
    _logger.info('[Connectivity Service] Current connectivity status: $connected (Result: $connectivityResult)');
    return connected;
  }

  @override
  Stream<bool> get connectivityStream {
    _logger.debug('[Connectivity Service] Subscribing to connectivity changes...');
    return _connectivity.onConnectivityChanged.map((results) {
      final bool connected =
          results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet);
      _logger.info('[Connectivity Service] Connectivity changed. New Status: $connected (Result: $results)');
      return connected;
    }).asBroadcastStream();
  }
}
