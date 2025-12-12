import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor internet connectivity status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  /// Check if device has internet connectivity
  Future<bool> hasConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      // If connectivity check fails, assume we have connectivity
      // to avoid false negatives
      return true;
    }
  }

  /// Get current connectivity type
  Future<ConnectivityStatus> getConnectivityStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      switch (result) {
        case ConnectivityResult.wifi:
          return ConnectivityStatus.wifi;
        case ConnectivityResult.mobile:
          return ConnectivityStatus.mobile;
        case ConnectivityResult.ethernet:
          return ConnectivityStatus.ethernet;
        case ConnectivityResult.none:
          return ConnectivityStatus.offline;
        default:
          return ConnectivityStatus.unknown;
      }
    } catch (e) {
      return ConnectivityStatus.unknown;
    }
  }

  /// Stream of connectivity changes
  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  /// Listen to connectivity changes
  void startMonitoring(Function(bool isConnected) onConnectivityChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      onConnectivityChanged(isConnected);
    });
  }

  /// Stop monitoring connectivity changes
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopMonitoring();
  }
}

enum ConnectivityStatus {
  wifi,
  mobile,
  ethernet,
  offline,
  unknown,
}
