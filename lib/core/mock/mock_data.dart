// lib/core/mock/mock_data.dart

class MockUser {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String role;
  final String? groupName;
  final String? kafedraName;
  final String? rank;
  final String? position;

  const MockUser({required this.id, required this.name, required this.surname,
    required this.email, required this.role, this.groupName,
    this.kafedraName, this.rank, this.position});

  String get fullName => '$surname $name';
}

class MockDiscipline {
  final int id;
  final String fullName;
  final String? shortName;
  final String? teacherName;
  final int journalCount;
  final String? driveLink;

  const MockDiscipline({required this.id, required this.fullName,
    this.shortName, this.teacherName, this.journalCount = 0, this.driveLink});
}

class MockLesson {
  final int id;
  final int disciplineId;      // ← прив'язка до дисципліни через ID
  final String disciplineName; // ← для відображення в розкладі
  final String topic;
  final String type;
  final DateTime date;
  final int lessonNumber;
  final String group;

  const MockLesson({
    required this.id,
    required this.disciplineId,
    required this.disciplineName,
    required this.topic,
    required this.type,
    required this.date,
    required this.lessonNumber,
    required this.group,
  });
}

class MockCadet {
  final int id;
  final String name;
  final String surname;
  final String group;

  const MockCadet({required this.id, required this.name,
    required this.surname, required this.group});

  String get fullName => '$surname $name';
  String get initial => surname[0];
}

class MockGrade {
  final int cadetId;
  int? score;
  String? status;
  String? comment;

  MockGrade({required this.cadetId, this.score, this.status, this.comment});
}

class MockDataProvider {
  static const MockUser currentUser = MockUser(
    id: '1', name: 'Богдан', surname: 'Макаренко',
    email: 'makarenko.b@viti.edu.ua', role: 'INSTRUCTOR',
    kafedraName: 'Кафедра №22', rank: 'Лейтенант', position: 'Викладач',
  );

  static const MockUser cadetUser = MockUser(
    id: '2', name: 'Олексій', surname: 'Сачук',
    email: 'sachuk.o@viti.edu.ua', role: 'CADET', groupName: 'Група 221',
  );

  static final List<MockDiscipline> disciplines = [
    const MockDiscipline(id: 1,
      fullName: 'Захист інформації в телекомунікаційних системах',
      shortName: 'ЗІТС', teacherName: 'Макаренко Б.', journalCount: 3,
      driveLink: 'https://drive.google.com'),
    const MockDiscipline(id: 2,
      fullName: 'Комп\'ютерні мережі та технології',
      shortName: 'КМТ', teacherName: 'Іваненко В.', journalCount: 2),
    const MockDiscipline(id: 3,
      fullName: 'Криптографічний захист інформації',
      shortName: 'КЗІ', teacherName: 'Петренко С.', journalCount: 1),
    const MockDiscipline(id: 4,
      fullName: 'Основи кібербезпеки',
      shortName: 'ОКБ', teacherName: 'Макаренко Б.', journalCount: 2),
    const MockDiscipline(id: 5,
      fullName: 'Програмування мікроконтролерів',
      shortName: 'ПМ', teacherName: 'Коваль О.', journalCount: 1),
  ];

  // ── Заняття прив'язані до disciplineId ──────────────────────────────────
  static List<MockLesson> get lessons => [
    // ЗІТС (id: 1) — 4 заняття
    MockLesson(id: 1,  disciplineId: 1, disciplineName: 'ЗІТС',
      topic: 'Вступ. Основи захисту інформації', type: 'lecture',
      date: DateTime.now().subtract(const Duration(days: 14)),
      lessonNumber: 1, group: '221'),
    MockLesson(id: 2,  disciplineId: 1, disciplineName: 'ЗІТС',
      topic: 'Протоколи шифрування TLS/SSL', type: 'lecture',
      date: DateTime.now().subtract(const Duration(days: 7)),
      lessonNumber: 2, group: '221'),
    MockLesson(id: 3,  disciplineId: 1, disciplineName: 'ЗІТС',
      topic: 'Практична робота №1 — аналіз трафіку', type: 'practice',
      date: DateTime.now().subtract(const Duration(days: 3)),
      lessonNumber: 3, group: '221'),
    MockLesson(id: 4,  disciplineId: 1, disciplineName: 'ЗІТС',
      topic: 'Семінар: сучасні загрози ІБ', type: 'seminar',
      date: DateTime.now(),
      lessonNumber: 4, group: '221'),

    // КМТ (id: 2) — 3 заняття
    MockLesson(id: 5,  disciplineId: 2, disciplineName: 'КМТ',
      topic: 'Модель OSI. Рівні мережі', type: 'lecture',
      date: DateTime.now().subtract(const Duration(days: 12)),
      lessonNumber: 1, group: '221'),
    MockLesson(id: 6,  disciplineId: 2, disciplineName: 'КМТ',
      topic: 'Маршрутизація в IP-мережах', type: 'lecture',
      date: DateTime.now().subtract(const Duration(days: 5)),
      lessonNumber: 2, group: '221'),
    MockLesson(id: 7,  disciplineId: 2, disciplineName: 'КМТ',
      topic: 'Лабораторна: налаштування VLAN', type: 'lab',
      date: DateTime.now().add(const Duration(days: 1)),
      lessonNumber: 3, group: '221'),

    // КЗІ (id: 3) — 2 заняття
    MockLesson(id: 8,  disciplineId: 3, disciplineName: 'КЗІ',
      topic: 'Симетричне шифрування. AES', type: 'lecture',
      date: DateTime.now().subtract(const Duration(days: 10)),
      lessonNumber: 1, group: '221'),
    MockLesson(id: 9,  disciplineId: 3, disciplineName: 'КЗІ',
      topic: 'Асиметричне шифрування. RSA', type: 'seminar',
      date: DateTime.now().add(const Duration(days: 2)),
      lessonNumber: 2, group: '221'),

    // ОКБ (id: 4) — 3 заняття
    MockLesson(id: 10, disciplineId: 4, disciplineName: 'ОКБ',
      topic: 'Вступ до кібербезпеки', type: 'lecture',
      date: DateTime.now().subtract(const Duration(days: 9)),
      lessonNumber: 1, group: '221'),
    MockLesson(id: 11, disciplineId: 4, disciplineName: 'ОКБ',
      topic: 'Вразливості та атаки', type: 'lecture',
      date: DateTime.now().subtract(const Duration(days: 2)),
      lessonNumber: 2, group: '221'),
    MockLesson(id: 12, disciplineId: 4, disciplineName: 'ОКБ',
      topic: 'Лабораторна робота №2', type: 'lab',
      date: DateTime.now().add(const Duration(days: 3)),
      lessonNumber: 3, group: '221'),

    // ПМ (id: 5) — 2 заняття
    MockLesson(id: 13, disciplineId: 5, disciplineName: 'ПМ',
      topic: 'Архітектура AVR мікроконтролерів', type: 'lecture',
      date: DateTime.now().subtract(const Duration(days: 6)),
      lessonNumber: 1, group: '221'),
    MockLesson(id: 14, disciplineId: 5, disciplineName: 'ПМ',
      topic: 'Програмування портів вводу/виводу', type: 'lab',
      date: DateTime.now().add(const Duration(days: 4)),
      lessonNumber: 2, group: '221'),
  ];

