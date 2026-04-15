// lib/features/grades/presentation/pages/cadet_grades_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../shared/theme/app_theme.dart';

class CadetGradesPage extends StatefulWidget {
  const CadetGradesPage({super.key});

  @override
  State<CadetGradesPage> createState() => _CadetGradesPageState();
}

class _CadetGradesPageState extends State<CadetGradesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final grades = MockDataProvider.cadetGrades;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  double get avg {
    final scored = grades.where((g) => g['score'] != null).toList();
    if (scored.isEmpty) return 0;
    return scored.map((g) => g['score'] as int).reduce((a, b) => a + b) /
        scored.length;
  }

  int get presentCount =>
      grades.where((g) => g['status'] == 'present').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мої оцінки'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMid,
          tabs: const [
            Tab(text: 'Оцінки'),
            Tab(text: 'Статистика'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _GradesList(grades: grades),
          _StatsView(grades: grades, avg: avg, presentCount: presentCount),
        ],
      ),
    );
  }
}

class _GradesList extends StatelessWidget {
  final List<Map<String, dynamic>> grades;
  const _GradesList({required this.grades});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grades.length,
      itemBuilder: (context, i) {
        final g = grades[i];
        final score = g['score'] as int?;
        final status = g['status'] as String?;
        final date = g['date'] as DateTime;

        Color scoreColor;
        if (score == null) scoreColor = Colors.grey;
        else if (score >= 90) scoreColor = const Color(0xFF059669);
        else if (score >= 75) scoreColor = AppTheme.secondary;
        else if (score >= 60) scoreColor = AppTheme.primary;
        else scoreColor = const Color(0xFFEF4444);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              // Score circle
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: scoreColor.withOpacity(0.3), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  score?.toString() ?? '—',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: scoreColor),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g['discipline'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(g['lesson'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMid)),
                    const SizedBox(height: 4),
                    Text(DateFormat('dd.MM.yyyy').format(date),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
              ),

              // Status badge
              _StatusBadge(status: status),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'present': bg = const Color(0xFFDCFCE7); fg = const Color(0xFF166534); label = 'Присутній'; break;
      case 'absent': bg = const Color(0xFFFEE2E2); fg = const Color(0xFF991B1B); label = 'Відсутній'; break;
      case 'late': bg = const Color(0xFFFFF7ED); fg = const Color(0xFF9A3412); label = 'Запізнився'; break;
      default: bg = AppTheme.surface; fg = AppTheme.textMid; label = '—';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _StatsView extends StatelessWidget {
  final List<Map<String, dynamic>> grades;
  final double avg;
  final int presentCount;
  const _StatsView(
      {required this.grades,
      required this.avg,
      required this.presentCount});

  List<Widget> _buildDisciplineCards() {
    final disciplines = <String>{
      for (final g in grades) g['discipline'] as String
    }.toList();

    return disciplines.map((disc) {
      final discGrades = grades.where((g) => g['discipline'] == disc).toList();
      final scored = discGrades.where((g) => g['score'] != null).toList();
      final discAvg = scored.isEmpty
          ? 0.0
          : scored.map((g) => g['score'] as int).reduce((a, b) => a + b) /
              scored.length;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(disc,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(disc,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  Text('${discGrades.length} занять',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMid)),
                ],
              ),
            ),
            Text(
              discAvg > 0 ? discAvg.toStringAsFixed(1) : '—',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _avgColor(discAvg)),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = grades.length;
    final attendancePct =
        total > 0 ? (presentCount / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main stats banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.bannerStart, AppTheme.bannerEnd]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                    label: 'Середній бал',
                    value: avg > 0 ? avg.toStringAsFixed(1) : '—'),
                _StatItem(label: 'Відвідуваність', value: '$attendancePct%'),
                _StatItem(label: 'Занять', value: '$total'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('По дисциплінах',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),

          ..._buildDisciplineCards(),
        ],
      ),
    );
  }

  Color _avgColor(double avg) {
    if (avg == 0) return Colors.grey;
    if (avg >= 90) return const Color(0xFF059669);
    if (avg >= 75) return AppTheme.secondary;
    if (avg >= 60) return AppTheme.primary;
    return const Color(0xFFEF4444);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}
