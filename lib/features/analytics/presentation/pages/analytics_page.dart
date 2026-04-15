// lib/features/analytics/presentation/pages/analytics_page.dart

import 'package:flutter/material.dart';
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
  String _group = '221';

  // Всі курсанти групи відсортовані за рейтингом
  final List<Map<String, dynamic>> _allCadets = [
    {'name': 'Макаренко Богдан',    'position': 'Командир відділення', 'group': '221', 'specialty': "Комп'ютерні науки", 'score': 96, 'attendance': 97},
    {'name': 'Науменко Олексій',    'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 95, 'attendance': 99},
    {'name': 'Ващик Олександр',     'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 88, 'attendance': 91},
    {'name': 'Чернікова Катерина',  'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 87, 'attendance': 100},
    {'name': 'Дубовик Владислав',   'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 84, 'attendance': 92},
    {'name': 'Бондаренко Дмитро',   'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 81, 'attendance': 89},
    {'name': 'Кравченко Іван',      'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 79, 'attendance': 94},
    {'name': 'Мельник Андрій',      'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 75, 'attendance': 87},
    {'name': 'Гриценко Сергій',     'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 72, 'attendance': 85},
    {'name': 'Шевченко Тарас',      'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 68, 'attendance': 80},
    {'name': 'Романенко Василь',    'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 65, 'attendance': 78},
    {'name': 'Лисенко Микола',      'position': 'Курсант',             'group': '221', 'specialty': "Комп'ютерні науки", 'score': 63, 'attendance': 82},
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    return _allCadets
        .where((c) =>
            c['name'].toString().toLowerCase().contains(_search.toLowerCase()))
        .toList();
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
          // ── Заголовок аналітики ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Аналітика групи',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  const Text(
                      'Рейтинг та статистика успішності вашої групи',
                      style: TextStyle(
                          color: AppTheme.textMid, fontSize: 13)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.secondary, width: 1.5),
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

          // ── Блок налаштувань ─────────────────────────────────────────────
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark)),
                  const SizedBox(height: 12),

                  // Поле групи
                  const Text('Група',
                      style: TextStyle(
                          color: AppTheme.textMid, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(_group,
                        style: const TextStyle(
                            color: AppTheme.textDark, fontSize: 15)),
                  ),
                  const SizedBox(height: 16),

                  // Tabs — іконка книги і графіка
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: AppTheme.border)),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicatorColor: AppTheme.primary,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textMid,
                      tabs: const [
                        Tab(icon: Icon(Icons.menu_book_outlined, size: 22)),
                        Tab(icon: Icon(Icons.bar_chart, size: 22)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Пошук
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

                  // Кнопка експорту
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Експорт в Excel'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Знайдено записів
                  Text(
                    'Знайдено записів: ${filtered.length}',
                    style: const TextStyle(
                        color: AppTheme.textMid, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Список курсантів ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final cadet = filtered[i];
                  // rank — позиція в повному списку (не у відфільтрованому)
                  final rank = _allCadets.indexOf(cadet) + 1;
                  return _CadetRankCard(
                    cadet: cadet,
                    rank: rank,
                  );
                },
                childCount: filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Картка курсанта ────────────────────────────────────────────────────────────

class _CadetRankCard extends StatelessWidget {
  final Map<String, dynamic> cadet;
  final int rank;
  const _CadetRankCard({required this.cadet, required this.rank});

  Color _rankBg() {
    if (rank == 1) return const Color(0xFFFEF3C7); // gold light
    if (rank == 2) return const Color(0xFFF3F4F6); // silver light
    if (rank == 3) return const Color(0xFFFEF3C7); // bronze light
    return const Color(0xFFF9FAFB);
  }

  Color _rankFg() {
    if (rank == 1) return const Color(0xFFD97706); // gold
    if (rank == 2) return const Color(0xFF6B7280); // silver
    if (rank == 3) return const Color(0xFF92400E); // bronze
    return AppTheme.textLight;
  }

  @override
  Widget build(BuildContext context) {
    final score = cadet['score'] as int;
    final attendance = cadet['attendance'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ім'я + позиція рейтингу
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
                            fontSize: 12,
                            color: AppTheme.textMid)),
                  ],
                ),
              ),
              // Номер позиції
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _rankBg(),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: TextStyle(
                      color: _rankFg(),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Спеціальність
          _InfoRow(
            label: 'Спеціальність:',
            value: cadet['specialty'] as String,
            bold: true,
          ),
          const SizedBox(height: 6),

          // Група
          _InfoRow(
            label: 'Група:',
            value: cadet['group'] as String,
            bold: true,
          ),
          const SizedBox(height: 6),

          // Успішність
          Row(
            children: [
              const Expanded(
                child: Text('Успішність:',
                    style: TextStyle(
                        color: AppTheme.textMid, fontSize: 13)),
              ),
              _PercentBadge(value: score),
            ],
          ),
          const SizedBox(height: 6),

          // Відвідуваність
          Row(
            children: [
              const Expanded(
                child: Text('Відвідуваність:',
                    style: TextStyle(
                        color: AppTheme.textMid, fontSize: 13)),
              ),
              _PercentBadge(value: attendance),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.textMid, fontSize: 13)),
        ),
        Text(value,
            style: TextStyle(
                color: AppTheme.textDark,
                fontWeight:
                    bold ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13)),
      ],
    );
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
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$value%',
          style: TextStyle(
              color: _fg,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }
}
