// lib/features/grades/data/models/grade_model.dart

import 'lesson_model.dart';

class GradeModel {
  final int id;
  final int lessonId;
  final int cadetId;
  final String cadetName;
  final double? score;
  final String? status; // null | 'Н' | 'ІЗ' | 'Зв'

  const GradeModel({
    required this.id,
    required this.lessonId,
    required this.cadetId,
    required this.cadetName,
    this.score,
    this.status,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) => GradeModel(
        id: json['id'] as int,
        lessonId: json['lessonId'] as int,
        cadetId: json['cadetId'] as int,
        cadetName: json['cadetName'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble(),
        status: json['status'] as String?,
      );
}

// ── Повна відповідь журналу ────────────────────────────────────────────────────

class GradeJournalResponse {
  final int journalId;
  final List<JournalCadet> cadets;
  final List<LessonModel> lessons; // використовуємо LessonModel замість окремого JournalLesson

  const GradeJournalResponse({
    required this.journalId,
    required this.cadets,
    required this.lessons,
  });

  factory GradeJournalResponse.fromJson(Map<String, dynamic> json) {
    final journalId = json['id'] as int? ?? 0;
    return GradeJournalResponse(
      journalId: journalId,
      cadets: (json['cadets'] as List<dynamic>? ?? [])
          .map((e) => JournalCadet.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Inject journalId into each lesson so LessonModel has correct reference
      lessons: (json['lessons'] as List<dynamic>? ?? [])
          .map((e) => LessonModel.fromJson({
                ...(e as Map<String, dynamic>),
                'journalId': journalId,
              }))
          .toList(),
    );
  }
}

// ── Курсант з оцінками ────────────────────────────────────────────────────────

class JournalCadet {
  final int id;
  final String fullName;
  final Map<int, double?> gradesByLessonId;
  final Map<int, String?> statusByLessonId;

  const JournalCadet({
    required this.id,
    required this.fullName,
    required this.gradesByLessonId,
    required this.statusByLessonId,
  });

  factory JournalCadet.fromJson(Map<String, dynamic> json) {
    final grades = <int, double?>{};
    final statuses = <int, String?>{};
    for (final g in (json['grades'] as List<dynamic>? ?? [])) {
      final gMap = g as Map<String, dynamic>;
      final lessonId = gMap['lessonId'] as int;
      grades[lessonId] = (gMap['score'] as num?)?.toDouble();
      statuses[lessonId] = gMap['status'] as String?;
    }
    return JournalCadet(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      gradesByLessonId: grades,
      statusByLessonId: statuses,
    );
  }
}
