// lib/features/grades/presentation/pages/grade_journal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../shared/theme/app_theme.dart';

class GradeJournalPage extends ConsumerStatefulWidget {
  final String disciplineId;
  const GradeJournalPage({super.key, required this.disciplineId});

  @override
  ConsumerState<GradeJournalPage> createState() => _GradeJournalPageState();
}

class _GradeJournalPageState extends ConsumerState<GradeJournalPage> {
  int _selectedLessonId = 1;
  late Map<int, MockGrade> _grades;

  @override
  void initState() {
    super.initState();
    final list = MockDataProvider.gradesForLesson(_selectedLessonId);
    _grades = {for (final g in list) g.cadetId: g};
  }

  void _selectLesson(int id) {
    setState(() {
      _selectedLessonId = id;
      final list = MockDataProvider.gradesForLesson(id);
      _grades = {for (final g in list) g.cadetId: g};
    });
  }

  void _updateGrade(int cadetId, {int? score, String? status}) {
    setState(() {
      final existing = _grades[cadetId] ??
          MockGrade(cadetId: cadetId);
      _grades[cadetId] = MockGrade(
        cadetId: cadetId,
        score: score ?? existing.score,
        status: status ?? existing.status,
        comment: existing.comment,
      );
    });
  }

  int get _presentCount =>
      _grades.values.where((g) => g.status == 'present').length;

  double get _avgScore {
    final scored =
        _grades.values.where((g) => g.score != null).toList();
    if (scored.isEmpty) return 0;
    return scored.map((g) => g.score!).reduce((a, b) => a + b) /
        scored.length;
  }

  @override
  Widget build(BuildContext context) {
    final discipline = MockDataProvider.disciplines
        .firstWhere((d) => d.id.toString() == widget.disciplineId,
            orElse: () => MockDataProvider.disciplines.first);
    final lessons = MockDataProvider.lessons
        .where((l) => l.disciplineName == discipline.shortName)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(discipline.shortName ?? 'Журнал',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Журнал • Група 221',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMid)),
          ],
        ),
        actions: [
          // Stats chip
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.people, size: 14, color: AppTheme.textMid),
              const SizedBox(width: 4),
              Text('$_presentCount/${MockDataProvider.cadets.length}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(children: [
              _SummaryChip(
                  label: 'Присутні',
                  value: '$_presentCount',
                  color: const Color(0xFF059669)),
              const SizedBox(width: 8),
              _SummaryChip(
                  label: 'Середній бал',
                  value: _avgScore > 0
                      ? _avgScore.toStringAsFixed(1)
                      : '—',
                  color: AppTheme.secondary),
              const SizedBox(width: 8),
              _SummaryChip(
                  label: 'Відсутні',
                  value: '${_grades.values.where((g) => g.status == 'absent').length}',
                  color: const Color(0xFFEF4444)),
            ]),
          ),
          const Divider(height: 1),

          // Lesson selector
          if (lessons.isNotEmpty)
            Container(
              height: 52,
              color: AppTheme.surface,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: lessons.length,
                itemBuilder: (context, i) {
                  final l = lessons[i];
                  final isSelected = _selectedLessonId == l.id;
                  return GestureDetector(
                    onTap: () => _selectLesson(l.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.border),
                      ),
                      child: Text(
                        'Зан. ${l.lessonNumber}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textDark),
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 52,
              color: AppTheme.surface,
              child: const Center(
                  child: Text('Заняття не знайдено',
                      style: TextStyle(color: AppTheme.textMid))),
            ),

          const Divider(height: 1),

          // Cadets list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: MockDataProvider.cadets.length,
              itemBuilder: (context, i) {
                final cadet = MockDataProvider.cadets[i];
                final grade = _grades[cadet.id];
                return _CadetRow(
                  cadet: cadet,
                  grade: grade,
                  onStatusChanged: (status) =>
                      _updateGrade(cadet.id, status: status),
                  onScoreChanged: (score) =>
                      _updateGrade(cadet.id, score: score),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textMid)),
        ],
      ),
    );
  }
}

class _CadetRow extends StatelessWidget {
  final MockCadet cadet;
  final MockGrade? grade;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<int?> onScoreChanged;

  const _CadetRow({
    required this.cadet,
    this.grade,
    required this.onStatusChanged,
    required this.onScoreChanged,
  });

  Color get _statusColor {
    switch (grade?.status) {
      case 'present': return const Color(0xFF059669);
      case 'absent': return const Color(0xFFEF4444);
      case 'late': return const Color(0xFFF97316);
      default: return AppTheme.textLight;
    }
  }

  IconData get _statusIcon {
    switch (grade?.status) {
      case 'present': return Icons.check_circle;
      case 'absent': return Icons.cancel;
      case 'late': return Icons.watch_later;
      default: return Icons.radio_button_unchecked;
    }
  }

  Color get _scoreColor {
    final s = grade?.score;
    if (s == null) return AppTheme.textLight;
    if (s >= 90) return const Color(0xFF059669);
    if (s >= 75) return AppTheme.secondary;
    if (s >= 60) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.secondary.withOpacity(0.1),
            child: Text(cadet.initial,
                style: const TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Text(
              cadet.fullName,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: AppTheme.textDark),
            ),
          ),

          // Status popup
          PopupMenuButton<String>(
            onSelected: onStatusChanged,
            itemBuilder: (_) => [
              _statusMenuItem('present', Icons.check_circle,
                  const Color(0xFF059669), 'Присутній'),
              _statusMenuItem('absent', Icons.cancel,
                  const Color(0xFFEF4444), 'Відсутній'),
              _statusMenuItem('late', Icons.watch_later,
                  const Color(0xFFF97316), 'Запізнився'),
            ],
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_statusIcon, color: _statusColor, size: 22),
            ),
          ),
          const SizedBox(width: 8),

          // Score
          _ScoreInput(
            score: grade?.score,
            color: _scoreColor,
            onChanged: onScoreChanged,
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _statusMenuItem(
      String value, IconData icon, Color color, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label),
      ]),
    );
  }
}

class _ScoreInput extends StatefulWidget {
  final int? score;
  final Color color;
  final ValueChanged<int?> onChanged;
  const _ScoreInput(
      {this.score, required this.color, required this.onChanged});

  @override
  State<_ScoreInput> createState() => _ScoreInputState();
}

class _ScoreInputState extends State<_ScoreInput> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.score?.toString() ?? '');
  }

  @override
  void didUpdateWidget(_ScoreInput old) {
    super.didUpdateWidget(old);
    if (!_editing) _ctrl.text = widget.score?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: widget.color),
        decoration: InputDecoration(
          hintText: '—',
          hintStyle: const TextStyle(
              color: AppTheme.textLight, fontSize: 15),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          filled: true,
          fillColor: widget.score != null
              ? widget.color.withOpacity(0.06)
              : AppTheme.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: widget.color.withOpacity(0.3))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: widget.score != null
                      ? widget.color.withOpacity(0.3)
                      : AppTheme.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.color, width: 2)),
        ),
        onTap: () => setState(() => _editing = true),
        onSubmitted: (val) {
          setState(() => _editing = false);
          final v = int.tryParse(val);
          if (v == null || (v >= 0 && v <= 100)) widget.onChanged(v);
        },
        onEditingComplete: () => setState(() => _editing = false),
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
}
