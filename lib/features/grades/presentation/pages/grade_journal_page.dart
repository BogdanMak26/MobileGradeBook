// lib/features/grades/presentation/pages/grade_journal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../shared/theme/app_theme.dart';

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

double _total(List<double?> scores) =>
    scores.fold(0.0, (sum, s) => sum + (s ?? 0.0));

class GradeJournalPage extends ConsumerStatefulWidget {
  final String disciplineId;
  final String? groupName;
  final String? semesterId;
  const GradeJournalPage({
    super.key,
    required this.disciplineId,
    this.groupName,
    this.semesterId,
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

  Color _scoreColor(double total) {
    final pct = total / 20 * 100;
    if (pct >= 75) return const Color(0xFF4ADE80);
    if (pct >= 60) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    final disc = _discipline;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              disc != null
                  ? '${disc.shortName} - ${widget.groupName ?? 'Журнал'}'
                  : 'Журнал',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text('Електронний журнал успішності',
                style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
          ],
        ),
        // Прогрес-бар зверху (зелений)
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
          // Оновити
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh, size: 16,
                color: AppTheme.textMid),
            label: const Text('Оновити',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textMid)),
          ),
          // Створити з РПНД
          OutlinedButton.icon(
            onPressed: () => _showRpndDialog(context),
            icon: const Icon(Icons.description_outlined,
                size: 14, color: AppTheme.textMid),
            label: const Text('Створити з РПНД',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textMid)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppTheme.border),
            ),
          ),
          const SizedBox(width: 6),
          // + Додати заняття
          ElevatedButton.icon(
            onPressed: () => _showAddLessonDialog(context),
            icon: const Icon(Icons.add, size: 14,
                color: Colors.white),
            label: const Text('Додати заняття',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 8),
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
                _GradesTab(scores: _scores),
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

class _GradesTab extends StatelessWidget {
  final Map<String, List<double?>> scores;
  const _GradesTab({required this.scores});

  Color _scoreColor(double total) {
    final pct = total / 20 * 100;
    if (pct >= 75) return const Color(0xFF4ADE80);
    if (pct >= 60) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }

  @override
  Widget build(BuildContext context) {
    final cadets = scores.keys.toList();
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: AppTheme.border, width: 0.5),
          defaultColumnWidth: const FixedColumnWidth(70),
          columnWidths: const {
            0: FixedColumnWidth(36),
            1: FixedColumnWidth(160),
            2: FixedColumnWidth(80),
          },
          children: [
            // Header row 1 — коди занять
            TableRow(
              decoration: BoxDecoration(color: AppTheme.surface),
              children: [
                _HCell('№'),
                _HCell('ПІБ'),
                _HCell('бали'),
                ..._mockLessons.map((l) => _LessonHeader(l)),
              ],
            ),
            // Header row 2 — дати
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _HCell(''),
                _HCell(''),
                _HCell(''),
                ..._mockLessons.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 2),
                      child: Text(l['date'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textMid)),
                    )),
              ],
            ),
            // Data rows
            ...cadets.asMap().entries.map((entry) {
              final i = entry.key;
              final name = entry.value;
              final cadetScores = scores[name]!;
              final total = cadetScores.fold(
                  0.0, (sum, s) => sum + (s ?? 0.0));
              final pct = (total / 20 * 100).round();
              return TableRow(
                children: [
                  // №
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text('${i + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMid)),
                  ),
                  // ПІБ
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: Text(name,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textDark)),
                  ),
                  // Бали
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: _scoreColor(total),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$total ($pct%)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  // Оцінки по заняттях
                  ...cadetScores.map((s) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          s != null ? s.toString() : '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark),
                        ),
                      )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const _LessonHeader(this.lesson);

  Color get _color {
    switch (lesson['type'] as String) {
      case 'ЛЕКЦІЯ':           return const Color(0xFF93C5FD);
      case 'ГРУПОВЕ ЗАНЯТТЯ':  return const Color(0xFF86EFAC);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ':return const Color(0xFFFDE68A);
      default:                 return AppTheme.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(lesson['code'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

Widget _HCell(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMid)),
    );

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
