// lib/features/admin/presentation/pages/admin_page.dart

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Адмін-панель'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: Column(
        children: [
          // Tabs — горизонтальний скрол
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
                Tab(text: 'Користувачі'),
                Tab(text: 'Факультети'),
                Tab(text: 'Кафедри'),
                Tab(text: 'Групи'),
                Tab(text: 'Семестри'),
                Tab(text: 'Дисципліни'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _UsersTab(),
                _FacultiesTab(),
                _KafedrasTab(),
                _GroupsTab(),
                _SemestersTab(),
                _DisciplinesAdminTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Користувачі ───────────────────────────────────────────────────────────────

class _UsersTab extends StatelessWidget {
  final _users = const [
    {'id': 1891, 'name': 'Микола',    'surname': 'Новіков',  'email': 'mykola.novikov@viti.edu.ua',      'role': 'CADET',    'rank': 'Солдат'},
    {'id': 1880, 'name': 'Вікторія',  'surname': 'Бурчак',   'email': 'viktoriia.burchak@viti.edu.ua',   'role': 'CADET',    'rank': 'Молодший сержант'},
    {'id': 1899, 'name': 'Олександр', 'surname': 'Баганець', 'email': 'oleksandr.bahanets@viti.edu.ua',  'role': 'CADET',    'rank': 'Солдат'},
    {'id': 1898, 'name': 'Олег',      'surname': 'Іваненко', 'email': 'oleh.ivanenko@viti.edu.ua',       'role': 'CADET',    'rank': 'Молодший сержант'},
    {'id': 10,   'name': 'Богдан',    'surname': 'Макаренко','email': 'makarenko.b@viti.edu.ua',          'role': 'TEACHER',  'rank': 'Лейтенант'},
    {'id': 11,   'name': 'Сачук',     'surname': 'Олексій',  'email': 'sachuk.o@viti.edu.ua',            'role': 'TEACHER',  'rank': 'Старший лейтенант'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Expanded(
              child: Text('Управління користувачами',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textDark)),
            ),
            _ActionButton(label: 'Перерахувати оцінки', color: AppTheme.primary, onTap: () {}),
            const SizedBox(width: 8),
            _ActionButton(label: 'Створити', color: const Color(0xFF16A34A), onTap: () {}),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(children: [
            _FilterButton(label: 'Імпорт', color: const Color(0xFF16A34A), onTap: () {}),
            const SizedBox(width: 8),
            _FilterButton(label: 'Фільтри', color: AppTheme.primary, onTap: () {}),
          ]),
        ),
        // Заголовок таблиці
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.surface,
          child: const Row(children: [
            SizedBox(width: 40, child: Text('ID', style: _headerStyle)),
            SizedBox(width: 70, child: Text("ІМ'Я", style: _headerStyle)),
            SizedBox(width: 80, child: Text('ПРІЗВИЩЕ', style: _headerStyle)),
            Expanded(child: Text('РОЛЬ', style: _headerStyle)),
            SizedBox(width: 60, child: Text('ЗВАННЯ', style: _headerStyle)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, i) {
              final u = _users[i];
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    SizedBox(width: 40,
                        child: Text('${u['id']}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMid))),
                    SizedBox(width: 70,
                        child: Text(u['name'] as String,
                            style: const TextStyle(fontSize: 13))),
                    SizedBox(width: 80,
                        child: Text(u['surname'] as String,
                            style: const TextStyle(fontSize: 13))),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: u['role'] == 'TEACHER'
                              ? AppTheme.secondary.withOpacity(0.1)
                              : AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(u['role'] as String,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: u['role'] == 'TEACHER'
                                    ? AppTheme.secondary
                                    : AppTheme.primary)),
                      ),
                    ),
                    SizedBox(width: 60,
                        child: Text(u['rank'] as String,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMid))),
                  ]),
                ),
                const Divider(height: 1, indent: 16),
              ]);
            },
          ),
        ),
      ],
    );
  }
}

// ── Факультети ────────────────────────────────────────────────────────────────

