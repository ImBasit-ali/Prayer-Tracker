import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/prayer_times_service.dart';

/// Settings screen for app configuration
class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationsEnabled = useState(false);
    final fajrTime = useState('05:00');
    final dhuhrTime = useState('12:30');
    final asrTime = useState('15:45');
    final maghribTime = useState('19:00');
    final ishaTime = useState('20:30');

    // Load settings on mount
    useEffect(() {
      Future<void> loadSettings() async {
        final prefs = await SharedPreferences.getInstance();
        notificationsEnabled.value =
            prefs.getBool('notifications_enabled') ?? false;

        final service = PrayerTimesService();
        fajrTime.value = await service.getManualTime(PrayerTimesService.keyManualFajr, '05:00');
        dhuhrTime.value = await service.getManualTime(PrayerTimesService.keyManualDhuhr, '12:30');
        asrTime.value = await service.getManualTime(PrayerTimesService.keyManualAsr, '15:45');
        maghribTime.value = await service.getManualTime(PrayerTimesService.keyManualMaghrib, '19:00');
        ishaTime.value = await service.getManualTime(PrayerTimesService.keyManualIsha, '20:30');
      }

      loadSettings();
      return null;
    }, []);

    Future<void> saveNotificationsSetting(bool enabled) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);
      notificationsEnabled.value = enabled;

      if (enabled) {
        // Request permissions and schedule notifications
        final service = NotificationService();
        final granted = await service.requestPermissions();

        if (granted) {
          final prayerTimes = await PrayerTimesService().getTodayPrayerTimes();
          if (prayerTimes != null) {
            await service.scheduleAllPrayers(prayerTimes);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prayer notifications enabled!')),
              );
            }
          }
        } else {
          notificationsEnabled.value = false;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Permission denied. Please enable notifications in settings.',
                ),
              ),
            );
          }
        }
      } else {
        await NotificationService().cancelAllNotifications();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prayer notifications disabled')),
          );
        }
      }
    }

    Future<void> pickPrayerTime(String prayerKey, ValueNotifier<String> timeState) async {
      final currentParts = timeState.value.split(':');
      final currentTime = TimeOfDay(
        hour: int.parse(currentParts[0]),
        minute: int.parse(currentParts[1]),
      );

      final selected = await showTimePicker(
        context: context,
        initialTime: currentTime,
      );

      if (selected != null) {
        final formattedTime =
            '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
        
        final service = PrayerTimesService();
        await service.saveManualTime(prayerKey, formattedTime);
        timeState.value = formattedTime;

        // Reschedule notifications if enabled
        if (notificationsEnabled.value) {
          final prayerTimes = await service.getTodayPrayerTimes();
          if (prayerTimes != null) {
            await NotificationService().cancelAllNotifications();
            await NotificationService().scheduleAllPrayers(prayerTimes);
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prayer time updated!')),
          );
        }
      }
    }

    Future<void> showPrayerTimes() async {
      final times = await PrayerTimesService().getTodayPrayerTimes();

      if (times != null && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Today\'s Prayer Times'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeRow('Fajr', times['fajr']!),
                _buildTimeRow('Sunrise', times['sunrise']!),
                _buildTimeRow('Dhuhr', times['dhuhr']!),
                _buildTimeRow('Asr', times['asr']!),
                _buildTimeRow('Maghrib', times['maghrib']!),
                _buildTimeRow('Isha', times['isha']!),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        children: [
          // Notifications Section
          const ListTile(
            title: Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SwitchListTile(
            title: const Text('Prayer Time Notifications'),
            subtitle: const Text('Get notified at each prayer time'),
            value: notificationsEnabled.value,
            onChanged: saveNotificationsSetting,
            secondary: const Icon(Icons.notifications_active),
          ),
          ListTile(
            title: const Text('Test Notification'),
            subtitle: const Text('Send a test notification now'),
            leading: const Icon(Icons.notification_add),
            onTap: () async {
              await NotificationService().showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              }
            },
          ),

          const Divider(),

          // Manual Prayer Times Configuration Section
          const ListTile(
            title: Text(
              'Configure Prayer Times',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          _buildManualTimeTile(
            context,
            name: 'Fajr',
            time: fajrTime.value,
            onTap: () => pickPrayerTime(PrayerTimesService.keyManualFajr, fajrTime),
          ),
          _buildManualTimeTile(
            context,
            name: 'Dhuhr',
            time: dhuhrTime.value,
            onTap: () => pickPrayerTime(PrayerTimesService.keyManualDhuhr, dhuhrTime),
          ),
          _buildManualTimeTile(
            context,
            name: 'Asr',
            time: asrTime.value,
            onTap: () => pickPrayerTime(PrayerTimesService.keyManualAsr, asrTime),
          ),
          _buildManualTimeTile(
            context,
            name: 'Maghrib',
            time: maghribTime.value,
            onTap: () => pickPrayerTime(PrayerTimesService.keyManualMaghrib, maghribTime),
          ),
          _buildManualTimeTile(
            context,
            name: 'Isha',
            time: ishaTime.value,
            onTap: () => pickPrayerTime(PrayerTimesService.keyManualIsha, ishaTime),
          ),
          ListTile(
            title: const Text('View All Times'),
            subtitle: const Text('See today\'s full prayer times schedule'),
            leading: const Icon(Icons.access_time),
            onTap: showPrayerTimes,
          ),

          const Divider(),

          // App Info
          const ListTile(
            title: Text(
              'About',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const ListTile(
            title: Text('Muslim Prayer Tracker'),
            subtitle: Text(
              'Version 1.0.0\nTrack your daily prayers and tasbeeh',
            ),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTimeTile(
    BuildContext context, {
    required String name,
    required String time,
    required VoidCallback onTap,
  }) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    final formattedTime = timeOfDay.format(context);

    return ListTile(
      title: Text(name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit, size: 18),
        ],
      ),
      leading: const Icon(Icons.access_time),
      onTap: onTap,
    );
  }

  Widget _buildTimeRow(String name, DateTime time) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timeStr),
        ],
      ),
    );
  }
}
