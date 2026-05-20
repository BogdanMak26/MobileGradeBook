// lib/features/grades/presentation/pages/cadet_grades_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_theme.dart';
import '../viewmodels/cadet_grades_viewmodel.dart';

class CadetGradesPage extends ConsumerStatefulWidget {
  const CadetGradesPage({super.key});

  @override
  ConsumerState<CadetGradesPage> createState() => _CadetGradesPageState();
}

class _CadetGradesPageState extends ConsumerState<CadetGradesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(cadetGradesViewModelProvider);
    final grades = vmState.grades;

    final scored = grades.where((g) => g['score'] != null).toList();
    final avg = scored.isEmpty
        ? 0.0
        : scored.map((g) => (g['score'] as num).toDouble()).reduce((a, b) => a + b) /
            scored.length;
    final attendanceValues = grades
        .map((g) => (g['attendancePercentage'] as num?)?.toDouble())
        .where((v) => v != null)
        .cast<double>()
        .toList();
    final avgAttendancePct = attendanceValues.isEmpty
        ? 0
        : (attendanceValues.reduce((a, b) => a + b) / attendanceValues.length).round();

    if (vmState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Мої оцінки')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          _StatsView(grades: grades, avg: avg, avgAttendancePct: avgAttendancePct),
        ],
      ),
    );
  }
}

class _GradesList extends StatelessWidget {
  final List<Map<String, dynamic>> grades;
  const _GradesList({required this.grades});

  Color _scoreColor(int? score) {
    if (score == null) return Colors.grey;
    if (score >= 90) return const Color(0xFF059669);
    if (score >= 75) return AppTheme.secondary;
    if (score >= 60) return AppTheme.primary;
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return const Center(
        child: Text('Немає даних про оцінки',
            style: TextStyle(color: AppTheme.textMid)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grades.length,
      itemBuilder: (context, i) {
        final g = grades[i];
        final score = g['score'] as int?;
        final attendancePct = g['attendancePercentage'] as int? ?? 100;
        final studentMarks = g['studentMarks'] as double?;
        final maxMarks = g['maxMarks'] as double?;
        final date = g['date'] as DateTime;
        final scoreColor = _scoreColor(score);

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
              // Score circle (rate %)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: scoreColor.withOpacity(0.3), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score != null ? '$score%' : '—',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: score != null && score >= 100 ? 12 : 14,
                          color: scoreColor),
                    ),
                  ],
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
                    Text(g['shortName'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMid)),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (studentMarks != null && maxMarks != null)
                        Text(
                          '${studentMarks.toStringAsFixed(1)} / ${maxMarks.toStringAsFixed(1)} б.',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textLight),
                        ),
                      if (studentMarks != null && maxMarks != null)
                        const SizedBox(width: 8),
                      Text(DateFormat('yyyy').format(date),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textLight)),
                    ]),
                  ],
                ),
              ),

              // Attendance badge
              _AttendanceBadge(pct: attendancePct),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  final int pct;
  const _AttendanceBadge({required this.pct});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (pct >= 90) {
      bg = const Color(0xFFDCFCE7); fg = const Color(0xFF166534);
    } else if (pct >= 75) {
      bg = const Color(0xFFFFF7ED); fg = const Color(0xFF9A3412);
    } else {
      bg = const Color(0xFFFEE2E2); fg = const Color(0xFF991B1B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text('$pct%',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _StatsView extends StatelessWidget {
  final List<Map<String, dynamic>> grades;
  final double avg;
  final int avgAttendancePct;
  const _StatsView(
      {required this.grades,
      required this.avg,
      required this.avgAttendancePct});

  List<Widget> _buildDisciplineCards() {
    return grades.map((g) {
      final score = g['score'] as int?;
      final attendancePct = g['attendancePercentage'] as int? ?? 100;
      final shortName = g['shortName'] as String? ?? '';
      final discName = g['discipline'] as String;
      final scoreColor = score == null
          ? Colors.grey
          : score >= 90
              ? const Color(0xFF059669)
              : score >= 75
                  ? AppTheme.secondary
                  : score >= 60
                      ? AppTheme.primary
                      : const Color(0xFFEF4444);

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(shortName.isNotEmpty ? shortName : discName.substring(0, discName.length.clamp(0, 3)),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(discName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textDark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.check_circle_outline,
                        size: 12, color: AppTheme.textLight),
                    const SizedBox(width: 3),
                    Text('Відвідуваність: $attendancePct%',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMid)),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  score != null ? '$score%' : '—',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scoreColor),
                ),
                const Text('рейтинг',
                    style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                    label: 'Середній рейтинг',
                    value: avg > 0 ? '${avg.toStringAsFixed(1)}%' : '—'),
                _StatItem(label: 'Відвідуваність', value: '$avgAttendancePct%'),
                _StatItem(label: 'Дисциплін', value: '${grades.length}'),
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
