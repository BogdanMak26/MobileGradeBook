// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../core/mock/mock_data.dart';
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _mockLogin(String role) {
    ref.read(authViewModelProvider.notifier).mockLogin(role);
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
                        // Логотип
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school,
                              size: 46, color: AppTheme.primary),
                        ),
                        const SizedBox(height: 16),
                        Text('GradeBook',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Text('ВІТІ імені Героїв Крут',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textMid)),
                        const SizedBox(height: 28),

                        // Production секція
                        _Section(
                          title: 'Вхід через Google Workspace',
                          child: SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () => _mockLogin('INSTRUCTOR'),
                              icon: const Icon(Icons.login, size: 18),
                              label: const Text('Увійти через Google',
                                  style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w600)),
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
                                onTap: () => _mockLogin('INSTRUCTOR'),
                              ),
                              const SizedBox(height: 8),
                              _RoleButton(
                                label: 'Курсант',
                                subtitle: 'Сачук О.В.',
                                icon: Icons.school,
                                color: const Color(0xFF059669),
                                onTap: () => _mockLogin('CADET'),
                              ),
                              const SizedBox(height: 8),
                              _RoleButton(
                                label: 'Начальник кафедри',
                                subtitle: 'Кафедра №22',
                                icon: Icons.admin_panel_settings,
                                color: AppTheme.primary,
                                onTap: () => _mockLogin('DEPARTMENT_HEAD'),
                              ),
                              const SizedBox(height: 8),
                              _RoleButton(
                                label: 'Суперадмін',
                                subtitle: 'Повний доступ',
                                icon: Icons.security,
                                color: const Color(0xFF7C3AED),
                                onTap: () => _mockLogin('SUPER_ADMIN'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text('Електронний журнал успішності',
                            style: Theme.of(context).textTheme.bodySmall
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
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppTheme.textMid, fontWeight: FontWeight.w600)),
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
  const _RoleButton({required this.label, required this.subtitle,
    required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textDark)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMid)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}
