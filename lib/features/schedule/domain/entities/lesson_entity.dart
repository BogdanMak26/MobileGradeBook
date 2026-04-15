// lib/features/schedule/domain/entities/lesson_entity.dart

import 'package:equatable/equatable.dart';

class LessonEntity extends Equatable {
  final String id;
  final String disciplineId;
  final String groupId;
  final int? lessonNumber;
  final String? topic;
  final String? type;
  final DateTime date;

  const LessonEntity({
    required this.id,
    required this.disciplineId,
    required this.groupId,
    this.lessonNumber,
    this.topic,
    this.type,
    required this.date,
  });

  String get displayType {
    switch (type) {
      case 'lecture': return 'Лекція';
      case 'seminar': return 'Семінар';
      case 'lab': return 'Лабораторна';
      case 'practice': return 'Практика';
      default: return type ?? 'Заняття';
    }
  }

  @override
  List<Object?> get props => [id, disciplineId, date];
}
