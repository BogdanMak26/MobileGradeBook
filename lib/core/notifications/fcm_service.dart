// lib/core/notifications/fcm_service.dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'notification_service.dart';

// Обробник фонових повідомлень — має бути top-level функцією
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final n = message.notification;
  if (n == null) return;
  final service = NotificationService();
  await service.initialize();
  await service.show(
    id: message.hashCode,
    title: n.title ?? 'GradeBook ВІТІ',
    body: n.body ?? '',
  );
}

class FcmTopics {
  static const allUsers       = 'all_users';
  static const cadets         = 'cadets';
  static const instructors    = 'instructors';
  static const departmentHeads = 'department_heads';
  static const educationOffice = 'education_office';
  static const admins         = 'admins';

  static String? forRole(String? role) => switch (role) {
    'CADET'                    => cadets,
    'INSTRUCTOR'               => instructors,
    'DEPARTMENT_HEAD'          => departmentHeads,
    'FACULTY_EDUCATION_OFFICE' => educationOffice,
    'INSTITUTE_EDUCATION_OFFICE' => educationOffice,
    'SUPER_ADMIN'              => admins,
    _ => null,
  };
}

class FcmService {
  final NotificationService _notificationService;
  final ApiClient _apiClient;
  bool _initialized = false;

  FcmService(this._notificationService, this._apiClient);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    // Підписка на topic не залежить від дозволу на показ нотифікацій
    try {
      await FirebaseMessaging.instance.subscribeToTopic('all_users');
      print('[FCM] subscribed to topic: all_users');
    } catch (e) {
      print('[FCM] topic subscription error: $e');
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('[FCM] permission status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // iOS: показувати banner навіть коли застосунок відкритий
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      print('[FCM] token: $token');
      await _registerToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      print('[FCM] token refreshed: $t');
      _registerToken(t);
    });

    // Повідомлення, коли застосунок відкритий (foreground)
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Натискання на нотифікацію з фону
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // Натискання з закритого стану
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    await _notificationService.show(
      id: message.hashCode,
      title: n.title ?? 'GradeBook ВІТІ',
      body: n.body ?? '',
    );
  }

  void _handleTap(RemoteMessage message) {
    // Навігація на основі message.data — додати роутинг при потребі
  }

  Future<void> subscribeToRoleTopic(String? role) async {
    final topic = FcmTopics.forRole(role);
    if (topic == null) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      print('[FCM] subscribed to role topic: $topic');
    } catch (e) {
      print('[FCM] role topic subscribe error: $e');
    }
  }

  Future<void> unsubscribeFromRoleTopic(String? role) async {
    final topic = FcmTopics.forRole(role);
    if (topic == null) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      print('[FCM] unsubscribed from role topic: $topic');
    } catch (e) {
      print('[FCM] role topic unsubscribe error: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiClient.dio.post(
        '/notifications/device-token',
        data: {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
    } catch (_) {
      // Endpoint може ще не бути реалізованим на бекенді
    }
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    ref.read(notificationServiceProvider),
    ref.read(apiClientProvider),
  );
});
