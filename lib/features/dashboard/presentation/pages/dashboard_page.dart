// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _itemFades;
  late List<Animation<Offset>> _itemSlides;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    // Staggered animations for each section
    _itemFades = List.generate(5, (i) {
      final start = i * 0.15;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _ctrl,
            curve: Interval(start, end, curve: Curves.easeOut)),
      );
    });

    _itemSlides = List.generate(5, (i) {
      final start = i * 0.15;
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
              begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _ctrl,
              curve: Interval(start, end, curve: Curves.easeOut)));
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    final i = index.clamp(0, 4);
    return FadeTransition(
      opacity: _itemFades[i],
      child: SlideTransition(position: _itemSlides[i], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final role = authState.role ?? '';
    final isCadet = role == UserRole.cadet;
    final isAdmin = role == UserRole.superAdmin;
    final user = isCadet
        ? MockDataProvider.cadetUser
        : MockDataProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          ClipOval(
            child: Image.asset('assets/images/logo.png',
                width: 28, height: 28, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.school, size: 24, color: AppTheme.primary)),
          ),
          const SizedBox(width: 8),
          const Text('Головна'),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
        actions: [
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _AvatarChip(name: user.fullName),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down,
                    color: AppTheme.textMid, size: 18),
              ]),
            ),
          ),
        ],
      ),
      body: isCadet
          ? _CadetDashboard(user: user, animated: _animated)
          : isAdmin
              ? _AdminDashboard(user: user, animated: _animated)
              : _InstructorDashboard(user: user, animated: _animated),
    );
  }
}

// ── Avatar chip в AppBar ───────────────────────────────────────────────────────

class _AvatarChip extends StatelessWidget {
  final String name;
  const _AvatarChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0] : '').join();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(initials.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 6),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 110),
        child: Text(name,
            style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ),
    ]);
  }
}

// ── Курсант ───────────────────────────────────────────────────────────────────

class _CadetDashboard extends StatelessWidget {
  final MockUser user;
  final Widget Function(int, Widget) animated;
  const _CadetDashboard({required this.user, required this.animated});

  @override
  Widget build(BuildContext context) {
    final grades = MockDataProvider.cadetGrades;
    final scored = grades.where((g) => g['score'] != null).toList();
    final avg = scored.isEmpty
        ? 0.0
        : scored.map((g) => g['score'] as int).reduce((a, b) => a + b) /
            scored.length;
    final total = grades.length;
    final present = grades.where((g) => g['status'] == 'present').length;
    final attendancePct = total == 0 ? 0 : (present / total * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          animated(0, _WelcomeBanner(
              name: user.fullName.split(' ').first,
              role: 'Курсант',
              sub: 'Час для нових звершень!')),
          const SizedBox(height: 16),
          animated(1, Row(children: [
            Expanded(child: _StatCard(
                label: 'Середній бал',
                value: avg > 0 ? avg.toStringAsFixed(1) : '—',
                icon: Icons.star_rounded,
                color: AppTheme.primary,
                progress: avg / 100)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
                label: 'Відвідуваність',
                value: '$attendancePct%',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF059669),
                progress: attendancePct / 100)),
          ])),
          const SizedBox(height: 16),
          animated(2, _QuickActions(isCadet: true)),
        ],
      ),
    );
  }
}

// ── Викладач ──────────────────────────────────────────────────────────────────

class _InstructorDashboard extends StatelessWidget {
  final MockUser user;
  final Widget Function(int, Widget) animated;
  const _InstructorDashboard({required this.user, required this.animated});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          animated(0, _WelcomeBanner(
              name: user.fullName.split(' ').first,
              role: 'Викладач',
              sub: 'Продуктивного дня!')),
          const SizedBox(height: 16),
          animated(1, _StatCard(
              label: 'Всього дисциплін',
              value: '${MockDataProvider.disciplines.length}',
              icon: Icons.school_rounded,
              color: AppTheme.secondary,
              wide: true)),
          const SizedBox(height: 16),
          animated(2, _QuickActions(isCadet: false)),
        ],
      ),
    );
  }
}

// ── Адмін ─────────────────────────────────────────────────────────────────────

class _AdminDashboard extends StatelessWidget {
  final MockUser user;
  final Widget Function(int, Widget) animated;
  const _AdminDashboard({required this.user, required this.animated});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          animated(0, _WelcomeBanner(
              name: 'Адміне',
              role: 'Суперадмін',
              sub: 'Все під контролем!')),
          const SizedBox(height: 16),
          animated(1, _StatCard(
              label: 'Всього дисциплін',
              value: '${MockDataProvider.disciplines.length}',
              icon: Icons.school_rounded,
              color: AppTheme.secondary,
              wide: true)),
          const SizedBox(height: 16),
          animated(2, _QuickActions(isCadet: false, isAdmin: true)),
        ],
      ),
    );
  }
}

// ── Welcome Banner ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final String role;
  final String sub;
  const _WelcomeBanner(
      {required this.name, required this.role, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.bannerStart, AppTheme.bannerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Вітаємо, $name!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(sub,
                    style: const TextStyle(
                        color: Color(0xFFFEE2B3), fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Text(role,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? progress;
  final bool wide;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.progress,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (wide) ...[
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMid)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.sidebar)),
                ]),
              ],
            ],
          ),
          if (!wide) ...[
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMid)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final bool isCadet;
  final bool isAdmin;
  const _QuickActions({required this.isCadet, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    final items = <_ActionItem>[
      _ActionItem(
          icon: Icons.menu_book_rounded,
          label: 'Дисципліни',
          sub: isCadet ? 'Мої дисципліни' : '${MockDataProvider.disciplines.length} дисциплін',
          color: AppTheme.secondary,
          gradientColors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          onTap: () => context.go('/disciplines')),
      _ActionItem(
          icon: Icons.bar_chart_rounded,
          label: 'Рейтинг',
          sub: 'Успішність',
          color: AppTheme.primary,
          gradientColors: const [Color(0xFFF97316), Color(0xFFFACC15)],
          onTap: () => context.go('/analytics')),
      if (!isCadet)
        _ActionItem(
            icon: Icons.library_books_rounded,
            label: 'Журнали',
            sub: 'Електронний журнал',
            color: const Color(0xFF059669),
            gradientColors: const [Color(0xFF059669), Color(0xFF34D399)],
            onTap: () => context.go('/journals')),
      _ActionItem(
          icon: Icons.calendar_month_rounded,
          label: 'Розклад',
          sub: 'Тижневий розклад',
          color: const Color(0xFF0284C7),
          gradientColors: const [Color(0xFF0284C7), Color(0xFF38BDF8)],
          onTap: () => context.go('/schedule')),
      if (isAdmin)
        _ActionItem(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Адмін-панель',
            sub: 'Управління',
            color: const Color(0xFF7C3AED),
            gradientColors: const [Color(0xFF7C3AED), Color(0xFFA855F7)],
            onTap: () => context.go('/admin')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Швидкий доступ',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textDark)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: items.asMap().entries
              .map((e) => _ActionCard(item: e.value, index: e.key))
              .toList(),
        ),
      ],
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.gradientColors,
    required this.onTap,
  });
}

class _ActionCard extends StatefulWidget {
  final _ActionItem item;
  final int index;
  const _ActionCard({required this.item, required this.index});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) {
        _pressCtrl.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _pressCtrl.reverse();
        item.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: item.gradientColors.first.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white)),
                  Text(item.sub,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.75)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
