// lib/features/disciplines/presentation/pages/disciplines_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../grades/presentation/pages/grade_journal_page.dart';
import '../../data/models/discipline_model.dart';
import '../../data/models/journal_model.dart';
import '../viewmodels/disciplines_viewmodel.dart';
import 'discipline_management_page.dart';
import '../../../../shared/widgets/add_discipline_sheet.dart';
import '../../../../shared/widgets/create_journal_dialog.dart';

class DisciplinesPage extends ConsumerStatefulWidget {
  const DisciplinesPage({super.key});

  @override
  ConsumerState<DisciplinesPage> createState() => _DisciplinesPageState();
}

class _DisciplinesPageState extends ConsumerState<DisciplinesPage> {
  String _search = '';

  bool _canManage(String role) =>
      role == UserRole.departmentHead || role == UserRole.superAdmin;

  bool _isCadet(String role) => role == UserRole.cadet;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final role = authState.role ?? '';
    final cadetGroupId = authState.groupId;
    final vm = ref.watch(disciplinesViewModelProvider);

    final disciplines = vm.disciplines
        .where((d) =>
            d.fullName.toLowerCase().contains(_search.toLowerCase()) ||
            (d.shortName?.toLowerCase().contains(_search.toLowerCase()) ??
                false))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дисципліни'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
        actions: [
          if (_canManage(role))
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DisciplineManagementPage(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Пошук дисциплін...',
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.textMid, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _search = ''),
                          )
                        : null,
                  ),
                ),
              ),
              if (_canManage(role)) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune,
                      color: Colors.white, size: 20),
                ),
              ],
            ]),
          ),
          if (role == UserRole.instructor)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
              child: Row(children: [
                Checkbox(
                  value: vm.myOnly,
                  onChanged: (v) => ref
                      .read(disciplinesViewModelProvider.notifier)
                      .setMyOnly(v ?? true),
                  activeColor: AppTheme.primary,
                ),
                const Text(
                  'Тільки мої дисципліни',
                  style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                ),
              ]),
            ),
          if (vm.isLoading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (vm.error != null)
            Expanded(child: Center(child: Text(vm.error!)))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(disciplinesViewModelProvider.notifier).load(),
                child: disciplines.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [_EmptyState(search: _search)],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount:
                            disciplines.length + (_canManage(role) ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (_canManage(role) && i == disciplines.length) {
                            return _AddDisciplineCard(
                              onCreated: () => ref.read(disciplinesViewModelProvider.notifier).load(),
                            );
                          }
                          return _DisciplineCard(
                            discipline: disciplines[i],
                            isCadet: _isCadet(role),
                            cadetGroupId: cadetGroupId,
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Картка дисципліни ─────────────────────────────────────────────────────────

class _DisciplineCard extends ConsumerStatefulWidget {
  final DisciplineModel discipline;
  final bool isCadet;
  final int? cadetGroupId;

  const _DisciplineCard({
    required this.discipline,
    required this.isCadet,
    required this.cadetGroupId,
  });

  @override
  ConsumerState<_DisciplineCard> createState() => _DisciplineCardState();
}

class _DisciplineCardState extends ConsumerState<_DisciplineCard> {
  @override
  Widget build(BuildContext context) {
    final discipline = widget.discipline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (discipline.shortName != null)
                            Text(discipline.shortName!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary)),
                          const SizedBox(height: 2),
                          Text(discipline.fullName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155))),
                        ],
                      ),
                    ),
                    const Icon(Icons.school,
                        color: AppTheme.primary, size: 24),
                  ],
                ),
                const SizedBox(height: 8),
                Text(discipline.fullName,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMid),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FooterRow(
                      label: 'Журналів:',
                      value: '${discipline.journalCount}',
                    ),
                    const SizedBox(height: 4),
                    if (discipline.teacherName != null)
                      _FooterRow(
                        label: 'Викладач:',
                        value: discipline.teacherName!,
                        highlight: true,
                      ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  if (widget.isCadet) {
                    final groupId = discipline.groupId;
                    final semesterId = discipline.semesterId;
                    if (groupId == null || semesterId == null) return;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => GradeJournalPage(
                        groupId: groupId,
                        disciplineId: discipline.id.toString(),
                        semesterId: semesterId.toString(),
                        disciplineShortName: discipline.shortName,
                        groupName: 'Навчальна група',
                        readOnly: true,
                      ),
                    ));
                  } else {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _JournalListPage(discipline: discipline),
                    ));
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryDark,
                  side: const BorderSide(color: AppTheme.primaryDark),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                child: const Text('Переглянути'),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _FooterRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: highlight
              ? AppTheme.primary.withOpacity(0.1)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: highlight
                    ? AppTheme.primary
                    : const Color(0xFF334155))),
      ),
    ]);
  }
}

