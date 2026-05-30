// lib/features/admin/presentation/pages/admin_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/local/local_cache.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../features/disciplines/data/repositories/disciplines_repository.dart';
import '../../../../shared/theme/app_theme.dart';

// ── Enum label maps ────────────────────────────────────────────────────────────

const _ranks = <String, String>{
  'CIVILIAN': 'Працівник ЗСУ', 'SOLDIER': 'Солдат', 'SENIOR_SOLDIER': 'Старший солдат',
  'JUNIOR_SERGEANT': 'Молодший сержант', 'SERGEANT': 'Сержант',
  'SENIOR_SERGEANT': 'Старший сержант', 'CHIEF_SERGEANT': 'Головний сержант',
  'STAFF_SERGEANT': 'Штаб-сержант', 'MASTER_SERGEANT': 'Майстер-сержант',
  'SENIOR_MASTER_SERGEANT': 'Старший майстер-сержант',
  'CHIEF_MASTER_SERGEANT': 'Головний майстер-сержант',
  'JUNIOR_LIEUTENANT': 'Молодший лейтенант', 'LIEUTENANT': 'Лейтенант',
  'SENIOR_LIEUTENANT': 'Старший лейтенант', 'CAPTAIN': 'Капітан',
  'MAJOR': 'Майор', 'LIEUTENANT_COLONEL': 'Підполковник', 'COLONEL': 'Полковник',
  'BRIGADIER_GENERAL': 'Бригадний генерал', 'MAJOR_GENERAL': 'Генерал-майор',
  'LIEUTENANT_GENERAL': 'Генерал-лейтенант', 'GENERAL': 'Генерал',
};

const _positions = <String, String>{
  'CADET': 'Курсант', 'LISTENER': 'Слухач', 'JOURNALIST': 'Журналіст',
  'SQUAD_COMMANDER': 'Командир відділення', 'GROUP_COMMANDER': 'Командир групи',
  'COMPANY_MASTER_SERGEANT': 'Головний сержант курсу', 'TEACHER': 'Викладач',
  'SENIOR_TEACHER': 'Старший викладач', 'DOCENT': 'Доцент', 'PROFESSOR': 'Професор',
  'DEPUTY_HEAD_OF_KAFEDRA': 'Заст. начальника кафедри',
  'HEAD_OF_KAFEDRA': 'Начальник кафедри', 'HEAD_OF_FACULTY': 'Начальник факультету',
  'DEPUTY_HEAD_OF_EDUCATION_DEPARTMENT': 'Заст. нач. навч. відділу',
  'HEAD_OF_EDUCATION_DEPARTMENT': 'Нач. навч. відділу',
  'DEPUTY_HEAD_OF_INSTITUTE_FOR_ACADEMIC_WORK': 'Заст. нач. інституту з НР',
  'HEAD_OF_EDUCATION_QUALITY_CONTROL_DEPARTMENT': 'Нач. відділу контролю якості',
  'DEPUTY_HEAD_OF_NV': 'Заст. нач. НВ', 'SENIOR_ASSISTANT_HEAD_OF_NV': 'Ст. пом. нач. НВ',
  'ASSISTANT_HEAD_OF_NV': 'Помічник нач. НВ', 'HEAD_OF_GOSDN': 'Нач. ГОСДН',
  'SENIOR_OFFICER_GOSDN': 'Ст. офіцер ГОСДН', 'HEAD_OF_NM_OFFICE': 'Завідувач НМ кабінетом',
  'METHODIST_NMK': 'Методист НМК',
  'DEPUTY_HEAD_OF_FACULTY_FOR_ACADEMIC_WORK': 'Заст. нач. факультету з НР',
  'HEAD_OF_ZYAODVO_DEPARTMENT': 'Нач. відділу ЗЯОДВО',
  'LEADING_RESEARCH_FELLOW': 'Провідний науковий співробітник',
  'SENIOR_RESEARCH_FELLOW': 'Старший науковий співробітник',
  'SENIOR_ASSISTANT': 'Старший помічник', 'HEAD_OF_TRAINING_COURSE': 'Нач. навч. курсу',
  'COURSE_OFFICER': 'Курсовий офіцер', 'HEAD_OF_INSTITUTE': 'Нач. інституту',
  'DEPUTY_HEAD_OF_INSTITUTE_FOR_LOGISTICS': 'ЗНІ з логістики',
};

const _studyRanks = <String, String>{
  'CANDIDATE': 'Кандидат наук', 'DOCTOR_OF_SCIENCE': 'Доктор наук',
  'DOCTOR_OF_PHILOSOPHY': 'Доктор філософії',
};
const _studyPositions = <String, String>{'DOCENT': 'Доцент', 'PROFESSOR': 'Професор'};
const _specialities = <String, String>{
  'COMPUTER_SCIENCES': "Комп'ютерні науки",
  'CYBERSECURITY_AND_INFORMATION_PROTECTION': 'Кібербезпека та захист інформації',
  'INFORMATION_SYSTEMS_AND_TECHNOLOGIES': 'Інформаційні системи і технології',
  'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING':
      'Електроніка, електронні комунікації, прил. та радіотехніка',
  'MILITARY_MANAGEMENT': 'Військове управління',
  'ARMAMENT_AND_MILITARY_EQUIPMENT': 'Озброєння та військова техніка',
};
const _degrees = <String, String>{'BACHELOR': 'Бакалавр', 'MASTER': 'Магістр'};
const _groupTypes = <String, String>{'FULL_TIME': 'Очна ф.н.', 'CORRESPONDENCE': 'Заочна ф.н.'};
const _genders = <String, String>{'MALE': 'Чоловік', 'FEMALE': 'Жінка'};
const _roles = <String, String>{
  'CADET': 'Курсант', 'TEACHER': 'Викладач',
  'DEPARTMENT_HEAD': 'Нач. кафедри', 'SUPERADMIN': 'Адміністратор',
};

