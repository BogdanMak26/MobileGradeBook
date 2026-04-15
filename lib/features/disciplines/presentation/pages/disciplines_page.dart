// lib/features/disciplines/presentation/pages/disciplines_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../shared/theme/app_theme.dart';

class DisciplinesPage extends ConsumerStatefulWidget {
  const DisciplinesPage({super.key});

  @override
  ConsumerState<DisciplinesPage> createState() => _DisciplinesPageState();
}

class _DisciplinesPageState extends ConsumerState<DisciplinesPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final disciplines = MockDataProvider.disciplines
        .where((d) =>
            d.fullName.toLowerCase().contains(_search.toLowerCase()) ||
            (d.shortName?.toLowerCase().contains(_search.toLowerCase()) ?? false))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Дисципліни')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Пошук дисциплін...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textMid, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: disciplines.isEmpty
                ? _EmptyState(search: _search)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: disciplines.length,
                    itemBuilder: (context, i) =>
                        _DisciplineCard(discipline: disciplines[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DisciplineCard extends StatelessWidget {
  final MockDiscipline discipline;
  const _DisciplineCard({required this.discipline});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/disciplines/${discipline.id}/journal'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (discipline.shortName != null)
                          Text(
                            discipline.shortName!,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          discipline.fullName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.school, color: AppTheme.primary, size: 24),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (discipline.teacherName != null)
                          Row(children: [
                            const Text('Викладач: ',
                                style: TextStyle(
                                    fontSize: 12, color: AppTheme.textMid)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(discipline.teacherName!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155))),
                            ),
                          ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Text('Журналів: ',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textMid)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: discipline.journalCount == 0
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              discipline.journalCount == 0
                                  ? 'Немає'
                                  : '${discipline.journalCount}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: discipline.journalCount == 0
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF334155),
                                  fontStyle: discipline.journalCount == 0
                                      ? FontStyle.italic
                                      : FontStyle.normal),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  // Resource links
                  if (discipline.driveLink != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder,
                              color: Color(0xFF2E7D32), size: 12),
                          SizedBox(width: 4),
                          Text('Drive',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () =>
                        context.go('/disciplines/${discipline.id}/journal'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String search;
  const _EmptyState({required this.search});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            search.isNotEmpty ? 'Нічого не знайдено' : 'Немає дисциплін',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
          if (search.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Спробуйте інший запит',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ),
        ],
      ),
    );
  }
}
