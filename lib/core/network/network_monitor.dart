// lib/core/network/network_monitor.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class NetworkMonitor {
  final Connectivity _connectivity;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus _currentStatus = NetworkStatus.online;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  NetworkMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  void _init() {
    _subscription =
        _connectivity.onConnectivityChanged.listen(_onChanged);
    _connectivity.checkConnectivity().then(_onChanged);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    final next = isOnline ? NetworkStatus.online : NetworkStatus.offline;
    if (next != _currentStatus) {
      _currentStatus = next;
      _controller.add(next);
    }
  }

  Stream<NetworkStatus> get statusStream => _controller.stream;
  NetworkStatus get currentStatus => _currentStatus;
  bool get isOnline => _currentStatus == NetworkStatus.online;

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}

// ─── Providers (ручні) ───────────────────────────────────────────────────────

final networkMonitorProvider = Provider<NetworkMonitor>((ref) {
  final monitor = NetworkMonitor();
  ref.onDispose(monitor.dispose);
  return monitor;
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  return ref.watch(networkMonitorProvider).statusStream;
});
