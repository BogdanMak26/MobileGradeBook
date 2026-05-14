// lib/features/admin/presentation/pages/admin_page.dart

import 'package:flutter/material.dart';
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
  'DEPARTMENT_HEAD': 'Нач. кафедри', 'SUPER_ADMIN': 'Адміністратор',
};

// ── Mock data ─────────────────────────────────────────────────────────────────

final _initFaculties = <Map<String, dynamic>>[
  {'id': 3, 'name': 'Факультет електронних комунікаційних систем', 'number': 1},
  {'id': 1, 'name': 'Факультет інформаційних технологій',          'number': 2},
  {'id': 4, 'name': 'Факультет кіберборотьби',                     'number': 3},
  {'id': 5, 'name': 'Факультет лідерства',                         'number': 4},
];

final _initKafedras = <Map<String, dynamic>>[
  {'id': 5, 'name': 'Комунікаційних систем та мереж',                     'number': 11, 'facultyId': 3},
  {'id': 2, 'name': 'Інформаційних систем та технологій',                 'number': 21, 'facultyId': 1},
  {'id': 1, 'name': "Комп'ютерних наук та інтелект. технологій",          'number': 22, 'facultyId': 1},
  {'id': 4, 'name': 'Технічного забезпечення',                            'number': 23, 'facultyId': 1},
  {'id': 3, 'name': 'Бойового забезпечення та повсяк. діяльності',        'number': 43, 'facultyId': 4},
];

final _initGroups = <Map<String, dynamic>>[
  {'id': 156, 'name': '121', 'specialty': 'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING', 'year': 2022, 'degree': 'BACHELOR', 'type': 'FULL_TIME', 'facultyId': 3},
  {'id': 107, 'name': '122', 'specialty': 'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING', 'year': 2022, 'degree': 'BACHELOR', 'type': 'FULL_TIME', 'facultyId': 3},
  {'id': 104, 'name': '131', 'specialty': 'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING', 'year': 2023, 'degree': 'BACHELOR', 'type': 'FULL_TIME', 'facultyId': 3},
  {'id': 105, 'name': '132', 'specialty': 'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING', 'year': 2023, 'degree': 'BACHELOR', 'type': 'FULL_TIME', 'facultyId': 3},
  {'id': 103, 'name': '141', 'specialty': 'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING', 'year': 2024, 'degree': 'BACHELOR', 'type': 'FULL_TIME', 'facultyId': 3},
  {'id': 102, 'name': '142', 'specialty': 'ELECTRONICS_ELECTRONIC_COMMUNICATIONS_INSTRUMENTATION_AND_RADIO_ENGINEERING', 'year': 2024, 'degree': 'BACHELOR', 'type': 'FULL_TIME', 'facultyId': 3},
  {'id': 112, 'name': '221', 'specialty': 'COMPUTER_SCIENCES', 'year': 2022, 'degree': 'BACHELOR', 'type': 'FULL_TIME', 'facultyId': 1},
  {'id': 113, 'name': '222', 'specialty': 'COMPUTER_SCIENCES', 'year': 2022, 'degree': 'BACHELOR', 'type': 'FULL_TIME', 'facultyId': 1},
];

final _initSemesters = <Map<String, dynamic>>[
  {'id': 53, 'number': 1, 'degree': 'BACHELOR', 'start': '2023-09-01', 'end': '2024-01-31', 'yearStart': 2023, 'yearEnd': 2024},
  {'id': 54, 'number': 2, 'degree': 'BACHELOR', 'start': '2024-02-01', 'end': '2024-06-30', 'yearStart': 2023, 'yearEnd': 2024},
  {'id': 55, 'number': 3, 'degree': 'BACHELOR', 'start': '2024-09-01', 'end': '2025-01-31', 'yearStart': 2024, 'yearEnd': 2025},
  {'id': 56, 'number': 4, 'degree': 'BACHELOR', 'start': '2025-02-01', 'end': '2025-06-30', 'yearStart': 2024, 'yearEnd': 2025},
  {'id': 47, 'number': 3, 'degree': 'BACHELOR', 'start': '2025-07-28', 'end': '2026-01-26', 'yearStart': 2025, 'yearEnd': 2026},
  {'id': 59, 'number': 7, 'degree': 'BACHELOR', 'start': '2026-09-01', 'end': '2027-01-31', 'yearStart': 2026, 'yearEnd': 2027},
];

