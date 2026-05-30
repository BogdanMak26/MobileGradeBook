// lib/core/utils/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/disciplines/presentation/pages/disciplines_page.dart';
import '../../features/journals/presentation/pages/journals_page.dart';
import '../../features/grades/presentation/pages/grade_journal_page.dart';
import '../../features/grades/presentation/pages/cadet_grades_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/groups/presentation/pages/my_group_page.dart';
// AllGroupsPage is defined in my_group_page.dart
import '../../features/admin/presentation/pages/admin_page.dart';
import '../../features/notifications/presentation/pages/notifications_settings_page.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/pages/lock_page.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/utils/app_constants.dart';

const _rootPaths = {
  '/dashboard', '/disciplines', '/analytics',
  '/grades', '/schedule', '/profile', '/journals',
  '/groups', '/group', '/admin',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    onException: (_, __, router) {
      // OAuth callback deep links have no matching route — redirect to splash
      router.go('/splash');
    },
    redirect: (context, state) {
      final status = notifier.authStatus;
      final loc = state.matchedLocation;

      // Splash handles its own navigation — don't intercept
      if (loc == '/splash') return null;
      // Still determining auth state — don't redirect yet
      if (status == AuthStatus.initial || status == AuthStatus.loading) return null;

      if (status == AuthStatus.locked) {
        return loc == '/lock' ? null : '/lock';
      }
      if (status == AuthStatus.authenticated) {
        if (loc == '/login' || loc == '/lock') return '/dashboard';
        return null;
      }
      // unauthenticated or error
      if (loc != '/login') return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginPage()),
      GoRoute(path: '/lock',   builder: (_, __) => const LockPage()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsSettingsPage()),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard',   builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/disciplines', builder: (_, __) => const _ToDashboard(child: DisciplinesPage())),
          GoRoute(path: '/journals',    builder: (_, __) => const _ToDashboard(child: JournalsPage())),
          GoRoute(
            path: '/disciplines/:id/journal',
            builder: (_, state) =>
                GradeJournalPage(disciplineId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/grades',    builder: (_, __) => const _ToDashboard(child: CadetGradesPage())),
          GoRoute(path: '/analytics', builder: (_, __) => const _ToDashboard(child: AnalyticsPage())),
          GoRoute(path: '/schedule',  builder: (_, __) => const _ToDashboard(child: SchedulePage())),
          GoRoute(path: '/profile',   builder: (_, __) => const _ToDashboard(child: ProfilePage())),
          GoRoute(path: '/group',     builder: (_, __) => const _ToDashboard(child: MyGroupPage())),
          GoRoute(path: '/groups',    builder: (_, __) => const _ToDashboard(child: AllGroupsPage())),
          GoRoute(path: '/admin',     builder: (_, __) => const _ToDashboard(child: AdminPage())),
        ],
      ),
    ],
  );

  ref.onDispose(() { notifier.dispose(); router.dispose(); });
  return router;
});

class _AuthRouterNotifier extends ChangeNotifier {
  AuthStatus _authStatus;
  late final VoidCallback _cancel;

  _AuthRouterNotifier(Ref ref)
      : _authStatus = ref.read(authViewModelProvider).status {
    _cancel = ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      if (prev?.status != next.status) {
        _authStatus = next.status;
        notifyListeners();
      }
    }).close;
  }

  AuthStatus get authStatus => _authStatus;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated;

  @override
  void dispose() { _cancel(); super.dispose(); }
}

// ── MainShell ──────────────────────────────────────────────────────────────────

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // Реєструємось останніми → в reversed-ітерації будемо першими
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // WidgetsBinding.handlePopRoute() викликає didPopRoute у зворотному порядку.
  // Повертаємо true — подія вважається оброблена, SystemNavigator.pop() не буде.
  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;

    final loc = GoRouterState.of(context).matchedLocation;
    final router = GoRouter.of(context);

    // Відкрито діалог або bottom sheet → закрити його
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
      return true;
    }

    // Підсторінка зі стеком (context.push) → назад
    if (!_rootPaths.contains(loc) && router.canPop()) {
      router.pop();
      return true;
    }

    // Будь-яка вкладка навбару → на дашборд
    if (loc != '/dashboard') {
      context.go('/dashboard');
      return true;
    }

    // Дашборд → запитати про вихід
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Вийти з додатку?'),
        content: const Text('Закрити GradeBook?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Скасувати')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Вийти',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldExit == true && mounted) SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authViewModelProvider.select((s) => s.role ?? ''));

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _BottomNav(role: role),
    );
  }
}

// ── Role helpers ──────────────────────────────────────────────────────────────