// ── AdminPage ──────────────────────────────────────────────────────────────────

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 6, vsync: this); }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Адмін-панель'),
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
              isScrollable: true,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMid,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Користувачі'), Tab(text: 'Факультети'),
                Tab(text: 'Кафедри'),     Tab(text: 'Групи'),
                Tab(text: 'Семестри'),    Tab(text: 'Дисципліни'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _UsersTab(), _FacultiesTab(), _KafedrasTab(),
                _GroupsTab(), _SemestersTab(), _DisciplinesAdminTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Користувачі ───────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _kafedras = [];
  final _searchCtrl = TextEditingController();
  String _roleFilter = '';
  int _page = 0;
  int _totalElements = 0;
  static const _pageSize = 20;
  bool _loading = true;
  String? _error;
  Timer? _searchDebounce;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadRefData();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRefData() async {
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);
    // Застосовуємо кеш для форм редагування
    final cg = cache.get<List<dynamic>>('admin_ref_groups');
    final ck = cache.get<List<dynamic>>('admin_ref_kafedras');
    if (cg != null || ck != null) {
      setState(() {
        if (cg != null) _groups = cg.cast<Map<String, dynamic>>();
        if (ck != null) _kafedras = ck.cast<Map<String, dynamic>>();
      });
    }
    if (!network.isOnline) return;
    try {
      final groupData = await ref.read(groupsRepositoryProvider).getGroups();
      final kafedraData = await ref.read(kafedrasRepositoryProvider).getKafedras();
      if (!mounted) return;
      final groups = groupData.cast<Map<String, dynamic>>();
      final kafedras = kafedraData.cast<Map<String, dynamic>>();
      await cache.set('admin_ref_groups', groups);
      await cache.set('admin_ref_kafedras', kafedras);
      setState(() { _groups = groups; _kafedras = kafedras; });
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      final name    = (u['name']    as String? ?? '').toLowerCase();
      final surname = (u['surname'] as String? ?? '').toLowerCase();
      final email   = (u['email']   as String? ?? '').toLowerCase();
      return name.contains(q) || surname.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final seq = ++_loadSeq;
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);
    setState(() { _error = null; });

    // Кеш тільки для сторінки 0 без фільтрів (типовий вигляд)
    final isDefault = _page == 0 && _roleFilter.isEmpty && _searchCtrl.text.trim().isEmpty;
    if (isDefault) {
      final cached = cache.get<Map<String, dynamic>>('admin_users');
      if (cached != null) {
        final content = (cached['content'] as List? ?? []).cast<Map<String, dynamic>>();
        final total = cached['totalElements'] as int? ?? content.length;
        setState(() { _users = content; _totalElements = total; });
      }
    }

    if (!network.isOnline) {
      setState(() { _loading = false; });
      return;
    }

    setState(() { _loading = _users.isEmpty; });
    try {
      final hasSearch = _searchCtrl.text.trim().isNotEmpty;
      final fetchSize = hasSearch ? 10000 : _pageSize;
      final result = await ref.read(userRepositoryProvider).getUsers(
        page: hasSearch ? 0 : _page,
        size: fetchSize,
        role: _roleFilter.isEmpty ? null : _roleFilter,
      );
      if (!mounted || seq != _loadSeq) return;
      final content = (result['content'] as List? ?? []).cast<Map<String, dynamic>>();
      final total = result['totalElements'] as int? ?? content.length;
      if (isDefault) await cache.set('admin_users', result);
      setState(() { _users = content; _totalElements = total; _loading = false; });
    } catch (e) {
      if (!mounted || seq != _loadSeq) return;
      setState(() { _error = _users.isEmpty ? e.toString() : null; _loading = false; });
    }
  }

  int get _totalPages => ((_totalElements + _pageSize - 1) ~/ _pageSize).clamp(1, 9999);

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _page = 0);
      _load();
    });
  }

  void _openSheet([Map<String, dynamic>? user]) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSheet(
        initial: user,
        groups: _groups, kafedras: _kafedras,
        onSubmit: (data) {
          final cadetRepo   = ref.read(cadetsRepositoryProvider);
          final teacherRepo = ref.read(teachersRepositoryProvider);
          final newRole = (data['roles'] as List?)?.firstOrNull?.toString() ?? '';
          final existingRole = ((user?['roles'] as List?)?.firstOrNull?.toString()) ?? '';
          final role = user == null ? newRole : existingRole;

          Future<dynamic> future;
          if (user == null) {
            future = role == 'CADET'
                ? cadetRepo.createCadet(data)
                : teacherRepo.createTeacher(data);
          } else {
            final id = user['id'] as int;
            future = role == 'CADET'
                ? cadetRepo.updateCadet(id, data)
                : teacherRepo.updateTeacher(id, data);
          }

          future
            .then((_) { if (mounted) { setState(() => _page = 0); _load(); } })
            .catchError((e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Помилка: $e')));
            });
        },
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> user) {
    String mode = 'DEACTIVATE';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Видалити ${user['name']} ${user['surname']}?'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _RadioTile(
              label: 'Деактивувати',
              subtitle: 'Зберегти дані, заблокувати доступ',
              selected: mode == 'DEACTIVATE',
              onTap: () => setLocal(() => mode = 'DEACTIVATE'),
            ),
            _RadioTile(
              label: 'Повне видалення',
              subtitle: 'Видалити всі дані назавжди',
              selected: mode == 'FULL',
              onTap: () => setLocal(() => mode = 'FULL'),
              danger: true,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(ctx);
                final userRole = ((user['roles'] as List?)?.firstOrNull?.toString()) ?? '';
                final Future<void> deleteFuture = userRole == 'CADET'
                    ? ref.read(cadetsRepositoryProvider).deleteCadet(user['id'] as int, mode: mode)
                    : ref.read(teachersRepositoryProvider).deleteTeacher(user['id'] as int, mode: mode);
                deleteFuture
                    .then((_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${user['name']} ${user['surname']} видалено')));
                      _load();
                    })
                    .catchError((e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Помилка: $e')));
                    });
              },
              child: const Text('Підтвердити'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalPages;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
        child: Row(children: [
          const Expanded(
            child: Text('Користувачі',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Перерахувати оцінки',
            color: AppTheme.primary,
            onPressed: () {
              ref.read(ratesRepositoryProvider).recalculateRates()
                  .then((r) {
                    if (!mounted) return;
                    final updated = r['updated'] ?? '?';
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Оцінки перераховано: $updated записів')));
                  })
                  .catchError((e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Помилка: $e')));
                  });
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Створити користувача',
            color: const Color(0xFF16A34A),
            onPressed: _openSheet,
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Пошук за іменем або email...',
            prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textMid),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _RoleChip(label: 'Всі', selected: _roleFilter.isEmpty,
                onTap: () { setState(() { _roleFilter = ''; _page = 0; }); _load(); }),
            ..._roles.entries.map((e) => _RoleChip(
              label: e.value,
              selected: _roleFilter == e.key,
              onTap: () { setState(() { _roleFilter = e.key; _page = 0; }); _load(); },
            )),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: _loading && _users.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _users.isEmpty
                ? _ErrorView(error: _error!, onRetry: _load)
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('Нічого не знайдено', style: TextStyle(color: AppTheme.textMid)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (_, i) {
                          final u = _filteredUsers[i];
                          final name = (u['name'] as String? ?? '');
                          final surname = (u['surname'] as String? ?? '');
                          final roles = (u['roles'] as List?) ?? [];
                          final role = roles.isNotEmpty ? roles.first.toString() : '';
                          final roleColor = role == 'SUPERADMIN' ? Colors.purple
                              : role == 'DEPARTMENT_HEAD' ? Colors.orange
                              : role == 'TEACHER' ? AppTheme.secondary : AppTheme.primary;
                          final initials = '${name.isNotEmpty ? name[0] : ''}${surname.isNotEmpty ? surname[0] : ''}';
                          final orgUnit = role == 'CADET'
                              ? 'Група ${u['groupName'] ?? ''}'
                              : (u['kafedraName'] as String? ?? '');
                          final rankLabel = _ranks[u['rank']] ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: InkWell(
                              onTap: () => _openSheet(u),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: roleColor.withAlpha(30),
                                    child: Text(initials.toUpperCase(),
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: roleColor)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('$surname $name',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: roleColor.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                                          child: Text(_roles[role] ?? role,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
                                        ),
                                        if (rankLabel.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(rankLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                                        ],
                                      ]),
                                      const SizedBox(height: 2),
                                      Text(u['email'] as String? ?? '',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMid),
                                          overflow: TextOverflow.ellipsis),
                                      if (orgUnit.isNotEmpty)
                                        Text(orgUnit, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                                    ]),
                                  ),
                                  Column(mainAxisSize: MainAxisSize.min, children: [
                                    _IconBtn(icon: Icons.edit_outlined, color: const Color(0xFF16A34A), onTap: () => _openSheet(u)),
                                    _IconBtn(icon: Icons.delete_outline, color: const Color(0xFFEF4444), onTap: () => _showDeleteDialog(u)),
                                  ]),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      if (total > 1 && _searchCtrl.text.trim().isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))), color: Colors.white),
          child: Row(children: [
            Text('$_totalElements записів', style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.chevron_left), iconSize: 20, padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _page > 0 ? () { setState(() => _page--); _load(); } : null),
            Text('${_page + 1} / $total', style: const TextStyle(fontSize: 13)),
            IconButton(icon: const Icon(Icons.chevron_right), iconSize: 20, padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _page < total - 1 ? () { setState(() => _page++); _load(); } : null),
          ]),
        ),
    ]);
  }
}

