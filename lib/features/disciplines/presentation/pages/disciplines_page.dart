// lib/features/disciplines/presentation/pages/disciplines_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../grades/presentation/pages/grade_journal_page.dart';
import 'discipline_management_page.dart';

// ── Mock journals per discipline ───────────────────────────────────────────────
// journalId, groupId, groupName, disciplineName, semester, startDate, endDate, year
const _disciplineJournals = <int, List<Map<String, dynamic>>>{
  1: [ // РПЗ
    {'journalId': 1, 'groupId': 221, 'groupName': '221', 'disc': 'Розробка програмного забезпечення для мобільних пристроїв', 'semester': 8, 'start': '03.01.2026', 'end': '26.06.2026', 'year': '2025-2026', 'hasDrive': true, 'hasMeet': true, 'hasMoodle': true},
    {'journalId': 2, 'groupId': 222, 'groupName': '222', 'disc': 'Розробка програмного забезпечення для мобільних пристроїв', 'semester': 8, 'start': '03.01.2026', 'end': '26.06.2026', 'year': '2025-2026', 'hasDrive': true, 'hasMeet': false, 'hasMoodle': true},
  ],
  2: [ // ПІС
    {'journalId': 3, 'groupId': 221, 'groupName': '221', 'disc': 'Проєктування інформаційних систем', 'semester': 6, 'start': '03.01.2026', 'end': '26.06.2026', 'year': '2025-2026', 'hasDrive': false, 'hasMeet': true, 'hasMoodle': true},
    {'journalId': 4, 'groupId': 231, 'groupName': '231', 'disc': 'Проєктування інформаційних систем', 'semester': 6, 'start': '03.01.2026', 'end': '26.06.2026', 'year': '2025-2026', 'hasDrive': true, 'hasMeet': false, 'hasMoodle': false},
    {'journalId': 5, 'groupId': 232, 'groupName': '232', 'disc': 'Проєктування інформаційних систем', 'semester': 6, 'start': '03.01.2026', 'end': '26.06.2026', 'year': '2025-2026', 'hasDrive': false, 'hasMeet': false, 'hasMoodle': true},
  ],
  3: [ // ДМ
    {'journalId': 6, 'groupId': 241, 'groupName': '241', 'disc': 'Дискретна математика', 'semester': 4, 'start': '29.01.2026', 'end': '29.08.2026', 'year': '2025-2026', 'hasDrive': true, 'hasMeet': true, 'hasMoodle': true},
    {'journalId': 7, 'groupId': 242, 'groupName': '242', 'disc': 'Дискретна математика', 'semester': 4, 'start': '29.01.2026', 'end': '29.08.2026', 'year': '2025-2026', 'hasDrive': true, 'hasMeet': true, 'hasMoodle': true},
    {'journalId': 8, 'groupId': 243, 'groupName': '243', 'disc': 'Дискретна математика', 'semester': 4, 'start': '29.01.2026', 'end': '29.08.2026', 'year': '2025-2026', 'hasDrive': false, 'hasMeet': false, 'hasMoodle': false},
  ],
  4: [ // ТСА
    {'journalId': 9, 'groupId': 221, 'groupName': '221', 'disc': 'Технології системного адміністрування', 'semester': 4, 'start': '29.01.2026', 'end': '29.08.2026', 'year': '2025-2026', 'hasDrive': false, 'hasMeet': true, 'hasMoodle': true},
    {'journalId': 10, 'groupId': 222, 'groupName': '222', 'disc': 'Технології системного адміністрування', 'semester': 4, 'start': '29.01.2026', 'end': '29.08.2026', 'year': '2025-2026', 'hasDrive': true, 'hasMeet': false, 'hasMoodle': true},
  ],
  5: [ // МАР
    {'journalId': 11, 'groupId': 251, 'groupName': '251', 'disc': 'Методики автоматизованого розгортання IT-інфраструктури', 'semester': 2, 'start': '01.09.2025', 'end': '31.01.2026', 'year': '2025-2026', 'hasDrive': false, 'hasMeet': false, 'hasMoodle': false},
  ],
};

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
    final role = ref.watch(authViewModelProvider.select((s) => s.role ?? ''));
    final disciplines = MockDataProvider.disciplines
        .where((d) =>
            d.fullName.toLowerCase().contains(_search.toLowerCase()) ||
            (d.shortName?.toLowerCase().contains(_search.toLowerCase()) ?? false))
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
          Expanded(
            child: disciplines.isEmpty
                ? _EmptyState(search: _search)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: disciplines.length,
                    itemBuilder: (context, i) => _DisciplineCard(
                      discipline: disciplines[i],
                      isCadet: _isCadet(role),
                      cadetGroupId: 221, // mock cadet group
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Картка дисципліни ─────────────────────────────────────────────────────────

class _DisciplineCard extends StatelessWidget {
  final MockDiscipline discipline;
  final bool isCadet;
  final int cadetGroupId;

  const _DisciplineCard({
    required this.discipline,
    required this.isCadet,
    required this.cadetGroupId,
  });

  @override
  Widget build(BuildContext context) {
    final journals = _disciplineJournals[discipline.id] ?? [];

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
                      value: '${journals.length}',
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
                  if (isCadet) {
                    // Курсант — одразу журнал своєї групи
                    final journal = journals.firstWhere(
                      (j) => j['groupId'] == cadetGroupId,
                      orElse: () => journals.isNotEmpty ? journals[0] : {},
                    );
                    if (journal.isNotEmpty) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => GradeJournalPage(
                          disciplineId: discipline.id.toString(),
                          groupName: '${journal['groupName']} навчальна група',
                          semesterId: journal['semester'].toString(),
                        ),
                      ));
                    }
                  } else {
                    // Викладач/адмін — список журналів по групах
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

class _JournalListPage extends StatefulWidget {
  final MockDiscipline discipline;
  const _JournalListPage({required this.discipline});

  @override
  State<_JournalListPage> createState() => _JournalListPageState();
}

class _JournalListPageState extends State<_JournalListPage> {
  String _search = '';
  bool _currentOnly = true;

  @override
  Widget build(BuildContext context) {
    final journals = _disciplineJournals[widget.discipline.id] ?? [];
    final filtered = journals
        .where((j) => j['groupName'].toString().toLowerCase()
            .contains(_search.toLowerCase()))
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
          // Back
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
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Пошук за групою...',
                prefixIcon: Icon(Icons.search,
                    color: AppTheme.textMid, size: 18),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          // Checkbox
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
                  'Показувати поточні семестри (${filtered.map((j) => j['semester']).toSet().join(', ')})'
                  '  (${filtered.length} з ${journals.length} журналів)',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textDark),
                ),
              ),
            ]),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == filtered.length) {
                  // Кнопка "Створити журнал"
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
                        onPressed: () {},
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
                            '${j['groupName']} навчальна група',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textDark),
                          ),
                        ),
                        Icon(Icons.star_border,
                            color: Colors.grey.shade400, size: 20),
                      ]),
                      const SizedBox(height: 6),
                      Text('(${j['disc']})',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMid)),
                      const SizedBox(height: 4),
                      Text(
                        'Семестр: ${j['semester']} (${j['start']} - ${j['end']} | ${j['year']})',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMid),
                      ),
                      // Drive/Meet/Moodle badges
                      if (j['hasDrive'] == true || j['hasMeet'] == true || j['hasMoodle'] == true) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, children: [
                          if (j['hasDrive'] == true)
                            _ResourceBadge(icon: Icons.folder, label: 'Drive',
                                bg: const Color(0xFFE8F5E9), fg: const Color(0xFF2E7D32)),
                          if (j['hasMeet'] == true)
                            _ResourceBadge(icon: Icons.videocam, label: 'Meet',
                                bg: const Color(0xFFE3F2FD), fg: const Color(0xFF1565C0)),
                          if (j['hasMoodle'] == true)
                            _ResourceBadge(icon: Icons.school, label: 'Moodle',
                                bg: const Color(0xFFFFF3E0), fg: const Color(0xFFE65100)),
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
                                disciplineId: widget.discipline.id.toString(),
                                groupName: '${j['groupName']} навчальна група',
                                semesterId: j['semester'].toString(),
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
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
