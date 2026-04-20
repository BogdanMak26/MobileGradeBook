// lib/features/journals/presentation/pages/journals_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../grades/presentation/pages/grade_journal_page.dart';

// ── Mock data ─────────────────────────────────────────────────────────────────

const _kafedras = [
  {'id': 1,  'name': 'Кафедра №1',  'desc': 'Фундаментальних дисциплін'},
  {'id': 2,  'name': 'Кафедра №2',  'desc': 'Іноземних мов'},
  {'id': 3,  'name': 'Кафедра №3',  'desc': 'Автомобільної техніки'},
  {'id': 21, 'name': 'Кафедра №21', 'desc': 'Інформаційних систем та технологій'},
  {'id': 22, 'name': 'Кафедра №22', 'desc': "Комп'ютерних наук та інтелектуальних технологій"},
];

const _courses = [
  {'id': 1, 'name': '1 курс', 'year': 2025, 'groups': 15,
    'specialties': ["Електроніка", "Комп'ютерні науки", "ІСТ", "Озброєння", "Кібербезпека", "Військове управління"]},
  {'id': 2, 'name': '2 курс', 'year': 2024, 'groups': 14,
    'specialties': ["Електроніка", "Комп'ютерні науки", "ІСТ", "Озброєння", "Кібербезпека"]},
  {'id': 3, 'name': '3 курс', 'year': 2023, 'groups': 12,
    'specialties': ["Електроніка", "Комп'ютерні науки", "ІСТ"]},
  {'id': 4, 'name': '4 курс', 'year': 2022, 'groups': 10,
    'specialties': ["Електроніка", "Комп'ютерні науки"]},
];