class _UserSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> groups, kafedras;
  final void Function(Map<String, dynamic>) onSubmit;
  const _UserSheet({this.initial, required this.groups, required this.kafedras, required this.onSubmit});
  @override
  State<_UserSheet> createState() => _UserSheetState();
}

class _UserSheetState extends State<_UserSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _surnameCtrl, _emailCtrl, _phoneCtrl, _birthdayCtrl;
  late String _role, _rank, _position, _gender, _studyRank, _studyPosition;
  int? _groupId, _kafedraId;

  bool get _isTeacher => _role == 'TEACHER' || _role == 'DEPARTMENT_HEAD';
  bool get _isCadet => _role == 'CADET';

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _nameCtrl     = TextEditingController(text: d?['name'] as String? ?? '');
    _surnameCtrl  = TextEditingController(text: d?['surname'] as String? ?? '');
    _emailCtrl    = TextEditingController(text: d?['email'] as String? ?? '');
    _phoneCtrl    = TextEditingController(text: d?['phoneNumber'] as String? ?? '');
    _birthdayCtrl = TextEditingController(text: d?['birthday'] as String? ?? '');
    final serverRoles = (d?['roles'] as List?)?.map((r) => r.toString()).toList() ?? [];
    _role         = serverRoles.isNotEmpty ? serverRoles.first : 'CADET';
    _rank         = d?['rank'] as String? ?? '';
    _position     = d?['position'] as String? ?? '';
    _gender       = d?['gender'] as String? ?? '';
    _studyRank    = d?['scientificDegree'] as String? ?? '';
    _studyPosition = d?['academicRank'] as String? ?? '';
    _groupId      = d?['groupId'] as int?;
    _kafedraId    = d?['kafedraId'] as int?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _surnameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _birthdayCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final isCreate = widget.initial == null;
    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'surname': _surnameCtrl.text.trim(),
      if (_rank.isNotEmpty) 'rank': _rank,
      if (_position.isNotEmpty) 'position': _position,
      if (_gender.isNotEmpty) 'gender': _gender,
      if (_phoneCtrl.text.trim().isNotEmpty) 'phoneNumber': _phoneCtrl.text.trim(),
      if (_birthdayCtrl.text.trim().isNotEmpty) 'birthday': _birthdayCtrl.text.trim(),
      if (_isTeacher && _studyRank.isNotEmpty) 'scientificDegree': _studyRank,
      if (_isTeacher && _studyPosition.isNotEmpty) 'academicRank': _studyPosition,
      if (_isCadet && _groupId != null) 'groupId': _groupId,
      if (_isTeacher && _kafedraId != null) 'kafedraId': _kafedraId,
    };
    if (isCreate) {
      body['email'] = _emailCtrl.text.trim();
      body['roles'] = [_role];
    }
    widget.onSubmit(body);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return _SheetFrame(
      title: isEdit ? 'Редагувати користувача' : 'Новий користувач',
      onClose: () => Navigator.pop(context),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FieldLabel("Ім'я", required: true),
        _FormTextField(ctrl: _nameCtrl, hint: "Ім'я",
            validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
        const SizedBox(height: 12),
        _FieldLabel('Прізвище', required: true),
        _FormTextField(ctrl: _surnameCtrl, hint: 'Прізвище',
            validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
        const SizedBox(height: 12),
        _FieldLabel('Email', required: true),
        _FormTextField(ctrl: _emailCtrl, hint: 'email@viti.edu.ua',
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              if (v?.trim().isEmpty ?? true) return "Обов'язкове поле";
              if (!v!.contains('@')) return 'Невірний email';
              return null;
            }),
        const SizedBox(height: 12),
        _FieldLabel('Роль', required: true),
        _FormDrop<String>(
          value: _role,
          items: _roles.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() { _role = v!; _groupId = null; _kafedraId = null; }),
        ),
        const SizedBox(height: 12),
        if (_isCadet) ...[
          _FieldLabel('Група', required: true),
          _FormDrop<int>(
            value: _groupId,
            hint: 'Оберіть групу',
            items: widget.groups.map((g) =>
                DropdownMenuItem(value: g['id'] as int, child: Text(g['name'] as String))).toList(),
            onChanged: (v) => setState(() => _groupId = v),
            validator: (v) => v == null ? 'Оберіть групу' : null,
          ),
          const SizedBox(height: 12),
        ],
        if (_isTeacher) ...[
          _FieldLabel('Кафедра', required: true),
          _FormDrop<int>(
            value: _kafedraId,
            hint: 'Оберіть кафедру',
            items: widget.kafedras.map((k) => DropdownMenuItem(
              value: k['id'] as int,
              child: Text(k['name'] as String, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) => setState(() => _kafedraId = v),
            validator: (v) => v == null ? 'Оберіть кафедру' : null,
          ),
          const SizedBox(height: 12),
        ],
        _FieldLabel('Звання'),
        _FormDrop<String>(
          value: _rank.isEmpty ? null : _rank, hint: 'Оберіть звання',
          items: _ranks.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _rank = v ?? ''),
        ),
        const SizedBox(height: 12),
        _FieldLabel('Посада'),
        _FormDrop<String>(
          value: _position.isEmpty ? null : _position, hint: 'Оберіть посаду',
          items: _positions.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _position = v ?? ''),
        ),
        const SizedBox(height: 12),
        _FieldLabel('Стать'),
        _FormDrop<String>(
          value: _gender.isEmpty ? null : _gender, hint: 'Оберіть стать',
          items: _genders.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _gender = v ?? ''),
        ),
        const SizedBox(height: 12),
        _FieldLabel('Телефон'),
        _FormTextField(ctrl: _phoneCtrl, hint: '+380XXXXXXXXX', keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _FieldLabel('Дата народження'),
        _FormTextField(ctrl: _birthdayCtrl, hint: 'РРРР-ММ-ДД'),
        if (_isTeacher) ...[
          const SizedBox(height: 12),
          _FieldLabel('Вчений ступінь'),
          _FormDrop<String>(
            value: _studyRank.isEmpty ? null : _studyRank, hint: 'Оберіть ступінь',
            items: _studyRanks.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _studyRank = v ?? ''),
          ),
          const SizedBox(height: 12),
          _FieldLabel('Наукове звання'),
          _FormDrop<String>(
            value: _studyPosition.isEmpty ? null : _studyPosition, hint: 'Оберіть наукове звання',
            items: _studyPositions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _studyPosition = v ?? ''),
          ),
        ],
        const SizedBox(height: 24),
        _SheetActions(onCancel: () => Navigator.pop(context), onSubmit: _submit,
            submitLabel: isEdit ? 'Зберегти' : 'Створити'),
      ])),
    );
  }
}

