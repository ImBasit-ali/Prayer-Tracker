import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../logging/logger.dart';

/// Notification service for prayer time reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize timezone data and set dynamically
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      logger.info('Timezone set dynamically to: ${tz.local.name}');

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _isInitialized = true;
        logger.info('Notification service initialized successfully');

        // Create notification channel for Android
        await _createNotificationChannel();

        return true;
      }

      return false;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to initialize notification service',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'prayer_times',
      'Prayer Times',
      description: 'Notifications for daily prayer times',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    logger.info('Notification tapped: ${response.payload}');
    // TODO: Navigate to prayer screen when app supports it
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // iOS permissions
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Android 13+ permissions
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final androidGranted = await androidPlugin
          ?.requestNotificationsPermission();

      logger.info(
        'Notification permissions: iOS=$iosGranted, Android=$androidGranted',
      );
      return iosGranted ?? androidGranted ?? true;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to request notification permissions',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Schedule prayer time notification
  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Validate prayer time is in the future
      final now = DateTime.now();
      if (prayerTime.isBefore(now)) {
        logger.warning(
          'Skipping $prayerName - time has passed: ${prayerTime.toString()}',
        );
        return;
      }

      final scheduledDate = tz.TZDateTime.from(prayerTime, tz.local);

      logger.info(
        'Scheduling $prayerName notification:'
        '\n  ID: $id'
        '\n  Time: ${prayerTime.toString()}'
        '\n  TZ Time: ${scheduledDate.toString()}'
        '\n  Current: ${now.toString()}',
      );

      await _notifications.zonedSchedule(
        id,
        'Prayer Time: $prayerName',
        'It\'s time for $prayerName prayer. Don\'t forget to pray! 🕌',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_times',
            'Prayer Times',
            channelDescription: 'Notifications for daily prayer times',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          linux: LinuxNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: prayerName,
      );

      logger.info('✅ Successfully scheduled notification for $prayerName');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to schedule notification for $prayerName',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Schedule all 5 daily prayer notifications
  Future<void> scheduleAllPrayers(Map<String, DateTime> prayerTimes) async {
    final prayers = [
      {'id': 1, 'name': 'Fajr', 'time': prayerTimes['fajr']},
      {'id': 2, 'name': 'Dhuhr', 'time': prayerTimes['dhuhr']},
      {'id': 3, 'name': 'Asr', 'time': prayerTimes['asr']},
      {'id': 4, 'name': 'Maghrib', 'time': prayerTimes['maghrib']},
      {'id': 5, 'name': 'Isha', 'time': prayerTimes['isha']},
    ];

    for (final prayer in prayers) {
      final time = prayer['time'] as DateTime?;
      if (time != null && time.isAfter(DateTime.now())) {
        await schedulePrayerNotification(
          id: prayer['id'] as int,
          prayerName: prayer['name'] as String,
          prayerTime: time,
        );
      }
    }

    logger.info('Scheduled all prayer notifications for today');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    logger.info('Cancelled all notifications');
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    logger.info('Cancelled notification with id: $id');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final enabled = await androidPlugin?.areNotificationsEnabled();
    return enabled ?? false;
  }

  /// Show immediate test notification
  Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Test Notification',
      'Prayer time notifications are working! 🕌',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_times',
          'Prayer Times',
          channelDescription: 'Notifications for daily prayer times',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
    );
    logger.info('Showed test notification');
  }

  /// Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    logger.info('Found ${pending.length} pending notifications');
    for (final notification in pending) {
      logger.debug(
        'Pending: ID=${notification.id}, Title=${notification.title}',
      );
    }
    return pending;
  }
}
