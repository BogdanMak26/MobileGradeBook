// lib/features/groups/presentation/pages/my_group_page.dart

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

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
