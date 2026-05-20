// lib/features/auth/presentation/pages/lock_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/biometric_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Always try to authenticate — local_auth decides what to show
    // (biometric dialog, PIN dialog, or notAvailable if no hardware at all)
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bio = ref.read(biometricServiceProvider);
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
          setState(() {
            _loading = false;
            _error = null;
          });
        case BiometricResult.notAvailable:
          // No auth hardware at all — restore session without check
          await _restoreSession();
        case BiometricResult.notEnrolled:
          // Device has no PIN/biometric set up at all
          setState(() {
            _loading = false;
            _error =
                'На пристрої не налаштовано захист екрану.\nВстановіть PIN або відбиток у налаштуваннях.';
          });
        default:
          setState(() {
            _loading = false;
            _error = 'Аутентифікацію не підтверджено.';
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

  Future<void> _restoreSession() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .loginWithBiometric();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Не вдалося відновити сесію.\nСпробуйте увійти знову.';
      });
    }
    // On success the router redirect handles navigation to /dashboard
  }

  Future<void> _signOut() async {
    await ref.read(authViewModelProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

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
            child: Column(
              children: [
                const Spacer(),
                // Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1.5),
                  ),
                  child: Icon(
                    _loading
                        ? Icons.lock_clock_outlined
                        : Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'GradeBook',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Підтвердіть свою особу для продовження',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.red.withOpacity(0.4)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Authenticate button
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.fingerprint_rounded, size: 22),
                      label: Text(
                        _loading ? 'Перевірка...' : 'Підтвердити особу',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // Sign out link
                Padding(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
