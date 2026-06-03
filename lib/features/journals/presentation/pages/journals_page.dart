// lib/features/journals/presentation/pages/journals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/local/local_cache.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/disciplines/data/models/discipline_model.dart';
import '../../../../features/disciplines/data/models/journal_model.dart';
import '../../../../features/disciplines/data/repositories/disciplines_repository.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/add_discipline_sheet.dart';
import '../../../../shared/widgets/create_journal_dialog.dart'
    show CreateJournalDialog, showEditJournalSheet;
import '../../../grades/presentation/pages/grade_journal_page.dart';


// ── Main page ────────────────────────────────────────────────────────────────

class JournalsPage extends ConsumerStatefulWidget {
  const JournalsPage({super.key});

  @override
  ConsumerState<JournalsPage> createState() => _JournalsPageState();
}

class _JournalsPageState extends ConsumerState<JournalsPage>
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
    final auth = ref.watch(authViewModelProvider);
    final isDeptHead = auth.role == UserRole.departmentHead;

    if (isDeptHead) {
      final kafedraId = auth.kafedraId;
      final kafedraName = auth.kafedraName ?? 'Кафедра';
      if (kafedraId == null) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Електронний журнал'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(height: 3, color: AppTheme.primary),
            ),
          ),
          body: const Center(child: Text('Не вдалося визначити кафедру')),
        );
      }
      return _KafedraDisciplinesPage(
        kafedraId: kafedraId,
        kafedraName: kafedraName,
        isRoot: true,
      );
    }

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
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);

    const cacheKey = 'kafedras_list';
    final cachedRaw = cache.get<List<dynamic>>(cacheKey);
    if (cachedRaw != null) {
      setState(() { _kafedras = cachedRaw.cast<Map<String, dynamic>>(); });
    }

    if (!network.isOnline) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final raw = await ref.read(kafedrasRepositoryProvider).getKafedras();
      await cache.set(cacheKey, raw);
      setState(() {
        _kafedras = raw.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (cachedRaw == null) _error = e.toString();
      });
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}

// ── Курси → Групи → Дисципліни групи → Журнал ───────────────────────────────

class _CoursesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<_CoursesTab> {
  Map<String, List<Map<String, dynamic>>> _byCourse = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);

    const cacheKey = 'groups_list';
    List<dynamic>? cachedRaw = cache.get<List<dynamic>>(cacheKey);
    if (cachedRaw != null) {
      _applyGroups(cachedRaw);
    }

    if (!network.isOnline) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final raw = await ref.read(groupsRepositoryProvider).getGroups();
      await cache.set(cacheKey, raw);
      _applyGroups(raw);
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (cachedRaw == null) _error = e.toString();
      });
    }
  }

  void _applyGroups(List<dynamic> raw) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in raw) {
      final g = item as Map<String, dynamic>;
      final course = g['courseNumber'] as int? ?? 0;
      final degree = (g['educationDegree'] as String?) ?? 'BACHELOR';
      final key = '${course}_$degree';
      grouped.putIfAbsent(key, () => []).add(g);
    }
    final sorted = Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) {
          final aParts = a.key.split('_');
          final bParts = b.key.split('_');
          final aDeg = aParts.sublist(1).join('_');
          final bDeg = bParts.sublist(1).join('_');
          final aC = int.tryParse(aParts[0]) ?? 0;
          final bC = int.tryParse(bParts[0]) ?? 0;
          if (aDeg != bDeg) {
            if (aDeg == 'MASTER') return 1;
            if (bDeg == 'MASTER') return -1;
          }
          return aC.compareTo(bC);
        }),
    );
    setState(() { _byCourse = sorted; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMid)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Повторити')),
        ]),
      );
    }

    final entries = _byCourse.entries.toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final key = entries[i].key;
        final groups = entries[i].value;
        final kParts = key.split('_');
        final courseNum = int.tryParse(kParts[0]) ?? 0;
        final degree = kParts.sublist(1).join('_');
        final isMaster = degree == 'MASTER';
        final courseLabel = isMaster ? '${courseNum}м' : '$courseNum';
        final courseName = isMaster
            ? '${courseNum}м курс (Магістр)'
            : (courseNum > 0 ? '$courseNum курс' : 'Інші групи');
        final cadetCount = groups.fold<int>(0, (sum, g) {
          final cadets = g['cadets'] as List?;
          return sum + (cadets?.length ?? 0);
        });

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _GroupsPage(
                courseNumber: courseNum,
                courseName: courseName,
                groups: groups,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(courseLabel,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(courseName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _InfoBadge(label: 'Груп', value: '${groups.length}'),
                    const SizedBox(width: 6),
                    if (cadetCount > 0)
                      _InfoBadge(label: 'Курсантів', value: '$cadetCount'),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textMid),
            ]),
          ),
        );
      },
      ),
    );
  }
}

