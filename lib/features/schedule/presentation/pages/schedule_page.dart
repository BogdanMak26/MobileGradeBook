// lib/features/schedule/presentation/pages/schedule_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

// ── Lesson type display helpers ────────────────────────────────────────────────


const _typeBg = <String, Color>{
  'LECTURE': Color(0xFFDBEAFE),
  'GROUP_WORK': Color(0xFFFEF3C7),
  'GROUP_EXERCISE': Color(0xFFFEF3C7),
  'PRACTICAL_WORK': Color(0xFFDCFCE7),
  'SEMINAR': Color(0xFFEDE9FE),
  'LABORATORY_WORK': Color(0xFFDCFCE7),
  'TEST_EXAMINATION': Color(0xFFFFEDD5),
  'EXAMINATION': Color(0xFFFFEDD5),
  'SELF_STUDY': Color(0xFFF3F4F6),
  'CONSULTATION': Color(0xFFDBEAFE),
  'MODULE_TEST': Color(0xFFFFEDD5),
  'OTHER': Color(0xFFF3F4F6),
};

const _typeFg = <String, Color>{
  'LECTURE': Color(0xFF1D4ED8),
  'GROUP_WORK': Color(0xFFB45309),
  'GROUP_EXERCISE': Color(0xFFB45309),
  'PRACTICAL_WORK': Color(0xFF15803D),
  'SEMINAR': Color(0xFF7C3AED),
  'LABORATORY_WORK': Color(0xFF15803D),
  'TEST_EXAMINATION': Color(0xFFEA580C),
  'EXAMINATION': Color(0xFFEA580C),
  'SELF_STUDY': Color(0xFF6B7280),
  'CONSULTATION': Color(0xFF1D4ED8),
  'MODULE_TEST': Color(0xFFEA580C),
  'OTHER': Color(0xFF6B7280),
};

const _dayAbbr = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];

const _locationSpecialNames = <int, String>{
  1: 'ВІТІ',
  10: 'Поле',
  11: 'Дистанційно',
  9999: 'HZ',
};

String _locationLabel(int? n) {
  if (n == null) return '';
  return _locationSpecialNames[n] ?? '№$n';
}

DateTime _getMonday(DateTime date) {
  final diff = date.weekday - 1;
  return DateTime(date.year, date.month, date.day - diff);
}

