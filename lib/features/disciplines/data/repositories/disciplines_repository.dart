// lib/features/disciplines/data/repositories/disciplines_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../models/discipline_model.dart';
import '../models/journal_model.dart';

class DisciplinesRepository {
  final ApiClient _client;
  DisciplinesRepository(this._client);

  // ── Мої дисципліни (для викладача) ──────────────────────────────────────
  Future<List<DisciplineModel>> getMyDisciplines() async {
    final response = await _client.dio.get('/disciplines/my');
    final list = response.data as List<dynamic>;
    return list.map((e) => DisciplineModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Дисципліни курсанта (з rates endpoint) ──────────────────────────────
  Future<List<DisciplineModel>> getCadetDisciplines(int cadetId) async {
    final response = await _client.dio.get('/rates/cadets/$cadetId');
    final data = response.data;
    final map = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
    final disciplines = map['disciplines'] as List<dynamic>? ?? [];
    return disciplines.map((e) {
      final m = e as Map<String, dynamic>;
      final semIds = m['semesterIds'] as List<dynamic>?;
      return DisciplineModel(
        id: m['disciplineId'] as int,
        fullName: m['disciplineFullName'] as String? ?? '',
        shortName: m['disciplineShortName'] as String?,
        journalId: m['journalId'] as int?,
        groupId: m['groupId'] as int?,
        semesterId: semIds?.isNotEmpty == true ? semIds!.first as int? : null,
        journalCount: m['journalId'] != null ? 1 : 0,
      );
    }).toList();
  }

  // ── Журнали дисципліни (GET /journals?discipline_id={id}) ───────────────
  Future<List<JournalModel>> getDisciplineJournals(int disciplineId) async {
    final response = await _client.dio.get(
      '/journals',
      queryParameters: {'discipline_id': disciplineId},
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => JournalModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Журнали групи (GET /journals?group_id={id}) ──────────────────────────
  Future<List<JournalModel>> getGroupJournals(int groupId) async {
    final response = await _client.dio.get(
      '/journals',
      queryParameters: {'group_id': groupId},
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => JournalModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Всі дисципліни — сирий JSON (зберігає масив teachers) ──────────────
  Future<List<Map<String, dynamic>>> getAllDisciplinesRaw({int? kafedraId}) async {
    final response = await _client.dio.get(
      '/disciplines',
      queryParameters: kafedraId != null ? {'kafedraId': kafedraId} : null,
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ── Всі дисципліни (для адміна/нач.кафедри) ─────────────────────────────
  Future<List<DisciplineModel>> getAllDisciplines({int? kafedraId}) async {
    final response = await _client.dio.get(
      '/disciplines',
      queryParameters: kafedraId != null ? {'kafedraId': kafedraId} : null,
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => DisciplineModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── CRUD дисциплін (адмін) ───────────────────────────────────────────────

  Future<DisciplineModel> createDiscipline(Map<String, dynamic> data) async {
    final response = await _client.dio.post('/disciplines', data: data);
    return DisciplineModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DisciplineModel> updateDiscipline(
      int disciplineId, Map<String, dynamic> data) async {
    final response =
        await _client.dio.patch('/disciplines/$disciplineId', data: data);
    return DisciplineModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDiscipline(int disciplineId) async {
    await _client.dio.delete('/disciplines/$disciplineId');
  }

  // ── Викладачі дисципліни ─────────────────────────────────────────────────

  Future<void> addTeacher(int disciplineId, int teacherId) async {
    await _client.dio.post(
      '/disciplines/$disciplineId/teachers/$teacherId',
    );
  }

  Future<void> removeTeacher(int disciplineId, int teacherId) async {
    await _client.dio.delete(
      '/disciplines/$disciplineId/teachers/$teacherId',
    );
  }
}

final disciplinesRepositoryProvider = Provider<DisciplinesRepository>((ref) {
  return DisciplinesRepository(ref.read(apiClientProvider));
});
