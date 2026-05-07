// lib/core/auth/biometric_preferences.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'biometric_service.dart';

class BiometricState {
  final bool isEnabled;
  final bool isAvailable;
  final bool isEnrolled;
  final BiometricType? primaryType;
  final bool isInitialized;

  const BiometricState({
    this.isEnabled = false,
    this.isAvailable = false,
    this.isEnrolled = false,
    this.primaryType,
    this.isInitialized = false,
  });

  bool get canUse => isAvailable && isEnrolled;

  String get typeLabel {
    if (!isAvailable || !isEnrolled) return 'Недоступно на цьому пристрої';
    return switch (primaryType) {
      BiometricType.face        => 'Face ID',
      BiometricType.fingerprint => 'Відбиток пальця',
      BiometricType.iris        => 'Сканер райдужки',
      _                         => 'Біометрія',
    };
  }

  String get shortLabel {
    if (!canUse) return '';
    return switch (primaryType) {
      BiometricType.face        => 'Face ID',
      BiometricType.fingerprint => 'Відбиток',
      _                         => 'Біометрія',
    };
  }

  BiometricState copyWith({
    bool? isEnabled,
    bool? isAvailable,
    bool? isEnrolled,
    BiometricType? primaryType,
    bool? isInitialized,
  }) =>
      BiometricState(
        isEnabled: isEnabled ?? this.isEnabled,
        isAvailable: isAvailable ?? this.isAvailable,
        isEnrolled: isEnrolled ?? this.isEnrolled,
        primaryType: primaryType ?? this.primaryType,
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

class BiometricNotifier extends StateNotifier<BiometricState> {
  final BiometricService _service;
  SharedPreferences? _prefs;

  static const _enabledKey = 'biometric_enabled';
  static const _roleKey    = 'biometric_saved_role';

  BiometricNotifier(this._service) : super(const BiometricState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final isAvailable = await _service.isDeviceSupported();
    final isEnrolled  = isAvailable ? await _service.isEnrolled() : false;
    final primaryType = isEnrolled  ? await _service.getPrimaryType() : null;
    final isEnabled   = (_prefs!.getBool(_enabledKey) ?? false) && isEnrolled;

    if (mounted) {
      state = BiometricState(
        isEnabled: isEnabled,
        isAvailable: isAvailable,
        isEnrolled: isEnrolled,
        primaryType: primaryType,
        isInitialized: true,
      );
    }
  }

  String? get savedRole => _prefs?.getString(_roleKey);

  // Вмикає біометрію — спочатку підтверджує відбитком/Face ID
  Future<bool> enable({required String role}) async {
    if (!state.canUse) return false;
    final result = await _service.authenticate(
      'Підтвердіть особу для увімкнення біометричного входу',
    );
    if (result != BiometricResult.success) return false;
    await _prefs?.setBool(_enabledKey, true);
    await _prefs?.setString(_roleKey, role);
    state = state.copyWith(isEnabled: true);
    return true;
  }

  Future<void> disable() async {
    await _prefs?.setBool(_enabledKey, false);
    state = state.copyWith(isEnabled: false);
  }

  // Зберігає роль після будь-якого успішного входу (для подальшого biometric login)
  Future<void> saveRole(String role) async {
    await _prefs?.setString(_roleKey, role);
  }

  Future<BiometricResult> authenticate(String reason) =>
      _service.authenticate(reason);
}

final biometricProvider =
    StateNotifierProvider<BiometricNotifier, BiometricState>((ref) {
  return BiometricNotifier(ref.read(biometricServiceProvider));
});
