// lib/features/auth/presentation/pages/security_setup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/app_pin_service.dart';
import '../../../../core/auth/biometric_service.dart';
import '../../../../core/platform/platform_settings.dart';
import '../../../../shared/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

enum _SetupMode { prompt, pinSetup, pinConfirm }

class SecuritySetupPage extends ConsumerStatefulWidget {
  const SecuritySetupPage({super.key});

  @override
  ConsumerState<SecuritySetupPage> createState() => _SecuritySetupPageState();
}

class _SecuritySetupPageState extends ConsumerState<SecuritySetupPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  _SetupMode _mode = _SetupMode.prompt;
  bool _deviceSupportsBiometric = false;
  bool _loading = true;
  String? _error;
  String _pinInput = '';
  String _pinFirst = '';
  bool _returnedFromSettings = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _checkDevice();
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
      _onReturnedFromSettings();
    }
  }

  Future<void> _checkDevice() async {
    final platform = ref.read(platformSettingsProvider);
    final hasHardware = await platform.hasBiometricHardware();
    if (mounted) {
      setState(() {
        _deviceSupportsBiometric = hasHardware;
        _loading = false;
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

  Future<void> _onReturnedFromSettings() async {
    final bio = ref.read(biometricServiceProvider);
    // Accept either enrolled biometrics OR a PIN/pattern/password set up
    final enrolled = await bio.isEnrolled();
    final secured = await bio.isDeviceSupported();
    if (!mounted) return;
    if (enrolled || secured) {
      _dismiss();
    } else {
      setState(() => _error =
          'Захист ще не налаштовано. Спробуйте ще раз або оберіть PIN-код застосунку.');
    }
  }

  void _dismiss() {
    ref.read(authViewModelProvider.notifier).dismissSecurityPrompt();
    // Router redirect will send to /dashboard
  }

  // ── PIN ─────────────────────────────────────────────────────────────────────

  void _startPinSetup() {
    setState(() {
      _mode = _SetupMode.pinSetup;
      _pinInput = '';
      _error = null;
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
    if (_mode == _SetupMode.pinSetup) {
      setState(() {
        _pinFirst = _pinInput;
        _pinInput = '';
        _mode = _SetupMode.pinConfirm;
        _error = null;
      });
    } else if (_mode == _SetupMode.pinConfirm) {
      if (_pinInput != _pinFirst) {
        setState(() {
          _pinInput = '';
          _pinFirst = '';
          _mode = _SetupMode.pinSetup;
          _error = 'PIN-коди не збігаються. Спробуйте ще раз.';
        });
        return;
      }
      setState(() => _loading = true);
      await ref.read(appPinServiceProvider).setPin(_pinInput);
      if (!mounted) return;
      _dismiss();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : FadeTransition(
                  opacity: _fade,
                  child: _mode == _SetupMode.prompt
                      ? _buildPrompt()
                      : _buildPinUI(),
                ),
        ),
      ),
    );
  }

  // ── Prompt UI ────────────────────────────────────────────────────────────────

  Widget _buildPrompt() {
    return Column(
      children: [
        const SizedBox(height: 48),
        // Shield icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
                color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          child: const Icon(Icons.shield_outlined,
              color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          'Захистіть GradeBook',
          style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Text(
            'На вашому пристрої не налаштовано жодного способу захисту. '
            'Оберіть метод входу — він буде використовуватися щоразу, '
            'коли ви повертаєтеся до застосунку.',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 36),
        if (_error != null) _errorBox(),

        // Option 1: Biometric (shown only if device has hardware)
        if (_deviceSupportsBiometric)
          _optionCard(
            icon: Icons.fingerprint_rounded,
            title: 'Біометрія',
            subtitle: 'Відбиток пальця або розпізнавання обличчя',
            onTap: _openSecuritySettings,
          ),

        if (_deviceSupportsBiometric) const SizedBox(height: 12),

        // Option 2: App PIN (always available)
        _optionCard(
          icon: Icons.pin_outlined,
          title: 'PIN-код застосунку',
          subtitle: '6-значний код тільки для GradeBook',
          onTap: _startPinSetup,
        ),

        const Spacer(),

        // Skip
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: TextButton(
            onPressed: _dismiss,
            child: Text(
              'Пропустити (не рекомендується)',
              style: TextStyle(
                color: Colors.orange.withOpacity(0.7),
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: Colors.orange.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.2),
                  ),
                  child: Icon(icon, color: AppTheme.primary, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── PIN UI ───────────────────────────────────────────────────────────────────

  Widget _buildPinUI() {
    final subtitle = _mode == _SetupMode.pinSetup
        ? 'Введіть новий PIN-код'
        : 'Підтвердіть PIN-код';

    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
                color: Colors.white.withOpacity(0.25), width: 1.5),
          ),
          child: const Icon(Icons.pin_outlined,
              color: Colors.white, size: 38),
        ),
        const SizedBox(height: 20),
        const Text(
          'PIN-код застосунку',
          style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style:
              TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
        const SizedBox(height: 32),
        if (_error != null) _errorBox(),
        _pinDots(),
        const SizedBox(height: 32),
        _numpad(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: TextButton(
            onPressed: () => setState(() {
              _mode = _SetupMode.prompt;
              _pinInput = '';
              _pinFirst = '';
              _error = null;
            }),
            child: Text(
              'Назад до вибору',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ),
        ),
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
                      onTap: () =>
                          isBack ? _onPinBackspace() : _onPinDigit(key),
                      child: Center(
                        child: isBack
                            ? Icon(Icons.backspace_outlined,
                                color: Colors.white.withOpacity(0.8), size: 22)
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

  // ── Shared ───────────────────────────────────────────────────────────────────

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
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
}
