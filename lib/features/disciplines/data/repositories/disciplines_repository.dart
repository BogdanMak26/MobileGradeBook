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

  // ── Журнали дисципліни ───────────────────────────────────────────────────
  Future<List<JournalModel>> getDisciplineJournals(int disciplineId) async {
    final response = await _client.dio.get('/journals/discipline/$disciplineId');
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
}

final disciplinesRepositoryProvider = Provider<DisciplinesRepository>((ref) {
  return DisciplinesRepository(ref.read(apiClientProvider));
});