// ── Page ──────────────────────────────────────────────────────────────────────

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  int _tabIndex = 0;
  DateTime _weekStart = _getMonday(DateTime.now());
  double _scale = 1.0;

  String _groupNum = '';
  final _groupController = TextEditingController();
  int? _deptNum;
  final _courseController = TextEditingController();
  int? _facultyNum;
  int? _facultyId; // gradebook internal id → used for /faculties/$id/groups
  Set<String> _facultyGroupNums = {}; // group names of the selected faculty
  int _locationNum = 1;

  List<Map<String, dynamic>> _kafedras = [];
  List<Map<String, dynamic>> _faculties = [];
  static const _locationOptions = [1, 2, 7, 8, 9, 10, 11];

  List<Map<String, dynamic>> _lessons = [];
  bool _loading = false;
  String? _error;

  String get _startDate => DateFormat('yyyy-MM-dd').format(_weekStart);
  String get _endDate =>
      DateFormat('yyyy-MM-dd').format(_weekStart.add(const Duration(days: 6)));

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authViewModelProvider);
    _groupNum = auth.groupName ?? '';
    _groupController.text = _groupNum;
    // cadets: pre-fill course from group name (e.g. "221" → "22")
    if (auth.role == UserRole.cadet &&
        _groupNum.length >= 3 &&
        int.tryParse(_groupNum) != null) {
      _courseController.text = _groupNum.substring(0, _groupNum.length - 1);
    }
    _loadDropdowns();
  }

  @override
  void dispose() {
    _groupController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final kafedrasFuture = ref.read(kafedrasRepositoryProvider).getKafedras();
      final facultiesFuture = ref.read(facultiesRepositoryProvider).getFaculties();
      final kafedrasRaw = await kafedrasFuture;
      final facultiesRaw = await facultiesFuture;
      if (!mounted) return;
      final kafedras = kafedrasRaw
          .map((k) => Map<String, dynamic>.from(k as Map))
          .toList();
      final faculties = facultiesRaw
          .map((f) => Map<String, dynamic>.from(f as Map))
          .toList();
      setState(() {
        _kafedras = kafedras;
        _faculties = faculties;
        if (kafedras.isNotEmpty) _deptNum = _numOf(kafedras.first);
        if (faculties.isNotEmpty) {
          _facultyNum = _numOf(faculties.first);
          _facultyId = faculties.first['id'] as int?;
          // for cadets: pre-select their own faculty by name
          final auth = ref.read(authViewModelProvider);
          if (auth.role == UserRole.cadet && auth.facultyName != null) {
            final match = faculties.firstWhere(
              (f) => (f['name'] as String?) == auth.facultyName,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              _facultyNum = _numOf(match);
              _facultyId = match['id'] as int?;
            }
          }
        }
      });
      _fetchSchedule();
    } catch (_) {
      _fetchSchedule();
    }
  }

  int? _numOf(Map<String, dynamic> m) =>
      m['number'] as int? ?? m['id'] as int?;

  Future<void> _fetchSchedule() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(scheduleRepositoryProvider);

      final Map<String, dynamic> resp;

      switch (_tabIndex) {
        case 0: // Group
          if (_groupNum.isEmpty) {
            setState(() { _loading = false; _lessons = []; });
            return;
          }
          resp = await repo.getGroupSchedule(
              groupNumber: _groupNum,
              startDate: _startDate,
              endDate: _endDate);
        case 1: // Department
          if (_deptNum == null) {
            setState(() { _loading = false; _lessons = []; });
            return;
          }
          resp = await repo.getDepartmentSchedule(
              departmentNumber: _deptNum!,
              startDate: _startDate,
              endDate: _endDate);
        case 2: // Course
          final courseNum = int.tryParse(_courseController.text.trim());
          if (courseNum == null) {
            setState(() { _loading = false; _lessons = []; });
            return;
          }
          resp = await repo.getCourseSchedule(
              courseNumber: courseNum,
              startDate: _startDate,
              endDate: _endDate);
        case 3: // Faculty
          if (_facultyNum == null) {
            setState(() { _loading = false; _lessons = []; });
            return;
          }
          resp = await repo.getFacultySchedule(
              facultyNumber: _facultyNum!,
              startDate: _startDate,
              endDate: _endDate);
          // load faculty's own groups so we can filter cross-faculty noise
          if (_facultyId != null) {
            try {
              final fGroups = await ref
                  .read(facultiesRepositoryProvider)
                  .getFacultyGroups(_facultyId!);
              _facultyGroupNums = fGroups
                  .map((g) => (g as Map<String, dynamic>))
                  .map((g) =>
                      g['name']?.toString() ??
                      g['number']?.toString() ??
                      '')
                  .where((s) => s.isNotEmpty)
                  .toSet();
            } catch (_) {
              _facultyGroupNums = {};
            }
          }
        default: // Location
          resp = await repo.getLocationSchedule(
              locationNumber: _locationNum,
              startDate: _startDate,
              endDate: _endDate);
      }

      if (!mounted) return;
      final rawLessons = resp['lessons'];
      setState(() {
        _lessons = (rawLessons as List<dynamic>? ?? [])
            .map((l) => l as Map<String, dynamic>)
            .toList();
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      print('[Schedule] DioException $code ${e.requestOptions.path}: ${e.message}');
      if (code == 404) {
        // entity not found in schedule service → empty schedule, not an error
        setState(() { _loading = false; _lessons = []; });
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Помилка ${code ?? "мережі"}: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      print('[Schedule] error: $e');
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _isToday(int dayIndex) {
    final day = _weekStart.add(Duration(days: dayIndex));
    final now = DateTime.now();
    return day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
  }

  // period(1-4) → day(0-6) → lessons  (for group tab)
  Map<int, Map<int, List<Map<String, dynamic>>>> _buildGroupGrid() {
    final result = <int, Map<int, List<Map<String, dynamic>>>>{};
    for (int p = 1; p <= 4; p++) result[p] = {};
    for (final lesson in _lessons) {
      final st = lesson['startTime'] as String? ?? lesson['date'] as String?;
      if (st == null) continue;
      DateTime dt;
      try { dt = DateTime.parse(st); } catch (_) { continue; }
      final day = dt.weekday - 1;
      if (day < 0 || day > 6) continue;
      final order = (lesson['orderOfLesson'] as int?) ?? 0;
      if (order < 0 || order > 4) continue;
      if (order == 0) {
        // Whole-day event: show in all 4 periods for this day
        for (int p = 1; p <= 4; p++) {
          result[p]!.putIfAbsent(day, () => []);
          result[p]![day]!.add(lesson);
        }
      } else {
        result[order]!.putIfAbsent(day, () => []);
        result[order]![day]!.add(lesson);
      }
    }
    return result;
  }

  // rowLabel → cellKey('dayIndex_periodIndex') → lessons  (for dept/course/faculty/location tabs)
  Map<String, Map<String, List<Map<String, dynamic>>>> _buildGrid() {
    final result = <String, Map<String, List<Map<String, dynamic>>>>{};
    for (final lesson in _lessons) {
      final st = lesson['startTime'] as String? ?? lesson['date'] as String?;
      if (st == null) continue;
      DateTime dt;
      try {
        dt = DateTime.parse(st);
      } catch (_) {
        continue;
      }
      final day = dt.weekday - 1;
      if (day < 0 || day > 5) continue;
      final order = (lesson['orderOfLesson'] as int?) ?? 0;
      if (order < 0 || order > 4) continue;
      // order == 0 → whole-day event: spread across all 4 periods
      final keys = order == 0
          ? ['${day}_0', '${day}_1', '${day}_2', '${day}_3']
          : ['${day}_${order - 1}'];

      List<String> rows;
      if (_tabIndex == 4) {
        // Location: rows = audience numbers
        final audiences = lesson['audiences'] as List<dynamic>? ?? [];
        rows = audiences.isEmpty
            ? ['—']
            : audiences
                .map((a) => (a as Map<String, dynamic>)['number']?.toString() ?? '—')
                .toList();
      } else if (_tabIndex == 1) {
        // Department: rows = teacher surnames
        final teachers = lesson['teachers'] as List<dynamic>? ?? [];
        rows = teachers.isEmpty
            ? ['—']
            : teachers
                .map((t) => (t as Map<String, dynamic>)['surname']?.toString() ?? '—')
                .toList();
      } else {
        // Course / Faculty: rows = group numbers
        final groups = lesson['groups'] as List<dynamic>? ?? [];
        final groupNums = groups.isEmpty
            ? <String>['—']
            : groups
                .map((g) =>
                    (g as Map<String, dynamic>)['number']?.toString() ?? '—')
                .toList();
        if (_tabIndex == 3 && _facultyGroupNums.isNotEmpty) {
          // keep only groups that belong to this faculty
          rows = groupNums.where((n) => _facultyGroupNums.contains(n)).toList();
          // empty → cross-faculty lesson, skip entirely
        } else {
          rows = groupNums;
        }
      }

      for (final row in rows) {
        result.putIfAbsent(row, () => {});
        for (final k in keys) {
          result[row]!.putIfAbsent(k, () => []);
          result[row]![k]!.add(lesson);
        }
      }
    }
    return result;
  }

  void _selectTab(int idx) {
    setState(() => _tabIndex = idx);
    _fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final isCadet =
        ref.watch(authViewModelProvider).role == UserRole.cadet;

    const tabTitles = [
      'Розклад групи',
      'Розклад кафедри',
      'Розклад курсу',
      'Розклад факультету',
      'Розклад локації',
    ];

    List<DropdownMenuItem<int>> items;
    int? value;

    switch (_tabIndex) {
      case 0: // Group — handled separately below
        items = [];
        value = null;
      case 1:
        items = _kafedras.map((k) {
          final n = _numOf(k);
          return DropdownMenuItem(
              value: n,
              child: Text(k['name'] as String? ?? 'Кафедра',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)));
        }).toList();
        value = _deptNum;
      case 2: // Course — handled separately below (text input)
        items = [];
        value = null;
      case 3:
        items = _faculties.map((f) {
          final n = _numOf(f);
          return DropdownMenuItem(
              value: n,
              child: Text(f['name'] as String? ?? 'Факультет',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)));
        }).toList();
        value = _facultyNum;
      default:
        items = _locationOptions
            .map((l) => DropdownMenuItem(
                value: l,
                child: Text(_locationLabel(l),
                    style: const TextStyle(fontSize: 13))))
            .toList();
        value = _locationNum;
    }

    if (items.isNotEmpty && !items.any((i) => i.value == value)) {
      value = items.first.value;
    }

    // Group tab uses a different grid (period rows × day columns)
    final groupGrid = _tabIndex == 0 ? _buildGroupGrid() : null;
    final grid = _tabIndex != 0 ? _buildGrid() : <String, Map<String, List<Map<String, dynamic>>>>{};
    final rows = grid.keys.toList()
      ..sort((a, b) {
        final ai = int.tryParse(a);
        final bi = int.tryParse(b);
        if (ai != null && bi != null) return ai.compareTo(bi);
        return a.compareTo(b);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(tabTitles[_tabIndex]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 20),
            onPressed: () =>
                setState(() => _scale = (_scale - 0.1).clamp(0.7, 1.5)),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            onPressed: () =>
                setState(() => _scale = (_scale + 0.1).clamp(0.7, 1.5)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _TabChip(
                      label: 'Група',
                      selected: _tabIndex == 0,
                      onTap: () => _selectTab(0)),
                  if (!isCadet) ...[
                    const SizedBox(width: 6),
                    _TabChip(
                        label: 'Кафедра',
                        selected: _tabIndex == 1,
                        onTap: () => _selectTab(1)),
                  ],
                  const SizedBox(width: 6),
                  _TabChip(
                      label: 'Курс',
                      selected: _tabIndex == 2,
                      onTap: () => _selectTab(2)),
                  const SizedBox(width: 6),
                  _TabChip(
                      label: 'Факультет',
                      selected: _tabIndex == 3,
                      onTap: () => _selectTab(3)),
                  if (!isCadet) ...[
                    const SizedBox(width: 6),
                    _TabChip(
                        label: 'Локація',
                        selected: _tabIndex == 4,
                        onTap: () => _selectTab(4)),
                  ],
                ]),
              ),
              const SizedBox(height: 8),
              if (_tabIndex == 0 || _tabIndex == 2)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _tabIndex == 0 ? _groupController : _courseController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: _tabIndex == 0
                              ? 'Номер групи (напр. 221)'
                              : 'Номер курсу (напр. 11, 22)',
                        ),
                        keyboardType: TextInputType.number,
                        onSubmitted: (_) {
                          if (_tabIndex == 0) {
                            setState(() => _groupNum = _groupController.text.trim());
                            if (_groupNum.isNotEmpty) _fetchSchedule();
                          } else {
                            _fetchSchedule();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (_tabIndex == 0) {
                          setState(() => _groupNum = _groupController.text.trim());
                          if (_groupNum.isNotEmpty) _fetchSchedule();
                        } else {
                          _fetchSchedule();
                        }
                      },
                    ),
                  ]),
                )
              else if (items.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: value,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    items: items,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        switch (_tabIndex) {
                          case 1:
                            _deptNum = v;
                          case 2:
                            break; // course uses text field
                          case 3:
                            _facultyNum = v;
                            final fac = _faculties.firstWhere(
                              (f) => _numOf(f) == v,
                              orElse: () => {},
                            );
                            _facultyId = fac['id'] as int?;
                            _facultyGroupNums = {};
                          default:
                            _locationNum = v;
                        }
                      });
                      _fetchSchedule();
                    },
                  ),
                ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 18),
                  onPressed: () {
                    setState(() => _weekStart =
                        _weekStart.subtract(const Duration(days: 7)));
                    _fetchSchedule();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('dd.MM').format(_weekStart)} – '
                  '${DateFormat('dd.MM').format(_weekStart.add(const Duration(days: 6)))}',
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMid),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  onPressed: () {
                    setState(() => _weekStart =
                        _weekStart.add(const Duration(days: 7)));
                    _fetchSchedule();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ]),
          ),
          const Divider(height: 1),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Не вдалося завантажити розклад',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            )
          else if (_tabIndex == 0)
            Expanded(
              child: _GroupScheduleGrid(
                groupGrid: groupGrid!,
                weekStart: _weekStart,
                isToday: _isToday,
                scale: _scale,
              ),
            )
          else if (rows.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Розклад відсутній на цей тиждень',
                    style: TextStyle(color: AppTheme.textMid)),
              ),
            )
          else
            Expanded(
              child: _ScheduleGrid(
                rows: rows,
                grid: grid,
                weekStart: _weekStart,
                isToday: _isToday,
                scale: _scale,
                isLocationMode: _tabIndex == 4,
                rowHeader: _tabIndex == 4
                    ? 'Ауд.'
                    : _tabIndex == 1
                        ? 'Викладач'
                        : 'Група',
                // dept(1) and location(4) rows ≠ groups → show groups in secondary
                // course(2) and faculty(3) rows = groups → show teachers in secondary
                showGroupSecondary: _tabIndex == 1 || _tabIndex == 4,
              ),
            ),
        ],
      ),
    );
  }
}

