// lib/features/analytics/presentation/pages/analytics_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/utils/military_labels.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

  // API data
  List<Map<String, dynamic>> _apiCadets = [];
  bool _isLoading = false;

  // Filter data from API
  List<Map<String, dynamic>> _allFaculties = [];
  List<Map<String, dynamic>> _allGroups = [];
  List<Map<String, dynamic>> _allSemesters = [];
  bool _filtersLoading = false;

  // Selected filter IDs
  int? _selectedFacultyId;
  int? _selectedCourse; // 1-4, client-side filter for semesters visibility
  int? _selectedGroupId;
  int? _selectedSemesterId;

  void _resetFilters() {
    setState(() {
      _selectedFacultyId = null;
      _selectedCourse = null;
      _selectedGroupId = null;
      _selectedSemesterId = null;
      _allSemesters = [];
    });
    _loadRates();
  }

  Future<void> _loadFilters() async {
    setState(() => _filtersLoading = true);
    final facsRaw = await ref
        .read(facultiesRepositoryProvider)
        .getFaculties()
        .catchError((_) => <dynamic>[]);
    final groupsRaw = await ref
        .read(groupsRepositoryProvider)
        .getGroups()
        .catchError((_) => <dynamic>[]);
    final semsRaw = await ref
        .read(semestersRepositoryProvider)
        .getSemesters()
        .catchError((_) => <dynamic>[]);
    if (!mounted) return;
    setState(() {
      _allFaculties = facsRaw.whereType<Map<String, dynamic>>().toList();
      _allGroups = groupsRaw.whereType<Map<String, dynamic>>().toList();
      // getSemesters може повернути paginated об'єкт — витягуємо content
      final semsList = semsRaw.isNotEmpty ? semsRaw : <dynamic>[];
      _allSemesters = semsList.whereType<Map<String, dynamic>>().toList();
      _filtersLoading = false;
    });
  }

  Future<void> _loadSemestersForGroup(int groupId) async {
    final sems = await ref
        .read(semestersRepositoryProvider)
        .getSemestersByGroup(groupId)
        .catchError((_) => <dynamic>[]);
    if (!mounted) return;
    setState(() {
      _allSemesters = sems.whereType<Map<String, dynamic>>().toList();
    });
  }

  Future<void> _loadRates() async {
    final auth = ref.read(authViewModelProvider);
    final isCadet = auth.role == UserRole.cadet;
    final groupId = auth.groupId;
    if (isCadet && groupId == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(ratesRepositoryProvider).getRates(
        groupId: isCadet ? groupId : _selectedGroupId,
        semesterId: _selectedSemesterId,
        size: 5000,
      );
      final content = result['content'] as List<dynamic>? ?? [];
      final cadets = content.map((r) {
        final m = r as Map<String, dynamic>;
        final last  = m['lastName']  as String? ?? '';
        final first = m['firstName'] as String? ?? '';
        return <String, dynamic>{
          'cadetId':        (m['cadetId'] as num?)?.toInt(),
          'name':           '$last $first'.trim(),
          'position':       MilitaryLabels.position(m['position'] as String?),
          'group':          m['groupName']   as String? ?? '',
          'specialty':      MilitaryLabels.speciality(m['speciality'] as String?),
          'facultyName':    m['facultyName'] as String? ?? '',
          'enrollmentYear': m['enrollmentYear']?.toString() ?? '',
          'score':          ((m['ratePercentage']    as num?) ?? 0).round(),
          'attendance':     ((m['presentPercentage'] as num?) ?? 0).round(),
        };
      }).toList();
      if (mounted) setState(() { _apiCadets = cadets; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRates();
      final role = ref.read(authViewModelProvider).role ?? '';
      if (role != UserRole.cadet) _loadFilters();
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _showDetails(BuildContext context, Map<String, dynamic> cadet, int rank) {
    showDialog(
      context: context,
      builder: (_) => _CadetDetailsDialog(cadet: cadet, rank: rank),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final role = auth.role ?? '';
    final isCadet = role == UserRole.cadet;
    final fullName = auth.fullName ?? auth.email ?? 'Користувач';

    final visibleCadets = _apiCadets;

    // Групи тільки коли обраний факультет; фільтр по курсу якщо обраний
    final filteredGroups = _selectedFacultyId == null
        ? <Map<String, dynamic>>[]
        : _allGroups.where((g) {
            final fId = (g['facultyId'] as num?)?.toInt() ??
                ((g['faculty'] as Map<String, dynamic>?)?['id'] as num?)
                    ?.toInt();
            final courseNum = (g['courseNumber'] as num?)?.toInt();
            return fId == _selectedFacultyId &&
                (_selectedCourse == null || courseNum == _selectedCourse);
          }).toList();

    // Набір назв груп для client-side фільтрації (факультет + курс)
    // Використовується тільки коли _allGroups завантажені і група не обрана
    Set<String>? targetGroupNames;
    if (_selectedGroupId == null &&
        _allGroups.isNotEmpty &&
        (_selectedFacultyId != null || _selectedCourse != null)) {
      targetGroupNames = filteredGroups
          .map((g) => (g['name'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
    }

    final filtered = visibleCadets.where((c) {
      final matchSearch = c['name']
          .toString()
          .toLowerCase()
          .contains(_search.toLowerCase());
      final matchGroups = targetGroupNames == null ||
          targetGroupNames.contains(c['group']);
      return matchSearch && matchGroups;
    }).toList();

    final roleIcon = _roleIcon(role);
    final roleColor = _roleColor(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рейтинг'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 15, color: roleColor),
                const SizedBox(width: 5),
                Text(
                  fullName,
                  style: TextStyle(
                      fontSize: 13,
                      color: roleColor,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down, size: 15, color: roleColor),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Заголовок ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCadet ? 'Рейтинг групи' : 'Аналітика навчання',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCadet
                        ? 'Рейтинг успішності курсантів вашої групи'
                        : 'Комплексна аналітика успішності курсантів',
                    style: const TextStyle(
                        color: AppTheme.textMid, fontSize: 13),
                  ),
                  if (isCadet) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.secondary, width: 1.5),
                      ),
                      child: Text(
                        auth.groupName != null
                            ? 'Група: ${auth.groupName}'
                            : 'Моя група',
                        style: const TextStyle(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Фільтри (тільки для адмін/викладач/нач. кафедри) ─────────
          if (!isCadet) ...[
            SliverToBoxAdapter(
              child: _FiltersCard(
                faculties: _allFaculties,
                groups: filteredGroups,
                semesters: _allSemesters,
                selectedFacultyId: _selectedFacultyId,
                selectedCourse: _selectedCourse,
                selectedGroupId: _selectedGroupId,
                selectedSemesterId: _selectedSemesterId,
                onFacultyChanged: (id) {
                  final hadGroup = _selectedGroupId != null;
                  setState(() {
                    _selectedFacultyId = id;
                    _selectedCourse = null;
                    _selectedGroupId = null;
                    _selectedSemesterId = null;
                    _allSemesters = [];
                  });
                  if (hadGroup) _loadRates();
                },
                onCourseChanged: (course) => setState(() {
                  _selectedCourse = course;
                  _selectedSemesterId = null;
                }),
                onGroupChanged: (id) {
                  setState(() {
                    _selectedGroupId = id;
                    _selectedSemesterId = null;
                    _allSemesters = [];
                  });
                  if (id != null) _loadSemestersForGroup(id);
                  _loadRates();
                },
                onSemesterChanged: (id) {
                  setState(() => _selectedSemesterId = id);
                  _loadRates();
                },
                onReset: _resetFilters,
                isLoading: _filtersLoading,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],

          // ── Вкладки ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppTheme.border))),
                    child: TabBar(
                      controller: _tab,
                      onTap: (_) => setState(() {}),
                      indicatorColor: AppTheme.primary,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textMid,
                      tabs: const [
                        Tab(
                            icon: Icon(Icons.menu_book_outlined, size: 18),
                            text: 'Рейтинг'),
                        Tab(
                            icon: Icon(Icons.bar_chart, size: 18),
                            text: 'Статистика'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_tab.index == 0) ...[
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Пошук за прізвищем',
                        prefixIcon: Icon(Icons.search,
                            color: AppTheme.textMid, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!isCadet) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Експорт в Excel',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text('Знайдено записів: ${filtered.length}',
                        style: const TextStyle(
                            color: AppTheme.textMid, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Рейтинг або Статистика ─────────────────────────────────
          SliverToBoxAdapter(
            child: _tab.index == 0
                ? _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _apiCadets.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text('Немає даних',
                                  style: TextStyle(color: AppTheme.textMid)),
                            ),
                          )
                        : Column(
                            children: [
                              ...List.generate(filtered.length, (i) {
                                final cadet = filtered[i];
                                final rank = visibleCadets.indexOf(cadet) + 1;
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: _CadetRankCard(
                                    cadet: cadet,
                                    rank: rank,
                                    onTap: () =>
                                        _showDetails(context, cadet, rank),
                                  ),
                                );
                              }),
                              const SizedBox(height: 24),
                            ],
                          )
                : _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _apiCadets.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text('Немає даних',
                                  style: TextStyle(color: AppTheme.textMid)),
                            ),
                          )
                        : _StatisticsTab(cadets: visibleCadets),
          ),
        ],
      ),
    );
  }

  static IconData _roleIcon(String role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.instructor:
        return Icons.person_outline;
      case UserRole.departmentHead:
        return Icons.school_outlined;
      default:
        return Icons.military_tech_outlined;
    }
  }

  static Color _roleColor(String role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppTheme.secondary;
      case UserRole.instructor:
        return const Color(0xFF0284C7);
      case UserRole.departmentHead:
        return const Color(0xFF059669);
      default:
        return AppTheme.textMid;
    }
  }
}

// ── Блок фільтрів ────────────────────────────────────────────────────────────

class _FiltersCard extends StatelessWidget {
  final List<Map<String, dynamic>> faculties;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> semesters;
  final int? selectedFacultyId;
  final int? selectedCourse;
  final int? selectedGroupId;
  final int? selectedSemesterId;
  final ValueChanged<int?> onFacultyChanged;
  final ValueChanged<int?> onCourseChanged;
  final ValueChanged<int?> onGroupChanged;
  final ValueChanged<int?> onSemesterChanged;
  final VoidCallback onReset;
  final bool isLoading;

  const _FiltersCard({
    required this.faculties,
    required this.groups,
    required this.semesters,
    required this.selectedFacultyId,
    required this.selectedCourse,
    required this.selectedGroupId,
    required this.selectedSemesterId,
    required this.onFacultyChanged,
    required this.onCourseChanged,
    required this.onGroupChanged,
    required this.onSemesterChanged,
    required this.onReset,
    this.isLoading = false,
  });

  static int _id(Map<String, dynamic> m) => (m['id'] as num).toInt();

  static String _facultyLabel(Map<String, dynamic> f) =>
      f['name'] as String? ?? f['fullName'] as String? ?? '—';

  static String _groupLabel(Map<String, dynamic> g) =>
      g['name'] as String? ?? g['groupNumber'] as String? ?? '—';

  static String _semesterLabel(Map<String, dynamic> s) {
    final n = (s['semesterNumber'] as num?)?.toInt() ??
        (s['number'] as num?)?.toInt();
    if (n != null) return 'Семестр $n';
    return s['name'] as String? ?? '—';
  }

  static const _courseLabels = ['1 курс', '2 курс', '3 курс', '4 курс'];

  static int _semesterNum(Map<String, dynamic> s) =>
      (s['semesterNumber'] as num?)?.toInt() ??
      (s['number'] as num?)?.toInt() ??
      0;

  static int _courseForSem(Map<String, dynamic> s) {
    final n = _semesterNum(s);
    if (n <= 2) return 1;
    if (n <= 4) return 2;
    if (n <= 6) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedFacultyId != null ||
        selectedCourse != null ||
        selectedGroupId != null ||
        selectedSemesterId != null;

    final facultyNames = faculties.map(_facultyLabel).toList();
    final selectedFacultyName = selectedFacultyId == null
        ? null
        : faculties
            .where((f) => _id(f) == selectedFacultyId)
            .map(_facultyLabel)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);

    // Дедуплікація семестрів по номеру (беремо останній по id)
    final seenNums = <int>{};
    final uniqueSems = ([...semesters]
          ..sort((a, b) => _id(b).compareTo(_id(a))))
        .where((s) => seenNums.add(_semesterNum(s)))
        .toList()
      ..sort((a, b) => _semesterNum(a).compareTo(_semesterNum(b)));

    // Семестри для обраного курсу
    final semestersForCourse = selectedCourse != null
        ? uniqueSems
            .where((s) => _courseForSem(s) == selectedCourse)
            .toList()
        : <Map<String, dynamic>>[];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок — як у веб-версії
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                const Text('Фільтри',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark)),
                const Spacer(),
                GestureDetector(
                  onTap: hasFilters ? onReset : null,
                  child: Text(
                    'Скинути фільтри',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasFilters
                          ? AppTheme.secondary
                          : AppTheme.textLight,
                      fontWeight: hasFilters
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Факультет
                  const Text('Факультет',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  _FilterDropdown(
                    hint: 'Оберіть факультет',
                    value: selectedFacultyName,
                    items: facultyNames,
                    onChanged: (name) {
                      if (name == null) {
                        onFacultyChanged(null);
                        return;
                      }
                      final match = faculties
                          .where((f) => _facultyLabel(f) == name)
                          .cast<Map<String, dynamic>?>()
                          .firstWhere((_) => true, orElse: () => null);
                      onFacultyChanged(match != null ? _id(match) : null);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Курс
                  const Text('Курс',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  _FilterDropdown(
                    hint: 'Оберіть курс',
                    value: selectedCourse != null
                        ? _courseLabels[selectedCourse! - 1]
                        : null,
                    items: _courseLabels,
                    onChanged: (label) {
                      if (label == null) {
                        onCourseChanged(null);
                        return;
                      }
                      final idx = _courseLabels.indexOf(label);
                      onCourseChanged(idx >= 0 ? idx + 1 : null);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Групи — з'являються після вибору факультету
                  const Text('Групи',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  if (selectedFacultyId == null)
                    const _FilterPlaceholder(
                        text:
                            'Оберіть факультет щоб побачити доступні групи')
                  else if (groups.isEmpty)
                    const _FilterPlaceholder(
                        text: 'Немає доступних груп')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: groups.map((g) {
                        final id = _id(g);
                        return _FilterChip(
                          label: _groupLabel(g),
                          selected: selectedGroupId == id,
                          onTap: () => onGroupChanged(
                              selectedGroupId == id ? null : id),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 14),

                  // Семестри — з'являються після вибору групи
                  const Text('Семестри',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  if (selectedGroupId == null)
                    const _FilterPlaceholder(
                        text: 'Оберіть групу щоб побачити доступні семестри')
                  else if (semesters.isEmpty)
                    const _FilterPlaceholder(
                        text: 'Завантаження семестрів...')
                  else if (semestersForCourse.isEmpty && selectedCourse != null)
                    const _FilterPlaceholder(
                        text: 'Немає семестрів для цього курсу')
                  else if (semestersForCourse.isEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: uniqueSems.map((s) {
                        final id = _id(s);
                        return _FilterChip(
                          label: _semesterLabel(s),
                          selected: selectedSemesterId == id,
                          onTap: () => onSemesterChanged(
                              selectedSemesterId == id ? null : id),
                        );
                      }).toList(),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: semestersForCourse.map((s) {
                        final id = _id(s);
                        return _FilterChip(
                          label: _semesterLabel(s),
                          selected: selectedSemesterId == id,
                          onTap: () => onSemesterChanged(
                              selectedSemesterId == id ? null : id),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      hint: Text(hint,
          style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
          overflow: TextOverflow.ellipsis),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.secondary, width: 1.5),
        ),
        filled: true,
        fillColor: AppTheme.surface,
      ),
      icon: const Icon(Icons.keyboard_arrow_down,
          color: AppTheme.textMid, size: 20),
      dropdownColor: Colors.white,
      style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.secondary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.secondary : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

class _FilterPlaceholder extends StatelessWidget {
  final String text;
  const _FilterPlaceholder({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textLight,
          fontStyle: FontStyle.italic),
    );
  }
}

// ── Картка курсанта ───────────────────────────────────────────────────────────

class _CadetRankCard extends StatelessWidget {
  final Map<String, dynamic> cadet;
  final int rank;
  final VoidCallback onTap;
  const _CadetRankCard(
      {required this.cadet, required this.rank, required this.onTap});

  Color _rankBg() {
    if (rank == 1) return const Color(0xFFFEF3C7);
    if (rank == 2) return const Color(0xFFEFF6FF);
    if (rank == 3) return const Color(0xFFFFF7ED);
    return const Color(0xFFF9FAFB);
  }

  Color _rankFg() {
    if (rank == 1) return const Color(0xFFD97706);
    if (rank == 2) return const Color(0xFF2563EB);
    if (rank == 3) return const Color(0xFF92400E);
    return AppTheme.textLight;
  }

  @override
  Widget build(BuildContext context) {
    final score      = cadet['score'] as int;
    final attendance = cadet['attendance'] as int;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: _rankBg(), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$rank',
                  style: TextStyle(
                      color: _rankFg(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(cadet['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textDark),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      _RatingPill(value: score, isScore: true),
                      const SizedBox(width: 5),
                      _RatingPill(value: attendance, isScore: false),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${cadet['position']} • ${cadet['specialty']} • Гр. ${cadet['group']}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMid),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final int value;
  final bool isScore;
  const _RatingPill({required this.value, required this.isScore});

  Color get _fg {
    if (!isScore) return const Color(0xFF0284C7);
    if (value >= 75) return const Color(0xFF16A34A);
    if (value >= 60) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Color get _bg {
    if (!isScore) return const Color(0xFFE0F2FE);
    if (value >= 75) return const Color(0xFFDCFCE7);
    if (value >= 60) return const Color(0xFFFEF3C7);
    return const Color(0xFFFEE2E2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$value%',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _fg)),
    );
  }
}

// ── Діалог деталей курсанта ───────────────────────────────────────────────────

class _CadetDetailsDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> cadet;
  final int rank;

  const _CadetDetailsDialog({required this.cadet, required this.rank});

  @override
  ConsumerState<_CadetDetailsDialog> createState() => _CadetDetailsDialogState();
}

class _CadetDetailsDialogState extends ConsumerState<_CadetDetailsDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _disciplines = [];
  String? _facultyName;
  String? _enrollmentYear;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final cadetId = widget.cadet['cadetId'] as int?;
    if (cadetId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final data = await ref.read(ratesRepositoryProvider).getCadetRates(cadetId);
      final rawDisc = data['disciplines'] as List<dynamic>? ?? [];
      final disciplines = rawDisc.map((d) {
        final m = d as Map<String, dynamic>;
        final studentMarks = (m['studentMarks'] as num?)?.toStringAsFixed(0) ?? '0';
        final maxMarks     = (m['maxPossibleMarks'] as num?)?.toStringAsFixed(0) ?? '0';
        final sems         = m['semesterNumbers'] as List<dynamic>?;
        return <String, dynamic>{
          'name':       m['disciplineFullName']  as String?
                     ?? m['disciplineShortName'] as String? ?? '',
          'score':      ((m['ratePercentage']       as num?) ?? 0).round(),
          'attendance': ((m['attendancePercentage'] as num?) ?? 0).round(),
          'points':     '$studentMarks/$maxMarks',
          'semester':   sems?.isNotEmpty == true ? sems!.first : null,
        };
      }).toList();
      if (mounted) setState(() {
        _disciplines  = disciplines;
        _facultyName  = data['facultyName'] as String?;
        _enrollmentYear = data['enrollmentYear']?.toString();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _initials {
    final parts = (widget.cadet['name'] as String).split(' ');
    return parts.take(2).map((w) => w.isEmpty ? '' : w[0]).join();
  }

  @override
  Widget build(BuildContext context) {
    final cadet = widget.cadet;
    final overallScore = cadet['score'] as int;
    final facultyName  = _facultyName ?? cadet['facultyName'] as String? ?? '';
    final year         = _enrollmentYear?.isNotEmpty == true
        ? _enrollmentYear!
        : (cadet['enrollmentYear'] as String? ?? '—');

    return Dialog(
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Кольорова шапка ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 12, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(_initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cadet['name'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 7),
                      Row(children: [
                        _HeaderChip(label: '#${widget.rank} у групі'),
                        const SizedBox(width: 8),
                        _HeaderChip(label: 'Рейтинг: $overallScore%'),
                      ]),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Контент ──────────────────────────────────────────────────
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _InfoTile(
                            icon: Icons.group_outlined,
                            label: 'Група',
                            value: cadet['group'] as String? ?? '—',
                          ),
                          const SizedBox(width: 8),
                          _InfoTile(
                            icon: Icons.calendar_today_outlined,
                            label: 'Рік вступу',
                            value: year,
                          ),
                        ]),
                        const SizedBox(height: 8),
                        _DetailRow(
                          icon: Icons.school_outlined,
                          label: 'Спеціальність',
                          value: cadet['specialty'] as String? ?? '—',
                        ),
                        const SizedBox(height: 8),
                        if (facultyName.isNotEmpty)
                          _DetailRow(
                            icon: Icons.business_outlined,
                            label: 'Факультет',
                            value: facultyName,
                          ),
                        const SizedBox(height: 20),

                        // Дисципліни
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.library_books_outlined,
                                size: 16, color: Color(0xFF4F46E5)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Дисципліни (${_disciplines.length})',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textDark),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        const _ScoreLegend(),
                        const SizedBox(height: 12),

                        if (_disciplines.isEmpty)
                          const Text('Дані дисциплін відсутні',
                              style: TextStyle(
                                  color: AppTheme.textMid,
                                  fontStyle: FontStyle.italic))
                        else
                          ..._disciplines.map((d) => _DisciplineCard(discipline: d)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: AppTheme.textMid),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Плитка інфо ──────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.textMid),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMid)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark)),
          ]),
        ]),
      ),
    );
  }
}

// ── Чіп у шапці діалогу ──────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  final String label;
  const _HeaderChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ── Легенда шкали успішності ──────────────────────────────────────────────────

class _ScoreLegend extends StatelessWidget {
  const _ScoreLegend();

  static const _colors = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFF22C55E),
    Color(0xFF84CC16),
    Color(0xFFEA580C),
    Color(0xFFDC2626),
  ];

  static const _labels = [
    '>100%',
    '90–100%',
    '80–90%',
    '65–80%',
    '50–65%',
    '<50%',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: List.generate(
        _colors.length,
        (i) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: _colors[i], shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(_labels[i],
                style:
                    const TextStyle(fontSize: 10, color: AppTheme.textMid)),
          ],
        ),
      ),
    );
  }
}

// ── Картка дисципліни ─────────────────────────────────────────────────────────

class _DisciplineCard extends StatelessWidget {
  final Map<String, dynamic> discipline;
  const _DisciplineCard({required this.discipline});

  static Color _accentColor(int score) {
    if (score > 100) return const Color(0xFF2563EB);
    if (score >= 90) return const Color(0xFF16A34A);
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 65) return const Color(0xFF84CC16);
    if (score >= 50) return const Color(0xFFEA580C);
    return const Color(0xFFDC2626);
  }

  static Color _bgColor(int score) {
    if (score > 100) return const Color(0xFFEFF6FF);
    if (score >= 90) return const Color(0xFFF0FDF4);
    if (score >= 80) return const Color(0xFFF0FDF4);
    if (score >= 65) return const Color(0xFFF7FEE7);
    if (score >= 50) return const Color(0xFFFFF7ED);
    return const Color(0xFFFEF2F2);
  }

  static String _scoreLabel(int score) {
    if (score > 100) return 'Бонус';
    if (score >= 90) return 'Відмінно';
    if (score >= 80) return 'Добре';
    if (score >= 65) return 'Задовільно';
    if (score >= 50) return 'Слабо';
    return 'Незадовільно';
  }

  @override
  Widget build(BuildContext context) {
    final score = discipline['score'] as int;
    final attendance = discipline['attendance'] as int;
    final accent = _accentColor(score);
    final bg = _bgColor(score);
    final progress = (score / 100).clamp(0.0, 1.0);

    final attendanceColor = attendance >= 90
        ? const Color(0xFF0284C7)
        : attendance >= 75
            ? const Color(0xFF16A34A)
            : const Color(0xFFEA580C);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ліва кольорова смуга
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14)),
              ),
            ),
            // Контент
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Назва + бейдж статусу
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            discipline['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _scoreLabel(score),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Прогрес-бар з відсотком
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: accent.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$score%',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    // Статистика внизу
                    Row(children: [
                      _StatChip(
                        icon: Icons.event_available_outlined,
                        value: '$attendance%',
                        label: 'Відвідуваність',
                        color: attendanceColor,
                      ),
                      const SizedBox(width: 14),
                      _StatChip(
                        icon: Icons.grading_outlined,
                        value: discipline['points'] as String,
                        label: 'Бали',
                        color: AppTheme.textDark,
                      ),
                      const Spacer(),
                      Text(
                        'Сем. ${discipline['semester']}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMid),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMid)),
        const SizedBox(height: 2),
        Row(children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// STATISTICS TAB — insert after existing TabBar in analytics_page.dart

// ── Статистика ────────────────────────────────────────────────────────────────

class _StatisticsTab extends StatelessWidget {
  final List<Map<String, dynamic>> cadets;
  const _StatisticsTab({required this.cadets});

  // Розподіл за рейтингом
  Map<String, int> get _distribution {
    int excellent = 0, good = 0, satisfactory = 0, poor = 0;
    for (final c in cadets) {
      final s = c['score'] as int;
      if (s >= 90) excellent++;
      else if (s >= 75) good++;
      else if (s >= 60) satisfactory++;
      else poor++;
    }
    return {'Відмінно': excellent, 'Добре': good, 'Задовільно': satisfactory, 'Незадовільно': poor};
  }

  double get _avgScore => cadets.isEmpty ? 0 :
    cadets.map((c) => c['score'] as int).reduce((a, b) => a + b) / cadets.length;

  double get _avgAttendance => cadets.isEmpty ? 0 :
    cadets.map((c) => c['attendance'] as int).reduce((a, b) => a + b) / cadets.length;

  @override
  Widget build(BuildContext context) {
    final dist = _distribution;
    final top10 = List<Map<String, dynamic>>.from(cadets)
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final top = top10.take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
      children: [
        // Заголовок
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Аналіз успішності курсантів',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text(
                'Статистичні дані щодо успішності курсантів, відвідуваності та інших освітніх показників.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMid),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Середні показники
        Row(children: [
          Expanded(child: _StatCard(
            label: 'Середній бал',
            value: _avgScore.toStringAsFixed(1),
            icon: Icons.star,
            color: const Color(0xFF6366F1),
          )),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(
            label: 'Відвідуваність',
            value: '${_avgAttendance.toStringAsFixed(0)}%',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF059669),
          )),
        ]),
        const SizedBox(height: 12),

        // Розподіл рейтингу — donut chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Розподіл рейтингу курсантів',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: [
                          PieChartSectionData(
                            value: dist['Відмінно']!.toDouble(),
                            color: const Color(0xFF3B82F6),
                            radius: 45,
                            title: dist['Відмінно']! > 0
                                ? '${dist['Відмінно']}'
                                : '',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          PieChartSectionData(
                            value: dist['Добре']!.toDouble(),
                            color: const Color(0xFF10B981),
                            radius: 45,
                            title: dist['Добре']! > 0
                                ? '${dist['Добре']}'
                                : '',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          PieChartSectionData(
                            value: dist['Задовільно']!.toDouble(),
                            color: const Color(0xFFF59E0B),
                            radius: 45,
                            title: dist['Задовільно']! > 0
                                ? '${dist['Задовільно']}'
                                : '',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                          PieChartSectionData(
                            value: dist['Незадовільно']!.toDouble(),
                            color: const Color(0xFFEF4444),
                            radius: 45,
                            title: dist['Незадовільно']! > 0
                                ? '${dist['Незадовільно']}'
                                : '',
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Legend(color: const Color(0xFF3B82F6),
                            label: 'Відмінно',
                            count: dist['Відмінно']!,
                            total: cadets.length),
                        const SizedBox(height: 8),
                        _Legend(color: const Color(0xFF10B981),
                            label: 'Добре',
                            count: dist['Добре']!,
                            total: cadets.length),
                        const SizedBox(height: 8),
                        _Legend(color: const Color(0xFFF59E0B),
                            label: 'Задовільно',
                            count: dist['Задовільно']!,
                            total: cadets.length),
                        const SizedBox(height: 8),
                        _Legend(color: const Color(0xFFEF4444),
                            label: 'Незадовільно',
                            count: dist['Незадовільно']!,
                            total: cadets.length),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Топ-10 бар чарт
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Топ 10 курсантів за успішністю',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark)),
              const Text('Відсоток виконання завдань',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMid)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barGroups: top.asMap().entries.map((e) =>
                      BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: (e.value['score'] as int).toDouble(),
                            color: const Color(0xFF6366F1),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) => Text(
                            v.toInt().toString(),
                            style: const TextStyle(fontSize: 9, color: AppTheme.textMid),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx >= top.length) return const SizedBox();
                            final name = top[idx]['name'] as String;
                            final lastName = name.split(' ').first;
                            return SideTitleWidget(
                              axisSide: AxisSide.bottom,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Text(lastName,
                                    style: const TextStyle(
                                        fontSize: 9, color: AppTheme.textMid)),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppTheme.border,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Відвідуваність donut
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Розподіл відвідуваності',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textDark)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 45,
                        sections: _attendanceSections(cadets),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Legend(color: const Color(0xFF3B82F6),
                            label: 'Відмінно\n(≥95%)',
                            count: cadets.where((c) => (c['attendance'] as int) >= 95).length,
                            total: cadets.length),
                        const SizedBox(height: 6),
                        _Legend(color: const Color(0xFF10B981),
                            label: 'Добре\n(80-94%)',
                            count: cadets.where((c) => (c['attendance'] as int) >= 80 && (c['attendance'] as int) < 95).length,
                            total: cadets.length),
                        const SizedBox(height: 6),
                        _Legend(color: const Color(0xFFF59E0B),
                            label: 'Задовільно\n(60-79%)',
                            count: cadets.where((c) => (c['attendance'] as int) >= 60 && (c['attendance'] as int) < 80).length,
                            total: cadets.length),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
      ),
    );
  }

  List<PieChartSectionData> _attendanceSections(List<Map<String, dynamic>> cadets) {
    final excellent = cadets.where((c) => (c['attendance'] as int) >= 95).length;
    final good = cadets.where((c) => (c['attendance'] as int) >= 80 && (c['attendance'] as int) < 95).length;
    final satisfactory = cadets.where((c) => (c['attendance'] as int) < 80).length;
    return [
      PieChartSectionData(value: excellent.toDouble(), color: const Color(0xFF3B82F6), radius: 40,
          title: excellent > 0 ? '$excellent' : '', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      PieChartSectionData(value: good.toDouble(), color: const Color(0xFF10B981), radius: 40,
          title: good > 0 ? '$good' : '', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      PieChartSectionData(value: satisfactory.toDouble(), color: const Color(0xFFF59E0B), radius: 40,
          title: satisfactory > 0 ? '$satisfactory' : '', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    ];
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
          Text(value, style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  const _Legend({required this.color, required this.label,
      required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 10, height: 10,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Expanded(child: Text('$label: $count ($pct%)',
          style: const TextStyle(fontSize: 10, color: AppTheme.textDark))),
    ]);
  }
}