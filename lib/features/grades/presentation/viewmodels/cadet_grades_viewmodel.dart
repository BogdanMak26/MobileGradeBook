// lib/features/grades/presentation/viewmodels/cadet_grades_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/repositories.dart';
import '../../../../core/local/local_cache.dart';
import '../../../../core/network/network_monitor.dart';
import '../../../../core/notifications/notification_preferences.dart';
import '../../../../core/notifications/notification_service.dart';
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
  final LocalCache _cache;
  final NetworkMonitor _network;
  final String? _cadetId;
  final NotificationService _notifService;
  final String _role;

  CadetGradesViewModel(this._repo, this._cache, this._network, this._cadetId, this._notifService, this._role)
      : super(const CadetGradesState()) {
    if (_cadetId != null) load();
  }

  String get _cacheKey => 'cadet_grades_$_cadetId';

  Future<void> _checkLowGrades({
    required List<Map<String, dynamic>> oldGrades,
    required List<Map<String, dynamic>> freshGrades,
  }) async {
    if (!await isNotifEnabled(NotifKey.lowGrades, role: _role)) return;
    final oldScores = {
      for (final g in oldGrades)
        g['discipline'] as String: g['score'] as int?,
    };
    for (final g in freshGrades) {
      final name = g['discipline'] as String? ?? '';
      final score = g['score'] as int?;
      if (score == null || score >= 60) continue;
      final prev = oldScores[name];
      // тільки якщо раніше не було низькою
      if (prev != null && prev < 60) continue;
      final studentMarks = (g['studentMarks'] as double?)?.toInt();
      final maxMarks = (g['maxMarks'] as double?)?.toInt();
      final scoreStr = (studentMarks != null && maxMarks != null && maxMarks > 0)
          ? '$studentMarks / $maxMarks балів ($score%)'
          : '$score%';
      await _notifService.show(
        id: name.hashCode.abs() % 65535,
        title: 'Низька успішність',
        body: '$name\n$scoreStr',
      );
    }
  }

  static List<Map<String, dynamic>> _parseRaw(Map<String, dynamic> raw) {
    final disciplines = raw['disciplines'] as List<dynamic>? ?? [];
    return disciplines.map((item) {
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
  }

  Future<void> load() async {
    final id = int.tryParse(_cadetId ?? '');
    if (id == null) return;
    state = state.copyWith(isLoading: true, error: null);

    // Показуємо кешовані дані одразу
    final cachedRaw = _cache.get<Map<String, dynamic>>(_cacheKey);
    if (cachedRaw != null) {
      state = state.copyWith(grades: _parseRaw(cachedRaw));
    }

    if (!_network.isOnline) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final raw = await _repo.getCadetRates(id);
      final freshGrades = _parseRaw(raw);
      _checkLowGrades(oldGrades: state.grades, freshGrades: freshGrades);
      await _cache.set(_cacheKey, raw);
      state = state.copyWith(isLoading: false, grades: freshGrades);
    } catch (e) {
      if (cachedRaw == null) {
        state = state.copyWith(isLoading: false, error: e.toString());
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}

final cadetGradesViewModelProvider =
    StateNotifierProvider<CadetGradesViewModel, CadetGradesState>((ref) {
  final auth = ref.watch(authViewModelProvider);
  return CadetGradesViewModel(
    ref.read(ratesRepositoryProvider),
    ref.read(localCacheProvider),
    ref.read(networkMonitorProvider),
    auth.userId,
    ref.read(notificationServiceProvider),
    auth.role ?? '',
  );
});