// ── Список груп курсу ────────────────────────────────────────────────────────

class _GroupsPage extends StatefulWidget {
  final int courseNumber;
  final String courseName;
  final List<Map<String, dynamic>> groups;
  const _GroupsPage({
    required this.courseNumber,
    required this.courseName,
    required this.groups,
  });

  @override
  State<_GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<_GroupsPage> {
  String _search = '';

  static String _degreeLabel(String? raw) => switch (raw) {
    'BACHELOR' => 'Бакалавр',
    'MASTER'   => 'Магістр',
    'JUNIOR_SPECIALIST' => 'Молодший спеціаліст',
    _ => raw ?? '—',
  };

  static String _typeLabel(String? raw) => switch (raw) {
    'FULL_TIME'  => 'Денна',
    'PART_TIME'  => 'Заочна',
    'EXTRAMURAL' => 'Екстернат',
    _ => raw ?? '—',
  };

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
            child: Text(
              'Групи — ${widget.courseName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Пошук групи за назвою...',
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
                final groupId = g['id'] as int?;
                final groupName = g['name']?.toString() ?? '—';
                final cadets = g['cadets'] as List?;
                final cadetCount = cadets?.length ?? 0;
                final degree = _degreeLabel(g['educationDegree'] as String?);
                final type = _typeLabel(g['type'] as String?);
                final rawEnrollYear = g['enrollmentYear'];
                final enrollYear = rawEnrollYear is int
                    ? rawEnrollYear
                    : int.tryParse(rawEnrollYear?.toString() ?? '');

                return GestureDetector(
                  onTap: () {
                    if (groupId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDisciplinesPage(
                          groupId: groupId,
                          groupName: groupName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.people_outline,
                            color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(groupName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: AppTheme.primary)),
                            const SizedBox(height: 4),
                            Row(children: [
                              _InfoBadge(label: 'Ступінь', value: degree),
                              const SizedBox(width: 6),
                              _InfoBadge(label: 'Форма', value: type),
                            ]),
                            if (enrollYear != null || cadetCount > 0) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                if (enrollYear != null)
                                  _InfoBadge(label: 'Набір', value: '$enrollYear'),
                                if (enrollYear != null && cadetCount > 0)
                                  const SizedBox(width: 6),
                                if (cadetCount > 0)
                                  _InfoBadge(label: 'Курсантів', value: '$cadetCount'),
                              ]),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textMid),
                    ]),
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

class GroupDisciplinesPage extends ConsumerStatefulWidget {
  final int groupId;
  final String groupName;
  const GroupDisciplinesPage({super.key, required this.groupId, required this.groupName});

  @override
  ConsumerState<GroupDisciplinesPage> createState() => _GroupDisciplinesPageState();
}

class _GroupDisciplinesPageState extends ConsumerState<GroupDisciplinesPage> {
  String _search = '';
  List<JournalModel> _journals = [];
  Map<String, int> _discIdByName = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);

    final journalsCacheKey = 'group_journals_${widget.groupId}';
    final discsCacheKey = 'all_disciplines';
    final cachedJournals = cache.get<List<dynamic>>(journalsCacheKey);
    final cachedDiscs = cache.get<List<dynamic>>(discsCacheKey);

