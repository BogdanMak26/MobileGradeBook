// lib/core/auth/biometric_service.dart

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult {
  success,
  failed,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
}

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnrolled() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<BiometricType?> getPrimaryType() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricType.face;
      if (types.contains(BiometricType.fingerprint)) return BiometricType.fingerprint;
      return types.isNotEmpty ? types.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<BiometricResult> authenticate(String reason) async {
    try {
      final success = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return success ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      return switch (e.code) {
        'NotAvailable'          => BiometricResult.notAvailable,
        'NotEnrolled'           => BiometricResult.notEnrolled,
        'LockedOut'             => BiometricResult.lockedOut,
        'PermanentlyLockedOut'  => BiometricResult.lockedOut,
        'UserCancel'            => BiometricResult.cancelled,
        'systemCancel'          => BiometricResult.cancelled,
        _                       => BiometricResult.failed,
      };
    }
  }
}

final biometricServiceProvider =
    Provider<BiometricService>((_) => BiometricService());
