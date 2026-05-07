// lib/features/grades/presentation/pages/grade_journal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

// ── Мокові заняття для журналу ────────────────────────────────────────────────
const _mockLessons = [
  {'code': 'Л 1/1',  'type': 'ЛЕКЦІЯ',           'date': '07.01.2026', 'topic': 'Мобільні пристрої та платформи',               'maxScore': null},
  {'code': 'ГЗ 1/2', 'type': 'ГРУПОВЕ ЗАНЯТТЯ',   'date': '09.01.2026', 'topic': 'Введення у розробку ПЗ під ОС Android',        'maxScore': 2.0},
  {'code': 'ГЗ 1/3', 'type': 'ГРУПОВЕ ЗАНЯТТЯ',   'date': '10.01.2026', 'topic': 'Особливості проєкту в Android Studio',         'maxScore': 2.0},
  {'code': 'ПЗ 1/4', 'type': 'ПРАКТИЧНЕ ЗАНЯТТЯ', 'date': '13.01.2026', 'topic': 'Розробка мобільного додатку Калькулятор',      'maxScore': null},
  {'code': 'ГЗ 1/5', 'type': 'ГРУПОВЕ ЗАНЯТТЯ',   'date': '14.01.2026', 'topic': 'Основи Flutter',                               'maxScore': 2.0},
];

// Бали курсантів
final _mockScores = <String, List<double?>> {
  'Атабаєв Олексій':   [null, 1.75, 2.0,  null, 1.5],
  'Ващик Олександр':   [null, 1.5,  1.25, 5.5,  1.75],
  'Войтенко Андрій':   [null, 2.0,  1.5,  1.0,  1.5],
  'Гупало Ярослав':    [null, 0.75, 1.5,  4.0,  1.75],
  'Гур\'янов Михайло': [null, 1.25, 1.75, 2.0,  1.5],
  'Дмитренко Марія':   [null, 2.0,  2.0,  3.0,  1.25],
  'Дрига Микола':      [null, 1.75, 1.5,  4.0,  1.75],
  'Дубовик Владислав': [null, 1.75, 1.75, 6.0,  2.0],
};

class GradeJournalPage extends ConsumerStatefulWidget {
  final String disciplineId;
  final String? groupName;
  final String? semesterId;
  final bool readOnly;
  const GradeJournalPage({
    super.key,
    required this.disciplineId,
    this.groupName,
    this.semesterId,
    this.readOnly = false,
  });

  @override
  ConsumerState<GradeJournalPage> createState() => _GradeJournalPageState();
}