// ── _ScheduleGrid ─────────────────────────────────────────────────────────────

class _ScheduleGrid extends StatelessWidget {
  final List<String> rows;
  final Map<String, Map<String, List<Map<String, dynamic>>>> grid;
  final DateTime weekStart;
  final bool Function(int) isToday;
  final double scale;
  final bool isLocationMode;
  final String rowHeader;
  // true → secondary in cells = groups; false → secondary in cells = teachers

  final bool showGroupSecondary;

  const _ScheduleGrid({
    required this.rows,
    required this.grid,
    required this.weekStart,
    required this.isToday,
    required this.scale,
    required this.isLocationMode,
    required this.rowHeader,
    required this.showGroupSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final rowLabelW = 80.0 * scale;
    final colW = 52.0 * scale;
    final headerH = 52.0 * scale;
    final cellH = 68.0 * scale;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Container(
                width: rowLabelW,
                height: headerH,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    rowHeader,
                    style: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMid),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // 6 days × 4 periods
              ..._dayAbbr.asMap().entries.expand((de) => List.generate(4, (p) {
                final today = isToday(de.key);
                return Container(
                  width: colW,
                  height: headerH,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: today ? const Color(0xFFDCFCE7) : Colors.white,
                    border:
                        Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (p == 0) ...[
                        Text(_dayAbbr[de.key],
                            style: TextStyle(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.w600,
                                color: today
                                    ? const Color(0xFF15803D)
                                    : AppTheme.textDark),
                            textAlign: TextAlign.center),
                        Text(
                          DateFormat('dd.MM')
                              .format(weekStart.add(Duration(days: de.key))),
                          style: TextStyle(
                              fontSize: 9 * scale,
                              color: AppTheme.textMid),
                          textAlign: TextAlign.center,
                        ),
                      ] else
                        SizedBox(height: 20 * scale),
                      Text('${p + 1}',
                          style: TextStyle(
                              fontSize: 9 * scale,
                              color: AppTheme.textMid),
                          textAlign: TextAlign.center),
                    ],
                  ),
                );
              })),
            ]),
            // Data rows
            ...rows.map((rowLabel) {
              final rowData = grid[rowLabel] ?? {};
              return Row(children: [
                Container(
                  width: rowLabelW,
                  height: cellH,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Center(
                    child: Text(rowLabel,
                        style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                        textAlign: TextAlign.center),
                  ),
                ),
                ..._dayAbbr.asMap().entries.expand(
                    (de) => List.generate(4, (p) {
                          final key = '${de.key}_$p';
                          return _LessonCell(
                            lessons: rowData[key] ?? [],
                            width: colW,
                            height: cellH,
                            today: isToday(de.key),
                            scale: scale,
                            isLocationMode: isLocationMode,
                            showGroupSecondary: showGroupSecondary,
                          );
                        })),
              ]);
            }),
          ],
        ),
      ),
    );
  }
}

