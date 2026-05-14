// lib/features/disciplines/presentation/pages/disciplines_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../grades/presentation/pages/grade_journal_page.dart';
import 'discipline_management_page.dart';
import '../../../../shared/widgets/add_discipline_sheet.dart';

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
                    itemCount: disciplines.length + (_canManage(role) ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_canManage(role) && i == disciplines.length) {
                        return const _AddDisciplineCard();
                      }
                      return _DisciplineCard(
                        discipline: disciplines[i],
                        isCadet: _isCadet(role),
                        cadetGroupId: 221,
                      );
                    },
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
                          groupName: '\${journal[\'groupName\']} навчальна група',
                          semesterId: journal['semester'].toString(),
                          readOnly: true,
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

  static const _groups = <Map<String, dynamic>>[
    {'id': 221, 'name': '221', 'specialty': "Комп'ютерні науки"},
    {'id': 222, 'name': '222', 'specialty': "Комп'ютерні науки"},
    {'id': 231, 'name': '231', 'specialty': 'ІСТ'},
    {'id': 241, 'name': '241', 'specialty': 'Електроніка'},
    {'id': 321, 'name': '321', 'specialty': "Комп'ютерні науки"},
    {'id': 421, 'name': '421', 'specialty': "Комп'ютерні науки"},
  ];

  static const _semesters = [
    'Семестр 1 (бакалаври) (2022-2023)',
    'Семестр 2 (бакалаври) (2022-2023)',
    'Семестр 3 (бакалаври) (2023-2024)',
    'Семестр 4 (бакалаври) (2023-2024)',
    'Семестр 5 (бакалаври) (2024-2025)',
    'Семестр 6 (бакалаври) (2024-2025)',
    'Семестр 7 (бакалаври) (2025-2026)',
    'Семестр 8 (бакалаври) (2025-2026)',
  ];

  void _showCreateJournalDialog(BuildContext context) {
    Map<String, dynamic>? selectedGroup;
    final semSelected = List<bool>.filled(_semesters.length, false);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  const Expanded(
                    child: Text('Створити новий журнал',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppTheme.textDark)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ]),
                const Divider(height: 20),

                // Дисципліна (фіксована)
                const Text('Дисципліна',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMid)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.surface,
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        widget.discipline.fullName,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.lock_outline,
                        color: AppTheme.textLight, size: 16),
                  ]),
                ),
                const SizedBox(height: 14),

                // Група
                const Text('Група *',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMid)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: selectedGroup == null
                            ? AppTheme.border
                            : AppTheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedGroup,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Оберіть групу',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textMid)),
                    items: _groups
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                '${g['name']} (${g['specialty']})',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedGroup = val),
                  ),
                ),
                const SizedBox(height: 14),

                // Семестри
                const Text('Семестри',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMid)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFFBBF24)
                            .withOpacity(0.4)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Якщо дисципліна продовжується в іншому семестрі та закінчується заліком у іншому — обирайте відповідні семестри.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _semesters.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) => CheckboxListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 12),
                        title: Text(_semesters[i],
                            style:
                                const TextStyle(fontSize: 13)),
                        value: semSelected[i],
                        onChanged: (val) => setDialogState(
                            () => semSelected[i] = val ?? false),
                        controlAffinity:
                            ListTileControlAffinity.leading,
                        activeColor: AppTheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF374151),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Скасувати'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedGroup != null
                          ? () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content:
                                    const Text('Журнал створено'),
                                backgroundColor:
                                    const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10)),
                              ));
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.border,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Створити журнал'),
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
                        onPressed: () => _showCreateJournalDialog(context),
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

class _AddDisciplineCard extends StatelessWidget {
  const _AddDisciplineCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showAddDisciplineSheet(context),
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