bool _roleHasDisciplines(String role) =>
    role == UserRole.cadet ||
    role == UserRole.instructor ||
    role == UserRole.departmentHead ||
    role == UserRole.superAdmin;

bool _roleHasJournals(String role) =>
    role == UserRole.departmentHead ||
    role == UserRole.facultyEducation ||
    role == UserRole.instituteEducation ||
    role == UserRole.superAdmin;

// ── Bottom Navigation — різна залежно від ролі ────────────────────────────────

class _BottomNav extends StatelessWidget {
  final String role;
  const _BottomNav({required this.role});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isCadet = role == UserRole.cadet;
    final hasDisciplines = _roleHasDisciplines(role);
    final hasJournals = _roleHasJournals(role);

    // Будуємо список вкладок + відповідні маршрути для onTap.
    // Формат: (navItem, path для go())
    final entries = <({_NavItem item, String path})>[];

    entries.add((
      item: _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Головна'),
      path: '/dashboard',
    ));

    if (hasDisciplines) {
      entries.add((
        item: _NavItem(icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Дисципліни'),
        path: '/disciplines',
      ));
    }

    if (hasJournals) {
      entries.add((
        item: _NavItem(icon: Icons.library_books_outlined, activeIcon: Icons.library_books_rounded, label: 'Журнали'),
        path: '/journals',
      ));
    }

    if (isCadet) {
      entries.add((
        item: _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Рейтинг'),
        path: '/analytics',
      ));
    }

    entries.add((
      item: _NavItem(icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Профіль'),
      path: '/profile',
    ));

    entries.add((
      item: _NavItem(icon: Icons.menu_rounded, activeIcon: Icons.menu_rounded, label: 'Більше'),
      path: '',
    ));

    // Визначаємо активний індекс за поточним маршрутом.
    int idx = 0;
    for (int i = 0; i < entries.length; i++) {
      final p = entries[i].path;
      if (p.isNotEmpty && location.startsWith(p)) {
        idx = i;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.sidebar,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: entries.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value.item;
              final path = e.value.path;
              final isSelected = i == idx;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (path.isNotEmpty) {
                      context.go(path);
                    } else {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _MoreMenu(role: role),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 14 : 0,
                            vertical: isSelected ? 4 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFFCBD5E1),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.primary
                                : const Color(0xFF94A3B8),
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ── "Більше" меню — різне залежно від ролі ───────────────────────────────────

class _MoreMenu extends ConsumerWidget {
  final String role;
  const _MoreMenu({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = role == 'SUPER_ADMIN';
    final isCadet = role == 'CADET';

    return Container(
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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(children: [
                const Text('Меню',
                    style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Рейтинг — для всіх
            _MenuItem(icon: Icons.bar_chart, label: 'Рейтинг',
                color: Colors.white,
                onTap: () { Navigator.pop(context); context.go('/analytics'); }),
            const Divider(color: Colors.white12, height: 1, indent: 56),

            // Навчальні групи — не для курсанта
            if (!isCadet) ...[
              _MenuItem(icon: Icons.people_outline, label: 'Навчальні групи',
                  color: Colors.white,
                  onTap: () { Navigator.pop(context); context.go('/groups'); }),
              const Divider(color: Colors.white12, height: 1, indent: 56),
            ],

            // Моя група — тільки для курсанта
            if (isCadet) ...[
              _MenuItem(icon: Icons.group_outlined, label: 'Моя група',
                  color: Colors.white,
                  onTap: () { Navigator.pop(context); context.go('/group'); }),
              const Divider(color: Colors.white12, height: 1, indent: 56),
            ],

            // Розклад — для всіх
            _MenuItem(icon: Icons.calendar_today_outlined, label: 'Розклад',
                color: Colors.white,
                onTap: () { Navigator.pop(context); context.go('/schedule'); }),
            const Divider(color: Colors.white12, height: 1, indent: 56),

            // Адмін-панель — тільки для адміна
            if (isAdmin) ...[
              _MenuItem(icon: Icons.settings_outlined, label: 'Адмін-панель',
                  color: Colors.white,
                  onTap: () { Navigator.pop(context); context.go('/admin'); }),
              const Divider(color: Colors.white12, height: 1, indent: 56),
            ],

            // Вийти
            _MenuItem(icon: Icons.logout, label: 'Вийти',
                color: AppTheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authViewModelProvider.notifier).logout();
                }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Перехоплює свайп-назад на вкладках навбару → повертає на /dashboard ────────

class _ToDashboard extends StatelessWidget {
  final Widget child;
  const _ToDashboard({required this.child});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.go('/dashboard');
    },
    child: child,
  );
}

// ── Пункт меню "Більше" ───────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Text(label,
              style: TextStyle(color: color, fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
