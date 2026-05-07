// lib/features/disciplines/data/models/journal_model.dart

class JournalModel {
  final int id;
  final int groupId;
  final String groupName;
  final int disciplineId;
  final String disciplineName;
  final int semester;
  final String? startDate;
  final String? endDate;
  final String? academicYear;
  final String? driveLink;
  final String? meetLink;
  final String? moodleLink;

  const JournalModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.disciplineId,
    required this.disciplineName,
    required this.semester,
    this.startDate,
    this.endDate,
    this.academicYear,
    this.driveLink,
    this.meetLink,
    this.moodleLink,
  });

  bool get hasDrive => driveLink != null && driveLink!.isNotEmpty;
  bool get hasMeet => meetLink != null && meetLink!.isNotEmpty;
  bool get hasMoodle => moodleLink != null && moodleLink!.isNotEmpty;

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    final group = json['group'] as Map<String, dynamic>?;
    final discipline = json['discipline'] as Map<String, dynamic>?;
    return JournalModel(
      id: json['id'] as int,
      groupId: json['groupId'] as int? ?? group?['id'] as int? ?? 0,
      groupName: json['groupName'] as String? ?? group?['name'] as String? ?? '',
      disciplineId: json['disciplineId'] as int? ?? discipline?['id'] as int? ?? 0,
      disciplineName: json['disciplineName'] as String? ?? discipline?['name'] as String? ?? '',
      semester: json['semester'] as int? ?? 0,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      academicYear: json['academicYear'] as String?,
      driveLink: json['driveLink'] as String?,
      meetLink: json['meetLink'] as String?,
      moodleLink: json['moodleLink'] as String?,
    );
  }
}