// ── Факультети ────────────────────────────────────────────────────────────────

class _FacultiesTab extends ConsumerStatefulWidget {
  const _FacultiesTab();
  @override
  ConsumerState<_FacultiesTab> createState() => _FacultiesTabState();
}

class _FacultiesTabState extends ConsumerState<_FacultiesTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);
    setState(() => _error = null);
    final cached = cache.get<List<dynamic>>('admin_faculties');
    if (cached != null) setState(() => _items = cached.cast<Map<String, dynamic>>());
    if (!network.isOnline) { setState(() => _loading = false); return; }
    setState(() => _loading = _items.isEmpty);
    try {
      final data = await ref.read(facultiesRepositoryProvider).getFaculties();
      if (!mounted) return;
      final items = data.cast<Map<String, dynamic>>();
      await cache.set('admin_faculties', items);
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _items.isEmpty ? e.toString() : null; _loading = false; });
    }
  }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FacultySheet(
      initial: item,
      onSubmit: (name, number) {
        final repo = ref.read(facultiesRepositoryProvider);
        final future = item == null
            ? repo.createFaculty({'name': name, 'number': number})
            : repo.updateFaculty(item['id'] as int, {'name': name, 'number': number});
        future
          .then((_) { if (mounted) _load(); })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: item['name'] as String,
      onConfirm: () {
        ref.read(facultiesRepositoryProvider).deleteFaculty(item['id'] as int)
          .then((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Факультет "${item['name']}" видалено')));
            _load();
          })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    return _ListTab(
      title: 'Управління факультетами',
      createLabel: 'Створити',
      onCreate: () => _openSheet(),
      items: _items,
      titleOf: (f) => f['name'] as String,
      subtitleOf: (f) => 'Факультет №${f['number']}',
      onEdit: _openSheet, onDelete: _confirmDelete,
    );
  }
}

class _FacultySheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final void Function(String name, int number) onSubmit;
  const _FacultySheet({this.initial, required this.onSubmit});
  @override
  State<_FacultySheet> createState() => _FacultySheetState();
}

class _FacultySheetState extends State<_FacultySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _numCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?['name'] as String? ?? '');
    _numCtrl  = TextEditingController(text: widget.initial?['number']?.toString() ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _numCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_nameCtrl.text.trim(), int.tryParse(_numCtrl.text) ?? 0);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: widget.initial == null ? 'Новий факультет' : 'Редагувати факультет',
    onClose: () => Navigator.pop(context),
    child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel('Назва', required: true),
      _FormTextField(ctrl: _nameCtrl, hint: 'Назва факультету',
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Номер', required: true),
      _FormTextField(ctrl: _numCtrl, hint: '1', keyboard: TextInputType.number,
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return "Обов'язкове поле";
            if (int.tryParse(v!) == null || int.parse(v) <= 0) return 'Введіть додатне число';
            return null;
          }),
      const SizedBox(height: 24),
      _SheetActions(onCancel: () => Navigator.pop(context), onSubmit: _submit,
          submitLabel: widget.initial == null ? 'Створити' : 'Зберегти'),
    ])),
  );
}

// ── Кафедри ───────────────────────────────────────────────────────────────────

class _KafedrasTab extends ConsumerStatefulWidget {
  const _KafedrasTab();
  @override
  ConsumerState<_KafedrasTab> createState() => _KafedrasTabState();
}

class _KafedrasTabState extends ConsumerState<_KafedrasTab> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _faculties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);
    setState(() => _error = null);
    final ck = cache.get<List<dynamic>>('admin_kafedras');
    final cf = cache.get<List<dynamic>>('admin_faculties');
    if (ck != null) setState(() => _items = ck.cast<Map<String, dynamic>>());
    if (cf != null) setState(() => _faculties = cf.cast<Map<String, dynamic>>());
    if (!network.isOnline) { setState(() => _loading = false); return; }
    setState(() => _loading = _items.isEmpty);
    try {
      final kafedraData = await ref.read(kafedrasRepositoryProvider).getKafedras();
      final facultyData = await ref.read(facultiesRepositoryProvider).getFaculties();
      if (!mounted) return;
      final kafedras = kafedraData.cast<Map<String, dynamic>>();
      final faculties = facultyData.cast<Map<String, dynamic>>();
      await cache.set('admin_kafedras', kafedras);
      await cache.set('admin_faculties', faculties);
      setState(() { _items = kafedras; _faculties = faculties; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _items.isEmpty ? e.toString() : null; _loading = false; });
    }
  }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _KafedraSheet(
      initial: item, faculties: _faculties,
      onSubmit: (data) {
        final repo = ref.read(kafedrasRepositoryProvider);
        final future = item == null
            ? repo.createKafedra(data)
            : repo.updateKafedra(item['id'] as int, data);
        future
          .then((_) { if (mounted) _load(); })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: item['name'] as String,
      onConfirm: () {
        ref.read(kafedrasRepositoryProvider).deleteKafedra(item['id'] as int)
          .then((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Кафедру "${item['name']}" видалено')));
            _load();
          })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    return _ListTab(
      title: 'Управління кафедрами',
      createLabel: 'Створити',
      onCreate: () => _openSheet(),
      items: _items,
      titleOf: (k) => k['name'] as String,
      subtitleOf: (k) => 'Кафедра №${k['number']}',
      onEdit: _openSheet, onDelete: _confirmDelete,
    );
  }
}

class _KafedraSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> faculties;
  final void Function(Map<String, dynamic>) onSubmit;
  const _KafedraSheet({this.initial, required this.faculties, required this.onSubmit});
  @override
  State<_KafedraSheet> createState() => _KafedraSheetState();
}

