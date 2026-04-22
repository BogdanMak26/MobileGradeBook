// lib/features/schedule/presentation/pages/schedule_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_theme.dart';

// ── Mock дані розкладу ────────────────────────────────────────────────────────

const _lessonTypes = {
  'Лекція': Color(0xFFDBEAFE),
  'Практичне': Color(0xFFDCFCE7),
  'Групове': Color(0xFFFEF3C7),
  'СР': Color(0xFFF3F4F6),
  'НАРЯД': Color(0xFFFFEDD5),
  'СТАЖУВАННЯ': Color(0xFFDBEAFE),
};

const _lessonTypeText = {
  'Лекція': Color(0xFF1D4ED8),
  'Практичне': Color(0xFF15803D),
  'Групове': Color(0xFFB45309),
  'СР': Color(0xFF6B7280),
  'НАРЯД': Color(0xFFEA580C),
  'СТАЖУВАННЯ': Color(0xFF1D4ED8),
};

// Пари з часом
const _periods = [
  {'num': '1 пара', 'time': '8:30–10:05'},
  {'num': '2 пара', 'time': '10:20–11:55'},
  {'num': '3 пара', 'time': '12:10–13:45'},
  {'num': '4 пара', 'time': '15:15–16:50'},
];

const _days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
const _fullDays = ['Понеділок', 'Вівторок', 'Середа', 'Четвер', "П'ятниця", 'Субота'];

// Розклад групи (dayIndex 0=Пн, period 0=1пара)
const _groupSchedule = <String, dynamic>{
  '0_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
  '1_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
  '2_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
  '3_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
  '4_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
  '5_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
};

// Розклад курсу (групи × дні × пари)
const _courseGroups = ['221', '222', '223', '231', '232'];
const _courseSchedule = <String, Map<String, dynamic>>{
  '221': {
    '0_0': {'subj': 'КОБЕ УВАННЯ', 'type': 'Практичне', 'teacher': 'Задорожна', 'room': 'ВІТІ 134'},
    '1_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
    '2_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
    '1_1': {'subj': 'ТРІ 1/6', 'type': 'Групове', 'teacher': 'Налісний', 'room': 'ВІТІ 136'},
    '1_2': {'subj': 'ОБД 3/2', 'type': 'Групове', 'teacher': 'Бовда', 'room': 'ВІТІ 136'},
    '1_3': {'subj': 'ТРП 2/4', 'type': 'Практичне', 'teacher': 'С.Романенко', 'room': 'ВІТІ 136'},
  },
  '222': {
    '0_0': {'subj': 'КОБЕ УВАННЯ', 'type': 'Практичне', 'teacher': 'Задорожна', 'room': 'ВІТІ 134'},
    '1_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
    '1_1': {'subj': 'ІМ 3/12', 'type': 'Практичне', 'teacher': 'Задорожна, Бужикова', 'room': 'ВІТІ 144'},
    '1_2': {'subj': 'МСВ 1/8', 'type': 'Практичне', 'teacher': 'Гріньков', 'room': 'ВІТІ 144'},
    '1_3': {'subj': 'ПРАВ 2/4', 'type': 'Практичне', 'teacher': 'Саvoткін', 'room': 'ВІТІ 144'},
  },
  '223': {
    '1_0': {'subj': 'ВІЙСЬКОВЕ СТАЖУВАННЯ', 'type': 'СТАЖУВАННЯ', 'teacher': '', 'room': ''},
    '1_1': {'subj': 'ФВ 5/19', 'type': 'Практичне', 'teacher': 'Попович', 'room': 'ВІТІ спорт.'},
    '1_2': {'subj': 'ІМ 3/12', 'type': 'Практичне', 'teacher': 'Задорожна', 'room': 'ВІТІ 138'},
    '1_3': {'subj': 'ТСА 7/3', 'type': 'Практичне', 'teacher': 'Кондрусь', 'room': 'ВІТІ 138'},
  },
  '231': {
    '1_0': {'subj': 'ОБД 3/3', 'type': 'Практичне', 'teacher': 'Бовда', 'room': 'ВІТІ 136'},
    '1_1': {'subj': 'ПРАВ 2/4', 'type': 'Практичне', 'teacher': 'Саvoткін', 'room': 'ВІТІ 136'},
    '1_2': {'subj': 'ІМ 3/13', 'type': 'Практичне', 'teacher': 'Задорожна', 'room': 'ВІТІ 206'},
    '1_3': {'subj': 'МСВ 2/1', 'type': 'Лекція', 'teacher': 'Гріньков', 'room': 'ВІТІ 133'},
  },
  '232': {
    '1_1': {'subj': 'ОБД 3/2', 'type': 'Групове', 'teacher': 'Бовда', 'room': 'ВІТІ 144'},
    '1_2': {'subj': 'МСВ 1/8', 'type': 'Практичне', 'teacher': 'Гріньков', 'room': 'ВІТІ 144'},
    '1_3': {'subj': 'ПРАВ 2/4', 'type': 'Практичне', 'teacher': 'Саvoткін', 'room': 'ВІТІ 144'},
  },
};

