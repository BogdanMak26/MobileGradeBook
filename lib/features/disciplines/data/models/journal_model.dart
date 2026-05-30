// lib/features/disciplines/data/models/journal_model.dart

class JournalModel {
  final int id;           // journalId from API
  final int semesterId;   // semester DB ID (e.g. 68) — used for API calls
  final int groupId;
  final String groupName;
  final int disciplineId; // 0 if not returned by API
  final String disciplineName;
  final int semester;     // semester number (e.g. 8)
  final String? startDate;
  final String? endDate;
  final String? academicYear;
  final String? driveLink;
  final String? meetLink;
  final String? moodleLink;

  const JournalModel({
    required this.id,
    required this.semesterId,
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

  Map<String, dynamic> toJson() => {
        'journalId': id,
        'semesterId': semesterId,
        'groupId': groupId,
        'groupName': groupName,
        'disciplineId': disciplineId,
        'disciplineName': disciplineName,
        'semester': semester,
        'startDate': startDate,
        'endDate': endDate,
        'academicYear': academicYear,
        'driveLink': driveLink,
        'meetLink': meetLink,
        'moodleLink': moodleLink,
      };

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    final group = json['group'] as Map<String, dynamic>?;
    final discipline = json['discipline'] as Map<String, dynamic>?;

    // API returns nested semesters array: [{semesterId, semesterNumber, startDate, endDate}]
    final semestersList = json['semesters'] as List<dynamic>?;
    final firstSem = semestersList?.isNotEmpty == true
        ? semestersList!.first as Map<String, dynamic>?
        : null;

    return JournalModel(
      id: json['journalId'] as int? ?? json['id'] as int? ?? 0,
      semesterId: firstSem?['semesterId'] as int? ?? firstSem?['id'] as int? ?? json['semesterId'] as int? ?? 0,
      groupId: json['groupId'] as int? ?? group?['id'] as int? ?? 0,
      groupName: json['groupName'] as String? ?? group?['name'] as String? ?? '',
      disciplineId: json['disciplineId'] as int? ?? discipline?['id'] as int? ?? 0,
      disciplineName: json['disciplineFullName'] as String? ??
          json['disciplineName'] as String? ??
          discipline?['name'] as String? ?? '',
      semester: firstSem?['semesterNumber'] as int? ?? json['semester'] as int? ?? 0,
      startDate: firstSem?['startDate'] as String? ?? json['startDate'] as String?,
      endDate: firstSem?['endDate'] as String? ?? json['endDate'] as String?,
      academicYear: json['academicYear'] as String?,
      driveLink: json['driveLink'] as String?,
      meetLink: json['meetLink'] as String?,
      moodleLink: json['moodleLink'] as String?,
    );
  }
}