// ── _LessonCell ───────────────────────────────────────────────────────────────

class _LessonCell extends StatelessWidget {
  final List<Map<String, dynamic>> lessons;
  final double width;
  final double height;
  final bool today;
  final double scale;
  final bool isLocationMode;
  // true → secondary = groups (dept/location), false → secondary = teachers (course/faculty)
  final bool showGroupSecondary;

  const _LessonCell({
    required this.lessons,
    required this.width,
    required this.height,
    required this.today,
    required this.scale,
    required this.isLocationMode,
    this.showGroupSecondary = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: today ? const Color(0xFFF0FDF4) : Colors.white,
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: lessons.isEmpty
          ? null
          : lessons.length == 1
              ? _buildCard(lessons.first)
              : Column(
                  children: lessons
                      .take(2)
                      .map((l) => Expanded(child: _buildCard(l)))
                      .toList(),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> lesson) {
    final typeKey = lesson['typeLesson'] as String? ?? '';
    final bg = _typeBg[typeKey] ?? const Color(0xFFF3F4F6);
    final fg = _typeFg[typeKey] ?? AppTheme.textDark;

    final discipline = lesson['discipline'] as Map<String, dynamic>?;
    final subjShort = discipline?['shortName'] as String? ??
        discipline?['fullName'] as String? ??
        lesson['title'] as String? ??
        lesson['name'] as String? ??
        lesson['eventName'] as String? ??
        '—';
    final numLesson = lesson['numberLesson'] as String? ?? '';
    final subj = numLesson.isNotEmpty ? '$subjShort $numLesson' : subjShort;

    // Secondary: groups for dept/location rows, teachers for course/faculty rows
    final String secondary;
    if (showGroupSecondary) {
      final groups = lesson['groups'] as List<dynamic>? ?? [];
      final groupNums = groups
          .map((g) => (g as Map<String, dynamic>)['number']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .join(', ');
      secondary = groupNums.isNotEmpty ? 'Гр. $groupNums' : '';
    } else {
      final teachers = lesson['teachers'] as List<dynamic>? ?? [];
      final teacherNames = teachers
          .map((t) => (t as Map<String, dynamic>)['surname']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .join(', ');
      secondary = teacherNames;
    }

    // Tertiary: show room for dept/course/faculty (not for location where row IS the room)
    String tertiary = '';
    if (!isLocationMode) {
      final audiences = lesson['audiences'] as List<dynamic>? ?? [];
      if (audiences.isNotEmpty) {
        final a = audiences.first as Map<String, dynamic>;
        final locNum = a['locationNumber'] as int?;
        final roomNum = a['number']?.toString() ?? '';
        final locName = _locationSpecialNames[locNum];
        tertiary = locName != null ? '$locName $roomNum'.trim() : roomNum;
      }
    }

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: fg, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subj,
              style: TextStyle(
                  fontSize: 8.5 * scale,
                  fontWeight: FontWeight.w600,
                  color: fg),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(secondary,
                style: TextStyle(
                    fontSize: 7.5 * scale, color: AppTheme.textMid),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
          if (tertiary.isNotEmpty)
            Text(tertiary,
                style: TextStyle(
                    fontSize: 7.5 * scale, color: AppTheme.textLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── _GroupScheduleGrid ────────────────────────────────────────────────────────

const _periodTimes = ['8:30–10:05', '10:20–11:55', '12:10–13:45', '15:15–16:50'];
const _allDayAbbr = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];

class _GroupScheduleGrid extends StatelessWidget {
  final Map<int, Map<int, List<Map<String, dynamic>>>> groupGrid;
  final DateTime weekStart;
  final bool Function(int) isToday;
  final double scale;

  const _GroupScheduleGrid({
    required this.groupGrid,
    required this.weekStart,
    required this.isToday,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final periodLabelW = 72.0 * scale;
    final dayColW = 120.0 * scale;
    final headerH = 44.0 * scale;
    final cellH = 90.0 * scale;

    // Show Mon–Sun (7 days), skip Sunday if no lessons
    final hasSunday = groupGrid.values.any((d) => d.containsKey(6));
    final dayCount = hasSunday ? 7 : 6;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: "Пара" | Mon 18.05 | Tue 19.05 | ...
            Row(children: [
              Container(
                width: periodLabelW,
                height: headerH,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Center(
                  child: Text('Пара',
                      style: TextStyle(
                          fontSize: 10 * scale,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMid),
                      textAlign: TextAlign.center),
                ),
              ),
              ...List.generate(dayCount, (d) {
                final today = isToday(d);
                return Container(
                  width: dayColW,
                  height: headerH,
                  decoration: BoxDecoration(
                    color: today ? const Color(0xFFDCFCE7) : Colors.white,
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_allDayAbbr[d],
                          style: TextStyle(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w600,
                              color: today
                                  ? const Color(0xFF15803D)
                                  : AppTheme.textDark),
                          textAlign: TextAlign.center),
                      Text(
                        DateFormat('dd.MM').format(weekStart.add(Duration(days: d))),
                        style: TextStyle(
                            fontSize: 9 * scale, color: AppTheme.textMid),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ]),
            // Period rows
            ...List.generate(4, (pi) {
              final period = pi + 1;
              final dayMap = groupGrid[period] ?? {};
              return Row(children: [
                // Period label
                Container(
                  width: periodLabelW,
                  height: cellH,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$period пара',
                            style: TextStyle(
                                fontSize: 10 * scale,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary),
                            textAlign: TextAlign.center),
                        Text(_periodTimes[pi],
                            style: TextStyle(
                                fontSize: 7.5 * scale,
                                color: AppTheme.textMid),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                // Day cells
                ...List.generate(dayCount, (d) {
                  final lessons = dayMap[d] ?? [];
                  final today = isToday(d);
                  return Container(
                    width: dayColW,
                    height: cellH,
                    decoration: BoxDecoration(
                      color: today ? const Color(0xFFF0FDF4) : Colors.white,
                      border: Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: lessons.isEmpty
                        ? null
                        : lessons.length == 1
                            ? _buildGroupCell(lessons.first, scale)
                            : Column(
                                children: lessons
                                    .take(2)
                                    .map((l) => Expanded(
                                        child: _buildGroupCell(l, scale)))
                                    .toList(),
                              ),
                  );
                }),
              ]);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCell(Map<String, dynamic> lesson, double scale) {
    final typeKey = lesson['typeLesson'] as String? ?? '';
    final bg = _typeBg[typeKey] ?? const Color(0xFFEFF6FF);
    final fg = _typeFg[typeKey] ?? AppTheme.primary;

    final discipline = lesson['discipline'] as Map<String, dynamic>?;
    final subjName = discipline?['shortName'] as String? ??
        discipline?['fullName'] as String? ??
        lesson['title'] as String? ??
        lesson['name'] as String? ??
        lesson['eventName'] as String? ??
        '—';

    final teachers = lesson['teachers'] as List<dynamic>? ?? [];
    final teacherStr = teachers
        .map((t) => (t as Map<String, dynamic>)['surname']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .join(', ');

    final audiences = lesson['audiences'] as List<dynamic>? ?? [];
    String roomStr = '';
    if (audiences.isNotEmpty) {
      final a = audiences.first as Map<String, dynamic>;
      final locNum = a['locationNumber'] as int?;
      final roomNum = a['number']?.toString() ?? '';
      final locName = _locationSpecialNames[locNum];
      roomStr = locName != null ? '$locName $roomNum'.trim() : roomNum;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(4),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: fg, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subjName,
              style: TextStyle(
                  fontSize: 9 * scale,
                  fontWeight: FontWeight.w700,
                  color: fg),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (teacherStr.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(teacherStr,
                style: TextStyle(
                    fontSize: 8 * scale, color: AppTheme.textMid),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
          if (roomStr.isNotEmpty)
            Text(roomStr,
                style: TextStyle(
                    fontSize: 7.5 * scale, color: AppTheme.textLight),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── _TabChip ──────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.sidebar : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.sidebar : AppTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppTheme.textDark)),
      ),
    );
  }
}
