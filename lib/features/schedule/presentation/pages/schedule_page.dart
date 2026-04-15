// lib/features/schedule/presentation/pages/schedule_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../shared/theme/app_theme.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _selected = DateTime.now();

  List<MockLesson> get _dayLessons {
    return MockDataProvider.lessons.where((l) =>
        l.date.day == _selected.day && l.date.month == _selected.month).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Розклад')),
      body: Column(
        children: [
          _WeekStrip(selected: _selected, onSelect: (d) => setState(() => _selected = d)),
          Expanded(
            child: _dayLessons.isEmpty
                ? _EmptyDay(date: _selected)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _dayLessons.length,
                    itemBuilder: (context, i) =>
                        _LessonCard(lesson: _dayLessons[i], number: i + 1),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _WeekStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final now = DateTime.now();

    return Container(
      color: AppTheme.sidebar,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: days.map((day) {
          final isSelected = day.day == selected.day && day.month == selected.month;
          final isToday = day.day == now.day && day.month == now.month;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(day),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected
                      ? Border.all(color: Colors.white38)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('E', 'uk').format(day).toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white),
                    ),
                    // Dot for days with lessons
                    if (_hasLessons(day))
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _hasLessons(DateTime day) {
    return MockDataProvider.lessons.any(
        (l) => l.date.day == day.day && l.date.month == day.month);
  }
}

class _LessonCard extends StatelessWidget {
  final MockLesson lesson;
  final int number;
  const _LessonCard({required this.lesson, required this.number});

  Color get _typeColor {
    switch (lesson.type) {
      case 'lecture': return AppTheme.secondary;
      case 'practice': return AppTheme.primary;
      case 'seminar': return const Color(0xFF7C3AED);
      case 'lab': return const Color(0xFF059669);
      default: return AppTheme.textMid;
    }
  }

  String get _typeLabel {
    switch (lesson.type) {
      case 'lecture': return 'Лекція';
      case 'practice': return 'Практика';
      case 'seminar': return 'Семінар';
      case 'lab': return 'Лаборат.';
      default: return lesson.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _typeColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Time/number column
            SizedBox(
              width: 42,
              child: Column(
                children: [
                  Text(DateFormat('HH:mm').format(lesson.date),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text('Пара $number',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textMid)),
                ],
              ),
            ),
            Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppTheme.border),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.topic,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_typeLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _typeColor)),
                    ),
                    const SizedBox(width: 8),
                    Text(lesson.disciplineName,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMid)),
                    const SizedBox(width: 8),
                    Text('Гр. ${lesson.group}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textLight)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final DateTime date;
  const _EmptyDay({required this.date});

  @override
  Widget build(BuildContext context) {
    final isWeekend = date.weekday >= 6;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWeekend ? Icons.weekend : Icons.event_available,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            isWeekend ? 'Вихідний день' : 'Занять немає',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, d MMMM', 'uk').format(date),
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
