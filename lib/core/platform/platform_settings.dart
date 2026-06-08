// lib/core/platform/platform_settings.dart

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlatformSettings {
  static const _ch = MethodChannel('com.viti.gradebook/settings');

  Future<void> openSecuritySettings() async {
    await _ch.invokeMethod<void>('openSecuritySettings');
  }

  /// True if the device has biometric hardware (even if not enrolled).
  /// Uses Android BiometricManager: returns false only for BIOMETRIC_ERROR_NO_HARDWARE.
  Future<bool> hasBiometricHardware() async {
    try {
      return await _ch.invokeMethod<bool>('hasBiometricHardware') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Schedules a native AlarmManager alarm that syncs the offline queue
  /// even when the app is killed (bypasses WorkManager throttling on OEM Android).
  static Future<void> scheduleOfflineSyncAlarm() async {
    try {
      await const MethodChannel('com.viti.gradebook/settings')
          .invokeMethod<void>('scheduleOfflineSyncAlarm');
    } catch (_) {}
  }

  /// Cancels the alarm when the queue is empty.
  static Future<void> cancelOfflineSyncAlarm() async {
    try {
      await const MethodChannel('com.viti.gradebook/settings')
          .invokeMethod<void>('cancelOfflineSyncAlarm');
    } catch (_) {}
  }

  /// True if the app is already exempt from battery optimisation
  /// (i.e. WorkManager will not be throttled by Doze / OEM power managers).
  Future<bool> checkBatteryOptimization() async {
    try {
      return await _ch.invokeMethod<bool>('checkBatteryOptimization') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens the system "Allow background activity" dialog.
  /// Should be called at most once; gate with SharedPreferences flag.
  Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _ch.invokeMethod<void>('requestIgnoreBatteryOptimization');
    } catch (_) {}
  }

  /// Invokes Android's BiometricPrompt with DEVICE_CREDENTIAL only —
  /// bypasses local_auth's biometric-enrollment check.
  /// Returns: 'success' | 'cancelled' | 'lockedOut' | 'notEnrolled' | 'failed' | 'notImplemented'
  Future<String> authenticateWithDeviceCredential(String reason) async {
    final result = await _ch.invokeMethod<String>(
      'authenticateWithDeviceCredential',
      {'reason': reason},
    );
    return result ?? 'failed';
  }
}

final platformSettingsProvider =
    Provider<PlatformSettings>((_) => PlatformSettings());
