import 'dart:async';
import 'package:holodex_notifier/domain/interfaces/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus

class ConnectivityPlusService implements IConnectivityService {
  // Hold Connectivity instance
  final Connectivity _connectivity = Connectivity();

  @override
  Future<bool> isConnected() async {
     final connectivityResult = await _connectivity.checkConnectivity();
     // Check if connected to mobile or wifi (or others if needed)
     return connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi) ||
            connectivityResult.contains(ConnectivityResult.ethernet); // Add ethernet if relevant for desktop
  }

  @override
  Stream<bool> get connectivityStream {
    // Return connectivity stream, mapping result to bool
    return _connectivity.onConnectivityChanged.map((results) {
      return results.contains(ConnectivityResult.mobile) ||
             results.contains(ConnectivityResult.wifi) ||
             results.contains(ConnectivityResult.ethernet);
    }).asBroadcastStream(); // Use broadcast if multiple listeners might exist
  }
}