final _initUsers = <Map<String, dynamic>>[
  {'id': 1891, 'name': 'Микола',    'surname': 'Новіков',   'email': 'mykola.novikov@viti.edu.ua',     'role': 'CADET',           'rank': 'SOLDIER',          'position': 'CADET',          'gender': 'MALE',   'phone': '+380671234567', 'groupId': 156, 'groupName': '121', 'studyRank': '', 'studyPosition': ''},
  {'id': 1880, 'name': 'Вікторія',  'surname': 'Бурчак',    'email': 'viktoriia.burchak@viti.edu.ua',  'role': 'CADET',           'rank': 'JUNIOR_SERGEANT',  'position': 'CADET',          'gender': 'FEMALE', 'phone': '',              'groupId': 107, 'groupName': '122', 'studyRank': '', 'studyPosition': ''},
  {'id': 1899, 'name': 'Олександр', 'surname': 'Баганець',  'email': 'oleksandr.bahanets@viti.edu.ua', 'role': 'CADET',           'rank': 'SOLDIER',          'position': 'CADET',          'gender': 'MALE',   'phone': '',              'groupId': 156, 'groupName': '121', 'studyRank': '', 'studyPosition': ''},
  {'id': 1898, 'name': 'Олег',      'surname': 'Іваненко',  'email': 'oleh.ivanenko@viti.edu.ua',      'role': 'CADET',           'rank': 'JUNIOR_SERGEANT',  'position': 'SQUAD_COMMANDER','gender': 'MALE',   'phone': '',              'groupId': 107, 'groupName': '122', 'studyRank': '', 'studyPosition': ''},
  {'id': 10,   'name': 'Богдан',    'surname': 'Макаренко', 'email': 'makarenko.b@viti.edu.ua',        'role': 'TEACHER',         'rank': 'LIEUTENANT',       'position': 'TEACHER',        'gender': 'MALE',   'phone': '+380501112233', 'kafedraId': 1, 'kafedraName': "Комп'ютерних наук", 'studyRank': 'CANDIDATE', 'studyPosition': 'DOCENT'},
  {'id': 11,   'name': 'Олексій',   'surname': 'Сачук',     'email': 'sachuk.o@viti.edu.ua',           'role': 'TEACHER',         'rank': 'SENIOR_LIEUTENANT','position': 'SENIOR_TEACHER', 'gender': 'MALE',   'phone': '',              'kafedraId': 1, 'kafedraName': "Комп'ютерних наук", 'studyRank': '', 'studyPosition': ''},
  {'id': 12,   'name': 'Людмила',   'surname': 'Павленко',  'email': 'pavlenko.l@viti.edu.ua',         'role': 'DEPARTMENT_HEAD', 'rank': 'MAJOR',            'position': 'HEAD_OF_KAFEDRA','gender': 'FEMALE', 'phone': '+380671112233', 'kafedraId': 2, 'kafedraName': 'Інформаційних систем', 'studyRank': 'DOCTOR_OF_SCIENCE', 'studyPosition': 'PROFESSOR'},
];

final _initDisciplines = <Map<String, dynamic>>[
  {'id': 35, 'name': 'Розробка ПЗ для мобільних пристроїв', 'short': 'РПЗ', 'kafedraId': 1, 'kafedraName': "Комп'ютерних наук", 'journals': 2},
  {'id': 36, 'name': 'Проєктування інформаційних систем',   'short': 'ПІС', 'kafedraId': 1, 'kafedraName': "Комп'ютерних наук", 'journals': 3},
  {'id': 37, 'name': 'Іноземна мова',                       'short': 'ІМ',  'kafedraId': 3, 'kafedraName': 'Бойового забезпечення', 'journals': 64},
  {'id': 38, 'name': 'Технології системного адміністрування','short': 'ТСА', 'kafedraId': 2, 'kafedraName': 'Інформаційних систем', 'journals': 2},
  {'id': 39, 'name': 'Кібербезпека та захист інформації',   'short': 'КЗІ', 'kafedraId': 1, 'kafedraName': "Комп'ютерних наук", 'journals': 1},
];

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

