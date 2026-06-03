// lib/features/grades/presentation/viewmodels/grade_journal_viewmodel.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/local/local_cache.dart';
import '../../../../core/local/offline_queue.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/background/background_tasks.dart';
import '../../../../core/notifications/notification_preferences.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/military_labels.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/grade_model.dart';
import '../../data/models/lesson_model.dart';
import '../../data/repositories/grades_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class JournalState {
  final bool isLoading;
  final String? error;
  final GradeJournalResponse? journal;
  final List<LessonModel> lessons;
  final bool isSyncing;
  final String? syncMessage;
  final String? offlineMessage; // сервер впав — дані в черзі

  const JournalState({
    this.isLoading = false,
    this.error,
    this.journal,
    this.lessons = const [],
    this.isSyncing = false,
    this.syncMessage,
    this.offlineMessage,
  });

  JournalState copyWith({
    bool? isLoading,
    String? error,
    GradeJournalResponse? journal,
    List<LessonModel>? lessons,
    bool? isSyncing,
    String? syncMessage,
    String? offlineMessage,
  }) =>
      JournalState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        journal: journal ?? this.journal,
        lessons: lessons ?? this.lessons,
        isSyncing: isSyncing ?? this.isSyncing,
        syncMessage: syncMessage,
        offlineMessage: offlineMessage,
      );
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class GradeJournalViewModel extends StateNotifier<JournalState> {
  final GradesRepository _repo;
  final AttendsRepository _attendsRepo;
  final LocalCache _cache;
  final NetworkMonitor _network;
  final OfflineQueueNotifier _queue;
  final NotificationService _notifService;
  final String _role;

  // Runtime cache for markIds created during this session (cadetId → lessonId → markId)
  final Map<int, Map<int, int>> _markIds = {};
  // Runtime cache for attendIds created during this session (cadetId → lessonId → attendId)
  final Map<int, Map<int, int>> _attendIds = {};

  String _disciplineName = '';

  void setDisciplineName(String name) => _disciplineName = name;

  GradeJournalViewModel(this._repo, this._attendsRepo, this._cache, this._network, this._queue, this._notifService, this._role)
      : super(const JournalState());

  Future<void> _checkUnfilledJournals(GradeJournalResponse journal) async {
    if (!await isNotifEnabled(NotifKey.unfilledJournals, role: _role)) return;
    final now = DateTime.now();
    final hasUnfilled = journal.lessons.any((l) {
      final d = DateTime.tryParse(l.date);
      if (d == null || !d.isBefore(DateTime(now.year, now.month, now.day))) return false;
      return journal.cadets.every((c) => c.gradesByLessonId[l.id] == null);
    });
    if (!hasUnfilled) return;
    final prefs = await SharedPreferences.getInstance();
    // Встановлюємо флаг для фонової задачі
    await prefs.setBool(kUnfilledJournalsFlag, true);
    final dedupKey = 'notif_unfilled_${journal.journalId}_${now.year}${now.month}${now.day}';
    if (prefs.getBool(dedupKey) == true) return;
    await prefs.setBool(dedupKey, true);
    await _notifService.show(
      id: journal.journalId % 65535,
      title: 'Незаповнений журнал',
      body: 'Є заняття в минулому без виставлених оцінок',
    );
  }

  // Сервер недоступний (timeout / connection error / 5xx) — треба класти в чергу
  bool _isServerDown(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) return true;
      final status = e.response?.statusCode ?? 0;
      if (status >= 500) return true;
    }
    return false;
  }

  Future<void> _enqueueServerDown(PendingOp op) async {
    await _queue.enqueue(op);
    state = state.copyWith(
      offlineMessage: 'Сервер тимчасово недоступний — зміни збережено і синхронізуються автоматично при відновленні',
    );
  }

  // ── Журнал оцінок ─────────────────────────────────────────────────────────

  Future<void> loadJournal({
    required int groupId,
    required int disciplineId,
    required int semesterId,
  }) async {
    state = const JournalState(isLoading: true);

    final cacheKey = 'journal_${groupId}_${disciplineId}_$semesterId';
    final cachedRaw = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cachedRaw != null) {
      final cached = GradeJournalResponse.fromCacheJson(cachedRaw);
      state = state.copyWith(journal: cached);
    }

    if (!_network.isOnline) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final raw = await _repo.getJournal(
        groupId: groupId,
        disciplineId: disciplineId,
        semesterId: semesterId,
      );
      final journal = await _mergeMarkData(raw);
      await _cache.set(cacheKey, journal.toJson());
      state = state.copyWith(isLoading: false, journal: journal);
      _checkUnfilledJournals(journal);
    } catch (e) {
      if (cachedRaw == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // ── Журнал за journalId (GET /journals/{id}) ─────────────────────────────

  Future<void> loadJournalById(int journalId) async {
    state = const JournalState(isLoading: true);

    final cacheKey = 'journal_id_$journalId';
    final cachedRaw = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cachedRaw != null) {
      final cached = GradeJournalResponse.fromCacheJson(cachedRaw);
      state = state.copyWith(journal: cached);
    }

    if (!_network.isOnline) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final raw = await _repo.getJournalById(journalId);
      final journal = await _mergeMarkData(raw);
      await _cache.set(cacheKey, journal.toJson());
      state = state.copyWith(isLoading: false, journal: journal);
      _checkUnfilledJournals(journal);
    } catch (e) {
      if (cachedRaw == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
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
        final op = PendingOp(
          id: 'mark_del_${cadetId}_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'DELETE',
          path: '/marks/$existingMarkId',
          data: {},
          createdAt: DateTime.now(),
          label: 'Видалення оцінки',
          subtitle: '$cadetName · ${_lessonLabel(lesson)}',
        );
        if (!_network.isOnline) {
          await _queue.enqueue(op);
          (_markIds[cadetId] ??= {}).remove(lessonId);
          return;
        }
        try {
          await _repo.deleteMark(existingMarkId);
          (_markIds[cadetId] ??= {}).remove(lessonId);
        } catch (e) {
          if (_isServerDown(e)) { await _enqueueServerDown(op); return; }
          rethrow;
        }
      } else if (existingMarkId != null) {
        final op = PendingOp(
          id: 'mark_upd_${cadetId}_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'PATCH',
          path: '/marks/$existingMarkId',
          data: {'markValue': value},
          createdAt: DateTime.now(),
          label: 'Оновлення оцінки',
          subtitle: '$cadetName · ${_lessonLabel(lesson)} · ${value.toInt()} балів',
        );
        if (!_network.isOnline) {
          await _queue.enqueue(op);
          return;
        }
        try {
          await _repo.updateMark(existingMarkId, value);
        } catch (e) {
          if (_isServerDown(e)) { await _enqueueServerDown(op); return; }
          rethrow;
        }
      } else {
        if (subLessonId == null) {
          state = state.copyWith(error: 'Немає підзаняття для заняття $lessonId');
          return;
        }
        final op = PendingOp(
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
          label: 'Виставлена оцінка',
          subtitle: '$cadetName · ${_lessonLabel(lesson)} · ${value.toInt()} балів',
        );
        if (!_network.isOnline) {
          await _queue.enqueue(op);
          return;
        }
        try {
          final result = await _repo.createMark(
            cadetId: cadetId,
            subLessonId: subLessonId,
            teacherId: teacherId,
            value: value,
          );
          final newMarkId = result['id'] as int? ?? result['markId'] as int?;
          if (newMarkId != null) (_markIds[cadetId] ??= {})[lessonId] = newMarkId;
        } catch (e) {
          if (_isServerDown(e)) { await _enqueueServerDown(op); return; }
          rethrow;
        }
      }
      if (value != null) _notifyGradeSaved(lesson, value, cadetName);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  String _lessonLabel(LessonModel lesson) =>
      lesson.code.isNotEmpty ? lesson.code : 'Заняття ${lesson.id}';

  void _notifyGradeSaved(LessonModel lesson, double value, String cadetName) {
    final discPrefix = _disciplineName.isNotEmpty ? '$_disciplineName\n' : '';
    final lessonLabel = lesson.code.isNotEmpty ? lesson.code : 'Заняття ${lesson.id}';
    final maxStr = lesson.maxScore > 0 ? '${lesson.maxScore.toInt()}' : '?';
    _notifService.show(
      id: (cadetName.hashCode ^ lesson.id).abs() % 65535,
      title: 'Оцінку збережено',
      body: '$discPrefix$lessonLabel: ${value.toInt()} / $maxStr балів\n$cadetName',
    );
  }

  // ── Збереження відвідуваності (create / update / delete) ──────────────────
  Future<void> saveAttendances({
    required Map<String, List<String?>> attendance,
    required int teacherId,
  }) async {
    final journal = state.journal;
    if (journal == null) return;

    final toCreate = <Map<String, dynamic>>[];          // POST /attends
    final toUpdate = <Map<String, dynamic>>[];          // PATCH /attends/{id}
    final toDelete = <(int, String)>[];                 // (attendId, displayLabel)

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

        final lessonCodeLabel = _lessonLabel(journal.lessons[i]);
        if (currentEnum == null && attendId != null) {
          toDelete.add((attendId, '${cadet.fullName} · $lessonCodeLabel'));
        } else if (currentEnum != null && attendId == null) {
          toCreate.add({
            'cadetId': cadet.id,
            'lessonId': lessonId,
            'teacherId': teacherId,
            'attended': currentEnum,
            '__label': '${cadet.fullName} · $lessonCodeLabel',
          });
        } else if (currentEnum != null && attendId != null) {
          final originalEnum = MilitaryLabels.attendEnum(originalCode);
          if (currentEnum != originalEnum) {
            toUpdate.add({
              'attendId': attendId,
              'attended': currentEnum,
              '__label': '${cadet.fullName} · $lessonCodeLabel',
            });
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
        final label = rec['__label'] as String?;
        final apiData = Map<String, dynamic>.from(rec)..remove('__label');
        await _queue.enqueue(PendingOp(
          id: 'att_new_${rec['cadetId']}_${rec['lessonId']}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'POST', path: '/attends', data: apiData, createdAt: DateTime.now(),
          label: 'Відвідуваність', subtitle: label,
        ));
      }
      for (final rec in toUpdate) {
        final label = rec['__label'] as String?;
        await _queue.enqueue(PendingOp(
          id: 'att_upd_${rec['attendId']}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'PATCH', path: '/attends/${rec['attendId']}',
          data: {'attended': rec['attended']}, createdAt: DateTime.now(),
          label: 'Зміна відвідуваності', subtitle: label,
        ));
      }
      for (final (aId, label) in toDelete) {
        await _queue.enqueue(PendingOp(
          id: 'att_del_${aId}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'DELETE', path: '/attends/$aId', data: {}, createdAt: DateTime.now(),
          label: 'Видалення відвідуваності', subtitle: label,
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
        final label = rec['__label'] as String?;
        final apiData = Map<String, dynamic>.from(rec)..remove('__label');
        final op = PendingOp(
          id: 'att_new_${rec['cadetId']}_${rec['lessonId']}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'POST', path: '/attends', data: apiData, createdAt: DateTime.now(),
          label: 'Відвідуваність', subtitle: label,
        );
        try {
          final created = await _attendsRepo.createAttend(apiData);
          final aId = created['id'] as int? ?? created['attendId'] as int?;
          final cId = rec['cadetId'] as int?;
          final lId = rec['lessonId'] as int?;
          if (aId != null && cId != null && lId != null) {
            (_attendIds[cId] ??= {})[lId] = aId;
          }
        } catch (e) {
          if (_isServerDown(e)) { await _enqueueServerDown(op); continue; }
          rethrow;
        }
      }
      for (final rec in toUpdate) {
        final label = rec['__label'] as String?;
        final op = PendingOp(
          id: 'att_upd_${rec['attendId']}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'PATCH', path: '/attends/${rec['attendId']}',
          data: {'attended': rec['attended']}, createdAt: DateTime.now(),
          label: 'Зміна відвідуваності', subtitle: label,
        );
        try {
          await _attendsRepo.updateAttend(
            rec['attendId'] as int,
            {'attended': rec['attended']},
          );
        } catch (e) {
          if (_isServerDown(e)) { await _enqueueServerDown(op); continue; }
          rethrow;
        }
      }
      for (final (aId, label) in toDelete) {
        final op = PendingOp(
          id: 'att_del_${aId}_${DateTime.now().millisecondsSinceEpoch}',
          method: 'DELETE', path: '/attends/$aId', data: {}, createdAt: DateTime.now(),
          label: 'Видалення відвідуваності', subtitle: label,
        );
        try {
          await _attendsRepo.deleteAttend(aId);
          for (final lessonMap in _attendIds.values) {
            lessonMap.removeWhere((_, v) => v == aId);
          }
        } catch (e) {
          if (_isServerDown(e)) { await _enqueueServerDown(op); continue; }
          rethrow;
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
  final auth = ref.read(authViewModelProvider);
  return GradeJournalViewModel(
    ref.read(gradesRepositoryProvider),
    ref.read(attendsRepositoryProvider),
    ref.read(localCacheProvider),
    ref.read(networkMonitorProvider),
    ref.read(offlineQueueProvider.notifier),
    ref.read(notificationServiceProvider),
    auth.role ?? '',
  );
});