// Групи по курсу
const _groupsByCourse = <int, List<Map<String, dynamic>>>{
  1: [
    {'id': 151, 'name': '151', 'specialty': 'Електроніка, електронні комунікації, приладобудування', 'year': 2025, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 152, 'name': '152', 'specialty': 'Електроніка, електронні комунікації, приладобудування', 'year': 2025, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 153, 'name': '153', 'specialty': "Комп'ютерні науки", 'year': 2025, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 154, 'name': '154', 'specialty': "Комп'ютерні науки", 'year': 2025, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 155, 'name': '155', 'specialty': 'ІСТ', 'year': 2025, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
  ],
  2: [
    {'id': 221, 'name': '221', 'specialty': "Комп'ютерні науки", 'year': 2024, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 222, 'name': '222', 'specialty': "Комп'ютерні науки", 'year': 2024, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 231, 'name': '231', 'specialty': 'ІСТ', 'year': 2024, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 241, 'name': '241', 'specialty': 'Електроніка', 'year': 2024, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
  ],
  3: [
    {'id': 321, 'name': '321', 'specialty': "Комп'ютерні науки", 'year': 2023, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 331, 'name': '331', 'specialty': 'ІСТ', 'year': 2023, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
  ],
  4: [
    {'id': 421, 'name': '421', 'specialty': "Комп'ютерні науки", 'year': 2022, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
    {'id': 431, 'name': '431', 'specialty': 'Електроніка', 'year': 2022, 'degree': 'Бакалавр', 'type': 'Очна ф.н.'},
  ],
};

// Дисципліни по групі (groupId -> список дисциплін з journalId)
const _disciplinesByGroup = <int, List<Map<String, dynamic>>>{
  151: [
    {'disciplineId': 37, 'short': 'ІМ', 'name': 'Іноземна мова', 'journalId': 20, 'semester': 2, 'journals': 64},
    {'disciplineId': 38, 'short': 'ТСА', 'name': 'Технології системного адміністрування', 'journalId': 21, 'semester': 2, 'journals': 2},
  ],
  152: [
    {'disciplineId': 37, 'short': 'ІМ', 'name': 'Іноземна мова', 'journalId': 22, 'semester': 2, 'journals': 64},
    {'disciplineId': 35, 'short': 'РПЗ', 'name': 'Розробка програмного забезпечення для мобільних пристроїв', 'journalId': 23, 'semester': 2, 'journals': 2},
  ],
  153: [
    {'disciplineId': 36, 'short': 'ПІС', 'name': 'Проєктування інформаційних систем', 'journalId': 24, 'semester': 2, 'journals': 3},
    {'disciplineId': 37, 'short': 'ІМ', 'name': 'Іноземна мова', 'journalId': 25, 'semester': 2, 'journals': 64},
  ],
  221: [
    {'disciplineId': 35, 'short': 'РПЗ', 'name': 'Розробка програмного забезпечення для мобільних пристроїв', 'journalId': 1, 'semester': 8, 'journals': 2},
    {'disciplineId': 36, 'short': 'ПІС', 'name': 'Проєктування інформаційних систем', 'journalId': 3, 'semester': 6, 'journals': 3},
    {'disciplineId': 38, 'short': 'ТСА', 'name': 'Технології системного адміністрування', 'journalId': 9, 'semester': 4, 'journals': 2},
  ],
  222: [
    {'disciplineId': 35, 'short': 'РПЗ', 'name': 'Розробка програмного забезпечення для мобільних пристроїв', 'journalId': 2, 'semester': 8, 'journals': 2},
    {'disciplineId': 38, 'short': 'ТСА', 'name': 'Технології системного адміністрування', 'journalId': 10, 'semester': 4, 'journals': 2},
  ],
  241: [
    {'disciplineId': 33, 'short': 'ДМ', 'name': 'Дискретна математика', 'journalId': 6, 'semester': 4, 'journals': 7},
  ],
  321: [
    {'disciplineId': 36, 'short': 'ПІС', 'name': 'Проєктування інформаційних систем', 'journalId': 30, 'semester': 6, 'journals': 3},
  ],
  421: [
    {'disciplineId': 35, 'short': 'РПЗ', 'name': 'Розробка програмного забезпечення для мобільних пристроїв', 'journalId': 40, 'semester': 8, 'journals': 2},
  ],
};

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

class _KafedrasTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kafedras.length,
      itemBuilder: (context, i) {
        final k = _kafedras[i];
        return _CardTile(
          icon: Icons.school,
          title: k['name'] as String,
          subtitle: k['desc'] as String,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _KafedraDisciplinesPage(
                kafedraName: k['name'] as String,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Курси → Групи → Дисципліни групи → Журнал ───────────────────────────────

class _CoursesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, i) {
        final c = _courses[i];
        final specs = c['specialties'] as List;
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
                child: Text(c['name'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark)),
              ),
              const Icon(Icons.people_outline, color: AppTheme.primary),
            ]),
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
                child: Text(s as String,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textDark)),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _InfoBadge(label: 'Рік вступу', value: '${c['year']}'),
              const SizedBox(width: 8),
              _InfoBadge(label: 'Груп', value: '${c['groups']}'),
              const Spacer(),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _GroupsPage(
                      courseId: c['id'] as int,
                      courseName: c['name'] as String,
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
  final int courseId;
  final String courseName;
  const _GroupsPage({required this.courseId, required this.courseName});

  @override
  State<_GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<_GroupsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final groups = _groupsByCourse[widget.courseId] ?? [];
    final filtered = groups
        .where((g) => g['name'].toString().toLowerCase()
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
                        Text(g['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primary)),
                        const Spacer(),
                        const Icon(Icons.people_outline, color: AppTheme.primary),
                      ]),
                      const SizedBox(height: 10),
                      _InfoRow(label: 'Спеціальність:', value: g['specialty'] as String),
                      const SizedBox(height: 4),
                      _InfoRow(label: 'Ступінь:', value: g['degree'] as String),
                      const SizedBox(height: 10),
                      Row(children: [
                        _InfoBadge(label: 'Рік вступу', value: '${g['year']}'),
                        const SizedBox(width: 8),
                        _InfoBadge(label: 'Тип', value: g['type'] as String),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _GroupDisciplinesPage(
                                groupId: g['id'] as int,
                                groupName: g['name'] as String,
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

class _GroupDisciplinesPage extends StatefulWidget {
  final int groupId;
  final String groupName;
  const _GroupDisciplinesPage({required this.groupId, required this.groupName});

  @override
  State<_GroupDisciplinesPage> createState() => _GroupDisciplinesPageState();
}

class _GroupDisciplinesPageState extends State<_GroupDisciplinesPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final disciplines = _disciplinesByGroup[widget.groupId] ?? [];
    final filtered = disciplines
        .where((d) =>
            d['name'].toString().toLowerCase().contains(_search.toLowerCase()) ||
            d['short'].toString().toLowerCase().contains(_search.toLowerCase()))
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
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Немає дисциплін для групи ${widget.groupName}',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final d = filtered[i];
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
                                    Text(d['short'] as String,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary)),
                                    const SizedBox(height: 2),
                                    Text(d['name'] as String,
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
                                  label: 'Журналів',
                                  value: '${d['journals']}'),
                              const Spacer(),
                              OutlinedButton(
                                // ← Тут одразу відкриваємо журнал цієї групи!
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GradeJournalPage(
                                      disciplineId: d['disciplineId'].toString(),
                                      groupName: '${widget.groupName} навчальна група',
                                      semesterId: d['semester'].toString(),
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

// ── Дисципліни кафедри (зі старої логіки) ───────────────────────────────────

class _KafedraDisciplinesPage extends StatefulWidget {
  final String kafedraName;
  const _KafedraDisciplinesPage({required this.kafedraName});

  @override
  State<_KafedraDisciplinesPage> createState() =>
      _KafedraDisciplinesPageState();
}

class _KafedraDisciplinesPageState extends State<_KafedraDisciplinesPage> {
  String _search = '';

  static const _disciplines = [
    {'id': 35, 'name': 'Розробка програмного забезпечення для мобільних пристроїв', 'short': 'РПЗ', 'journals': 2},
    {'id': 36, 'name': 'Проєктування інформаційних систем', 'short': 'ПІС', 'journals': 3},
    {'id': 33, 'name': 'Дискретна математика', 'short': 'ДМ', 'journals': 7},
    {'id': 38, 'name': 'Технології системного адміністрування', 'short': 'ТСА', 'journals': 2},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _disciplines
        .where((d) =>
            d['name'].toString().toLowerCase().contains(_search.toLowerCase()) ||
            d['short'].toString().toLowerCase().contains(_search.toLowerCase()))
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
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final d = filtered[i];
                return _CardTile(
                  icon: Icons.school,
                  title: '${d['short']} - ${d['name']}',
                  subtitle: 'Журналів: ${d['journals']}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _DisciplineJournalListPage(
                        disciplineId: d['id'] as int,
                        disciplineName: d['name'] as String,
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

class _DisciplineJournalListPage extends StatefulWidget {
  final int disciplineId;
  final String disciplineName;
  const _DisciplineJournalListPage(
      {required this.disciplineId, required this.disciplineName});

  @override
  State<_DisciplineJournalListPage> createState() =>
      _DisciplineJournalListPageState();
}

class _DisciplineJournalListPageState
    extends State<_DisciplineJournalListPage> {
  String _search = '';

  // Всі журнали цієї дисципліни по всіх групах
  List<Map<String, dynamic>> get _journals {
    final result = <Map<String, dynamic>>[];
    _disciplinesByGroup.forEach((groupId, disciplines) {
      for (final d in disciplines) {
        if (d['disciplineId'] == widget.disciplineId) {
          // Знайдемо назву групи
          String groupName = groupId.toString();
          for (final course in _groupsByCourse.values) {
            for (final g in course) {
              if (g['id'] == groupId) groupName = g['name'] as String;
            }
          }
          result.add({
            ...d,
            'groupId': groupId,
            'groupName': groupName,
          });
        }
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _journals
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
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final j = filtered[i];
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
                            '${j['groupName']} навчальна група',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.textDark),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('Семестр: ${j['semester']}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMid)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GradeJournalPage(
                                disciplineId: widget.disciplineId.toString(),
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
