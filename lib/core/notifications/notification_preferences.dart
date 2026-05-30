// lib/core/notifications/notification_preferences.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

class NotifKey {
  NotifKey._();

  static const master = 'notif_master';

  // CADET
  static const newGrades         = 'notif_new_grades';
  static const lowGrades         = 'notif_low_grades';
  static const scheduleChanges   = 'notif_schedule_changes';
  static const classCancellation = 'notif_class_cancellation';

  // INSTRUCTOR + CADET
  static const beforeClassReminder = 'notif_before_class';
  static const beforeClassTime     = 'notif_before_class_time'; // '15m' | '30m' | '1h'

  // INSTRUCTOR + DEPARTMENT_HEAD
  static const unfilledJournals  = 'notif_unfilled_journals';
  static const myScheduleChanges = 'notif_my_schedule';
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
            NotifKey.newGrades:           true,
            NotifKey.lowGrades:           true,
            NotifKey.scheduleChanges:     true,
            NotifKey.classCancellation:   true,
            NotifKey.beforeClassReminder: false,
          },
          options: {NotifKey.beforeClassTime: '15m'},
        );
      case UserRole.instructor:
        return const NotificationSettings(
          masterEnabled: true,
          toggles: {
            NotifKey.unfilledJournals:    true,
            NotifKey.beforeClassReminder: true,
            NotifKey.myScheduleChanges:   true,
            NotifKey.classCancellation:   true,
          },
          options: {NotifKey.beforeClassTime: '15m'},
        );
      case UserRole.departmentHead:
        return const NotificationSettings(
          masterEnabled: true,
          toggles: {
            NotifKey.unfilledJournals:  true,
            NotifKey.myScheduleChanges: true,
            NotifKey.classCancellation: true,
          },
          options: {},
        );
      default:
        return const NotificationSettings(
          masterEnabled: true,
          toggles: {},
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

/// Перевіряє, чи увімкнено сповіщення [key] у SharedPreferences.
/// Враховує master-перемикач та role-based defaults.
Future<bool> isNotifEnabled(String key, {String role = ''}) async {
  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool(NotifKey.master) ?? true)) return false;
  final defaults = NotificationSettings.defaultsForRole(role).toggles;
  return prefs.getBool(key) ?? defaults[key] ?? false;
}
