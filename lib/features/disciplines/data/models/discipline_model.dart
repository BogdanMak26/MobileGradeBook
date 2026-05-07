// lib/features/disciplines/data/models/discipline_model.dart

class DisciplineModel {
  final int id;
  final String fullName;
  final String? shortName;
  final String? teacherName;
  final int? kafedraId;
  final int journalCount;

  const DisciplineModel({
    required this.id,
    required this.fullName,
    this.shortName,
    this.teacherName,
    this.kafedraId,
    this.journalCount = 0,
  });

  factory DisciplineModel.fromJson(Map<String, dynamic> json) {
    return DisciplineModel(
      id: json['id'] as int,
      fullName: json['name'] as String? ?? json['fullName'] as String? ?? '',
      shortName: json['shortName'] as String?,
      teacherName: json['teacherName'] as String? ??
          _buildTeacherName(json['teacher'] as Map<String, dynamic>?),
      kafedraId: json['kafedraId'] as int?,
      journalCount: json['journalCount'] as int? ?? 0,
    );
  }

  static String? _buildTeacherName(Map<String, dynamic>? teacher) {
    if (teacher == null) return null;
    final last = teacher['lastName'] as String? ?? '';
    final first = teacher['firstName'] as String? ?? '';
    return '$last $first'.trim();
  }
}