class _FacultiesTab extends StatelessWidget {
  final _faculties = const [
    {'id': 1, 'name': 'Факультет інформаційних технологій',       'number': 2},
    {'id': 3, 'name': 'Факультет електронних комунікаційних систем','number': 1},
    {'id': 4, 'name': 'Факультет кіберборотьби',                  'number': 3},
    {'id': 5, 'name': 'Факультет лідерства',                      'number': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return _AdminListTab(
      title: 'Управління факультетами',
      createLabel: 'Створити факультет',
      columns: const ['ID', 'НАЗВА', 'НОМЕР'],
      items: _faculties.map((f) => [
        '${f['id']}', f['name'] as String, '${f['number']}',
      ]).toList(),
    );
  }
}

// ── Кафедри ───────────────────────────────────────────────────────────────────

class _KafedrasTab extends StatelessWidget {
  final _kafedras = const [
    {'id': 2, 'name': 'Інформаційних систем та технологій',               'number': 21},
    {'id': 1, 'name': "Комп'ютерних наук та інтелектуальних технологій",  'number': 22},
    {'id': 4, 'name': 'Технічного забезпечення',                          'number': 23},
    {'id': 3, 'name': 'Бойового забезпечення та повсякденної діяльності', 'number': 43},
    {'id': 5, 'name': 'Комунікаційних систем та мереж',                   'number': 11},
  ];

  @override
  Widget build(BuildContext context) {
    return _AdminListTab(
      title: 'Управління кафедрами',
      createLabel: 'Створити кафедру',
      columns: const ['ID', 'НАЗВА', '№'],
      items: _kafedras.map((k) => [
        '${k['id']}', k['name'] as String, '${k['number']}',
      ]).toList(),
    );
  }
}

// ── Групи ─────────────────────────────────────────────────────────────────────

class _GroupsTab extends StatelessWidget {
  final _groups = const [
    {'id': 106, 'name': '121', 'specialty': 'Електроніка, електронні комунікації...', 'year': 2022},
    {'id': 107, 'name': '122', 'specialty': 'Електроніка, електронні комунікації...', 'year': 2022},
    {'id': 104, 'name': '131', 'specialty': 'Електроніка, електронні комунікації...', 'year': 2023},
    {'id': 105, 'name': '132', 'specialty': 'Електроніка, електронні комунікації...', 'year': 2023},
    {'id': 102, 'name': '141', 'specialty': 'Електроніка, електронні комунікації...', 'year': 2024},
    {'id': 112, 'name': '221', "specialty": "Комп'ютерні науки",                      'year': 2022},
    {'id': 113, 'name': '222', "specialty": "Комп'ютерні науки",                      'year': 2022},
  ];

  @override
  Widget build(BuildContext context) {
    return _AdminListTab(
      title: 'Управління групами',
      createLabel: 'Створити групу',
      columns: const ['ID', 'НАЗВА', 'СПЕЦІАЛЬНІСТЬ', 'РІК'],
      items: _groups.map((g) => [
        '${g['id']}', g['name'] as String, g['specialty'] as String, '${g['year']}',
      ]).toList(),
      showSearch: true,
    );
  }
}

// ── Семестри ──────────────────────────────────────────────────────────────────

class _SemestersTab extends StatelessWidget {
  final _semesters = const [
    {'id': 47, 'number': 3, 'degree': 'Бакалавр', 'start': '28.07.2025', 'end': '26.01.2026', 'year': '2025/2026'},
    {'id': 53, 'number': 1, 'degree': 'Бакалавр', 'start': '01.09.2023', 'end': '31.01.2024', 'year': '2023/2024'},
    {'id': 54, 'number': 2, 'degree': 'Бакалавр', 'start': '01.02.2024', 'end': '30.06.2024', 'year': '2023/2024'},
    {'id': 55, 'number': 3, 'degree': 'Бакалавр', 'start': '01.09.2024', 'end': '31.01.2025', 'year': '2024/2025'},
    {'id': 56, 'number': 4, 'degree': 'Бакалавр', 'start': '01.02.2025', 'end': '30.06.2025', 'year': '2024/2025'},
    {'id': 59, 'number': 7, 'degree': 'Бакалавр', 'start': '01.09.2026', 'end': '31.01.2027', 'year': '2026/2027'},
  ];