class _GradeJournalPageState extends ConsumerState<GradeJournalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late MockDiscipline? _discipline;
  late Map<String, List<double?>> _scores;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    final id = int.tryParse(widget.disciplineId) ?? 0;
    _discipline = MockDataProvider.disciplineById(id);
    // Копія для редагування
    _scores = _mockScores.map((k, v) => MapEntry(k, List<double?>.from(v)));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final disc = _discipline;
    final role = ref.watch(authViewModelProvider).role;
    final canEdit = !widget.readOnly &&
        (role == UserRole.instructor ||
         role == UserRole.departmentHead ||
         role == UserRole.superAdmin);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              disc != null
                  ? '${disc.shortName} — ${widget.groupName ?? 'Журнал'}'
                  : 'Журнал',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const Text('Електронний журнал успішності',
                style: TextStyle(fontSize: 10, color: AppTheme.textMid)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {},
            tooltip: 'Оновити',
            padding: const EdgeInsets.all(8),
          ),
          if (!widget.readOnly)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            onSelected: (v) {
              if (v == 'rpnd') _showRpndDialog(context);
              if (v == 'add') _showAddLessonDialog(context);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(children: [
                  Icon(Icons.add_circle_outline, size: 18,
                      color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text('Додати заняття'),
                ]),
              ),
              const PopupMenuItem(
                value: 'rpnd',
                child: Row(children: [
                  Icon(Icons.description_outlined, size: 18,
                      color: AppTheme.textMid),
                  SizedBox(width: 10),
                  Text('Створити з РПНД'),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMid,
              labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              tabs: [
                _TabItem(icon: Icons.bar_chart, label: 'Журнал'),
                _TabItem(icon: Icons.menu_book_outlined, label: 'Заняття'),
                _TabItem(icon: Icons.link, label: 'Посилання'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _GradesTab(
                  scores: _scores,
                  canEdit: canEdit,
                  onScoreChanged: (name, lessonIdx, newScore) {
                    setState(() => _scores[name]![lessonIdx] = newScore);
                  },
                ),
                _LessonsTab(onAdd: () => _showAddLessonDialog(context)),
                _LinksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRpndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                  child: Text('Створити заняття з РПНД',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppTheme.textDark)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 12),
              const Text(
                'Завантажте документ РПНД (Робоча програма навчальної дисципліни) у форматі DOCX. Система автоматично розпізнає модулі та заняття з таблиці.',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textDark),
              ),
              const SizedBox(height: 16),
              // Drop zone
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.border,
                      style: BorderStyle.solid,
                      width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file,
                        size: 48,
                        color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        text: 'Перетягніть файл сюди або ',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textDark),
                        children: [
                          TextSpan(
                            text: 'оберіть файл',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Підтримується: DOCX (макс. 10 МБ)',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMid)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Що буде розпізнано:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 8),
                    ...['Модулі курсу',
                      'Типи занять (лекції, практичні, лабораторні тощо)',
                      'Теми занять',
                      'Кількість годин']
                        .map((item) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 4),
                              child: Row(children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppTheme.textMid)),
                                Text(item,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textDark)),
                              ]),
                            )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF374151),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Скасувати'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.upload_file,
                        size: 16, color: Colors.white),
                    label: const Text('Завантажити'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddLessonDialog(BuildContext context) {
    String _type = 'Лекція';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                    child: Text('Додати нове заняття',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppTheme.textDark)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
                const SizedBox(height: 16),
                // Вид + Дата
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Вид заняття',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMid)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppTheme.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _type,
                            isExpanded: true,
                            underline: const SizedBox(),
                            items: ['Лекція', 'Практичне заняття',
                              'Групове заняття', 'Лабораторна робота']
                                .map((t) => DropdownMenuItem(
                                    value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => _type = v!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Дата заняття',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMid)),
                        const SizedBox(height: 6),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'дд.мм.рррр',
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                _DialogField(label: 'Номер заняття *',
                    hint: 'Введіть номер заняття: 1/1 | 2/2 | 4/3'),
                const SizedBox(height: 14),
                _DialogField(
                  label: 'Найменування заняття *',
                  hint: 'Введіть найменування заняття',
                  maxLines: 4,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: _DialogField(
                        label: 'Максимальний бал *',
                        hint: '5',
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogField(
                        label: 'Пара',
                        hint: '1',
                        keyboardType: TextInputType.number),
                  ),
                ]),
                const SizedBox(height: 14),
                _DialogField(label: 'Аудиторія',
                    hint: 'Номер аудиторії'),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Скасувати'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Створити',
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Журнал оцінок — горизонтальна таблиця ─────────────────────────────────────

class _GradesTab extends StatefulWidget {
  final Map<String, List<double?>> scores;
  final bool canEdit;
  final void Function(String cadetName, int lessonIdx, double? newScore) onScoreChanged;

  const _GradesTab({
    required this.scores,
    required this.canEdit,
    required this.onScoreChanged,
  });

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Color _scoreColor(double pct) {
    if (pct >= 75) return const Color(0xFF16A34A);
    if (pct >= 60) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Color _scoreBg(double pct) {
    if (pct >= 75) return const Color(0xFFDCFCE7);
    if (pct >= 60) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  Color _cellScoreColor(double? score, double? maxScore) {
    if (score == null) return Colors.transparent;
    if (maxScore == null) return const Color(0xFFE0F2FE);
    final pct = score / maxScore * 100;
    if (pct >= 75) return const Color(0xFFDCFCE7);
    if (pct >= 50) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  static const double _rowH   = 48.0;
  static const double _headH  = 36.0;
  static const double _dateH  = 24.0;
  static const double _fixedW = 200.0;
  static const double _colW   = 72.0;

  void _showScoreDialog(
    BuildContext context,
    String cadetName,
    int lessonIdx,
    double maxScore,
    double? currentScore,
  ) {
    final ctrl = TextEditingController(
      text: currentScore != null ? currentScore.toString() : '',
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            cadetName,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заняття ${_mockLessons[lessonIdx]['code']}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
              ),
              Text(
                'Макс. бал: $maxScore',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Оцінка',
                  hintText: '0 – $maxScore',
                  errorText: errorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  suffixText: '/ $maxScore',
                ),
                onChanged: (_) => setDialogState(() => errorText = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Скасувати'),
            ),
            if (currentScore != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onScoreChanged(cadetName, lessonIdx, null);
                },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                child: const Text('Видалити'),
              ),
            ElevatedButton(
              onPressed: () {
                final raw = ctrl.text.trim().replaceAll(',', '.');
                if (raw.isEmpty) {
                  Navigator.pop(ctx);
                  widget.onScoreChanged(cadetName, lessonIdx, null);
                  return;
                }
                final val = double.tryParse(raw);
                if (val == null || val < 0) {
                  setDialogState(() => errorText = 'Введіть число ≥ 0');
                  return;
                }
                if (val > maxScore) {
                  setDialogState(() => errorText = 'Макс. допустимий бал: $maxScore');
                  return;
                }
                Navigator.pop(ctx);
                widget.onScoreChanged(cadetName, lessonIdx, val);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cadets = widget.scores.keys.toList();
    final lessons = _mockLessons;

    return Column(
      children: [
        // ── Статистика зверху ───────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(children: [
            _StatBadge(
              label: 'Курсантів',
              value: '${cadets.length}',
              color: AppTheme.secondary,
            ),
            const SizedBox(width: 10),
            _StatBadge(
              label: 'Занять',
              value: '${lessons.length}',
              color: const Color(0xFF0284C7),
            ),
            const Spacer(),
            _LegendDot(color: const Color(0xFF16A34A), label: '≥75%'),
            const SizedBox(width: 8),
            _LegendDot(color: const Color(0xFFD97706), label: '60-74%'),
            const SizedBox(width: 8),
            _LegendDot(color: const Color(0xFFDC2626), label: '<60%'),
          ]),
        ),
        const Divider(height: 1),

        // ── Таблиця зі sticky лівою частиною ───────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Фіксована ліва частина (№, ПІБ, Бали) ───────────────
              SizedBox(
                width: _fixedW,
                child: Column(
                  children: [
                    Container(
                      height: _headH + _dateH,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          right: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: const Row(children: [
                        SizedBox(
                          width: 36,
                          child: Center(
                            child: Text('№',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMid)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('ПІБ',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMid)),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Center(
                            child: Text('Бали',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMid)),
                          ),
                        ),
                      ]),
                    ),
                    Expanded(
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        itemCount: cadets.length,
                        itemExtent: _rowH,
                        itemBuilder: (ctx, i) {
                          final name = cadets[i];
                          final cadetScores = widget.scores[name]!;
                          final total = cadetScores.fold(0.0, (s, v) => s + (v ?? 0.0));
                          final pct = (total / 20 * 100).round();
                          final isEven = i % 2 == 0;
                          return Container(
                            decoration: BoxDecoration(
                              color: isEven ? Colors.white : const Color(0xFFFAFAFA),
                              border: const Border(
                                bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                right: BorderSide(color: Color(0xFFE2E8F0), width: 2),
                              ),
                            ),
                            child: Row(children: [
                              SizedBox(
                                width: 36,
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textLight,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(name,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textDark),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1),
                                ),
                              ),
                              SizedBox(
                                width: 64,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _scoreBg(pct.toDouble()),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _scoreColor(pct.toDouble()).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${total.toStringAsFixed(1)}\n$pct%',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                            color: _scoreColor(pct.toDouble())),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ── Прокручувана права частина (заняття) ─────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: lessons.length * _colW,
                    child: Column(
                      children: [
                        SizedBox(
                          height: _headH,
                          child: Row(
                            children: lessons.map((l) {
                              return _LessonHeaderCell(lesson: l, width: _colW);
                            }).toList(),
                          ),
                        ),
                        SizedBox(
                          height: _dateH,
                          child: Row(
                            children: lessons.map((l) {
                              return Container(
                                width: _colW,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  border: Border(
                                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                    right: BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Center(
                                  child: Text(l['date'] as String,
                                      style: const TextStyle(
                                          fontSize: 9, color: AppTheme.textMid)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            itemCount: cadets.length,
                            itemExtent: _rowH,
                            itemBuilder: (ctx, i) {
                              final name = cadets[i];
                              final cadetScores = widget.scores[name]!;
                              final isEven = i % 2 == 0;
                              return Row(
                                children: lessons.asMap().entries.map((e) {
                                  final li = e.key;
                                  final lesson = e.value;
                                  final score = li < cadetScores.length
                                      ? cadetScores[li]
                                      : null;
                                  final maxScore = lesson['maxScore'] as double?;
                                  final bg = score != null
                                      ? _cellScoreColor(score, maxScore)
                                      : (isEven ? Colors.white : const Color(0xFFFAFAFA));

                                  final canTap = widget.canEdit && maxScore != null;

                                  Widget cell = Container(
                                    width: _colW,
                                    decoration: BoxDecoration(
                                      color: bg,
                                      border: const Border(
                                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                        right: BorderSide(color: Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    child: Center(
                                      child: score != null
                                          ? Text(score.toString(),
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: maxScore != null
                                                      ? _scoreColor(score / maxScore * 100)
                                                      : const Color(0xFF0284C7)))
                                          : canTap
                                              ? Icon(Icons.add,
                                                  size: 14,
                                                  color: AppTheme.textLight.withOpacity(0.4))
                                              : const Text('—',
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFFCBD5E1))),
                                    ),
                                  );

                                  if (canTap) {
                                    cell = InkWell(
                                      onTap: () => _showScoreDialog(
                                          context, name, li, maxScore, score),
                                      child: cell,
                                    );
                                  }

                                  return cell;
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textMid)),
      ]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 3),
      Text(label,
          style: const TextStyle(fontSize: 9, color: AppTheme.textMid)),
    ]);
  }
}

class _LessonHeaderCell extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final double width;
  const _LessonHeaderCell({required this.lesson, required this.width});

  Color get _bg {
    switch (lesson['type'] as String) {
      case 'ЛЕКЦІЯ':            return const Color(0xFFDBEAFE);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFFDCFCE7);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFFEF3C7);
      default:                  return AppTheme.surface;
    }
  }

  Color get _fg {
    switch (lesson['type'] as String) {
      case 'ЛЕКЦІЯ':            return const Color(0xFF1D4ED8);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFF15803D);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFB45309);
      default:                  return AppTheme.textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          bottom: BorderSide(color: _fg.withOpacity(0.2)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Center(
        child: Text(lesson['code'] as String,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _fg)),
      ),
    );
  }
}

// ── Управління заняттями ──────────────────────────────────────────────────────

class _LessonsTab extends StatelessWidget {
  final VoidCallback onAdd;
  const _LessonsTab({required this.onAdd});

  Color _typeColor(String type) {
    switch (type) {
      case 'ЛЕКЦІЯ':           return const Color(0xFF93C5FD);
      case 'ГРУПОВЕ ЗАНЯТТЯ':  return const Color(0xFF86EFAC);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ':return const Color(0xFFFDE68A);
      default:                 return AppTheme.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Заняття',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textDark)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                  'Всього: ${_mockLessons.length}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMid)),
            ),
          ]),
          const SizedBox(height: 12),
          // Заголовок таблиці
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            color: AppTheme.surface,
            child: const Row(children: [
              SizedBox(width: 90,
                  child: Text('Дата',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMid))),
              SizedBox(width: 90,
                  child: Text('Тип',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMid))),
              SizedBox(width: 50,
                  child: Text('Назва',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMid))),
              Expanded(
                  child: Text('Тема заняття',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMid))),
              SizedBox(width: 50,
                  child: Text('Макс.бал',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMid))),
              SizedBox(width: 30),
            ]),
          ),
          const Divider(height: 1),
          ..._mockLessons.map((l) => Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(children: [
                    SizedBox(
                      width: 90,
                      child: Text(l['date'] as String,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark)),
                    ),
                    SizedBox(
                      width: 90,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _typeColor(l['type'] as String),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(l['type'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(l['code'] as String,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark)),
                    ),
                    Expanded(
                      child: Text(l['topic'] as String,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        l['maxScore'] != null
                            ? '${l['maxScore']} б.'
                            : '—',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMid),
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: AppTheme.primary),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ]),
                ),
                const Divider(height: 1),
              ])),
        ],
      ),
    );
  }
}

// ── Корисні посилання ─────────────────────────────────────────────────────────

class _LinksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _LinkBadge(
              icon: Icons.folder,
              label: 'Drive',
              bg: const Color(0xFFE8F5E9),
              fg: const Color(0xFF2E7D32)),
          _LinkBadge(
              icon: Icons.videocam,
              label: 'Meet',
              bg: const Color(0xFFE3F2FD),
              fg: const Color(0xFF1565C0)),
          _LinkBadge(
              icon: Icons.school,
              label: 'Moodle',
              bg: const Color(0xFFFFF3E0),
              fg: const Color(0xFFE65100)),
          // Додати месенджер
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.link, size: 14),
            label: const Text('Додати Месенджер',
                style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMid,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  const _LinkBadge(
      {required this.icon,
      required this.label,
      required this.bg,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ]),
      ),
      IconButton(
        icon: const Icon(Icons.edit_outlined,
            size: 14, color: AppTheme.textMid),
        onPressed: () {},
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(),
      ),
    ]);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tab(
      icon: Icon(icon, size: 16),
      text: label,
      iconMargin: const EdgeInsets.only(bottom: 2),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _DialogField({
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textMid)),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
