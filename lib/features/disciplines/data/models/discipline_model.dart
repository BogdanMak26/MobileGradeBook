// lib/features/disciplines/data/models/discipline_model.dart

class DisciplineModel {
  final int id;
  final String fullName;
  final String? shortName;
  final String? teacherName;
  final int? kafedraId;
  final int journalCount;
  // Populated only for cadet (from /rates/cadets/{id} response)
  final int? journalId;
  final int? groupId;
  final int? semesterId;

  const DisciplineModel({
    required this.id,
    required this.fullName,
    this.shortName,
    this.teacherName,
    this.kafedraId,
    this.journalCount = 0,
    this.journalId,
    this.groupId,
    this.semesterId,
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
      journalId: json['journalId'] as int?,
      groupId: json['groupId'] as int?,
      semesterId: json['semesterId'] as int?,
    );
  }

  static String? _buildTeacherName(Map<String, dynamic>? teacher) {
    if (teacher == null) return null;
    final last = teacher['lastName'] as String? ?? '';
    final first = teacher['firstName'] as String? ?? '';
    return '$last $first'.trim();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': fullName,
        'shortName': shortName,
        'teacherName': teacherName,
        'kafedraId': kafedraId,
        'journalCount': journalCount,
        if (journalId != null) 'journalId': journalId,
        if (groupId != null) 'groupId': groupId,
        if (semesterId != null) 'semesterId': semesterId,
      };
}
