// lib/features/grades/data/repositories/grades_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/grade_model.dart';
import '../models/lesson_model.dart';

class GradesRepository {
  final ApiClient _client;
  GradesRepository(this._client);

  // ── Журнал оцінок (курсанти + заняття + оцінки) ──────────────────────────
  // GET /journals/groups/{groupId}/disciplines/{disciplineId}/semesters/{semesterId}
  Future<GradeJournalResponse> getJournal({
    required int groupId,
    required int disciplineId,
    required int semesterId,
  }) async {
    final response = await _client.dio.get(
      '/journals/groups/$groupId/disciplines/$disciplineId/semesters/$semesterId',
    );
    return GradeJournalResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Заняття журналу (GET /lessons/journal/{journalId}) ────────────────────
  Future<List<LessonModel>> getLessons(int journalId) async {
    final response = await _client.dio.get('/lessons/journal/$journalId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LessonModel> createLesson({
    required int journalId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.dio.post(
      '/journals/$journalId/lessons',
      data: data,
    );
    return LessonModel.fromJson(response.data as Map<String, dynamic>);
  }

  // PATCH /lessons/{lessonId} (не PUT)
  Future<LessonModel> updateLesson({
    required int lessonId,
    required Map<String, dynamic> data,
  }) async {
    final response = await _client.dio.patch('/lessons/$lessonId', data: data);
    return LessonModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLesson(int lessonId) async {
    await _client.dio.delete('/lessons/$lessonId');
  }

  // ── Підзаняття (стовпці оцінювання всередині заняття) ────────────────────

  Future<List<dynamic>> getSublessons(int lessonId) async {
    final response = await _client.dio.get('/lessons/$lessonId/sublessons');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSublesson(
      int lessonId, Map<String, dynamic> data) async {
    final response =
        await _client.dio.post('/lessons/$lessonId/sublessons', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ── Оцінка (одиночна) ────────────────────────────────────────────────────

  Future<GradeModel> putGrade({
    required int lessonId,
    required int cadetId,
    double? score,
    String? status, // 'Н' — відсутній, 'ІЗ' — індивідуальне завдання
  }) async {
    final response = await _client.dio.put(
      '/lessons/$lessonId/grades/$cadetId',
      data: {
        'score': score,
        if (status != null) 'status': status,
      },
    );
    return GradeModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Масове виставлення оцінок (весь рядок журналу) ───────────────────────

  Future<List<GradeModel>> batchGrades(
      List<Map<String, dynamic>> grades) async {
    final response = await _client.dio.post('/grades/batch', data: grades);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => GradeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final gradesRepositoryProvider = Provider<GradesRepository>(
    (ref) => GradesRepository(ref.read(apiClientProvider)));