class _KafedraSheetState extends State<_KafedraSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _numCtrl;
  int? _facultyId;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.initial?['name'] as String? ?? '');
    _numCtrl   = TextEditingController(text: widget.initial?['number']?.toString() ?? '');
    _facultyId = widget.initial?['facultyId'] as int?;
  }

  @override
  void dispose() { _nameCtrl.dispose(); _numCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final faculty = widget.faculties.where((f) => f['id'] == _facultyId).cast<Map<String,dynamic>?>().firstOrNull;
    widget.onSubmit({
      'name': _nameCtrl.text.trim(),
      'number': int.tryParse(_numCtrl.text) ?? 0,
      'facultyId': _facultyId,
      'facultyName': faculty?['name'] ?? '',
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: widget.initial == null ? 'Нова кафедра' : 'Редагувати кафедру',
    onClose: () => Navigator.pop(context),
    child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel('Назва', required: true),
      _FormTextField(ctrl: _nameCtrl, hint: 'Назва кафедри',
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Номер', required: true),
      _FormTextField(ctrl: _numCtrl, hint: '21', keyboard: TextInputType.number,
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return "Обов'язкове поле";
            if (int.tryParse(v!) == null || int.parse(v) <= 0) return 'Введіть додатне число';
            return null;
          }),
      const SizedBox(height: 12),
      _FieldLabel('Факультет'),
      _FormDrop<int>(
        value: _facultyId, hint: "Не обрано (необов'язково)",
        items: widget.faculties.map((f) =>
            DropdownMenuItem(value: f['id'] as int, child: Text(f['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) => setState(() => _facultyId = v),
      ),
      const SizedBox(height: 24),
      _SheetActions(onCancel: () => Navigator.pop(context), onSubmit: _submit,
          submitLabel: widget.initial == null ? 'Створити' : 'Зберегти'),
    ])),
  );
}

// ── Групи ─────────────────────────────────────────────────────────────────────

class _GroupsTab extends ConsumerStatefulWidget {
  const _GroupsTab();
  @override
  ConsumerState<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<_GroupsTab> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _faculties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);
    setState(() => _error = null);
    final cg = cache.get<List<dynamic>>('admin_groups');
    final cf = cache.get<List<dynamic>>('admin_faculties');
    if (cg != null) setState(() => _items = cg.cast<Map<String, dynamic>>());
    if (cf != null) setState(() => _faculties = cf.cast<Map<String, dynamic>>());
    if (!network.isOnline) { setState(() => _loading = false); return; }
    setState(() => _loading = _items.isEmpty);
    try {
      final groupData = await ref.read(groupsRepositoryProvider).getGroups();
      final facultyData = await ref.read(facultiesRepositoryProvider).getFaculties();
      if (!mounted) return;
      final groups = groupData.cast<Map<String, dynamic>>();
      final faculties = facultyData.cast<Map<String, dynamic>>();
      await cache.set('admin_groups', groups);
      await cache.set('admin_faculties', faculties);
      setState(() { _items = groups; _faculties = faculties; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _items.isEmpty ? e.toString() : null; _loading = false; });
    }
  }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GroupSheet(
      initial: item, faculties: _faculties,
      onSubmit: (data) {
        final repo = ref.read(groupsRepositoryProvider);
        final future = item == null
            ? repo.createGroup(data)
            : repo.updateGroup(item['id'] as int, data);
        future
          .then((_) { if (mounted) _load(); })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: 'групу ${item['name']}',
      onConfirm: () {
        ref.read(groupsRepositoryProvider).deleteGroup(item['id'] as int)
          .then((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Групу ${item['name']} видалено')));
            _load();
          })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    return _ListTab(
      title: 'Управління групами',
      createLabel: 'Створити',
      onCreate: () => _openSheet(),
      showSearch: true, searchHint: 'Пошук групи...',
      items: _items,
      titleOf: (g) => 'Група ${g['name']}',
      subtitleOf: (g) {
        final spec = _specialities[g['specialty']] ?? (g['specialty'] as String? ?? '');
        return '$spec • ${g['year']} • ${_degrees[g['degree']] ?? ''}';
      },
      onEdit: _openSheet, onDelete: _confirmDelete,
    );
  }
}

class _GroupSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> faculties;
  final void Function(Map<String, dynamic>) onSubmit;
  const _GroupSheet({this.initial, required this.faculties, required this.onSubmit});
  @override
  State<_GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<_GroupSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _yearCtrl;
  String _specialty = '';
  String _type = 'FULL_TIME';
  String _degree = 'BACHELOR';
  int? _facultyId;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _nameCtrl  = TextEditingController(text: d?['name'] as String? ?? '');
    _yearCtrl  = TextEditingController(text: d?['year']?.toString() ?? '');
    _specialty = d?['specialty'] as String? ?? '';
    _type      = d?['type'] as String? ?? 'FULL_TIME';
    _degree    = d?['degree'] as String? ?? 'BACHELOR';
    _facultyId = d?['facultyId'] as int?;
  }

  @override
  void dispose() { _nameCtrl.dispose(); _yearCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'name': _nameCtrl.text.trim(),
      'specialty': _specialty,
      'year': int.tryParse(_yearCtrl.text) ?? 2024,
      if (!_isEdit) 'type': _type,
      if (!_isEdit) 'degree': _degree,
      if (!_isEdit) 'facultyId': _facultyId,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: _isEdit ? 'Редагувати групу' : 'Нова група',
    onClose: () => Navigator.pop(context),
    child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel('Назва групи', required: true),
      _FormTextField(ctrl: _nameCtrl, hint: '121',
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Спеціальність', required: true),
      _FormDrop<String>(
        value: _specialty.isEmpty ? null : _specialty, hint: 'Оберіть спеціальність',
        items: _specialities.entries.map((e) =>
            DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) => setState(() => _specialty = v ?? ''),
        validator: (v) => (v == null || v.isEmpty) ? 'Оберіть спеціальність' : null,
      ),
      const SizedBox(height: 12),
      _FieldLabel('Рік вступу', required: true),
      _FormTextField(ctrl: _yearCtrl, hint: '2024', keyboard: TextInputType.number,
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return "Обов'язкове поле";
            final y = int.tryParse(v!);
            if (y == null || y < 2000 || y > 2100) return 'Введіть коректний рік';
            return null;
          }),
      if (!_isEdit) ...[
        const SizedBox(height: 12),
        _FieldLabel('Форма навчання', required: true),
        _FormDrop<String>(
          value: _type,
          items: _groupTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _type = v ?? 'FULL_TIME'),
        ),
        const SizedBox(height: 12),
        _FieldLabel('Ступінь освіти', required: true),
        _FormDrop<String>(
          value: _degree,
          items: _degrees.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) => setState(() => _degree = v ?? 'BACHELOR'),
        ),
        const SizedBox(height: 12),
        _FieldLabel('Факультет', required: true),
        _FormDrop<int>(
          value: _facultyId, hint: 'Оберіть факультет',
          items: widget.faculties.map((f) =>
              DropdownMenuItem(value: f['id'] as int, child: Text(f['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _facultyId = v),
          validator: (v) => v == null ? 'Оберіть факультет' : null,
        ),
      ],
      const SizedBox(height: 24),
      _SheetActions(onCancel: () => Navigator.pop(context), onSubmit: _submit,
          submitLabel: _isEdit ? 'Зберегти' : 'Створити'),
    ])),
  );
}

