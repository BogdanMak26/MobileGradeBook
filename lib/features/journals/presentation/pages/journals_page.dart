// lib/features/journals/presentation/pages/journals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../../features/disciplines/data/models/discipline_model.dart';
import '../../../../features/disciplines/data/repositories/disciplines_repository.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/add_discipline_sheet.dart';
import '../../../../shared/widgets/create_journal_dialog.dart';
import '../../../grades/presentation/pages/grade_journal_page.dart';


// ── Main page ────────────────────────────────────────────────────────────────

class JournalsPage extends StatefulWidget {
  const JournalsPage({super.key});

  @override
  State<JournalsPage> createState() => _JournalsPageState();
}

class _JournalsPageState extends State<JournalsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Електронний журнал'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMid,
              tabs: [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.school_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Кафедри'),
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.people_outline, size: 16),
                  SizedBox(width: 6),
                  Text('Курси'),
                ])),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _KafedrasTab(),
                _CoursesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Кафедри → Дисципліни кафедри ────────────────────────────────────────────

class _KafedrasTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_KafedrasTab> createState() => _KafedrasTabState();
}

class _KafedrasTabState extends ConsumerState<_KafedrasTab> {
  List<Map<String, dynamic>> _kafedras = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ref.read(kafedrasRepositoryProvider).getKafedras();
      setState(() {
        _kafedras = raw.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMid)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Повторити')),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kafedras.length,
      itemBuilder: (context, i) {
        final k = _kafedras[i];
        final kafedraId = k['id'] as int?;
        final name = k['name']?.toString() ?? '—';
        final number = k['number'] ?? k['kafedraNumber'];
        final subtitle = number != null ? 'Кафедра №$number' : '';
        return _CardTile(
          icon: Icons.school,
          title: name,
          subtitle: subtitle,
          onTap: () {
            if (kafedraId == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _KafedraDisciplinesPage(
                  kafedraId: kafedraId,
                  kafedraName: name,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Курси → Групи → Дисципліни групи → Журнал ───────────────────────────────

class _CoursesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<_CoursesTab> {
  // year → groups
  Map<int, List<Map<String, dynamic>>> _byYear = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ref.read(groupsRepositoryProvider).getGroups();
      final grouped = <int, List<Map<String, dynamic>>>{};
      for (final item in raw) {
        final g = item as Map<String, dynamic>;
        final year = g['yearStart'] as int? ??
            g['enrollmentYear'] as int? ??
            g['year'] as int? ?? 0;
        grouped.putIfAbsent(year, () => []).add(g);
      }
      // Sort years descending (newest first)
      final sorted = Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
      );
      setState(() { _byYear = sorted; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMid)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Повторити')),
          ],
        ),
      );
    }

    final entries = _byYear.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final year = entries[i].key;
        final groups = entries[i].value;
        // Collect unique specialties
        final specs = groups
            .map((g) => g['specialty']?.toString() ??
                g['specialization']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
        final courseName = 'Набір $year';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(courseName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark)),
              ),
              const Icon(Icons.people_outline, color: AppTheme.primary),
            ]),
            if (specs.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Спеціальності:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: specs.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(s,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textDark)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              _InfoBadge(label: 'Рік вступу', value: '$year'),
              const SizedBox(width: 8),
              _InfoBadge(label: 'Груп', value: '${groups.length}'),
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _GroupsPage(
                      yearStart: year,
                      courseName: courseName,
                      groups: groups,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryDark,
                  side: const BorderSide(color: AppTheme.primaryDark),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                child: const Text('Переглянути'),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

// ── Список груп курсу ────────────────────────────────────────────────────────

class _GroupsPage extends StatefulWidget {
  final int yearStart;
  final String courseName;
  final List<Map<String, dynamic>> groups;
  const _GroupsPage({
    required this.yearStart,
    required this.courseName,
    required this.groups,
  });

  @override
  State<_GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<_GroupsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.groups
        .where((g) => (g['name']?.toString() ?? '').toLowerCase()
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
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('До списку курсів'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMid,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text('Групи',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Пошук груп за назвою...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textMid, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final g = filtered[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(g['name']?.toString() ?? '—',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primary)),
                        const Spacer(),
                        const Icon(Icons.people_outline, color: AppTheme.primary),
                      ]),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Спеціальність:', value: g['specialty']?.toString() ?? g['specialization']?.toString() ?? '—'),
                      const SizedBox(height: 4),
                      _InfoRow(label: 'Ступінь:', value: g['degree']?.toString() ?? '—'),
                      const SizedBox(height: 10),
                      Row(children: [
                        _InfoBadge(label: 'Рік вступу', value: (g['yearStart'] ?? g['enrollmentYear'] ?? g['year'])?.toString() ?? '—'),
                        const SizedBox(width: 8),
                        _InfoBadge(label: 'Тип', value: g['formOfStudy']?.toString() ?? g['type']?.toString() ?? '—'),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            final groupId = g['id'] as int?;
                            if (groupId == null) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _GroupDisciplinesPage(
                                  groupId: groupId,
                                  groupName: g['name']?.toString() ?? '—',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryDark,
                            side: const BorderSide(color: AppTheme.primaryDark),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          child: const Text('Переглянути'),
                        ),
                      ]),
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

// ── Дисципліни конкретної групи ──────────────────────────────────────────────

class _GroupDisciplinesPage extends ConsumerStatefulWidget {
  final int groupId;
  final String groupName;
  const _GroupDisciplinesPage({required this.groupId, required this.groupName});

  @override
  ConsumerState<_GroupDisciplinesPage> createState() => _GroupDisciplinesPageState();
}

class _GroupDisciplinesPageState extends ConsumerState<_GroupDisciplinesPage> {
  String _search = '';
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ref.read(journalsRepositoryProvider).getJournals(groupId: widget.groupId);
      setState(() {
        _journals = raw.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  void _showCreateJournalForGroupDialog(BuildContext context) {
    // Унікальні дисципліни з журналів
    final seen = <int>{};
    final groupDisciplines = <Map<String, dynamic>>[];
    for (final j in _journals) {
      final dId = j['disciplineId'] as int? ?? 0;
      if (seen.add(dId)) {
        groupDisciplines.add({'id': dId, 'name': j['disciplineName'] ?? '', 'short': j['disciplineName'] ?? ''});
      }
    }

    // 8 семестрів (4 роки) — загальна форма
    final semesters = <String>[];
    for (int i = 0; i < 8; i++) {
      semesters.add('Семестр ${i + 1}');
    }
    final semSelected = List<bool>.filled(semesters.length, false);

    Map<String, dynamic>? selectedDisc;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Заголовок
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

                // Група (фіксована)
                const Text('Група',
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
                        '${widget.groupName} навчальна група',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textDark),
                      ),
                    ),
                    const Icon(Icons.lock_outline,
                        color: AppTheme.textLight, size: 16),
                  ]),
                ),
                const SizedBox(height: 14),

                // Дисципліна
                const Text('Дисципліна *',
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
                        color: selectedDisc == null
                            ? AppTheme.border
                            : AppTheme.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<Map<String, dynamic>>(
                    value: selectedDisc,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Оберіть дисципліну',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textMid)),
                    items: groupDisciplines
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                '${d['short']} — ${d['name']}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedDisc = val),
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
                        color:
                            const Color(0xFFFBBF24).withOpacity(0.4)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          'Якщо дисципліна продовжується в іншому семестрі та закінчується заліком у іншому — обирайте відповідні семестри.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: semesters.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) => CheckboxListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        title: Text(semesters[i],
                            style: const TextStyle(fontSize: 13)),
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
                      onPressed: selectedDisc != null
                          ? () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: const Text('Журнал створено'),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
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
    final filtered = _journals
        .where((d) =>
            (d['disciplineName'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Електронний журнал'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text('Помилка: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textMid)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Повторити')),
                    ],
                  ),
                )
              : Column(
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Дисципліни групи ${widget.groupName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Пошук дисциплін...',
                    prefixIcon: Icon(Icons.search,
                        color: AppTheme.textMid, size: 18),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 18),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length + 2,
                    itemBuilder: (context, i) {
                      if (i == filtered.length) {
                        return _CreateJournalCard(
                          onTap: () =>
                              _showCreateJournalForGroupDialog(context),
                        );
                      }
                      if (i == filtered.length + 1) {
                        return const _AddDisciplineCard();
                      }
                      final d = filtered[i];
                      // API returns nested semesters array and journalId (not id)
                      final dSemesters = d['semesters'] as List<dynamic>?;
                      final dFirstSem = dSemesters?.isNotEmpty == true
                          ? dSemesters!.first as Map<String, dynamic>?
                          : null;
                      final dSemNum = dFirstSem?['semesterNumber'] as int?
                          ?? d['semester'] as int?;
                      final dJournalId = d['journalId'] as int? ?? d['id'] as int?;
                      final dGroupId = d['groupId'] as int?;
                      final dDisciplineId = d['disciplineId'] as int?;
                      final dSemesterId = dFirstSem?['semesterId'] as int?;
                      final dDiscName = d['disciplineFullName']?.toString()
                          ?? d['disciplineName']?.toString() ?? '—';
                      final dDiscShort = d['disciplineShortName']?.toString();
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
                                    Text('Семестр ${dSemNum ?? '—'}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary)),
                                    const SizedBox(height: 2),
                                    Text(dDiscName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: AppTheme.textDark)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.school,
                                  color: AppTheme.primary, size: 22),
                            ]),
                            const SizedBox(height: 12),
                            Row(children: [
                              _InfoBadge(
                                  label: 'ID журналу',
                                  value: '${dJournalId ?? '—'}'),
                              const Spacer(),
                              OutlinedButton(
                                onPressed: (dGroupId == null || dDisciplineId == null || dSemesterId == null) ? null : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GradeJournalPage(
                                      groupId: dGroupId,
                                      disciplineId: dDisciplineId.toString(),
                                      semesterId: dSemesterId.toString(),
                                      disciplineShortName: dDiscShort ?? dDiscName,
                                      groupName: d['groupName']?.toString()
                                          ?? '${widget.groupName} навчальна група',
                                    ),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryDark,
                                  side: const BorderSide(color: AppTheme.primaryDark),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Переглянути',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ]),
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

// ── Дисципліни кафедри ───────────────────────────────────────────────────────

class _KafedraDisciplinesPage extends ConsumerStatefulWidget {
  final int kafedraId;
  final String kafedraName;
  const _KafedraDisciplinesPage(
      {required this.kafedraId, required this.kafedraName});

  @override
  ConsumerState<_KafedraDisciplinesPage> createState() =>
      _KafedraDisciplinesPageState();
}

class _KafedraDisciplinesPageState
    extends ConsumerState<_KafedraDisciplinesPage> {
  String _search = '';
  List<DisciplineModel> _disciplines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ref
          .read(disciplinesRepositoryProvider)
          .getAllDisciplines();
      setState(() {
        _disciplines = raw
            .where((d) => d.kafedraId == widget.kafedraId)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Електронний журнал'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Container(height: 3, color: AppTheme.primary),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = _disciplines
        .where((d) =>
            d.fullName.toLowerCase().contains(_search.toLowerCase()) ||
            (d.shortName ?? '').toLowerCase().contains(_search.toLowerCase()))
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 18),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == filtered.length) return _AddDisciplineCard(
                  onTap: () => showAddDisciplineSheet(
                    context,
                    kafedraId: widget.kafedraId,
                    onCreated: _load,
                  ),
                );
                final d = filtered[i];
                final discName = d.fullName;
                final discShort = d.shortName ?? '';
                return _CardTile(
                  icon: Icons.school,
                  title: discShort.isNotEmpty ? '$discShort — $discName' : discName,
                  subtitle: widget.kafedraName,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _DisciplineJournalListPage(
                        disciplineId: d.id,
                        disciplineName: discName,
                      ),
                    ),
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

// ── Список журналів дисципліни (для кафедри) ─────────────────────────────────

class _DisciplineJournalListPage extends ConsumerStatefulWidget {
  final int disciplineId;
  final String disciplineName;
  const _DisciplineJournalListPage(
      {required this.disciplineId, required this.disciplineName});

  @override
  ConsumerState<_DisciplineJournalListPage> createState() =>
      _DisciplineJournalListPageState();
}

class _DisciplineJournalListPageState
    extends ConsumerState<_DisciplineJournalListPage> {
  String _search = '';
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await ref.read(journalsRepositoryProvider)
          .getJournals(disciplineId: widget.disciplineId);
      setState(() {
        _journals = raw.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _journals
        .where((j) => (j['groupName'] ?? '').toString().toLowerCase()
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
              'Журнали - ${widget.disciplineName}',
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
                prefixIcon: Icon(Icons.search, color: AppTheme.textMid, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == filtered.length) {
                  return _CreateJournalCard(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => CreateJournalDialog(
                        disciplineId: widget.disciplineId,
                        disciplineName: widget.disciplineName,
                        onCreated: _load,
                      ),
                    ),
                  );
                }
                final j = filtered[i];
                final jSemesters = j['semesters'] as List<dynamic>?;
                final jFirstSem = jSemesters?.isNotEmpty == true
                    ? jSemesters!.first as Map<String, dynamic>?
                    : null;
                final jSemNum = jFirstSem?['semesterNumber'] as int?
                    ?? j['semester'] as int?;
                final jGroupId = j['groupId'] as int?;
                final jSemesterId = jFirstSem?['semesterId'] as int?;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
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
                            '${j['groupName'] ?? '—'} навчальна група',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textDark),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('Семестр: ${jSemNum ?? '—'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMid)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: (jGroupId == null || jSemesterId == null) ? null : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GradeJournalPage(
                                groupId: jGroupId,
                                disciplineId: widget.disciplineId.toString(),
                                semesterId: jSemesterId.toString(),
                                disciplineShortName: widget.disciplineName,
                                groupName: '${j['groupName'] ?? ''} навчальна група',
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _AddDisciplineCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddDisciplineCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => showAddDisciplineSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
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

class _CardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _CardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.textDark)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
        ),
        trailing: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryDark,
            side: const BorderSide(color: AppTheme.primaryDark),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          child: const Text('Переглянути'),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$label: ',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
          TextSpan(text: value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
        ]),
      ),
    );
  }
}

class _CreateJournalCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateJournalCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('Створити журнал',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark),
            overflow: TextOverflow.ellipsis),
      ),
    ]);
  }
}
