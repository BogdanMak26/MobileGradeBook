// lib/features/groups/presentation/pages/my_group_page.dart

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

// ── Дані всіх навчальних груп ─────────────────────────────────────────────────

const _allGroups = <Map<String, dynamic>>[
  {'id': 156, 'name': '121', 'specialty': 'Електроніка, електронні комунікації, приладобудування та радіотехніка', 'year': 2022, 'degree': 'Бакалавр', 'type': 'Очна ф.н.', 'faculty': '1'},
  {'id': 107, 'name': '122', 'specialty': 'Електроніка, електронні комунікації, приладобудування та радіотехніка', 'year': 2022, 'degree': 'Бакалавр', 'type': 'Очна ф.н.', 'faculty': '1'},
  {'id': 104, 'name': '131', 'specialty': 'Електроніка, електронні комунікації, приладобудування та радіотехніка', 'year': 2023, 'degree': 'Бакалавр', 'type': 'Очна ф.н.', 'faculty': '1'},
  {'id': 105, 'name': '132', 'specialty': 'Електроніка, електронні комунікації, приладобудування та радіотехніка', 'year': 2023, 'degree': 'Бакалавр', 'type': 'Очна ф.н.', 'faculty': '1'},
  {'id': 103, 'name': '141', 'specialty': 'Електроніка, електронні комунікації, приладобудування та радіотехніка', 'year': 2024, 'degree': 'Бакалавр', 'type': 'Очна ф.н.', 'faculty': '1'},
  {'id': 102, 'name': '142', 'specialty': 'Електроніка, електронні комунікації, приладобудування та радіотехніка', 'year': 2024, 'degree': 'Бакалавр', 'type': 'Очна ф.н.', 'faculty': '1'},
  {'id': 112, 'name': '221', 'specialty': "Комп'ютерні науки", 'year': 2022, 'degree': 'Бакалавр', 'type': 'Очна ф.н.', 'faculty': '2'},
  {'id': 113, 'name': '222', 'specialty': "Комп'ютерні науки", 'year': 2022, 'degree': 'Бакалавр', 'type': 'Очна ф.н.', 'faculty': '2'},
];

const _cadetsA = <Map<String, dynamic>>[
  {'name': 'Авраменко Сергій',    'position': 'Командир відділення', 'email': 'serhiy.avramenko@viti.edu.ua',   'phone': '+380671100101'},
  {'name': 'Бандура Тарас',       'position': 'Заступник командира', 'email': 'taras.bandura@viti.edu.ua',       'phone': '+380671100102'},
  {'name': 'Гончаренко Павло',    'position': 'Солдат',              'email': 'pavlo.honcharenko@viti.edu.ua',   'phone': '+380671100103'},
  {'name': 'Дорошенко Юрій',      'position': 'Солдат',              'email': 'yurii.doroshenko@viti.edu.ua',    'phone': '+380671100104'},
  {'name': 'Єрошенко Богдан',     'position': 'Солдат',              'email': 'bohdan.yeroshenko@viti.edu.ua',   'phone': '+380671100105'},
  {'name': 'Жук Олексій',         'position': 'Солдат',              'email': 'oleksiy.zhuk@viti.edu.ua',       'phone': '+380671100106'},
  {'name': 'Зінченко Артем',      'position': 'Солдат',              'email': 'artem.zinchenko@viti.edu.ua',    'phone': '+380671100107'},
  {'name': 'Іванець Микита',      'position': 'Солдат',              'email': 'mykyta.ivanets@viti.edu.ua',     'phone': '+380671100108'},
  {'name': 'Карпенко Владислав',  'position': 'Солдат',              'email': 'vladyslav.karpenko@viti.edu.ua', 'phone': '+380671100109'},
  {'name': 'Литвиненко Роман',    'position': 'Солдат',              'email': 'roman.lytvynenko@viti.edu.ua',   'phone': '+380671100110'},
  {'name': 'Мельниченко Дмитро',  'position': 'Солдат',              'email': 'dmytro.melnychenko@viti.edu.ua', 'phone': '+380671100111'},
  {'name': 'Нікітенко Максим',    'position': 'Солдат',              'email': 'maksym.nikitenko@viti.edu.ua',   'phone': '+380671100112'},
];

