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

  // ── Журнал за ID (GET /journals/{journalId}) ─────────────────────────────
  Future<GradeJournalResponse> getJournalById(int journalId) async {
    final response = await _client.dio.get('/journals/$journalId');
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

  // ── Список журналів дисципліни ────────────────────────────────────────────
  // GET /journals?discipline_id={id}  (server uses snake_case params)
  Future<List<dynamic>> getDisciplineJournals(int disciplineId) async {
    final response = await _client.dio.get(
      '/journals',
      queryParameters: {'discipline_id': disciplineId},
    );
    return response.data as List<dynamic>;
  }

  // ── Деталі оцінок з детального списку занять ─────────────────────────────
  // Returns: cadetId → lessonId → (markId, value)
  Future<Map<int, Map<int, (int, double)>>> getLessonMarkData(int journalId) async {
    final response = await _client.dio.get('/lessons/journal/$journalId');
    final list = response.data as List<dynamic>;
    final result = <int, Map<int, (int, double)>>{};
    for (final l in list) {
      final lMap = l as Map<String, dynamic>;
      final lessonId = lMap['id'] as int?;
      if (lessonId == null) continue;
      final cadetAccum = <int, (int, double)>{};
      for (final sl in (lMap['subLessons'] as List<dynamic>? ?? [])) {
        final slMap = sl as Map<String, dynamic>;
        for (final m in (slMap['marks'] as List<dynamic>? ?? [])) {
          final mMap = m as Map<String, dynamic>;
          final cadetId = mMap['cadetId'] as int?;
          final markId = mMap['id'] as int?;
          final value = (mMap['value'] as num?)?.toDouble();
          if (cadetId != null && markId != null && value != null) {
            final prev = cadetAccum[cadetId];
            cadetAccum[cadetId] = prev == null
                ? (markId, value)
                : (prev.$1, prev.$2 + value); // sum subLessons, keep first markId
          }
        }
      }
      for (final e in cadetAccum.entries) {
        (result[e.key] ??= {})[lessonId] = e.value;
      }
    }
    return result;
  }

  // ── CRUD занять ───────────────────────────────────────────────────────────

  Future<LessonModel> createLesson({
    required int journalId,
    required Map<String, dynamic> data,
  }) async {
    // POST /lessons (not /journals/{id}/lessons)
    final response = await _client.dio.post(
      '/lessons',
      data: {'journalId': journalId, ...data},
    );
    return LessonModel.fromJson(response.data as Map<String, dynamic>);
  }

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

  // ── Оцінки (POST /marks, PATCH /marks/{id}) ───────────────────────────────

  // Creates a new mark. Returns the created mark ID.
  Future<Map<String, dynamic>> createMark({
    required int cadetId,
    required int subLessonId,
    required int teacherId,
    required double value,
    String type = 'PRACTICAL',
  }) async {
    final response = await _client.dio.post('/marks', data: {
      'cadetId': cadetId,
      'subLessonId': subLessonId,
      'teacherId': teacherId,
      'value': value,
      'type': type,
    });
    return response.data as Map<String, dynamic>;
  }

  // Updates an existing mark by markId.
  Future<void> updateMark(int markId, double value) async {
    await _client.dio.patch('/marks/$markId', data: {'markValue': value});
  }

  Future<void> deleteMark(int markId) async {
    await _client.dio.delete('/marks/$markId');
  }

  // ── Відвідуваність (POST /attends, PATCH /attends/{id}) ──────────────────

  Future<Map<String, dynamic>> createAttend({
    required int cadetId,
    required int lessonId,
    required int teacherId,
    required String attended,
  }) async {
    final response = await _client.dio.post('/attends', data: {
      'cadetId': cadetId,
      'lessonId': lessonId,
      'teacherId': teacherId,
      'attended': attended,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateAttend(int attendId, String attended) async {
    await _client.dio.patch('/attends/$attendId', data: {'attended': attended});
  }

  Future<void> deleteAttend(int attendId) async {
    await _client.dio.delete('/attends/$attendId');
  }
}

final gradesRepositoryProvider = Provider<GradesRepository>(
    (ref) => GradesRepository(ref.read(apiClientProvider)));
