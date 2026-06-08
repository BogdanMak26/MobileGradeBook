import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'core/background/background_tasks.dart';
import 'core/local/local_cache.dart';
import 'core/local/offline_queue.dart';
import 'core/notifications/fcm_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/platform/platform_settings.dart';
import 'core/sync/sync_service.dart';
import 'core/utils/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/connectivity_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('uk', null);
  final prefs = await SharedPreferences.getInstance();
  await NotificationService().initialize();

  // Ініціалізація timezone для планованих сповіщень
  tz.initializeTimeZones();
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  // "Europe/Kiev" перейменовано на "Europe/Kyiv" у IANA tzdb
  final tzId = timezoneInfo.identifier == 'Europe/Kiev'
      ? 'Europe/Kyiv'
      : timezoneInfo.identifier;
  try {
    tz.setLocalLocation(tz.getLocation(tzId));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  // Реєстрація фонових задач (workmanager)
  await BackgroundTasks.register();

  runApp(ProviderScope(
    overrides: [
      localCacheProvider.overrideWithValue(LocalCache(prefs)),
      offlineQueueProvider.overrideWith((ref) => OfflineQueueNotifier(prefs)),
    ],
    child: const GradeBookApp(),
  ));
}

class GradeBookApp extends ConsumerWidget {
  const GradeBookApp({super.key});

  // Checked once per process lifetime — subsequent builds skip the call.
  static bool _batteryOptChecked = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(syncServiceProvider);
    ref.read(fcmServiceProvider).initialize();

    if (!_batteryOptChecked) {
      _batteryOptChecked = true;
      // addPostFrameCallback ensures the Flutter engine + MethodChannel is
      // fully ready before we invoke the native battery-opt dialog.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeRequestBatteryOpt(ref.read(platformSettingsProvider));
      });
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'GradeBook ВІТІ',
      theme: AppTheme.light.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uk'), Locale('en')],
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => ConnectivityOverlay(child: child!),
    );
  }

  static Future<void> _maybeRequestBatteryOpt(PlatformSettings platform) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'battery_opt_prompted';
      if (prefs.getBool(key) == true) return;
      final isIgnoring = await platform.checkBatteryOptimization();
      if (!isIgnoring) {
        await prefs.setBool(key, true);
        await platform.requestIgnoreBatteryOptimization();
      }
    } catch (_) {}
  }
}
