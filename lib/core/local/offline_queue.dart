// lib/core/local/offline_queue.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class PendingOp {
  final String id;
  final String method;
  final String path;
  final dynamic data;
  final DateTime createdAt;
  final String? label;    // напр. "Виставлена оцінка"
  final String? subtitle; // напр. "Іваненко І.І. · Заняття 3 · 85 балів"

  const PendingOp({
    required this.id,
    required this.method,
    required this.path,
    this.data,
    required this.createdAt,
    this.label,
    this.subtitle,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        if (label != null) 'label': label,
        if (subtitle != null) 'subtitle': subtitle,
      };

  factory PendingOp.fromJson(Map<String, dynamic> j) => PendingOp(
        id: j['id'] as String,
        method: j['method'] as String,
        path: j['path'] as String,
        data: j['data'],
        createdAt: DateTime.parse(j['createdAt'] as String),
        label: j['label'] as String?,
        subtitle: j['subtitle'] as String?,
      );
}

class OfflineQueueNotifier extends StateNotifier<int> {
  static const _key = 'offline_queue';
  final SharedPreferences _prefs;

  OfflineQueueNotifier(this._prefs) : super(0) {
    state = _loadOps().length;
  }

  List<PendingOp> getAll() => _loadOps();

  Future<void> enqueue(PendingOp op) async {
    final ops = _loadOps()..add(op);
    await _saveOps(ops);
    state = ops.length;
    // Реєструємо фонову задачу — виконається як тільки з'явиться мережа,
    // навіть якщо додаток буде повністю закритий.
    await Workmanager().registerOneOffTask(
      'offlineSyncPending',
      'com.viti.gradebook.offlineSync',
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  }

  Future<void> remove(String id) async {
    final ops = _loadOps().where((o) => o.id != id).toList();
    await _saveOps(ops);
    state = ops.length;
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
    state = 0;
  }

  List<PendingOp> _loadOps() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => PendingOp.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveOps(List<PendingOp> ops) =>
      _prefs.setString(_key, jsonEncode(ops.map((e) => e.toJson()).toList()));
}

// state = кількість операцій в черзі (для UI)
final offlineQueueProvider =
    StateNotifierProvider<OfflineQueueNotifier, int>(
  (ref) => throw UnimplementedError('Override offlineQueueProvider in ProviderScope'),
);
