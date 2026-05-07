// lib/core/sync/sync_service.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../local/offline_queue.dart';
import '../network/network_monitor.dart';

class SyncService {
  final OfflineQueueNotifier _queue;
  final ApiClient _apiClient;
  StreamSubscription<NetworkStatus>? _sub;

  SyncService(this._queue, this._apiClient, NetworkMonitor network) {
    _sub = network.statusStream.listen((status) {
      if (status == NetworkStatus.online) syncNow();
    });
  }

  Future<void> syncNow() async {
    final ops = _queue.getAll();
    for (final op in ops) {
      try {
        await _execute(op);
        await _queue.remove(op.id);
      } catch (_) {
        // залишити в черзі, повторити при наступному підключенні
      }
    }
  }

  Future<void> _execute(PendingOp op) async {
    final dio = _apiClient.dio;
    switch (op.method) {
      case 'POST':
        await dio.post(op.path, data: op.data);
      case 'PUT':
        await dio.put(op.path, data: op.data);
      case 'PATCH':
        await dio.patch(op.path, data: op.data);
      case 'DELETE':
        await dio.delete(op.path);
    }
  }

  void dispose() => _sub?.cancel();
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    ref.read(offlineQueueProvider.notifier),
    ref.read(apiClientProvider),
    ref.read(networkMonitorProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
