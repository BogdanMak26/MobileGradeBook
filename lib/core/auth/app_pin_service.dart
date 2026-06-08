// lib/core/auth/app_pin_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppPinService {
  static const _key = 'app_pin_hash';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<bool> hasPin() async {
    final val = await _storage.read(key: _key);
    return val != null && val.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final hash = sha256.convert(utf8.encode(pin)).toString();
    await _storage.write(key: _key, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _key);
    if (stored == null) return false;
    final hash = sha256.convert(utf8.encode(pin)).toString();
    return hash == stored;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _key);
  }
}

final appPinServiceProvider = Provider<AppPinService>((_) => AppPinService());