// lib/features/analytics/presentation/pages/analytics_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../shared/theme/app_theme.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';
  final String _group = '221';

  static const List<Map<String, dynamic>> _allCadets = [
    {'name': 'Макаренко Богдан',   'position': 'Командир відділення', 'group': '221', 'specialty': "Комп'ютерні науки", 'score': 96, 'attendance': 97},
    {'name': 'Науменко Олексій',   'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 95, 'attendance': 99},
    {'name': 'Ващик Олександр',    'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 88, 'attendance': 91},
    {'name': 'Чернікова Катерина', 'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 87, 'attendance': 100},
    {'name': 'Дубовик Владислав',  'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 84, 'attendance': 92},
    {'name': 'Бондаренко Дмитро',  'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 81, 'attendance': 89},
    {'name': 'Кравченко Іван',     'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 79, 'attendance': 94},
    {'name': 'Мельник Андрій',     'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 75, 'attendance': 87},
    {'name': 'Гриценко Сергій',    'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 72, 'attendance': 85},
    {'name': 'Шевченко Тарас',     'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 68, 'attendance': 80},
    {'name': 'Романенко Василь',   'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 65, 'attendance': 78},
    {'name': 'Лисенко Микола',     'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 63, 'attendance': 82},
  ];

  // Дисципліни для деталей кожного курсанта (мок)
  static List<Map<String, dynamic>> _disciplinesFor(String name) {
    final colors = [
      const Color(0xFF4ADE80), // зелений
      const Color(0xFFA78BFA), // фіолетовий
      const Color(0xFF60A5FA), // синій
      const Color(0xFFFBBF24), // жовтий
      const Color(0xFFF87171), // червоний
    ];
    final disciplines = [
      'Захист інформації в телекомунікаційних системах',
      'Комп\'ютерні мережі та технології',
      "Комп'ютерні науки та інформаційні технології",
      'Криптографічний захист інформації',
      'Основи кібербезпеки',
    ];
    return List.generate(disciplines.length, (i) => {
      'name': disciplines[i],
      'score': 65 + (i * 7 + name.length * 3) % 35,
      'attendance': 78 + (i * 5 + name.length * 2) % 22,
      'points': '${60 + (i * 8 + name.length) % 38}/100',
      'semester': 8,
      'color': colors[i % colors.length],
    });
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _filtered => _allCadets
      .where((c) => c['name'].toString().toLowerCase()
          .contains(_search.toLowerCase()))
      .toList();

  void _showDetails(BuildContext context, Map<String, dynamic> cadet, int rank) {
    showDialog(
      context: context,
      builder: (_) => _CadetDetailsDialog(
        cadet: cadet,
        rank: rank,
        disciplines: _disciplinesFor(cadet['name'] as String),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рейтинг'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Аналітика групи ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Аналітика групи',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  const Text('Рейтинг та статистика успішності вашої групи',
                      style: TextStyle(color: AppTheme.textMid, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.secondary, width: 1.5),
                    ),
                    child: Text('Група: $_group',
                        style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Налаштування ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Налаштування',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 12),
                  const Text('Група',
                      style: TextStyle(color: AppTheme.textMid, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(_group,
                        style: const TextStyle(color: AppTheme.textDark, fontSize: 15)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppTheme.border))),
                    child: TabBar(
                      controller: _tab,
                      onTap: (_) => setState(() {}),
                      indicatorColor: AppTheme.primary,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textMid,
                      tabs: const [
                        Tab(icon: Icon(Icons.menu_book_outlined, size: 18), text: 'Рейтинг'),
                        Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Статистика'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_tab.index == 0) ...[
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Пошук за прізвищем',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textMid, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Експорт в Excel',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Знайдено записів: ${filtered.length}',
                      style: const TextStyle(color: AppTheme.textMid, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Рейтинг або Статистика ─────────────────────────────────
          SliverToBoxAdapter(
            child: _tab.index == 0
                ? Column(
                    children: [
                      ...List.generate(filtered.length, (i) {
                        final cadet = filtered[i];
                        final rank = _allCadets.indexOf(cadet) + 1;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: _CadetRankCard(
                            cadet: cadet,
                            rank: rank,
                            onTap: () => _showDetails(context, cadet, rank),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  )
                : _StatisticsTab(cadets: _allCadets),
          ),
        ],
      ),
    );
  }
}

// ── Картка курсанта ───────────────────────────────────────────────────────────

class _CadetRankCard extends StatelessWidget {
  final Map<String, dynamic> cadet;
  final int rank;
  final VoidCallback onTap;
  const _CadetRankCard(
      {required this.cadet, required this.rank, required this.onTap});

  Color _rankBg() {
    if (rank == 1) return const Color(0xFFFEF3C7);
    if (rank == 2) return const Color(0xFFF3F4F6);
    if (rank == 3) return const Color(0xFFFEF3C7);
    return const Color(0xFFF9FAFB);
  }

  Color _rankFg() {
    if (rank == 1) return const Color(0xFFD97706);
    if (rank == 2) return const Color(0xFF6B7280);
    if (rank == 3) return const Color(0xFF92400E);
    return AppTheme.textLight;
  }

  @override
  Widget build(BuildContext context) {
    final score = cadet['score'] as int;
    final attendance = cadet['attendance'] as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cadet['name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textDark)),
                      const SizedBox(height: 2),
                      Text(cadet['position'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMid)),
                    ],
                  ),
                ),
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                      color: _rankBg(), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('$rank',
                      style: TextStyle(
                          color: _rankFg(),
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _InfoRow(label: 'Спеціальність:', value: cadet['specialty'] as String, bold: true),
            const SizedBox(height: 6),
            _InfoRow(label: 'Група:', value: cadet['group'] as String, bold: true),
            const SizedBox(height: 6),
            Row(children: [
              const Expanded(child: Text('Успішність:',
                  style: TextStyle(color: AppTheme.textMid, fontSize: 13))),
              _PercentBadge(value: score),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Expanded(child: Text('Відвідуваність:',
                  style: TextStyle(color: AppTheme.textMid, fontSize: 13))),
              _PercentBadge(value: attendance),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Діалог деталей курсанта ───────────────────────────────────────────────────

class _CadetDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> cadet;
  final int rank;
  final List<Map<String, dynamic>> disciplines;

  const _CadetDetailsDialog({
    required this.cadet,
    required this.rank,
    required this.disciplines,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Заголовок ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Деталі рейтингу: ${cadet['name']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMid),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Контент (скролиться) ────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Інформація про курсанта
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Група: ${cadet['group']}',
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.textDark)),
                        const SizedBox(height: 6),
                        const Text('Факультет: Факультет інформаційних технологій',
                            style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
                        const SizedBox(height: 6),
                        Text('Спеціальність: ${cadet['specialty']}',
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.textDark)),
                        const SizedBox(height: 6),
                        const Text('Рік вступу: 2022',
                            style: TextStyle(fontSize: 14, color: AppTheme.textDark)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Дисципліни
                  Text('Дисципліни',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 12),

                  ...disciplines.map((d) => _DisciplineCard(discipline: d)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Картка дисципліни в діалозі ───────────────────────────────────────────────

class _DisciplineCard extends StatelessWidget {
  final Map<String, dynamic> discipline;
  const _DisciplineCard({required this.discipline});

  @override
  Widget build(BuildContext context) {
    final color = discipline['color'] as Color;
    final score = discipline['score'] as int;
    final attendance = discipline['attendance'] as int;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(discipline['name'] as String,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark)),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Успішність: ',
                style: TextStyle(fontSize: 13, color: AppTheme.textDark)),
            _SmallBadge(value: '$score%', color: const Color(0xFF16A34A)),
            const SizedBox(width: 12),
            const Text('Відвідування: ',
                style: TextStyle(fontSize: 13, color: AppTheme.textDark)),
            _SmallBadge(
                value: '$attendance%',
                color: attendance >= 90
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF7C3AED)),
          ]),
          const SizedBox(height: 6),
          Text(
            'Бали: ${discipline['points']}  Семестр: ${discipline['semester']}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String value;
  final Color color;
  const _SmallBadge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(label,
          style: const TextStyle(color: AppTheme.textMid, fontSize: 13))),
      Text(value,
          style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13)),
    ]);
  }
}

class _PercentBadge extends StatelessWidget {
  final int value;
  const _PercentBadge({required this.value});

  Color get _bg {
    if (value >= 90) return const Color(0xFFDCFCE7);
    if (value >= 75) return const Color(0xFFDCFCE7);
    if (value >= 60) return const Color(0xFFFEF9C3);
    return const Color(0xFFFEE2E2);
  }

  Color get _fg {
    if (value >= 90) return const Color(0xFF166534);
    if (value >= 75) return const Color(0xFF166534);
    if (value >= 60) return const Color(0xFF854D0E);
    return const Color(0xFF991B1B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
      child: Text('$value%',
          style: TextStyle(color: _fg, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
// STATISTICS TAB — insert after existing TabBar in analytics_page.dart

// ── Статистика ────────────────────────────────────────────────────────────────

class _StatisticsTab extends StatelessWidget {
  final List<Map<String, dynamic>> cadets;
  const _StatisticsTab({required this.cadets});

  // Розподіл за рейтингом
  Map<String, int> get _distribution {
    int excellent = 0, good = 0, satisfactory = 0, poor = 0;
    for (final c in cadets) {
      final s = c['score'] as int;
      if (s >= 90) excellent++;
      else if (s >= 75) good++;
      else if (s >= 60) satisfactory++;
      else poor++;
    }
    return {'Відмінно': excellent, 'Добре': good, 'Задовільно': satisfactory, 'Незадовільно': poor};
  }

  double get _avgScore => cadets.isEmpty ? 0 :
    cadets.map((c) => c['score'] as int).reduce((a, b) => a + b) / cadets.length;

  double get _avgAttendance => cadets.isEmpty ? 0 :
    cadets.map((c) => c['attendance'] as int).reduce((a, b) => a + b) / cadets.length;

  @override
  Widget build(BuildContext context) {
    final dist = _distribution;
    final top10 = List<Map<String, dynamic>>.from(cadets)
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final top = top10.take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
      children: [
        // Заголовок
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Аналіз успішності курсантів',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text(
                'Статистичні дані щодо успішності курсантів, відвідуваності та інших освітніх показників.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMid),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Середні показники
        Row(children: [
          Expanded(child: _StatCard(
            label: 'Середній бал',
            value: _avgScore.toStringAsFixed(1),
            icon: Icons.star,
            color: const Color(0xFF6366F1),
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(
            label: 'Відвідуваність',
            value: '${_avgAttendance.toStringAsFixed(0)}%',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF059669),
          )),
        ]),
        const SizedBox(height: 12),

        // Розподіл рейтингу — donut chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Розподіл рейтингу курсантів',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            value: dist['Відмінно']!.toDouble(),
                            color: const Color(0xFF3B82F6),
                            radius: 45,
                            title: dist['Відмінно']! > 0
                                ? '${dist['Відмінно']}'
                                : '',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          PieChartSectionData(
                            value: dist['Добре']!.toDouble(),
                            color: const Color(0xFF10B981),
                            radius: 45,
                            title: dist['Добре']! > 0
                                ? '${dist['Добре']}'
                                : '',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          PieChartSectionData(
                            value: dist['Задовільно']!.toDouble(),
                            color: const Color(0xFFF59E0B),
                            radius: 45,
                            title: dist['Задовільно']! > 0
                                ? '${dist['Задовільно']}'
                                : '',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          PieChartSectionData(
                            value: dist['Незадовільно']!.toDouble(),
                            color: const Color(0xFFEF4444),
                            radius: 45,
                            title: dist['Незадовільно']! > 0
                                ? '${dist['Незадовільно']}'
                                : '',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Legend(color: const Color(0xFF3B82F6),
                            label: 'Відмінно',
                            count: dist['Відмінно']!,
                            total: cadets.length),
                        const SizedBox(height: 8),
                        _Legend(color: const Color(0xFF10B981),
                            label: 'Добре',
                            count: dist['Добре']!,
                            total: cadets.length),
                        const SizedBox(height: 8),
                        _Legend(color: const Color(0xFFF59E0B),
                            label: 'Задовільно',
                            count: dist['Задовільно']!,
                            total: cadets.length),
                        const SizedBox(height: 8),
                        _Legend(color: const Color(0xFFEF4444),
                            label: 'Незадовільно',
                            count: dist['Незадовільно']!,
                            total: cadets.length),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Топ-10 бар чарт
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Топ 10 курсантів за успішністю',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark)),
              const Text('Відсоток виконання завдань',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barGroups: top.asMap().entries.map((e) =>
                      BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: (e.value['score'] as int).toDouble(),
                            color: const Color(0xFF6366F1),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(fontSize: 9, color: AppTheme.textMid),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx >= top.length) return const SizedBox();
                            final name = top[idx]['name'] as String;
                            final lastName = name.split(' ').last;
                            return SideTitleWidget(
                              axisSide: AxisSide.bottom,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(lastName,
                                    style: const TextStyle(
                                        fontSize: 9, color: AppTheme.textMid)),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.border,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Відвідуваність donut
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Розподіл відвідуваності',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 45,
                        sections: _attendanceSections(cadets),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Legend(color: const Color(0xFF3B82F6),
                            label: 'Відмінно\n(≥95%)',
                            count: cadets.where((c) => (c['attendance'] as int) >= 95).length,
                            total: cadets.length),
                        const SizedBox(height: 6),
                        _Legend(color: const Color(0xFF10B981),
                            label: 'Добре\n(80-94%)',
                            count: cadets.where((c) => (c['attendance'] as int) >= 80 && (c['attendance'] as int) < 95).length,
                            total: cadets.length),
                        const SizedBox(height: 6),
                        _Legend(color: const Color(0xFFF59E0B),
                            label: 'Задовільно\n(60-79%)',
                            count: cadets.where((c) => (c['attendance'] as int) >= 60 && (c['attendance'] as int) < 80).length,
                            total: cadets.length),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      ),
    );
  }

  List<PieChartSectionData> _attendanceSections(List<Map<String, dynamic>> cadets) {
    final excellent = cadets.where((c) => (c['attendance'] as int) >= 95).length;
    final good = cadets.where((c) => (c['attendance'] as int) >= 80 && (c['attendance'] as int) < 95).length;
    final satisfactory = cadets.where((c) => (c['attendance'] as int) < 80).length;
    return [
      PieChartSectionData(value: excellent.toDouble(), color: const Color(0xFF3B82F6), radius: 40,
          title: excellent > 0 ? '$excellent' : '', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      PieChartSectionData(value: good.toDouble(), color: const Color(0xFF10B981), radius: 40,
          title: good > 0 ? '$good' : '', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      PieChartSectionData(value: satisfactory.toDouble(), color: const Color(0xFFF59E0B), radius: 40,
          title: satisfactory > 0 ? '$satisfactory' : '', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    ];
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
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
          Text(value, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _Legend({required this.color, required this.label,
      required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 10, height: 10,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Expanded(child: Text('$label: $count ($pct%)',
          style: const TextStyle(fontSize: 10, color: AppTheme.textDark))),
    ]);
  }
}
