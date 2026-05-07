import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/local/local_cache.dart';
import 'core/local/offline_queue.dart';
import 'core/notifications/notification_service.dart';
import 'core/sync/sync_service.dart';
import 'core/utils/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/connectivity_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uk', null);
  final prefs = await SharedPreferences.getInstance();
  await NotificationService().initialize();

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // eagerly init sync so it starts listening to network changes
    ref.read(syncServiceProvider);

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
}
