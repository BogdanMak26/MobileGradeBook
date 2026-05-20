// lib/features/grades/presentation/pages/grade_journal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/grade_journal_viewmodel.dart';

// Attendance options matching the reference app
const _attOptions = [
  {'code': 'П',  'label': 'Присутній',              'hint': ''},
  {'code': 'Н',  'label': 'Наряд',                  'hint': '(Н)'},
  {'code': 'Зв', 'label': 'Звільнення',             'hint': '(Зв)'},
  {'code': 'К',  'label': 'Відрядження',            'hint': '(К)'},
  {'code': 'ІЗ', 'label': 'Індивідуальні заняття',  'hint': '(ІЗ)'},
  {'code': 'В',  'label': 'Відпустка',              'hint': '(В)'},
  {'code': 'Хв', 'label': 'Хворий',                 'hint': '(Хв)'},
  {'code': 'Х',  'label': 'Не з\'явився',           'hint': '(Х)'},
];

// ── Page ──────────────────────────────────────────────────────────────────────

class GradeJournalPage extends ConsumerStatefulWidget {
  final String disciplineId;
  final String? disciplineShortName;
  final String? groupName;
  final String? semesterId;
  final int? groupId;
  final bool readOnly;
  const GradeJournalPage({
    super.key,
    this.disciplineId = '',
    this.disciplineShortName,
    this.groupName,
    this.semesterId,
    this.groupId,
    this.readOnly = false,
  });

  @override
  ConsumerState<GradeJournalPage> createState() => _GradeJournalPageState();
}

