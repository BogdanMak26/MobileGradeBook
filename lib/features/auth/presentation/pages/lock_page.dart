// lib/features/auth/presentation/pages/lock_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/auth/app_pin_service.dart';
import '../../../../core/auth/biometric_service.dart';
import '../../../../core/platform/platform_settings.dart';
import '../../../../shared/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

enum _LockMode { biometric, enrollPrompt, pinEntry, pinSetup, pinConfirm }

class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _loading = false;
  String? _error;
  _LockMode _mode = _LockMode.biometric;
  String _pinInput = '';
  String _pinFirst = '';
  bool _returnedFromSettings = false;
  // null until checked; used only for button icon/label
  BiometricType? _biometricType;

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadBiometricType();
      _authenticate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returnedFromSettings) {
      _returnedFromSettings = false;
      _authenticate();
    }
  }

  // ── Biometric type (icon/label only) ────────────────────────────────────────

  Future<void> _loadBiometricType() async {
    final type = await ref.read(biometricServiceProvider).getPrimaryType();
    if (mounted) setState(() => _biometricType = type);
  }

  IconData _biometricIcon() {
    if (_biometricType == BiometricType.face) return Icons.face_outlined;
    if (_biometricType == BiometricType.fingerprint) return Icons.fingerprint_rounded;
    return Icons.lock_open_rounded;
  }

  String _biometricLabel() {
    if (_biometricType == BiometricType.face) return 'Розпізнавання обличчя';
    if (_biometricType == BiometricType.fingerprint) return 'Відбиток пальця';
    return 'Підтвердити особу';
  }

  // ── Authentication ──────────────────────────────────────────────────────────

  Future<void> _authenticate() async {
    setState(() {
      _loading = true;
      _error = null;
      _mode = _LockMode.biometric;
    });
    try {
      final bio = ref.read(biometricServiceProvider);
      // biometricOnly: false → Android shows face/fingerprint with device
      // PIN/pattern as built-in fallback, all in one native dialog.
      final result = await bio.authenticate(
        'Підтвердіть особу для входу в GradeBook',
      );
      if (!mounted) return;
      switch (result) {
        case BiometricResult.success:
          await _restoreSession();
        case BiometricResult.lockedOut:
          setState(() {
            _loading = false;
            _error = 'Забагато невдалих спроб.\nРозблокуйте пристрій вручну.';
          });
        case BiometricResult.cancelled:
        case BiometricResult.failed:
          // User dismissed the dialog — show retry button.
          setState(() {
            _loading = false;
            _error = null;
          });
        case BiometricResult.notEnrolled:
          // local_auth says nothing is enrolled. On some devices this is a
          // false negative — try native credential dialog as safety net.
          await _authenticateWithCredential();
        case BiometricResult.notAvailable:
          // No hardware / no device security at all → app PIN.
          await _switchToAppPin();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Помилка: ${e.toString()}';
        });
      }
    }
  }

  // Uses native BiometricPrompt(DEVICE_CREDENTIAL) on Android 11+,
  // bypassing local_auth's biometric-enrollment pre-check.
  Future<void> _authenticateWithCredential() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final nativeResult = await ref
          .read(platformSettingsProvider)
          .authenticateWithDeviceCredential(
            'Введіть PIN або графічний ключ для входу в GradeBook',
          );
      if (!mounted) return;
      switch (nativeResult) {
        case 'success':
          await _restoreSession();
        case 'lockedOut':
          setState(() {
            _loading = false;
            _error = 'Забагато невдалих спроб.\nРозблокуйте пристрій вручну.';
          });
        case 'notEnrolled':
          // Device truly has no credential → app PIN.
          await _switchToAppPin();
        case 'notImplemented':
          // Android < 11 — fall back to local_auth credential auth.
          await _authenticateWithLocalAuth();
        default:
          setState(() {
            _loading = false;
            _error = null;
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Помилка: ${e.toString()}';
        });
      }
    }
  }

  // Fallback for Android < 11: local_auth with biometricOnly: false.
  Future<void> _authenticateWithLocalAuth() async {
    final result = await ref.read(biometricServiceProvider).authenticateWithCredential(
      'Введіть PIN або графічний ключ для входу в GradeBook',
    );
    if (!mounted) return;
    switch (result) {
      case BiometricResult.success:
        await _restoreSession();
      case BiometricResult.lockedOut:
        setState(() {
          _loading = false;
          _error = 'Забагато невдалих спроб.\nРозблокуйте пристрій вручну.';
        });
      case BiometricResult.notEnrolled:
      case BiometricResult.notAvailable:
        await _switchToAppPin();
      default:
        setState(() {
          _loading = false;
          _error = null;
        });
    }
  }

  Future<void> _openSecuritySettings() async {
    _returnedFromSettings = true;
    try {
      await ref.read(platformSettingsProvider).openSecuritySettings();
    } catch (_) {
      _returnedFromSettings = false;
      if (mounted) {
        setState(() => _error =
            'Не вдалося відкрити налаштування. Перейдіть вручну: Налаштування → Безпека.');
      }
    }
  }

  // ── App PIN ─────────────────────────────────────────────────────────────────

  Future<void> _switchToAppPin() async {
    final pinService = ref.read(appPinServiceProvider);
    final hasPin = await pinService.hasPin();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _pinInput = '';
      _mode = hasPin ? _LockMode.pinEntry : _LockMode.pinSetup;
    });
  }

  void _onPinDigit(String digit) {
    if (_pinInput.length >= 6) return;
    setState(() => _pinInput += digit);
    if (_pinInput.length == 6) _onPinComplete();
  }

  void _onPinBackspace() {
    if (_pinInput.isEmpty) return;
    setState(() => _pinInput = _pinInput.substring(0, _pinInput.length - 1));
  }

  Future<void> _onPinComplete() async {
    switch (_mode) {
      case _LockMode.pinEntry:
        await _verifyPin();
      case _LockMode.pinSetup:
        setState(() {
          _pinFirst = _pinInput;
          _pinInput = '';
          _mode = _LockMode.pinConfirm;
          _error = null;
        });
      case _LockMode.pinConfirm:
        await _confirmPin();
      default:
        break;
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _loading = true);
    final ok = await ref.read(appPinServiceProvider).verifyPin(_pinInput);
    if (!mounted) return;
    if (ok) {
      await _restoreSession();
    } else {
      setState(() {
        _loading = false;
        _pinInput = '';
        _error = 'Невірний PIN-код. Спробуйте ще раз.';
      });
    }
  }

  Future<void> _confirmPin() async {
    if (_pinInput != _pinFirst) {
      setState(() {
        _pinInput = '';
        _pinFirst = '';
        _mode = _LockMode.pinSetup;
        _error = 'PIN-коди не збігаються. Спробуйте ще раз.';
      });
      return;
    }
    setState(() => _loading = true);
    await ref.read(appPinServiceProvider).setPin(_pinInput);
    if (!mounted) return;
    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() => _loading = true);
    final ok =
        await ref.read(authViewModelProvider.notifier).loginWithBiometric();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Не вдалося відновити сесію.\nСпробуйте увійти знову.';
      });
    }
  }

  Future<void> _signOut() async {
    await ref.read(authViewModelProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF433F31)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: switch (_mode) {
              _LockMode.biometric    => _buildBiometricUI(),
              _LockMode.enrollPrompt => _buildEnrollPromptUI(),
              _                      => _buildPinUI(),
            },
          ),
        ),
      ),
    );
  }

  // ── Biometric UI ────────────────────────────────────────────────────────────

  Widget _buildBiometricUI() {
    return Column(
      children: [
        const Spacer(),
        _lockIcon(),
        const SizedBox(height: 28),
        const Text(
          'GradeBook',
          style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          'Підтвердіть свою особу для продовження',
          style:
              TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        if (_error != null) _errorBox(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _authenticate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_biometricIcon(), size: 22),
              label: Text(
                _loading ? 'Перевірка...' : _biometricLabel(),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const Spacer(),
        _signOutButton(),
      ],
    );
  }

  // ── Enroll Prompt UI ────────────────────────────────────────────────────────

  Widget _buildEnrollPromptUI() {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
                color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          child: const Icon(Icons.fingerprint_rounded,
              color: Colors.white, size: 48),
        ),
        const SizedBox(height: 28),
        const Text(
          'GradeBook',
          style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'Ваш пристрій підтримує біометричну аутентифікацію',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Налаштуйте відбиток пальця або розпізнавання обличчя для швидкого та безпечного входу.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 36),
        if (_error != null) _errorBox(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _openSecuritySettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.settings_outlined, size: 20),
              label: const Text(
                'Налаштувати біометрію',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _loading ? null : _authenticateWithCredential,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                    color: Colors.white.withOpacity(0.35), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Використати PIN пристрою',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
        const Spacer(),
        _signOutButton(),
      ],
    );
  }

  // ── PIN UI ──────────────────────────────────────────────────────────────────

  Widget _buildPinUI() {
    final subtitle = switch (_mode) {
      _LockMode.pinEntry   => 'Введіть PIN-код застосунку',
      _LockMode.pinSetup   => 'Встановіть PIN-код для GradeBook',
      _LockMode.pinConfirm => 'Підтвердіть PIN-код',
      _                    => '',
    };
    final isSetup =
        _mode == _LockMode.pinSetup || _mode == _LockMode.pinConfirm;

    return Column(
      children: [
        const SizedBox(height: 40),
        _lockIcon(),
        const SizedBox(height: 20),
        const Text(
          'GradeBook',
          style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style:
              TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14),
        ),
        if (isSetup) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Text(
              'На вашому пристрої не налаштовано захист екрану. '
              'Встановіть PIN-код для безпечного доступу до GradeBook.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.42), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 28),
        if (_error != null) _errorBox(),
        _pinDots(),
        const SizedBox(height: 32),
        _numpad(),
        const Spacer(),
        _signOutButton(),
      ],
    );
  }

  Widget _pinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < _pinInput.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white : Colors.transparent,
            border: Border.all(
              color: Colors.white.withOpacity(filled ? 1.0 : 0.4),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _numpad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: row.map((key) {
                if (key.isEmpty) return const SizedBox(width: 72, height: 58);
                final isBack = key == '⌫';
                return SizedBox(
                  width: 72,
                  height: 58,
                  child: Material(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: _loading
                          ? null
                          : () => isBack
                              ? _onPinBackspace()
                              : _onPinDigit(key),
                      child: Center(
                        child: isBack
                            ? Icon(Icons.backspace_outlined,
                                color: Colors.white.withOpacity(0.8),
                                size: 22)
                            : Text(key,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────────

  Widget _lockIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.12),
        border: Border.all(
            color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
      child: Icon(
        _loading ? Icons.lock_clock_outlined : Icons.lock_outline_rounded,
        color: Colors.white,
        size: 44,
      ),
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _signOutButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: TextButton(
        onPressed: _loading ? null : _signOut,
        child: Text(
          'Увійти з іншого акаунту',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
