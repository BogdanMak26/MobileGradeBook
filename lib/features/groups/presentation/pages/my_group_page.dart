// lib/features/groups/presentation/pages/my_group_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/utils/military_labels.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../journals/presentation/pages/journals_page.dart';

// ── Сторінка всіх навчальних груп ────────────────────────────────────────────

class AllGroupsPage extends ConsumerStatefulWidget {
  const AllGroupsPage({super.key});

  @override
  ConsumerState<AllGroupsPage> createState() => _AllGroupsPageState();
}

class _AllGroupsPageState extends ConsumerState<AllGroupsPage> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await ref.read(groupsRepositoryProvider).getGroups();
      setState(() {
        _groups = raw.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _groups;
    final q = _search.toLowerCase();
    return _groups.where((g) {
      final name = g['name']?.toString().toLowerCase() ?? '';
      final specialty = _groupSpecialty(g).toLowerCase();
      return name.contains(q) || specialty.contains(q);
    }).toList();
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Text('Навчальні групи',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Пошук груп...',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textMid, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
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
            Text('Помилка: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMid)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Повторити')),
          ],
        ),
      );
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Груп не знайдено',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _GroupCard(group: filtered[i]),
    );
  }
}

// ── Картка групи ──────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final groupId = group['id'] as int?;
    return GestureDetector(
      onTap: () {
        if (groupId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(groupId: groupId, group: group),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name']?.toString() ?? '—',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary),
                ),
                const Spacer(),
                if (group['courseNumber'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${group['courseNumber']} курс',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                _groupSpecialty(group),
                style: const TextStyle(fontSize: 11, color: AppTheme.textMid),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            _GroupInfoRow(label: 'Рік вступу', value: _groupYear(group)),
            const SizedBox(height: 2),
            _GroupInfoRow(label: 'Ступінь', value: _groupDegree(group)),
            const SizedBox(height: 2),
            _GroupInfoRow(label: 'Факультет', value: _groupFaculty(group)),
          ],
        ),
      ),
    );
  }
}

// ── Деталі групи (для не-курсантів) ──────────────────────────────────────────

