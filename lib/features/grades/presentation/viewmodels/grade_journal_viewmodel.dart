// lib/features/grades/presentation/viewmodels/grade_journal_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/local/local_cache.dart';
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

  GradeJournalViewModel(this._repo, this._attendsRepo, this._cache, this._network)
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
      final journal = await _repo.getJournal(
        groupId: groupId,
        disciplineId: disciplineId,
        semesterId: semesterId,
      );
      state = state.copyWith(isLoading: false, journal: journal);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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

  // ── Збереження відвідуваності (batch) ──────────────────────────────────────
  // attendance: {cadetFullName: [code per lesson index]} — same structure as page state.
  // teacherId: used to associate the attend record with a teacher.
  Future<void> saveAttendances({
    required Map<String, List<String?>> attendance,
    required int teacherId,
  }) async {
    final journal = state.journal;
    if (journal == null) return;
    if (!_network.isOnline) {
      state = state.copyWith(error: "Немає з'єднання. Спробуйте при підключенні.");
      return;
    }

    state = state.copyWith(isSyncing: true, syncMessage: null);

    final attends = <Map<String, dynamic>>[];
    for (final cadet in journal.cadets) {
      final cadetAtt = attendance[cadet.fullName];
      if (cadetAtt == null) continue;
      for (int i = 0; i < journal.lessons.length && i < cadetAtt.length; i++) {
        final serverEnum = MilitaryLabels.attendEnum(cadetAtt[i]);
        if (serverEnum != null) {
          attends.add({
            'cadetId': cadet.id,
            'lessonId': journal.lessons[i].id,
            'teacherId': teacherId,
            'attended': serverEnum,
          });
        }
      }
    }

    if (attends.isEmpty) {
      state = state.copyWith(isSyncing: false, syncMessage: '✓ Без змін');
      return;
    }

    try {
      await _attendsRepo.batchAttends(attends);
      state = state.copyWith(isSyncing: false, syncMessage: '✓ Відвідуваність збережено');
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
  );
});
