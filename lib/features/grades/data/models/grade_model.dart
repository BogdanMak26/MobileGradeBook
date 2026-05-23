// lib/features/grades/data/models/grade_model.dart

import 'lesson_model.dart';
import '../../../../core/utils/military_labels.dart';

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
    final journalId = json['journalId'] as int? ?? json['id'] as int? ?? 0;
    final lessonsRaw = json['lessons'] as List<dynamic>? ?? [];

    final lessons = lessonsRaw
        .map((l) => LessonModel.fromJson({
              ...(l as Map<String, dynamic>),
              'journalId': journalId,
            }))
        .toList();

    // Server returns cadets (names only) and grades inside lessons.subLessons.marks
    // attendance inside lessons.attends — build per-cadet maps from there
    final cadetsRaw = json['cadets'] as List<dynamic>? ?? [];
    final cadets = cadetsRaw.map((c) {
      final cMap = c as Map<String, dynamic>;
      final cadetId = cMap['cadetId'] as int? ?? cMap['id'] as int? ?? 0;
      final surname = cMap['cadetSurname'] as String? ?? '';
      final firstName = cMap['cadetName'] as String? ?? cMap['fullName'] as String? ?? '';
      final fullName = (surname.isNotEmpty && firstName.isNotEmpty)
          ? '$surname $firstName'
          : (surname + firstName).trim();

      final grades = <int, double?>{};
      final statuses = <int, String?>{};
      final markIds = <int, int>{};
      final attendIds = <int, int>{};

      for (final l in lessonsRaw) {
        final lMap = l as Map<String, dynamic>;
        final lessonId = (lMap['lessonId'] ?? lMap['id']) as int;

        // Sum marks for this cadet across all subLessons of this lesson
        double? totalScore;
        for (final sl in (lMap['subLessons'] as List<dynamic>? ?? [])) {
          final slMap = sl as Map<String, dynamic>;
          for (final m in (slMap['marks'] as List<dynamic>? ?? [])) {
            final mMap = m as Map<String, dynamic>;
            if ((mMap['cadetId'] as int?) == cadetId) {
              final v = (mMap['value'] as num?)?.toDouble();
              if (v != null) totalScore = (totalScore ?? 0.0) + v;
              final mId = mMap['id'] as int? ?? mMap['markId'] as int?;
              if (mId != null) markIds[lessonId] = mId;
            }
          }
        }
        if (totalScore != null) grades[lessonId] = totalScore;

        // Find attendance record for this cadet
        for (final a in (lMap['attends'] as List<dynamic>? ?? [])) {
          final aMap = a as Map<String, dynamic>;
          if ((aMap['cadetId'] as int?) == cadetId) {
            final code = MilitaryLabels.attendCode(aMap['attended'] as String?);
            if (code != null) statuses[lessonId] = code;
            final aId = aMap['id'] as int? ?? aMap['attendId'] as int?;
            if (aId != null) attendIds[lessonId] = aId;
            break;
          }
        }
      }

      return JournalCadet(
        id: cadetId,
        fullName: fullName,
        gradesByLessonId: grades,
        statusByLessonId: statuses,
        markIdByLessonId: markIds,
        attendIdByLessonId: attendIds,
      );
    }).toList();

    return GradeJournalResponse(
      journalId: journalId,
      cadets: cadets,
      lessons: lessons,
    );
  }
}

// ── Курсант з оцінками ────────────────────────────────────────────────────────

class JournalCadet {
  final int id;
  final String fullName;
  final Map<int, double?> gradesByLessonId;
  final Map<int, String?> statusByLessonId;
  final Map<int, int> markIdByLessonId;   // lessonId → markId   (for PATCH/DELETE marks)
  final Map<int, int> attendIdByLessonId; // lessonId → attendId (for PATCH/DELETE attends)

  const JournalCadet({
    required this.id,
    required this.fullName,
    required this.gradesByLessonId,
    required this.statusByLessonId,
    this.markIdByLessonId = const {},
    this.attendIdByLessonId = const {},
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