// ── Список журналів дисципліни ─────────────────────────────────────────────────

class _JournalListPage extends ConsumerStatefulWidget {
  final DisciplineModel discipline;
  const _JournalListPage({required this.discipline});

  @override
  ConsumerState<_JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends ConsumerState<_JournalListPage> {
  String _search = '';
  bool _currentOnly = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(disciplinesViewModelProvider.notifier)
          .getJournalsFor(widget.discipline.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(disciplinesViewModelProvider);
    final allJournals =
        vmState.journals[widget.discipline.id] ?? <JournalModel>[];
    final filtered = allJournals
        .where((j) =>
            j.groupName.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Електронний журнал'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Назад'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMid,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'Журнали - ${widget.discipline.fullName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Пошук за групою...',
                prefixIcon: Icon(Icons.search,
                    color: AppTheme.textMid, size: 18),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 16, 4),
            child: Row(children: [
              Checkbox(
                value: _currentOnly,
                onChanged: (v) =>
                    setState(() => _currentOnly = v ?? true),
                activeColor: AppTheme.primary,
              ),
              Expanded(
                child: Text(
                  'Показувати поточні семестри'
                  '  (${filtered.length} з ${allJournals.length} журналів)',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textDark),
                ),
              ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(disciplinesViewModelProvider.notifier)
                  .getJournalsFor(widget.discipline.id),
              child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == filtered.length) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(children: [
                      Icon(Icons.add,
                          size: 32, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => CreateJournalDialog(
                            disciplineId: widget.discipline.id,
                            disciplineName: widget.discipline.fullName,
                            onCreated: () => ref
                                .read(disciplinesViewModelProvider.notifier)
                                .getJournalsFor(widget.discipline.id),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Створити журнал'),
                      ),
                    ]),
                  );
                }

                final j = filtered[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                        const Icon(Icons.menu_book_outlined,
                            color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${j.groupName} навчальна група',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textDark),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AppTheme.textMid, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => showEditJournalSheet(
                            context,
                            journalId: j.id,
                            driveLink: j.driveLink,
                            meetLink: j.meetLink,
                            moodleLink: j.moodleLink,
                            onUpdated: () => ref
                                .read(disciplinesViewModelProvider.notifier)
                                .getJournalsFor(widget.discipline.id),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text('(${j.disciplineName})',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMid)),
                      const SizedBox(height: 4),
                      Text(
                        'Семестр: ${j.semester}'
                        '${j.startDate != null ? ' (${j.startDate} - ${j.endDate}' : ''}'
                        '${j.academicYear != null ? ' | ${j.academicYear})' : (j.startDate != null ? ')' : '')}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMid),
                      ),
                      if (j.hasDrive || j.hasMeet || j.hasMoodle) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, children: [
                          if (j.hasDrive)
                            _ResourceBadge(
                                icon: Icons.folder,
                                label: 'Drive',
                                bg: const Color(0xFFE8F5E9),
                                fg: const Color(0xFF2E7D32)),
                          if (j.hasMeet)
                            _ResourceBadge(
                                icon: Icons.videocam,
                                label: 'Meet',
                                bg: const Color(0xFFE3F2FD),
                                fg: const Color(0xFF1565C0)),
                          if (j.hasMoodle)
                            _ResourceBadge(
                                icon: Icons.school,
                                label: 'Moodle',
                                bg: const Color(0xFFFFF3E0),
                                fg: const Color(0xFFE65100)),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GradeJournalPage(
                                groupId: j.groupId != 0 ? j.groupId : null,
                                disciplineId: j.disciplineId != 0
                                    ? j.disciplineId.toString()
                                    : widget.discipline.id.toString(),
                                semesterId: j.semesterId != 0
                                    ? j.semesterId.toString()
                                    : null,
                                disciplineShortName:
                                    widget.discipline.shortName,
                                groupName:
                                    '${j.groupName} навчальна група',
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Журнал'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  const _ResourceBadge(
      {required this.icon, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: fg, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _AddDisciplineCard extends StatelessWidget {
  final VoidCallback? onCreated;
  const _AddDisciplineCard({this.onCreated});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showAddDisciplineSheet(context, onCreated: onCreated),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          const Text('Додати дисципліну',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Створити нову навчальну дисципліну',
              style: TextStyle(color: AppTheme.textMid, fontSize: 12)),
        ],
      ),
    ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String search;
  const _EmptyState({required this.search});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            search.isNotEmpty ? 'Нічого не знайдено' : 'Немає дисциплін',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
