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

  // ── Дисципліни групи (для курсанта) ──────────────────────────────────────
  Future<List<DisciplineModel>> getGroupDisciplines(int groupId) async {
    final response = await _client.dio.get('/groups/$groupId/disciplines');
    final list = response.data as List<dynamic>;
    return list.map((e) => DisciplineModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Журнали дисципліни (GET /journals?disciplineId={id}) ─────────────────
  Future<List<JournalModel>> getDisciplineJournals(int disciplineId) async {
    final response = await _client.dio.get(
      '/journals',
      queryParameters: {'disciplineId': disciplineId},
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => JournalModel.fromJson(e as Map<String, dynamic>)).toList();
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
