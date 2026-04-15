// lib/features/grades/domain/entities/grade_entity.dart

import 'package:equatable/equatable.dart';

class GradeEntity extends Equatable {
  final String id;
  final String lessonId;
  final String cadetId;
  final int? score;
  final String? gradeValue;
  final String? status;
  final String? note;
  final int serverVersion;
  final int clientVersion;
  final DateTime updatedAt;
  final bool isSynced;

  const GradeEntity({
    required this.id,
    required this.lessonId,
    required this.cadetId,
    this.score,
    this.gradeValue,
    this.status,
    this.note,
    required this.serverVersion,
    required this.clientVersion,
    required this.updatedAt,
    required this.isSynced,
  });

  String get displayScore => score?.toString() ?? '—';

  GradeEntity copyWith({
    int? score,
    String? gradeValue,
    String? status,
    String? note,
  }) {
    return GradeEntity(
      id: id,
      lessonId: lessonId,
      cadetId: cadetId,
      score: score ?? this.score,
      gradeValue: gradeValue ?? this.gradeValue,
      status: status ?? this.status,
      note: note ?? this.note,
      serverVersion: serverVersion,
      clientVersion: clientVersion + 1,
      updatedAt: DateTime.now(),
      isSynced: false,
    );
  }

  @override
  List<Object?> get props =>
      [id, lessonId, cadetId, score, gradeValue, status, isSynced];
}