  // ── Отримати заняття за disciplineId ────────────────────────────────────
  static List<MockLesson> lessonsForDiscipline(int disciplineId) =>
      lessons.where((l) => l.disciplineId == disciplineId).toList()
        ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

  // ── Отримати дисципліну за ID ────────────────────────────────────────────
  static MockDiscipline? disciplineById(int id) =>
      disciplines.where((d) => d.id == id).firstOrNull;

  static final List<MockCadet> cadets = [
    const MockCadet(id: 1, name: 'Олексій',  surname: 'Сачук',       group: '221'),
    const MockCadet(id: 2, name: 'Дмитро',   surname: 'Бондаренко',  group: '221'),
    const MockCadet(id: 3, name: 'Іван',      surname: 'Кравченко',   group: '221'),
    const MockCadet(id: 4, name: 'Андрій',    surname: 'Мельник',     group: '221'),
    const MockCadet(id: 5, name: 'Сергій',    surname: 'Гриценко',    group: '221'),
    const MockCadet(id: 6, name: 'Тарас',     surname: 'Шевченко',    group: '221'),
    const MockCadet(id: 7, name: 'Микола',    surname: 'Лисенко',     group: '221'),
    const MockCadet(id: 8, name: 'Василь',    surname: 'Романенко',   group: '221'),
  ];

  static List<MockGrade> gradesForLesson(int lessonId) => [
    MockGrade(cadetId: 1, score: 95, status: 'present'),
    MockGrade(cadetId: 2, score: 78, status: 'present'),
    MockGrade(cadetId: 3, score: 88, status: 'present'),
    MockGrade(cadetId: 4, score: null, status: 'absent'),
    MockGrade(cadetId: 5, score: 72, status: 'present'),
    MockGrade(cadetId: 6, score: 65, status: 'late'),
    MockGrade(cadetId: 7, score: 91, status: 'present'),
    MockGrade(cadetId: 8, score: 83, status: 'present'),
  ];

  static final List<Map<String, dynamic>> cadetGrades = [
    {'discipline': 'ЗІТС', 'lesson': 'Лекція 1', 'score': 95, 'status': 'present', 'date': DateTime.now().subtract(const Duration(days: 14))},
    {'discipline': 'ЗІТС', 'lesson': 'Лекція 2', 'score': 88, 'status': 'present', 'date': DateTime.now().subtract(const Duration(days: 7))},
    {'discipline': 'ЗІТС', 'lesson': 'Практика 1', 'score': 91, 'status': 'present', 'date': DateTime.now().subtract(const Duration(days: 3))},
    {'discipline': 'КМТ',  'lesson': 'Лекція 1', 'score': 72, 'status': 'present', 'date': DateTime.now().subtract(const Duration(days: 12))},
    {'discipline': 'КМТ',  'lesson': 'Лекція 2', 'score': null, 'status': 'absent', 'date': DateTime.now().subtract(const Duration(days: 5))},
    {'discipline': 'КЗІ',  'lesson': 'Лекція 1', 'score': 85, 'status': 'present', 'date': DateTime.now().subtract(const Duration(days: 10))},
    {'discipline': 'ОКБ',  'lesson': 'Лекція 1', 'score': 78, 'status': 'late',    'date': DateTime.now().subtract(const Duration(days: 9))},
    {'discipline': 'ОКБ',  'lesson': 'Лекція 2', 'score': 82, 'status': 'present', 'date': DateTime.now().subtract(const Duration(days: 2))},
  ];
}
