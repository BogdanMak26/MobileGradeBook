// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final isCadet = authState.role == UserRole.cadet;
    final user = isCadet ? MockDataProvider.cadetUser : MockDataProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GradeBook'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              child: Text(
                user.surname[0],
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            _WelcomeBanner(name: user.fullName, role: authState.role ?? ''),
            const SizedBox(height: 20),

            // Stats row
            if (isCadet) ...[
              _CadetStatsRow(),
              const SizedBox(height: 20),
            ] else ...[
              _InstructorStatsRow(),
              const SizedBox(height: 20),
            ],

            // Quick actions
            Text('Швидкий доступ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
            const SizedBox(height: 12),
            _QuickActionsGrid(role: authState.role ?? ''),
          ],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final String role;
  const _WelcomeBanner({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.bannerStart, AppTheme.bannerEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Вітаємо! 👋',
                    style: TextStyle(
                        color: Color(0xFFFEE2B3), fontSize: 13)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(UserRole.displayName(role),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const Icon(Icons.school, color: Colors.white54, size: 48),
        ],
      ),
    );
  }
}

class _CadetStatsRow extends StatelessWidget {
  const _CadetStatsRow();

  @override
  Widget build(BuildContext context) {
    final grades = MockDataProvider.cadetGrades;
    final scored = grades.where((g) => g['score'] != null).toList();
    final avg = scored.isEmpty
        ? 0.0
        : scored.map((g) => g['score'] as int).reduce((a, b) => a + b) /
            scored.length;
    final attendancePct = grades.isEmpty
        ? 0
        : (grades.where((g) => g['status'] == 'present').length /
                grades.length *
                100)
            .round();

    return Row(children: [
      Expanded(child: _StatCard(
          label: 'Середній бал',
          value: avg > 0 ? avg.toStringAsFixed(1) : '—',
          icon: Icons.star,
          color: AppTheme.primary)),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(
          label: 'Відвідуваність',
          value: '$attendancePct%',
          icon: Icons.check_circle,
          color: const Color(0xFF059669))),
    ]);
  }
}

class _InstructorStatsRow extends StatelessWidget {
  const _InstructorStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatCard(
          label: 'Дисципліни',
          value: '${MockDataProvider.disciplines.length}',
          icon: Icons.menu_book,
          color: AppTheme.secondary)),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(
          label: 'Курсанти',
          value: '${MockDataProvider.cadets.length}',
          icon: Icons.people,
          color: AppTheme.primary)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.sidebar),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMid),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final String role;
  const _QuickActionsGrid({required this.role});

  @override
  Widget build(BuildContext context) {
    final isCadet = role == UserRole.cadet;
    final items = <_ActionItem>[
      _ActionItem(icon: Icons.menu_book, label: 'Дисципліни',
          sub: '${MockDataProvider.disciplines.length} дисциплін',
          color: AppTheme.secondary,
          onTap: () => context.go('/disciplines')),
      _ActionItem(icon: Icons.bar_chart, label: 'Рейтинг',
          sub: 'Успішність групи',
          color: AppTheme.primary,
          onTap: () => context.go(isCadet ? '/grades' : '/analytics')),
      _ActionItem(icon: Icons.calendar_today, label: 'Розклад',
          sub: 'На сьогодні',
          color: const Color(0xFF059669),
          onTap: () => context.go('/schedule')),
      _ActionItem(icon: Icons.person, label: 'Профіль',
          sub: 'Мої дані',
          color: const Color(0xFF7C3AED),
          onTap: () => context.go('/profile')),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items.map((a) => _ActionCard(item: a)).toList(),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem({required this.icon, required this.label,
    required this.sub, required this.color, required this.onTap});
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;
  const _ActionCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(item.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textDark)),
            Text(item.sub,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMid)),
          ],
        ),
      ),
    );
  }
}
