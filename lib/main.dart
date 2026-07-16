import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/database/isar_service.dart';
import 'core/logging/logger.dart';
import 'core/services/notification_service.dart';
import 'core/services/prayer_times_service.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  logger.info('Starting Muslim Prayer Tracker App...');

  // Initialize Isar database
  try {
    await IsarService.instance.database;
    logger.info('Database initialized successfully');
  } catch (e, stackTrace) {
    logger.error(
      'Failed to initialize database',
      error: e,
      stackTrace: stackTrace,
    );
  }

  // Initialize notification service
  try {
    final notificationService = NotificationService();
    final initialized = await notificationService.initialize();

    if (!initialized) {
      logger.error('Notification service failed to initialize');
    } else {
      logger.info('Notification service initialized successfully');

      // Request notification permissions explicitly
      final permissionGranted = await notificationService.requestPermissions();
      logger.info('Notification permissions granted: $permissionGranted');

      // Schedule daily prayer notifications if enabled
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? false;

      logger.info('Notifications enabled in settings: $notificationsEnabled');

      if (notificationsEnabled && permissionGranted) {
        final prayerTimesService = PrayerTimesService();
        final prayerTimes = await prayerTimesService.getTodayPrayerTimes();

        if (prayerTimes != null) {
          logger.info('Got prayer times, scheduling notifications...');
          await notificationService.scheduleAllPrayers(prayerTimes);

          // Verify scheduled notifications
          final pending = await notificationService.getPendingNotifications();
          logger.info(
            '✅ Prayer notifications scheduled. Pending: ${pending.length}',
          );
        } else {
          logger.warning('Failed to get prayer times');
        }
      } else if (!notificationsEnabled) {
        logger.info('Notifications disabled in settings');
      } else {
        logger.warning('Notification permissions not granted');
      }
    }
  } catch (e, stackTrace) {
    logger.error(
      'Failed to initialize notification service',
      error: e,
      stackTrace: stackTrace,
    );
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muslim Prayer Tracker',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Initial route
      home: const SplashScreen(),

      // Builder for error handling
      builder: (context, child) {
        // Handle errors in widget tree
        ErrorWidget.builder = (FlutterErrorDetails details) {
          logger.error(
            'Widget error',
            error: details.exception,
            stackTrace: details.stack,
          );

          return Material(
            child: Container(
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.exception.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        };

        return child ?? const SizedBox();
      },
    );
  }
}
