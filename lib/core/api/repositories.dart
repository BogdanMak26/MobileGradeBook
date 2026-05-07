// lib/core/api/repositories.dart
// Спільні репозиторії: користувачі, групи, семестри, журнали (CRUD), відвідуваність, курсанти, викладачі.
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

  Future<List<dynamic>> getUsers() async {
    final r = await _client.dio.get('/users');
    return r.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    final r = await _client.dio.get('/users/$userId');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUser(
      int userId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/users/$userId', data: data);
    return r.data as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> getCurrentSemester() async {
    final r = await _client.dio.get('/semesters/current');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSemesterById(int semesterId) async {
    final r = await _client.dio.get('/semesters/$semesterId');
    return r.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSemestersByGroup(int groupId) async {
    final r = await _client.dio.get('/semesters/groups/$groupId');
    return r.data as List<dynamic>;
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
}

final cadetsRepositoryProvider = Provider<CadetsRepository>(
    (ref) => CadetsRepository(ref.read(apiClientProvider)));

// ── Teachers Repository ───────────────────────────────────────────────────────

class TeachersRepository {
  final ApiClient _client;
  TeachersRepository(this._client);

  Future<List<dynamic>> getTeachers() async {
    final r = await _client.dio.get('/teachers');
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

  Future<Map<String, dynamic>> updateTeacher(
      int teacherId, Map<String, dynamic> data) async {
    final r = await _client.dio.patch('/teachers/$teacherId', data: data);
    return r.data as Map<String, dynamic>;
  }
}

final teachersRepositoryProvider = Provider<TeachersRepository>(
    (ref) => TeachersRepository(ref.read(apiClientProvider)));
