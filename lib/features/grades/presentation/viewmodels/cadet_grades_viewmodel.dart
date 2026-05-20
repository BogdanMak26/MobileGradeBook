// lib/features/grades/presentation/viewmodels/cadet_grades_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class CadetGradesState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> grades;

  const CadetGradesState({
    this.isLoading = false,
    this.error,
    this.grades = const [],
  });

  CadetGradesState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? grades,
  }) =>
      CadetGradesState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        grades: grades ?? this.grades,
      );
}

class CadetGradesViewModel extends StateNotifier<CadetGradesState> {
  final RatesRepository _repo;
  final String? _cadetId;

  CadetGradesViewModel(this._repo, this._cadetId)
      : super(const CadetGradesState()) {
    if (_cadetId != null) load();
  }

  Future<void> load() async {
    final id = int.tryParse(_cadetId ?? '');
    if (id == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final raw = await _repo.getCadetRates(id);
      final disciplines = raw['disciplines'] as List<dynamic>? ?? [];
      final grades = disciplines.map((item) {
        final m = item as Map<String, dynamic>;
        final academicYear = m['academicYear'] as int?;
        final semNumbers = m['semesterNumbers'] as List<dynamic>?;
        final sem = semNumbers?.isNotEmpty == true ? semNumbers!.first : null;
        final attendancePct = (m['attendancePercentage'] as num?)?.toInt() ?? 100;
        final ratePct = (m['ratePercentage'] as num?)?.toInt();
        final studentMarks = (m['studentMarks'] as num?)?.toDouble();
        final maxMarks = (m['maxPossibleMarks'] as num?)?.toDouble();
        return <String, dynamic>{
          'discipline': m['disciplineFullName'] ?? m['disciplineShortName'] ?? '',
          'shortName': m['disciplineShortName'] ?? '',
          'score': ratePct,
          'studentMarks': studentMarks,
          'maxMarks': maxMarks,
          'attendancePercentage': attendancePct,
          'date': DateTime(
            academicYear ?? DateTime.now().year,
            sem != null ? ((sem as num).toInt() % 2 == 0 ? 2 : 9) : 9,
          ),
        };
      }).toList();
      state = state.copyWith(isLoading: false, grades: grades);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final cadetGradesViewModelProvider =
    StateNotifierProvider<CadetGradesViewModel, CadetGradesState>((ref) {
  final auth = ref.watch(authViewModelProvider);
  return CadetGradesViewModel(
    ref.read(ratesRepositoryProvider),
    auth.userId,
  );
});
