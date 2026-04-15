// lib/features/grades/presentation/viewmodels/grade_journal_viewmodel.dart

import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/network/sync_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class JournalState {
  final bool isLoading;
  final String? error;
  final List<Grade> grades;
  final bool isSyncing;
  final String? syncMessage;

  const JournalState({
    this.isLoading = false,
    this.error,
    this.grades = const [],
    this.isSyncing = false,
    this.syncMessage,
  });

  JournalState copyWith({
    bool? isLoading,
    String? error,
    List<Grade>? grades,
    bool? isSyncing,
    String? syncMessage,
  }) =>
      JournalState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        grades: grades ?? this.grades,
        isSyncing: isSyncing ?? this.isSyncing,
        syncMessage: syncMessage,
      );
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class GradeJournalViewModel extends StateNotifier<JournalState> {
  final AppDatabase _db;
  final SyncService _syncService;
  final NetworkMonitor _monitor;

  GradeJournalViewModel(this._db, this._syncService, this._monitor)
      : super(const JournalState());

  Future<void> loadGradesForLesson(String lessonId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final grades = await _db.getGradesForLesson(lessonId);
      state = state.copyWith(isLoading: false, grades: grades);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Offline-First: зберігаємо локально → sync_log → sync якщо онлайн
  Future<void> setGrade({
    required String lessonId,
    required String cadetId,
    int? score,
    String? status,
    String? note,
  }) async {
    final existing = state.grades
        .where((g) => g.lessonId == lessonId && g.cadetId == cadetId)
        .firstOrNull;

    final gradeId = existing?.id ?? const Uuid().v4();
    final now = DateTime.now();
    final newClientVersion = (existing?.clientVersion ?? 0) + 1;

    await _db.upsertGrade(GradesCompanion(
      id: Value(gradeId),
      lessonId: Value(lessonId),
      cadetId: Value(cadetId),
      score: Value(score),
      status: Value(status),
      note: Value(note),
      clientVersion: Value(newClientVersion),
      serverVersion: Value(existing?.serverVersion ?? 0),
      updatedAt: Value(now),
      isSynced: const Value(false),
    ));

    final payload = jsonEncode({
      'id': gradeId,
      'lesson_id': lessonId,
      'cadet_id': cadetId,
      'score': score,
      'status': status,
      'note': note,
      'client_version': newClientVersion,
      'updated_at': now.toIso8601String(),
    });

    await _db.markGradeForSync(gradeId, payload);
    await loadGradesForLesson(lessonId);

    if (_monitor.isOnline) {
      await _triggerSync();
    } else {
      state = state.copyWith(
          syncMessage: 'Збережено офлайн. Синхронізується при підключенні.');
    }
  }

  Future<void> _triggerSync() async {
    state = state.copyWith(isSyncing: true);
    try {
      final result = await _syncService.syncPendingChanges();
      state = state.copyWith(
        isSyncing: false,
        syncMessage: result.synced > 0 ? '✓ Синхронізовано' : null,
      );
    } catch (_) {
      state = state.copyWith(isSyncing: false);
    }
  }

  Future<void> manualSync() => _triggerSync();
}

// ─── Provider (ручний) ────────────────────────────────────────────────────────

final gradeJournalViewModelProvider =
    StateNotifierProvider<GradeJournalViewModel, JournalState>((ref) {
  return GradeJournalViewModel(
    ref.read(appDatabaseProvider),
    ref.read(syncServiceProvider),
    ref.read(networkMonitorProvider),
  );
});