    if (cachedJournals != null) {
      final journals = cachedJournals
          .map((e) => JournalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final map = <String, int>{};
      if (cachedDiscs != null) {
        for (final e in cachedDiscs) {
          final d = DisciplineModel.fromJson(e as Map<String, dynamic>);
          map[d.fullName] = d.id;
          if (d.shortName != null && d.shortName!.isNotEmpty) map[d.shortName!] = d.id;
        }
      }
      setState(() { _journals = journals; _discIdByName = map; });
    }

    if (!network.isOnline) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final repo = ref.read(disciplinesRepositoryProvider);
      final journals = await repo.getGroupJournals(widget.groupId);
      final allDiscs = await repo.getAllDisciplines();
      await cache.set(journalsCacheKey, journals.map((j) => j.toJson()).toList());
      await cache.set(discsCacheKey, allDiscs.map((d) => d.toJson()).toList());
      final map = <String, int>{};
      for (final d in allDiscs) {
        map[d.fullName] = d.id;
        if (d.shortName != null && d.shortName!.isNotEmpty) map[d.shortName!] = d.id;
      }
      setState(() { _journals = journals; _discIdByName = map; _isLoading = false; });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (cachedJournals == null) _error = e.toString();
      });
    }
  }

  bool _isActive(JournalModel j) {
    final endStr = j.endDate;
    if (endStr == null || endStr.isEmpty) return true;
    try {
      final end = DateTime.parse(endStr);
      final today = DateTime.now();
      return !end.isBefore(DateTime(today.year, today.month, today.day));
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _journals
        .where((j) => j.disciplineName.toLowerCase().contains(_search.toLowerCase()))
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
            label: const Text('До списку груп'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMid,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text('Дисципліни — ${widget.groupName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text('Журналів: ${_journals.length}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Пошук за дисципліною...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textMid, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, i) {
                      if (i == filtered.length) {
                        return _AddDisciplineCard(
                          onTap: () => showAddDisciplineSheet(
                            context,
                            onCreated: _load,
                          ),
                        );
                      }
                      final j = filtered[i];
                      final jGroupId = j.groupId != 0 ? j.groupId : widget.groupId;
                      final jSemesterId = j.semesterId != 0 ? j.semesterId : null;
                      final jDisciplineId = j.disciplineId != 0
                          ? j.disciplineId
                          : (_discIdByName[j.disciplineName] ?? 0);
                      final isArchived = !_isActive(j);

                      String semLabel = 'Семестр: ${j.semester == 0 ? '—' : j.semester}';
                      if (j.startDate != null || j.endDate != null) {
                        semLabel += ' (${j.startDate ?? '?'} - ${j.endDate ?? '?'})';
                      }

                      final canOpen = jSemesterId != null && jDisciplineId != 0;
                      void openJournal() => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GradeJournalPage(
                            groupId: jGroupId,
                            disciplineId: jDisciplineId.toString(),
                            semesterId: jSemesterId.toString(),
                            disciplineShortName: j.disciplineName,
                            groupName: '${widget.groupName} навчальна група',
                          ),
                        ),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: isArchived ? const Color(0xFFF9FAFB) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: canOpen ? openJournal : null,
                        child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isArchived ? const Color(0xFFE5E7EB) : AppTheme.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(semLabel,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isArchived
                                                ? AppTheme.textMid
                                                : AppTheme.primary)),
                                    const SizedBox(height: 2),
                                    Text(j.disciplineName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: isArchived
                                                ? AppTheme.textMid
                                                : AppTheme.textDark)),
                                  ],
                                ),
                              ),
                              if (isArchived)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE4E6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: const Text('АРХІВНИЙ',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFB91C1C),
                                          letterSpacing: 0.5)),
                                )
                              else
                                const Icon(Icons.school, color: AppTheme.primary, size: 22),
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
                                  onUpdated: _load,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: canOpen ? openJournal : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isArchived
                                      ? const Color(0xFF6B7280)
                                      : AppTheme.primary,
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
                      ),
                          ),
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

// ── Дисципліни кафедри ───────────────────────────────────────────────────────

