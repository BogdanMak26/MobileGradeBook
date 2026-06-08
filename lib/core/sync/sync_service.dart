// lib/core/sync/sync_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../local/offline_queue.dart';
import '../network/network_monitor.dart';
import '../network/native_network_channel.dart';

class SyncService {
  final OfflineQueueNotifier _queue;
  final ApiClient _apiClient;
  StreamSubscription<NetworkStatus>? _sub;
  StreamSubscription<void>? _nativeSub;
  bool _syncing = false;

  SyncService(this._queue, this._apiClient, NetworkMonitor network) {
    _sub = network.statusStream.listen((status) {
      if (status == NetworkStatus.online) syncNow();
    });
    // Native Android callback: fires immediately when network returns,
    // even if the Dart isolate was suspended in the background.
    _nativeSub = nativeNetworkAvailableStream.listen((_) => syncNow());
    // Синхронізувати залишки черги одразу при старті (якщо мережа вже є)
    if (network.isOnline) syncNow();
  }

  Future<void> syncNow() async {
    // Guard against concurrent calls (e.g. from statusStream + nativeNetworkAvailableStream)
    if (_syncing) return;
    _syncing = true;
    try {
      // reload() ensures we see changes made by the WorkManager background isolate
      final ops = await _queue.getAll();
      for (final op in ops) {
        try {
          await _execute(op);
          await _queue.remove(op.id);
        } on DioException catch (e) {
          final status = e.response?.statusCode ?? 0;
          // 4xx (except 401 = token expired, worth retrying after refresh) means
          // the server rejected the payload — it will never succeed, so drop it.
          if (status >= 400 && status < 500 && status != 401) {
            await _queue.remove(op.id);
          }
        } catch (_) {
          // Network / 5xx → keep in queue, retry on next connection
        }
      }
    } finally {
      _syncing = false;
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

  void dispose() {
    _sub?.cancel();
    _nativeSub?.cancel();
  }
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
