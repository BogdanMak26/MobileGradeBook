// lib/features/grades/presentation/pages/grade_journal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local/offline_queue.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/sync_status_chip.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/grade_journal_viewmodel.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _lessonTypeKey(String type) {
  switch (type.toUpperCase()) {
    case 'LECTURE':           return 'ЛЕКЦІЯ';
    case 'GROUP_WORK':        return 'ГРУПОВЕ ЗАНЯТТЯ';
    case 'PRACTICAL_WORK':    return 'ПРАКТИЧНЕ ЗАНЯТТЯ';
    case 'LAB_WORK':
    case 'LABORATORY_WORK':   return 'ЛАБОРАТОРНА';
    case 'SEMINAR':           return 'СЕМІНАР';
    case 'EXAMINATION':       return 'ІСПИТ';
    case 'TEST_EXAMINATION':  return 'ЗАЛІК';
    default:                  return type.toUpperCase();
  }
}

String _lessonTypeLabel(String type) {
  switch (_lessonTypeKey(type)) {
    case 'ЛЕКЦІЯ':             return 'Лекція';
    case 'ГРУПОВЕ ЗАНЯТТЯ':    return 'Групове';
    case 'ПРАКТИЧНЕ ЗАНЯТТЯ':  return 'Практичне';
    case 'ЛАБОРАТОРНА':        return 'Лабораторна';
    case 'СЕМІНАР':            return 'Семінар';
    case 'ІСПИТ':              return 'Іспит';
    case 'ЗАЛІК':              return 'Залік';
    default:                   return type;
  }
}

const _lessonTypes = <String, String>{
  'LECTURE':          'Лекція',
  'PRACTICAL_WORK':   'Практичне заняття',
  'GROUP_WORK':       'Групове заняття',
  'LABORATORY_WORK':  'Лабораторна робота',
  'SEMINAR':          'Семінар',
  'EXAMINATION':      'Іспит',
  'TEST_EXAMINATION': 'Залік',
};

