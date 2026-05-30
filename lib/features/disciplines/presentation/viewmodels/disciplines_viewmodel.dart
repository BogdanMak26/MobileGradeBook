// lib/features/disciplines/presentation/viewmodels/disciplines_viewmodel.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local/local_cache.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/models/discipline_model.dart';
import '../../data/models/journal_model.dart';
import '../../data/repositories/disciplines_repository.dart';

class DisciplinesState {
  final bool isLoading;
  final String? error;
  final List<DisciplineModel> disciplines;
  final Map<int, List<JournalModel>> journals;
  final bool myOnly;

  const DisciplinesState({
    this.isLoading = false,
    this.error,
    this.disciplines = const [],
    this.journals = const {},
    this.myOnly = true,
  });

  DisciplinesState copyWith({
    bool? isLoading,
    String? error,
    List<DisciplineModel>? disciplines,
    Map<int, List<JournalModel>>? journals,
    bool? myOnly,
  }) =>
      DisciplinesState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        disciplines: disciplines ?? this.disciplines,
        journals: journals ?? this.journals,
        myOnly: myOnly ?? this.myOnly,
      );
}

class DisciplinesViewModel extends StateNotifier<DisciplinesState> {
  final DisciplinesRepository _repo;
  final String _role;
  final int? _cadetId;
  final int? _kafedraId;
  final LocalCache _cache;
  final NetworkMonitor _network;

  DisciplinesViewModel(
    this._repo,
    this._role,
    this._cadetId,
    this._kafedraId,
    this._cache,
    this._network,
  ) : super(const DisciplinesState()) {
    load();
  }

  String get _disciplinesCacheKey {
    if (_role == UserRole.cadet) return 'disciplines_cadet_$_cadetId';
    if (_role == UserRole.superAdmin) return 'disciplines_all';
    if (_role == UserRole.departmentHead) return 'disciplines_kafedra_$_kafedraId';
    return 'disciplines_instructor_${_kafedraId}_${state.myOnly}';
  }

  Future<void> load() async {
    if (_role.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);

    final cacheKey = _disciplinesCacheKey;
    final cachedRaw = _cache.get<List<dynamic>>(cacheKey);
    if (cachedRaw != null) {
      final cached = cachedRaw
          .map((e) => DisciplineModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(disciplines: cached);
    }

    if (!_network.isOnline) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      List<DisciplineModel> disciplines;
      final cadetId = _cadetId;
      if (_role == UserRole.cadet) {
        disciplines = cadetId != null
            ? await _repo.getCadetDisciplines(cadetId)
            : [];
      } else if (_role == UserRole.superAdmin) {
        disciplines = await _repo.getAllDisciplines();
      } else if (_role == UserRole.departmentHead) {
        disciplines = await _repo.getAllDisciplines(kafedraId: _kafedraId);
      } else {
        disciplines = state.myOnly
            ? await _loadInstructorDisciplines()
            : await _repo.getAllDisciplines(kafedraId: _kafedraId);
      }
      await _cache.set(cacheKey, disciplines.map((d) => d.toJson()).toList());
      state = state.copyWith(isLoading: false, disciplines: disciplines);
    } catch (e) {
      if (cachedRaw == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> setMyOnly(bool myOnly) async {
    if (_role != UserRole.instructor) return;
    state = state.copyWith(myOnly: myOnly);
    await load();
  }

  Future<List<DisciplineModel>> _loadInstructorDisciplines() async {
    try {
      return await _repo.getMyDisciplines();
    } on DioException catch (e) {
      if (e.response?.statusCode == 405 || e.response?.statusCode == 404) {
        return await _repo.getAllDisciplines(kafedraId: _kafedraId);
      }
      rethrow;
    }
  }

  Future<List<JournalModel>> getJournalsFor(int disciplineId) async {
    if (state.journals.containsKey(disciplineId)) {
      return state.journals[disciplineId]!;
    }

    final cacheKey = 'discipline_journals_$disciplineId';
    final cachedRaw = _cache.get<List<dynamic>>(cacheKey);
    if (cachedRaw != null) {
      final cached = cachedRaw
          .map((e) => JournalModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(journals: {...state.journals, disciplineId: cached});
      if (!_network.isOnline) return cached;
    }

    if (!_network.isOnline) return [];

    try {
      final journals = await _repo.getDisciplineJournals(disciplineId);
      await _cache.set(cacheKey, journals.map((j) => j.toJson()).toList());
      state = state.copyWith(
        journals: {...state.journals, disciplineId: journals},
      );
      return journals;
    } catch (_) {
      return cachedRaw != null
          ? cachedRaw
              .map((e) => JournalModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [];
    }
  }
}

final disciplinesViewModelProvider =
    StateNotifierProvider<DisciplinesViewModel, DisciplinesState>((ref) {
  final auth = ref.watch(authViewModelProvider);
  return DisciplinesViewModel(
    ref.read(disciplinesRepositoryProvider),
    auth.role ?? '',
    int.tryParse(auth.userId ?? ''),
    auth.kafedraId,
    ref.read(localCacheProvider),
    ref.read(networkMonitorProvider),
  );
});