class _KafedraDisciplinesPage extends ConsumerStatefulWidget {
  final int kafedraId;
  final String kafedraName;
  final bool isRoot;
  const _KafedraDisciplinesPage({
    required this.kafedraId,
    required this.kafedraName,
    this.isRoot = false,
  });

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
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);

    final cacheKey = 'kafedra_disciplines_${widget.kafedraId}';
    final cachedRaw = cache.get<List<dynamic>>(cacheKey);
    if (cachedRaw != null) {
      setState(() {
        _disciplines = cachedRaw
            .map((e) => DisciplineModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }

    if (!network.isOnline) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final raw = await ref
          .read(disciplinesRepositoryProvider)
          .getAllDisciplines(kafedraId: widget.kafedraId);
      await cache.set(cacheKey, raw.map((d) => d.toJson()).toList());
      setState(() {
        _disciplines = raw.where((d) => d.kafedraId == widget.kafedraId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (cachedRaw == null) _error = e.toString();
      });
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

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Електронний журнал'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Container(height: 3, color: AppTheme.primary),
          ),
        ),
        body: Center(
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
        ),
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
          if (!widget.isRoot)
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('До списку кафедр'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textMid,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, widget.isRoot ? 12 : 4, 16, 8),
            child: Text(
              'Дисципліни — ${widget.kafedraName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.textDark),
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
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
  List<JournalModel> _journals = [];
  bool _isLoading = true;
  String? _error;
  bool _currentOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);

    final cacheKey = 'discipline_journals_${widget.disciplineId}';
    final cachedRaw = cache.get<List<dynamic>>(cacheKey);
    if (cachedRaw != null) {
      setState(() {
        _journals = cachedRaw
            .map((e) => JournalModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }

    if (!network.isOnline) {
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final journals = await ref.read(disciplinesRepositoryProvider)
          .getDisciplineJournals(widget.disciplineId);
      await cache.set(cacheKey, journals.map((j) => j.toJson()).toList());
      setState(() { _journals = journals; _isLoading = false; });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (cachedRaw == null) _error = e.toString();
      });
    }
  }

  bool _isActive(JournalModel j) {
    final endStr = j.endDate;
    if (endStr == null || endStr.isEmpty) return true;
    try {
      final end = DateTime.parse(endStr);
      final today = DateTime.now();
      return !end.isBefore(DateTime(today.year, today.month, today.day));
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _journals.where(_isActive).length;
    final filtered = _journals
        .where((j) => !_currentOnly || _isActive(j))
        .where((j) => j.groupName.toLowerCase().contains(_search.toLowerCase()))
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
            label: const Text('До списку дисциплін'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMid,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              'Журнали — ${widget.disciplineName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
            child: Row(children: [
              Checkbox(
                value: _currentOnly,
                onChanged: (v) => setState(() => _currentOnly = v ?? false),
                activeColor: AppTheme.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentOnly = !_currentOnly),
                  child: Text(
                    'Показувати поточні семестри  ($activeCount з ${_journals.length} журналів)',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                  ),
                ),
              ),
            ]),
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
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                final jGroupId = j.groupId != 0 ? j.groupId : null;
                final jSemesterId = j.semesterId != 0 ? j.semesterId : null;
                final jDisciplineId = j.disciplineId != 0 ? j.disciplineId : widget.disciplineId;
                final isArchived = !_isActive(j);

                String semesterLabel = 'Семестр: ${j.semester == 0 ? '—' : j.semester}';
                if (j.startDate != null || j.endDate != null) {
                  semesterLabel += ' (${j.startDate ?? '?'} - ${j.endDate ?? '?'}';
                  if (j.academicYear != null) semesterLabel += ' | ${j.academicYear}';
                  semesterLabel += ')';
                }

                final canOpen = jGroupId != null && jSemesterId != null;
                void openJournal() => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GradeJournalPage(
                      groupId: jGroupId!,
                      disciplineId: jDisciplineId.toString(),
                      semesterId: jSemesterId!.toString(),
                      disciplineShortName: widget.disciplineName,
                      groupName: '${j.groupName} навчальна група',
                    ),
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isArchived ? const Color(0xFFF9FAFB) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: canOpen ? openJournal : null,
                  child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isArchived ? const Color(0xFFE5E7EB) : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.menu_book_outlined,
                            color: isArchived ? AppTheme.textMid : AppTheme.primary,
                            size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${j.groupName} навчальна група',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isArchived ? AppTheme.textMid : AppTheme.textDark),
                          ),
                        ),
                        if (isArchived)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: const Text('АРХІВНИЙ',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                    letterSpacing: 0.5)),
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
                            onUpdated: _load,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(semesterLabel,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: canOpen ? openJournal : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isArchived
                                ? const Color(0xFF6B7280)
                                : AppTheme.primary,
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
                  ),
                    ),
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
        onTap: onTap,
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

