// lib/core/local/local_cache.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  static const _prefix = 'cache_';
  final SharedPreferences _prefs;

  LocalCache(this._prefs);

  Future<void> set(String key, dynamic data) async {
    final encoded = jsonEncode({
      'data': data,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    await _prefs.setString('$_prefix$key', encoded);
  }

  T? get<T>(String key) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return null;
    return (jsonDecode(raw) as Map<String, dynamic>)['data'] as T?;
  }

  bool hasValid(String key, {Duration maxAge = const Duration(hours: 24)}) {
    final raw = _prefs.getString('$_prefix$key');
    if (raw == null) return false;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final ts = decoded['ts'] as int;
    return DateTime.now().millisecondsSinceEpoch - ts < maxAge.inMilliseconds;
  }

  Future<void> remove(String key) => _prefs.remove('$_prefix$key');
}

final localCacheProvider = Provider<LocalCache>(
  (ref) => throw UnimplementedError('Override localCacheProvider in ProviderScope'),
);