  @override
  Widget build(BuildContext context) {
    return _AdminListTab(
      title: 'Управління семестрами',
      createLabel: 'Створити семестр',
      columns: const ['ID', '№', 'СТУПІНЬ', 'ПОЧАТОК', 'КІНЕЦЬ', 'РІК'],
      items: _semesters.map((s) => [
        '${s['id']}', '${s['number']}', s['degree'] as String,
        s['start'] as String, s['end'] as String, s['year'] as String,
      ]).toList(),
      showSearch: true,
      searchHint: 'Пошук по номеру',
    );
  }
}

// ── Дисципліни (адмін) ────────────────────────────────────────────────────────

class _DisciplinesAdminTab extends StatelessWidget {
  final _disciplines = const [
    {'id': 35, 'name': 'Розробка програмного забезпечення для мобільних пристроїв', 'short': 'РПЗ', 'kafedra': "Комп'ютерних наук...", 'journals': 2},
    {'id': 36, 'name': 'Проєктування інформаційних систем',                         'short': 'ПІС', 'kafedra': "Комп'ютерних наук...", 'journals': 3},
    {'id': 37, 'name': 'Іноземна мова',                                             'short': 'ІМ',  'kafedra': 'Іноземних мов',        'journals': 64},
    {'id': 38, 'name': 'Технології системного адміністрування',                     'short': 'ТСА', 'kafedra': 'Інформаційних систем', 'journals': 2},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Expanded(
              child: Text('Управління дисциплінами',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textDark)),
            ),
            _ActionButton(label: 'Створити дисципліну',
                color: AppTheme.primary, onTap: () {}),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _disciplines.length,
            itemBuilder: (context, i) {
              final d = _disciplines[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('ID: ${d['id']}',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMid)),
                      ),
                      const Spacer(),
                      Text('Журналів: ${d['journals']}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMid)),
                    ]),
                    const SizedBox(height: 6),
                    Text(d['name'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text('${d['short']} • ${d['kafedra']}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMid)),
                    const SizedBox(height: 10),
                    Row(children: [
                      _ActionButton(label: 'Редагувати',
                          color: const Color(0xFF16A34A), onTap: () {}),
                      const SizedBox(width: 6),
                      _ActionButton(label: 'Видалити',
                          color: const Color(0xFFEF4444), onTap: () {}),
                      const SizedBox(width: 6),
                      _ActionButton(label: 'Перенести журнал',
                          color: AppTheme.primary, onTap: () {}),
                    ]),
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

// ── Спільний таб-список ───────────────────────────────────────────────────────

class _AdminListTab extends StatefulWidget {
  final String title;
  final String createLabel;
  final List<String> columns;
  final List<List<String>> items;
  final bool showSearch;
  final String searchHint;

  const _AdminListTab({
    required this.title,
    required this.createLabel,
    required this.columns,
    required this.items,
    this.showSearch = false,
    this.searchHint = 'Пошук...',
  });

  @override
  State<_AdminListTab> createState() => _AdminListTabState();
}

class _AdminListTabState extends State<_AdminListTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((row) =>
        row.any((cell) => cell.toLowerCase().contains(_search.toLowerCase())))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Expanded(
              child: Text(widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textDark)),
            ),
            _ActionButton(label: widget.createLabel,
                color: AppTheme.primary, onTap: () {}),
          ]),
        ),
        if (widget.showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.textMid, size: 18),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
            ),
          ),
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.surface,
          child: Row(
            children: widget.columns.asMap().entries.map((e) {
              final isFirst = e.key == 0;
              final isLast = e.key == widget.columns.length - 1;
              return isLast
                  ? Expanded(child: Text(e.value, style: _headerStyle))
                  : SizedBox(
                      width: isFirst ? 40 : 80,
                      child: Text(e.value, style: _headerStyle));
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final row = filtered[i];
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(children: [
                    ...row.asMap().entries.map((e) {
                      final isFirst = e.key == 0;
                      final isLast = e.key == row.length - 1;
                      return isLast
                          ? Expanded(
                              child: Text(e.value,
                                  style: const TextStyle(fontSize: 12,
                                      color: AppTheme.textDark),
                                  overflow: TextOverflow.ellipsis))
                          : SizedBox(
                              width: isFirst ? 40 : 80,
                              child: Text(e.value,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isFirst
                                          ? AppTheme.textMid
                                          : AppTheme.textDark),
                                  overflow: TextOverflow.ellipsis));
                    }),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      _SmallBtn(label: 'Ред.', color: const Color(0xFF16A34A), onTap: () {}),
                      const SizedBox(width: 4),
                      _SmallBtn(label: 'Вид.', color: const Color(0xFFEF4444), onTap: () {}),
                    ]),
                  ]),
                ),
                const Divider(height: 1, indent: 16),
              ]);
            },
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppTheme.textMid,
    letterSpacing: 0.3);

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FilterButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(label),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(label),
    );
  }
}
