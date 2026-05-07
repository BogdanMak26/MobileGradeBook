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
    return LessonModel(
      id: json['id'] as int,
      journalId: json['journalId'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? 'ЛЕКЦІЯ',
      topic: json['topic'] as String? ?? '',
      date: json['date'] as String? ?? '',
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 0,
      pair: json['pair'] as int?,
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