class _UsersTab extends StatefulWidget {
  const _UsersTab();
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  late List<Map<String, dynamic>> _users;
  final _searchCtrl = TextEditingController();
  String _roleFilter = '';
  int _page = 0;
  static const _pageSize = 5;
  int _nextId = 2000;

  @override
  void initState() { super.initState(); _users = List.from(_initUsers); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _filtered => _users.where((u) {
    final q = _searchCtrl.text.toLowerCase();
    final matchSearch = q.isEmpty ||
        (u['name'] as String).toLowerCase().contains(q) ||
        (u['surname'] as String).toLowerCase().contains(q) ||
        (u['email'] as String).toLowerCase().contains(q);
    final matchRole = _roleFilter.isEmpty || u['role'] == _roleFilter;
    return matchSearch && matchRole;
  }).toList();

  List<Map<String, dynamic>> get _paged {
    final f = _filtered;
    final start = _page * _pageSize;
    if (start >= f.length) return [];
    return f.sublist(start, (start + _pageSize).clamp(0, f.length));
  }

  int get _totalPages => ((_filtered.length + _pageSize - 1) ~/ _pageSize).clamp(1, 9999);

  void _openSheet([Map<String, dynamic>? user]) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSheet(
        initial: user,
        groups: _initGroups, kafedras: _initKafedras,
        onSubmit: (data) => setState(() {
          if (user == null) {
            _users.add({'id': _nextId++, ...data});
          } else {
            final idx = _users.indexWhere((u) => u['id'] == user['id']);
            if (idx != -1) _users[idx] = {'id': user['id'], ...data};
          }
        }),
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
                setState(() => _users.removeWhere((u) => u['id'] == user['id']));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user['name']} ${user['surname']} видалено')),
                );
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
    final paged = _paged;
    final total = _totalPages;
    return Column(children: [
      // Заголовок + кнопки дій
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
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Оцінки перераховано'))),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Створити користувача',
            color: const Color(0xFF16A34A),
            onPressed: _openSheet,
          ),
        ]),
      ),
      // Пошук
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() => _page = 0),
          decoration: const InputDecoration(
            hintText: 'Пошук за іменем або email...',
            prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textMid),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
      // Фільтр за роллю — чіпи з горизонтальним скролом
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _RoleChip(label: 'Всі', selected: _roleFilter.isEmpty,
                onTap: () => setState(() { _roleFilter = ''; _page = 0; })),
            ..._roles.entries.map((e) => _RoleChip(
              label: e.value,
              selected: _roleFilter == e.key,
              onTap: () => setState(() { _roleFilter = e.key; _page = 0; }),
            )),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Expanded(
        child: paged.isEmpty
            ? const Center(child: Text('Нічого не знайдено', style: TextStyle(color: AppTheme.textMid)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: paged.length,
                itemBuilder: (_, i) {
                  final u = paged[i];
                  final name = u['name'] as String;
                  final surname = u['surname'] as String;
                  final role = u['role'] as String;
                  final roleColor = role == 'SUPER_ADMIN' ? Colors.purple
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
                              Text(u['email'] as String,
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
      if (total > 1)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))), color: Colors.white),
          child: Row(children: [
            Text('${_filtered.length} записів', style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.chevron_left), iconSize: 20, padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _page > 0 ? () => setState(() => _page--) : null),
            Text('${_page + 1} / $total', style: const TextStyle(fontSize: 13)),
            IconButton(icon: const Icon(Icons.chevron_right), iconSize: 20, padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: _page < total - 1 ? () => setState(() => _page++) : null),
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
    _phoneCtrl    = TextEditingController(text: d?['phone'] as String? ?? '');
    _birthdayCtrl = TextEditingController(text: d?['birthday'] as String? ?? '');
    _role         = d?['role'] as String? ?? 'CADET';
    _rank         = d?['rank'] as String? ?? '';
    _position     = d?['position'] as String? ?? '';
    _gender       = d?['gender'] as String? ?? '';
    _studyRank    = d?['studyRank'] as String? ?? '';
    _studyPosition = d?['studyPosition'] as String? ?? '';
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
    final group = _isCadet
        ? widget.groups.where((g) => g['id'] == _groupId).cast<Map<String,dynamic>?>().firstOrNull
        : null;
    final kafedra = _isTeacher
        ? widget.kafedras.where((k) => k['id'] == _kafedraId).cast<Map<String,dynamic>?>().firstOrNull
        : null;
    widget.onSubmit({
      'name': _nameCtrl.text.trim(), 'surname': _surnameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(), 'role': _role,
      'rank': _rank, 'position': _position, 'gender': _gender,
      'phone': _phoneCtrl.text.trim(), 'birthday': _birthdayCtrl.text.trim(),
      'studyRank': _isTeacher ? _studyRank : '',
      'studyPosition': _isTeacher ? _studyPosition : '',
      if (_isCadet) 'groupId': _groupId,
      if (_isCadet) 'groupName': group?['name'] ?? '',
      if (_isTeacher) 'kafedraId': _kafedraId,
      if (_isTeacher) 'kafedraName': kafedra?['name'] ?? '',
    });
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

class _FacultiesTab extends StatefulWidget {
  const _FacultiesTab();
  @override
  State<_FacultiesTab> createState() => _FacultiesTabState();
}

class _FacultiesTabState extends State<_FacultiesTab> {
  late List<Map<String, dynamic>> _items;
  int _nextId = 100;

  @override
  void initState() { super.initState(); _items = List.from(_initFaculties); }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FacultySheet(
      initial: item,
      onSubmit: (name, number) => setState(() {
        if (item == null) {
          _items.add({'id': _nextId++, 'name': name, 'number': number});
        } else {
          final idx = _items.indexOf(item);
          _items[idx] = {'id': item['id'], 'name': name, 'number': number};
        }
      }),
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: item['name'] as String,
      onConfirm: () {
        setState(() => _items.remove(item));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Факультет "${item['name']}" видалено')));
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
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

class _KafedrasTab extends StatefulWidget {
  const _KafedrasTab();
  @override
  State<_KafedrasTab> createState() => _KafedrasTabState();
}

class _KafedrasTabState extends State<_KafedrasTab> {
  late List<Map<String, dynamic>> _items;
  int _nextId = 200;

  @override
  void initState() { super.initState(); _items = List.from(_initKafedras); }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _KafedraSheet(
      initial: item, faculties: _initFaculties,
      onSubmit: (data) => setState(() {
        if (item == null) {
          _items.add({'id': _nextId++, ...data});
        } else {
          final idx = _items.indexOf(item);
          _items[idx] = {'id': item['id'], ...data};
        }
      }),
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: item['name'] as String,
      onConfirm: () {
        setState(() => _items.remove(item));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Кафедру "${item['name']}" видалено')));
      },
    ),
  );

  @override
  Widget build(BuildContext context) => _ListTab(
    title: 'Управління кафедрами',
    createLabel: 'Створити',
    onCreate: () => _openSheet(),
    items: _items,
    titleOf: (k) => k['name'] as String,
    subtitleOf: (k) => 'Кафедра №${k['number']}',
    onEdit: _openSheet, onDelete: _confirmDelete,
  );
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
        value: _facultyId, hint: 'Не обрано (необов\'язково)',
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

class _GroupsTab extends StatefulWidget {
  const _GroupsTab();
  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  late List<Map<String, dynamic>> _items;
  int _nextId = 300;

  @override
  void initState() { super.initState(); _items = List.from(_initGroups); }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GroupSheet(
      initial: item, faculties: _initFaculties,
      onSubmit: (data) => setState(() {
        if (item == null) {
          _items.add({'id': _nextId++, ...data});
        } else {
          final idx = _items.indexOf(item);
          _items[idx] = {
            'id': item['id'],
            'degree': item['degree'], 'type': item['type'], 'facultyId': item['facultyId'],
            ...data,
          };
        }
      }),
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: 'групу ${item['name']}',
      onConfirm: () {
        setState(() => _items.remove(item));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Групу ${item['name']} видалено')));
      },
    ),
  );

  @override
  Widget build(BuildContext context) => _ListTab(
    title: 'Управління групами',
    createLabel: 'Створити',
    onCreate: () => _openSheet(),
    showSearch: true, searchHint: 'Пошук групи...',
    items: _items,
    titleOf: (g) => 'Група ${g['name']}',
    subtitleOf: (g) {
      final spec = _specialities[g['specialty']] ?? g['specialty'] as String;
      return '$spec • ${g['year']} • ${_degrees[g['degree']] ?? ''}';
    },
    onEdit: _openSheet, onDelete: _confirmDelete,
  );
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

class _SemestersTab extends StatefulWidget {
  const _SemestersTab();
  @override
  State<_SemestersTab> createState() => _SemestersTabState();
}

class _SemestersTabState extends State<_SemestersTab> {
  late List<Map<String, dynamic>> _items;
  int _nextId = 400;

  @override
  void initState() { super.initState(); _items = List.from(_initSemesters); }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SemesterSheet(
      initial: item, groups: _initGroups,
      onSubmit: (data) => setState(() {
        if (item == null) {
          _items.add({'id': _nextId++, ...data});
        } else {
          final idx = _items.indexOf(item);
          _items[idx] = {'id': item['id'], ...data};
        }
      }),
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: 'семестр №${item['number']} (${item['yearStart']}/${item['yearEnd']})',
      onConfirm: () {
        setState(() => _items.remove(item));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Семестр видалено')));
      },
    ),
  );

  @override
  Widget build(BuildContext context) => _ListTab(
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
            _specialities[g['specialty']] ?? g['specialty'] as String,
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

class _DisciplinesAdminTab extends StatefulWidget {
  const _DisciplinesAdminTab();
  @override
  State<_DisciplinesAdminTab> createState() => _DisciplinesAdminTabState();
}

class _DisciplinesAdminTabState extends State<_DisciplinesAdminTab> {
  late List<Map<String, dynamic>> _items;
  int _nextId = 500;

  @override
  void initState() { super.initState(); _items = List.from(_initDisciplines); }

  void _openSheet([Map<String, dynamic>? item]) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DisciplineSheet(
      initial: item, kafedras: _initKafedras,
      onSubmit: (data) => setState(() {
        if (item == null) {
          _items.add({'id': _nextId++, 'journals': 0, ...data});
        } else {
          final idx = _items.indexOf(item);
          _items[idx] = {'id': item['id'], 'journals': item['journals'], ...data};
        }
      }),
    ),
  );

  void _confirmDelete(Map<String, dynamic> item) => showDialog(
    context: context,
    builder: (_) => _DeleteDialog(
      name: item['name'] as String,
      onConfirm: () {
        setState(() => _items.remove(item));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Дисципліну "${item['short']}" видалено')));
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
        child: ListView.builder(
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
      'name': _nameCtrl.text.trim(),
      'short': _shortCtrl.text.trim(),
      'kafedraId': _kafedraId,
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

class _MoveJournalSheet extends StatefulWidget {
  final Map<String, dynamic> discipline;
  final List<Map<String, dynamic>> disciplines;
  const _MoveJournalSheet({required this.discipline, required this.disciplines});
  @override
  State<_MoveJournalSheet> createState() => _MoveJournalSheetState();
}

class _MoveJournalSheetState extends State<_MoveJournalSheet> {
  int? _targetId;

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
              onPressed: () => Navigator.pop(context), child: const Text('Скасувати'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: _targetId == null ? null : () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Журнал перенесено')),
              );
            },
            child: const Text('Перенести'),
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