// ── Page ──────────────────────────────────────────────────────────────────────

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

// Selector options
const _kafedraOptions = ['Кафедра №1', 'Кафедра №2', 'Кафедра №3', 'Кафедра №21', 'Кафедра №22'];
const _courseOptions = ['1 курс', '2 курс', '3 курс', '4 курс'];
const _facultyOptions = ['Факультет №1', 'Факультет №2', 'Факультет №3'];
const _locationOptions = ['Локація №1', 'Локація №2', 'Локація №3', 'Корпус №8'];

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  DateTime _weekStart = _getMonday(DateTime.now());
  double _scale = 1.0;
  int _kafedraIdx = 0;
  int _courseIdx = 0;
  int _facultyIdx = 0;
  int _locationIdx = 0;

  static DateTime _getMonday(DateTime date) {
    final diff = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - diff);
  }

  String get _weekLabel {
    final end = _weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('dd.MM');
    return '${fmt.format(_weekStart)} – ${fmt.format(end)}';
  }

  void _prevWeek() => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  void _nextWeek() => setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  bool _isToday(int dayIndex) {
    final day = _weekStart.add(Duration(days: dayIndex));
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab.index == 0
            ? 'Розклад занять'
            : _tab.index == 1 ? 'Розклад курсу'
            : _tab.index == 2 ? 'Розклад факультету'
            : 'Розклад локації'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 20),
            onPressed: () => setState(() => _scale = (_scale - 0.1).clamp(0.7, 1.5)),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            onPressed: () => setState(() => _scale = (_scale + 0.1).clamp(0.7, 1.5)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs + Selector + Week navigation
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(children: [
              // Рядок 1: таби (Кафедра/Курс/Факультет/Локація)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _TabChip(label: 'Кафедра', selected: _tab.index == 0,
                      onTap: () => setState(() => _tab.animateTo(0))),
                  const SizedBox(width: 6),
                  _TabChip(label: 'Курс', selected: _tab.index == 1,
                      onTap: () => setState(() => _tab.animateTo(1))),
                  const SizedBox(width: 6),
                  _TabChip(label: 'Факультет', selected: _tab.index == 2,
                      onTap: () => setState(() => _tab.animateTo(2))),
                  const SizedBox(width: 6),
                  _TabChip(label: 'Локація', selected: _tab.index == 3,
                      onTap: () => setState(() => _tab.animateTo(3))),
                ]),
              ),
              const SizedBox(height: 8),
              // Рядок 2: вибір кафедри/курсу/факультету/локації через dropdown
              Row(children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: _tab.index == 0 ? _kafedraIdx
                          : _tab.index == 1 ? _courseIdx
                          : _tab.index == 2 ? _facultyIdx
                          : _locationIdx,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      items: (() {
                        final opts = _tab.index == 0 ? _kafedraOptions
                            : _tab.index == 1 ? _courseOptions
                            : _tab.index == 2 ? _facultyOptions
                            : _locationOptions;
                        return opts.asMap().entries.map((e) =>
                          DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                          )).toList();
                      })(),
                      onChanged: (v) => setState(() {
                        if (v == null) return;
                        if (_tab.index == 0) _kafedraIdx = v;
                        else if (_tab.index == 1) _courseIdx = v;
                        else if (_tab.index == 2) _facultyIdx = v;
                        else _locationIdx = v;
                      }),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              // Рядок 3: тиждень
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 18),
                  onPressed: _prevWeek,
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),
                Text(_weekLabel,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMid)),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 18),
                  onPressed: _nextWeek,
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ]),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _GroupScheduleView(
                    weekStart: _weekStart,
                    isToday: _isToday,
                    scale: _scale),
                _CourseScheduleView(
                    weekStart: _weekStart,
                    isToday: _isToday,
                    scale: _scale),
                _FacultyScheduleView(
                    weekStart: _weekStart,
                    isToday: _isToday,
                    scale: _scale),
                _LocationScheduleView(
                    weekStart: _weekStart,
                    isToday: _isToday,
                    scale: _scale),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Розклад групи ─────────────────────────────────────────────────────────────