const _cadetsB = <Map<String, dynamic>>[
  {'name': 'Олійниченко Андрій',  'position': 'Командир відділення', 'email': 'andriy.oliinychenko@viti.edu.ua', 'phone': '+380672200201'},
  {'name': 'Петренко Василь',     'position': 'Заступник командира', 'email': 'vasyl.petrenko@viti.edu.ua',      'phone': '+380672200202'},
  {'name': 'Романченко Ігор',     'position': 'Солдат',              'email': 'ihor.romanchenko@viti.edu.ua',    'phone': '+380672200203'},
  {'name': 'Свиридченко Антон',   'position': 'Солдат',              'email': 'anton.svyrydchenko@viti.edu.ua',  'phone': '+380672200204'},
  {'name': 'Терещенко Євген',     'position': 'Солдат',              'email': 'yevhen.tereshchenko@viti.edu.ua', 'phone': '+380672200205'},
  {'name': 'Ткаченко Вадим',      'position': 'Солдат',              'email': 'vadym.tkachenko@viti.edu.ua',     'phone': '+380672200206'},
  {'name': 'Удовиченко Олег',     'position': 'Солдат',              'email': 'oleh.udovychenko@viti.edu.ua',    'phone': '+380672200207'},
  {'name': 'Федоренко Руслан',    'position': 'Солдат',              'email': 'ruslan.fedorenko@viti.edu.ua',    'phone': '+380672200208'},
  {'name': 'Харченко Станіслав',  'position': 'Солдат',              'email': 'stanislav.kharchenko@viti.edu.ua','phone': '+380672200209'},
  {'name': 'Цибуленко Кирило',    'position': 'Солдат',              'email': 'kyrylo.tsybulenko@viti.edu.ua',   'phone': '+380672200210'},
  {'name': 'Чорновол Іван',       'position': 'Солдат',              'email': 'ivan.chornovil@viti.edu.ua',      'phone': '+380672200211'},
  {'name': 'Шульженко Денис',     'position': 'Солдат',              'email': 'denys.shulzhenko@viti.edu.ua',    'phone': '+380672200212'},
];

const _cadetsByGroupName = <String, List<Map<String, dynamic>>>{
  '121': _cadetsA,
  '122': _cadetsB,
  '131': _cadetsA,
  '132': _cadetsB,
  '141': _cadetsA,
  '142': _cadetsB,
  '222': _cadetsB,
};

// ── Сторінка всіх навчальних груп ────────────────────────────────────────────

class AllGroupsPage extends StatefulWidget {
  const AllGroupsPage({super.key});

  @override
  State<AllGroupsPage> createState() => _AllGroupsPageState();
}

class _AllGroupsPageState extends State<AllGroupsPage> {
  String _search = '';

  List<Map<String, dynamic>> get _filtered => _allGroups
      .where((g) =>
          g['name'].toString().contains(_search) ||
          (g['specialty'] as String).toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

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
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMid, size: 18),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Груп не знайдено',
                            style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final g = filtered[i];
                      return _GroupCard(group: g);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final name = group['name'] as String;
        final cadets = _cadetsByGroupName[name] ??
            (name == '221' ? _MyGroupPageState._cadets : _cadetsA);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailPage(group: group, cadets: cadets),
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
                Text(group['name'] as String,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('ID: ${group['id']}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMid)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(group['specialty'] as String,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMid),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
            _GroupInfoRow(label: 'Рік вступу', value: '${group['year']}'),
            const SizedBox(height: 2),
            _GroupInfoRow(label: 'Ступінь', value: group['degree'] as String),
            const SizedBox(height: 2),
            _GroupInfoRow(label: 'Факультет', value: group['faculty'] as String),
          ],
        ),
      ),
    );
  }
}

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

// ── Деталі конкретної групи (для не-курсантів) ────────────────────────────────

class GroupDetailPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> cadets;
  const GroupDetailPage({super.key, required this.group, required this.cadets});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  String _search = '';

  List<Map<String, dynamic>> get _filtered => widget.cadets
      .where((c) => c['name']
          .toString()
          .toLowerCase()
          .contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final g = widget.group;

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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Text('Деталі ${g['name']} групи',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
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
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark)),
                  ]),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoBadge(label: 'Група',        value: g['name'] as String),
                      _InfoBadge(label: 'Факультет',    value: g['faculty'] as String),
                      _InfoBadge(label: 'Спеціальність',value: g['specialty'] as String),
                      _InfoBadge(label: 'Рік вступу',   value: '${g['year']}'),
                      _InfoBadge(label: 'Ступінь',      value: g['degree'] as String),
                      _InfoBadge(label: 'Тип',          value: g['type'] as String),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.people_outline, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Text('Курсанти (${widget.cadets.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Пошук курсантів...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textMid, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
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

class MyGroupPage extends StatefulWidget {
  const MyGroupPage({super.key});

  @override
  State<MyGroupPage> createState() => _MyGroupPageState();
}

class _MyGroupPageState extends State<MyGroupPage> {
  String _search = '';

  // Мокові дані групи
  static const _groupInfo = {
    'name': '221',
    'faculty': '2',
    'specialty': "Комп'ютерні науки",
    'yearStart': '2022',
    'degree': 'Бакалавр',
    'type': 'Очна ф.н.',
  };

  // Мокові курсанти з контактами
  static final List<Map<String, dynamic>> _cadets = [
    {'name': 'Атабаєв Олексій',    'position': 'Солдат',              'email': 'oleksiy.atabayev@viti.edu.ua',    'phone': '+380683394811'},
    {'name': 'Ващик Олександр',    'position': 'Солдат',              'email': 'oleksandr.vashchyk@viti.edu.ua',  'phone': '+380680947558'},
    {'name': 'Войтенко Андрій',    'position': 'Солдат',              'email': 'andriy.voytenko@viti.edu.ua',     'phone': '+380635727653'},
    {'name': 'Гупало Ярослав',     'position': 'Солдат',              'email': 'yaroslav.gupalo@viti.edu.ua',     'phone': '+380671234567'},
    {'name': 'Кравченко Іван',     'position': 'Солдат',              'email': 'ivan.kravchenko@viti.edu.ua',     'phone': '+380682345678'},
    {'name': 'Макаренко Богдан',   'position': 'Командир відділення', 'email': 'bogdan.makarenko@viti.edu.ua',    'phone': '+380993456789'},
    {'name': 'Мельник Андрій',     'position': 'Солдат',              'email': 'andriy.melnyk@viti.edu.ua',       'phone': '+380674567890'},
    {'name': 'Науменко Олексій',   'position': 'Заступник командира', 'email': 'oleksiy.naumenko@viti.edu.ua',    'phone': '+380685678901'},
    {'name': 'Романенко Василь',   'position': 'Солдат',              'email': 'vasyl.romanenko@viti.edu.ua',     'phone': '+380636789012'},
    {'name': 'Лисенко Микола',     'position': 'Солдат',              'email': 'mykola.lysenko@viti.edu.ua',      'phone': '+380997890123'},
    {'name': 'Бондаренко Дмитро',  'position': 'Солдат',              'email': 'dmytro.bondarenko@viti.edu.ua',   'phone': '+380688901234'},
    {'name': 'Гриценко Сергій',    'position': 'Солдат',              'email': 'serhiy.hrytsenko@viti.edu.ua',    'phone': '+380679012345'},
    {'name': 'Чернікова Катерина', 'position': 'Солдат',              'email': 'kateryna.chernikova@viti.edu.ua', 'phone': '+380630123456'},
    {'name': 'Дубовик Владислав',  'position': 'Солдат',              'email': 'vladyslav.dubovyk@viti.edu.ua',   'phone': '+380991234567'},
    {'name': 'Шевченко Тарас',     'position': 'Солдат',              'email': 'taras.shevchenko@viti.edu.ua',    'phone': '+380682345679'},
  ];

  List<Map<String, dynamic>> get _filtered => _cadets
      .where((c) => c['name']
          .toString()
          .toLowerCase()
          .contains(_search.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
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
          // ── Заголовок ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Text(
                'Деталі ${_groupInfo['name']} групи',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark),
              ),
            ),
          ),

          // ── Інформація про групу ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
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
                  // Заголовок картки
                  Row(
                    children: [
                      const Icon(Icons.school,
                          color: AppTheme.primary, size: 26),
                      const SizedBox(width: 12),
                      Text('Інформація про групу',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Бейджі
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoBadge(label: 'Група', value: _groupInfo['name']!),
                      _InfoBadge(label: 'Факультет', value: _groupInfo['faculty']!),
                      _InfoBadge(label: 'Спеціальність', value: _groupInfo['specialty']!),
                      _InfoBadge(label: 'Рік вступу', value: _groupInfo['yearStart']!),
                      _InfoBadge(label: 'Ступінь', value: _groupInfo['degree']!),
                      _InfoBadge(label: 'Тип', value: _groupInfo['type']!),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Курсанти ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок секції
                  Row(
                    children: [
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
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Пошук
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Пошук курсантів...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.textMid, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── Список курсантів ─────────────────────────────────────────────
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

  Color get _positionColor {
    final pos = cadet['position'] as String;
    if (pos == 'Командир відділення') return const Color(0xFF1D4ED8);
    if (pos == 'Заступник командира') return const Color(0xFF7C3AED);
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
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
          // Ім'я
          Text(cadet['name'] as String,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),

          // Посада (бейдж)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _positionColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(cadet['position'] as String,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 12),

          // Email
          _ContactRow(
            label: 'EMAIL:',
            value: cadet['email'] as String,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 6),

          // Телефон
          _ContactRow(
            label: 'ТЕЛЕФОН:',
            value: cadet['phone'] as String,
            icon: Icons.phone_outlined,
          ),
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
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textDark)),
      ],
    );
  }
}
