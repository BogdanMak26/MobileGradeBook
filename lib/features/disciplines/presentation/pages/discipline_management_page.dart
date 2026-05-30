// lib/features/disciplines/presentation/pages/discipline_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/add_discipline_sheet.dart'
    show showAddDisciplineSheet, showEditDisciplineSheet;
import '../../data/repositories/disciplines_repository.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

String _teacherFullName(Map<String, dynamic> t) {
  final surname = (t['surname'] ?? t['lastName'] ?? '').toString();
  final first = (t['name'] ?? t['firstName'] ?? '').toString();
  final full = '$surname $first'.trim();
  return full.isNotEmpty ? full : 'ID: ${t['id']}';
}

String _teacherPosition(Map<String, dynamic> t) {
  const ranks = <String, String>{
    'CIVILIAN': 'Працівник ЗСУ', 'LIEUTENANT': 'Лейтенант',
    'SENIOR_LIEUTENANT': 'Старший лейтенант', 'CAPTAIN': 'Капітан',
    'MAJOR': 'Майор', 'LIEUTENANT_COLONEL': 'Підполковник', 'COLONEL': 'Полковник',
    'JUNIOR_LIEUTENANT': 'Молодший лейтенант', 'BRIGADIER_GENERAL': 'Бригадний генерал',
  };
  const positions = <String, String>{
    'TEACHER': 'Викладач', 'SENIOR_TEACHER': 'Старший викладач',
    'DOCENT': 'Доцент', 'PROFESSOR': 'Профессор',
    'HEAD_OF_KAFEDRA': 'Нач. кафедри',
    'DEPUTY_HEAD_OF_KAFEDRA': 'Заст. нач. кафедри',
  };
  const studyRanks = <String, String>{
    'CANDIDATE': 'Кандидат наук', 'DOCTOR_OF_SCIENCE': 'Доктор наук',
    'DOCTOR_OF_PHILOSOPHY': 'Доктор філософії',
  };
  const studyPositions = <String, String>{'DOCENT': 'Доцент', 'PROFESSOR': 'Профессор'};

  final parts = <String>[];
  final rank = ranks[t['rank']?.toString()];
  if (rank != null) parts.add(rank);
  final pos = positions[t['position']?.toString()];
  if (pos != null) parts.add(pos);
  final sp = studyPositions[t['scientificPosition']?.toString()];
  if (sp != null) parts.add(sp);
  final sr = studyRanks[t['scientificRank']?.toString()];
  if (sr != null) parts.add(sr);
  return parts.join(', ');
}

// Витягує масив призначених викладачів з raw-дисципліни.
// API може повертати `teachers` (масив) або `teacher` (один об'єкт).
List<Map<String, dynamic>> _disciplineTeachers(Map<String, dynamic> d) {
  final teachers = d['teachers'];
  if (teachers is List && teachers.isNotEmpty) {
    return teachers.whereType<Map<String, dynamic>>().toList();
  }
  final single = d['teacher'];
  if (single is Map<String, dynamic>) return [single];
  return [];
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DisciplineManagementPage extends ConsumerStatefulWidget {
  const DisciplineManagementPage({super.key});

  @override
  ConsumerState<DisciplineManagementPage> createState() =>
      _DisciplineManagementPageState();
}

class _DisciplineManagementPageState
    extends ConsumerState<DisciplineManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  List<Map<String, dynamic>> _disciplines = [];
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        ref.read(disciplinesRepositoryProvider).getAllDisciplinesRaw(),
        ref.read(teachersRepositoryProvider).getTeachers(),
      ]);
      if (!mounted) return;
      setState(() {
        _disciplines = (results[0] as List).cast<Map<String, dynamic>>();
        _teachers = (results[1] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab.index == 0
            ? 'Управління дисциплінами'
            : 'Управління викладачами'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left, size: 18, color: AppTheme.textMid),
              label: const Text('Повернутися до дисциплін',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMid,
              tabs: const [
                Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Дисципліни'),
                Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Викладачі'),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Помилка: $_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMid)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Повторити')),
              ]),
            ))
          else
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _DisciplinesTab(
                    disciplines: _disciplines,
                    teachers: _teachers,
                    onReload: _load,
                    onSnack: _snack,
                  ),
                  _TeachersTab(
                    teachers: _teachers,
                    disciplines: _disciplines,
                    onReload: _load,
                    onSnack: _snack,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Вкладка: Дисципліни ───────────────────────────────────────────────────────

class _DisciplinesTab extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> disciplines;
  final List<Map<String, dynamic>> teachers;
  final VoidCallback onReload;
  final void Function(String) onSnack;
  const _DisciplinesTab({
    required this.disciplines,
    required this.teachers,
    required this.onReload,
    required this.onSnack,
  });

  @override
  ConsumerState<_DisciplinesTab> createState() => _DisciplinesTabState();
}