// ── Семестри ──────────────────────────────────────────────────────────────────

class _SemestersTab extends ConsumerStatefulWidget {
  const _SemestersTab();
  @override
  ConsumerState<_SemestersTab> createState() => _SemestersTabState();
}

class _SemestersTabState extends ConsumerState<_SemestersTab> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);
    setState(() => _error = null);
    final cs = cache.get<List<dynamic>>('admin_semesters');
    final cg = cache.get<List<dynamic>>('admin_groups');
    if (cs != null) setState(() => _items = cs.cast<Map<String, dynamic>>());
    if (cg != null) setState(() => _groups = cg.cast<Map<String, dynamic>>());
    if (!network.isOnline) { setState(() => _loading = false); return; }
    setState(() => _loading = _items.isEmpty);
    try {
      final semData = await ref.read(semestersRepositoryProvider).getSemesters();
      final groupData = await ref.read(groupsRepositoryProvider).getGroups();
      if (!mounted) return;
      final sems = semData.cast<Map<String, dynamic>>();
      final groups = groupData.cast<Map<String, dynamic>>();
      await cache.set('admin_semesters', sems);
      await cache.set('admin_groups', groups);
      setState(() { _items = sems; _groups = groups; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _items.isEmpty ? e.toString() : null; _loading = false; });
    }
  }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SemesterSheet(
      initial: item, groups: _groups,
      onSubmit: (data) {
        final repo = ref.read(semestersRepositoryProvider);
        final future = item == null
            ? repo.createSemester(data)
            : repo.updateSemester(item['id'] as int, data);
        future
          .then((_) { if (mounted) _load(); })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: 'семестр №${item['number']} (${item['yearStart']}/${item['yearEnd']})',
      onConfirm: () {
        ref.read(semestersRepositoryProvider).deleteSemester(item['id'] as int)
          .then((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Семестр видалено')));
            _load();
          })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    return _ListTab(
      title: 'Управління семестрами',
      createLabel: 'Створити',
      onCreate: () => _openSheet(),
      showSearch: true, searchHint: 'Пошук за номером...',
      items: _items,
      titleOf: (s) => 'Семестр №${s['number']} (${s['yearStart']}/${s['yearEnd']})',
      subtitleOf: (s) => '${s['start']} — ${s['end']} • ${_degrees[s['degree']] ?? ''}',
      onEdit: _openSheet, onDelete: _confirmDelete,
    );
  }
}

class _SemesterSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> groups;
  final void Function(Map<String, dynamic>) onSubmit;
  const _SemesterSheet({this.initial, required this.groups, required this.onSubmit});
  @override
  State<_SemesterSheet> createState() => _SemesterSheetState();
}

