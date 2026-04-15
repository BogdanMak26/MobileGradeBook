// lib/core/network/sync_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../database/app_database.dart';
import '../utils/app_constants.dart';

class SyncResult {
  final int synced;
  final int failed;
  const SyncResult({required this.synced, required this.failed});
}

class SyncService {
  final AppDatabase _db;
  final ApiClient _apiClient;

  SyncService(this._db, this._apiClient);

  // ── Push pending local changes to server ────────────────────────────────────

  Future<SyncResult> syncPendingChanges() async {
    final pending = await _db.getPendingSyncItems();
    if (pending.isEmpty) return const SyncResult(synced: 0, failed: 0);

    int synced = 0;
    int failed = 0;

    for (final item in pending) {
      if (item.retryCount >= AppConstants.maxRetryAttempts) {
        failed++;
        continue;
      }
      try {
        await _syncItem(item);
        await _db.markSyncItemDone(item.id);
        synced++;
      } catch (e) {
        await _db.incrementRetry(item.id, e.toString());
        failed++;
      }
    }
    return SyncResult(synced: synced, failed: failed);
  }

  Future<void> _syncItem(SyncLogData item) async {
    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    switch (item.entityType) {
      case 'grade':
        await _syncGrade(item.entityId, payload);
        break;
      case 'lesson':
        await _syncLesson(item.entityId, payload);
        break;
    }
  }

  Future<void> _syncGrade(String gradeId, Map<String, dynamic> clientPayload) async {
    final clientVersion = clientPayload['client_version'] as int? ?? 0;
    final clientUpdatedAt = DateTime.tryParse(
            clientPayload['updated_at'] as String? ?? '') ??
        DateTime.now();

    try {
      final response = await _apiClient.dio.put(
        '/grades/$gradeId',
        data: {
          ...clientPayload,
          'client_version': clientVersion,
          'updated_at': clientUpdatedAt.toIso8601String(),
        },
      );
      final resolved = response.data as Map<String, dynamic>;
      await _db.upsertGrade(GradesCompanion(
        id: Value(gradeId),
        serverVersion: Value(resolved['version'] as int? ?? clientVersion + 1),
        isSynced: const Value(true),
        score: Value(resolved['score'] as int?),
        gradeValue: Value(resolved['grade_value'] as String?),
        status: Value(resolved['status'] as String?),
        updatedAt: Value(DateTime.now()),
      ));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        await _resolveGradeConflict(gradeId, clientPayload, e.response!.data);
      } else {
        rethrow;
      }
    }
  }

  /// Алгоритм вирішення конфліктів згідно тези:
  /// - client_version >= server_version → клієнт перемагає
  /// - client_version < server_version → числові за newer updated_at, текстові merge
  Future<void> _resolveGradeConflict(
    String gradeId,
    Map<String, dynamic> clientData,
    dynamic serverData,
  ) async {
    final serverMap = serverData as Map<String, dynamic>;
    final clientVersion = clientData['client_version'] as int? ?? 0;
    final serverVersion = serverMap['version'] as int? ?? 0;

    Map<String, dynamic> resolved;

    if (clientVersion >= serverVersion) {
      resolved = clientData;
    } else {
      final clientUpdated =
          DateTime.tryParse(clientData['updated_at'] ?? '') ?? DateTime(0);
      final serverUpdated =
          DateTime.tryParse(serverMap['updated_at'] ?? '') ?? DateTime(0);

      if (clientUpdated.isAfter(serverUpdated)) {
        // Числові поля (score) — newer wins
        resolved = {
          ...serverMap,
          'score': clientData['score'],
          'grade_value': clientData['grade_value'],
          'updated_at': clientData['updated_at'],
        };
      } else {
        // Текстові поля — field-level merge
        resolved = {
          ...serverMap,
          'note': (serverMap['note'] as String?)?.isNotEmpty == true
              ? serverMap['note']
              : clientData['note'],
        };
      }
    }

    await _apiClient.dio.put('/grades/$gradeId/resolve', data: resolved);
    await _db.upsertGrade(GradesCompanion(
      id: Value(gradeId),
      score: Value(resolved['score'] as int?),
      gradeValue: Value(resolved['grade_value'] as String?),
      serverVersion: Value(serverVersion + 1),
      isSynced: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> _syncLesson(String lessonId, Map<String, dynamic> payload) async {
    await _apiClient.dio.put('/lessons/$lessonId', data: payload);
  }

  // ── Pull from server ────────────────────────────────────────────────────────

  Future<void> pullFromServer() async {
    await Future.wait([
      _pullDisciplines(),
      _pullCadets(),
    ]);
  }

  Future<void> _pullDisciplines() async {
    try {
      final response = await _apiClient.dio.get('/disciplines');
      final list = response.data as List;
      for (final item in list) {
        final d = item as Map<String, dynamic>;
        await _db.upsertDiscipline(DisciplinesCompanion(
          id: Value(d['id'].toString()),
          name: Value(d['name']?.toString() ?? ''),
          code: Value(d['code']?.toString()),
          instructorId: Value(d['instructorId']?.toString()),
          semester: Value(d['semester'] as int?),
          year: Value(d['year'] as int?),
          serverVersion: Value(d['version'] as int? ?? 0),
          updatedAt: Value(
              DateTime.tryParse(d['updatedAt']?.toString() ?? '') ??
                  DateTime.now()),
          isSynced: const Value(true),
        ));
      }
    } catch (_) {
      // Офлайн — продовжуємо з локальними даними
    }
  }

  Future<void> _pullCadets() async {
    try {
      final response = await _apiClient.dio.get('/users/cadets');
      final list = response.data as List;
      for (final item in list) {
        final c = item as Map<String, dynamic>;
        await _db.upsertCadet(CadetsCompanion(
          id: Value(c['id'].toString()),
          firstName: Value(c['firstName']?.toString() ?? ''),
          lastName: Value(c['lastName']?.toString() ?? ''),
          middleName: Value(c['middleName']?.toString()),
          email: Value(c['email']?.toString() ?? ''),
          groupId: Value(c['groupId']?.toString()),
          photoUrl: Value(c['photoUrl']?.toString()),
          updatedAt: Value(DateTime.now()),
        ));
      }
    } catch (_) {}
  }
}

// ─── Provider (ручний) ────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(appDatabaseProvider),
    ref.read(apiClientProvider),
  );
});