class _DisciplinesTabState extends ConsumerState<_DisciplinesTab> {
  String _search = '';

  void _addTeacher(Map<String, dynamic> discipline, int teacherId) async {
    final dId = discipline['id'] as int;
    try {
      await ref.read(disciplinesRepositoryProvider).addTeacher(dId, teacherId);
      widget.onReload();
    } catch (e) {
      widget.onSnack('Помилка: $e');
    }
  }

  void _removeTeacher(Map<String, dynamic> discipline, int teacherId) async {
    final dId = discipline['id'] as int;
    try {
      await ref.read(disciplinesRepositoryProvider).removeTeacher(dId, teacherId);
      widget.onReload();
    } catch (e) {
      widget.onSnack('Помилка: $e');
    }
  }

  void _editDiscipline(Map<String, dynamic> d) {
    final name  = (d['name']      ?? d['fullName']  ?? '').toString();
    final short = (d['shortName'] ?? d['short']     ?? '').toString();
    showEditDisciplineSheet(
      context,
      disciplineId: d['id'] as int,
      name:         name,
      shortName:    short,
      onUpdated:    widget.onReload,
    );
  }

  void _deleteDiscipline(Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Видалити дисципліну?'),
        content: Text('"${d['name'] ?? d['fullName'] ?? ''}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ref.read(disciplinesRepositoryProvider)
                    .deleteDiscipline(d['id'] as int);
                widget.onSnack('Дисципліну видалено');
                widget.onReload();
              } catch (e) {
                widget.onSnack('Помилка: $e');
              }
            },
            child: const Text('Видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.disciplines.where((d) {
      final name = (d['name'] ?? d['fullName'] ?? '').toString().toLowerCase();
      final short = (d['shortName'] ?? d['short'] ?? '').toString().toLowerCase();
      return name.contains(_search.toLowerCase()) ||
          short.contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Пошук дисциплін...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMid, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Row(children: [
              const Icon(Icons.menu_book_outlined, size: 16, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text('Всього: ${widget.disciplines.length}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showAddDisciplineSheet(context, onCreated: widget.onReload),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('+ Додати дисципліну',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('Дисциплін не знайдено',
                      style: TextStyle(color: AppTheme.textMid)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final d = filtered[i];
                    final teachers = _disciplineTeachers(d);
                    final assignedIds = teachers.map((t) => t['id'] as int?).toSet();
                    final available = widget.teachers
                        .where((t) => !assignedIds.contains(t['id'] as int?))
                        .toList();
                    final name = (d['name'] ?? d['fullName'] ?? '').toString();
                    final short = (d['shortName'] ?? d['short'] ?? '').toString();
                    final journals = d['journalCount'] ?? d['journals'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6, offset: const Offset(0, 2),
                        )],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.textDark)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    if (short.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppTheme.border),
                                        ),
                                        child: Text(short,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textDark)),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text('ID: ${d['id']}   Журналів: $journals',
                                        style: const TextStyle(
                                            fontSize: 12, color: AppTheme.textMid)),
                                  ]),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: AppTheme.textMid),
                              onPressed: () => _editDiscipline(d),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppTheme.textMid),
                              onPressed: () => _deleteDiscipline(d),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.people_outline,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text('Призначені викладачі (${teachers.length})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.primary)),
                          ]),
                          const SizedBox(height: 8),
                          if (teachers.isEmpty)
                            _EmptyBox(label: 'Викладачі не призначені')
                          else
                            ...teachers.map((t) => _AssignedRow(
                              label: _teacherFullName(t),
                              onDelete: () =>
                                  _removeTeacher(d, t['id'] as int),
                            )),
                          const SizedBox(height: 8),
                          if (available.isNotEmpty)
                            _AssignDropdown<int>(
                              hint: 'Призначити викладача...',
                              items: available.map((t) => DropdownMenuItem(
                                value: t['id'] as int,
                                child: Text(_teacherFullName(t),
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              )).toList(),
                              onChanged: (id) {
                                if (id != null) _addTeacher(d, id);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Вкладка: Викладачі ────────────────────────────────────────────────────────

class _TeachersTab extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> disciplines;
  final VoidCallback onReload;
  final void Function(String) onSnack;
  const _TeachersTab({
    required this.teachers,
    required this.disciplines,
    required this.onReload,
    required this.onSnack,
  });

  @override
  ConsumerState<_TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends ConsumerState<_TeachersTab> {
  String _search = '';

  // Будує map: teacherId → список дисциплін, де викладач призначений.
  Map<int, List<Map<String, dynamic>>> get _teacherDisciplines {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final d in widget.disciplines) {
      for (final t in _disciplineTeachers(d)) {
        final tId = t['id'];
        if (tId is int) {
          map.putIfAbsent(tId, () => []).add(d);
        }
      }
    }
    return map;
  }

  void _addDiscipline(int teacherId, int disciplineId) async {
    try {
      await ref.read(disciplinesRepositoryProvider).addTeacher(disciplineId, teacherId);
      widget.onReload();
    } catch (e) {
      widget.onSnack('Помилка: $e');
    }
  }

  void _removeDiscipline(int teacherId, int disciplineId) async {
    try {
      await ref.read(disciplinesRepositoryProvider).removeTeacher(disciplineId, teacherId);
      widget.onReload();
    } catch (e) {
      widget.onSnack('Помилка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tdMap = _teacherDisciplines;

    final filtered = widget.teachers.where((t) =>
        _teacherFullName(t).toLowerCase().contains(_search.toLowerCase())).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Пошук викладачів...',
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMid, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Row(children: [
              const Icon(Icons.person_outline, size: 16, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text('Всього: ${widget.teachers.length}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
            ]),
          ]),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('Викладачів не знайдено',
                      style: TextStyle(color: AppTheme.textMid)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final t = filtered[i];
                    final tId = t['id'] as int?;
                    final assignedDiscs = tId != null ? (tdMap[tId] ?? []) : <Map<String, dynamic>>[];
                    final assignedDiscIds = assignedDiscs.map((d) => d['id'] as int?).toSet();
                    final availableDiscs = widget.disciplines
                        .where((d) => !assignedDiscIds.contains(d['id'] as int?))
                        .toList();
                    final position = _teacherPosition(t);
                    final birthday = t['birthday'] as String?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6, offset: const Offset(0, 2),
                        )],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_teacherFullName(t),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppTheme.textDark)),
                                  if (position.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(position,
                                        style: const TextStyle(
                                            fontSize: 12, color: AppTheme.textMid)),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    birthday != null
                                        ? 'ID: ${t['id']}   Д.н.: $birthday'
                                        : 'ID: ${t['id']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppTheme.textMid),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(children: [
                            const Icon(Icons.menu_book_outlined,
                                size: 16, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text('Призначені дисципліни (${assignedDiscs.length})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.primary)),
                          ]),
                          const SizedBox(height: 8),
                          if (assignedDiscs.isEmpty)
                            _EmptyBox(label: 'Дисципліни не призначені')
                          else
                            ...assignedDiscs.map((d) {
                              final dName = (d['name'] ?? d['fullName'] ?? '').toString();
                              final dShort = (d['shortName'] ?? d['short'] ?? '').toString();
                              return _AssignedRow(
                                label: dName,
                                badge: dShort.isNotEmpty ? dShort : null,
                                onDelete: tId != null
                                    ? () => _removeDiscipline(tId, d['id'] as int)
                                    : null,
                              );
                            }),
                          const SizedBox(height: 8),
                          if (tId != null && availableDiscs.isNotEmpty)
                            _AssignDropdown<int>(
                              hint: 'Призначити дисципліну...',
                              items: availableDiscs.map((d) {
                                final dName = (d['name'] ?? d['fullName'] ?? '').toString();
                                return DropdownMenuItem(
                                  value: d['id'] as int,
                                  child: Text(dName,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (dId) {
                                if (dId != null) _addDiscipline(tId, dId);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Спільні допоміжні віджети ─────────────────────────────────────────────────

class _EmptyBox extends StatelessWidget {
  final String label;
  const _EmptyBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textMid, fontStyle: FontStyle.italic)),
    );
  }
}

class _AssignedRow extends StatelessWidget {
  final String label;
  final String? badge;
  final VoidCallback? onDelete;
  const _AssignedRow({required this.label, this.badge, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
              ),
          ]),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 16, color: AppTheme.textLight),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ]),
    );
  }
}

class _AssignDropdown<T> extends StatelessWidget {
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _AssignDropdown({
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButton<T>(
        hint: Text(hint,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
        isExpanded: true,
        underline: const SizedBox(),
        value: null,
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
