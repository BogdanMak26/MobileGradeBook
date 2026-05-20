// lib/features/grades/data/models/lesson_model.dart

class LessonModel {
  final int id;
  final int journalId;
  final String code;
  final String type;
  final String topic;
  final String date;
  final double maxScore;
  final int? pair;
  final String? room;

  const LessonModel({
    required this.id,
    required this.journalId,
    required this.code,
    required this.type,
    required this.topic,
    required this.date,
    required this.maxScore,
    this.pair,
    this.room,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    // Handle JournalLessonResource (lessonId/lessonName/lessonTheme/lessonType)
    // and LessonDetailsResource (id/name/theme/type) formats
    double maxScore = (json['markMaxValue'] as num?)?.toDouble() ?? 0.0;
    if (maxScore == 0.0) {
      final subLessons = json['subLessons'] as List<dynamic>?;
      if (subLessons != null) {
        maxScore = subLessons.fold(0.0, (sum, sl) {
          final slMap = sl as Map<String, dynamic>;
          return sum + ((slMap['markMaxValue'] as num?)?.toDouble() ?? 0.0);
        });
      }
    }
    return LessonModel(
      id: (json['lessonId'] ?? json['id']) as int,
      journalId: json['journalId'] as int? ?? 0,
      code: json['lessonName'] as String?
          ?? json['name'] as String?
          ?? json['code'] as String?
          ?? '',
      type: json['lessonType'] as String?
          ?? json['type'] as String?
          ?? 'ЛЕКЦІЯ',
      topic: json['lessonTheme'] as String?
          ?? json['theme'] as String?
          ?? json['topic'] as String?
          ?? '',
      date: json['lessonDate'] as String? ?? json['date'] as String? ?? '',
      maxScore: maxScore,
      pair: json['lessonPara'] as int? ?? json['pair'] as int?,
      room: json['room'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'type': type,
    'topic': topic,
    'date': date,
    'maxScore': maxScore,
    if (pair != null) 'pair': pair,
    if (room != null) 'room': room,
  };
}
