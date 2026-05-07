// lib/core/notifications/notification_preferences.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

class NotifKey {
  NotifKey._();

  static const master = 'notif_master';

  // CADET
  static const importantClasses     = 'notif_important_classes';
  static const importantClassesTime = 'notif_important_classes_time'; // '1h' | '24h' | '48h'
  static const newGrades            = 'notif_new_grades';
  static const lowGrades            = 'notif_low_grades';
  static const scheduleChanges      = 'notif_schedule_changes';
  static const classCancellation    = 'notif_class_cancellation';
  static const deptAnnouncements    = 'notif_dept_announcements';

  // INSTRUCTOR
  static const unfilledJournals     = 'notif_unfilled_journals';
  static const beforeClassReminder  = 'notif_before_class';
  static const beforeClassTime      = 'notif_before_class_time'; // '15m' | '30m' | '1h'
  static const myScheduleChanges    = 'notif_my_schedule';
  static const newCadets            = 'notif_new_cadets';

  // DEPARTMENT_HEAD
  static const weeklyDigest                = 'notif_weekly_digest';
  static const criticalPerformance         = 'notif_critical_performance';
  static const monthlyReport               = 'notif_monthly_report';
  static const unfilledInstructorJournals  = 'notif_instructor_journals';
  static const overdueJournals             = 'notif_overdue_journals';
  static const deptSchedule               = 'notif_dept_schedule';

  // ADMIN / EDUCATION OFFICE
  static const newUsers            = 'notif_new_users';
  static const syncErrors          = 'notif_sync_errors';
  static const weeklyReports       = 'notif_weekly_reports';
  static const criticalIndicators  = 'notif_critical_indicators';
  static const groupChanges        = 'notif_group_changes';
  static const disciplineChanges   = 'notif_discipline_changes';
}

class NotificationSettings {
  final bool masterEnabled;
  final Map<String, bool> toggles;
  final Map<String, String> options;

  const NotificationSettings({
    required this.masterEnabled,
    required this.toggles,
    required this.options,
  });

  bool isEnabled(String key) => masterEnabled && (toggles[key] ?? false);
  String option(String key, String fallback) => options[key] ?? fallback;

  int get enabledCount => toggles.values.where((v) => v).length;
  int get totalCount   => toggles.length;

  NotificationSettings copyWithToggle(String key, bool value) {
    if (key == NotifKey.master) {
      return NotificationSettings(
          masterEnabled: value, toggles: toggles, options: options);
    }
    return NotificationSettings(
      masterEnabled: masterEnabled,
      toggles: {...toggles, key: value},
      options: options,
    );
  }

  NotificationSettings copyWithOption(String key, String value) {
    return NotificationSettings(
      masterEnabled: masterEnabled,
      toggles: toggles,
      options: {...options, key: value},
    );
  }

  static NotificationSettings defaultsForRole(String role) {
    switch (role) {
      case UserRole.cadet:
        return const NotificationSettings(
          masterEnabled: true,
          toggles: {
            NotifKey.importantClasses:  true,
            NotifKey.newGrades:         true,
            NotifKey.lowGrades:         true,
            NotifKey.scheduleChanges:   true,
            NotifKey.classCancellation: true,
            NotifKey.deptAnnouncements: false,
          },
          options: {NotifKey.importantClassesTime: '24h'},
        );
      case UserRole.instructor:
        return const NotificationSettings(
          masterEnabled: true,
          toggles: {
            NotifKey.unfilledJournals:    true,
            NotifKey.beforeClassReminder: true,
            NotifKey.myScheduleChanges:   true,
            NotifKey.classCancellation:   true,
            NotifKey.newCadets:           false,
          },
          options: {NotifKey.beforeClassTime: '15m'},
        );
      case UserRole.departmentHead:
        return const NotificationSettings(
          masterEnabled: true,
          toggles: {
            NotifKey.weeklyDigest:               true,
            NotifKey.criticalPerformance:        true,
            NotifKey.monthlyReport:              false,
            NotifKey.unfilledInstructorJournals: true,
            NotifKey.overdueJournals:            true,
            NotifKey.deptSchedule:               true,
          },
          options: {},
        );
      default:
        return const NotificationSettings(
          masterEnabled: true,
          toggles: {
            NotifKey.newUsers:           true,
            NotifKey.syncErrors:         true,
            NotifKey.weeklyReports:      true,
            NotifKey.criticalIndicators: true,
            NotifKey.groupChanges:       false,
            NotifKey.disciplineChanges:  false,
          },
          options: {},
        );
    }
  }
}

class NotificationSettingsNotifier
    extends StateNotifier<NotificationSettings> {
  SharedPreferences? _prefs;
  final String _role;

  NotificationSettingsNotifier(this._role)
      : super(NotificationSettings.defaultsForRole(_role)) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final def    = NotificationSettings.defaultsForRole(_role);
    final master = _prefs!.getBool(NotifKey.master) ?? true;

    final toggles = <String, bool>{};
    for (final k in def.toggles.keys) {
      toggles[k] = _prefs!.getBool(k) ?? def.toggles[k]!;
    }
    final options = <String, String>{};
    for (final k in def.options.keys) {
      options[k] = _prefs!.getString(k) ?? def.options[k]!;
    }
    if (mounted) {
      state = NotificationSettings(
          masterEnabled: master, toggles: toggles, options: options);
    }
  }

  Future<void> toggle(String key, bool value) async {
    final prefKey = key == NotifKey.master ? NotifKey.master : key;
    await _prefs?.setBool(prefKey, value);
    state = state.copyWithToggle(key, value);
  }

  Future<void> setOption(String key, String value) async {
    await _prefs?.setString(key, value);
    state = state.copyWithOption(key, value);
  }
}

final notificationSettingsProvider = StateNotifierProvider.autoDispose<
    NotificationSettingsNotifier, NotificationSettings>(
  (ref) {
    final role =
        ref.watch(authViewModelProvider.select((s) => s.role ?? UserRole.cadet));
    return NotificationSettingsNotifier(role);
  },
);