class _GroupScheduleView extends StatelessWidget {
  final DateTime weekStart;
  final bool Function(int) isToday;
  final double scale;
  const _GroupScheduleView(
      {required this.weekStart, required this.isToday, required this.scale});

  @override
  Widget build(BuildContext context) {
    final dayW = 110.0 * scale;
    final periodW = 72.0 * scale;
    final cellH = 80.0 * scale;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — days
            Row(children: [
              SizedBox(width: periodW), // empty corner
              ..._days.asMap().entries.map((e) {
                final date = weekStart.add(Duration(days: e.key));
                final today = isToday(e.key);
                return Container(
                  width: dayW,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: today ? const Color(0xFFDCFCE7) : Colors.white,
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(children: [
                    Text(_fullDays[e.key],
                        style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                            color: today
                                ? const Color(0xFF15803D)
                                : AppTheme.textDark),
                        textAlign: TextAlign.center),
                    Text(DateFormat('dd.MM').format(date),
                        style: TextStyle(
                            fontSize: 10 * scale,
                            color: today
                                ? const Color(0xFF15803D)
                                : AppTheme.textMid),
                        textAlign: TextAlign.center),
                  ]),
                );
              }),
            ]),
            // Data rows — periods
            ..._periods.asMap().entries.map((pe) {
              return Row(children: [
                // Period label
                Container(
                  width: periodW,
                  height: cellH,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_periods[pe.key]['num']!,
                          style: TextStyle(
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark),
                          textAlign: TextAlign.center),
                      Text(_periods[pe.key]['time']!,
                          style: TextStyle(
                              fontSize: 9 * scale, color: AppTheme.textMid),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                // Cells for each day
                ..._days.asMap().entries.map((de) {
                  final key = '${de.key}_${pe.key}';
                  final lesson = _groupSchedule[key];
                  final today = isToday(de.key);
                  return _LessonCell(
                    lesson: lesson,
                    width: dayW,
                    height: cellH,
                    today: today,
                    scale: scale,
                  );
                }),
              ]);
            }),
          ],
        ),
      ),
    );
  }
}

// ── Розклад курсу ─────────────────────────────────────────────────────────────

class _CourseScheduleView extends StatelessWidget {
  final DateTime weekStart;
  final bool Function(int) isToday;
  final double scale;
  const _CourseScheduleView(
      {required this.weekStart, required this.isToday, required this.scale});

