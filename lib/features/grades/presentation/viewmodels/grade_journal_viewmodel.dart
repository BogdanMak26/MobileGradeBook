// lib/features/grades/presentation/viewmodels/grade_journal_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/local/local_cache.dart';
import '../../../../core/local/offline_queue.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/utils/military_labels.dart';
import '../../data/models/grade_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/repositories/grades_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class JournalState {
  final bool isLoading;
  final String? error;
  final GradeJournalResponse? journal; // grades tab: cadets + lessons + оцінки
  final List<LessonModel> lessons;     // lessons tab: детальний список занять
  final bool isSyncing;
  final String? syncMessage;

  const JournalState({
    this.isLoading = false,
    this.error,
    this.journal,
    this.lessons = const [],
    this.isSyncing = false,
    this.syncMessage,
  });

  JournalState copyWith({
    bool? isLoading,
    String? error,
    GradeJournalResponse? journal,
    List<LessonModel>? lessons,
    bool? isSyncing,
    String? syncMessage,
  }) =>
      JournalState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        journal: journal ?? this.journal,
        lessons: lessons ?? this.lessons,
        isSyncing: isSyncing ?? this.isSyncing,
        syncMessage: syncMessage,
      );
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class GradeJournalViewModel extends StateNotifier<JournalState> {
  final GradesRepository _repo;
  final AttendsRepository _attendsRepo;
  final LocalCache _cache;
  final NetworkMonitor _network;
  final OfflineQueueNotifier _queue;

  // Runtime cache for markIds created during this session (cadetId → lessonId → markId)
  final Map<int, Map<int, int>> _markIds = {};
  // Runtime cache for attendIds created during this session (cadetId → lessonId → attendId)
  final Map<int, Map<int, int>> _attendIds = {};

  GradeJournalViewModel(this._repo, this._attendsRepo, this._cache, this._network, this._queue)
      : super(const JournalState());

  // ── Журнал оцінок ─────────────────────────────────────────────────────────

  Future<void> loadJournal({
    required int groupId,
    required int disciplineId,
    required int semesterId,
  }) async {
    state = const JournalState(isLoading: true);

    if (!_network.isOnline) {
      state = const JournalState();
      return;
    }

    try {
      final raw = await _repo.getJournal(
        groupId: groupId,
        disciplineId: disciplineId,
        semesterId: semesterId,
      );
      final journal = await _mergeMarkData(raw);
      state = state.copyWith(isLoading: false, journal: journal);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Журнал за journalId (GET /journals/{id}) ─────────────────────────────

  Future<void> loadJournalById(int journalId) async {
    state = const JournalState(isLoading: true);
    if (!_network.isOnline) {
      state = const JournalState();
      return;
    }
    try {
      final raw = await _repo.getJournalById(journalId);
      final journal = await _mergeMarkData(raw);
      state = state.copyWith(isLoading: false, journal: journal);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Завантаження marks з детального списку занять ────────────────────────
  // Оновлює _markIds і повертає журнал з заповненим gradesByLessonId
  Future<GradeJournalResponse> _mergeMarkData(GradeJournalResponse journal) async {
    try {
      final data = await _repo.getLessonMarkData(journal.journalId);

      for (final cadetEntry in data.entries) {
        (_markIds[cadetEntry.key] ??= {})
            .addAll(cadetEntry.value.map((k, v) => MapEntry(k, v.$1)));
      }

      final updatedCadets = journal.cadets.map((cadet) {
        final cadetData = data[cadet.id];
        if (cadetData == null) return cadet;
        final grades = Map<int, double?>.from(cadet.gradesByLessonId);
        cadetData.forEach((lessonId, rec) => grades[lessonId] = rec.$2);
        return JournalCadet(
          id: cadet.id,
          fullName: cadet.fullName,
          gradesByLessonId: grades,
          statusByLessonId: cadet.statusByLessonId,
          markIdByLessonId: cadet.markIdByLessonId,
          attendIdByLessonId: cadet.attendIdByLessonId,
        );
      }).toList();

      return GradeJournalResponse(
        journalId: journal.journalId,
        cadets: updatedCadets,
        lessons: journal.lessons,
      );
    } catch (_) {
      return journal;
    }
  }

  // ── Заняття (cache-first) ─────────────────────────────────────────────────

  Future<void> loadLessons(int journalId) async {
    state = state.copyWith(isLoading: true, error: null);

    final cachedRaw = _cache.get<List<dynamic>>('lessons_$journalId');
    if (cachedRaw != null) {
      final cached = cachedRaw
          .map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(lessons: cached);
    }

    if (!_network.isOnline) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final lessons = await _repo.getLessons(journalId);
      await _cache.set(
          'lessons_$journalId', lessons.map((l) => l.toJson()).toList());
      state = state.copyWith(isLoading: false, lessons: lessons);
    } catch (e) {
      if (cachedRaw == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // ── Заняття CRUD (тільки онлайн — структурні зміни) ──────────────────────

  Future<void> createLesson({
    required int journalId,
    required Map<String, dynamic> data,
  }) async {
    if (!_network.isOnline) {
      state = state.copyWith(error: "Немає з'єднання. Спробуйте при підключенні.");
      return;
    }
    try {
      final lesson = await _repo.createLesson(journalId: journalId, data: data);
      state = state.copyWith(
        lessons: [...state.lessons, lesson],
        syncMessage: '✓ Заняття створено',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateLesson({
    required int lessonId,
    required Map<String, dynamic> data,
  }) async {
    if (!_network.isOnline) {
      state = state.copyWith(error: "Немає з'єднання. Спробуйте при підключенні.");
      return;
    }
    try {
      final updated = await _repo.updateLesson(lessonId: lessonId, data: data);
      state = state.copyWith(
        lessons: state.lessons.map((l) => l.id == lessonId ? updated : l).toList(),
        syncMessage: '✓ Заняття оновлено',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteLesson(int lessonId) async {
    if (!_network.isOnline) {
      state = state.copyWith(error: "Немає з'єднання. Спробуйте при підключенні.");
      return;
    }
    try {
      await _repo.deleteLesson(lessonId);
      state = state.copyWith(
        lessons: state.lessons.where((l) => l.id != lessonId).toList(),
        syncMessage: '✓ Заняття видалено',
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Збереження оцінки (create / update / delete) ─────────────────────────

  Future<void> saveGrade({
    required String cadetName,
    required int lessonIdx,
    required double? value,
    required int teacherId,
  }) async {
    final journal = state.journal;
    if (journal == null || lessonIdx >= journal.lessons.length) return;

    final lesson = journal.lessons[lessonIdx];
    final lessonId = lesson.id;
    final subLessonId = lesson.subLessonId;

    JournalCadet cadet;
    try {
      cadet = journal.cadets.firstWhere((c) => c.fullName == cadetName);
    } catch (_) {
      return;
    }
    final cadetId = cadet.id;

    final existingMarkId = _markIds[cadetId]?[lessonId]
        ?? cadet.markIdByLessonId[lessonId];

    try {
      if (value == null) {
        if (existingMarkId == null) return;
        if (!_network.isOnline) {
          await _queue.enqueue(PendingOp(
            id: 'mark_del_${cadetId}_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
            method: 'DELETE',
            path: '/marks/$existingMarkId',
            data: {},
            createdAt: DateTime.now(),
          ));
          (_markIds[cadetId] ??= {}).remove(lessonId);
          return;
        }
        await _repo.deleteMark(existingMarkId);
        (_markIds[cadetId] ??= {}).remove(lessonId);
      } else if (existingMarkId != null) {
        if (!_network.isOnline) {
          await _queue.enqueue(PendingOp(
            id: 'mark_upd_${cadetId}_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
            method: 'PATCH',
            path: '/marks/$existingMarkId',
            data: {'markValue': value},
            createdAt: DateTime.now(),
          ));
          return;
        }
        await _repo.updateMark(existingMarkId, value);
      } else {
        if (subLessonId == null) {
          state = state.copyWith(error: 'Немає підзаняття для заняття $lessonId');
          return;
        }
        if (!_network.isOnline) {
          await _queue.enqueue(PendingOp(
            id: 'mark_new_${cadetId}_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
            method: 'POST',
            path: '/marks',
            data: {
              'cadetId': cadetId,
              'subLessonId': subLessonId,
              'teacherId': teacherId,
              'value': value,
              'type': 'PRACTICAL',
            },
            createdAt: DateTime.now(),
          ));
          return;
        }
        final result = await _repo.createMark(
          cadetId: cadetId,
          subLessonId: subLessonId,
          teacherId: teacherId,
          value: value,
        );
        final newMarkId = result['id'] as int? ?? result['markId'] as int?;
        if (newMarkId != null) {
          (_markIds[cadetId] ??= {})[lessonId] = newMarkId;
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Збереження відвідуваності (create / update / delete) ──────────────────
  Future<void> saveAttendances({
    required Map<String, List<String?>> attendance,
    required int teacherId,
  }) async {
    final journal = state.journal;
    if (journal == null) return;

    final toCreate = <Map<String, dynamic>>[];          // POST /attends/batch
    final toUpdate = <Map<String, dynamic>>[];          // PATCH /attends/{id}
    final toDelete = <int>[];                           // DELETE /attends/{id}

    for (final cadet in journal.cadets) {
      final cadetAtt = attendance[cadet.fullName];
      if (cadetAtt == null) continue;

      for (int i = 0; i < journal.lessons.length && i < cadetAtt.length; i++) {
        final lessonId = journal.lessons[i].id;
        final currentCode = cadetAtt[i];

        // 'П' (present) treated same as null — means "no attendance record"
        final currentEnum = MilitaryLabels.attendEnum(currentCode);
        final originalCode = cadet.statusByLessonId[lessonId];

        // Skip if nothing changed
        if (currentCode == originalCode) continue;
        if (currentEnum == null && originalCode == null) continue;

        final attendId = _attendIds[cadet.id]?[lessonId]
            ?? cadet.attendIdByLessonId[lessonId];

        if (currentEnum == null && attendId != null) {
          // Record existed, user cleared it → DELETE
          toDelete.add(attendId);
        } else if (currentEnum != null && attendId == null) {
          // New record → CREATE
          toCreate.add({
            'cadetId': cadet.id,
            'lessonId': lessonId,
            'teacherId': teacherId,
            'attended': currentEnum,
          });
        } else if (currentEnum != null && attendId != null) {
          // Record existed, user changed value → UPDATE
          final originalEnum = MilitaryLabels.attendEnum(originalCode);
          if (currentEnum != originalEnum) {
            toUpdate.add({'attendId': attendId, 'attended': currentEnum});
          }
        }
      }
    }

    final total = toCreate.length + toUpdate.length + toDelete.length;
    if (total == 0) {
      state = state.copyWith(isSyncing: false, syncMessage: '✓ Без змін');
      return;
    }

    if (!_network.isOnline) {
      for (final rec in toCreate) {
        await _queue.enqueue(PendingOp(
          id: 'att_new_${rec['cadetId']}_${rec['lessonId']}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'POST', path: '/attends', data: rec, createdAt: DateTime.now(),
        ));
      }
      for (final rec in toUpdate) {
        await _queue.enqueue(PendingOp(
          id: 'att_upd_${rec['attendId']}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'PATCH', path: '/attends/${rec['attendId']}',
          data: {'attended': rec['attended']}, createdAt: DateTime.now(),
        ));
      }
      for (final aId in toDelete) {
        await _queue.enqueue(PendingOp(
          id: 'att_del_${aId}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'DELETE', path: '/attends/$aId', data: {}, createdAt: DateTime.now(),
        ));
      }
      state = state.copyWith(
        isSyncing: false,
        syncMessage: '📥 Збережено офлайн ($total записів)',
      );
      return;
    }

    state = state.copyWith(isSyncing: true, syncMessage: null);
    try {
      for (final rec in toCreate) {
        final created = await _attendsRepo.createAttend(rec);
        final aId = created['id'] as int? ?? created['attendId'] as int?;
        final cId = rec['cadetId'] as int?;
        final lId = rec['lessonId'] as int?;
        if (aId != null && cId != null && lId != null) {
          (_attendIds[cId] ??= {})[lId] = aId;
        }
      }
      for (final rec in toUpdate) {
        await _attendsRepo.updateAttend(
          rec['attendId'] as int,
          {'attended': rec['attended']},
        );
      }
      for (final aId in toDelete) {
        await _attendsRepo.deleteAttend(aId);
        // Remove from session cache
        for (final lessonMap in _attendIds.values) {
          lessonMap.removeWhere((_, v) => v == aId);
        }
      }
      state = state.copyWith(isSyncing: false, syncMessage: '✓ Відвідуваність збережено ($total)');
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final gradeJournalViewModelProvider =
    StateNotifierProvider<GradeJournalViewModel, JournalState>((ref) {
  return GradeJournalViewModel(
    ref.read(gradesRepositoryProvider),
    ref.read(attendsRepositoryProvider),
    ref.read(localCacheProvider),
    ref.read(networkMonitorProvider),
    ref.read(offlineQueueProvider.notifier),
  );
});