// "2026-01-07" → "07.01.26"
String _fmtDate(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  return '${p[2]}.${p[1]}.${p[0].substring(2)}';
}

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
  final int? journalId;
  final bool readOnly;
  const GradeJournalPage({
    super.key,
    this.disciplineId = '',
    this.disciplineShortName,
    this.groupName,
    this.semesterId,
    this.groupId,
    this.journalId,
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
  int _journalId = 0;

  double get _maxTotalScore =>
      _lessons.fold(0.0, (s, l) => s + ((l['maxScore'] as double?) ?? 0.0));

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = ref.read(gradeJournalViewModelProvider.notifier);
      if (widget.disciplineShortName != null) {
        vm.setDisciplineName(widget.disciplineShortName!);
      }
      final jId = widget.journalId;
      if (jId != null && jId != 0) {
        vm.loadJournalById(jId);
      } else if (widget.groupId != null) {
        final discId = int.tryParse(widget.disciplineId) ?? 0;
        final semId = int.tryParse(widget.semesterId ?? '') ?? 0;
        vm.loadJournal(
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
      _journalId = journal.journalId;
      _lessons = journal.lessons.map((l) => <String, dynamic>{
        'code': l.code,
        'type': l.type,
        'date': l.date,
        'topic': l.topic,
        'maxScore': l.maxScore > 0 ? l.maxScore : null,
        'id': l.id,
        'pair': l.pair,
        'room': l.room,
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

  void _triggerReload() {
    setState(() => _dataFromApi = false);
    if (widget.groupId != null) {
      final discId = int.tryParse(widget.disciplineId) ?? 0;
      final semId  = int.tryParse(widget.semesterId ?? '') ?? 0;
      ref.read(gradeJournalViewModelProvider.notifier).loadJournal(
        groupId:      widget.groupId!,
        disciplineId: discId,
        semesterId:   semId,
      );
    } else if (_journalId != 0) {
      ref.read(gradeJournalViewModelProvider.notifier).loadJournalById(_journalId);
    }
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    ref.listen<JournalState>(gradeJournalViewModelProvider, (prev, next) {
      if (!next.isLoading && next.journal != null && !_dataFromApi) _loadFromJournal(next);
      if (next.syncMessage != null && next.syncMessage != prev?.syncMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.syncMessage!), duration: const Duration(seconds: 2)));
      }
      if (next.error != null && next.error != prev?.error && _dataFromApi) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red));
      }
      if (next.offlineMessage != null && next.offlineMessage != prev?.offlineMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(next.offlineMessage!,
                style: const TextStyle(fontSize: 13))),
          ]),
          backgroundColor: const Color(0xFFF59E0B),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    // Після завершення офлайн-синхронізації — перезавантажити журнал
    ref.listen<int>(offlineQueueProvider, (prev, next) {
      if ((prev ?? 0) > 0 && next == 0 && _dataFromApi) {
        _triggerReload();
      }
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
            onPressed: () {
              if (widget.groupId != null) {
                _dataFromApi = false;
                ref.read(gradeJournalViewModelProvider.notifier).loadJournal(
                  groupId: widget.groupId!,
                  disciplineId: int.tryParse(widget.disciplineId) ?? 0,
                  semesterId: int.tryParse(widget.semesterId ?? '') ?? 0,
                );
              }
            },
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
              if (MediaQuery.of(context).orientation == Orientation.portrait)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: const Row(children: [SyncStatusChip()]),
                ),
              Container(
                color: Colors.white,
                child: Builder(builder: (ctx) {
                  final landscape = MediaQuery.of(ctx).orientation == Orientation.landscape;
                  return TabBar(
                    controller: _tab,
                    indicatorColor: AppTheme.primary,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textMid,
                    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 10),
                    tabs: landscape
                        ? const [
                            Tab(icon: Icon(Icons.bar_chart, size: 18)),
                            Tab(icon: Icon(Icons.menu_book_outlined, size: 18)),
                            Tab(icon: Icon(Icons.link, size: 18)),
                          ]
                        : const [
                            _TabItem(icon: Icons.bar_chart, label: 'Журнал'),
                            _TabItem(icon: Icons.menu_book_outlined, label: 'Заняття'),
                            _TabItem(icon: Icons.link, label: 'Посилання'),
                          ],
                  );
                }),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    journalVm.error != null && !_dataFromApi
                        ? RefreshIndicator(
                            onRefresh: () async => _triggerReload(),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 120),
                                Center(child: Text(journalVm.error!, style: const TextStyle(color: Colors.red))),
                              ],
                            ),
                          )
                        : !_dataFromApi && _lessons.isEmpty
                            ? journalVm.isLoading
                                ? const SizedBox.shrink()
                                : RefreshIndicator(
                                    onRefresh: () async => _triggerReload(),
                                    child: ListView(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      children: const [
                                        SizedBox(height: 120),
                                        Center(child: Text('Немає даних', style: TextStyle(color: AppTheme.textMid))),
                                      ],
                                    ),
                                  )
                            : _GradesTab(
                                    lessons: _lessons,
                                    maxTotalScore: _maxTotalScore,
                                    scores: _scores,
                                    attendance: _attendance,
                                    canEdit: canEdit,
                                    onScoreChanged: (name, idx, v) {
                                      setState(() => _scores[name]![idx] = v);
                                      final teacherId = int.tryParse(
                                          ref.read(authViewModelProvider).userId ?? '') ?? 0;
                                      ref.read(gradeJournalViewModelProvider.notifier).saveGrade(
                                        cadetName: name,
                                        lessonIdx: idx,
                                        value: v,
                                        teacherId: teacherId,
                                      );
                                    },
                                    onAttendanceChanged: (name, idx, code) {
                                      setState(() => _attendance[name]![idx] = code);
                                      final teacherId = int.tryParse(
                                          ref.read(authViewModelProvider).userId ?? '') ?? 0;
                                      ref.read(gradeJournalViewModelProvider.notifier).saveAttendances(
                                        attendance: _attendance,
                                        teacherId: teacherId,
                                      );
                                    },
                                  ),
                    _LessonsTab(
                      lessons: _lessons,
                      canEdit: canEdit,
                      onAdd: () => _showAddLessonDialog(context),
                      onEdit: (l) => _showEditLessonDialog(context, l),
                      onRefresh: () async => _triggerReload(),
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
    String lessonType = 'LECTURE';
    DateTime? selectedDate;
    final nameCtrl   = TextEditingController();
    final themeCtrl  = TextEditingController();
    final scoreCtrl  = TextEditingController();
    final pairCtrl   = TextEditingController();
    final roomCtrl   = TextEditingController();
    String? nameError, themeError, scoreError;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) {
          void submit() {
            bool ok = true;
            if (nameCtrl.text.trim().isEmpty)  { setDS(() => nameError  = 'Обов\'язкове'); ok = false; }
            if (themeCtrl.text.trim().isEmpty) { setDS(() => themeError = 'Обов\'язкове'); ok = false; }
            final ms = double.tryParse(scoreCtrl.text.trim());
            if (ms == null) { setDS(() => scoreError = 'Введіть число'); ok = false; }
            if (!ok) return;
            final teacherId = int.tryParse(ref.read(authViewModelProvider).userId ?? '') ?? 0;
            final date = selectedDate ?? DateTime.now();
            final dateStr = '${date.year.toString().padLeft(4, '0')}-'
                '${date.month.toString().padLeft(2, '0')}-'
                '${date.day.toString().padLeft(2, '0')}';
            final data = <String, dynamic>{
              'teacherId':    teacherId,
              'markMaxValue': ms,
              'name':         nameCtrl.text.trim(),
              'theme':        themeCtrl.text.trim(),
              'type':         lessonType,
              'lessonDate':   dateStr,
              if (pairCtrl.text.isNotEmpty && int.tryParse(pairCtrl.text) != null)
                'lessonPara': int.parse(pairCtrl.text),
              if (roomCtrl.text.isNotEmpty) 'room': roomCtrl.text.trim(),
            };
            Navigator.pop(ctx);
            ref.read(gradeJournalViewModelProvider.notifier)
                .createLesson(journalId: _journalId, data: data)
                .then((_) { if (mounted) _triggerReload(); });
          }

          return _LessonDialog(
            title: 'Додати нове заняття',
            lessonType: lessonType,
            selectedDate: selectedDate,
            nameCtrl: nameCtrl,
            themeCtrl: themeCtrl,
            scoreCtrl: scoreCtrl,
            pairCtrl: pairCtrl,
            roomCtrl: roomCtrl,
            nameError: nameError,
            themeError: themeError,
            scoreError: scoreError,
            onTypeChanged: (v) => setDS(() => lessonType = v),
            onDatePicked: (d) => setDS(() => selectedDate = d),
            onNameChanged: (_) => setDS(() => nameError = null),
            onThemeChanged: (_) => setDS(() => themeError = null),
            onScoreChanged: (_) => setDS(() => scoreError = null),
            submitLabel: 'Створити',
            onSubmit: submit,
            onCancel: () => Navigator.pop(ctx),
          );
        },
      ),
    ).then((_) {
      nameCtrl.dispose(); themeCtrl.dispose(); scoreCtrl.dispose();
      pairCtrl.dispose(); roomCtrl.dispose();
    });
  }

  void _showEditLessonDialog(BuildContext context, Map<String, dynamic> lesson) {
    final lessonId = lesson['id'] as int;
    final rawType  = lesson['type'] as String? ?? 'LECTURE';
    String lessonType = _lessonTypes.containsKey(rawType) ? rawType : 'LECTURE';
    final dateStr  = lesson['date'] as String?;
    DateTime? selectedDate = (dateStr != null && dateStr.isNotEmpty) ? DateTime.tryParse(dateStr) : null;

    final ms = lesson['maxScore'] as double?;
    final nameCtrl  = TextEditingController(text: lesson['code']  as String? ?? '');
    final themeCtrl = TextEditingController(text: lesson['topic'] as String? ?? '');
    final scoreCtrl = TextEditingController(text: ms != null
        ? (ms == ms.truncateToDouble() ? ms.toInt().toString() : ms.toString()) : '');
    final pairCtrl  = TextEditingController(text: (lesson['pair'] as int?)?.toString() ?? '');
    final roomCtrl  = TextEditingController(text: lesson['room']  as String? ?? '');
    String? nameError, themeError, scoreError;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDS) {
          void submit() {
            bool ok = true;
            if (nameCtrl.text.trim().isEmpty)  { setDS(() => nameError  = 'Обов\'язкове'); ok = false; }
            if (themeCtrl.text.trim().isEmpty) { setDS(() => themeError = 'Обов\'язкове'); ok = false; }
            final msVal = double.tryParse(scoreCtrl.text.trim());
            if (msVal == null) { setDS(() => scoreError = 'Введіть число'); ok = false; }
            if (!ok) return;
            final editDate = selectedDate ?? DateTime.now();
            final editDateStr = '${editDate.year.toString().padLeft(4, '0')}-'
                '${editDate.month.toString().padLeft(2, '0')}-'
                '${editDate.day.toString().padLeft(2, '0')}';
            final data = <String, dynamic>{
              'markMaxValue': msVal,
              'name':        nameCtrl.text.trim(),
              'theme':       themeCtrl.text.trim(),
              'type':        lessonType,
              'lessonDate':  editDateStr,
              if (pairCtrl.text.isNotEmpty && int.tryParse(pairCtrl.text) != null)
                'lessonPara': int.parse(pairCtrl.text),
              'room': roomCtrl.text.trim(),
            };
            Navigator.pop(ctx);
            ref.read(gradeJournalViewModelProvider.notifier)
                .updateLesson(lessonId: lessonId, data: data)
                .then((_) { if (mounted) _triggerReload(); });
          }

          void deleteConfirm() async {
            final ok = await showDialog<bool>(
              context: ctx,
              builder: (c) => AlertDialog(
                title: const Text('Видалити заняття?'),
                content: Text('«${lesson['code']}» буде видалено безповоротно.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Скасувати')),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Видалити'),
                  ),
                ],
              ),
            );
            if (ok == true && ctx.mounted) {
              Navigator.pop(ctx);
              ref.read(gradeJournalViewModelProvider.notifier)
                  .deleteLesson(lessonId)
                  .then((_) { if (mounted) _triggerReload(); });
            }
          }

          return _LessonDialog(
            title: 'Редагувати заняття',
            lessonType: lessonType,
            selectedDate: selectedDate,
            nameCtrl: nameCtrl,
            themeCtrl: themeCtrl,
            scoreCtrl: scoreCtrl,
            pairCtrl: pairCtrl,
            roomCtrl: roomCtrl,
            nameError: nameError,
            themeError: themeError,
            scoreError: scoreError,
            onTypeChanged: (v) => setDS(() => lessonType = v),
            onDatePicked: (d) => setDS(() => selectedDate = d),
            onNameChanged: (_) => setDS(() => nameError = null),
            onThemeChanged: (_) => setDS(() => themeError = null),
            onScoreChanged: (_) => setDS(() => scoreError = null),
            submitLabel: 'Оновити',
            onSubmit: submit,
            onCancel: () => Navigator.pop(ctx),
            onDelete: deleteConfirm,
          );
        },
      ),
    ).then((_) {
      nameCtrl.dispose(); themeCtrl.dispose(); scoreCtrl.dispose();
      pairCtrl.dispose(); roomCtrl.dispose();
    });
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
  static const double _attW   = 36.0;
  static const double _scoreW = 46.0;
  static const double _fixedW = 180.0;

  // Adaptive heights: компактніші у landscape щоб всі рядки вмістились
  bool get _compact => MediaQuery.of(context).orientation == Orientation.landscape;
  double get _headH   => _compact ? 20.0 : 36.0;
  double get _dateH   => _compact ? 13.0 : 22.0;
  double get _subH    => _compact ? 10.0 : 18.0;
  double get _rowH    => _compact ? 30.0 : 42.0;
  double get _footerH => _compact ?  0.0 : 28.0;

  double _lessonW(Map<String, dynamic> l) =>
      (l['maxScore'] as double?) != null ? _attW + _scoreW : _attW;

  double get _totalScrollW =>
      widget.lessons.fold(0.0, (s, l) => s + _lessonW(l));

  // Sum of maxScores for lessons where at least one cadet has a grade.
  double get _effectiveMaxScore {
    double sum = 0.0;
    for (int i = 0; i < widget.lessons.length; i++) {
      final maxScore = widget.lessons[i]['maxScore'] as double?;
      if (maxScore == null) continue;
      final hasAnyGrade = widget.scores.values.any(
        (scores) => i < scores.length && scores[i] != null,
      );
      if (hasAnyGrade) sum += maxScore;
    }
    return sum;
  }

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
    switch (_lessonTypeKey(l['type'] as String)) {
      case 'ЛЕКЦІЯ':            return const Color(0xFFDBEAFE);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFFDCFCE7);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFFEF3C7);
      default:                  return AppTheme.surface;
    }
  }

  Color _lessonFg(Map<String, dynamic> l) {
    switch (_lessonTypeKey(l['type'] as String)) {
      case 'ЛЕКЦІЯ':            return const Color(0xFF1D4ED8);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFF15803D);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFB45309);
      default:                  return AppTheme.textMid;
    }
  }

  String _shortName(String full) => full.trim();

  static const _ukrAlphabet = 'абвгґдеєжзиіїйклмнопрстуфхцчшщьюя';

  int _ukrCompare(String a, String b) {
    final al = a.toLowerCase();
    final bl = b.toLowerCase();
    final len = al.length < bl.length ? al.length : bl.length;
    for (int i = 0; i < len; i++) {
      final ai = _ukrAlphabet.indexOf(al[i]);
      final bi = _ukrAlphabet.indexOf(bl[i]);
      final ap = ai == -1 ? _ukrAlphabet.length + al.codeUnitAt(i) : ai;
      final bp = bi == -1 ? _ukrAlphabet.length + bl.codeUnitAt(i) : bi;
      if (ap != bp) return ap - bp;
    }
    return al.length - bl.length;
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
          content: SingleChildScrollView(
            child: Column(
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
    final cadets  = widget.scores.keys.toList()..sort(_ukrCompare);
    final lessons = widget.lessons;

    return Column(children: [
      // Stats bar — прихований у landscape щоб звільнити місце для таблиці
      if (!_compact) ...[
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
      ],

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
                      final effMax = _effectiveMaxScore;
                      final pct = effMax > 0
                          ? (total / effMax * 100).round().toDouble()
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
                              child: Builder(builder: (_) {
                                final parts = name.trim().split(' ');
                                final surname = parts.isNotEmpty ? parts[0] : name;
                                final initials = parts.length > 1
                                    ? parts.skip(1).where((p) => p.isNotEmpty).join(' ')
                                    : '';
                                if (_compact) {
                                  return Text(
                                    initials.isNotEmpty ? '$surname $initials' : surname,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                    overflow: TextOverflow.ellipsis, maxLines: 1,
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(surname,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                        overflow: TextOverflow.ellipsis, maxLines: 1),
                                    if (initials.isNotEmpty)
                                      Text(initials,
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textMid)),
                                  ],
                                );
                              }),
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
                // ── Max score footer (left) ────────────────────────────────
                Container(
                  height: _footerH,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    border: Border(
                      top:   BorderSide(color: Color(0xFFE2E8F0), width: 2),
                      right: BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    ),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 28),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('Макс. бал',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMid)),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Center(
                        child: Text(
                          _effectiveMaxScore == _effectiveMaxScore.truncateToDouble()
                              ? _effectiveMaxScore.toInt().toString()
                              : _effectiveMaxScore.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMid),
                        ),
                      ),
                    ),
                  ]),
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
                              child: Text(_fmtDate(l['date'] as String),
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
                        itemBuilder: (_, i) {
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
                                      : const SizedBox.shrink(),
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
                    // ── Max score footer (right) ───────────────────────────
                    SizedBox(
                      height: _footerH,
                      child: Row(
                        children: lessons.map((l) {
                          final maxScore = l['maxScore'] as double?;
                          final hasScore = maxScore != null;
                          final bg = _lessonBg(l).withOpacity(0.3);
                          final fg = _lessonFg(l);
                          const topBorder = Border(
                            top:   BorderSide(color: Color(0xFFE2E8F0), width: 2),
                            right: BorderSide(color: Color(0xFFE2E8F0)),
                          );

                          final attCell = Container(
                            width: _attW,
                            decoration: BoxDecoration(color: bg, border: topBorder),
                          );

                          if (!hasScore) return attCell;

                          final label = maxScore == maxScore.truncateToDouble()
                              ? maxScore.toInt().toString()
                              : maxScore.toStringAsFixed(1);

                          return Row(children: [
                            attCell,
                            Container(
                              width: _scoreW,
                              decoration: BoxDecoration(color: bg, border: topBorder),
                              child: Center(
                                child: Text(label,
                                    style: TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
                              ),
                            ),
                          ]);
                        }).toList(),
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
  final bool canEdit;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>) onEdit;
  final Future<void> Function()? onRefresh;
  const _LessonsTab({
    required this.lessons,
    required this.canEdit,
    required this.onAdd,
    required this.onEdit,
    this.onRefresh,
  });

  Color _typeBg(String type) {
    switch (_lessonTypeKey(type)) {
      case 'ЛЕКЦІЯ':            return const Color(0xFFDBEAFE);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFFDCFCE7);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFFEF3C7);
      default:                  return AppTheme.surface;
    }
  }

  Color _typeFg(String type) {
    switch (_lessonTypeKey(type)) {
      case 'ЛЕКЦІЯ':            return const Color(0xFF1D4ED8);
      case 'ГРУПОВЕ ЗАНЯТТЯ':   return const Color(0xFF15803D);
      case 'ПРАКТИЧНЕ ЗАНЯТТЯ': return const Color(0xFFB45309);
      default:                  return AppTheme.textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listView = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
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
              if (canEdit) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Додати', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ]),
          );
        }

        final l = lessons[i - 1];
        final type = l['type'] as String;
        final date = _fmtDate(l['date'] as String);
        final code = l['code'] as String;
        final topic = l['topic'] as String;
        final maxScore = l['maxScore'] as double?;
        final bg  = _typeBg(type);
        final fg  = _typeFg(type);
        final lbl = _lessonTypeLabel(type);
        final scoreText = (maxScore != null && maxScore > 0)
            ? '${maxScore == maxScore.truncateToDouble() ? maxScore.toInt() : maxScore} б.'
            : '—';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: fg),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(lbl,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(code,
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(
                                    topic.isNotEmpty ? topic : '—',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.4),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(date,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(scoreText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: (maxScore != null && maxScore > 0)
                                              ? AppTheme.primary
                                              : AppTheme.textLight,
                                        )),
                                    if (canEdit) ...[
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () => onEdit(l),
                                        child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textMid),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: listView);
    }
    return listView;
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

class _CtrlField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController ctrl;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? error;
  final void Function(String)? onChanged;
  const _CtrlField({
    required this.label, required this.hint, required this.ctrl,
    this.maxLines = 1, this.keyboardType, this.error, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _LessonDialog extends StatelessWidget {
  final String title;
  final String lessonType;
  final DateTime? selectedDate;
  final TextEditingController nameCtrl, themeCtrl, scoreCtrl, pairCtrl, roomCtrl;
  final String? nameError, themeError, scoreError;
  final void Function(String) onTypeChanged;
  final void Function(DateTime) onDatePicked;
  final void Function(String) onNameChanged, onThemeChanged, onScoreChanged;
  final String submitLabel;
  final VoidCallback onSubmit, onCancel;
  final VoidCallback? onDelete;

  const _LessonDialog({
    required this.title, required this.lessonType, required this.selectedDate,
    required this.nameCtrl, required this.themeCtrl, required this.scoreCtrl,
    required this.pairCtrl, required this.roomCtrl,
    this.nameError, this.themeError, this.scoreError,
    required this.onTypeChanged, required this.onDatePicked,
    required this.onNameChanged, required this.onThemeChanged, required this.onScoreChanged,
    required this.submitLabel, required this.onSubmit, required this.onCancel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = selectedDate != null
        ? '${selectedDate!.day.toString().padLeft(2, '0')}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.year}'
        : 'дд.мм.рррр';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark))),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: onCancel,
                  padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
            const SizedBox(height: 16),
            // Type + Date
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Вид заняття', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<String>(
                      value: lessonType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: _lessonTypes.entries
                          .map((e) => DropdownMenuItem(value: e.key,
                              child: Text(e.value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => onTypeChanged(v!),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Дата заняття', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (d != null) onDatePicked(d);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Expanded(child: Text(dateLabel,
                            style: TextStyle(fontSize: 13,
                                color: selectedDate != null ? AppTheme.textDark : AppTheme.textLight))),
                        const Icon(Icons.calendar_today, size: 14, color: AppTheme.textMid),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            _CtrlField(label: 'Номер заняття *', hint: '1/1', ctrl: nameCtrl,
                error: nameError, onChanged: onNameChanged),
            const SizedBox(height: 14),
            _CtrlField(label: 'Найменування заняття *', hint: 'Тема заняття',
                ctrl: themeCtrl, maxLines: 3, error: themeError, onChanged: onThemeChanged),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _CtrlField(
                label: 'Максимальний бал *', hint: '5', ctrl: scoreCtrl,
                keyboardType: TextInputType.number, error: scoreError, onChanged: onScoreChanged,
              )),
              const SizedBox(width: 12),
              Expanded(child: _CtrlField(
                label: 'Пара (1–4)', hint: '1', ctrl: pairCtrl,
                keyboardType: TextInputType.number,
              )),
            ]),
            const SizedBox(height: 14),
            _CtrlField(label: 'Аудиторія', hint: 'Номер аудиторії', ctrl: roomCtrl),
            const SizedBox(height: 20),
            // Buttons
            Row(children: [
              if (onDelete != null)
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Видалити'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              if (onDelete != null) const Spacer(),
              if (onDelete == null) const Spacer(),
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Скасувати'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(submitLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
