// lib/core/utils/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/disciplines/presentation/pages/disciplines_page.dart';
import '../../features/grades/presentation/pages/grade_journal_page.dart';
import '../../features/grades/presentation/pages/cadet_grades_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/groups/presentation/pages/my_group_page.dart';
import '../../shared/theme/app_theme.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = notifier.isAuthenticated;
      final isLogin = state.matchedLocation == '/login';
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login',       builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard',   builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/disciplines', builder: (_, __) => const DisciplinesPage()),
          GoRoute(
            path: '/disciplines/:id/journal',
            builder: (_, state) =>
                GradeJournalPage(disciplineId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/grades',    builder: (_, __) => const CadetGradesPage()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsPage()),
          GoRoute(path: '/schedule',  builder: (_, __) => const SchedulePage()),
          GoRoute(path: '/profile',   builder: (_, __) => const ProfilePage()),
          GoRoute(path: '/group',     builder: (_, __) => const MyGroupPage()),
        ],
      ),
    ],
  );

  ref.onDispose(() { notifier.dispose(); router.dispose(); });
  return router;
});

class _AuthRouterNotifier extends ChangeNotifier {
  bool _isAuthenticated;
  late final VoidCallback _cancel;

  _AuthRouterNotifier(Ref ref)
      : _isAuthenticated = ref.read(authViewModelProvider).isAuthenticated {
    _cancel = ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (prev?.isAuthenticated != next.isAuthenticated) {
        _isAuthenticated = next.isAuthenticated;
        notifyListeners();
      }
    }).close;
  }

  bool get isAuthenticated => _isAuthenticated;

  @override
  void dispose() { _cancel(); super.dispose(); }
}

// ── MainShell ──────────────────────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(
        authViewModelProvider.select((s) => s.role ?? ''));
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(role: role),
    );
  }
}

// ── Bottom Navigation ──────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final String role;
  const _BottomNav({required this.role});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    const items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Головна',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.school_outlined),
        activeIcon: Icon(Icons.school),
        label: 'Дисципліни',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Рейтинг',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Мій профіль',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.menu),
        activeIcon: Icon(Icons.menu),
        label: 'Більше',
      ),
    ];

    int idx = 0;
    if (location.startsWith('/disciplines')) idx = 1;
    else if (location.startsWith('/analytics') ||
             location.startsWith('/grades'))   idx = 2;
    else if (location.startsWith('/profile'))  idx = 3;

    return BottomNavigationBar(
      currentIndex: idx,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.sidebar,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: const Color(0xFFCBD5E1),
      selectedLabelStyle:
          const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      items: items,
      onTap: (i) {
        switch (i) {
          case 0: context.go('/dashboard'); break;
          case 1: context.go('/disciplines'); break;
          case 2: context.go('/analytics'); break;
          case 3: context.go('/profile'); break;
          case 4:
            // Відкриваємо меню як bottom sheet з темним фоном
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => _MoreMenu(
                onLogout: () {
                  Navigator.pop(context);
                  // logout через ref — викличемо через callback
                },
              ),
            );
            break;
        }
      },
    );
  }
}

// ── "Більше" меню (bottom sheet як drawer у веб) ──────────────────────────────

class _MoreMenu extends ConsumerWidget {
  final VoidCallback? onLogout;
  const _MoreMenu({this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.sidebar,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Заголовок
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('Меню',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Моя група
            _MenuItem(
              icon: Icons.group_outlined,
              label: 'Моя група',
              color: Colors.white,
              onTap: () {
                Navigator.pop(context);
                context.go('/group');
              },
            ),

            const Divider(color: Colors.white12, height: 1, indent: 56),

            // Розклад
            _MenuItem(
              icon: Icons.calendar_today_outlined,
              label: 'Розклад',
              color: Colors.white,
              onTap: () {
                Navigator.pop(context);
                context.go('/schedule');
              },
            ),

            const Divider(color: Colors.white12, height: 1, indent: 56),

            // Вийти
            _MenuItem(
              icon: Icons.logout,
              label: 'Вийти',
              color: AppTheme.primary,
              onTap: () {
                Navigator.pop(context);
                ref.read(authViewModelProvider.notifier).logout();
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
