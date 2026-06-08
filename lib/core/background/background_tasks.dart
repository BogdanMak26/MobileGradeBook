// lib/core/background/background_tasks.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../notifications/notification_preferences.dart';
import '../notifications/notification_service.dart';
import '../utils/app_constants.dart';

const _kGradesCheckTask = 'com.viti.gradebook.gradesCheck';
const _kJournalsReminderTask = 'com.viti.gradebook.journalsReminder';
const _kOfflineSyncTask = 'com.viti.gradebook.offlineSync';

/// Ключ у SharedPreferences: true якщо є незаповнені журнали (встановлює foreground)
const kUnfilledJournalsFlag = 'bg_has_unfilled_journals';

// ── Top-level dispatcher (обовʼязково @pragma) ────────────────────────────────

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      switch (taskName) {
        case _kGradesCheckTask:
          await _runGradesCheck();
          return true;
        case _kJournalsReminderTask:
          await _runJournalsReminder();
          return true;
        case _kOfflineSyncTask:
          // Return false → WorkManager retries with backoff if sync fails
          return await _runOfflineSync();
      }
      return true;
    } catch (_) {
      // Unexpected error → retry later
      return false;
    }
  });
}

// ── Оновлення токену доступу ───────────────────────────────────────────────────

Future<String?> _getValidToken() async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final accessToken  = await storage.read(key: AppConstants.accessTokenKey);
  final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);
  final expiresAtStr = await storage.read(key: 'expires_at');
  if (accessToken == null) return null;

  final expiresAt = expiresAtStr != null
      ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(expiresAtStr) ?? 0)
      : null;

  if (expiresAt != null && DateTime.now().isAfter(expiresAt) && refreshToken != null) {
    try {
      final dio = Dio();
      final resp = await dio.post(
        AppConstants.tokenEndpoint,
        data: {
          'grant_type':    'refresh_token',
          'client_id':     AppConstants.keycloakClientId,
          'refresh_token': refreshToken,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final data = resp.data is String
          ? jsonDecode(resp.data as String) as Map<String, dynamic>
          : resp.data as Map<String, dynamic>;
      final newAccess  = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      final expiresIn  = data['expires_in'] as int? ?? 300;
      await storage.write(key: AppConstants.accessTokenKey, value: newAccess);
      await storage.write(key: AppConstants.refreshTokenKey, value: newRefresh);
      await storage.write(
        key: 'expires_at',
        value: DateTime.now()
            .add(Duration(seconds: expiresIn - 30))
            .millisecondsSinceEpoch
            .toString(),
      );
      return newAccess;
    } catch (_) {
      return accessToken;
    }
  }
  return accessToken;
}

// ── Перевірка нових оцінок (курсанти, щогодини) ───────────────────────────────

Future<void> _runGradesCheck() async {
  final prefs = await SharedPreferences.getInstance();
  final role       = prefs.getString(AppConstants.userRoleKey);
  final userId     = prefs.getString(AppConstants.userIdKey);
  final groupIdStr = prefs.getString(AppConstants.groupIdKey);
  if (role != UserRole.cadet || userId == null || groupIdStr == null) return;

  if (!await isNotifEnabled(NotifKey.newGrades, role: role ?? '')) return;

  final token = await _getValidToken();
  if (token == null) return;

  final cadetId = int.tryParse(userId);
  final groupId = int.tryParse(groupIdStr);
  if (cadetId == null || groupId == null) return;

  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'CF-Access-Client-Id':     AppConstants.cfClientId,
      'CF-Access-Client-Secret': AppConstants.cfClientSecret,
      'Authorization':           'Bearer $token',
    },
  ));

  // 1. Отримуємо список журналів групи (з назвою дисципліни)
  final journalsResp = await dio.get('/journals', queryParameters: {'groupId': groupId});
  final journals = journalsResp.data as List<dynamic>? ?? [];

  NotificationService? notif;

  for (final j in journals) {
    final jMap = j as Map<String, dynamic>;
    final journalId = jMap['journalId'] as int? ?? jMap['id'] as int?;
    if (journalId == null) continue;

    final disciplineName = jMap['disciplineFullName'] as String?
        ?? jMap['disciplineName'] as String?
        ?? (jMap['discipline'] as Map<String, dynamic>?)?['name'] as String?
        ?? '';

    // 2. Отримуємо заняття з оцінками для цього журналу
    final lessonsResp = await dio.get('/lessons/journal/$journalId');
    final lessons = lessonsResp.data as List<dynamic>? ?? [];

    // 3. Збираємо оцінки курсанта: lessonId → (lessonCode, value, maxScore)
    final freshMarks = <String, Map<String, dynamic>>{};
    for (final l in lessons) {
      final lMap = l as Map<String, dynamic>;
      final lessonId = (lMap['id'] ?? lMap['lessonId']) as int?;
      if (lessonId == null) continue;

      final lessonCode = lMap['lessonName'] as String?
          ?? lMap['name'] as String?
          ?? lMap['code'] as String?
          ?? '';
      double maxScore = 0;
      double cadetScore = 0;
      bool hasScore = false;

      for (final sl in (lMap['subLessons'] as List<dynamic>? ?? [])) {
        final slMap = sl as Map<String, dynamic>;
        maxScore += (slMap['markMaxValue'] as num?)?.toDouble() ?? 0.0;
        for (final m in (slMap['marks'] as List<dynamic>? ?? [])) {
          final mMap = m as Map<String, dynamic>;
          if ((mMap['cadetId'] as int?) == cadetId) {
            cadetScore += (mMap['value'] as num?)?.toDouble() ?? 0.0;
            hasScore = true;
          }
        }
      }

      if (hasScore) {
        freshMarks[lessonId.toString()] = {
          'code': lessonCode,
          'value': cadetScore,
          'max': maxScore,
        };
      }
    }

    // 4. Порівнюємо з кешем і надсилаємо сповіщення
    final cacheKey = 'bg_marks_${journalId}_$cadetId';
    final cachedJson = prefs.getString(cacheKey);
    final cached = cachedJson != null
        ? jsonDecode(cachedJson) as Map<String, dynamic>
        : <String, dynamic>{};

    for (final entry in freshMarks.entries) {
      final lessonKey = entry.key;
      final fresh = entry.value;
      final oldValue = (cached[lessonKey]?['value'] as num?)?.toDouble();

      if (oldValue == null || oldValue != (fresh['value'] as double)) {
        final lessonCode = fresh['code'] as String? ?? '';
        final val = (fresh['value'] as double).toInt();
        final max = (fresh['max'] as double) > 0
            ? (fresh['max'] as double).toInt().toString()
            : '?';
        notif ??= NotificationService();
        await notif.initialize();
        await notif.show(
          id: (journalId * 1000 + int.parse(lessonKey)).abs() % 65535,
          title: 'Нова оцінка',
          body: '$disciplineName\n$lessonCode: $val з $max балів',
        );
      }
    }

    // 5. Оновлюємо кеш
    await prefs.setString(cacheKey, jsonEncode(freshMarks));
  }
}

