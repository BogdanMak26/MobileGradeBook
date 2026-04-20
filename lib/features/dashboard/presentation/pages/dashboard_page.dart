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
    final role = authState.role ?? '';
    final isCadet = role == UserRole.cadet;
    final isAdmin = role == UserRole.superAdmin;
    final user = isCadet
        ? MockDataProvider.cadetUser
        : MockDataProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Головна'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.go('/profile'),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down,
                    color: AppTheme.textMid, size: 18),
              ]),
            ),
          ),
        ],
      ),
      body: isCadet
          ? _CadetDashboard(user: user)
          : isAdmin
              ? _AdminDashboard(user: user)
              : _InstructorDashboard(user: user),
    );
  }
}

// ── Курсант ───────────────────────────────────────────────────────────────────

class _CadetDashboard extends StatelessWidget {
  final MockUser user;
  const _CadetDashboard({required this.user});

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeBanner(name: user.fullName, sub: 'Час для нових звершень!'),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _StatCard(
                    label: 'Середній бал',
                    value: avg > 0 ? avg.toStringAsFixed(1) : '—',
                    icon: Icons.star,
                    color: AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    label: 'Відвідуваність',
                    value: '$attendancePct%',
                    icon: Icons.check_circle,
                    color: const Color(0xFF059669))),
          ]),
          const SizedBox(height: 16),
          _QuickActions(isCadet: true),
        ],
      ),
    );
  }
}

// ── Викладач ──────────────────────────────────────────────────────────────────

class _InstructorDashboard extends StatelessWidget {
  final MockUser user;
  const _InstructorDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeBanner(name: user.fullName, sub: 'Час для нових звершень!'),
          const SizedBox(height: 16),
          _StatCard(
            label: 'Всього дисциплін',
            value: '${MockDataProvider.disciplines.length}',
            icon: Icons.school,
            color: AppTheme.secondary,
            wide: true,
          ),
          const SizedBox(height: 16),
          _ScheduleSection(),
          const SizedBox(height: 16),
          _QuickActions(isCadet: false),
        ],
      ),
    );
  }
}

// ── Адмін ─────────────────────────────────────────────────────────────────────

class _AdminDashboard extends StatelessWidget {
  final MockUser user;
  const _AdminDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeBanner(name: 'Адміне', sub: 'Час для нових звершень!'),
          const SizedBox(height: 16),
          _StatCard(
            label: 'Всього дисциплін',
            value: '137',
            icon: Icons.school,
            color: AppTheme.secondary,
            wide: true,
          ),
          const SizedBox(height: 16),
          _ScheduleSection(isAdmin: true),
          const SizedBox(height: 16),
          _QuickActions(isCadet: false, isAdmin: true),
        ],
      ),
    );
  }
}

// ── Welcome Banner ────────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final String sub;
  const _WelcomeBanner({required this.name, required this.sub});

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
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMid)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.sidebar)),
            ],
          ),
        ],
      ),
    );
    return wide ? content : content;
  }
}

// ── Розклад секція (для викладача/адміна) ─────────────────────────────────────

class _ScheduleSection extends StatefulWidget {
  final bool isAdmin;
  const _ScheduleSection({this.isAdmin = false});

  @override
  State<_ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends State<_ScheduleSection> {
  int _selectedTab = 2; // Факультет за замовчуванням (як на скріншоті)
  int _facultyNumber = 1;

  final _tabs = ['Кафедра', 'Курс', 'Факультет', 'Локація'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок з навігацією
          Row(children: [
            Expanded(
              child: Text(
                'Розклад ${_tabs[_selectedTab].toLowerCase()}у',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_selectedTab == 2) ...[
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppTheme.textMid, size: 18),
                onPressed: () => setState(() {
                  if (_facultyNumber > 1) _facultyNumber--;
                }),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('$_facultyNumber',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppTheme.textMid, size: 18),
                onPressed: () => setState(() => _facultyNumber++),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
            // Перемикачі виду
            const SizedBox(width: 4),
            _ViewToggle(icon: Icons.table_chart_outlined, selected: true, onTap: () {}),
            const SizedBox(width: 4),
            _ViewToggle(icon: Icons.calendar_today_outlined, selected: false, onTap: () {}),
          ]),
          const SizedBox(height: 12),

          // Таби: Кафедра / Курс / Факультет / Локація
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tabs.asMap().entries.map((e) {
                final isSelected = e.key == _selectedTab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.sidebar : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSelected
                              ? AppTheme.sidebar
                              : AppTheme.border),
                    ),
                    child: Text(e.value,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textDark)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Мінітаблиця розкладу
          _MiniScheduleTable(),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ViewToggle(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(icon,
            size: 18,
            color: selected ? AppTheme.primary : AppTheme.textMid),
      ),
    );
  }
}

class _MiniScheduleTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(70),
        border: TableBorder.all(color: AppTheme.border, width: 0.5),
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: AppTheme.surface),
            children: ['Група', 'Пн', 'Вт', 'Ср', 'Чт', "П'ят"]
                .map((h) => Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(h,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMid)),
                    ))
                .toList(),
          ),
          // Rows
          ...['121', '122', '221', '222', '231'].map((group) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(group,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark)),
                  ),
                  ...List.generate(
                      5,
                      (i) => Padding(
                            padding: const EdgeInsets.all(4),
                            child: group == '121' && i == 2
                                ? Container(
                                    padding: const EdgeInsets.all(3),
                                    color: const Color(0xFFDCFCE7),
                                    child: const Text('ВІЙСЬКОВЕ\nСТАЖУВАННЯ',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 8,
                                            color: Color(0xFF166534))),
                                  )
                                : Text('${i + 1}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMid)),
                          )),
                ],
              )),
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
      if (!isCadet)
        _ActionItem(
            icon: Icons.menu_book,
            label: 'Дисципліни',
            sub: '${MockDataProvider.disciplines.length} дисциплін',
            color: AppTheme.secondary,
            onTap: () => context.go('/disciplines')),
      if (isCadet)
        _ActionItem(
            icon: Icons.school,
            label: 'Дисципліни',
            sub: 'Мої дисципліни',
            color: AppTheme.secondary,
            onTap: () => context.go('/disciplines')),
      _ActionItem(
          icon: Icons.bar_chart,
          label: 'Рейтинг',
          sub: 'Успішність',
          color: AppTheme.primary,
          onTap: () => context.go('/analytics')),
      if (!isCadet)
        _ActionItem(
            icon: Icons.menu_book_outlined,
            label: 'Журнали',
            sub: 'Електронний журнал',
            color: const Color(0xFF059669),
            onTap: () => context.go('/journals')),
      if (isAdmin)
        _ActionItem(
            icon: Icons.settings,
            label: 'Адмін-панель',
            sub: 'Управління',
            color: const Color(0xFF7C3AED),
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
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: items.map((a) => _ActionCard(item: a)).toList(),
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
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });
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
            const SizedBox(height: 8),
            Text(item.label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textDark)),
            Text(item.sub,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textMid)),
          ],
        ),
      ),
    );
  }
}