  @override
  Widget build(BuildContext context) {
    final groupW = 38.0 * scale;
    final dayW = 56.0 * scale;
    final cellH = 70.0 * scale;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Container(
                width: groupW,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Text('Група',
                    style: TextStyle(
                        fontSize: 10 * scale,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMid),
                    textAlign: TextAlign.center),
              ),
              ..._days.asMap().entries.expand((de) => List.generate(4, (p) {
                final today = isToday(de.key);
                return Container(
                  width: dayW,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: today ? const Color(0xFFDCFCE7) : Colors.white,
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(children: [
                    if (p == 0)
                      Text(_days[de.key],
                          style: TextStyle(
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w600,
                              color: today
                                  ? const Color(0xFF15803D)
                                  : AppTheme.textDark),
                          textAlign: TextAlign.center),
                    if (p == 0)
                      Text(
                        DateFormat('dd.MM').format(
                            weekStart.add(Duration(days: de.key))),
                        style: TextStyle(
                            fontSize: 9 * scale, color: AppTheme.textMid),
                        textAlign: TextAlign.center,
                      ),
                    if (p > 0) SizedBox(height: 16 * scale),
                    Text('${p + 1}',
                        style: TextStyle(
                            fontSize: 9 * scale, color: AppTheme.textMid),
                        textAlign: TextAlign.center),
                  ]),
                );
              })),
            ]),
            // Rows per group
            ..._courseGroups.map((group) {
              return Row(children: [
                Container(
                  width: groupW,
                  height: cellH,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Center(
                    child: Text(group,
                        style: TextStyle(
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                        textAlign: TextAlign.center),
                  ),
                ),
                ..._days.asMap().entries.expand((de) =>
                    List.generate(4, (p) {
                      final key = '${de.key}_$p';
                      final lesson = _courseSchedule[group]?[key];
                      final today = isToday(de.key);
                      return _LessonCell(
                        lesson: lesson,
                        width: dayW,
                        height: cellH,
                        today: today,
                        scale: scale,
                        compact: true,
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

// ── Розклад факультету ────────────────────────────────────────────────────────

class _FacultyScheduleView extends StatelessWidget {
  final DateTime weekStart;
  final bool Function(int) isToday;
  final double scale;
  const _FacultyScheduleView(
      {required this.weekStart, required this.isToday, required this.scale});

  @override
  Widget build(BuildContext context) {
    return _CourseScheduleView(
      weekStart: weekStart,
      isToday: isToday,
      scale: scale,
    );
  }
}

// ── Розклад локації ──────────────────────────────────────────────────────────

class _LocationScheduleView extends StatelessWidget {
  final DateTime weekStart;
  final bool Function(int) isToday;
  final double scale;
  const _LocationScheduleView(
      {required this.weekStart, required this.isToday, required this.scale});

  static const _rooms = ['119', '120', '121', '133', '136', '138', '144', '206'];
  static const _roomSchedule = <String, Map<String, dynamic>>{
    '119': {
      '0_1': {'subj': 'АП 2/3', 'type': 'Практичне', 'teacher': 'Шарнін', 'group': '355'},
      '1_1': {'subj': 'ЗТ 2/9', 'type': 'Групове', 'teacher': 'Кущик', 'group': '355'},
      '1_2': {'subj': 'АП 2/4', 'type': 'Практичне', 'teacher': 'Шарнін', 'group': '355'},
    },
    '136': {
      '0_0': {'subj': 'ТРІ 1/6', 'type': 'Групове', 'teacher': 'Налісний', 'group': '231'},
      '1_0': {'subj': 'ОБД 3/3', 'type': 'Практичне', 'teacher': 'Бовда', 'group': '231'},
      '1_1': {'subj': 'ПРАВ 2/4', 'type': 'Практичне', 'teacher': 'Саvoткін', 'group': '231'},
    },
    '144': {
      '0_0': {'subj': 'ТРІ 1/6', 'type': 'Групове', 'teacher': 'Налісний', 'group': '232'},
      '1_1': {'subj': 'ОБД 3/2', 'type': 'Групове', 'teacher': 'Бовда', 'group': '232'},
    },
  };

  @override
  Widget build(BuildContext context) {
    final roomW = 42.0 * scale;
    final dayW = 56.0 * scale;
    final cellH = 70.0 * scale;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: roomW,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Text('Ауд.',
                    style: TextStyle(fontSize: 10 * scale,
                        fontWeight: FontWeight.w600, color: AppTheme.textMid),
                    textAlign: TextAlign.center),
              ),
              ..._days.asMap().entries.expand((de) => List.generate(4, (p) {
                final today = isToday(de.key);
                return Container(
                  width: dayW,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: today ? const Color(0xFFDCFCE7) : Colors.white,
                    border: Border.all(color: AppTheme.border, width: 0.5),
                  ),
                  child: Column(children: [
                    if (p == 0) Text(_days[de.key],
                        style: TextStyle(fontSize: 10 * scale,
                            fontWeight: FontWeight.w600,
                            color: today ? const Color(0xFF15803D) : AppTheme.textDark),
                        textAlign: TextAlign.center),
                    if (p == 0) Text(
                      DateFormat('dd.MM').format(weekStart.add(Duration(days: de.key))),
                      style: TextStyle(fontSize: 9 * scale, color: AppTheme.textMid),
                      textAlign: TextAlign.center,
                    ),
                    if (p > 0) SizedBox(height: 16 * scale),
                    Text('${p + 1}',
                        style: TextStyle(fontSize: 9 * scale, color: AppTheme.textMid),
                        textAlign: TextAlign.center),
                  ]),
                );
              })),
            ]),
            ..._rooms.map((room) => Row(children: [
              Container(
                width: roomW, height: cellH,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Center(child: Text(room,
                    style: TextStyle(fontSize: 11 * scale,
                        fontWeight: FontWeight.bold, color: AppTheme.primary),
                    textAlign: TextAlign.center)),
              ),
              ..._days.asMap().entries.expand((de) => List.generate(4, (p) {
                final key = '${de.key}_$p';
                final lesson = _roomSchedule[room]?[key];
                return _LessonCell(
                  lesson: lesson, width: dayW, height: cellH,
                  today: isToday(de.key), scale: scale, compact: true,
                );
              })),
            ])),
          ],
        ),
      ),
    );
  }
}

// ── Клітинка заняття ──────────────────────────────────────────────────────────

class _LessonCell extends StatelessWidget {
  final Map<String, dynamic>? lesson;
  final double width;
  final double height;
  final bool today;
  final double scale;
  final bool compact;

  const _LessonCell({
    required this.lesson,
    required this.width,
    required this.height,
    required this.today,
    required this.scale,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (lesson == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: today ? const Color(0xFFF0FDF4) : Colors.white,
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
      );
    }

    final type = lesson!['type'] as String;
    final bg = _lessonTypes[type] ?? const Color(0xFFF3F4F6);
    final fg = _lessonTypeText[type] ?? AppTheme.textDark;

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(compact ? 3 : 5),
      decoration: BoxDecoration(
        color: today ? const Color(0xFFF0FDF4) : Colors.white,
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Container(
        padding: EdgeInsets.all(compact ? 3 : 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: fg, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lesson!['subj'] as String,
                style: TextStyle(
                    fontSize: (compact ? 8.5 : 10) * scale,
                    fontWeight: FontWeight.w600,
                    color: fg),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (!compact && (lesson!['type'] as String).isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: fg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(type,
                    style: TextStyle(
                        fontSize: 8 * scale,
                        fontWeight: FontWeight.w600,
                        color: fg)),
              ),
            ],
            if ((lesson!['teacher'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(lesson!['teacher'] as String? ?? '',
                  style: TextStyle(
                      fontSize: (compact ? 7.5 : 9) * scale,
                      color: AppTheme.textMid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (((lesson!['room'] as String?) ?? '').isNotEmpty)
                Text(lesson!['room'] as String? ?? '',
                    style: TextStyle(
                        fontSize: (compact ? 7.5 : 9) * scale,
                        color: AppTheme.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

// ── TabChip ───────────────────────────────────────────────────────────────────

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
                color:
                    selected ? Colors.white : AppTheme.textDark)),
      ),
    );
  }
}
