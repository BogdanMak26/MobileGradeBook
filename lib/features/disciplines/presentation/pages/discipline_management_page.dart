// lib/features/disciplines/presentation/pages/discipline_management_page.dart

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

// ── Mock data ─────────────────────────────────────────────────────────────────

const _mockDisciplines = [
  {
    'id': 35, 'name': 'Розробка програмного забезпечення для мобільних пристроїв',
    'short': 'РПЗ', 'journals': 2,
    'teachers': ['Сачук Олександр'],
  },
  {
    'id': 36, 'name': 'Проєктування інформаційних систем',
    'short': 'ПІС', 'journals': 3,
    'teachers': ['Задворний Андрій', 'Устинов Дмитро'],
  },
  {
    'id': 37, 'name': 'Іноземна мова',
    'short': 'ІМ', 'journals': 64,
    'teachers': ['Малярчук Максим', 'Сидоренко Марина', 'Терегеря Євген'],
  },
  {
    'id': 38, 'name': 'Технології системного адміністрування',
    'short': 'ТСА', 'journals': 2,
    'teachers': [],
  },
];

const _mockTeachers = [
  {
    'id': 1, 'name': 'Адміненко Адмін',
    'position': 'Працівник ЗСУ, Викладач',
    'birthday': '01.01.2000',
    'disciplines': <String>[],
  },
  {
    'id': 66, 'name': 'Бовда Едуард',
    'position': 'Полковник, Професор, Доцент, Кандидат наук',
    'birthday': null,
    'disciplines': [
      'Технології побудови програмного та інформаційного забезпечення військових інформаційних систем',
      'Організація баз даних та знань',
    ],
  },
  {
    'id': 69, 'name': 'Голуб Олександр',
    'position': 'Підполковник, Старший викладач',
    'birthday': null,
    'disciplines': ['Захист інформації в телекомунікаційних системах'],
  },
  {
    'id': 10, 'name': 'Макаренко Богдан',
    'position': 'Лейтенант, Викладач',
    'birthday': null,
    'disciplines': ['Захист інформації в телекомунікаційних системах', 'Основи кібербезпеки'],
  },
  {
    'id': 11, 'name': 'Сачук Олександр',
    'position': 'Старший лейтенант, Викладач',
    'birthday': null,
    'disciplines': ['Розробка програмного забезпечення для мобільних пристроїв'],
  },
];

// ── Page ──────────────────────────────────────────────────────────────────────

class DisciplineManagementPage extends StatefulWidget {
  const DisciplineManagementPage({super.key});

  @override
  State<DisciplineManagementPage> createState() =>
      _DisciplineManagementPageState();
}

class _DisciplineManagementPageState extends State<DisciplineManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tab.index == 0
              ? 'Управління дисциплінами'
              : 'Управління викладачами',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppTheme.primary),
        ),
      ),
      body: Column(
        children: [
          // Back button
          Container(
            color: Colors.white,
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left,
                  size: 18, color: AppTheme.textMid),
              label: const Text('Повернутися до дисциплін',
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textMid)),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              ),
            ),
          ),
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMid,
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Дисципліни'),
                Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Викладачі'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _DisciplinesTab(),
                _TeachersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Вкладка: Управління дисциплінами ─────────────────────────────────────────

class _DisciplinesTab extends StatefulWidget {
  @override
  State<_DisciplinesTab> createState() => _DisciplinesTabState();
}

class _DisciplinesTabState extends State<_DisciplinesTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _mockDisciplines
        .where((d) =>
            d['name'].toString().toLowerCase()
                .contains(_search.toLowerCase()) ||
            d['short'].toString().toLowerCase()
                .contains(_search.toLowerCase()))
        .toList();

    return Column(
      children: [
        // Search + count + add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            const SizedBox(width: 12),
            // Всього
            Row(children: [
              const Icon(Icons.menu_book_outlined,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text('Всього дисциплін: ${_mockDisciplines.length}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMid)),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text('+ Додати дисципліну',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final d = filtered[i];
              final teachers = d['teachers'] as List;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.textDark)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Text(d['short'] as String,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDark)),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'ID: ${d['id']}   Журналів: ${d['journals']}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMid),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      // Edit / Delete
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppTheme.textMid),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: AppTheme.textMid),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Призначені викладачі
                    Row(children: [
                      const Icon(Icons.people_outline,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Призначені викладачі (${teachers.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.primary),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    if (teachers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Text('Викладачі не призначені',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMid,
                                fontStyle: FontStyle.italic)),
                      )
                    else
                      ...teachers.map((t) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Text(t as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textDark)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 16,
                                    color: AppTheme.textLight),
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ]),
                          )),

                    const SizedBox(height: 8),
                    // Призначити викладача dropdown
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButton<String>(
                        hint: const Text('Призначити викладача...',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMid)),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _mockTeachers
                            .map((t) => DropdownMenuItem(
                                  value: t['name'] as String,
                                  child: Text(t['name'] as String,
                                      style:
                                          const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (_) {},
                      ),
                    ),
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

// ── Вкладка: Управління викладачами ──────────────────────────────────────────

class _TeachersTab extends StatefulWidget {
  @override
  State<_TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<_TeachersTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _mockTeachers
        .where((t) => t['name'].toString().toLowerCase()
            .contains(_search.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Пошук викладачів...',
                  prefixIcon: Icon(Icons.search,
                      color: AppTheme.textMid, size: 18),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text('Всього викладачів: ${_mockTeachers.length}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMid)),
            ]),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final t = filtered[i];
              final disciplines = t['disciplines'] as List;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.textDark)),
                            const SizedBox(height: 2),
                            Text(t['position'] as String,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMid)),
                            const SizedBox(height: 2),
                            Text(
                              t['birthday'] != null
                                  ? 'ID: ${t['id']}   Д.н.: ${t['birthday']}'
                                  : 'ID: ${t['id']}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMid),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppTheme.textMid),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Призначені дисципліни
                    Row(children: [
                      const Icon(Icons.menu_book_outlined,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Призначені дисципліни (${disciplines.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.primary),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    if (disciplines.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Text(
                            'Дисципліни не призначені',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMid,
                                fontStyle: FontStyle.italic)),
                      )
                    else
                      ...disciplines.map((d) {
                        // Find short name
                        final found = _mockDisciplines.where((disc) =>
                            disc['name'] == d).firstOrNull;
                        final shortName = found?['short'] as String?;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(d as String,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textDark)),
                                  if (shortName != null)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 4),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        border: Border.all(
                                            color: AppTheme.border),
                                      ),
                                      child: Text(shortName,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 16,
                                  color: AppTheme.textLight),
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ]),
                        );
                      }),

                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButton<String>(
                        hint: const Text('Призначити дисципліну...',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMid)),
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _mockDisciplines
                            .map((d) => DropdownMenuItem(
                                  value: d['name'] as String,
                                  child: Text(d['name'] as String,
                                      style:
                                          const TextStyle(fontSize: 12)),
                                ))
                            .toList(),
                        onChanged: (_) {},
                      ),
                    ),
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