class _SemesterSheetState extends State<_SemesterSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numCtrl, _startCtrl, _endCtrl, _yearStartCtrl, _yearEndCtrl;
  String _degree = 'BACHELOR';
  final Set<int> _selectedGroupIds = {};

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _numCtrl       = TextEditingController(text: d?['number']?.toString() ?? '');
    _startCtrl     = TextEditingController(text: d?['start'] as String? ?? '');
    _endCtrl       = TextEditingController(text: d?['end'] as String? ?? '');
    _yearStartCtrl = TextEditingController(text: d?['yearStart']?.toString() ?? '');
    _yearEndCtrl   = TextEditingController(text: d?['yearEnd']?.toString() ?? '');
    _degree        = d?['degree'] as String? ?? 'BACHELOR';
  }

  @override
  void dispose() {
    _numCtrl.dispose(); _startCtrl.dispose(); _endCtrl.dispose();
    _yearStartCtrl.dispose(); _yearEndCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit({
      'number':    int.tryParse(_numCtrl.text) ?? 1,
      'start':     _startCtrl.text.trim(),
      'end':       _endCtrl.text.trim(),
      'yearStart': int.tryParse(_yearStartCtrl.text) ?? 2024,
      'yearEnd':   int.tryParse(_yearEndCtrl.text) ?? 2025,
      'degree':    _degree,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: _isEdit ? 'Редагувати семестр' : 'Новий семестр',
    onClose: () => Navigator.pop(context),
    child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel('Номер семестру', required: true),
      _FormTextField(ctrl: _numCtrl, hint: '1', keyboard: TextInputType.number,
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Дата початку', required: true),
      _FormTextField(ctrl: _startCtrl, hint: 'РРРР-ММ-ДД',
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Дата закінчення', required: true),
      _FormTextField(ctrl: _endCtrl, hint: 'РРРР-ММ-ДД',
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Рік початку навч. плану', required: true),
      _FormTextField(ctrl: _yearStartCtrl, hint: '2024', keyboard: TextInputType.number,
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Рік закінчення навч. плану', required: true),
      _FormTextField(ctrl: _yearEndCtrl, hint: '2025', keyboard: TextInputType.number,
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Ступінь освіти', required: true),
      _FormDrop<String>(
        value: _degree,
        items: _degrees.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
        onChanged: (v) => setState(() => _degree = v ?? 'BACHELOR'),
      ),
      if (_isEdit) ...[
        const SizedBox(height: 16),
        const Text('Групи семестру', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
        const SizedBox(height: 6),
        ...widget.groups.map((g) => CheckboxListTile(
          value: _selectedGroupIds.contains(g['id'] as int),
          onChanged: (checked) => setState(() {
            if (checked == true) _selectedGroupIds.add(g['id'] as int);
            else _selectedGroupIds.remove(g['id'] as int);
          }),
          title: Text(g['name'] as String, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            _specialities[g['specialty']] ?? (g['specialty'] as String? ?? ''),
            style: const TextStyle(fontSize: 11, color: AppTheme.textMid),
            overflow: TextOverflow.ellipsis,
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primary,
        )),
      ],
      const SizedBox(height: 24),
      _SheetActions(onCancel: () => Navigator.pop(context), onSubmit: _submit,
          submitLabel: _isEdit ? 'Зберегти' : 'Створити'),
    ])),
  );
}

// ── Дисципліни (адмін) ────────────────────────────────────────────────────────

class _DisciplinesAdminTab extends ConsumerStatefulWidget {
  const _DisciplinesAdminTab();
  @override
  ConsumerState<_DisciplinesAdminTab> createState() => _DisciplinesAdminTabState();
}

class _DisciplinesAdminTabState extends ConsumerState<_DisciplinesAdminTab> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _kafedras = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    final cache = ref.read(localCacheProvider);
    final network = ref.read(networkMonitorProvider);
    setState(() => _error = null);
    final cd = cache.get<List<dynamic>>('admin_disciplines');
    final ck = cache.get<List<dynamic>>('admin_kafedras');
    if (cd != null) setState(() => _items = cd.cast<Map<String, dynamic>>());
    if (ck != null) setState(() => _kafedras = ck.cast<Map<String, dynamic>>());
    if (!network.isOnline) { setState(() => _loading = false); return; }
    setState(() => _loading = _items.isEmpty);
    try {
      final disciplines = await ref.read(disciplinesRepositoryProvider).getAllDisciplines();
      final kafedraData = await ref.read(kafedrasRepositoryProvider).getKafedras();
      if (!mounted) return;
      final kafedras = kafedraData.cast<Map<String, dynamic>>();
      final kafedraMap = {
        for (final k in kafedras) (k['id'] as int): (k['name'] as String? ?? '')
      };
      final items = disciplines.map((d) => <String, dynamic>{
        'id': d.id,
        'name': d.fullName,
        'short': d.shortName ?? '',
        'kafedraId': d.kafedraId,
        'kafedraName': d.kafedraId != null ? (kafedraMap[d.kafedraId] ?? '') : '',
        'journals': d.journalCount,
      }).toList();
      await cache.set('admin_disciplines', items);
      await cache.set('admin_kafedras', kafedras);
      setState(() { _kafedras = kafedras; _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _items.isEmpty ? e.toString() : null; _loading = false; });
    }
  }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DisciplineSheet(
      initial: item, kafedras: _kafedras,
      onSubmit: (data) {
        final repo = ref.read(disciplinesRepositoryProvider);
        final future = item == null
            ? repo.createDiscipline(data)
            : repo.updateDiscipline(item['id'] as int, data);
        future
          .then((_) { if (mounted) _load(); })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: item['name'] as String,
      onConfirm: () {
        ref.read(disciplinesRepositoryProvider).deleteDiscipline(item['id'] as int)
          .then((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Дисципліну "${item['short']}" видалено')));
            _load();
          })
          .catchError((e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e')));
          });
      },
    ),
  );

  void _openMoveJournal(Map<String, dynamic> item) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MoveJournalSheet(discipline: item, disciplines: _items),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          const Text('Управління дисциплінами',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
          const Spacer(),
          _ActionButton(label: 'Створити', color: AppTheme.primary, onTap: () => _openSheet()),
        ]),
      ),
      Expanded(
        child: _items.isEmpty
            ? const Center(child: Text('Дисциплін немає', style: TextStyle(color: AppTheme.textMid)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final d = _items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: InkWell(
                      onTap: () => _openSheet(d),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                              child: Text(d['short'] as String,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(d['kafedraName'] as String,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMid),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(6)),
                              child: Text('${d['journals']} журн.',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(d['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.swap_horiz, size: 16),
                                label: const Text('Перенести журнал', style: TextStyle(fontSize: 12)),
                                onPressed: () => _openMoveJournal(d),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _IconBtn(icon: Icons.edit_outlined, color: const Color(0xFF16A34A), onTap: () => _openSheet(d)),
                            _IconBtn(icon: Icons.delete_outline, color: const Color(0xFFEF4444), onTap: () => _confirmDelete(d)),
                          ]),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _DisciplineSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> kafedras;
  final void Function(Map<String, dynamic>) onSubmit;
  const _DisciplineSheet({this.initial, required this.kafedras, required this.onSubmit});
  @override
  State<_DisciplineSheet> createState() => _DisciplineSheetState();
}

class _DisciplineSheetState extends State<_DisciplineSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _shortCtrl;
  int? _kafedraId;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.initial?['name'] as String? ?? '');
    _shortCtrl = TextEditingController(text: widget.initial?['short'] as String? ?? '');
    _kafedraId = widget.initial?['kafedraId'] as int?;
  }

  @override
  void dispose() { _nameCtrl.dispose(); _shortCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final kafedra = widget.kafedras.where((k) => k['id'] == _kafedraId).cast<Map<String,dynamic>?>().firstOrNull;
    widget.onSubmit({
      'fullName':   _nameCtrl.text.trim(),
      'shortName':  _shortCtrl.text.trim(),
      'kafedraId':  _kafedraId,
      'kafedraName': kafedra?['name'] ?? '',
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: widget.initial == null ? 'Нова дисципліна' : 'Редагувати дисципліну',
    onClose: () => Navigator.pop(context),
    child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FieldLabel('Повна назва', required: true),
      _FormTextField(ctrl: _nameCtrl, hint: 'Повна назва дисципліни', maxLines: 2,
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Коротка назва', required: true),
      _FormTextField(ctrl: _shortCtrl, hint: 'РПЗ',
          maxLength: 10,
          validator: (v) => (v?.trim().isEmpty ?? true) ? "Обов'язкове поле" : null),
      const SizedBox(height: 12),
      _FieldLabel('Кафедра', required: true),
      _FormDrop<int>(
        value: _kafedraId, hint: 'Оберіть кафедру',
        items: widget.kafedras.map((k) =>
            DropdownMenuItem(value: k['id'] as int, child: Text(k['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: (v) => setState(() => _kafedraId = v),
        validator: (v) => v == null ? 'Оберіть кафедру' : null,
      ),
      const SizedBox(height: 24),
      _SheetActions(onCancel: () => Navigator.pop(context), onSubmit: _submit,
          submitLabel: widget.initial == null ? 'Створити' : 'Зберегти'),
    ])),
  );
}

class _MoveJournalSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> discipline;
  final List<Map<String, dynamic>> disciplines;
  const _MoveJournalSheet({required this.discipline, required this.disciplines});
  @override
  ConsumerState<_MoveJournalSheet> createState() => _MoveJournalSheetState();
}

class _MoveJournalSheetState extends ConsumerState<_MoveJournalSheet> {
  int? _targetId;
  bool _loading = false;

  Future<void> _move() async {
    if (_targetId == null) return;
    setState(() => _loading = true);
    try {
      final journalRepo = ref.read(journalsRepositoryProvider);
      final journals = await journalRepo.getJournals(
          disciplineId: widget.discipline['id'] as int);
      for (final j in journals) {
        final id = j['id'] as int?;
        if (id != null) await journalRepo.updateJournal(id, {'disciplineId': _targetId});
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          'Перенесено ${journals.length} журн. до дисципліни "${widget.disciplines.firstWhere((d) => d['id'] == _targetId)['short']}"'
        )),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final others = widget.disciplines.where((d) => d['id'] != widget.discipline['id']).toList();
    return _SheetFrame(
      title: 'Перенести журнал',
      onClose: () => Navigator.pop(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('З дисципліни: ${widget.discipline['short']} — ${widget.discipline['name']}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMid)),
        const SizedBox(height: 16),
        _FieldLabel('Перенести до дисципліни', required: true),
        _FormDrop<int>(
          value: _targetId, hint: 'Оберіть дисципліну',
          items: others.map((d) => DropdownMenuItem(
            value: d['id'] as int,
            child: Text('${d['short']} — ${d['name']}', overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (v) => setState(() => _targetId = v),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: const Text('Скасувати'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: (_targetId == null || _loading) ? null : _move,
            child: _loading
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Перенести'),
          )),
        ]),
      ]),
    );
  }
}

// ── Generic list tab (card layout) ────────────────────────────────────────────

class _ListTab extends StatefulWidget {
  final String title, createLabel;
  final VoidCallback onCreate;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) titleOf;
  final String Function(Map<String, dynamic>) subtitleOf;
  final void Function(Map<String, dynamic>) onEdit, onDelete;
  final bool showSearch;
  final String searchHint;

  const _ListTab({
    required this.title, required this.createLabel, required this.onCreate,
    required this.items, required this.titleOf, required this.subtitleOf,
    required this.onEdit, required this.onDelete,
    this.showSearch = false, this.searchHint = 'Пошук...',
  });

  @override
  State<_ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<_ListTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((item) =>
        widget.titleOf(item).toLowerCase().contains(q) ||
        widget.subtitleOf(item).toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Expanded(child: Text(widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark))),
          _ActionButton(label: widget.createLabel, color: AppTheme.primary, onTap: widget.onCreate),
        ]),
      ),
      if (widget.showSearch)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(height: 36, child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMid),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
          )),
        ),
      Expanded(
        child: filtered.isEmpty
            ? const Center(child: Text('Нічого не знайдено', style: TextStyle(color: AppTheme.textMid)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: InkWell(
                      onTap: () => widget.onEdit(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(widget.titleOf(item),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark)),
                              const SizedBox(height: 3),
                              Text(widget.subtitleOf(item),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
                            ]),
                          ),
                          _IconBtn(icon: Icons.edit_outlined, color: const Color(0xFF16A34A),
                              onTap: () => widget.onEdit(item)),
                          _IconBtn(icon: Icons.delete_outline, color: const Color(0xFFEF4444),
                              onTap: () => widget.onDelete(item)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text('Помилка завантаження', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        const SizedBox(height: 6),
        Text(error, style: const TextStyle(fontSize: 12, color: AppTheme.textMid), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Спробувати знову'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
          onPressed: onRetry,
        ),
      ]),
    ),
  );
}

