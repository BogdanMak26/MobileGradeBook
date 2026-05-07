// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool _isLoading = false;
  String? _errorMessage;
  String? _loadingRole;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _login(String role) async {
    setState(() {
      _isLoading = true;
      _loadingRole = role;
      _errorMessage = null;
    });

    try {
      // Симуляція затримки мережі
      await Future.delayed(const Duration(milliseconds: 1200));
      ref.read(authViewModelProvider.notifier).mockLogin(role);
    } catch (e) {
      setState(() {
        _errorMessage = 'Помилка авторизації. Спробуйте ще раз.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingRole = null;
        });
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _isLoading = true;
      _loadingRole = 'GOOGLE';
      _errorMessage = null;
    });

    try {
      await ref.read(authViewModelProvider.notifier).login();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Помилка авторизації: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingRole = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.loginGradientStart, AppTheme.loginGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Логотип з пульсацією при завантаженні
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLoading
                                ? AppTheme.primary.withOpacity(0.1)
                                : AppTheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: _isLoading
                                    ? AppTheme.primary.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: _isLoading ? 20 : 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.school, size: 46,
                                        color: AppTheme.primary),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text('GradeBook',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Text('ВІТІ імені Героїв Крут',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textMid)),
                        const SizedBox(height: 24),

                        // Повідомлення про помилку
                        if (_errorMessage != null) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMessage!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF991B1B))),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _errorMessage = null),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Color(0xFF991B1B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Google Workspace вхід
                        _Section(
                          title: 'Вхід через Google Workspace',
                          child: SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isLoading ? null : _googleLogin,
                              icon: _loadingRole == 'GOOGLE'
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.login, size: 18),
                              label: Text(
                                _loadingRole == 'GOOGLE'
                                    ? 'Підключення...'
                                    : 'Увійти через Google',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dev секція — вибір ролі
                        _Section(
                          title: 'Тестовий вхід (Dev)',
                          child: Column(
                            children: [
                              _RoleButton(
                                label: 'Викладач',
                                subtitle: 'Макаренко Б.Л.',
                                icon: Icons.person,
                                color: AppTheme.secondary,
                                isLoading: _loadingRole == 'INSTRUCTOR',
                                disabled: _isLoading,
                                onTap: () => _login('INSTRUCTOR'),
                              ),
                              const SizedBox(height: 8),
                              _RoleButton(
                                label: 'Курсант',
                                subtitle: 'Сачук О.В.',
                                icon: Icons.school,
                                color: const Color(0xFF059669),
                                isLoading: _loadingRole == 'CADET',
                                disabled: _isLoading,
                                onTap: () => _login('CADET'),
                              ),
                              const SizedBox(height: 8),
                              _RoleButton(
                                label: 'Начальник кафедри',
                                subtitle: 'Кафедра №22',
                                icon: Icons.admin_panel_settings,
                                color: AppTheme.primary,
                                isLoading:
                                    _loadingRole == 'DEPARTMENT_HEAD',
                                disabled: _isLoading,
                                onTap: () => _login('DEPARTMENT_HEAD'),
                              ),
                              const SizedBox(height: 8),
                              _RoleButton(
                                label: 'Суперадмін',
                                subtitle: 'Повний доступ',
                                icon: Icons.security,
                                color: const Color(0xFF7C3AED),
                                isLoading: _loadingRole == 'SUPER_ADMIN',
                                disabled: _isLoading,
                                onTap: () => _login('SUPER_ADMIN'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text('Електронний журнал успішності',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.textMid, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;
  final bool disabled;

  const _RoleButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled && !isLoading ? 0.5 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isLoading ? color.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isLoading ? color : AppTheme.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: color))
                    : Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? 'Завантаження...' : label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isLoading ? color : AppTheme.textDark),
                    ),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMid)),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox.shrink()
              else
                const Icon(Icons.chevron_right,
                    color: AppTheme.textLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