class _GradeJournalPageState extends ConsumerState<GradeJournalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _lessons = const [];
  Map<String, List<double?>> _scores = const {};
  Map<String, List<String?>> _attendance = const {};
  bool _dataFromApi = false;

  double get _maxTotalScore =>
      _lessons.fold(0.0, (s, l) => s + ((l['maxScore'] as double?) ?? 0.0));

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.groupId != null) {
        final discId = int.tryParse(widget.disciplineId) ?? 0;
        final semId = int.tryParse(widget.semesterId ?? '') ?? 0;
        ref.read(gradeJournalViewModelProvider.notifier).loadJournal(
          groupId: widget.groupId!,
          disciplineId: discId,
          semesterId: semId,
        );
      }
    });
  }

  void _loadFromJournal(JournalState s) {
    final journal = s.journal;
    if (journal == null || _dataFromApi) return;
    setState(() {
      _dataFromApi = true;
      _lessons = journal.lessons.map((l) => <String, dynamic>{
        'code': l.code,
        'type': l.type,
        'date': l.date,
        'topic': l.topic,
        'maxScore': l.maxScore > 0 ? l.maxScore : null,
        'id': l.id,
      }).toList();
      _scores = {
        for (final c in journal.cadets)
          c.fullName: journal.lessons
              .map((l) => c.gradesByLessonId[l.id])
              .toList()
      };
      _attendance = {
        for (final c in journal.cadets)
          c.fullName: journal.lessons
              .map((l) => c.statusByLessonId[l.id])
              .toList()
      };
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.listen<JournalState>(gradeJournalViewModelProvider, (_, next) {
      if (!next.isLoading && next.journal != null && !_dataFromApi) _loadFromJournal(next);
    });

    final journalVm = ref.watch(gradeJournalViewModelProvider);
    final role = ref.watch(authViewModelProvider).role;
    final canEdit = !widget.readOnly &&
        (role == UserRole.instructor ||
         role == UserRole.departmentHead ||
         role == UserRole.superAdmin);
    final prefix = widget.disciplineShortName ?? widget.disciplineId;
    final title = widget.groupName != null
        ? '$prefix — ${widget.groupName}'
        : 'Журнал';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
                  colors: [Color(0xFF4ADE80), Color(0xFF16A34A)]),
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
                if (v == 'add')  _showAddLessonDialog(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'add',
                  child: Row(children: [
                    Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text('Додати заняття'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'rpnd',
                  child: Row(children: [
                    Icon(Icons.description_outlined, size: 18, color: AppTheme.textMid),
                    SizedBox(width: 10),
                    Text('Створити з РПНД'),
                  ]),
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tab,
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textMid,
                  labelStyle: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 10),
                  tabs: [
                    _TabItem(icon: Icons.bar_chart, label: 'Журнал'),
                    _TabItem(
                        icon: Icons.menu_book_outlined, label: 'Заняття'),
                    _TabItem(icon: Icons.link, label: 'Посилання'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    journalVm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : journalVm.error != null && !_dataFromApi
                            ? Center(child: Text(journalVm.error!, style: const TextStyle(color: Colors.red)))
                            : !_dataFromApi && _lessons.isEmpty
                                ? const Center(child: Text('Немає даних', style: TextStyle(color: AppTheme.textMid)))
                                : _GradesTab(
                                    lessons: _lessons,
                                    maxTotalScore: _maxTotalScore,
                                    scores: _scores,
                                    attendance: _attendance,
                                    canEdit: canEdit,
                                    onScoreChanged: (name, idx, v) =>
                                        setState(() => _scores[name]![idx] = v),
                                    onAttendanceChanged: (name, idx, code) =>
                                        setState(() => _attendance[name]![idx] = code),
                                  ),
                    _LessonsTab(
                      lessons: _lessons,
                      onAdd: () => _showAddLessonDialog(context),
                    ),
                    _LinksTab(),
                  ],
                ),
              ),
            ],
          ),
          if (journalVm.isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  // ── dialogs (unchanged) ────────────────────────────────────────────────────

  void _showRpndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark)),
                ),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 12),
              const Text(
                'Завантажте документ РПНД (Робоча програма навчальної дисципліни) у форматі DOCX. Система автоматично розпізнає модулі та заняття з таблиці.',
                style: TextStyle(fontSize: 13, color: AppTheme.textDark),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1.5),
                ),
                child: Column(children: [
                  Icon(Icons.upload_file, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: 'Перетягніть файл сюди або ',
                      style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                      children: [
                        TextSpan(text: 'оберіть файл',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Підтримується: DOCX (макс. 10 МБ)',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF374151),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Скасувати'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.upload_file, size: 16, color: Colors.white),
                    label: const Text('Завантажити'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
    String lessonType = 'Лекція';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(
                    child: Text('Додати нове заняття',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark)),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Вид заняття', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<String>(
                          value: lessonType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['Лекція', 'Практичне заняття', 'Групове заняття', 'Лабораторна робота']
                              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setDialogState(() => lessonType = v!),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Дата заняття', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                      const SizedBox(height: 6),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'дд.мм.рррр',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                _DialogField(label: 'Номер заняття *', hint: 'Введіть номер заняття: 1/1 | 2/2 | 4/3'),
                const SizedBox(height: 14),
                _DialogField(label: 'Найменування заняття *', hint: 'Введіть найменування заняття', maxLines: 4),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _DialogField(label: 'Максимальний бал *', hint: '5', keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _DialogField(label: 'Пара', hint: '1', keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 14),
                _DialogField(label: 'Аудиторія', hint: 'Номер аудиторії'),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Створити', style: TextStyle(fontWeight: FontWeight.w600)),
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

// ── Grades tab ────────────────────────────────────────────────────────────────

class _GradesTab extends StatefulWidget {
  final List<Map<String, dynamic>> lessons;
  final double maxTotalScore;
  final Map<String, List<double?>> scores;
  final Map<String, List<String?>> attendance;
  final bool canEdit;
  final void Function(String name, int idx, double? score) onScoreChanged;
  final void Function(String name, int idx, String? code) onAttendanceChanged;

  const _GradesTab({
    required this.lessons,
    required this.maxTotalScore,
    required this.scores,
    required this.attendance,
    required this.canEdit,
    required this.onScoreChanged,
    required this.onAttendanceChanged,
  });

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  final _hCtrl     = ScrollController(); // horizontal
  final _vertLeft  = ScrollController(); // left list vertical
  final _vertRight = ScrollController(); // right list vertical
  bool _syncing = false;

  // Layout constants
  static const double _attW   = 36.0;  // attendance sub-column
  static const double _scoreW = 46.0;  // score sub-column
  static const double _headH  = 36.0;  // lesson code header row
  static const double _dateH  = 22.0;  // date row
  static const double _subH   = 18.0;  // sub-label row (Пр | Бал)
  static const double _rowH   = 42.0;  // data row
  static const double _fixedW = 160.0;

  double _lessonW(Map<String, dynamic> l) =>
      (l['maxScore'] as double?) != null ? _attW + _scoreW : _attW;

  double get _totalScrollW =>
      widget.lessons.fold(0.0, (s, l) => s + _lessonW(l));

  @override
  void initState() {
    super.initState();
    _vertLeft.addListener(() {
      if (_syncing) return;
      _syncing = true;
      _vertRight.jumpTo(_vertLeft.offset);
      _syncing = false;
    });
    _vertRight.addListener(() {
      if (_syncing) return;
      _syncing = true;
      _vertLeft.jumpTo(_vertRight.offset);
      _syncing = false;
    });
  }

  @override
  void dispose() {
    _hCtrl.dispose();
    _vertLeft.dispose();
    _vertRight.dispose();
    super.dispose();
  }

  // ── Colour helpers ─────────────────────────────────────────────────────────

  Color _totalColor(double pct) {
    if (pct >= 75) return const Color(0xFF16A34A);
    if (pct >= 60) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Color _totalBg(double pct) {
    if (pct >= 75) return const Color(0xFFDCFCE7);
    if (pct >= 60) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  Color _attCellBg(String? code) {
    if (code == 'Х')  return const Color(0xFFFEE2E2);
    if (code != null && code != 'П') return const Color(0xFFFFF7ED);
    return Colors.transparent;
  }

  Color _attCellFg(String? code) {
    if (code == 'Х')  return const Color(0xFFDC2626);
    if (code != null && code != 'П') return const Color(0xFFD97706);
    return Colors.transparent;
  }

  Color _scoreCellFg(double score, double max) {
    final pct = score / max * 100;
    if (pct >= 75) return const Color(0xFF16A34A);
    if (pct >= 50) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  // ── Lesson type colours (for header chip) ─────────────────────────────────

  Color _lessonBg(Map<String, dynamic> l) {
    switch (l['type'] as String) {
      case 'ЛЕКЦІЯ':            return const Color(0xFFDBEAFE);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFFDCFCE7);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFFEF3C7);
      default:                  return AppTheme.surface;
    }
  }

  Color _lessonFg(Map<String, dynamic> l) {
    switch (l['type'] as String) {
      case 'ЛЕКЦІЯ':            return const Color(0xFF1D4ED8);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFF15803D);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFB45309);
      default:                  return AppTheme.textMid;
    }
  }

  String _shortName(String full) {
    final p = full.trim().split(' ');
    return p.length < 2 ? full : '${p[0]} ${p[1][0]}.';
  }

  // ── Score format ───────────────────────────────────────────────────────────

  String _fmtScore(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  // ── Attendance bottom-sheet ────────────────────────────────────────────────

  void _showAttendanceSheet(BuildContext context, String name, int lessonIdx, String? current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(children: [
                Text(_shortName(name),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border)),
                  child: Text(widget.lessons[lessonIdx]['code'] as String,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                ),
              ]),
            ),
            const Divider(height: 1),
            ..._attOptions.map((opt) {
              final code = opt['code'] as String;
              final hint = opt['hint'] as String;
              final isSelected = current == code;
              return ListTile(
                dense: true,
                title: Text(opt['label'] as String,
                    style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppTheme.primary : AppTheme.textDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                trailing: hint.isNotEmpty
                    ? Text(hint, style: const TextStyle(fontSize: 13, color: AppTheme.textMid))
                    : (isSelected ? const Icon(Icons.check, size: 18, color: AppTheme.primary) : null),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onAttendanceChanged(name, lessonIdx, code);
                },
              );
            }),
            ListTile(
              dense: true,
              title: const Text('Не відмічено',
                  style: TextStyle(fontSize: 14, color: AppTheme.textLight)),
              trailing: current == null
                  ? const Icon(Icons.check, size: 18, color: AppTheme.textLight)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                widget.onAttendanceChanged(name, lessonIdx, null);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Score dialog ───────────────────────────────────────────────────────────

  void _showScoreDialog(BuildContext context, String name, int lessonIdx,
      double maxScore, double? currentScore) {
    final ctrl = TextEditingController(
        text: currentScore != null ? _fmtScore(currentScore) : '');
    String? errorText;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(_shortName(name),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.lessons[lessonIdx]['code']} · Макс: $maxScore',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
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
                onChanged: (_) => setDS(() => errorText = null),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
            if (currentScore != null)
              TextButton(
                onPressed: () { Navigator.pop(ctx); widget.onScoreChanged(name, lessonIdx, null); },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                child: const Text('Видалити'),
              ),
            ElevatedButton(
              onPressed: () {
                final raw = ctrl.text.trim().replaceAll(',', '.');
                if (raw.isEmpty) { Navigator.pop(ctx); widget.onScoreChanged(name, lessonIdx, null); return; }
                final val = double.tryParse(raw);
                if (val == null || val < 0) { setDS(() => errorText = 'Введіть число ≥ 0'); return; }
                if (val > maxScore) { setDS(() => errorText = 'Макс. $maxScore'); return; }
                Navigator.pop(ctx);
                widget.onScoreChanged(name, lessonIdx, val);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cadets  = widget.scores.keys.toList();
    final lessons = widget.lessons;

    return Column(children: [
      // Stats bar
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _StatBadge(label: 'Курсантів', value: '${cadets.length}', color: AppTheme.secondary),
          const SizedBox(width: 10),
          _StatBadge(label: 'Занять', value: '${lessons.length}', color: const Color(0xFF0284C7)),
          const Spacer(),
          _LegendDot(color: const Color(0xFF16A34A), label: '≥75%'),
          const SizedBox(width: 8),
          _LegendDot(color: const Color(0xFFD97706), label: '60-74%'),
          const SizedBox(width: 8),
          _LegendDot(color: const Color(0xFFDC2626), label: '<60%'),
        ]),
      ),
      const Divider(height: 1),

      // Table
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed left: №, ПІБ, Бали ──────────────────────────────────
            SizedBox(
              width: _fixedW,
              child: Column(children: [
                // Header matching right 3-row header
                Container(
                  height: _headH + _dateH + _subH,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      right: BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    ),
                  ),
                  child: const Row(children: [
                    SizedBox(
                      width: 28,
                      child: Center(child: Text('№',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid))),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('ПІБ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid)),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Center(child: Text('Бали',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid))),
                    ),
                  ]),
                ),
                // Data rows
                Expanded(
                  child: ListView.builder(
                    controller: _vertLeft,
                    physics: const ClampingScrollPhysics(),
                    itemCount: cadets.length,
                    itemExtent: _rowH,
                    itemBuilder: (_, i) {
                      final name = cadets[i];
                      final cadetScores = widget.scores[name]!;
                      final total = cadetScores.fold(0.0, (s, v) => s + (v ?? 0.0));
                      final pct = widget.maxTotalScore > 0
                          ? (total / widget.maxTotalScore * 100).round().toDouble()
                          : 0.0;
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
                            width: 28,
                            child: Center(child: Text('${i + 1}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w600))),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(_shortName(name),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textDark),
                                  overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                          ),
                          SizedBox(
                            width: 52,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _totalBg(pct),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: _totalColor(pct).withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text(
                                    '${total.toStringAsFixed(1)}\n${pct.toInt()}%',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, height: 1.3,
                                        color: _totalColor(pct)),
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
              ]),
            ),

            // ── Scrollable right: lessons ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _hCtrl,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _totalScrollW,
                  child: Column(children: [
                    // Row 1: lesson code chips
                    SizedBox(
                      height: _headH,
                      child: Row(
                        children: lessons.map((l) => _buildLessonCodeCell(l)).toList(),
                      ),
                    ),
                    // Row 2: dates
                    SizedBox(
                      height: _dateH,
                      child: Row(
                        children: lessons.map((l) {
                          return Container(
                            width: _lessonW(l),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                right: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Center(
                              child: Text(l['date'] as String,
                                  style: const TextStyle(fontSize: 9, color: AppTheme.textMid)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Row 3: sub-labels (Пр | Бал)
                    SizedBox(
                      height: _subH,
                      child: Row(
                        children: lessons.map((l) {
                          final hasScore = (l['maxScore'] as double?) != null;
                          final fg = _lessonFg(l);
                          if (!hasScore) {
                            return Container(
                              width: _attW,
                              decoration: BoxDecoration(
                                color: _lessonBg(l).withOpacity(0.4),
                                border: const Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                  right: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Center(child: Text('Пр',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg))),
                            );
                          }
                          return Row(children: [
                            Container(
                              width: _attW,
                              decoration: BoxDecoration(
                                color: _lessonBg(l).withOpacity(0.4),
                                border: const Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                  right: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Center(child: Text('Пр',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg))),
                            ),
                            Container(
                              width: _scoreW,
                              decoration: BoxDecoration(
                                color: _lessonBg(l).withOpacity(0.4),
                                border: const Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                  right: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Center(child: Text('Бал',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: fg))),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                    // Data rows
                    Expanded(
                      child: ListView.builder(
                        controller: _vertRight,
                        physics: const ClampingScrollPhysics(),
                        itemCount: cadets.length,
                        itemExtent: _rowH,
                        itemBuilder: (ctx, i) {
                          final name = cadets[i];
                          final cadetScores = widget.scores[name]!;
                          final cadetAtt    = widget.attendance[name]!;
                          final isEven = i % 2 == 0;
                          final rowBg = isEven ? Colors.white : const Color(0xFFFAFAFA);

                          return Row(
                            children: lessons.asMap().entries.map((e) {
                              final li     = e.key;
                              final lesson = e.value;
                              final maxScore = lesson['maxScore'] as double?;
                              final attCode  = li < cadetAtt.length ? cadetAtt[li] : null;
                              final score    = li < cadetScores.length ? cadetScores[li] : null;
                              final hasScore = maxScore != null;

                              // Attendance cell
                              final attBg = _attCellBg(attCode);
                              final attFg = _attCellFg(attCode);
                              final attText = (attCode == null || attCode == 'П') ? '' : attCode;

                              Widget attCell = Container(
                                width: _attW,
                                height: _rowH,
                                decoration: BoxDecoration(
                                  color: attBg == Colors.transparent ? rowBg : attBg,
                                  border: Border(
                                    bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                                    right: BorderSide(
                                        color: const Color(0xFFE2E8F0),
                                        width: hasScore ? 0.5 : 1.0),
                                  ),
                                ),
                                child: attText.isEmpty
                                    ? const SizedBox.shrink()
                                    : Center(
                                        child: Text(attText,
                                            style: TextStyle(fontSize: 11,
                                                fontWeight: FontWeight.w700, color: attFg)),
                                      ),
                              );

                              if (widget.canEdit) {
                                attCell = GestureDetector(
                                  onTap: () => _showAttendanceSheet(context, name, li, attCode),
                                  child: attCell,
                                );
                              }

                              if (!hasScore) return attCell;

                              // Score cell (only for non-lecture lessons)
                              final scoreFg = score != null
                                  ? _scoreCellFg(score, maxScore)
                                  : AppTheme.textLight;

                              Widget scoreCell = Container(
                                width: _scoreW,
                                height: _rowH,
                                decoration: BoxDecoration(
                                  color: rowBg,
                                  border: const Border(
                                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                    right: BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Center(
                                  child: score != null
                                      ? Text(_fmtScore(score),
                                          style: TextStyle(fontSize: 13,
                                              fontWeight: FontWeight.w600, color: scoreFg))
                                      : widget.canEdit
                                          ? Icon(Icons.add, size: 12,
                                              color: Colors.grey.shade300)
                                          : const Text('—',
                                              style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
                                ),
                              );

                              if (widget.canEdit) {
                                scoreCell = GestureDetector(
                                  onTap: () => _showScoreDialog(context, name, li, maxScore, score),
                                  child: scoreCell,
                                );
                              }

                              return Row(children: [attCell, scoreCell]);
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildLessonCodeCell(Map<String, dynamic> l) {
    final bg = _lessonBg(l);
    final fg = _lessonFg(l);
    return Container(
      width: _lessonW(l),
      height: _headH,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: fg.withOpacity(0.15)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Center(
        child: Text(l['code'] as String,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

// ── Stat badge ────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});

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
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
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
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMid)),
    ]);
  }
}

// ── Lessons tab ───────────────────────────────────────────────────────────────

class _LessonsTab extends StatelessWidget {
  final List<Map<String, dynamic>> lessons;
  final VoidCallback onAdd;
  const _LessonsTab({required this.lessons, required this.onAdd});

  Color _typeColor(String type) {
    switch (type) {
      case 'ЛЕКЦІЯ':            return const Color(0xFF93C5FD);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFF86EFAC);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFFDE68A);
      default:                  return AppTheme.border;
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.surface, borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border)),
              child: Text('Всього: ${lessons.length}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppTheme.surface,
            child: const Row(children: [
              SizedBox(width: 90, child: Text('Дата', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid))),
              SizedBox(width: 90, child: Text('Тип',  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid))),
              SizedBox(width: 50, child: Text('Назва',style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid))),
              Expanded(child: Text('Тема заняття',   style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid))),
              SizedBox(width: 50, child: Text('Макс.бал', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid))),
              SizedBox(width: 30),
            ]),
          ),
          const Divider(height: 1),
          ...lessons.map((l) => Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                SizedBox(width: 90, child: Text(l['date'] as String,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
                SizedBox(
                  width: 90,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: _typeColor(l['type'] as String), borderRadius: BorderRadius.circular(4)),
                    child: Text(l['type'] as String, textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 50, child: Text(l['code'] as String,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
                Expanded(child: Text(l['topic'] as String,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                    overflow: TextOverflow.ellipsis)),
                SizedBox(
                  width: 50,
                  child: Text(
                    l['maxScore'] != null ? '${l['maxScore']} б.' : '—',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMid),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
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

// ── Links tab ─────────────────────────────────────────────────────────────────

class _LinksTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _LinkBadge(icon: Icons.folder,  label: 'Drive',  bg: const Color(0xFFE8F5E9), fg: const Color(0xFF2E7D32)),
          _LinkBadge(icon: Icons.videocam,label: 'Meet',   bg: const Color(0xFFE3F2FD), fg: const Color(0xFF1565C0)),
          _LinkBadge(icon: Icons.school,  label: 'Moodle', bg: const Color(0xFFFFF3E0), fg: const Color(0xFFE65100)),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.link, size: 14),
            label: const Text('Додати Месенджер', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textMid,
              side: const BorderSide(color: AppTheme.border),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  const _LinkBadge({required this.icon, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fg.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w500, fontSize: 13)),
        ]),
      ),
      IconButton(
        icon: const Icon(Icons.edit_outlined, size: 14, color: AppTheme.textMid),
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
    return Tab(icon: Icon(icon, size: 16), text: label, iconMargin: const EdgeInsets.only(bottom: 2));
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _DialogField({required this.label, required this.hint, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
