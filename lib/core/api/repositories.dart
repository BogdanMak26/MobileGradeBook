// lib/core/api/repositories.dart
// Спільні репозиторії: користувачі, групи, семестри, журнали (CRUD), відвідуваність, курсанти, викладачі,
// факультети, кафедри, рейтинги.
// Для операцій з оцінками і заняттями використовуйте GradesRepository.
// Для читання дисциплін — DisciplinesRepository з features/disciplines/data.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

// ── User Repository ───────────────────────────────────────────────────────────

class UserRepository {
  final ApiClient _client;
  UserRepository(this._client);

  Future<Map<String, dynamic>> getMe() async {
    final r = await _client.dio.get('/me',
        options: Options(responseType: ResponseType.json));
    final raw = r.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    return Map<String, dynamic>.from(raw as Map);
  }

  /// Повертає сторінку користувачів. Параметри: page, size, role, search.
  Future<Map<String, dynamic>> getUsers({
    int page = 0,
    int size = 20,
    String? role,
    String? search,
  }) async {
    final r = await _client.dio.get('/users', queryParameters: {
      'page': page,
      'size': size,
      if (role != null && role.isNotEmpty) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    // Сервер повертає або Page<User> (з полем content) або List<User>
    final raw = r.data;
    if (raw is Map<String, dynamic>) return raw;
    return {'content': raw, 'totalElements': (raw as List).length};
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final r = await _client.dio.get('/users/$userId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final r = await _client.dio.post('/users', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUser(
      int userId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/users/$userId', data: data);
    return r.data as Map<String, dynamic>;
  }

  /// mode: 'DEACTIVATE' | 'FULL'
  Future<void> deleteUser(int userId, {String mode = 'DEACTIVATE'}) async {
    await _client.dio.delete('/users/$userId',
        queryParameters: {'mode': mode});
  }
}

final userRepositoryProvider = Provider<UserRepository>(
    (ref) => UserRepository(ref.read(apiClientProvider)));

// ── Groups Repository ─────────────────────────────────────────────────────────

class GroupsRepository {
  final ApiClient _client;
  GroupsRepository(this._client);

  Future<List<dynamic>> getGroups() async {
    final r = await _client.dio.get('/groups');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getGroupById(int groupId) async {
    final r = await _client.dio.get('/groups/$groupId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final r = await _client.dio.post('/groups', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGroup(
      int groupId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/groups/$groupId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteGroup(int groupId) async {
    await _client.dio.delete('/groups/$groupId');
  }
}

final groupsRepositoryProvider = Provider<GroupsRepository>(
    (ref) => GroupsRepository(ref.read(apiClientProvider)));

// ── Semesters Repository ──────────────────────────────────────────────────────

class SemestersRepository {
  final ApiClient _client;
  SemestersRepository(this._client);

  Future<List<dynamic>> getSemesters() async {
    final r = await _client.dio.get('/semesters');
    return r.data as List<dynamic>;
  }

  /// Повертає список поточних семестрів (сервер повертає List, не одиночний об'єкт).
  Future<List<dynamic>> getCurrentSemester() async {
    final r = await _client.dio.get('/semesters/current');
    final raw = r.data;
    if (raw is List) return raw;
    return [raw];
  }

  Future<Map<String, dynamic>> getSemesterById(int semesterId) async {
    final r = await _client.dio.get('/semesters/$semesterId');
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSemestersByGroup(int groupId) async {
    final r = await _client.dio.get('/semesters/groups/$groupId');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSemester(
      Map<String, dynamic> data) async {
    final r = await _client.dio.post('/semesters', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSemester(
      int semesterId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/semesters/$semesterId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteSemester(int semesterId) async {
    await _client.dio.delete('/semesters/$semesterId');
  }
}

final semestersRepositoryProvider = Provider<SemestersRepository>(
    (ref) => SemestersRepository(ref.read(apiClientProvider)));

// ── Journals Repository (CRUD адміна) ─────────────────────────────────────────

class JournalsRepository {
  final ApiClient _client;
  JournalsRepository(this._client);

  Future<List<dynamic>> getJournals({
    int? groupId,
    int? disciplineId,
    int? semesterId,
  }) async {
    final r = await _client.dio.get('/journals', queryParameters: {
      if (groupId != null) 'groupId': groupId,
      if (disciplineId != null) 'disciplineId': disciplineId,
      if (semesterId != null) 'semesterId': semesterId,
    });
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createJournal(Map<String, dynamic> data) async {
    final r = await _client.dio.post('/journals', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> duplicateJournal(
      Map<String, dynamic> data) async {
    final r = await _client.dio.post('/journals/duplicate', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateJournal(
      int journalId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/journals/$journalId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteJournal(int journalId) async {
    await _client.dio.delete('/journals/$journalId');
  }
}

final journalsRepositoryProvider = Provider<JournalsRepository>(
    (ref) => JournalsRepository(ref.read(apiClientProvider)));

// ── Attends Repository ────────────────────────────────────────────────────────

class AttendsRepository {
  final ApiClient _client;
  AttendsRepository(this._client);

  Future<List<dynamic>> getAttends({int? lessonId, int? cadetId}) async {
    final r = await _client.dio.get('/attends', queryParameters: {
      if (lessonId != null) 'lessonId': lessonId,
      if (cadetId != null) 'cadetId': cadetId,
    });
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createAttend(Map<String, dynamic> data) async {
    final r = await _client.dio.post('/attends', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> batchAttends(
      List<Map<String, dynamic>> attends) async {
    final r = await _client.dio.post('/attends/batch', data: attends);
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateAttend(
      int attendId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/attends/$attendId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteAttend(int attendId) async {
    await _client.dio.delete('/attends/$attendId');
  }
}

final attendsRepositoryProvider = Provider<AttendsRepository>(
    (ref) => AttendsRepository(ref.read(apiClientProvider)));

// ── Cadets Repository ─────────────────────────────────────────────────────────

class CadetsRepository {
  final ApiClient _client;
  CadetsRepository(this._client);

  Future<List<dynamic>> getCadets({int? groupId}) async {
    final r = await _client.dio.get('/cadets', queryParameters: {
      if (groupId != null) 'groupId': groupId,
    });
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getCadetById(int cadetId) async {
    final r = await _client.dio.get('/cadets/$cadetId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCadetAnalytics(int cadetId) async {
    final r = await _client.dio.get('/cadets/$cadetId/analytics');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCadet(Map<String, dynamic> data) async {
    final r = await _client.dio.post('/cadets', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCadet(
      int cadetId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/cadets/$cadetId', data: data);
    return r.data as Map<String, dynamic>;
  }

  /// mode: 'DEACTIVATE' | 'FULL'
  Future<void> deleteCadet(int cadetId, {String mode = 'DEACTIVATE'}) async {
    await _client.dio.delete('/cadets/$cadetId',
        queryParameters: {'mode': mode});
  }
}

final cadetsRepositoryProvider = Provider<CadetsRepository>(
    (ref) => CadetsRepository(ref.read(apiClientProvider)));

// ── Teachers Repository ───────────────────────────────────────────────────────

class TeachersRepository {
  final ApiClient _client;
  TeachersRepository(this._client);

  Future<List<dynamic>> getTeachers({int? kafedraId}) async {
    final r = await _client.dio.get('/teachers', queryParameters: {
      if (kafedraId != null) 'kafedraId': kafedraId,
    });
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTeacherById(int teacherId) async {
    final r = await _client.dio.get('/teachers/$teacherId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTeacherAnalytics(int teacherId) async {
    final r = await _client.dio.get('/teachers/$teacherId/analytics');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTeacher(
      Map<String, dynamic> data) async {
    final r = await _client.dio.post('/teachers', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTeacher(
      int teacherId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/teachers/$teacherId', data: data);
    return r.data as Map<String, dynamic>;
  }

  /// mode: 'DEACTIVATE' | 'FULL'
  Future<void> deleteTeacher(int teacherId,
      {String mode = 'DEACTIVATE'}) async {
    await _client.dio.delete('/teachers/$teacherId',
        queryParameters: {'mode': mode});
  }
}

final teachersRepositoryProvider = Provider<TeachersRepository>(
    (ref) => TeachersRepository(ref.read(apiClientProvider)));

// ── Faculties Repository ──────────────────────────────────────────────────────

class FacultiesRepository {
  final ApiClient _client;
  FacultiesRepository(this._client);

  Future<List<dynamic>> getFaculties() async {
    final r = await _client.dio.get('/faculties');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getFacultyById(int facultyId) async {
    final r = await _client.dio.get('/faculties/$facultyId');
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getFacultyGroups(int facultyId) async {
    final r = await _client.dio.get('/faculties/$facultyId/groups');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createFaculty(
      Map<String, dynamic> data) async {
    final r = await _client.dio.post('/faculties', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateFaculty(
      int facultyId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/faculties/$facultyId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteFaculty(int facultyId) async {
    await _client.dio.delete('/faculties/$facultyId');
  }
}

final facultiesRepositoryProvider = Provider<FacultiesRepository>(
    (ref) => FacultiesRepository(ref.read(apiClientProvider)));

// ── Kafedras Repository ───────────────────────────────────────────────────────

class KafedrasRepository {
  final ApiClient _client;
  KafedrasRepository(this._client);

  Future<List<dynamic>> getKafedras({int? facultyId}) async {
    final r = await _client.dio.get('/kafedras', queryParameters: {
      if (facultyId != null) 'facultyId': facultyId,
    });
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getKafedraById(int kafedraId) async {
    final r = await _client.dio.get('/kafedras/$kafedraId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createKafedra(
      Map<String, dynamic> data) async {
    final r = await _client.dio.post('/kafedras', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateKafedra(
      int kafedraId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/kafedras/$kafedraId', data: data);
    return r.data as Map<String, dynamic>;
  }

  Future<void> deleteKafedra(int kafedraId) async {
    await _client.dio.delete('/kafedras/$kafedraId');
  }
}

final kafedrasRepositoryProvider = Provider<KafedrasRepository>(
    (ref) => KafedrasRepository(ref.read(apiClientProvider)));

// ── Rates Repository ──────────────────────────────────────────────────────────

class RatesRepository {
  final ApiClient _client;
  RatesRepository(this._client);

  /// Повертає сторінку рейтингу. Параметри: page, size, groupId, semesterId.
  Future<Map<String, dynamic>> getRates({
    int page = 0,
    int size = 20,
    int? groupId,
    int? semesterId,
  }) async {
    final r = await _client.dio.get('/rates', queryParameters: {
      'page': page,
      'size': size,
      if (groupId != null) 'groupIds': groupId,
      if (semesterId != null) 'semesterId': semesterId,
    });
    final raw = r.data;
    if (raw is Map<String, dynamic>) return raw;
    return {'content': raw, 'totalElements': (raw as List).length};
  }

  /// Рейтинг для конкретного курсанта.
  Future<Map<String, dynamic>> getCadetRates(int cadetId) async {
    final r = await _client.dio.get('/rates/cadets/$cadetId');
    final raw = r.data;
    if (raw is Map<String, dynamic>) return raw;
    return Map<String, dynamic>.from(raw as Map);
  }

  /// Запустити перерахунок рейтингу (повертає кількість оновлених записів).
  Future<Map<String, dynamic>> recalculateRates() async {
    final r = await _client.dio.post('/rates/recalculate');
    final raw = r.data;
    if (raw is Map<String, dynamic>) return raw;
    return {'updated': raw};
  }
}

final ratesRepositoryProvider = Provider<RatesRepository>(
    (ref) => RatesRepository(ref.read(apiClientProvider)));

// ── Schedule Repository ───────────────────────────────────────────────────────

Map<String, dynamic> _normalizeScheduleResponse(dynamic raw, String url) {
  print('[Schedule] raw response type: ${raw.runtimeType} from $url');

  if (raw is List) {
    return {'lessons': raw};
  }
  if (raw is Map<String, dynamic>) {
    final lessons = <dynamic>[
      if (raw['lessons'] is List) ...raw['lessons'] as List,
      if (raw['courseLessons'] is List) ...raw['courseLessons'] as List,
      if (raw['scheduleEvents'] is List) ...raw['scheduleEvents'] as List,
      if (raw['events'] is List) ...raw['events'] as List,
      if (raw['courseEvents'] is List) ...raw['courseEvents'] as List,
    ];
    if (lessons.isNotEmpty) {
      return {'lessons': lessons};
    }
    for (final key in ['data', 'content', 'schedules', 'items']) {
      if (raw.containsKey(key) && raw[key] is List) {
        print('[Schedule] found lessons under key "$key"');
        return {'lessons': raw[key]};
      }
    }
    print('[Schedule] no lessons key found, keys: ${raw.keys.toList()}');
    return raw;
  }
  print('[Schedule] unexpected response type from $url');
  return {};
}

class ScheduleRepository {
  final ApiClient _client;
  ScheduleRepository(this._client);

  // Nginx strips the leading /api/ prefix before Spring Boot, so Flutter must include
  // an extra /api/ so that after stripping the correct /api/proxy/schedule/** path remains.
  static const _scheduleBase = '/api/proxy/schedule/api/schedule';

  Future<Map<String, dynamic>> getGroupSchedule({
    required String groupNumber,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final r = await _client.dio.post(
        '$_scheduleBase/group-in-courses',
        data: {'groupNumber': groupNumber, 'startDate': startDate, 'endDate': endDate},
      );
      return _normalizeScheduleResponse(r.data, 'group-in-courses');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('[Schedule] group-in-courses → 400, fallback to /group');
        final r2 = await _client.dio.post(
          '$_scheduleBase/group',
          data: {'groupNumber': groupNumber, 'startDate': startDate, 'endDate': endDate},
        );
        return _normalizeScheduleResponse(r2.data, 'group');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDepartmentSchedule({
    required int departmentNumber,
    required String startDate,
    required String endDate,
  }) async {
    final r = await _client.dio.post(
      '$_scheduleBase/department/with-course-lessons',
      data: {'departmentNumber': departmentNumber, 'startDate': startDate, 'endDate': endDate},
    );
    return _normalizeScheduleResponse(r.data, 'department/with-course-lessons');
  }

  Future<Map<String, dynamic>> getCourseSchedule({
    required int courseNumber,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final r = await _client.dio.post(
        '$_scheduleBase/course/with-events',
        data: {'courseNumber': courseNumber, 'startDate': startDate, 'endDate': endDate},
      );
      return _normalizeScheduleResponse(r.data, 'course/with-events');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('[Schedule] course/with-events → 400, fallback to /course');
        final r2 = await _client.dio.post(
          '$_scheduleBase/course',
          data: {'courseNumber': courseNumber, 'startDate': startDate, 'endDate': endDate},
        );
        return _normalizeScheduleResponse(r2.data, 'course');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFacultySchedule({
    required int facultyNumber,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final r = await _client.dio.post(
        '$_scheduleBase/faculty/with-events',
        data: {'facultyNumber': facultyNumber, 'startDate': startDate, 'endDate': endDate},
      );
      return _normalizeScheduleResponse(r.data, 'faculty/with-events');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        print('[Schedule] faculty/with-events → 400, fallback to /faculty');
        final r2 = await _client.dio.post(
          '$_scheduleBase/faculty',
          data: {'facultyNumber': facultyNumber, 'startDate': startDate, 'endDate': endDate},
        );
        return _normalizeScheduleResponse(r2.data, 'faculty');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLocationSchedule({
    required int locationNumber,
    required String startDate,
    required String endDate,
  }) async {
    final r = await _client.dio.post(
      '$_scheduleBase/location',
      data: {'locationNumber': locationNumber, 'startDate': startDate, 'endDate': endDate},
    );
    return _normalizeScheduleResponse(r.data, 'location');
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
    (ref) => ScheduleRepository(ref.read(apiClientProvider)));