// ── Shared UI components ──────────────────────────────────────────────────────

class _SheetFrame extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  final Widget child;
  const _SheetFrame({required this.title, required this.onClose, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(children: [
            Expanded(child: Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
            IconButton(icon: const Icon(Icons.close), onPressed: onClose,
                padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
        ),
        const Divider(height: 16),
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: child,
        )),
      ]),
    );
  }
}

class _SheetActions extends StatelessWidget {
  final VoidCallback onCancel, onSubmit;
  final String submitLabel;
  const _SheetActions({required this.onCancel, required this.onSubmit, required this.submitLabel});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: OutlinedButton(onPressed: onCancel, child: const Text('Скасувати'))),
    const SizedBox(width: 12),
    Expanded(child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
      onPressed: onSubmit,
      child: Text(submitLabel),
    )),
  ]);
}

class _DeleteDialog extends StatelessWidget {
  final String name;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.name, required this.onConfirm});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Підтвердити видалення'),
    content: Text('Ви впевнені, що хочете видалити $name?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Скасувати')),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        onPressed: () { Navigator.pop(context); onConfirm(); },
        child: const Text('Видалити'),
      ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
      if (required) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 13)),
    ]),
  );
}

class _FormTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboard;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  const _FormTextField({
    required this.ctrl, required this.hint,
    this.keyboard = TextInputType.text, this.maxLines = 1,
    this.maxLength, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: keyboard,
    maxLines: maxLines,
    maxLength: maxLength,
    validator: validator,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textMid),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      counterText: maxLength != null ? null : '',
    ),
  );
}

class _FormDrop<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  const _FormDrop({this.value, this.hint, required this.items,
      required this.onChanged, this.validator});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    value: value,
    hint: hint != null ? Text(hint!, style: const TextStyle(color: AppTheme.textMid, fontSize: 14)) : null,
    isExpanded: true,
    items: items,
    onChanged: onChanged,
    validator: validator,
    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
  );
}

class _RadioTile extends StatelessWidget {
  final String label, subtitle;
  final bool selected, danger;
  final VoidCallback onTap;
  const _RadioTile({required this.label, required this.subtitle,
      required this.selected, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(children: [
        Radio<bool>(
          value: true, groupValue: selected,
          onChanged: (_) => onTap(),
          activeColor: danger ? Colors.red : AppTheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, color: danger ? Colors.red : AppTheme.textDark)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
        ]),
      ]),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color, foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    child: Text(label),
  );
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? Colors.white : AppTheme.textMid,
          ),
        ),
      ),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, size: 20, color: color),
    onPressed: onTap,
    padding: const EdgeInsets.all(8),
    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    splashRadius: 20,
  );
}
