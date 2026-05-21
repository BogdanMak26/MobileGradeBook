// lib/features/disciplines/presentation/viewmodels/disciplines_viewmodel.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  DisciplinesViewModel(this._repo, this._role, this._cadetId, this._kafedraId)
      : super(const DisciplinesState()) {
    load();
  }

  Future<void> load() async {
    if (_role.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      List<DisciplineModel> disciplines;
      final cadetId = _cadetId;
      if (_role == UserRole.cadet) {
        disciplines = cadetId != null
            ? await _repo.getCadetDisciplines(cadetId)
            : [];
      } else if (_role == UserRole.superAdmin ||
          _role == UserRole.departmentHead) {
        disciplines = await _repo.getAllDisciplines();
      } else {
        disciplines = state.myOnly
            ? await _loadInstructorDisciplines()
            : await _repo.getAllDisciplines(kafedraId: _kafedraId);
      }
      state = state.copyWith(isLoading: false, disciplines: disciplines);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    try {
      final journals = await _repo.getDisciplineJournals(disciplineId);
      state = state.copyWith(
        journals: {...state.journals, disciplineId: journals},
      );
      return journals;
    } catch (_) {
      return [];
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
  );
});