// ── Нагадування про незаповнені журнали (викладачі, раз на 12 год) ────────────

Future<void> _runJournalsReminder() async {
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString(AppConstants.userRoleKey);
  if (role != UserRole.instructor && role != UserRole.departmentHead) return;

  if (!await isNotifEnabled(NotifKey.unfilledJournals, role: role ?? '')) return;

  final hasUnfilled = prefs.getBool(kUnfilledJournalsFlag) ?? false;
  if (!hasUnfilled) return;

  final now      = DateTime.now();
  final dedupKey = 'notif_bg_journals_${now.year}${now.month}${now.day}';
  if (prefs.getBool(dedupKey) == true) return;
  await prefs.setBool(dedupKey, true);

  final notif = NotificationService();
  await notif.initialize();
  await notif.show(
    id: 50000,
    title: 'Незаповнені журнали',
    body: 'Є журнали, що потребують заповнення оцінок',
  );
}

// ── Фонова синхронізація офлайн-черги ─────────────────────────────────────────

// Returns true = all done (nothing left or all sent), false = retry needed.
Future<bool> _runOfflineSync() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('offline_queue');
  if (raw == null || raw.isEmpty) return true;

  final token = await _getValidToken();
  // No valid token → retry later
  if (token == null) return false;

  List<dynamic> ops;
  try {
    ops = jsonDecode(raw) as List<dynamic>;
  } catch (_) {
    // Corrupted queue — clear it so we don't loop forever
    await prefs.remove('offline_queue');
    return true;
  }
  if (ops.isEmpty) return true;

  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      // Cloudflare Access service token — without these all requests return 403
      'CF-Access-Client-Id':     AppConstants.cfClientId,
      'CF-Access-Client-Secret': AppConstants.cfClientSecret,
      'Authorization':           'Bearer $token',
    },
  ));

  final remaining = <dynamic>[];
  for (final opJson in ops) {
    final op = Map<String, dynamic>.from(opJson as Map);
    try {
      switch (op['method'] as String) {
        case 'POST':
          await dio.post(op['path'] as String, data: op['data']);
        case 'PUT':
          await dio.put(op['path'] as String, data: op['data']);
        case 'PATCH':
          await dio.patch(op['path'] as String, data: op['data']);
        case 'DELETE':
          await dio.delete(op['path'] as String);
      }
    } catch (_) {
      remaining.add(opJson);
    }
  }

  if (remaining.isEmpty) {
    await prefs.remove('offline_queue');
  } else {
    await prefs.setString('offline_queue', jsonEncode(remaining));
  }

  // If some ops still remain → tell WorkManager to retry with backoff
  return remaining.isEmpty;
}

// ── Публічний клас для реєстрації задач ───────────────────────────────────────

class BackgroundTasks {
  static Future<void> register() async {
    await Workmanager().initialize(backgroundCallbackDispatcher);

    // Курсанти: перевірка нових оцінок щогодини
    await Workmanager().registerPeriodicTask(
      'gradesCheck',
      _kGradesCheckTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );

    // Викладачі: нагадування про незаповнені журнали раз на 12 годин
    await Workmanager().registerPeriodicTask(
      'journalsReminder',
      _kJournalsReminderTask,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(hours: 1),
    );
  }
}