class GroupDetailPage extends ConsumerStatefulWidget {
  final int groupId;
  final Map<String, dynamic> group;
  const GroupDetailPage(
      {super.key, required this.groupId, required this.group});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  List<Map<String, dynamic>> _cadets = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final group = await ref.read(groupsRepositoryProvider).getGroupById(widget.groupId);
      final cadetsList = (group['cadets'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList()
        ..sort((a, b) {
          final aName = '${a['surname'] ?? ''} ${a['name'] ?? ''}'.toLowerCase();
          final bName = '${b['surname'] ?? ''} ${b['name'] ?? ''}'.toLowerCase();
          return aName.compareTo(bName);
        });
      setState(() {
        _cadets = cadetsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _cadets;
    final q = _search.toLowerCase();
    return _cadets.where((c) {
      final name =
          '${c['name'] ?? ''} ${c['surname'] ?? ''}'.toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Електронний журнал'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Деталі ${g['name'] ?? ''} групи',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDisciplinesPage(
                          groupId: widget.groupId,
                          groupName: g['name']?.toString() ?? '—',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 16),
                    label: const Text('Журнали'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _GroupInfoCard(group: g)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.people_outline,
                        color: AppTheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Курсанти (${_cadets.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(
                      hintText: 'Пошук курсантів...',
                      prefixIcon: Icon(Icons.search,
                          color: AppTheme.textMid, size: 18),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Помилка: $_error',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _CadetCard(cadet: filtered[i]),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Сторінка власної групи (курсант) ─────────────────────────────────────────

class MyGroupPage extends ConsumerStatefulWidget {
  const MyGroupPage({super.key});

  @override
  ConsumerState<MyGroupPage> createState() => _MyGroupPageState();
}

class _MyGroupPageState extends ConsumerState<MyGroupPage> {
  Map<String, dynamic>? _groupInfo;
  List<Map<String, dynamic>> _cadets = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = ref.read(authViewModelProvider);
    final groupId = auth.groupId;
    if (groupId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final group = await ref.read(groupsRepositoryProvider).getGroupById(groupId);
      final cadetsList = (group['cadets'] as List<dynamic>?) ?? [];
      final enriched = Map<String, dynamic>.from(group);
      if (!enriched.containsKey('facultyName') || enriched['facultyName'] == null) {
        enriched['facultyName'] = auth.facultyName;
      }
      final sortedCadets = cadetsList
          .map((c) => c as Map<String, dynamic>)
          .toList()
        ..sort((a, b) {
          final aName = '${a['surname'] ?? ''} ${a['name'] ?? ''}'.toLowerCase();
          final bName = '${b['surname'] ?? ''} ${b['name'] ?? ''}'.toLowerCase();
          return aName.compareTo(bName);
        });
      setState(() {
        _groupInfo = enriched;
        _cadets = sortedCadets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _cadets;
    final q = _search.toLowerCase();
    return _cadets.where((c) {
      final name =
          '${c['name'] ?? ''} ${c['surname'] ?? ''}'.toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final g = _groupInfo;

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
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(
                        'Помилка: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMid),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Повторити')),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        child: Text(
                          'Деталі ${g?['name'] ?? ''} групи',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark),
                        ),
                      ),
                    ),
                    if (g != null)
                      SliverToBoxAdapter(child: _GroupInfoCard(group: g)),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.people_outline,
                                  color: AppTheme.primary, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                'Курсанти (${_cadets.length})',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark),
                              ),
                            ]),
                            const SizedBox(height: 12),
                            TextField(
                              onChanged: (v) =>
                                  setState(() => _search = v),
                              decoration: const InputDecoration(
                                hintText: 'Пошук курсантів...',
                                prefixIcon: Icon(Icons.search,
                                    color: AppTheme.textMid, size: 18),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _CadetCard(cadet: _filtered[i]),
                          childCount: _filtered.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Картка інформації про групу ───────────────────────────────────────────────

class _GroupInfoCard extends StatelessWidget {
  final Map<String, dynamic> group;
  const _GroupInfoCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.school, color: AppTheme.primary, size: 26),
            const SizedBox(width: 12),
            Text('Інформація про групу',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ]),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoBadge(
                  label: 'Група',
                  value: group['name']?.toString() ?? '—'),
              _InfoBadge(
                  label: 'Факультет', value: _groupFaculty(group)),
              _InfoBadge(
                  label: 'Спеціальність',
                  value: _groupSpecialty(group)),
              _InfoBadge(label: 'Рік вступу', value: _groupYear(group)),
              _InfoBadge(label: 'Ступінь', value: _groupDegree(group)),
              _InfoBadge(label: 'Тип', value: _groupType(group)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Допоміжні функції для полів групи ────────────────────────────────────────

String _groupFaculty(Map<String, dynamic> g) {
  final f = g['faculty'];
  if (f is Map<String, dynamic>) {
    return f['name']?.toString() ?? f['shortName']?.toString() ?? '—';
  }
  final name = f?.toString() ?? g['facultyName']?.toString();
  if (name != null && name.isNotEmpty && name != 'null') return name;
  final num = g['facultyNumber'];
  if (num != null) return 'Факультет №$num';
  final id = g['facultyId'];
  if (id != null) return 'Факультет №$id';
  return '—';
}

String _groupSpecialty(Map<String, dynamic> g) {
  final raw = g['specialty']?.toString() ??
      g['speciality']?.toString() ??
      g['specialization']?.toString() ??
      g['specialtyName']?.toString() ?? '';
  const map = <String, String>{
    'COMPUTER_SCIENCES': "Комп'ютерні науки",
    'CYBERSECURITY_AND_INFORMATION_PROTECTION': 'Кібербезпека та захист інформації',
    'INFORMATION_SYSTEMS_AND_TECHNOLOGIES': 'Інформаційні системи і технології',
    'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING':
        'Електроніка, електронні комунікації, прил. та радіотехніка',
    'MILITARY_MANAGEMENT': 'Військове управління',
    'ARMAMENT_AND_MILITARY_EQUIPMENT': 'Озброєння та військова техніка',
    'INFORMATION_SYSTEMS': 'Інформаційні системи',
    'ELECTRONICS': 'Електроніка',
    'TELECOMMUNICATIONS': 'Телекомунікації',
    'SOFTWARE_ENGINEERING': 'Програмна інженерія',
    'CYBERSECURITY': 'Кібербезпека',
    'APPLIED_MATHEMATICS': 'Прикладна математика',
  };
  if (raw.isEmpty) return '—';
  return map[raw] ?? raw;
}

String _groupYear(Map<String, dynamic> g) =>
    g['yearStart']?.toString() ??
    g['enrollmentYear']?.toString() ??
    g['year']?.toString() ??
    '—';

String _groupDegree(Map<String, dynamic> g) {
  final raw = g['degree']?.toString() ?? g['educationDegree']?.toString() ?? '';
  const map = <String, String>{
    'BACHELOR': 'Бакалавр',
    'MASTER': 'Магістр',
    'PHD': 'Доктор філософії',
    'JUNIOR_BACHELOR': 'Молодший бакалавр',
  };
  if (raw.isEmpty) return '—';
  return map[raw] ?? raw;
}

String _groupType(Map<String, dynamic> g) {
  final raw = g['formOfStudy']?.toString() ??
      g['type']?.toString() ??
      g['groupType']?.toString() ??
      g['formOfEducation']?.toString() ?? '';
  const map = <String, String>{
    'FULL_TIME': 'Денна',
    'CORRESPONDENCE': 'Заочна',
    'PART_TIME': 'Заочна',
    'EVENING': 'Вечірня',
    'DISTANCE': 'Дистанційна',
    'EXTRAMURAL': 'Екстернат',
  };
  if (raw.isEmpty) return '—';
  return map[raw] ?? raw;
}

// ── Рядок інформації ──────────────────────────────────────────────────────────

class _GroupInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _GroupInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('$label: ',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
      Text(value,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark)),
    ]);
  }
}

// ── Бейдж інформації ──────────────────────────────────────────────────────────

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary, width: 1.5),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label:  ',
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Картка курсанта ───────────────────────────────────────────────────────────

class _CadetCard extends StatelessWidget {
  final Map<String, dynamic> cadet;
  const _CadetCard({required this.cadet});

  String get _displayName {
    final name = cadet['name']?.toString() ?? '';
    final surname = cadet['surname']?.toString() ?? '';
    if (surname.isNotEmpty) return '$surname $name'.trim();
    return name;
  }

  String get _displayPosition =>
      MilitaryLabels.position(cadet['position']?.toString());

  Color get _positionColor {
    final pos = cadet['position']?.toString() ?? '';
    if (pos == 'SQUAD_COMMANDER') return const Color(0xFF1D4ED8);
    if (pos == 'DEPUTY_COMMANDER' || pos == 'PLATOON_COMMANDER') {
      return const Color(0xFF7C3AED);
    }
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final email = cadet['email']?.toString() ?? '—';
    final phone =
        (cadet['phone'] ?? cadet['phoneNumber'])?.toString() ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_displayName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _positionColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_displayPosition,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 12),
          _ContactRow(
              label: 'EMAIL:',
              value: email,
              icon: Icons.email_outlined),
          const SizedBox(height: 6),
          _ContactRow(
              label: 'ТЕЛЕФОН:',
              value: phone,
              icon: Icons.phone_outlined),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ContactRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
                letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textDark)),
      ],
    );
  }
}
